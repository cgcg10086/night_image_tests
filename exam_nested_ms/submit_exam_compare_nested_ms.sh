#!/bin/bash -l
#SBATCH --account=pawsey0272
#SBATCH --partition=work
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=10G
#SBATCH --time=1:00:00
#SBATCH --output=compare_nested_ms_%j.log
#SBATCH --error=compare_nested_ms_%j.log


singularity exec "$GXCONTAINER" python3 exam_compare_nested_ms.py \
    2>&1 | tee exam_compare_nested_ms.log