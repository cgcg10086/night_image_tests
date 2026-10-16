#!/bin/bash -l
#SBATCH --account=pawsey0272
#SBATCH --partition=work
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=55
#SBATCH --mem=100G
#SBATCH --time=12:00:00
#SBATCH --output=idg_%j.log
#SBATCH --error=idg_%j.log

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

# # test 1: small dirty image with IDG gridding
# mkdir test_idg
# cp -a 1447262000.ms test_idg/
# cd test_idg

# # -niter 0--> no deconvolution, dirty image 
# wsclean \
#     -gridder idg \
#     -idg-mode cpu \
#     -j "$SLURM_CPUS_PER_TASK" \
#     -size 1024 1024 \
#     -scale 0.6amin \
#     -niter 0 \
#     -name test_idg_small_dirty \
#     1447262000.ms

# test 2: NIHGT image parameters

mkdir test_idg_NIGHT
cp -a 1447262000.ms test_idg_NIGHT/
cd test_idg_NIGHT

wsclean \
  -gridder idg \
  -idg-mode cpu \
  -j "$SLURM_CPUS_PER_TASK" \
  -abs-mem 90 \
  -name test_idg_NIGHT_params \
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


# image.tmpl 
#   wsclean \
#     -abs-mem "${PROGMEMORY}" \
#     "${multiscale}" \
#     "${scalebias}" \
#     -nmiter 3 \
#     -niter 10000000 \
#     -reuse-primary-beam \
#     -apply-primary-beam \
#     -auto-mask "${msigma}" \
#     -auto-threshold "${tsigma}" \
#     -name "${obsid}_deep" \
#     -size "${imsize}" "${imsize}" \
#     -scale "${scale:0:8}" \
#     -weight briggs "${robust}" \
#     -pol I \
#     -join-channels \
#     -channels-out 4 \
#     -save-source-list \
#     -fit-spectral-pol 2 \
#     -data-column "${datacolumn}" \
#     "${ms}" | tee wsclean.log