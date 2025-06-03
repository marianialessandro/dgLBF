#!/usr/bin/env python3
import numpy as np
from pathlib import Path
import sys

import config as c
from classes.experiment import Experiment

from classes.carbonCredit import load_carbon_credits

sys.path.insert(0, str(Path(__file__).parent))

from config import CARBON_CREDITS_FILE_PATH

def main():
    n_nodes = 100
    m = int(np.log2(n_nodes))
    seed = 42
    n_flows = 5
    builder = "barabasi_albert"
    p = None
    gml = None
    experiment_dir = Path(c.DATA_DIR)

    exp = Experiment(
        n_flows=n_flows,
        builder=builder,
        n=n_nodes,
        m=m,
        p=p,
        gml=gml,
        seed=seed,
        version="cc",
        experiment_dir=experiment_dir
    )
    exp.run()

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
            f"cioè {total_co2:.2f} kg di CO₂ "
            f"(costo unitario €{cc.costo}, max quantita {cc.max_quantita})"
        )


if __name__ == "__main__":
    main()
