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

obsnum=$1
testdir="/scratch/pawsey0272/gcchen/test3_image_parameters/"

singularity exec "$GXCONTAINER" mwa_client \
  -c obs_list.txt_manta.tmp \
  -d /scratch/pawsey0272/gcchen/${testdir}

jobid=$(find ${testdir} -name "${obsnum}.ms" -type d) # obs_data_ms will be ${testdir}/${jobid}/${obsnum}.ms if the download was successful, or empty if not
mv "${testdir}/${jobid}" "${testdir}/{obsnum}" # change folder name from jobid to obsnum 

# print to download_done.txt
