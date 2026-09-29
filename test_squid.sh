#!/bin/bash -l
#SBATCH --account=pawsey0272
#SBATCH --partition=copy
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=10G
#SBATCH --time=08:00:00
#SBATCH --output=log_single_line_scripts/squid_%j.log
#SBATCH --error=log_single_line_scripts/squid_%j.log

module load singularity/4.1.0-slurm

obsnum=$1
testdir="/scratch/pawsey0272/gcchen/test3_image_parameters"

downloaddir="/scratch/mwasci/asvo/" # giant-squid default 

echo "Working directory: $testdir"
echo "Container: $GXCONTAINER"

set -x
singularity exec "$GXCONTAINER" giant-squid submit-conv \
--wait \
	-p 'avg_time_res=4,avg_freq_res=160,flag_edge_width=80,output=ms' \
	-d 'scratch' \
	"${obsnum}"

obs_data_ms=$(find ${downloaddir} -name "${obsnum}.ms" -type d) # obs_data_ms will be ${testdir}/${jobid}/${obsnum}.ms if the download was successful, or empty if not
mv $(dirname ${obs_data_ms}) ${testdir} # move download folder from the default path to the test path   
mv "${testdir}/${obs_data_ms}" "${testdir}/{obsnum}" # change folder name from jobid to obsnum 