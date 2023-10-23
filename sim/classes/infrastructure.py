from os import makedirs
from os.path import dirname, exists, join
from typing import Any

import config as c
import matplotlib.pyplot as plt
import networkx as nx
import numpy as np


# nx graph obtained as a barabasi albert graph
class Infrastructure(nx.DiGraph):
	def __init__(self, n: int = 2, m: int = 1, seed: Any = None):
		super().__init__(directed=True)
		self.n = n
		self.m = m
		
		g = nx.barabasi_albert_graph(n, m, seed=seed)
		self.init_nodes(g.nodes)
		self.init_links(g.edges)

		self.to_directed()
		self._size = len(self.nodes)
		self.file = c.INFRA_FILE_PATH.format(size=self._size)

	def init_nodes(self, nodes):
		for n in nodes:
			latency_budget = np.random.randint(c.NODE_LAT_MIN, c.NODE_LAT_MAX)
			self.add_node(n, latency_budget=latency_budget)

	def init_links(self, links):
		for s,d in links:
			lat = np.random.randint(c.LINK_LAT_MIN, c.LINK_LAT_MAX)
			bw = np.random.randint(c.LINK_BW_MIN, c.LINK_BW_MAX)
			self.add_edge(s, d, lat=lat, bw=bw)

	def str_nodes(self):
		return "\n".join([c.NODE.format(nid=str(n), latency_budget=a["latency_budget"]) for n, a in self.nodes(data=True)])

	def str_links(self):
		return "\n".join([c.LINK.format(source=str(s), dest=str(d), lat=a["lat"], bw=a["bw"]) for s, d, a in self.edges(data=True)])
	
	def __str__(self):
		return self.str_nodes() + "\n\n" + self.str_links() + "\n\n"
	
	def __repr__(self):
		return self.__str__()
	
	def upload(self, file=None):
		file = self.file if not file else file
		makedirs(dirname(file)) if not exists(dirname(file)) else None		
		with open(file, "w+") as f:
			f.write(str(self))
	
	def save_graph(self):
		nx.draw_networkx(self, arrows=True, with_labels=True, **c.FIG_OPTIONS)
		name = f"infrastructure_{self._size}" + c.PLOT_FORMAT
		plt.savefig(join(c.PLOTS_DIR, name), dpi=c.PLOT_DPI, format=c.PLOT_FORMAT)

	