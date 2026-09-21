#!/bin/bash -l
#SBATCH --account=pawsey0272
#SBATCH --partition=copy
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=24
#SBATCH --mem=43G
#SBATCH --time=12:00:00
#SBATCH --output=autocal_%j.log
#SBATCH --error=autocal_%j.log

# use ram copy 
# update refant 

module load singularity/4.1.0-slurm

obsnum=1447262000
solutions="${obsnum}_test_solutions.bin"

# select any working antenna (read from meta? python) 
refant=21



# if [[ -d "${obsnum}" ]]
# then 
# else
# fi 


cd "${obsnum}" || exit 1

pwd
ls -ld "${obsnum}.ms"
ls -lh "${obsnum}.ms/table.dat"
set -x
base=/scratch/pawsey0272/gcchen

for project in test2_container_single_command_tests test2_container_15Sep26_pipeline; do
    echo "Checking $project"
    singularity exec "$GXCONTAINER" chgcentre \
        "$base/$project/1447262000/1447262000.ms"
done
# current=$(singularity exec "$GXCONTAINER" chgcentre "${obsnum}.ms") || exit 1

# if [[ "$current" == *shift* ]]; then
#     coords=$(singularity exec "$GXCONTAINER" calc_optimum_pointing.py \
#         --metafits "${obsnum}.metafits") || exit 1

#     singularity exec "$GXCONTAINER" chgcentre \
#         "${obsnum}.ms" $coords || exit 1
# fi

# calibrate 
singularity exec "$GXCONTAINER" hyperdrive \
    di-calibrate \
    --uvw-min 75lambda \
    --max-iterations 500 \
    --num-sources 500 \
    --uvw-max 1667lambda \
    --beam-file "${GXMWAPB}/mwa_full_embedded_element_pattern.h5" \
    --outputs "$solutions" \
    -d "${obsnum}.ms" "${obsnum}.metafits" \
    -s "${GXBASE}/models/GGSM.txt"

if [[ $? -ne 0 ]]; then
    exit 1
fi

# plot calibration solutions
singularity run $GXCONTAINER hyperdrive \
    solutions-plot \
    --max-amp 2 \
    -m ${obsnum}.metafits \
    "${solutions}" 



# autocal.tmpl 
# singularity exec "$GXCONTAINER" hyperdrive di-calibrate \
#   --uvw-min 75lambda \
#   --uvw-max 1667lambda \
#   --max-iterations 500 \
#   --num-sources 500 \
#   --beam-file "${GXMWAPB}/mwa_full_embedded_element_pattern.h5" \
#   --outputs "${obsnum}_test_solutions.bin" \
#   -d "${obsnum}.ms" "${obsnum}.metafits" \
#   -s "${GXBASE}/models/GGSM.txt"

# # plot calibration solutions
# singularity run $GXCONTAINER hyperdrive \
#     solutions-plot \
#     --ref-tile ${refant} \
#     --max-amp 2 \
#     -m ${obsnum}.metafits \
#     "${solutions%.bin}_ref.bin" 