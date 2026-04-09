#!/usr/bin/env python3
import argparse
import os
import random


def main() -> int:
    ap = argparse.ArgumentParser(description="Generate directed grid_NxN .edges only (no penalties file)")
    ap.add_argument("-N", type=int, required=True, help="Grid size N")
    ap.add_argument("--out-dir", type=str, default="../data", help="Output directory")
    ap.add_argument("--seed", type=int, default=42, help="Random seed")
    ap.add_argument("--wmin", type=int, default=1, help="Min base edge weight")
    ap.add_argument("--wmax", type=int, default=5, help="Max base edge weight")
    args = ap.parse_args()

    N = args.N
    random.seed(args.seed)

    script_dir = os.path.dirname(os.path.abspath(__file__))
    out_dir = os.path.normpath(os.path.join(script_dir, args.out_dir))
    os.makedirs(out_dir, exist_ok=True)

    edges_file = os.path.join(out_dir, f"grid_{N}x{N}.edges")

    with open(edges_file, "w") as f:
        f.write(f"# N={N}, Total Nodes={N*N}\n")
        f.write("# Format: u v base_weight\n")
        for r in range(N):
            base = r * N
            for c in range(N):
                u = base + c
                # 4-neighborhood (directed)
                if r > 0:
                    v = (r - 1) * N + c
                    f.write(f"{u} {v} {random.randint(args.wmin, args.wmax)}\n")
                if c + 1 < N:
                    v = r * N + (c + 1)
                    f.write(f"{u} {v} {random.randint(args.wmin, args.wmax)}\n")
                if r + 1 < N:
                    v = (r + 1) * N + c
                    f.write(f"{u} {v} {random.randint(args.wmin, args.wmax)}\n")
                if c > 0:
                    v = r * N + (c - 1)
                    f.write(f"{u} {v} {random.randint(args.wmin, args.wmax)}\n")

    print(f"✅ generated: {edges_file}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
