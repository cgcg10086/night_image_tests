#!/bin/bash -l
#SBATCH --account=pawsey0272
#SBATCH --partition=copy
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=10G
#SBATCH --time=08:00:00
#SBATCH --output=squid_%j.log
#SBATCH --error=squid_%j.log

obsnum=1379799704

module load singularity/4.1.0-slurm

echo "Working directory: $PWD"
echo "Container: $GXCONTAINER"
echo "Observation: $obsnum"
set -x

singularity exec "$GXCONTAINER" giant-squid submit-conv \
	-p 'avg_time_res=4,avg_freq_res=160,flag_edge_width=80,output=ms' \
	-d 'scratch' \
	"${obsnum}"
