#!/bin/bash
set -euo pipefail

old="/scratch/pawsey0272/gcchen/test3_image_parameters_run1_coarse"
new="/scratch/pawsey0272/gcchen/test3_image_parameters"

mkdir -p "$new"

# These must be the full observation list and complete revised flag list.
cp "$old/obs_list.txt" "$new/obs_list.txt"
cp "$old/flag_list.txt" "$new/flag_list.txt"

while read -r obsnum || [[ -n "$obsnum" ]]; do
    [[ -n "$obsnum" ]] || continue

    mkdir -p "$new/$obsnum"

    # Prevent accidentally nesting a copy inside an existing MS.
    if [[ -e "$new/$obsnum/$obsnum.ms" ]]; then
        echo "Already exists: $new/$obsnum/$obsnum.ms; stopping."
        exit 1
    fi

    # Copy the post-download backup, naming the new copy obsnum.ms.
    cp -r "$old/$obsnum/$obsnum.ms_backup" \
          "$new/$obsnum/$obsnum.ms"

    cp "$old/$obsnum/$obsnum.metafits" \
       "$new/$obsnum/$obsnum.metafits"

    echo "Restored $obsnum"
done < "$new/obs_list.txt"