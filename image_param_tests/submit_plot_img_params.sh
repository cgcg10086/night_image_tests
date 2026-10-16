#!/bin/bash -l
#SBATCH --account=pawsey0272
#SBATCH --partition=work
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --output=plot_parameters_%j.log

set -euo pipefail

testdir="/scratch/pawsey0272/gcchen/test3_image_parameters"

singularity exec "$GXCONTAINER" python3 -u \
    "${SLURM_SUBMIT_DIR}/plot_image_parameters.py" \
    "$testdir" \
    --obs-list "${testdir}/obs_list.txt" \
    --out "${testdir}/parameter_plots" 