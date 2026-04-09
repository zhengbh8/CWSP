#!/usr/bin/env python3

import argparse
import csv
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", required=True, help="Input CSV from bench_topology")
    ap.add_argument("--out", required=True, help="Output PDF path")
    args = ap.parse_args()

    csv_path = Path(args.csv)
    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    rows = []
    with csv_path.open("r", newline="") as f:
        reader = csv.DictReader(f)
        for r in reader:
            # Keep one row per dataset; if multiple runs exist, last one wins.
            rows.append(r)

    if not rows:
        raise SystemExit(f"No data rows in {csv_path}")

    # Sort by m (#edges) ascending
    def key(r):
        return int(r["m"])

    rows.sort(key=key)

    # Optionally drop tiny toy case(s) that are not part of the scaling study.
    rows = [r for r in rows if r.get("dataset") != "airport_trap"]

    labels = [r["dataset"] for r in rows]
    m_vals = [int(r["m"]) for r in rows]
    speedups = [float(r["speedup"]) for r in rows]

    fig = plt.figure(figsize=(7.0, 3.6))
    ax = fig.add_subplot(1, 1, 1)

    # Draw a light connecting line to show trend (no markers here; markers are colored scatters).
    ax.plot(m_vals, speedups, color="0.35", linewidth=1.2, zorder=1)

    ax.set_xlabel("m (number of edges in original graph)")
    ax.set_ylabel("Speedup (CPU time / GPU time)")
    ax.grid(True, linestyle="--", linewidth=0.6, alpha=0.6)

    # Avoid label overlap: put dataset names in a legend instead of annotating points.
    for x, y, lab in zip(m_vals, speedups, labels):
        ax.scatter([x], [y], s=40, label=lab, zorder=2)

    # Place legend outside the plot area to avoid covering points.
    ax.legend(loc="center left", bbox_to_anchor=(1.02, 0.5), borderaxespad=0.0, fontsize=8, frameon=False)

    fig.tight_layout()
    fig.savefig(out_path, bbox_inches="tight")
    print(f"[OK] Wrote {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
