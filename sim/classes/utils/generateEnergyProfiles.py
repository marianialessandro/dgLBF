import os
from os import makedirs
from os.path import exists, join
import numpy as np
import config as c

def generateEnergyProfiles(
    nodes: list[str],
    output_dir: str,
    filename: str,
    version: str,
    capacity_min: int = 150,
    capacity_max: int = 400,
    cost_min: float = 1e-3,
    cost_max: float = 3e-3,
    load_min: int = 5,
    load_max: int = 15,
    price_min: float = 0.10,
    price_max: float = 0.30,
) -> str:
    """
    Genera un file di energy profile in Prolog per un elenco di nodi.
    Restituisce il percorso completo del file scritto.
    """
    # Se la versione non è quella che ci interessa, esco subito
    if version != "cc":
        return ""
    
    # Verifico che la cartella esista (o la creo)
    if not exists(output_dir):
        makedirs(output_dir)

    file_path = join(output_dir, filename)
    with open(file_path, "w+") as f:
        for n in nodes:
            capacity = np.random.randint(capacity_min, capacity_max + 1)
            cost = np.random.uniform(cost_min, cost_max)
            cost_str = f"{cost:.1e}"
            price1 = np.random.uniform(price_min, price_max)
            price2 = np.random.uniform(price_min, price_max)
            price1_str = f"{price1:.2f}"
            price2_str = f"{price2:.2f}"

            fact = (
                f"energyProfile({n}, {capacity}, "
                f"p({cost_str}, {load_min}, {load_max}), "
                f"{price1_str}, {price2_str}).\n"
            )
            f.write(fact)

    return file_path