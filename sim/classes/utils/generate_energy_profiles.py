import numpy as np
from typing import List

from classes.energyProfile import EnergyProfile

def generate_energy_profiles(
    nodes: List[str],
    capacity_min: int = 150,
    capacity_max: int = 400,
    eps_min: float = 1e-3,
    eps_max: float = 3e-3,
    t1_min: int = 5,
    t2_max: int = 30,
    alpha_min: float = 0.10,
    alpha_max: float = 0.50,
    cost_min: float = 0.10,
    cost_max: float = 0.30,
) -> List[EnergyProfile]:
    
    profiles = []
    for node in nodes:
        idle_power = np.random.uniform(capacity_min, capacity_max)
        eps = np.random.uniform(eps_min, eps_max)
        t1 = np.random.randint(t1_min, t2_max - 1)
        t2 = np.random.randint(t1 + 1, t2_max + 1)
        alpha = np.random.uniform(alpha_min, alpha_max)
        cost_kwh = np.random.uniform(cost_min, cost_max)

        profile = EnergyProfile(
            node=node,
            idle_power=idle_power,
            eps=eps,
            t1=t1,
            t2=t2,
            alpha=alpha,
            cost_kwh=cost_kwh,
        )
        profiles.append(profile)

    return profiles
