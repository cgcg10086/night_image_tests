#!/bin/bash
set -euo pipefail

# test_image.sh 
obslist=$1
testdir="/scratch/pawsey0272/gcchen/test3_image_parameters"
# cd testdir


robust_choices=(-2 -1.5 -1 -0.5 0 0.5) #($(seq -2 0.5 0.5)) # (seq start, step, end)
# see uv-distribution Jupyter notebook 
minuv_choices=(50 100 300 600 900 0 30 75) 
tukey_choices=(50 100 300 600 900 0 30 75)

batch_limit=1000
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

wait_for_batch() {
    local job_id_list
    job_id_list=$(IFS=,; printf '%s' "${batch_job_ids[*]}")

    echo "Waiting for the previous batch of ${#batch_job_ids[@]} imaging jobs to finish."
    while [[ -n "$(squeue --noheader --jobs="$job_id_list" --format='%A')" ]]; do
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

                job_id=$(sbatch --parsable --export=ALL --job-name="$runname" \
                    test_image.sh "${obsnum}" "${robust}" "${minuv}" "${tukey}")
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