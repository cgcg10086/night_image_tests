#!/bin/bash
set -euo pipefail

obslist=$1
testdir="/scratch/pawsey0272/gcchen/test3_image_parameters"

batch_limit=500 # can be $2 if needed
submitted=0

# sbumit all at once: reach user job limit.
# while read -r obsnum || [[ -n "$obsnum" ]]; do
#     [[ -n "$obsnum" ]] || continue

#     while IFS= read -r image; do
#         echo "Submitting evaluation: $image"
#         sbatch --export=All image_param_evaluate.sh "$image"
#     done < <(
#         find "$testdir" -type f \
#             -name "${obsnum}_*-MFS-image.fits"
#     )

# done < "${testdir}/${obslist}"

# submit in batch and skip compeleted evaluations.
while read -r obsnum || [[ -n "$obsnum" ]]; do
    [[ -n "$obsnum" ]] || continue

    while IFS= read -r image; do
        prefix="${image%.fits}"

        # Skip evaluations already completed.
        if [[ -f "${prefix}_evaluate.done" ]]; then
            continue
        fi

        # After one batch, wait before submitting the next.
        if (( submitted >= batch_limit )); then
            echo "Submitted $submitted jobs. Waiting for your queue to empty."

            while true; do
                if ! queued_jobs=$(squeue --me --noheader); then
                    echo "Could not check the queue; stopping."
                    exit 1
                fi

                # An empty result means none of your jobs remain in the queue.
                if [[ -z "$queued_jobs" ]]; then
                    break
                fi

                sleep 60
            done

            submitted=0
            echo "Previous jobs finished. Submitting the next batch."
        fi

    
        echo "Submitting evaluation: $image"

        # In Bash, if runs a command and checks whether it succeeded. Exit code 0 --> execute then
        if sbatch --export=ALL image_param_evaluate.sh "$image"; then
            submitted=$((submitted + 1))
        else
            echo "Submission failed. Stopping after $submitted submissions."
            exit 1
        fi

    done < <(
        find "$testdir" -type f \
            -name "${obsnum}_*-MFS-image.fits" | sort
    )

done < "${testdir}/${obslist}"

echo "Submitted $submitted jobs; reached the end of the list."