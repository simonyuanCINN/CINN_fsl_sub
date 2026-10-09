#!/bin/bash
# Exercise 2: run the same FSL command for every subject as ONE array job.
#
# Write one command per line into a "task file", then submit the file with -t.
# Each line becomes one sub-task; Slurm runs them in parallel.
# RACC2 asks users to prefer array jobs over many separate submissions.

# ---- EDIT ME --------------------------------------------------------------
DATA=/storage/research/my_project/bids
OUT=/scratch2/$USER/cinn_fsl_sub_demo
# ---------------------------------------------------------------------------

mkdir -p "$OUT/logs"
TASKS="$OUT/bet_tasks.txt"
: > "$TASKS"

for t1 in "$DATA"/sub-*/anat/sub-*_T1w.nii.gz; do
    sub=$(basename "$t1" | cut -d_ -f1)
    mkdir -p "$OUT/$sub"
    echo "bet $t1 $OUT/$sub/${sub}_T1w_brain -R -f 0.4" >> "$TASKS"
done

n=$(wc -l < "$TASKS")
echo "Task file has $n commands:"; head -3 "$TASKS"; echo "..."

jid=$(fsl_sub \
        -t "$TASKS" \
        -x 20 \
        -T 15 \
        -R 4 \
        -N bet_all \
        -l "$OUT/logs")

echo "Submitted array job $jid with $n tasks"
echo "  Logs: $OUT/logs/bet_all.o${jid}.<task number>"

# Notes
#   -t FILE   one command per line; -T/-R apply to EACH line, not the total
#   -x 20     run at most 20 tasks at once (be kind to other users)
#   Task N is line N of the file - handy when one subject fails:
#     sed -n 7p "$TASKS"        # which command was task 7?
#   Lines must be complete commands; don't put "fsl_sub" in the task file.
