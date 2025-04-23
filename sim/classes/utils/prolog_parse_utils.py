from collections import defaultdict
from swiplserver import *

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


def parse_paths(paths):
    return {
        (flow, pid): {
            "path": path,
            "reliability": reliability,
            "budgets": budgets,
            "delay": delay,
        }
        for (flow, (pid, (path, (reliability, (budgets, delay))))) in paths
    }


def parse_paths_no_reliability(paths):
    return {
        (flow, pid): {
            "path": path,
            "budgets": budgets,
            "delay": delay,
        }
        for (flow, (pid, (path, (budgets, delay)))) in paths
    }


def parse_allocation(allocation):
    return {(s, d): bw for (s, (d, bw)) in allocation}


def parse_output(out, plain=True):
    o = parse_prolog(out)
    return {
        "Output": (
            parse_paths_no_reliability(o["Output"])
            if plain
            else parse_paths(o["Output"])
        ),
        "Allocation": parse_allocation(o["Allocation"]),
        "Inferences": o["Inferences"],
        "Time": o["Time"],
    }
