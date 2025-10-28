from typing import List, Optional
import numpy as np
from classes.energyProfile import EnergyProfile

BASE_PROFILES = [
    {"idle_power": 1099, "maxPower": 1500, "eps": 0.8},
    {"idle_power": 300, "maxPower": 500, "eps": 1.02},
    {"idle_power": 200, "maxPower": 300, "eps": 0.85},
    {"idle_power": 150, "maxPower": 310, "eps": 4.10},
    {"idle_power": 275, "maxPower": 650, "eps": 19.04},
    {"idle_power": 245, "maxPower": 250, "eps": 0.25},
    {"idle_power": 89, "maxPower": 650, "eps": 28.48},
    {"idle_power": 82, "maxPower": 250, "eps": 8.53},
    {"idle_power": 35, "maxPower": 100, "eps": 17.11},
    {"idle_power": 33, "maxPower": 100, "eps": 17.63},
]

def generate_energy_profiles(
    nodes: List[str],
    alpha_min: float = 0.01,
    alpha_max: float = 0.99,
    cost_min: float = 0.24,
    cost_max: float = 0.90,
    random_state: Optional[int] = None,
) -> List[EnergyProfile]:
    if not BASE_PROFILES:
        raise ValueError("BASE_PROFILES non può essere vuoto.")
    nbase = len(BASE_PROFILES)

    rng = np.random.default_rng(random_state)
    n = len(nodes)

    indices = rng.integers(0, nbase, size=n)

    def sample_alpha_day():
        a = alpha_min + rng.beta(0.6, 0.6) * (alpha_max - alpha_min)
        b = rng.uniform(alpha_min, alpha_max)
        return float(0.7 * a + 0.3 * b)

    def sample_cost():
        c = cost_min + rng.beta(0.7, 0.7) * (cost_max - cost_min)
        d = rng.uniform(cost_min, cost_max)
        return float(0.7 * c + 0.3 * d)

    profiles: List[EnergyProfile] = []
    for i, node in enumerate(nodes):
        base = BASE_PROFILES[int(indices[i])]
        
        alpha_day = sample_alpha_day()
        alpha_night = float(rng.triangular(alpha_day, alpha_max, alpha_max))
        cost_kwh = sample_cost()

        profiles.append(EnergyProfile(
            node=node,
            idle_power=float(base["idle_power"]),
            maxPower=float(base["maxPower"]),
            eps=base["eps"],
            alphaDay=alpha_day,
            alphaNight=alpha_night,
            cost_kwh=cost_kwh,
        ))

    return profiles
