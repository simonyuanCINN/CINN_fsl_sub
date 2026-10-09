#!/bin/bash
# ---------------------------------------------------------------------------
# CINN: FSL + fsl_sub environment for RACC2
#
# Source this from your ~/.bashrc so every login (and every job, because
# fsl_sub copies your environment into the job) is set up the same way:
#
#     echo 'source ~/CINN_fsl_sub/setup/racc2_fsl_env.sh' >> ~/.bashrc
#
# Edit the two paths marked EDIT ME if your copy lives somewhere else.
# ---------------------------------------------------------------------------

# 1. Make FSL available ------------------------------------------------------
# EDIT ME: use whichever applies on RACC2.
#   (a) a centrally installed module - find it with:  module avail fsl
#   (b) your own FSL install, e.g. in research storage
if module avail fsl 2>&1 | grep -qi fsl; then
    module load fsl
else
    export FSLDIR="${FSLDIR:-$HOME/fsl}"            # EDIT ME if installed elsewhere
    if [ -f "$FSLDIR/etc/fslconf/fsl.sh" ]; then
        source "$FSLDIR/etc/fslconf/fsl.sh"
        export PATH="$FSLDIR/share/fsl/bin:$PATH"
    else
        echo "racc2_fsl_env.sh: FSL not found (no module, no \$FSLDIR=$FSLDIR)" >&2
    fi
fi

# 2. Point fsl_sub at the CINN RACC2 configuration ---------------------------
# (Alternatively copy config/fsl_sub_racc2.yml to ~/.fsl_sub.yml.)
export FSLSUB_CONF="$HOME/CINN_fsl_sub/config/fsl_sub_racc2.yml"   # EDIT ME

# 3. RACC2 house rule: one thread per physical core --------------------------
# Every fsl_sub job gets  #SBATCH --threads-per-core=1
export FSLSUB_EXTRA_TPC="--threads-per-core=1"

# 4. Optional ---------------------------------------------------------------
# Only start a held job if its parent finished successfully (Slurm afterok).
# Default fsl_sub behaviour is afterany: children start even if a parent fails.
# export FSLSUB_STRICTDEPS=1
