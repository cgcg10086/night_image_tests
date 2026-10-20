#!/bin/bash
set -euo pipefail

testdir="/scratch/pawsey0272/gcchen/test3_image_parameters"

for obsnum in 1441747424 1454241400 1452001040; do
    obsdir="${testdir}/${obsnum}"

    # Stop rather than overwrite a previous saved copy.
    [[ -d "${obsdir}/${obsnum}.ms" ]]
    [[ -d "${obsdir}/${obsnum}.ms_backup" ]]
    if [[ -e "${obsdir}/${obsnum}.ms_flag_wrong" ]]; then
        echo "Already exists: ${obsdir}/${obsnum}.ms_flag_wrong; stopping."
        exit 1
    fi

    mv "${obsdir}/${obsnum}.ms" "${obsdir}/${obsnum}.ms_flag_wrong"
    cp -r "${obsdir}/${obsnum}.ms_backup" "${obsdir}/${obsnum}.ms"

    echo "Restored: ${obsnum}"
done