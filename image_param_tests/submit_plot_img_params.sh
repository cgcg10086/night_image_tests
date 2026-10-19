#!/bin/bash -l
#SBATCH --account=pawsey0272
#SBATCH --partition=work
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=24
#SBATCH --mem=50G
#SBATCH --time=10:00:00
#SBATCH --output=plot_parameters_%j.log

set -euo pipefail

testdir="/scratch/pawsey0272/gcchen/test3_image_parameters"

if (($# > 1)) || [[ "${1:-}" != "" && "${1:-}" != "csv" ]]; then
    echo "Usage: sbatch $0 [csv]" >&2
    exit 2
fi

if [[ "${1:-}" == "csv" ]]; then
    singularity exec "$GXCONTAINER" python3 -u \
        "${SLURM_SUBMIT_DIR}/plot_image_params_results.py" \
        --from-csv "${testdir}/parameter_plots_test2/image_parameter_summary.csv" \
        --out "${testdir}/parameter_plots_test2_replot"
else
    singularity exec "$GXCONTAINER" python3 -u \
        "${SLURM_SUBMIT_DIR}/plot_image_params_results.py" \
        "$testdir" \
        --obs-list "${testdir}/obs_list.txt" \
        --out "${testdir}/parameter_plots_test2"
fi