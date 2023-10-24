from os.path import abspath, dirname, join
from functools import wraps
import numpy as np
import time

# --- Directories & files ---
ROOT_DIR = dirname(dirname(abspath(__file__)))
SIM_DIR = join(ROOT_DIR, "sim")
PLOTS_DIR = join(SIM_DIR, "plots")
RESULTS_DIR = join(SIM_DIR, "results")

DATA_DIR = join(SIM_DIR, "data")
FLOW_DIR = join(DATA_DIR, "flows")
INFRA_DIR = join(DATA_DIR, "infrastructures")

FLOWS_FILE = "flows{size}.pl"
INFRA_FILE = "infr{size}.pl"
FLOW_FILE_PATH = join(FLOW_DIR, FLOWS_FILE)
INFRA_FILE_PATH = join(INFRA_DIR, INFRA_FILE)

# --- Plots config ---
PLOT_FORMAT = "pdf"
PLOT_FILE = "{name}." + PLOT_FORMAT
PLOT_PATH = join(PLOTS_DIR, PLOT_FILE)
PLOT_DPI = 600

# --- Figure config ---
FIG_OPTIONS = {
    'node_size': 500,
    'width': 1,
    'arrowstyle': '-|>',
    'arrowsize': 10,
}

# --- Infrastructure config ---

NODE_LAT_MIN, NODE_LAT_MAX = 1, 10
LINK_LAT_MIN, LINK_LAT_MAX = 1, 3
LINK_BW_MIN, LINK_BW_MAX = 10, 500

# --- Flow config ---
PACKET_SIZE = 0.008
#PACKET_SIZE_MIN, PACKET_SIZE_MAX, PACKET_SIZE_STEP = 0.001, 0.01, 0.001
#PACKET_SIZE_RANGE = np.arange(PACKET_SIZE_MIN, PACKET_SIZE_MAX + PACKET_SIZE_STEP, PACKET_SIZE_STEP)
BURST_SIZE_MIN, BURST_SIZE_MAX = 2, 4
BIT_RATE_MIN, BIT_RATE_MAX = 1, 15
LATENCY_BUDGET_MIN, LATENCY_BUDGET_MAX = 50, 200
TOLERATION_THRESHOLD_MIN, TOLERATION_THRESHOLD_MAX = 1, 10 

### TEMPLATES ###

# -- Prolog Templates ---
MAIN_FILE = join(SIM_DIR, "sim.pl")
MAIN_QUERY = "once(sim_glbf(Output, Allocation, Inferences, Time))."

# --- Flow templates ---
FLOW = "flow({fid}, {start}, {end}, {packet_size}, {burst_size}, {bit_rate}, {latency_budget}, {toleration_threshold})."

# --- Infrastructure templates ---
NODE = "node({nid}, {latency_budget})."
LINK = "link({source}, {dest}, {lat}, {bw})."
DEGREE = "degree({nid}, {degree})."
MAX_DEGREE = "maxDegree({max_degree})."
MIN_DEGREE = "minDegree({min_degree})."
MAX_LATENCY = "maxLatency({max_latency})."
MIN_LATENCY = "minLatency({min_latency})."
MAX_BW = "maxBandwidth({max_bw})."
MIN_BW = "minBandwidth({min_bw})."

# --- Auxiliary function for timing ---
def timeit(func):
    @wraps(func)
    def measure_time(*args, **kwargs):
        start_time = time.time()
        result = func(*args, **kwargs)
        end_time = time.time()
        print("{} took {} seconds.".format(func.__name__, end_time - start_time))
        return result
    return measure_time
