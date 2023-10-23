from classes.experiment import Experiment
import numpy as np
from swiplserver import *
import click

TIMEOUT = 60 # seconds

@click.command()
@click.argument('nodes', type=int, default=2)
@click.argument('flows', type=int, default=1)
@click.option('--seed', '-s', type=int, default=None, help="Seed for the random number generator.")
@click.option('--timeout', '-t', type=int, default=TIMEOUT, help="Timeout for the experiment.")
def main(nodes, flows, seed, timeout):
    """ Start an experiment with an infrastructure of NODES nodes, and FLOWS flows."""

    res = []
    i = 0
    print(f"Running experiment with {nodes} nodes and {flows} flows.")
    #while not res:
    i += 1
    e = Experiment(num_nodes=nodes, num_flows=flows, seed=seed, timeout=timeout)
    e.upload()
    print(f"Running attempt {i}...")
    e.run()
    print(e)

if __name__ == '__main__':
    main()