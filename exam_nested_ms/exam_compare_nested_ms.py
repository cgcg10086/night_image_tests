#!/usr/bin/env python3
# this code is used to compare the outer and inner MSs after the nested-copy bug in autocal has been fixed. 
# It checks that the geometry of the two MSs is identical, and that the outer MS has a CORRECTED_DATA column.

from pathlib import Path

import numpy as np
from casacore.tables import table

testdir = Path("/scratch/pawsey0272/gcchen/test3_image_parameters")


def compare_column(a, b, column, tolerance):
    """Compare every row, allowing only tiny numerical differences."""
    if a.nrows() != b.nrows():
        return False

    for start in range(0, a.nrows(), 10000):
        count = min(10000, a.nrows() - start)
        x = a.getcol(column, startrow=start, nrow=count)
        y = b.getcol(column, startrow=start, nrow=count)

        if x.shape != y.shape:
            return False
        if not np.allclose(x, y, rtol=0, atol=tolerance):
            return False

    return True


for obsdir in sorted(testdir.iterdir()):
    if not obsdir.is_dir() or not obsdir.name.isdigit():
        continue

    obsnum = obsdir.name
    outer = obsdir / f"{obsnum}.ms"
    inner = outer / f"{obsnum}.ms"

    print(f"\n{obsnum}", flush=True)

    if not inner.is_dir():
        print("  No nested MS; nothing to compare.")
        continue

    try:
        with table(str(outer / "FIELD"), readonly=True, ack=False) as a, \
             table(str(inner / "FIELD"), readonly=True, ack=False) as b:

            directions_match = True
            for column in ("PHASE_DIR", "DELAY_DIR", "REFERENCE_DIR"):
                same = compare_column(a, b, column, 1e-12)
                print(f"  {column}: {'MATCH' if same else 'DIFFERENT'}")
                directions_match = directions_match and same

        with table(str(outer), readonly=True, ack=False) as a, \
             table(str(inner), readonly=True, ack=False) as b:

            uvw_match = compare_column(a, b, "UVW", 1e-6)
            print(f"  UVW: {'MATCH' if uvw_match else 'DIFFERENT'}")

            corrected_exists = "CORRECTED_DATA" in a.colnames()
            print(f"  Outer CORRECTED_DATA exists: {corrected_exists}")

        if not directions_match or not uvw_match:
            print("  REVIEW: outer and calibration-copy geometry differ.")
        elif not corrected_exists:
            print("  REVIEW: geometry matches, but CORRECTED_DATA is missing.")
        else:
            print("  MATCH: no geometry mismatch from the nested-copy bug.")

    except Exception as error:
        print(f"  ERROR: could not complete comparison: {error}")