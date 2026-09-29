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
# singularity exec "$GXCONTAINER" ms_flag_by_uvdist.py "${obsnum}.ms" "${column}" -a

# singularity exec "$GXCONTAINER" python3 -c \
#   'import casacore.tables; print("casacore OK")'

# singularity exec "$GXCONTAINER" ms_flag_by_uvdist.py \

# temp solution create a new ms_flag_by_uvdist_test.py to modify imcompatiable 
singularity exec "$GXCONTAINER" cat \
  /opt/gleamx-python/bin/ms_flag_by_uvdist.py > ms_flag_by_uvdist_test.py

# fix python depandency later 
sed -i 's/np\.complex_/np.complex128/g' ms_flag_by_uvdist_test.py

singularity exec "$GXCONTAINER" ms_flag_by_uvdist_test.py "${obsnum}.ms" "${column}" -a


# singularity exec "$GXCONTAINER" /usr/bin/python3 \
#     /opt/gleamx-python/bin/ms_flag_by_uvdist.py \
#     "${obsnum}.ms" CORRECTED_DATA -a