#!/bin/bash -l
#SBATCH --account=pawsey0272
#SBATCH --partition=work
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=24
#SBATCH --mem=43G
#SBATCH --time=12:00:00
#SBATCH --output=image_%j.log
#SBATCH --error=image_%j.log

# source profile run in a login script 
# usually load module at the begining 
module load singularity/4.1.0-slurm
# use ramcopy for better speed 
# match CUP and memory choices 

obsnum=1447262000
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
robust=-1
# dynweight="natural"
scale=$(echo "0.6 / 157" | bc -l)

# check folder exist 



cd "${obsnum}" || exit 1


singularity exec "$GXCONTAINER" wsclean \
  -name "${obsnum}_test_r${robust}_m${msigma}_t${tsigma}" \
  -size "$imsize" "$imsize" \
  -scale "${scale}deg" \
  -weight briggs "$robust" \
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
  -data-column CORRECTED_DATA \
  "${obsnum}.ms"
