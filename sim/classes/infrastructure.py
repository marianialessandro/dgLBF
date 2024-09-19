from os import makedirs
import os
from os.path import basename, dirname, exists, join
from typing import Any

import click
import config as c
import matplotlib.pyplot as plt
import networkx as nx
import numpy as np
import time


# nx graph obtained as a barabasi albert graph
class Infrastructure(nx.DiGraph):
    def __init__(
        self,
        n: int = 2,
        m: int = 3,
        seed: Any = None,
        gml: str = None,
        infra_path: str = c.INFRA_DIR,
    ):
        super().__init__(directed=True)
        self.n = n
        self.m = m

        if gml:
            g = nx.read_gml(c.GML_FILE_PATH.format(name=gml))
        else:
            # g = nx.barabasi_albert_graph(n, m, seed=seed)
            g = nx.gnp_random_graph(n, 0.7, seed=seed, directed=True)

        self.init_nodes(g.nodes)
        self.init_links(g.edges)
        self.to_directed()
        self.diameter = nx.diameter(self)

        self._size = len(self.nodes)
        filename = c.INFRA_FILE.format(
            name=(gml.title() if gml else self._size), seed=seed
        )
        self.file = os.path.join(infra_path, filename)
        self.name = basename(self.file).split(".")[0]

    def init_nodes(self, nodes):
        for n in nodes:
            latency_budget = np.random.randint(c.NODE_LAT_MIN, c.NODE_LAT_MAX)
            self.add_node(str(n).lower(), latency_budget=latency_budget)

    def init_links(self, links):
        for s, d in links:
            s, d = str(s).lower(), str(d).lower()
            lat = np.random.randint(c.LINK_LAT_MIN, c.LINK_LAT_MAX)
            bw = np.random.randint(c.LINK_BW_MIN, c.LINK_BW_MAX)
            rel = round(np.random.uniform(c.LINK_REL_MIN, c.LINK_REL_MAX), 4)
            self.add_edge(s, d, lat=lat, bw=bw, rel=rel)
            self.add_edge(d, s, lat=lat, bw=bw, rel=rel)

    def str_nodes(self):
        return "\n".join(
            [
                c.NODE.format(nid=str(n), latency_budget=a["latency_budget"])
                for n, a in self.nodes(data=True)
            ]
        )

    def str_links(self):
        return "\n".join(
            [
                c.LINK.format(
                    source=str(s), dest=str(d), lat=a["lat"], bw=a["bw"], rel=a["rel"]
                )
                for s, d, a in self.edges(data=True)
            ]
        )

    def __str__(self):
        res = self.str_nodes() + "\n\n"
        res += self.str_links() + "\n\n"
        return res

    def __repr__(self):
        return super().__repr__()

    def simple_paths(self, source, target, disjoint=False):
        if disjoint:
            paths = list(
                nx.node_disjoint_paths(self, source, target, cutoff=self.diameter)
            )
        else:
            paths = list(
                nx.all_simple_paths(self, source, target, cutoff=self.diameter)
            )
        # sort by number of hops between source and target
        paths.sort(key=lambda x: len(x))

        if not paths:
            print(f"No path found between {source} and {target}.")
        return paths

    def upload(self, file=None):
        file = self.file if not file else file
        makedirs(dirname(file)) if not exists(dirname(file)) else None
        with open(file, "w+") as f:
            f.write(str(self))

    def save_graph(self):
        nx.draw_networkx(self, arrows=True, with_labels=True, **c.FIG_OPTIONS)
        name = f"infrastructure_{self._size}." + c.PLOT_FORMAT
        plt.savefig(join(c.PLOTS_DIR, name), dpi=c.PLOT_DPI, format=c.PLOT_FORMAT)


@click.command()
@click.argument("nodes", type=int)
@click.option(
    "--seed", "-s", type=int, default=None, help="Seed for the random number generator."
)
def main(nodes, seed):
    infrastructure = Infrastructure(n=nodes, m=int(np.log2(nodes)), seed=seed)
    infrastructure.upload()


if __name__ == "__main__":
    main()
