#!/bin/bash -l
#SBATCH --account=pawsey0272
#SBATCH --partition=work
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=12
#SBATCH --mem=24G
#SBATCH --time=01:00:00
#SBATCH --output=uvflag_%j.log
#SBATCH --error=uvflag_%j.log

module load singularity/4.1.0-slurm

obsnum=$1
column="CORRECTED_DATA"  
testdir="/scratch/pawsey0272/gcchen/test3_image_parameters"

cd "${testdir}/${obsnum}" 

# ms_flag_by_uvdist.py "${obsnum}.ms" ${column} -a
# this runs the ms_flag_by_uvdist.py inside the container's PATH 
# singularity exec "$GXCONTAINER" ms_flag_by_uvdist.py "${obsnum}.ms" "${column}" -a

# fixed ms_flag_by_uvdist.py in gleam_x/bin/, but need to rebuild container to update the code inside it's path
singularity exec "$GXCONTAINER" python3 \
  "$GXBASE/gleam_x/bin/ms_flag_by_uvdist.py" \
  "${obsnum}.ms" "${column}" -a

# when python modules didn't load correctly-- use /usr/bin/python3 instead of container's python3
# singularity exec "$GXCONTAINER" /usr/bin/python3 \
#     /opt/gleamx-python/bin/ms_flag_by_uvdist.py \
#     "${obsnum}.ms" CORRECTED_DATA -a

# confirm module load ok 
# singularity exec "$GXCONTAINER" python3 -c \
#   'import casacore.tables; print("casacore OK")'

# numpy compatiable issue in /opt/gleamx-python/bin/ms_flag_by_uvdist.py 
# temp solution: create a new ms_flag_by_uvdist_test.py here to fix 
# singularity exec "$GXCONTAINER" cat \
#   /opt/gleamx-python/bin/ms_flag_by_uvdist.py > ms_flag_by_uvdist_test.py

# change each "np.complex_" to "np.complex128"
# sed -i 's/np\.complex_/np.complex128/g' ms_flag_by_uvdist_test.py