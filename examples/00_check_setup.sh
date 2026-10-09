#!/bin/bash
# Exercise 0: confirm FSL and fsl_sub are set up to submit to Slurm on RACC2.
# Run on a RACC2 login node:  bash examples/00_check_setup.sh

echo "== FSL =="
if [ -n "$FSLDIR" ] && command -v bet >/dev/null; then
    echo "FSLDIR = $FSLDIR"
    cat "$FSLDIR/etc/fslversion" 2>/dev/null
else
    echo "FSL is not loaded - source setup/racc2_fsl_env.sh first"; exit 1
fi

echo; echo "== fsl_sub =="
command -v fsl_sub || { echo "fsl_sub not on PATH"; exit 1; }
fsl_sub --version
echo "FSLSUB_CONF = ${FSLSUB_CONF:-<not set, using ~/.fsl_sub.yml or FSL default>}"

echo; echo "== Is fsl_sub talking to Slurm? =="
if fsl_sub --has_queues; then
    echo "Yes - jobs will be submitted to the cluster."
else
    echo "NO - fsl_sub would run jobs on THIS login node (shell plugin)."
    echo "Install the Slurm plugin and set FSLSUB_CONF (see README, step 2)."
    exit 1
fi

echo; echo "== Queues fsl_sub knows about =="
fsl_sub --show_config | sed -n '/^queues:/,$p' | grep -E '^  [a-z]' | tr -d ':'

echo; echo "== Test submission =="
mkdir -p logs
jid=$(fsl_sub -T 5 -R 1 -N cinn_hello -l logs hostname)
echo "Submitted job $jid. Check it with:  squeue -j $jid   then   cat logs/cinn_hello.o$jid"
