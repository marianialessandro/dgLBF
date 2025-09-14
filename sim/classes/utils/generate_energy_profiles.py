import numpy as np
from typing import List, Optional
from classes.energyProfile import EnergyProfile

def generate_energy_profiles(
    nodes: List[str],
    capacity_min: int = 150,
    capacity_max: int = 270,
    eps_min: float = 1e-3,
    eps_max: float = 50e-3,
    t1_min: int = 1500,
    t2_max: int = 2000,
    alpha_min: float = 0.01,
    alpha_max: float = 0.99,
    cost_min: float = 0.24,
    cost_max: float = 0.90,
    random_state: Optional[int] = None,
) -> List[EnergyProfile]:
    rng = np.random.default_rng(random_state)
    n = len(nodes)

    def lhs_uniform(low, high, n):
        edges = np.linspace(low, high, n + 1)
        vals = np.array([rng.uniform(edges[i], edges[i+1]) for i in range(n)])
        rng.shuffle(vals)
        return vals

    def beta_in_range(a, b, low, high, size):
        return low + rng.beta(a, b, size=size) * (high - low)

    # U-shape per più estremi + LHS per evitare ammassamenti
    alpha_day_vals = 0.7 * beta_in_range(0.6, 0.6, alpha_min, alpha_max, n) \
                     + 0.3 * lhs_uniform(alpha_min, alpha_max, n)
    cost_vals = 0.7 * beta_in_range(0.7, 0.7, cost_min, cost_max, n) \
                + 0.3 * lhs_uniform(cost_min, cost_max, n)

    profiles = []
    for i, node in enumerate(nodes):
        idle_power = rng.uniform(capacity_min, capacity_max)
        
        # headroom = 0.20
        # maxPower = idle_power * (1.0 + headroom)
        
        headroom = rng.uniform(0.20, 0.50)
        maxPower = idle_power * (1.0 + headroom)

        
        eps = ((capacity_max-capacity_min)/19.7)/1000
        t1 = rng.integers(t1_min, t2_max)
        t2 = rng.integers(t1 + 1, t2_max + 1)

        alpha_day = float(alpha_day_vals[i])
        alpha_night = float(rng.triangular(alpha_day, alpha_max, alpha_max))

        cost_kwh = float(cost_vals[i])

        profiles.append(EnergyProfile(
            node=node,
            idle_power=idle_power,
            maxPower=maxPower,
            eps=eps,
            t1=t1,
            t2=t2,
            alphaDay=alpha_day,
            alphaNight=alpha_night,
            cost_kwh=cost_kwh,
        ))

    return profiles

 
