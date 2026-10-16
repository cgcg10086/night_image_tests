#!/bin/bash -l
#SBATCH --account=pawsey0272
#SBATCH --partition=work
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=01:00:00
#SBATCH --output=aegean_%j.log
#SBATCH --error=aegean_%j.log

set -euo pipefail
module load singularity/4.1.0-slurm

image="$1"
prefix="${image%.fits}"
GXCONTAINER="/software/projects/pawsey0272/gcchen/GLEAM-X-pipeline/gleamx_container_25Sep26.img"

# completion check  
if [[ -f "${prefix}_evaluate.done" ]]; then
    echo "Already evaluated: $image"
    exit 0
fi

# Estimate background and local RMS noise
singularity exec "$GXCONTAINER" BANE \
    --cores "$SLURM_CPUS_PER_TASK" \
    "$image"

# Detect and fit sources using those maps
singularity exec "$GXCONTAINER" aegean \
    --cores "$SLURM_CPUS_PER_TASK" \
    --autoload \
    --seedclip 5 \
    --floodclip 4 \
    --table "${prefix}_sources.fits" \
    "$image"

# completion mark 
touch "${prefix}_evaluate.done"