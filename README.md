<picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/png/logo-white.png"><img width=450 alt="dglbf-logo" src="assets/png/logo-no-background.png"/>
</picture>

<!-- Declarative implementation of guaranteed Latency Based Forwarding ([gLBF](https://link.springer.com/article/10.1007/s10922-022-09718-9)). -->

## How To &nbsp;<picture><source media="(prefers-color-scheme: dark)" srcset="https://cdn-icons-png.flaticon.com/512/2666/2666505.png"><img width="20" height="20" alt="files" src="https://cdn-icons-png.flaticon.com/512/2666/2666469.png">
</picture>

Download or clone this repo. Make sure you have the following prerequisites:

- [`swipl`](https://www.swi-prolog.org/download/stable) >= 9.0.4
- [`python`](https://www.python.org/downloads/) >= 3.8
- [`swipl MQI for Python`](https://www.swi-prolog.org/pldoc/man?section=mqi-python-installation)
- [`requirements.txt`](https://github.com/di-unipi-socc/dgLBF/blob/main/sim/requirements.txt) for the python virtual environment

1. Create a virtual environment and install the required packages:

    ```bash
    python3 -m venv venv
    source venv/bin/activate
    pip install -r sim/requirements.txt
    ```

2. Then, run the python script in the `sim` directory, after activating the virtual environment:

    ```bash
    python3 main.py [OPTIONS]
    ```

    The script runs a grid search on the parameters of the experiment, generating a random infrastructure and a random set of flows. The results are saved in a CSV file in the `results/<experiment>` directory.

    Grid parameters can be changed directly in the `main.py`, by modifying the `param_space` dictionary.
    ```

    Change the ranges of random values for both infrastructures and flows in the [`config.py`](https://github.com/di-unipi-socc/dgLBF/blob/main/sim/config.py) script.