import tempfile as tf
from pathlib import Path
from typing import Any, Dict

import numpy as np
import pandas as pd
import ray
from classes.experiment import Experiment
from config import GML_CHOICES, RESULTS_DIR
from ray import train, tune


# Define the search space
def get_param_space():
    # n_flows = [150, 225, 300, 375, 400]
    return {
        "timeout": 1800,
        "version": tune.grid_search(["plain", "pp", "aa", "rel", "all"]),
        "builder": tune.grid_search(["barabasi_albert", "erdos_renyi"]),  # "gml",
        "n_flows": tune.grid_search(list(range(500, 10001, 500))),
        "replica_probability": tune.grid_search([0.25, 0.5, 0.75]),
        "p": 0.7,
        "n": tune.grid_search([2**i for i in range(4, 11)]),
        "seed": tune.grid_search(
            [110296, 151195, 300997, 10664, 21297, 30997, 70799, 90597, 42, 80824]
        ),
        # "n_flows": tune.grid_search(n_flows),
        # "replica_probability": 1,
        # "n": tune.sample_from(lambda spec: n_flows.index(spec.config.n_flows) + 1),
        # "gml": # tune.grid_search(GML_CHOICES)
    }


# Define tunable
def dglbf(config: Dict[str, Any]):

    with tf.TemporaryDirectory() as tmpdir:
        e = Experiment(
            n_flows=config["n_flows"],
            builder=config["builder"],
            n=config["n"],
            m=int(np.log2(config["n"])),
            p=config["p"],
            replica_probability=config["replica_probability"],
            version=config["version"],
            seed=config["seed"],
            timeout=config["timeout"],
            experiment_dir=Path(tmpdir),
            # gml=config["gml"],
        )
        e.run()
        return e.stringify()


if __name__ == "__main__":
    config_example = {
        "builder": "gml",
        "version": "aa",
        "timeout": 2,
        "n_flows": 225,
        "replica_probability": 1,
        "gml": "cev",
        "seed": 110296,
    }

    ray.init(address="auto")

    name = input("Experiment name: ")

    # run_config = train.RunConfig(name=name, storage_path=RESULTS_DIR)
    # tuner = tune.Tuner(dglbf, param_space=get_param_space(), run_config=run_config)

    tuner = tune.Tuner.restore(
        f"/home/massa/dgLBF/sim/results/{name}",
        trainable=dglbf,
        param_space=get_param_space(),
        restart_errored=True,
    )

    results = tuner.fit()
    df = results.get_dataframe()
    df.set_index("trial_id", inplace=True)
    df.to_parquet(Path(results.experiment_path) / "results.parquet")

    # print(dglbf(config_example))
