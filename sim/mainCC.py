import os
import tempfile as tf
from typing import Any, Dict
from pathlib import Path

import ray
from ray import tune
from ray.air.config import RunConfig
from ray.tune import TuneConfig, FailureConfig

from config import RESULTS_DIR
from classes.experiment2 import Experiment

def get_param_space() -> Dict[str, Any]:
    return {    
        "version": tune.grid_search(["ccgp", "ccg", "ccbnb"]),
        "builder": tune.grid_search(["gml"]),
        "n_flows": tune.grid_search([50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000]),
        "seed": tune.grid_search(
            [110296, 151195, 300997, 10664, 21297, 30997, 70799, 90597, 42, 80824]
        ),
        "p": 0.7,
        "gml": None,
    }
    
def dual_ccnbt(config: Dict[str, Any]) -> None:
    with tf.TemporaryDirectory() as tmpdir:
        exp = Experiment(
            n_flows=config["n_flows"],
            builder=config["builder"],
            seed=config["seed"],
            version=config["version"],
            gml=config["gml"],
            timeout=7200,
            experiment_dir=Path(tmpdir)
        )
        
        exp.run()
        return exp.stringify()
    
if __name__ == "__main__":
    os.environ["RAY_memory_monitor_refresh_ms"] = "0"
    ray.shutdown()
    ray.init()
    resources = ray.available_resources()
        
    name = input("Experiment name: ")

    run_config = RunConfig(
        name=name,
        storage_path=RESULTS_DIR,
        failure_config=FailureConfig(
            max_failures=0,
            fail_fast=False
        ),
    )
    
    tuner = tune.Tuner(
        tune.with_resources(dual_ccnbt, {"cpu": 1}),
        param_space=get_param_space(),
        tune_config=TuneConfig(
            max_concurrent_trials=8
        ),
        run_config=run_config,
    )

    results = tuner.fit()
    df = results.get_dataframe()
    df.set_index("trial_id", inplace=True)
    df.to_parquet(Path(results.experiment_path) / f"{name}.parquet")
    
