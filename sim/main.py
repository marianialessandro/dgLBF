import click
import config as c
from classes.experiment import Experiment
from click_option_group import RequiredMutuallyExclusiveOptionGroup, optgroup
from swiplserver import *


@click.command()
@click.option('--flows', '-f', type=int, required=True, help="Number of flows in the experiment.")
@optgroup.group('Infrastructure', cls=RequiredMutuallyExclusiveOptionGroup, help="How to create the infrastructure (from gml or not).")
@optgroup.option('--nodes', '-n', type=int, help="Number of nodes in the infrastructure.")
@optgroup.option('--gml', '-g', type=click.Choice(c.GML_CHOICES), default=None, help="Name of a GML file (in data/gml) to use as infrastructure.")
@click.option('--seed', '-s', type=int, default=None, help="Seed for the random number generator.")
@click.option('--timeout', '-t', type=int, default=c.TIMEOUT, help="Timeout for the experiment.")
def main(flows, nodes, seed, timeout, gml):
    """ Start an experiment with an infrastructure of NODES nodes, and FLOWS flows."""

    e = Experiment(num_nodes=nodes, num_flows=flows, seed=seed, timeout=timeout, gml=gml)
    print(f"Running experiment with {len(e.infrastructure.nodes)} nodes, {len(e.infrastructure.edges)} edges and {flows} flows.")
    e.upload()
    e.run()
    print(e)

if __name__ == '__main__':
    main()