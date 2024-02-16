from glob import iglob
from os.path import join

import config as c
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
from scipy.stats import zscore

FLOWS_UNIQUE = [1, 2, 5, 10, 15, 20, 25]
FILES = list(iglob(join(c.RESULTS_DIR, "*.csv")))


def save_plot(name: str):
    plt.savefig(
        c.PLOT_PATH.format(name=name),
        dpi=c.PLOT_DPI,
        format=c.PLOT_FORMAT,
        bbox_inches="tight",
    )

    print(f"✅ {name} plot")


def remove_outliers_iqr(df, field, threshold=1.5):
    # remove outliers using IQR (interquartile range)
    q1 = df[field].quantile(0.25)
    q3 = df[field].quantile(0.75)
    iqr = q3 - q1

    lower_bound = q1 - (threshold * iqr)
    upper_bound = q3 + (threshold * iqr)

    df = df[(df[field] > lower_bound) & (df[field] < upper_bound)]
    return df


# remove outlier with scipy.stats zscore for specified column
def remove_outliers_zscore(df, field, threshold=3):
    z = np.abs(zscore(df[field]))
    df.loc[z > threshold, field] = df[field].median()
    return df


def get_95_percentile(df, field):
    q = df[field].quantile(0.95)
    df = df[df[field] < q]
    return df


def clean_data(df: pd.DataFrame):

    # remove rows with NaN Time(s)
    df = df.dropna(subset=["Time"])

    # remove Infrs that are not present in all Flows and runs
    counts = df["Infr"].value_counts()
    bound = len(FLOWS_UNIQUE) * len(FILES)
    df = df[df["Infr"].isin(counts[counts == bound].index)]

    # remove outliers
    df = remove_outliers_iqr(df, "Time")
    return df


def flows_time(df: pd.DataFrame):
    # for each "Flows" unique value make the average of only the column "Time"

    plt.figure(figsize=(10, 6))
    sns.lineplot(data=df, x="Flows", y="Time", label="Time")

    plt.legend(loc="upper left")
    plt.ylabel("Time (ms)")
    plt.xlim(0, FLOWS_UNIQUE[-1])

    save_plot("time")


def infr_flow_time(df: pd.DataFrame):

    plt.figure(figsize=(10, 6))
    df1 = df.sort_values(by=["Nodes"])
    sns.lineplot(
        data=df1,
        x="Flows",
        y="Time",
        # label=infr,
        # errorbar=None,
        hue=df1["Infr"] + "(" + df1["Nodes"].astype(str) + ")",
        palette="colorblind",
    )

    plt.legend(ncol=2)  # bbox_to_anchor=(1, 1),
    plt.ylabel("Time (ms)")
    plt.xlim(0, FLOWS_UNIQUE[-1])

    save_plot("infr-flow-time")


if __name__ == "__main__":
    # Load data
    df = pd.concat(map(pd.read_csv, FILES), ignore_index=True)
    # df = pd.read_csv(join(c.RESULTS_DIR, "results-281194.csv"))

    # Clean data
    df = clean_data(df)

    # Plot
    sns.set_theme(style="darkgrid")

    if not df.empty:
        flows_time(df)
        infr_flow_time(df)
    else:
        print("No data to plot!")
