#!/bin/bash -l

testdir="/scratch/pawsey0272/gcchen/test3_image_parameters"
reviewdir="${testdir}/review_images"
mkdir -p "$reviewdir"

robust=-0.5

# to view image
for minuv in 50 900; do
    for tukey in 50 900; do
        find "$testdir" -type f \
            -name "*_robust${robust}_minuv${minuv}_tukey${tukey}-MFS-image.fits" \
            -exec ln -s -t "$reviewdir" {} +
    done
done

# to view phase solution PNG
while read -r obsnum || [[ -n "$obsnum" ]]; do
    [[ -n "$obsnum" ]] || continue

    find "${testdir}/${obsnum}" -type f \
        -iname '*phase*.png' \
        -exec ln -s -t "$reviewdir" {} +

done < "${testdir}/obs_list.txt"