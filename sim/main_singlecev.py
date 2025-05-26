# main_simple.py
from pathlib import Path
import sys

from classes.carbonCredit import load_carbon_credits

# inserisco la cartella sim/ in testa a sys.path
sys.path.insert(0, str(Path(__file__).parent))

from config import CARBON_CREDITS_FILE_PATH, CEV_STANDARD_FLOWS_FILE
from classes.experiment_cev import Experiment

def main():
    params = {
        "n_flows": 3,
        "builder": "gml",
        "gml": "cev",
        "version": "cc",
        "seed": 110296,
        "timeout": 1800,
    }
    
    exp = Experiment(
        n_flows=params["n_flows"],
        builder=params["builder"],
        gml=params["gml"],
        version=params["version"],
        seed=params["seed"],
        timeout=params["timeout"],
        prebuilt_flows_file=Path(CEV_STANDARD_FLOWS_FILE),
    )
    exp.run()
    print(exp)
    
    credits = load_carbon_credits(Path(CARBON_CREDITS_FILE_PATH))
    credits_by_id = {cc.id: cc for cc in credits}

    used = exp.result.get("CarbonCredits", [])

    for entry in used:
        creds = entry.get("Credits")
        if not isinstance(creds, (list, tuple)) or len(creds) != 2:
            print(f"Attenzione: formato entry inatteso: {entry!r}")
            continue

        credit_id, quantity = creds

        cc = credits_by_id.get(credit_id)
        if cc is None:
            print(f"Attenzione: nessun CarbonCredit trovato per ID {credit_id}")
            continue

        total_co2 = quantity * cc.co2
        print(
            f"Servono {quantity} crediti (ID {credit_id}), "
            f"cioè {total_co2:.2f} t di CO₂ "
            f"(costo unitario €{cc.costo}, max quantita {cc.max_quantita})"
        )
        
if __name__ == "__main__":
    main()
