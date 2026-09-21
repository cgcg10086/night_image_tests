#!/bin/bash -l
#SBATCH --account=pawsey0272
#SBATCH --partition=copy
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=10G
#SBATCH --time=01:00:00
#SBATCH --output=autoflag_%j.log
#SBATCH --error=autoflag_%j.log

obsnum=1447262000
job_id=1095163
flag_list=(76 80 156 157) # array 

if [[ -d "${job_id}" ]]
then mv "$job_id" "${obsnum}"
fi 

module load singularity/4.1.0-slurm

cd "${obsnum}" || exit 1

singularity exec "$GXCONTAINER" flagantennae "${obsnum}.ms" "${flag_list[@]}" # parse each element of flag_list 

  # -c obs_list.txt_manta.tmp \
  # -d /scratch/pawsey0272/gcchen/test2_container_single_command_tests
