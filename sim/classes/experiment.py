from typing import Any
from os.path import exists

import numpy as np
from swiplserver import *
import config as c

from .flow import Flow
from .infrastructure import Infrastructure


def parse_prolog(query):
    if is_prolog_functor(query):
        if prolog_name(query) != ",":
            ans = (prolog_name(query),parse_prolog(prolog_args(query)))
        else:
            ans = tuple(parse_prolog(prolog_args(query)))
    elif is_prolog_list(query):
        ans = [parse_prolog(v) for v in query]
    elif is_prolog_atom(query):
        ans = query
    elif isinstance(query, dict):
        ans = {k:parse_prolog(v) for k,v in query.items()}
    else:
        ans = query
    return ans


class Experiment:
    def __init__(self, num_nodes: int = 2, num_flows: int = 1, 
                 seed: Any = None, timeout: int = None, gml: str = None):
        
        self.timeout = timeout
        np.random.seed(seed)
        self.infrastructure = Infrastructure(n=num_nodes, m=int(np.log2(num_nodes)), seed=seed, gml=gml) #
        self.flows = self.generate_flows(num_flows)

        self.flows_file = c.FLOW_FILE_PATH.format(size=num_flows)
        self.infr_file = c.INFRA_FILE_PATH.format(name=(gml if gml else num_nodes))

        self.result = []

    # @c.timeit
    def generate_flows(self, num_flows):
        flows = []
        for i in range(num_flows):
            start, end = np.random.choice(self.infrastructure.nodes, size=2, replace=False)
            flows.append(Flow(f"f{i}", start, end, random=True))
        return flows
    
    def upload(self):
        self.infrastructure.upload()
        [f.upload(file=self.flows_file, append=(False if i == 0 else True)) for i, f in enumerate(self.flows)]

    def run(self):
        with PrologMQI() as mqi:
            with mqi.create_thread() as prolog:
                prolog.query("consult('{}')".format(c.MAIN_FILE))
                prolog.query("consult('{}')".format(self.flows_file))
                prolog.query("consult('{}')".format(self.infr_file))
                prolog.query_async(c.MAIN_QUERY, find_all=False, query_timeout_seconds=self.timeout)

                try:
                    q = prolog.query_async_result()
                    if q:
                        self.result = self.parse_output(q[0])
                    else:
                        print("\tNo results found.")
                except PrologQueryTimeoutError as e:
                    print("\tTimeout reached. Skipping this experiment.")

    def parse_paths(self, paths):
        return {flow: {"path": path, "budgets": budgets, "delay": delay} for (flow, (path, (budgets, delay))) in paths} 

    def parse_allocation(self, allocation):
        return {(s, d): bw for (s, (d, bw)) in allocation}

    def parse_output(self, out):
        o = parse_prolog(out)
        return {"Output": self.parse_paths(o['Output']), 
                "Allocation": self.parse_allocation(o['Allocation']),
                "Inferences": o['Inferences'],
                "Time": o['Time']}
    
    def __str__(self):
        if not self.result:
            return "No results yet."
        else:
            res = ""
            res += "Paths: \n"
            for flow, attr in self.result["Output"].items():
                res += f"Flow {flow}: \n"
                res += f"\tPath: {attr['path']}\n"
                res += f"\tBudgets: {attr['budgets']}\n"
                res += f"\tDelay: {attr['delay']}\n"
            res += "Allocation: \n"
            for (s, d), bw in self.result["Allocation"].items():
                res += f"\tLink {s} -> {d}: {bw} Mbps\n"
            res += f"Inferences: {self.result['Inferences']}\n"
            res += f"Time: {round(self.result['Time'], 4)} (s)\n"
            return res

