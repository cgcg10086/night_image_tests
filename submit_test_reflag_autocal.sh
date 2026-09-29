#!/bin/bash

# flaglist is a text file. each line has:
# obsnum tile1 tile2 tile3... 

flaglist=$1
testdir="/scratch/pawsey0272/gcchen/test3_image_parameters"
code_dir="/software/projects/pawsey0272/gcchen/GLEAM-X-pipeline/test_single_task_scripts"

while read -r obsnum flags; do
    sbatch "${code_dir}/test_run_reflag_autocal.sh" "$obsnum" "$flags"
done < "${testdir}/$flaglist"