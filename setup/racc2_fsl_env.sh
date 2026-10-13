#!/bin/bash
# ---------------------------------------------------------------------------
# CINN: FSL + fsl_sub environment for RACC2
#
# Source this from your ~/.bashrc so every login (and every job, because
# fsl_sub copies your environment into the job) is set up the same way:
#
#     echo 'source ~/CINN_fsl_sub/setup/racc2_fsl_env.sh' >> ~/.bashrc
# ---------------------------------------------------------------------------

# 1. Load the CINN FSL --------------------------------------------------------
# fsl/6.0.7.23 includes the fsl_sub Slurm plugin and the CINN RACC2 config
# (installed as $FSLDIR/etc/fslconf/fsl_sub.yml), so fsl_sub submits to Slurm
# with no further setup - including FEAT's own internal fsl_sub calls.
#
# Do NOT use /software/CINN/fsl/6.0.7.12: it has no Slurm plugin, so its
# fsl_sub silently runs every job on the login node.
module load fsl/6.0.7.23

# 2. RACC2 house rule: one thread per physical core --------------------------
# Every fsl_sub job gets  #SBATCH --threads-per-core=1
export FSLSUB_EXTRA_TPC="--threads-per-core=1"

# 3. Optional ---------------------------------------------------------------
# Only start a held job if its parent finished successfully (Slurm afterok).
# Default fsl_sub behaviour is afterany: children start even if a parent fails.
# export FSLSUB_STRICTDEPS=1

# Use a personal copy of the config instead of the one inside the install:
# cp ~/CINN_fsl_sub/config/fsl_sub_racc2.yml ~/.fsl_sub.yml   (then edit it)
