from classes.experiment import Experiment
import numpy as np
from swiplserver import *
import click
from click_option_group import optgroup, RequiredMutuallyExclusiveOptionGroup

TIMEOUT = 60 # seconds

@click.command()
@click.argument('flows', type=int, default=1)
@optgroup.group('Infrastructure', cls=RequiredMutuallyExclusiveOptionGroup, help="How to create the infrastructure (from gml or not).")
@optgroup.option('--nodes', '-n', type=int, default=2, help="Number of nodes in the infrastructure.")
@optgroup.option('--gml', '-g', type=str, default=None, help="Name of a GML file (in data/gml) to use as infrastructure.")
@click.option('--seed', '-s', type=int, default=None, help="Seed for the random number generator.")
@click.option('--timeout', '-t', type=int, default=TIMEOUT, help="Timeout for the experiment.")
def main(nodes, flows, seed, timeout, gml):
    """ Start an experiment with an infrastructure of NODES nodes, and FLOWS flows."""

    e = Experiment(num_nodes=nodes, num_flows=flows, seed=seed, timeout=timeout, gml=gml)
    e.infrastructure.save_graph()
    print(f"Running experiment with {len(e.infrastructure.nodes)} nodes, {len(e.infrastructure.edges)} edges and {flows} flows.")
    e.upload()
    e.run()
    print(e)

if __name__ == '__main__':
    main()