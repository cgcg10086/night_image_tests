#!/bin/bash
set -euo pipefail

obslist=$1
testdir="/scratch/pawsey0272/gcchen/test3_image_parameters/"

# submit a job for each obsnum 
while read -r obsnum || [[ -n "$obsnum" ]]; do
    [[ -n "$obsnum" ]] || continue

    echo "Submitting test_autocal for $obsnum"
    sbatch test_autocal.sh "$obsnum"
done < "${testdir}/${obslist}"