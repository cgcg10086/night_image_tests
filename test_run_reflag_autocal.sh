#!/bin/bash -l
#SBATCH --account=pawsey0272
#SBATCH --partition=work
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=64G
#SBATCH --time=12:00:00
#SBATCH --output=autocal_%j.log
#SBATCH --error=autocal_%j.log

set -euo pipefail

obsnum=$1
flags=$2

# sbatch vs bash 
# sbatch submits a new slurm job, requests resources, and returns immediately after submission.
# bash runs the code inside the current allocation and waits for it to finish.
# use bash here because want each step sequentially & one after another. 

bash "test_autoflag.sh" "$obsnum" "$flags"
bash "test_autocal.sh" "$obsnum"
echo "Can still change flag before applycal."
# bash "test_applycal.sh" "$obsnum"
# bash "test_uvflag.sh" "$obsnum"