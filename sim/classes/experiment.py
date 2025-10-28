import os
import random
from os import makedirs
from os.path import dirname, exists
from pathlib import Path
from typing import Any, Dict, List, Literal, Optional, Tuple

from collections import defaultdict

import psutil

import config as c
import networkx as nx
import numpy as np
from swiplserver import *

from .flow import Flow
from .infrastructure import Infrastructure

from .utils.affinity_utils import get_anti_affinity
from .utils.prolog_parse import parse_output

from .utils.generate_energy_profiles import generate_energy_profiles
from .utils.save_energy_profiles import save_energy_profiles

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
        version: Literal["plain", "rel", "pp", "aa", "all", "ccg", "ccgp", "ccbnb"] = "plain",
        seed: Any = None,
        timeout: int = 7200,
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

        self.energy_profiles: Optional[Dict[Any, Any]] = None
        self.flows: List[Flow] = []
        self.n_flows = n_flows

        self.replica_probability = (
            replica_probability if version in ["pp", "all"] else 0.0
        )
        self.version = version
        self.seed = seed
        self.timeout = timeout
        self.experiment_dir = experiment_dir

        self.prebuilt_flows_file = prebuilt_flows_file
        self.flows_file: Optional[Path] = None
        self.energy_profile_file: Optional[Path] = None

        self.result: Dict[str, Any] = {}
        self.infrastructure: Optional[Infrastructure] = None
        self.candidates: Dict[Tuple[str, str], List[List[str]]] = {}
        self.average_alphas: Dict[Tuple[str, str], List[float]] = {}
        self.candidate_lengths: Dict[Tuple[str, str], List[int]] = {}

        self.process = psutil.Process(os.getpid())
        self.cpu = 0
        self.mem_start = 0
        self.mem_end = 0

        self.flow_scores: Dict[str, float] = {}


    def sort_flows(self) -> None:
        if not self.candidates:
            self.calculate_candidates()

        self.flows.sort(key=lambda flow: len(self.candidates.get((flow.start, flow.end), [])))
        
        self.flow_scores = {flow.fid: len(self.candidates.get((flow.start, flow.end), []))
                            for flow in self.flows}

    def set_flowsFileName(self):
        if self.prebuilt_flows_file is not None:
            self.flows_file = self.prebuilt_flows_file
        else:
            filename = c.FLOWS_FILE.format(
                size=self.n_flows,
                seed=self.seed,
                rp=self.replica_probability,
            )
            self.flows_file = self.experiment_dir / "flows" / filename
                        
    def set_energy_profile_file(self):
        if "cc" not in (self.version or "").lower():
            return

        if self.builder == "gml" and self.gml:
            name = Path(self.gml).stem if isinstance(self.gml, (str, Path)) else str(self.gml)
        else:
            name = self.infrastructure.name

        filename = c.ENERGY_PROFILE_FILE.format(name=name)
        self.energy_profile_file = self.experiment_dir / "energyProfiles" / filename

    def set_flows(self):
        if self.prebuilt_flows_file is not None:
            return

        self.flows = []
        for i in range(self.n_flows):
            exists_path = False
            while not exists_path:
                start, end = np.random.choice(
                    self.infrastructure.nodes, size=2, replace=False
                )
                exists_path = nx.has_path(self.infrastructure, start, end)
            self.flows.append(
                Flow(
                    f"f{i}", start, end, random=True, rep_prob=self.replica_probability
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

        flows_path = self.flows_file

        if not exists(dirname(flows_path)):
            makedirs(dirname(flows_path))

        parts: List[str] = []
        parts += flows
        parts.append("")
        parts += data_reqs
        parts.append("")
        parts += p_protection
        parts.append("")

        if aa_reqs and any(aa_reqs.values()):
            for f, anti_aff in aa_reqs.items():
                if anti_aff:
                    parts.append(
                        c.ANTI_AFFINITY.format(
                            fid=f,
                            anti_affinity=str(anti_aff).replace("'", ""),
                        )
                    )
            parts.append("")

        node_to_pids = defaultdict(list)
        st_to_pids: Dict[Tuple[str, str], List[str]] = defaultdict(list)

        for (source, target), paths in self.candidates.items():
            for idx, path in enumerate(paths):
                pid = f"p{idx}_{source}_{target}"
                parts.append(
                    c.CANDIDATE.format(
                        pid=pid,
                        path=str(path).replace("'", ""),
                        source=source,
                        target=target,
                    )
                )
                st_to_pids[(source, target)].append(pid)
                for n in path:
                    node_to_pids[str(n)].append(pid)
        parts.append("")

        for f in self.flows:
            pids = st_to_pids.get((f.start, f.end), [])
            pids_str = ", ".join(pids)
            parts.append(f"flow_candidates({f.fid}, [{pids_str}]).")
        parts.append("")
        
        parts.append(f"timeOfDay(day).")
        parts.append("")

        with open(flows_path, "w+") as file:
            file.write("\n".join(parts))
        
    def set_energy_profiles(self):
        if "cc" not in (self.version or "").lower():
            return
        profiles_list = generate_energy_profiles(
            nodes=list(self.infrastructure.nodes()),
            random_state= self.seed
        )
        
        self.energy_profiles = {str(p.node): p for p in profiles_list}
 
    def upload_energy_profiles(self):
        if "cc" not in self.version.lower() or not self.energy_profiles:
            return

        self.set_energy_profile_file()

        energy_path = self.energy_profile_file
        energy_dir = dirname(energy_path)
        if not exists(energy_dir):
            makedirs(energy_dir)
        save_energy_profiles(self.energy_profiles.values(), energy_path)

    def upload(self):
        self.infrastructure.upload()
        self.upload_flows()
        self.upload_energy_profiles()

    def save_result(self, prologResult):
        self.result.update(prologResult)

    def stringify(self):
        return {k: str(v) for k, v in self.result.items()}

    def printResult(self, result) -> list[str]:
        lines = [
            f"Version:      {self.version}",
            f"Flows:        {result.get('Flows', '–')}",
            f"Nodes:        {result.get('Nodes', '–')}",
            f"Edges:        {result.get('Edges', '–')}",
            f"Inferences:   {result.get('Inferences', '–')}",
        ]

        t = result.get("Time", None)
        if isinstance(t, (int, float)):
            lines.append(f"Time:         {t:.4f} s")
        elif t is None:
            lines.append("Time:         –")
        else:
            lines.append(f"Time:         {t}")
        lines.append("")

        output = result.get("Output")

        if not isinstance(output, dict):
            lines.append(f"No results: {output}")
            return lines

        lines.append("Paths and Delays:")
        for (flow, pid), attr in output.items():
            lines.append(f"  Flow {flow}/{pid}:")
            path = attr.get("path")
            if path is not None:
                lines.append(f"    Path:      {path}")
            budgets = attr.get("budgets")
            if (
                isinstance(budgets, (list, tuple)) and
                len(budgets) == 2 and
                all(isinstance(b, (int, float)) for b in budgets)
            ):
                b0, b1 = budgets
                lines.append(f"    Budgets:   min={b0:.4f}, max={b1:.4f}")
            delay = attr.get("delay")
            if isinstance(delay, (int, float)):
                lines.append(f"    Delay:     {delay:.4f} ms")
        lines.append("")

        allocation = result.get("Allocation") or {}
        if isinstance(allocation, dict) and allocation:
            lines.append("Allocation (link → bandwidth):")
            for (s, d), bw in allocation.items():
                lines.append(f"  {s} → {d}: {bw} Mbps")
            lines.append("")

        if "cc" in (self.version or "").lower():
            lines.append("Node Energy and Emissions Summary:")
            node_costs = result.get("NodeCarbonCost") or []
            if node_costs:
                for entry in node_costs:
                    node = entry.get("Node", "–")
                    load = entry.get("Load", "–")
                    ce = entry.get("CarbonEmissions", None)
                    ec = entry.get("EnergyCost", None)

                    lines.append(f"  Node:              {node}")
                    lines.append(f"    Load:             {load} Mbps")
                    if isinstance(ce, (int, float)):
                        lines.append(f"    CO₂ Emissions:    {ce:.2e} kgCO₂")
                    else:
                        lines.append(f"    CO₂ Emissions:    {ce}")
                    if isinstance(ec, (int, float)):
                        lines.append(f"    Energy Cost:      {ec:.2e} €")
                    else:
                        lines.append(f"    Energy Cost:      {ec}")
                    lines.append("")
            total_carbon = result.get("TotalCarbon", None)
            total_cost = result.get("TotalCost", None)
            if total_carbon is not None:
                lines.append(f"Total Carbon(Kg): {total_carbon}")
            if total_cost is not None:
                lines.append(f"Total Cost: {total_cost}")

        if "bnbT" in (self.version or "").lower():
            count = result.get("Count", None)
            if count is not None:
                lines.append(f"Examinated Solution: {count}")

        return lines



    def __str__(self) -> str:
        return "\n".join(self.printResult(self.result))



    def calculate_candidates(self):
        paths = {
            (f.start, f.end): sorted(
                self.infrastructure.simple_paths(f.start, f.end, True), key=lambda p: len(p)
            ) for f in self.flows
        }
        self.candidates = paths

    def calculate_average_alphas(self):
        if self.energy_profiles is None:
            raise RuntimeError("Chiamami solo dopo set_energy_profiles()")
        self.average_alphas = {
            key: [
                sum(self.energy_profiles[n].alphaDay for n in path) / len(path)
                for path in paths
            ] for key, paths in self.candidates.items()
        }

    def sort_candidates_by_alpha(self):
        for key, paths in self.candidates.items():
            alphas = self.average_alphas[key]
            sorted_pairs = sorted(zip(paths, alphas), key=lambda pa: pa[1])
            self.candidates[key], self.average_alphas[key] = (
                [p for p, _ in sorted_pairs], [a for _, a in sorted_pairs]
            )
            
    def calculate_candidate_lengths(self) -> Dict[Tuple[str, str], List[int]]:
        if not hasattr(self, 'candidates') or not self.candidates:
            raise RuntimeError("Chiamami solo dopo calculate_candidates()")
        
        self.candidate_lengths: Dict[Tuple[str, str], List[int]] = {
            key: [len(path) for path in paths]
            for key, paths in self.candidates.items()
        }

    def run(self):
        self.prepare_inputs()
        self.set_flowsFileName()
        
        self.infrastructure.upload()
        if self.version and "cc" in self.version:
            self.sort_flows()
            self.calculate_candidate_lengths()
            
        self.upload_flows()
        self.upload_energy_profiles()
        
        result = self.execute_experiment()
        
        if result:
            self.save_result(result)

    def prepare_inputs(self):
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
        self.set_energy_profiles()
        self.calculate_candidates()

    def execute_experiment(self):
        cpu_start = self.process.cpu_percent(interval=None)
        self.mem_start = self.process.memory_info().rss / (1024 * 1024)
        
        result = None

        with PrologMQI() as mqi, mqi.create_thread() as prolog:
            self.consult_prolog_files(prolog)
            result = self.run_prolog_query(prolog)

        self.mem_end = self.process.memory_info().rss / (1024 * 1024)
        self.cpu = self.process.cpu_percent(interval=None) - cpu_start
        
        return result

    def consult_prolog_files(self, prolog):
                
        prolog.query(
            "consult('{}')".format(
                c.VERSION_FILE_PATH.format(version=self.version)
            )
        )

        prolog.query(f"consult('{c.SIM_FILE_PATH}')")
        prolog.query(c.LOAD_INFR_QUERY.format(path=self.infrastructure.file))
        prolog.query(c.LOAD_FLOWS_QUERY.format(path=self.flows_file))
        if "cc" in self.version:
            prolog.query(c.LOAD_ENERGY_PROFILES_QUERY.format(path=self.energy_profile_file))
            prolog.query(c.LOAD_CARBON_CREDITS_QUERY.format(path=c.CARBON_CREDITS_FILE_PATH))

    def run_prolog_query(self, prolog):        
        query = None
        
        if self.version and "ccbnb" in self.version:
            query = c.MAIN_CCBNB_QUERY
        elif self.version and "ccg" in self.version:
            query = c.MAIN_CCG_QUERY
        else:
            query = c.MAIN_QUERY
        
        prolog.query_async(query, find_all=False, query_timeout_seconds=self.timeout)
        try:
            result = prolog.query_async_result()
            
            if result:
                return self.processResult(result[0])
            else:
                return self.empty_update("no_result")
                
        except PrologQueryTimeoutError:
            return self.empty_update("timeout")
            
    def processResult(self, prologResult):
        result: Dict[str, Any] = {
            "Version": self.version,
            "Seed": self.seed,
            "RepProb": self.replica_probability,
            "Infr": self.infrastructure.name,
            "Flows": self.n_flows,
            "Nodes": len(self.infrastructure.nodes),
            "Edges": len(self.infrastructure.edges),
            "Builder": self.builder,
            "cpu": self.cpu,
            "mem_start": self.mem_start,
            "mem_end": self.mem_end,
        }

        parsed = parse_output(prologResult, version=self.version)

        result.update(parsed)

        return result

    def empty_update(self, reason: str) -> dict:
        result = {
            "Output": reason,
            "Allocation": None,
            "Inferences": None,
            "Time": self.timeout,
        }
        if "cc" in self.version:
            result.update({
                "NodeCarbonCost": [],
                "TotalCarbon": None,
                "TotalCost": None,
                "CarbonCredits": [],
            })
        return result
