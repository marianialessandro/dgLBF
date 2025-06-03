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
from .utils.prolog_parse import parse_output

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
        version: Literal["plain", "rel", "pp", "aa", "all", "cc"] = "plain",
        seed: Any = None,
        timeout: int = 1800,
        experiment_dir: Path = c.DATA_DIR,
        prebuilt_flows_file: Optional[Path] = None,
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

        self.replica_probability = (
            replica_probability if version in ["pp", "all"] else 0.0
        )
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
        
        self.prebuilt_flows_file = prebuilt_flows_file

    def set_flows(self):
        if self.prebuilt_flows_file is not None:
            self.flows_file = self.prebuilt_flows_file
            return
        
        filename = c.FLOWS_FILE.format(
            size=self.n_flows,
            seed=self.seed,
            rp=self.replica_probability,
        )
        self.flows_file = self.experiment_dir / "flows" / filename
        self.flows: List[Flow] = []
        for i in range(self.n_flows):
            exists = False
            while not exists:
                start, end = np.random.choice(
                    self.infrastructure.nodes, size=2, replace=False
                )
                exists = nx.has_path(self.infrastructure, start, end)
            self.flows.append(
                Flow(
                    f"f{i}",
                    start,
                    end,
                    random=True,
                    rep_prob=self.replica_probability,
                )
            )

        self.flows.sort(
            key=lambda f: nx.shortest_path_length(self.infrastructure, f.start, f.end)
        )

    def upload_flows(self):
        
        if self.prebuilt_flows_file is not None:
            return

        flows = [str(f) for f in self.flows]
        data_reqs = [f.data_reqs() for f in self.flows]
        p_protection = [f.path_protection() for f in self.flows]
        aa_reqs = get_anti_affinity([f.fid for f in self.flows])

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
        
        if self.version == "cc":
            self.infrastructure.upload_energy_profiles()

        self.upload_flows()

    def save_result(self):
        self.result["Version"] = self.version
        self.result["Seed"] = self.seed
        self.result["RepProb"] = self.replica_probability
        self.result["Infr"] = self.infrastructure.name
        self.result["Flows"] = self.n_flows
        self.result["Nodes"] = len(self.infrastructure.nodes)
        self.result["Edges"] = len(self.infrastructure.edges)
        self.result["Builder"] = self.builder

        self.result["cpu"] = self.cpu
        self.result["mem_start"] = self.mem_start
        self.result["mem_end"] = self.mem_end

    def stringify(self):
        return {k: str(v) for k, v in self.result.items()}
        
    def __str__(self):
        if not self.result:
            return "\nNo results yet.\n"

        out = [
            f"Version:      {self.version}",
            f"Flows:        {self.result.get('Flows',     '–')}",
            f"Nodes:        {self.result.get('Nodes',     '–')}",
            f"Edges:        {self.result.get('Edges',     '–')}",
            f"Inferences:   {self.result.get('Inferences','–')}",
            f"Time:         {round(self.result.get('Time',0),4)} s",
            ""
        ]
        
        output = self.result.get("Output")
        if not isinstance(output, dict):
            out.append(f"No results: {output}")
            return "\n".join(out)

        out.append("Paths and Delays:")
        for (flow, pid), attr in self.result["Output"].items():
            out.append(f"  Flow {flow}/{pid}:")
            out.append(f"    Path:      {attr['path']}")
            b0,b1 = attr['budgets']
            out.append(f"    Budgets:   min={round(b0,4)} Mbps, max={round(b1,4)} Mbps")
            out.append(f"    Delay:     {round(attr['delay'],4)} ms")
        out.append("")
        out.append("Allocation (link → bandwidth):")
        for (s,d), bw in self.result["Allocation"].items():
            out.append(f"  {s} → {d}: {bw} Mbps")
                
        if self.version == "cc":
            out.append("")
            out.append("Node Energy and Emissions Summary: ")
            for entry in self.result.get("NodeCarbonCost", []):
                out.append(f"  Node:              {entry['Node']}")
                out.append(f"    Load:             {entry['Load']} Mbps")
                out.append(f"    CO₂ Emissions:    {entry['CarbonEmissions']:.2e} kgCO₂")
                out.append(f"    Energy Cost:      {entry['EnergyCost']:.2e} €")
                out.append("")
            
            out.append(f"Total Carbon(Kg): {self.result.get('TotalCarbon')}")
            out.append(f"Total Cost: {self.result.get('TotalCost')}")

        return "\n".join(out)

    def run(self):
        self.infrastructure = Infrastructure(
            builder=self.builder,
            n=self.n,
            m=self.m,
            p=self.p,
            seed=self.seed,
            gml=self.gml,
            infra_path=self.experiment_dir / "infrastructures",
            version=self.version,
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
                
                if self.version == "cc":
                    # filename = c.ENERGY_PROFILE_FILE.format(name=self.gml)
                    filename = c.ENERGY_PROFILE_FILE.format(name=self.infrastructure.name)
                    file_path = os.path.join(c.ENERGY_PROFILES_DIR, filename)
                    
                    prolog.query(
                        c.LOAD_ENERGY_PROFILES_QUERY.format(path=file_path)
                    )
                    
                    prolog.query(
                        c.LOAD_CARBON_CREDITS_QUERY.format(path=c.CARBON_CREDITS_FILE_PATH)
                    )
                    
                    prolog.query_async(
                        c.MAIN_CC_QUERY, find_all=False, query_timeout_seconds=self.timeout
                    )
                else:
                    prolog.query_async(
                        c.MAIN_QUERY, find_all=False, query_timeout_seconds=self.timeout
                    )
                    
                try:
                    q = prolog.query_async_result()
                    self.cpu = self.process.cpu_percent(interval=None) - cpu_start
                    self.mem_end = self.process.memory_info().rss / (1024 * 1024)
                    if q:
                        self.result.update(
                            parse_output(q[0], version=self.version)
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
        
        if self.version == "cc":
            self.result.update({
                "NodeCarbonCost": [],  # lista vuota di dict
                "TotalCarbon": None,   # oppure 0 se preferisci
                "TotalCost": None,
                "CarbonCredits": [],   # lista vuota di dict
            })
