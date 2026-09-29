#!/bin/bash -l
#SBATCH --account=pawsey0272
#SBATCH --partition=work
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=5
#SBATCH --mem=10G
#SBATCH --time=01:00:00
#SBATCH --output=autoflag_%j.log
#SBATCH --error=autoflag_%j.log

module load singularity/4.1.0-slurm

obsnum=$1
flags=$2 # additional tiles to be flagged (after inspect autocal solution) 
testdir="/scratch/pawsey0272/gcchen/test3_image_parameters"
cd "${testdir}/${obsnum}" || exit 1

# These have been flagged by birli during manta-ray-clinet (data conversion?) 
# # read flagged tile numbers 
# flags=$(
#     singularity exec "$GXCONTAINER" python3 - "${obsnum}.metafits" <<'PY'
# import sys
# import numpy as np
# from astropy.io import fits

# with fits.open(sys.argv[1]) as hdus:
#     tiles = hdus["TILEDATA"].data
#     print(*np.unique(tiles["Antenna"][tiles["Flag"] != 0]))
# PY
# ) || exit 1

# $flags without {} read each element seperately so no longer need flag_list[@]
if [[ -n "$flags" ]]; then
    echo "Flagging antennas: ${flags}"
    singularity exec "$GXCONTAINER" flagantennae "${obsnum}.ms" $flags
fi

# flag_list is a bash array flag_list=(76 80 156 157)
# singularity exec "$GXCONTAINER" flagantennae "${obsnum}.ms" "${flag_list[@]}" # parse each element of bash array flag_list 

  # -c obs_list.txt_manta.tmp \
  # -d /scratch/pawsey0272/gcchen/test2_container_single_command_tests
