#!/bin/bash
set -euo pipefail

# test_image.sh 
obslist=$1
testdir="/scratch/pawsey0272/gcchen/test3_image_parameters"
# cd testdir


robust_choices=(-0.4 -0.3 -0.2 -0.1 0 0.1 0.2 0.3 0.4)
# see uv-distribution Jupyter notebook 
minuv_choices=(0 10 20 30 40 50 60 70 80 100 120 160 200 250 300)
tukey_choices=(0 50 100 200 400)

batch_limit=300
submitted_in_batch=0
batch_job_ids=()
active_job_names=""

refresh_active_job_names() {
    active_job_names=$(squeue --noheader --user="${USER}" --format='%j')
}

job_is_active() {
    local active_name
    while IFS= read -r active_name; do
        [[ "$active_name" == "$1" ]] && return 0
    done <<< "$active_job_names"
    return 1
}

# wait_for_batch() {
#     local job_id_list
#     job_id_list=$(IFS=,; printf '%s' "${batch_job_ids[*]}")

#     echo "Waiting for the previous batch of ${#batch_job_ids[@]} imaging jobs to finish."
#     while [[ -n "$(squeue --noheader --jobs="$job_id_list" --format='%A')" ]]; do
#         sleep 60
#     done

#     batch_job_ids=()
#     submitted_in_batch=0
# }

wait_for_batch() {
    local queued_ids job_id still_active

    echo "Waiting for ${#batch_job_ids[@]} jobs to finish."

    while true; do
        if queued_ids=$(squeue --noheader --user="$USER" --format='%A'); then
            still_active=no

            for job_id in "${batch_job_ids[@]}"; do
                if grep -Fxq "$job_id" <<< "$queued_ids"; then
                    still_active=yes
                    break
                fi
            done

            if [[ "$still_active" == no ]]; then
                break
            fi
        else
            echo "Cannot query Slurm; retrying in 60 seconds."
        fi

        sleep 60
    done

    batch_job_ids=()
    submitted_in_batch=0
}

refresh_active_job_names

while read -r obsnum || [[ -n "$obsnum" ]]; do
    [[ -n "$obsnum" ]] || continue

    for robust in "${robust_choices[@]}"; do
        for minuv in "${minuv_choices[@]}"; do
            for tukey in "${tukey_choices[@]}"; do
                runname="${obsnum}_robust${robust}_minuv${minuv}_tukey${tukey}"
                rundir="${testdir}/${obsnum}/${runname}"

                if [[ -f "${rundir}/imaging.done" ]]; then
                    echo "Already completed: ${runname}; not submitting."
                    continue
                fi
                if job_is_active "$runname"; then
                    echo "Already submitted and active: ${runname}; not submitting."
                    continue
                fi

                if (( submitted_in_batch == batch_limit )); then
                    wait_for_batch
                    refresh_active_job_names

                    if [[ -f "${rundir}/imaging.done" ]]; then
                        echo "Already completed: ${runname}; not submitting."
                        continue
                    fi
                    if job_is_active "$runname"; then
                        echo "Already submitted and active: ${runname}; not submitting."
                        continue
                    fi
                fi

                # job_id=$(sbatch --parsable --export=ALL --job-name="$runname" \
                #     test_image.sh "${obsnum}" "${robust}" "${minuv}" "${tukey}")
                while true; do
                    if job_id=$(sbatch --parsable --export=ALL --job-name="$runname" \
                        test_image.sh "$obsnum" "$robust" "$minuv" "$tukey" 2>&1); then
                        break
                    fi

                    if [[ "$job_id" == *AssocMaxSubmitJobLimit* ||
                        "$job_id" == *QOSMaxSubmitJobPerUserLimit* ]]; then
                        echo "Submission limit reached; retrying this combination in 60 seconds."
                        sleep 60
                    else
                        echo "Submission failed: $job_id" >&2
                        exit 1
                    fi
                done

                job_id="${job_id%%;*}"
                if [[ ! "$job_id" =~ ^[0-9]+$ ]]; then
                    echo "Could not parse the Slurm job ID returned for ${runname}: ${job_id}" >&2
                    exit 1
                fi
                batch_job_ids+=("$job_id")
                active_job_names+=$'\n'"$runname"
                ((submitted_in_batch += 1))
            done
        done
    done
done < "${testdir}/${obslist}"