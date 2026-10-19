from pathlib import Path
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.colors import LogNorm

obsnum = "1447262000"
ms_path = Path(f"/scratch/pawsey0272/gcchen/test3_image_parameters/{obsnum}/{obsnum}.ms")
reference_mhz = 200.0
uvmin_choices = [0, 30, 50, 75, 100, 300, 600, 900]
chunk_rows = 1000
bin_width = 25.0                 # wavelengths; equal-width radial bins
zoom_max = 2000.0                # wavelengths
output_dir = Path(f"/scratch/pawsey0272/gcchen/test3_image_parameters/uv_plots_{obsnum}")
output_dir.mkdir(parents=True, exist_ok=True)
cache_path = output_dir / f"{obsnum}_uv_summary.npz"


# read the ms 
from casacore.tables import table

c = 299792458.0
with table(str(ms_path), readonly=True, ack=False) as ms:
    ddids = np.unique(ms.getcol("DATA_DESC_ID"))
    fields = np.unique(ms.getcol("FIELD_ID"))
    if len(ddids) != 1 or len(fields) != 1:
        raise ValueError("This notebook expects one DATA_DESC_ID and one field.")
    with table(str(ms_path / "DATA_DESCRIPTION"), readonly=True, ack=False) as dd:
        pol_id = int(dd.getcell("POLARIZATION_ID", int(ddids[0])))
        spw_id = int(dd.getcell("SPECTRAL_WINDOW_ID", int(ddids[0])))
    with table(str(ms_path / "POLARIZATION"), readonly=True, ack=False) as pol:
        corr_types = np.asarray(pol.getcell("CORR_TYPE", pol_id))
    parallel = np.flatnonzero(np.isin(corr_types, [9, 12]))  # MS codes: XX=9, YY=12
    if len(parallel) != 2:
        raise ValueError("Expected both XX and YY correlations.")
    with table(str(ms_path / "SPECTRAL_WINDOW"), readonly=True, ack=False) as spw:
        frequencies = np.asarray(spw.getcell("CHAN_FREQ", spw_id))
    print(f"MS band: {frequencies.min()/1e6:.2f}–{frequencies.max()/1e6:.2f} MHz")
    print(f"Plotting ALL coordinates at {reference_mhz:g} MHz")
    use_spectrum = ("WEIGHT_SPECTRUM" in ms.colnames()
                    and ms.iscelldefined("WEIGHT_SPECTRUM", 0))
    print("Weights:", "WEIGHT_SPECTRUM" if use_spectrum else "WEIGHT broadcast over channels")
    parts = []
    for start in range(0, ms.nrows(), chunk_rows):
        n = min(chunk_rows, ms.nrows() - start)
        uvw = ms.getcol("UVW", start, n)
        a1 = ms.getcol("ANTENNA1", start, n)
        a2 = ms.getcol("ANTENNA2", start, n)
        row_flag = ms.getcol("FLAG_ROW", start, n)
        flags = ms.getcol("FLAG", start, n)[:, :, parallel]
        if use_spectrum:
            weights = ms.getcol("WEIGHT_SPECTRUM", start, n)[:, :, parallel]
        else:
            weights = ms.getcol("WEIGHT", start, n)[:, parallel][:, None, :]
            weights = np.broadcast_to(weights, flags.shape)
        valid = (~flags) & np.isfinite(weights) & (weights > 0)
        valid &= ((a1 != a2) & ~row_flag)[:, None, None]
        counts = valid.sum(axis=(1, 2))
        row_weights = np.where(valid, weights, 0.0).sum(axis=(1, 2))
        keep = (counts > 0) & np.all(np.isfinite(uvw[:, :2]), axis=1)
        parts.append(np.column_stack((uvw[keep, 0], uvw[keep, 1],
                                      counts[keep], row_weights[keep])))
        if start % (10 * chunk_rows) == 0:
            print(f"Read {start+n:,} / {ms.nrows():,} rows", flush=True)

summary = np.concatenate(parts)
if len(summary) == 0:
    raise ValueError("No usable cross-correlation samples found.")
u = summary[:, 0] * reference_mhz * 1e6 / c
v = summary[:, 1] * reference_mhz * 1e6 / c
sample_count = summary[:, 2]
natural_weight = summary[:, 3]
np.savez_compressed(cache_path, u=u, v=v, sample_count=sample_count,
                    natural_weight=natural_weight, reference_mhz=reference_mhz,
                    obsnum=obsnum, ms_path=str(ms_path))
print(f"Saved {len(u):,} usable baseline-time rows to {cache_path}")
