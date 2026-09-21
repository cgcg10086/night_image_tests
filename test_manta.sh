#!/bin/bash -l
#SBATCH --account=pawsey0272
#SBATCH --partition=copy
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=10G
#SBATCH --time=08:00:00
#SBATCH --output=manta_%j.log
#SBATCH --error=manta_%j.log

module load singularity/4.1.0-slurm

singularity exec "$GXCONTAINER" mwa_client \
  -c obs_list.txt_manta.tmp \
  -d /scratch/pawsey0272/gcchen/test2_container_single_command_tests
