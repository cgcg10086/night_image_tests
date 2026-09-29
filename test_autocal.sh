#!/bin/bash -l
#SBATCH --account=pawsey0272
#SBATCH --partition=work
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=64G
#SBATCH --time=12:00:00
#SBATCH --output=autocal_%j.log
#SBATCH --error=autocal_%j.log

module load singularity/4.1.0-slurm
set -euo pipefail

obsnum=$1
refant="${2:-}" # optional variable 
solutions="${obsnum}_test_solutions.bin"
backup="${obsnum}.ms_backup" # keep an original copy in tests 

testdir="/scratch/pawsey0272/gcchen/test3_image_parameters"
tmpdir="/tmp/slurm_autocal_${GXUSER}_${obsnum}_${SLURM_JOB_ID}" # use a job-specific directory 
# base=/scratch/pawsey0272/gcchen

set -x
cd "${testdir}/${obsnum}" || exit 1

# correct previous error 
if [[ ! -d "${obsnum}.ms" && -d "${backup}" ]]; then
    cp -r "${backup}" "${obsnum}.ms" 
fi

# backup original copy 
if [[ ! -d "${backup}" ]]; then
    echo "create a backup copy ${backup}..."
    cp -r "${obsnum}.ms" ${backup}
fi 

# use ram copy
mkdir -p $tmpdir
cp -rf "${obsnum}.ms" "${tmpdir}"
mst="$tmpdir/${obsnum}.ms"

# Inspect the phase centre and any existing shift.
current=$(singularity exec "$GXCONTAINER" chgcentre "$mst") || exit 1
echo "$current"

# Undo the special shift detected by the template before calibration.
if [[ "$current" == *shift* ]]; then
    coords=$(singularity exec "$GXCONTAINER" \
        calc_optimum_pointing.py \
        --metafits "${obsnum}.metafits") || exit 1

    singularity exec "$GXCONTAINER" chgcentre "$mst" $coords || exit 1
fi

# singularity exec "$GXCONTAINER" chgcentre "${mst}"

# refernece antenna: $2 or select any working one 
if [[ -z "${refant}" ]]; then
refant=$(
    singularity exec "$GXCONTAINER" python3 - "${obsnum}.metafits" <<'PY'
import sys
import numpy as np
from astropy.io import fits

with fits.open(sys.argv[1]) as hdus:
    tiles = hdus["TILEDATA"].data
    print(tiles["Antenna"][tiles["Flag"] == 0][0])
PY
) || exit 1
fi

# main calibration
singularity exec "$GXCONTAINER" hyperdrive \
    di-calibrate \
    --uvw-min 75lambda \
    --max-iterations 500 \
    --num-sources 500 \
    --uvw-max 1667lambda \
    --beam-file "${GXMWAPB}/mwa_full_embedded_element_pattern.h5" \
    --outputs "$solutions" \
    -d "${mst}" "${obsnum}.metafits" \
    -s "${GXSHARE}/sky_models/GGSM.txt"

if [[ $? -ne 0 ]]; then
    exit 1
fi

# Phase-reference correction? I don't understand. 
# divide all amp by refant's amp? set refant phase = 0? 
# see MWA wiki: how to deine --xy and --dxy values? 
singularity run ${GXCONTAINER} aocal_phaseref.py \
    "${solutions}" "${solutions%.bin}_ref.bin" "${refant}" \
    --xy -2.806338586067941065e+01 \
    --dxy -4.426533296449057023e-07 \
    --ms "${obsnum}.ms"

# plot phase-referred solutions
singularity run $GXCONTAINER hyperdrive \
    solutions-plot \
    --ref-tile ${refant} \
    --max-amp 2 \
    -m ${obsnum}.metafits \
    "${solutions%.bin}_ref.bin"

    # "${solutions}" # if cannot create "${solutions%.bin}_ref.bin", plot "${solutions}"


# remove ram copy 
# cp -rf "${mst}/." "${obsnum}.ms/" # overwrites matching files but does not remove extra files already in the destination
cp -r ${mst} ${obsnum}.ms
rm -r $tmpdir
