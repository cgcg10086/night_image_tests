#!/bin/bash -l
#SBATCH --account=pawsey0272
#SBATCH --partition=work
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=55
#SBATCH --mem=100G
#SBATCH --time=12:00:00
#SBATCH --output=image_%j.log
#SBATCH --error=image_%j.log

# source profile run in a login script, not bash 
# usually load module at the begining 
module load singularity/4.1.0-slurm

set -euo pipefail

obsnum=$1
robust=$2 # test -2 to 0.5, +0.5 
minuv=$3 # baseline inner cut in \lambda 
tukey=$4 # baseline cut inner edge smoothening taper in \lambda 

testdir="/scratch/pawsey0272/gcchen/test3_image_parameters"
# testdir="/scratch/pawsey0272/gcchen/test3_image_parameters_run1_coarse"


runname="${obsnum}_robust${robust}_minuv${minuv}_tukey${tukey}"
rundir="${testdir}/$obsnum/${runname}"

tmpdir="/tmp/slurm_image_${GXUSER}_${runname}_${SLURM_JOB_ID}" # use ram copy with unique names! 

multiscale="-multiscale -mgain 0.85 -multiscale-gain 0.15" # If you really want to use multiscale.
# multiscale="-mgain 0.85" # For transient searches, we can be off with not using multiscale.

datacolumn="CORRECTED_DATA"
# WSClean suffixes for subchannels and MFS
# subchans="MFS 0000 0001 0002 0003"
# S/N Level at which to choose masked pixels for deepclean
msigma=5
# S/N Threshold at which to stop cleaning
tsigma=3
# Lowering the above values will make the cleaning more aggressive and introduce a CLEAN bias and is also computationally more expensive.

# how to choose? 
# State of play in mid-2025 -- lots of short baselines so downweight them
# telescope="MWALB"
imsize=8000
metafits="${testdir}/${obsnum}/${obsnum}.metafits"

# skip if already done without error
if [[ -f "${rundir}/imaging.done" ]]; then
    echo "Already completed: ${runname}; skipping."
    exit 0
fi

mkdir -p "${rundir}"

# dynweight="natural"
# scale=$(echo "0.6 / 157" | bc -l)
basescale=0.6 # why? 
# chan="$(singularity exec "$GXCONTAINER" pyhead.py -p CENTCHAN ${metafits} | awk '{print $3}')"
chan="$(singularity exec "$GXCONTAINER" pyhead.py -p CENTCHAN "${metafits}" | awk '{print $3}')"
scale=$(echo "$basescale / $chan" | bc -l)
echo "chan=${chan}, scale=${scale}"

# use ram copy
mkdir "${tmpdir}"
cp -rL "${testdir}/${obsnum}/${obsnum}.ms" "$tmpdir/" # -L copies the linked files to the new location, so that the MS is independent of the original MS. 
mst="${tmpdir}/${obsnum}.ms"

if [[ -L "$mst" || ! -f "$mst/table.dat" ]]; then
    echo "ERROR: temporary MS is not an independent MS directory."
    exit 1
fi

echo "Working MS: $(readlink -f "$mst")"


cd "${rundir}"

# image test: input MS is in /tmp, but output images go directly to $rundir
singularity exec "$GXCONTAINER" wsclean \
  -j "$SLURM_CPUS_PER_TASK" \
  -name "${runname}" \
  -size "$imsize" "$imsize" \
  -scale "${scale}deg" \
  -weight briggs "$robust" \
  -minuv-l "${minuv}" \
  -taper-inner-tukey "${tukey}" \
  ${multiscale} \
  -nmiter 3 \
  -niter 100000 \
  -auto-mask "$msigma" \
  -auto-threshold "$tsigma" \
  -local-rms \
  -local-rms-window 200 \
  -pol I \
  -join-channels \
  -channels-out 4 \
  -fit-spectral-pol 2 \
  -save-source-list \
  -data-column "${datacolumn}" \
  "${mst}"

# copy ram copy to rundir, then remove ram copy 
# do we still need the *.ms though? Takes too much space for parameter test. 

# echo "Copying ${obsnum}.ms from ram copy to ${rundir}/"
# mv "${mst}" "${rundir}/"
# rmdir $tmpdir # rmdir removes the directory only if it is empty

echo "For image test: did not copy ${obsnum}.ms from ram copy to ${rundir}/ to save space."
rm -rf -- "${mst}"
rmdir -- "${tmpdir}"

# add something to check if previous run compelete then skip rerun by default 
touch "${rundir}/imaging.done"