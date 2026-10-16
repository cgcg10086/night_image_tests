#!/bin/bash
set -euo pipefail

testdir="/scratch/pawsey0272/gcchen/test3_image_parameters"
cd "$testdir"

for folder in *_robust*_minuv*_tukey*; do
    [[ -d "$folder" && ! -L "$folder" ]] || continue

    # Match current run names exactly; exclude appended job IDs.
    if [[ "$folder" =~ ^([0-9]{10})_robust-?[0-9]+([.][0-9]+)?_minuv[0-9]+_tukey[0-9]+$ ]]; then
        obsnum="${BASH_REMATCH[1]}"
        mkdir -p "$obsnum"

        # Avoid overwriting or accidentally nesting an existing folder.
        if [[ -e "$obsnum/$folder" || -L "$obsnum/$folder" ]]; then
            echo "Skipping: $obsnum/$folder already exists"
            continue
        fi

        echo "Moving $folder -> $obsnum/"
        mv -- "$folder" "$obsnum/"
    fi
done