import math
import random
import time
from collections import defaultdict
from itertools import combinations, product
from os import makedirs
from os.path import dirname, exists
from typing import Any, List, Union

import colorama as clr
import config as c
import networkx as nx
import numpy as np
import pandas as pd
from multipledispatch import dispatch
from swiplserver import *

from .flow import Flow
from .infrastructure import Infrastructure


def parse_prolog(query):
    if is_prolog_functor(query):
        if prolog_name(query) != ",":
            ans = (prolog_name(query), parse_prolog(prolog_args(query)))
        else:
            ans = tuple(parse_prolog(prolog_args(query)))
    elif is_prolog_list(query):
        ans = [parse_prolog(v) for v in query]
    elif is_prolog_atom(query):
        ans = query
    elif isinstance(query, dict):
        ans = {k: parse_prolog(v) for k, v in query.items()}
    else:
        ans = query
    return ans


class Experiment:
    def __init__(
        self,
        num_nodes: List[int] = [],
        num_flows: List[int] = [],
        gmls: List[str] = [],
        max_iterations: int = 1,
        seed: Any = None,
        timeout: int = None,
    ):
        np.random.seed(seed)
        random.seed(seed)
        self.num_nodes = num_nodes
        self.num_flows = num_flows
        self.gmls = gmls
        self.max_iterations = max_iterations
        self.seed = seed
        self.timeout = timeout
        self.results = []

    @dispatch(str)
    def set_infrastructure(self, gml):
        self.infrastructure = Infrastructure(gml=gml)

    @dispatch(int)
    def set_infrastructure(self, num_nodes):
        self.infrastructure = Infrastructure(
            n=num_nodes, m=int(np.log2(num_nodes)), seed=self.seed
        )

    def set_flows(self, num_flows):
        self.flows_file = c.FLOW_FILE_PATH.format(size=num_flows)
        self.flows: List[Flow] = []
        for i in range(num_flows):
            exists = False
            while not exists:
                start, end = np.random.choice(
                    self.infrastructure.nodes, size=2, replace=False
                )
                exists = nx.has_path(self.infrastructure, start, end)
            self.flows.append(Flow(f"f{i}", start, end, random=True))

        self.flows.sort(
            key=lambda f: nx.shortest_path_length(self.infrastructure, f.start, f.end)
        )

    def get_anti_affinity(self, flow_ids):

        # f2 = random.choice(flow_ids[1:])
        # anti_affinity = {flow_ids[0]: [f2], f2: [flow_ids[0]]}

        N = len(flow_ids)
        PAIRS = int(math.log2(N))

        all_pairs = list(combinations(flow_ids, 2))

        random.shuffle(all_pairs)

        selected_pairs = all_pairs[:PAIRS]

        anti_affinity = defaultdict(list)

        for f1, f2 in selected_pairs:
            anti_affinity[f1].append(f2)
            anti_affinity[f2].append(f1)

        return anti_affinity

    def upload_flows(self):

        flows = [str(f) for f in self.flows]
        data_reqs = [f.data_reqs() for f in self.flows]
        p_protection = [f.path_protection() for f in self.flows]
        aa_reqs = self.get_anti_affinity([f.fid for f in self.flows])

        if not exists(dirname(self.flows_file)):
            makedirs(dirname(self.flows_file))

        result = ""
        result += "\n".join(flows) + "\n\n"
        result += "\n".join(data_reqs) + "\n\n"
        result += "\n".join(p_protection) + "\n\n"

        paths = defaultdict(
            lambda: None,
            {
                (f.start, f.end): self.infrastructure.simple_paths(
                    f.start,
                    f.end,  # disjoint=(f.replicas)
                )
                for f in self.flows
            },
        )

        if aa_reqs and any(aa_reqs.values()):
            for f, anti_aff in aa_reqs.items():
                if anti_aff:
                    result += (
                        c.ANTI_AFFINITY.format(
                            fid=f, anti_affinity=str(anti_aff).replace("'", "")
                        )
                        + "\n"
                    )
            result += "\n"

        for (source, target), ps in paths.items():
            for idx, path in enumerate(ps):
                result += (
                    c.CANDIDATE.format(
                        pid=f"p{idx}_{source}_{target}",
                        path=str(path).replace("'", ""),
                        source=source,
                        target=target,
                    )
                    + "\n"
                )

        with open(self.flows_file, "w+") as file:
            file.write(result)

    def upload(self):
        self.infrastructure.upload()
        self.upload_flows()

    def save_result(self, res):
        res["RepProb"] = c.REPLICAS_PROB
        res["Infr"] = self.infrastructure.name
        res["Flows"] = len(self.flows)
        res["Nodes"] = len(self.infrastructure.nodes)
        res["Edges"] = len(self.infrastructure.edges)
        res["Timestamp"] = pd.Timestamp.strftime(
            pd.Timestamp.now(), c.EXP_TIMESTAMP_FORMAT
        )
        self.results.append(res)

    def results_to_csv(self):
        if self.results:
            df = pd.DataFrame(
                self.results,
                columns=[
                    "Timestamp",
                    "Infr",
                    "RepProb",
                    "Flows",
                    "Nodes",
                    "Edges",
                    "Time",
                    "Inferences",
                    "Output",
                    "Allocation",
                    "Iterations",
                ],
            )
            df.set_index("Timestamp", inplace=True)
            name = (
                str(self.seed)
                if self.seed
                else pd.Timestamp.now().strftime(c.RES_TIMESTAMP_FORMAT)
            )
            filepath = c.RESULTS_DIR / c.RESULTS_FILE.format(name=name)
            c.df_to_file(df, filepath)
        else:
            print("No results yet.")

    def run_exp(self, infr: Union[int, str], flows: int, iteration: int = 1):
        start_time = time.time()
        self.set_infrastructure(infr)
        self.set_flows(flows)
        print(
            "\n" + clr.Fore.CYAN + f"Setting {round(time.time() - start_time, 4)}s",
            end="\t",
        )
        start_time = time.time()
        self.upload()
        print(
            clr.Fore.LIGHTCYAN_EX + f"Uploading {round(time.time() - start_time, 4)}s",
            end="\n\n",
        )

        with PrologMQI() as mqi:
            with mqi.create_thread() as prolog:
                print(
                    c.EXP_MESSAGE.format(
                        iteration=iteration,
                        flows=flows,
                        infr=self.infrastructure.name,
                        edges=len(self.infrastructure.edges),
                        nodes=len(self.infrastructure.nodes),
                        seed=self.seed,
                    )
                )
                prolog.query("consult('{}')".format(c.SIM_FILE_PATH))
                prolog.query(c.LOAD_INFR_QUERY.format(path=self.infrastructure.file))
                prolog.query(c.LOAD_FLOWS_QUERY.format(path=self.flows_file))
                prolog.query_async(
                    c.MAIN_QUERY, find_all=False, query_timeout_seconds=self.timeout
                )
                res = {}
                try:
                    q = prolog.query_async_result()
                    if q:
                        res = self.parse_output(q[0])
                    else:
                        print("\t" + clr.Fore.LIGHTRED_EX + "No results found.")
                except PrologQueryTimeoutError:
                    print(
                        "\t"
                        + clr.Fore.YELLOW
                        + "Timeout reached. Skipping this experiment."
                    )

                return res

    def run(self):
        clr.init(autoreset=True)
        infrs = self.gmls + self.num_nodes
        for i, f in product(infrs, self.num_flows):
            iterations = 0
            res = None
            while not res and iterations < self.max_iterations:
                iterations += 1
                res = self.run_exp(infr=i, flows=f)

            res["Iterations"] = iterations
            self.save_result(res)

    def parse_paths(self, paths):
        return {
            (flow, pid): {
                "path": path,
                "reliability": reliability,
                "budgets": budgets,
                "delay": delay,
            }
            for (flow, (pid, (path, (reliability, (budgets, delay))))) in paths
        }

    def parse_allocation(self, allocation):
        return {(s, d): bw for (s, (d, bw)) in allocation}

    def parse_output(self, out):
        o = parse_prolog(out)
        return {
            "Output": self.parse_paths(o["Output"]),
            "Allocation": self.parse_allocation(o["Allocation"]),
            "Inferences": o["Inferences"],
            "Time": o["Time"],
        }

    def __str__(self):
        if not self.results:
            return "\nNo results yet.\n"
        else:
            res = ""
            for r in self.results:
                res += f"Flows: {r['Flows']}" + "\n"
                res += f"Nodes: {r['Nodes']}" + "\n"
                res += f"Edges: {r['Edges']}" + "\n\n"
                res += "Paths: \n"
                for flow, attr in r["Output"].items():
                    res += f"Flow {flow}: \n"
                    res += f"\tPath: {attr['path']}\n"
                    res += f"\tBudgets: {round(attr['budgets'][0], 4), round(attr['budgets'][1], 4)}\n"
                    res += f"\tDelay: {round(attr['delay'],4)}\n"
                res += "Allocation: \n"
                for (s, d), bw in r["Allocation"].items():
                    res += f"\tLink {s} -> {d}: {bw} Mbps\n"
                res += f"Inferences: {r['Inferences']}\n"
                res += f"Time: {round(r['Time'], 4)} (s)\n"
            return res
