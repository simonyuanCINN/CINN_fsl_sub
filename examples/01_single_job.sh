#!/bin/bash
# Exercise 1: submit ONE FSL command to the cluster.
#
# Brain-extract a single T1 with bet. The command is exactly what you would
# type at the terminal - you just put "fsl_sub <options>" in front of it.

# ---- EDIT ME --------------------------------------------------------------
DATA=/storage/research/my_project/bids        # BIDS-style input folder
OUT=/scratch2/$USER/cinn_fsl_sub_demo         # outputs (scratch: not backed up!)
SUB=sub-01
# ---------------------------------------------------------------------------

mkdir -p "$OUT/$SUB" "$OUT/logs"

jid=$(fsl_sub \
        -T 15 \
        -R 4 \
        -N bet_$SUB \
        -l "$OUT/logs" \
        bet "$DATA/$SUB/anat/${SUB}_T1w.nii.gz" "$OUT/$SUB/${SUB}_T1w_brain" -R -f 0.4)

echo "Submitted bet for $SUB as job $jid"
echo "  Watch:  squeue -u $USER"
echo "  Logs:   $OUT/logs/bet_$SUB.o$jid  (stdout)"
echo "          $OUT/logs/bet_$SUB.e$jid  (stderr)"

# What each option does
#   -T 15        expected run time in minutes -> fsl_sub picks the partition
#                (<= 24 h: short, longer: long) and sets the Slurm time limit.
#                The job is KILLED if it runs past this, so leave headroom.
#   -R 4         memory in GB -> Slurm --mem. Killed if exceeded.
#                Note: RACC2 nodes have 8 GB per core, so fsl_sub asks for
#                ceil(R/8) cores; e.g. -R 32 gets 4 cores.
#   -N           job name shown in squeue and used for log file names
#   -l           where to write logs (default: the current directory)
