#!/bin/bash -l
#SBATCH --account=pawsey0272
#SBATCH --partition=work
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=64G
#SBATCH --time=12:00:00
#SBATCH --output=prepare_%A_%a.log
#SBATCH --error=prepare_%A_%a.log

set -euo pipefail

# what is this code for? 

obsfile="$1"
scriptdir="$2"

obsnum=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$obsfile")
[[ -n "$obsnum" ]] || { echo "Missing observation ID"; exit 1; }

bash "${scriptdir}/test_autoflag.sh" "$obsnum"
bash "${scriptdir}/test_autocal.sh" "$obsnum"

echo "autoflag and autocal completed for $obsnum"