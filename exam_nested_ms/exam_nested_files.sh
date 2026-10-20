#!/bin/bash

testdir="/scratch/pawsey0272/gcchen/test3_image_parameters"

for obsdir in "$testdir"/*/; do
    obsnum=$(basename "$obsdir")
    nested="${obsdir}${obsnum}.ms/${obsnum}.ms"

    if [[ -d "$nested" ]]; then
        echo "$nested"
    fi
done