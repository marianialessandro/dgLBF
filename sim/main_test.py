from pathlib import Path
import sys

from classes.carbonCredit import load_carbon_credits

sys.path.insert(0, str(Path(__file__).parent))

from config import CARBON_CREDITS_FILE_PATH, TEST_STANDARD_FLOWS_FILE
from classes.experiment_cev import Experiment

def main():
    # Parametri di esempio – modificali a piacere
    params = {
        "n_flows": 3,
        "builder": "gml",
        "gml": "test",
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
        prebuilt_flows_file=Path(TEST_STANDARD_FLOWS_FILE),
    )
    exp.run()
    # exp.__str__() mostra Output, Allocation, Inferences, Time
    print(exp)
    
    credits = load_carbon_credits(Path(CARBON_CREDITS_FILE_PATH))
    credits_by_id = {cc.id: cc for cc in credits}

    # Prendo i risultati
    used = exp.result.get("CarbonCredits", [])

    for entry in used:
        # entry["Credits"] è una lista [credit_id, quantity]
        creds = entry.get("Credits")
        if not isinstance(creds, (list, tuple)) or len(creds) != 2:
            print(f"Attenzione: formato entry inatteso: {entry!r}")
            continue

        credit_id, quantity = creds

        # ora credit_id è già un int (o almeno un numero)
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
    