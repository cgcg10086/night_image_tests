#!/bin/bash
set -euo pipefail

old="/scratch/pawsey0272/gcchen/test3_image_parameters_run1_coarse"
new="/scratch/pawsey0272/gcchen/test3_image_parameters"

mkdir -p "$new"

# Check all inputs before creating links.
while read -r obsnum || [[ -n "$obsnum" ]]; do
    [[ -n "$obsnum" ]] || continue

    [[ -d "$old/$obsnum/$obsnum.ms" ]] || {
        echo "Missing MS: $obsnum"
        exit 1
    }

    [[ -f "$old/$obsnum/$obsnum.metafits" ]] || {
        echo "Missing metafits: $obsnum"
        exit 1
    }
done < "$old/obs_list.txt"

# Copy the existing observation list.
cp "$old/obs_list.txt" "$new/obs_list.txt"

# Create links for each observation.
while read -r obsnum || [[ -n "$obsnum" ]]; do
    [[ -n "$obsnum" ]] || continue

    mkdir -p "$new/$obsnum"

    for filename in "${obsnum}.ms" "${obsnum}.metafits"; do
        destination="$new/$obsnum/$filename"

        if [[ -e "$destination" || -L "$destination" ]]; then
            echo "Already exists: $destination"
        else
            ln -s "$old/$obsnum/$filename" "$destination"
            echo "Linked: $destination"
        fi
    done
done < "$old/obs_list.txt"