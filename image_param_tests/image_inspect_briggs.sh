#!/bin/bash
set -euo pipefail

testdir="/scratch/pawsey0272/gcchen/test3_image_parameters"
obsnum=1447262000
minuv=50
tukey=50

inspectdir="${testdir}/inspect_${obsnum}_briggs"
mkdir -p "$inspectdir"

robust_choices=(-2 -1.5 -1 -0.5 0 0.5)

# Number the links so CARTA lists them in increasing robust order.
i=1
for robust in "${robust_choices[@]}"; do
    runname="${obsnum}_robust${robust}_minuv${minuv}_tukey${tukey}"
    image="${testdir}/${obsnum}/${runname}/${runname}-MFS-image.fits"

    if [[ -f "$image" ]]; then
        ln -sfn "$image" \
            "${inspectdir}/${i}_robust${robust}_minuv${minuv}_tukey${tukey}.fits"
        echo "Linked robust=$robust"
    else
        echo "Missing: $image"
    fi

    i=$((i + 1))
done

echo "Inspection folder: $inspectdir"