#!/bin/bash
# Exercise 3: chain steps into a pipeline with job holds (-j).
#
#   step 1  bet   (array, one task per subject)
#   step 2  fast  (array, waits for ALL of step 1)
#   step 3  summary table (single job, waits for step 2)
#
# Everything is submitted at once; Slurm starts each step when its
# parents finish. You can log out straight away.

set -e
# ---- EDIT ME --------------------------------------------------------------
DATA=/storage/research/my_project/bids
OUT=/scratch2/$USER/cinn_fsl_sub_demo
# ---------------------------------------------------------------------------

# Only start a step if its parent SUCCEEDED (Slurm afterok).
# Without this, fsl_sub uses afterany: step 2 would start even if bet failed.
export FSLSUB_STRICTDEPS=1

mkdir -p "$OUT/logs"
BET_TASKS="$OUT/bet_tasks.txt";  : > "$BET_TASKS"
FAST_TASKS="$OUT/fast_tasks.txt"; : > "$FAST_TASKS"

for t1 in "$DATA"/sub-*/anat/sub-*_T1w.nii.gz; do
    sub=$(basename "$t1" | cut -d_ -f1)
    brain="$OUT/$sub/${sub}_T1w_brain"
    mkdir -p "$OUT/$sub"
    echo "bet $t1 $brain -R -f 0.4"           >> "$BET_TASKS"
    echo "fast -t 1 -n 3 -o ${brain} ${brain}" >> "$FAST_TASKS"
done

# Step 1
bet_id=$(fsl_sub -t "$BET_TASKS" -x 20 -T 15 -R 4 -N bet -l "$OUT/logs")
echo "bet   : job $bet_id"

# Step 2 - fast's input doesn't exist yet, which is fine for task files.
fast_id=$(fsl_sub -t "$FAST_TASKS" -x 20 -T 30 -R 8 -N fast -l "$OUT/logs" \
                  -j "$bet_id")
echo "fast  : job $fast_id (held on $bet_id)"

# Step 3 - a single command. -n skips the "does this program exist" check,
# needed here because the command is a shell one-liner.
sum_id=$(fsl_sub -T 10 -R 2 -N gm_summary -l "$OUT/logs" -n -j "$fast_id" \
    bash -c "for v in $OUT/sub-*/sub-*_T1w_brain_pve_1.nii.gz; do \
                 echo \$(basename \$v) \$(fslstats \$v -V -M); \
             done > $OUT/grey_matter_summary.txt")
echo "summary: job $sum_id (held on $fast_id)"

echo
echo "squeue -u $USER   shows steps 2 and 3 as PENDING (Dependency) until their parents finish."

# More on holds
#   -j 111,222        wait for several jobs
#   --array_hold ID   task N of this array waits only for task N of array ID
#                     (Slurm aftercorr) - both arrays need the same length.
#                     Lets subject 1's fast start as soon as subject 1's bet ends.
