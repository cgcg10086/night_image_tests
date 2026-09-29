#!/bin/bash -l
#SBATCH --account=pawsey0272
#SBATCH --partition=work
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=12
#SBATCH --mem=24G
#SBATCH --time=01:00:00
#SBATCH --output=applycal_%j.log
#SBATCH --error=applycal_%j.log

module load singularity/4.1.0-slurm

obsnum=$1
calfile="${obsnum}_test_solutions_ref.bin" 
# calfile="${base}/${calid}/${calid}_local_gleam_model_solutions_initial_ref.bin"
testdir="/scratch/pawsey0272/gcchen/test3_image_parameters"

cd "${testdir}/${obsnum}" || exit 1

if [[ ! -s "${calfile}" ]]
then
    echo "Could not find calibrator file ${calfile}"
    exit 1
fi

# apply to the CORRECTED_DATA column
singularity exec "$GXCONTAINER" applysolutions \
    "${obsnum}.ms" \
    "${calfile}"
