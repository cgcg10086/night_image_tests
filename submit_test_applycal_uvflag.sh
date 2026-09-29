#!/bin/bash 

obslist=$1
testdir="/scratch/pawsey0272/gcchen/test3_image_parameters"
code_dir="/software/projects/pawsey0272/gcchen/GLEAM-X-pipeline/test_single_task_scripts"

while read -r obsnum || [[ -n "$obsnum" ]]; do
    sbatch "${code_dir}/test_run_applycal_uvflag.sh" "$obsnum" # "$flags"
done < "${testdir}/${obslist}"