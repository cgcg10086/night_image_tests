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

runname="${obsnum}_robust${robust}_minuv${minuv}_tukey${tukey}"
rundir="${testdir}/${runname}"

tmpdir="/tmp/slurm_image_${GXUSER}_${runname}_${SLURM_JOB_ID}" # use ram copy with unique names! 

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
basescale=0.6
imsize=8000

# dynweight="natural"
scale=$(echo "0.6 / 157" | bc -l)

# use ram copy
mkdir -p $tmpdir
cp -rf "${testdir}/${obsnum}/${obsnum}.ms" "$tmpdir/"
mst="${tmpdir}/${obsnum}.ms"

mkdir "${rundir}"
cd "${rundir}"

# image test: input MS is in /tmp, but output images go directly to $rundir
singularity exec "$GXCONTAINER" wsclean \
  -j "$SLURM_CPUS_PER_TASK" \
  -name "${runname}" \
  -size "$imsize" "$imsize" \
  -scale "${scale}deg" \
  -weight briggs "$robust" \
  -minuv-l ${minuv} \
  -taper-inner-tukey ${tukey} \
  -mgain 0.85 \
  -nmiter 3 \
  -niter 10000000 \
  -auto-mask "$msigma" \
  -auto-threshold "$tsigma" \
  -pol I \
  -join-channels \
  -channels-out 4 \
  -fit-spectral-pol 2 \
  -save-source-list \
  -data-column ${datacolumn} \
  "${mst}"

# copy ram copy to rundir, then remove ram copy 
# do we still need the *.ms though? 
echo "Copying ${obsnum}.ms from ram copy to ${rundir}/"
mv "${mst}" "${rundir}/"
rmdir $tmpdir # rmdir removes the directory only if it is empty

# add something to check if previous run compelete then skip re-run by default 
touch "${rundir}/imaging.done"