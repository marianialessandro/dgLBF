import os
from os.path import exists, dirname
from typing import List

from classes.energyProfile import EnergyProfile

def save_energy_profiles(profiles: List[EnergyProfile], output_path: str):
    if not exists(dirname(output_path)):
        os.makedirs(dirname(output_path))

    with open(output_path, "w") as f:
        for p in profiles:
            f.write(p.to_prolog() + "\n")
