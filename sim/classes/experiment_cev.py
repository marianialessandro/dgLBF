import math
import os
import random
from collections import defaultdict
from itertools import combinations
from os import makedirs
from os.path import dirname, exists
from pathlib import Path
from typing import Any, Dict, List, Literal, Optional

import psutil

import config as c
import networkx as nx
import numpy as np
from multipledispatch import dispatch
from swiplserver import *

from .flow import Flow
from .infrastructure import Infrastructure

from .utils.affinity_utils import get_anti_affinity
from .utils.prolog_parse_utils import parse_output

class Experiment:
    def __init__(
        self,
        n_flows: int,
        builder: Literal["barabasi_albert", "erdos_renyi", "gml"] = "gml",
        n: Optional[int] = None,
        m: Optional[int] = None,
        p: Optional[float] = None,
        gml: Optional[str] = None,
        replica_probability: float = 0.0,
        version: Literal["plain", "rel", "pp", "aa", "all"] = "plain",
        seed: Any = None,
        timeout: int = 1800,
        experiment_dir: Path = c.DATA_DIR,
    ):
        np.random.seed(seed)
        random.seed(seed)

        self.builder = builder
        self.n = n
        self.m = m
        self.p = p
        self.gml = gml

        self.flows = []
        self.n_flows = n_flows

        self.rep_prob = replica_probability
        self.version = version
        self.seed = seed
        self.timeout = timeout
        self.experiment_dir = experiment_dir

        self.result: Dict[str, Any] = {}
        self.infrastructure: Optional[Infrastructure] = None

        self.process = psutil.Process(os.getpid())
        self.cpu = 0
        self.mem_start = 0
        self.mem_end = 0

    def set_flows(self):
        filename = c.FLOWS_FILE.format(
            size=self.n_flows,
            seed=self.seed,
            rp=self.rep_prob,
        )
        self.flows_file = self.experiment_dir / "flows" / filename
        if self.flows == []:
            self.flows: List[Flow] = []
            valid_nodes = [n for n in self.infrastructure.nodes if n.startswith("ns")]
            for i in range(self.n_flows):
                exists = False
                while not exists:
                    start, end = np.random.choice(valid_nodes, size=2, replace=False)
                    exists = (
                        len(
                            self.infrastructure.simple_paths(
                                start,
                                end,
                                disjoint=True,
                            )
                        )
                        >= 2
                    )
                self.flows.append(
                    Flow(
                        f"f{i}",
                        start,
                        end,
                        random=True,
                        rep_prob=1 if i <= self.rep_prob else 0,
                    )
                )

            self.flows.sort(
                key=lambda f: nx.shortest_path_length(
                    self.infrastructure, f.start, f.end
                )
            )

    def upload_flows(self):

        flows = [str(f) for f in self.flows]
        data_reqs = [f.data_reqs() for f in self.flows]
        p_protection = [f.path_protection() for f in self.flows]
        # aa_reqs = get_anti_affinity([f.fid for f in self.flows], n=self.rep_prob)

        if not exists(dirname(self.flows_file)):
            makedirs(dirname(self.flows_file))

        result = ""
        result += "\n".join(flows) + "\n\n"
        result += "\n".join(data_reqs) + "\n\n"
        result += "\n".join(p_protection) + "\n\n"

        paths = defaultdict(
            lambda: None,
            {
                (f.start, f.end): self.infrastructure.simple_paths(f.start, f.end)
                for f in self.flows
            },
        )

        # if aa_reqs and any(aa_reqs.values()):
        #     for f, anti_aff in aa_reqs.items():
        #         if anti_aff:
        #             result += (
        #                 c.ANTI_AFFINITY.format(
        #                     fid=f, anti_affinity=str(anti_aff).replace("'", "")
        #                 )
        #                 + "\n"
        #             )
        #     result += "\n"

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

    def save_result(self):
        self.result["Version"] = self.version
        self.result["Seed"] = self.seed
        self.result["RepProb"] = self.rep_prob
        self.result["Infr"] = self.infrastructure.name
        self.result["Flows"] = self.n_flows
        self.result["Nodes"] = len(self.infrastructure.nodes)
        self.result["Edges"] = len(self.infrastructure.edges)

        self.result["cpu"] = self.cpu
        self.result["mem_start"] = self.mem_start
        self.result["mem_end"] = self.mem_end

    def stringify(self):
        return {k: str(v) for k, v in self.result.items()}

    def __str__(self):
        if not self.result:
            return "\nNo results yet.\n"
        else:
            res = f"Flows: {self.result['Flows']}" + "\n"
            res += f"Nodes: {self.result['Nodes']}" + "\n"
            res += f"Edges: {self.result['Edges']}" + "\n\n"
            res += "Paths: \n"
            for flow, attr in self.result["Output"].items():
                res += f"Flow {flow}: \n"
                res += f"\tPath: {attr['path']}\n"
                res += f"\tBudgets: {round(attr['budgets'][0], 4), round(attr['budgets'][1], 4)}\n"
                res += f"\tDelay: {round(attr['delay'],4)}\n"
            res += "Allocation: \n"
            for (s, d), bw in self.result["Allocation"].items():
                res += f"\tLink {s} -> {d}: {bw} Mbps\n"
            res += f"Inferences: {self.result['Inferences']}\n"
            res += f"Time: {round(self.result['Time'], 4)} (s)\n"
            return res

    def run(self):
        self.infrastructure = Infrastructure(
            builder=self.builder,
            n=self.n,
            m=self.m,
            p=self.p,
            seed=self.seed,
            gml=self.gml,
            infra_path=self.experiment_dir / "infrastructures",
        )

        self.set_flows()
        self.upload()

        cpu_start = self.process.cpu_percent(interval=None)
        self.mem_start = self.process.memory_info().rss / (1024 * 1024)

        # with PrologMQI(launch_mqi=False, port=4242, password="debugnow") as mqi:
        with PrologMQI() as mqi:
            with mqi.create_thread() as prolog:
                prolog.query(
                    "consult('{}')".format(
                        c.VERSION_FILE_PATH.format(version=self.version)
                    )
                )
                prolog.query("consult('{}')".format(c.SIM_FILE_PATH))
                prolog.query(c.LOAD_INFR_QUERY.format(path=self.infrastructure.file))
                prolog.query(c.LOAD_FLOWS_QUERY.format(path=self.flows_file))
                prolog.query_async(
                    c.MAIN_QUERY, find_all=False, query_timeout_seconds=self.timeout
                )
                self.cpu = self.process.cpu_percent(interval=None) - cpu_start
                self.mem_end = self.process.memory_info().rss / (1024 * 1024)
                try:
                    q = prolog.query_async_result()
                    if q and q[0] and q[0]["Output"] != []:
                        self.result.update(
                            parse_output(
                                q[0],
                                plain=self.version == "plain",
                            )
                        )
                    else:
                        print("No results found.")
                        self.empty_update("no_result")
                except PrologQueryTimeoutError:
                    print("Timeout reached. Skipping this experiment.")
                    self.empty_update("timeout")

        self.save_result()

    def empty_update(self, reason: str):
        self.result.update(
            {
                "Output": reason,
                "Allocation": None,
                "Inferences": None,
                "Time": (
                    self.timeout if "Time" not in self.result else self.result["Time"]
                ),
            }
        )
