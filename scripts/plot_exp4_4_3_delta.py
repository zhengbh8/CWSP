#!/usr/bin/env python3

import argparse
import csv
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", required=True)
    ap.add_argument("--out", required=True, help="Output PNG")
    args = ap.parse_args()

    rows = []
    with open(args.csv, "r", newline="") as f:
        reader = csv.DictReader(f)
        for r in reader:
            rows.append(r)

    if not rows:
        raise SystemExit("No rows")

    rows.sort(key=lambda r: int(r["delta"]))
    deltas = [int(r["delta"]) for r in rows]
    times = [float(r["gpu_ms"]) for r in rows]

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    fig = plt.figure(figsize=(6.0, 3.2))
    ax = fig.add_subplot(1, 1, 1)

    ax.plot(deltas, times, marker="o", linewidth=1.6)
    ax.set_xlabel(r"$\Delta$")
    ax.set_ylabel("GPU time (ms)")
    ax.grid(True, linestyle="--", linewidth=0.6, alpha=0.6)

    fig.tight_layout()
    fig.savefig(out_path, dpi=200, bbox_inches="tight")
    print(f"[OK] Wrote {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
