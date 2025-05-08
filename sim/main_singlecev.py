# main_simple.py
from pathlib import Path
import sys


# inserisco la cartella sim/ in testa a sys.path
sys.path.insert(0, str(Path(__file__).parent))

from config import CEV_STANDARD_FLOWS_FILE
from classes.experiment_cev import Experiment

def main():
    # Parametri di esempio – modificali a piacere
    params = {
        "n_flows": 3,
        "builder": "gml",
        "gml": "cev",
        "version": "cc",
        "seed": 110296,
        "timeout": 1800,
    }
    # Usa la cartella 'sim/data' (o un'altra a piacere) come experiment_dir
    root = Path(__file__).parent
    exp_dir = root / "sim" / "data"
    
    exp = Experiment(
        n_flows=params["n_flows"],
        builder=params["builder"],
        gml=params["gml"],
        version=params["version"],
        seed=params["seed"],
        timeout=params["timeout"],
        experiment_dir=exp_dir,
        prebuilt_flows_file=Path(CEV_STANDARD_FLOWS_FILE),  # Assicurati che il file esista
    )
    exp.run()
    # exp.__str__() mostra Output, Allocation, Inferences, Time
    print(exp)

if __name__ == "__main__":
    main()
