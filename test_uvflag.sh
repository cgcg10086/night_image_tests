#!/bin/bash -l
#SBATCH --account=pawsey0272
#SBATCH --partition=copy
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=64G
#SBATCH --time=01:00:00
#SBATCH --output=uvflag_%j.log
#SBATCH --error=uvflag_%j.log

obsnum=1447262000
# check folder exist 

module load singularity/4.1.0-slurm

cd "${obsnum}" || exit 1

# singularity exec "$GXCONTAINER" python3 -c \
#   'import casacore.tables; print("casacore OK")'

# singularity exec "$GXCONTAINER" ms_flag_by_uvdist.py \

singularity exec "$GXCONTAINER" cat \
  /opt/gleamx-python/bin/ms_flag_by_uvdist.py > ms_flag_by_uvdist_test.py

# fix python depandency later 
sed -i 's/np\.complex_/np.complex128/g' ms_flag_by_uvdist_test.py

singularity exec "$GXCONTAINER" /usr/bin/python3 \
  "$PWD/ms_flag_by_uvdist_test.py" "${obsnum}.ms" CORRECTED_DATA -a

# singularity exec "$GXCONTAINER" /usr/bin/python3 \
#     /opt/gleamx-python/bin/ms_flag_by_uvdist.py \
#     "${obsnum}.ms" CORRECTED_DATA -a