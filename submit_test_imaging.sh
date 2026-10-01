#!/bin/bash
set -euo pipefail

# test_image.sh 
obslist=$1
testdir="/scratch/pawsey0272/gcchen/test3_image_parameters"
# cd testdir


robust_choices=(-2 -1.5 -1 -0.5 0 0.5) #($(seq -2 0.5 0.5)) # (seq start, step, end)
# plot uv-distribution to help choices
minuv_choices=(50 100 300 600 900) 
tukey_choices=(50 100 300 600 900)

while read -r obsnum || [[ -n "$obsnum" ]]; do
    [[ -n "$obsnum" ]] || continue

    # [@] reads each element in the array 
    for robust in "${robust_choices[@]}"; do
        for minuv in "${minuv_choices[@]}"; do
            for tukey in "${tukey_choices[@]}"; do

                # echo "Submitting test_image.sh for $obsnum" using robust="${robust}", minuv="${minuv}", inner-tukey-taper="${tukey}"
                sbatch test_image.sh "${obsnum}" "${robust}" "${minuv}" "${tukey}"
                
            done
        done
    done
    
done < "${testdir}/${obslist}"