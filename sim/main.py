from pathlib import Path
import time
from typing import Any, Dict
import tempfile as tf

import pandas as pd
import ray
from classes.experiment import Experiment
from config import GML_CHOICES, RESULTS_DIR, TIMEOUT
from ray import train, tune


# Define the search space
param_space = {
    "timeout": 480,
    "n_flows": tune.grid_search(list(range(100, 5001, 100))),
    # "n_flows": tune.grid_search(list(range(5500, 10001, 500))),
    # "infr": tune.grid_search(GML_CHOICES),
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

    with tf.TemporaryDirectory() as tmpdir:
        e = Experiment(
            n_flows=config["n_flows"],
            infr=config["infr"],
            replica_probability=config["replica_probability"],
            seed=config["seed"],
            timeout=config["timeout"],
            experiment_dir=Path(tmpdir),
        )
        e.run()
        return e.stringify()


if __name__ == "__main__":
    config_example = {
        "timeout": 60,
        "n_flows": tune.grid_search([1000, 2, 3]),
        "infr": tune.grid_search([2, 16, 32]),
        "replica_probability": 0,
        "seed": 110396,
    }

    ray.init(address="auto")

    name = "BA-t480"

    run_config = train.RunConfig(name=name, storage_path=RESULTS_DIR)
    tuner = tune.Tuner(dglbf, param_space=param_space, run_config=run_config)

    # tuner = tune.Tuner.restore(
    #     f"/home/massa/dgLBF/sim/results/{name}",
    #     trainable=dglbf,
    #     param_space=param_space,
    #     restart_errored=True,
    # )

    results = tuner.fit()
    df = results.get_dataframe()
    df.set_index("trial_id", inplace=True)
    df.to_parquet(Path(results.experiment_path) / "results.parquet")
