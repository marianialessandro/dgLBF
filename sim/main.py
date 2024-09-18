from pathlib import Path
from typing import Any, Dict

import ray
from config import GML_CHOICES, RESULTS_DIR, TIMEOUT
from ray import train, tune

from classes.experiment import Experiment

# Define the search space
param_space = {
    "timeout": TIMEOUT,
    "n_flows": tune.grid_search(list(range(100, 5001, 100))),
    "infr": tune.grid_search([2**i for i in range(4, 11)]),
    "replica_probability": tune.grid_search(
        [
            0.25,
            0.5,
            0.75,
        ]
    ),
    "seed": tune.grid_search(
        [
            110396,
            151195,
            281194,
            300997,
            10664,
            21297,
            30997,
            51162,
            70799,
            90597,
        ]
    ),
}


# Define tunable
def dglbf(config: Dict[str, Any]):
    e = Experiment(
        n_flows=config["n_flows"],
        infr=config["infr"],
        replica_probability=config["replica_probability"],
        seed=config["seed"],
        timeout=config["timeout"],
    )

    e.run()
    return e.stringify()


if __name__ == "__main__":
    # config_example = {
    #     "timeout": 60,
    #     "n_flows": tune.grid_search([1, 2, 3]),
    #     "infr": 32,
    #     "replica_probability": 0.25,
    #     "seed": 110396,
    # }

    ray.init(address="auto")

    run_config = train.RunConfig(storage_path=RESULTS_DIR)
    tuner = tune.Tuner(dglbf, param_space=param_space, run_config=run_config)
    results = tuner.fit()
    df = results.get_dataframe()
    df.set_index("timestamp", inplace=True)
    df.to_csv(Path(results.experiment_path) / "results.csv")
