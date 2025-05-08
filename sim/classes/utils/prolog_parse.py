from collections import defaultdict
from swiplserver import *

def parse_prolog(query):
    if is_prolog_functor(query):
        if prolog_name(query) != ",":
            return (prolog_name(query), parse_prolog(prolog_args(query)))
        else:
            # comma functor: flatten tuple
            return tuple(parse_prolog(arg) for arg in prolog_args(query))
    elif is_prolog_list(query):
        return [parse_prolog(v) for v in query]
    elif is_prolog_atom(query):
        return query
    elif isinstance(query, dict):
        return {k: parse_prolog(v) for k, v in query.items()}
    else:
        return query


def parse_paths(paths, include_reliability: bool = False):
    """
    Parse the Output field into a dict keyed by (flow, pid).
    If include_reliability is True, include the 'reliability' field.
    """
    result = {}
    for flow, rest in paths:
        pid, payload = rest
        path, tail = payload
        if include_reliability:
            reliability, tail2 = tail
            budgets, delay = tail2
            result[(flow, pid)] = {
                "path": path,
                "reliability": reliability,
                "budgets": budgets,
                "delay": delay,
            }
        else:
            budgets, delay = tail
            result[(flow, pid)] = {
                "path": path,
                "budgets": budgets,
                "delay": delay,
            }
    return result


def parse_allocation(raw_alloc):
    """
    Parse the Allocation field into a dict mapping (src, dst) to bandwidth.
    """
    return {(src, dst): bw for src, (dst, bw) in raw_alloc}


def parse_output(out, version: str = "plain"):
    """
    Unified parser: accepts the raw Prolog output structure `out` and returns a Python dict.
    version can be:
      - "plain": parse without reliability
      - "cc": return the raw dict (after Prolog flattening)
      - "full": parse including reliability
    """
    
    # First, convert Prolog terms into Python built-ins
    data = parse_prolog(out)

    if version == "cc":
        # For CC mode, return the flattened dict for inspection
        return data

    # Determine if we include reliability in paths
    include_rel = (version == "full")

    parsed = {
        "Output": parse_paths(data.get("Output", []), include_reliability=include_rel),
        "Allocation": parse_allocation(data.get("Allocation", [])),
        "Inferences": data.get("Inferences"),
        "Time": data.get("Time"),
    }
    return parsed
