import numpy as np
from typing import List

from classes.energyProfile import EnergyProfile

def generate_energy_profiles(
    nodes: List[str],
    capacity_min: int = 150,
    capacity_max: int = 500,
    eps_min: float = 1e-3,
    eps_max: float = 5e-3,
    t1_min: int = 1500,
    t2_max: int = 2000,
    alpha_min: float = 0.004,
    alpha_max: float = 0.90,
    cost_min: float = 0.10,
    cost_max: float = 0.30,
) -> List[EnergyProfile]:
    profiles = []
    for node in nodes:
        idle_power = np.random.uniform(capacity_min, capacity_max)
        eps = np.random.uniform(eps_min, eps_max)
        t1 = np.random.randint(t1_min, t2_max - 1)
        t2 = np.random.randint(t1 + 1, t2_max + 1)
        # Estrai alphaDay e alphaNight con alphaNight > alphaDay
        alpha_day = np.random.uniform(alpha_min, alpha_max)
        alpha_night = np.random.uniform(alpha_day, alpha_max)
        cost_kwh = np.random.uniform(cost_min, cost_max)

        profile = EnergyProfile(
            node=node,
            idle_power=idle_power,
            eps=eps,
            t1=t1,
            t2=t2,
            alphaDay=alpha_day,
            alphaNight=alpha_night,
            cost_kwh=cost_kwh,
        )
        profiles.append(profile)

    return profiles
