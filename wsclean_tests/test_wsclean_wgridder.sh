#!/bin/bash -l
#SBATCH --account=pawsey0272
#SBATCH --partition=work
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=55
#SBATCH --mem=100G
#SBATCH --time=12:00:00
#SBATCH --output=wgridder_%j.log
#SBATCH --error=wgridder_%j.log

module load singularity/4.1.0-slurm
module load wsclean/3.4-idg  # NEW: host WSClean with IDG support

which wsclean
wsclean -version

set -euo pipefail

robust=0 
minuv=300 
tukey=300
msigma=5
tsigma=3
basescale=0.6 # why? 
imsize=8000
datacolumn="CORRECTED_DATA"

testdir="/scratch/pawsey0272/gcchen/test2_container_update_pipeline/1447262000"
cd $testdir

basescale=0.6 # why? 
metafits="1447262000.metafits"
chan="$(singularity exec --cleanenv "$GXCONTAINER" pyhead.py -p CENTCHAN ${metafits} | awk '{print $3}')"
scale=$(echo "$basescale / $chan" | bc -l)

echo "chan=${chan}, scale=${scale}"
# scale=$(echo "0.6 / 157" | bc -l) # convert to degrees, 157 is the MWA tile size in meters? 

echo "Host: $(hostname)"
echo "CPUs: $SLURM_CPUS_PER_TASK"
echo "Memory per node (MB): $SLURM_MEM_PER_NODE"



# # test 1: small dirty image with W-Stacking gridding
# mkdir test_wgrid
# cp -a 1447262000.ms test_wgrid/
# cd test_wgrid

# # -niter 0--> no deconvolution, dirty image 
# wsclean \
#     -gridder wgridder \
#     -j "$SLURM_CPUS_PER_TASK" \
#     -size 1024 1024 \
#     -scale 0.6amin \
#     -niter 0 \
#     -name night_wgrid_test \
#     1447262000.ms

# test 2: NIHGT image parameters

mkdir test_wgrid_NIGHT
cp -a 1447262000.ms test_wgrid_NIGHT/
cd test_wgrid_NIGHT

wsclean \
  -gridder wgridder \
  -j "$SLURM_CPUS_PER_TASK" \
  -abs-mem 90 \
  -name test_wgrid_NIGHT_params \
  -size "$imsize" "$imsize" \
  -scale "${scale}deg" \
  -weight briggs "${robust}" \
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
  1447262000.ms
