#!/usr/bin/env python3
"""Summarize NIGHT BANE/Aegean results and plot parameter comparisons.

Requires numpy, astropy and matplotlib. Reads inputs without modifying them.
Use a single experiment root: duplicate obs/parameter combinations are rejected.
RMS is the median of finite, positive pixels over the FULL BANE map.
Counts are fitted components, not necessarily distinct or genuine sources.
"""
import argparse
import csv
import re
from collections import defaultdict
from pathlib import Path

import numpy as np
from astropy.io import fits
from astropy.table import Table
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages

PARAMS = ("robust", "minuv", "tukey")
LABELS = ("Briggs robust", "Minimum UV distance (wavelengths)",
          "Inner Tukey taper (wavelengths)")
NUMBER = r"[-+]?\d+(?:\.\d+)?"
PATTERN = re.compile(
    rf"^(?P<obsnum>\d{{10}})_robust(?P<robust>{NUMBER})"
    rf"_minuv(?P<minuv>{NUMBER})_tukey(?P<tukey>{NUMBER})-MFS-image_rms\.fits$")


def collect(args):
    wanted = None
    if args.obs_list:
        wanted = {line.split('#')[0].strip() for line in
                  args.obs_list.read_text().splitlines()}
        wanted.discard("")
    rows, seen_files, combinations, problems = [], set(), {}, []
    for path in sorted(args.testdir.rglob("*-MFS-image_rms.fits")):
        # Do not count review-folder symbolic links as new runs.
        real = path.resolve()
        # Skip older runs whose folder name ends with _SLURM_JOB_ID.
        if re.search(r"_\d+$", real.parent.name):
            continue
        
        if real in seen_files:
            continue
        seen_files.add(real)
        match = PATTERN.match(real.name)
        if not match:
            continue
        row = match.groupdict()
        if wanted is not None and row["obsnum"] not in wanted:
            continue
        for key in PARAMS:
            row[key] = float(row[key])
        key = tuple(row[k] for k in ("obsnum", *PARAMS))
        if key in combinations:
            raise ValueError(f"Duplicate combination {key}:\n{combinations[key]}\n{real}\n"
                             "Select a testdir containing only one experiment/version.")
        combinations[key] = real
        prefix = real.name.removesuffix("_rms.fits")
        # Accept both catalogue names used in the test scripts.
        cats = [real.with_name(prefix + suffix) for suffix in
                ("_sources_comp.fits", "_source_comp.fits")]
        cats = [p for p in cats if p.is_file()]
        if len(cats) != 1:
            problems.append(f"SKIP {real}: expected one catalogue, found {len(cats)}")
            continue
        try:
            with fits.open(real, memmap=True) as hdus:
                unit = str(hdus[0].header.get("BUNIT", "")).lower().replace(" ", "")
                if unit not in ("jy/beam", "jybeam-1", "jybeam^-1"):
                    raise ValueError(f"Expected BUNIT Jy/beam; found {unit!r}")
                data = hdus[0].data
                good = np.isfinite(data) & (data > 0)
                values = data[good]
                if not values.size:
                    raise ValueError("No finite positive RMS pixels")
                row["rms_mjy_beam"] = float(np.median(values) * 1000)
                row["valid_rms_fraction"] = float(values.size / data.size)
            cat = Table.read(cats[0])
            row["n_components_all"] = len(cat)
            if "flags" not in cat.colnames:
                raise ValueError("Catalogue has no flags column")
            row["n_components_flags0"] = int(np.count_nonzero(
                np.ma.filled(cat["flags"] == 0, False)))
            row["rms_file"] = str(real)
            row["catalogue_file"] = str(cats[0])
            rows.append(row)
            print(f"{row['obsnum']} robust={row['robust']:g} minuv={row['minuv']:g} "
                  f"tukey={row['tukey']:g}: RMS={row['rms_mjy_beam']:.3f} mJy/beam, "
                  f"flags=0 components={row['n_components_flags0']}", flush=True)
        except Exception as exc:
            problems.append(f"SKIP {real}: {exc}")
    if wanted is not None:
        for obs in sorted(wanted - {r['obsnum'] for r in rows}):
            problems.append(f"NO COMPLETE RESULTS for {obs}")
    (args.out / "skipped_files.txt").write_text("\n".join(problems) + "\n")
    for problem in problems:
        print(problem, flush=True)
    return rows


def plot_observation(rows, obs, count_key, x_limits):
    fig, axes = plt.subplots(2, 3, figsize=(15, 8), constrained_layout=True)
    for col, (param, label) in enumerate(zip(PARAMS, LABELS)):
        other = [p for p in PARAMS if p != param]
        groups = defaultdict(list)
        for row in rows:
            groups[tuple(row[p] for p in other)].append(row)
        for axis, metric in zip(axes[:, col], ("rms_mjy_beam", count_key)):
            for group in groups.values():
                group = sorted(group, key=lambda r: r[param])
                axis.plot([r[param] for r in group], [r[metric] for r in group],
                          color="0.65", linewidth=0.6, alpha=0.5)
            axis.scatter([r[param] for r in rows], [r[metric] for r in rows],
                         s=13, alpha=0.5, color="tab:blue")
            xs = sorted({r[param] for r in rows})
            ys = [np.median([r[metric] for r in rows if r[param] == x]) for x in xs]
            axis.plot(xs, ys, "o-", color="tab:orange", linewidth=2,
                      label="Median over other settings")
            axis.set_xlabel(label)
            axis.set_xticks(xs)
            if param in x_limits:
                axis.set_xlim(*x_limits[param])
            elif param in ("minuv", "tukey") and param + "_max" in x_limits:
                axis.set_xlim(right=x_limits[param + "_max"])
            axis.grid(alpha=0.2)
        axes[0, col].set_ylabel("Median map RMS (mJy/beam)")
        axes[1, col].set_ylabel("Components (flags = 0)" if count_key.endswith("flags0")
                                else "All catalogue components")
    axes[0, 0].legend(fontsize=8)
    fig.suptitle(f"Observation {obs} — {len(rows)} evaluated combinations\n"
                 "Points: individual runs; grey lines: other two parameters fixed. "
                 "Full-image statistics.", fontsize=12)
    return fig


def main():
    parser = argparse.ArgumentParser(
        description=__doc__,
        epilog=("Use a FITS experiment directory to extract results and save a summary "
                "CSV, then use --from-csv with that CSV for later plots."))
    parser.add_argument(
        "testdir", type=Path, nargs="?",
        help="Root of ONE imaging experiment (extract results from FITS files)")
    parser.add_argument("--obs-list", type=Path, help="Optional one-observation-per-line file")
    parser.add_argument("--out", type=Path, default=Path("parameter_plots"))
    parser.add_argument("--all-components", action="store_true", help="Include nonzero fitting flags")
    parser.add_argument(
        "--robust-range", type=float, nargs=2, metavar=("MIN", "MAX"),
        help="Limit the Briggs robust x-axis to this range")
    parser.add_argument(
        "--minuv-max", type=float, metavar="MAX",
        help="Show minimum-UV x-axis values up to this maximum")
    parser.add_argument(
        "--summary", "--from-csv", dest="summary", type=Path,
        help="Plot from an existing summary CSV without reading FITS files")
    args = parser.parse_args()
    if args.robust_range is not None and args.robust_range[0] >= args.robust_range[1]:
        parser.error("--robust-range MIN must be less than MAX")
    if (args.testdir is None) == (args.summary is None):
        parser.error("provide exactly one input: a FITS experiment directory or --from-csv CSV")
    if args.summary is not None and not args.summary.is_file():
        parser.error(f"Summary CSV does not exist or is not a file: {args.summary}")

    args.out.mkdir(parents=True, exist_ok=True)
    if args.summary:
        with args.summary.open(newline="") as handle:
            rows = list(csv.DictReader(handle))
        for row in rows:
            for key in (*PARAMS, "rms_mjy_beam", "valid_rms_fraction"):
                row[key] = float(row[key])
            for key in ("n_components_all", "n_components_flags0"):
                row[key] = int(row[key])
    else:
        if not args.testdir.is_dir():
            parser.error(f"Directory does not exist: {args.testdir}")
        rows = collect(args)
    if not rows:
        raise SystemExit("No complete results found. Check filenames and skipped_files.txt.")
    with (args.out / "image_parameter_summary.csv").open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    count_key = "n_components_all" if args.all_components else "n_components_flags0"
    x_limits = {}
    if args.robust_range is not None:
        x_limits["robust"] = args.robust_range
    if args.minuv_max is not None:
        x_limits["minuv_max"] = args.minuv_max
    with PdfPages(args.out / "all_observations.pdf") as pdf:
        for obs in sorted({r["obsnum"] for r in rows}):
            subset = [r for r in rows if r["obsnum"] == obs]
            fig = plot_observation(subset, obs, count_key, x_limits)
            fig.savefig(args.out / f"{obs}_parameters.png", dpi=160)
            pdf.savefig(fig)
            plt.close(fig)
    print(f"Saved {len(rows)} runs to {args.out.resolve()}")


if __name__ == "__main__":
    main()
