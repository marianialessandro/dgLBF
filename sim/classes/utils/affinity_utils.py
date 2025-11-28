import math, random
from itertools import combinations
from collections import defaultdict

def get_anti_affinity(flow_ids):

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