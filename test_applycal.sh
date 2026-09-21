#!/bin/bash -l
#SBATCH --account=pawsey0272
#SBATCH --partition=copy
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=24G
#SBATCH --time=01:00:00
#SBATCH --output=applycal_%j.log
#SBATCH --error=applycal_%j.log

obsnum=1447262000
calfile="${obsnum}_test_solutions.bin" 

# check folder exist 

module load singularity/4.1.0-slurm

cd "${obsnum}" || exit 1

if [[ ! -s "${calfile}" ]]
then
    echo "Could not find calibrator file ${calfile}"
    exit 1
fi

singularity exec "$GXCONTAINER" applysolutions \
    ${obsnum}.ms \
    "${calfile}"
