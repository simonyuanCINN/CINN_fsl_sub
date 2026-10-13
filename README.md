# CINN_fsl_sub

**Running FSL jobs on the University of Reading RACC2 cluster with `fsl_sub`**

A teaching template for members of the Centre for Integrative Neuroscience and Neurodynamics (CINN). Work through it top to bottom the first time; afterwards, copy the example scripts and edit the paths.

> Maintainer: Simon Yuan (CINN). Uses the CINN FSL 6.0.7.23 install on RACC2 (`module load fsl/6.0.7.23`), which includes the fsl_sub Slurm plugin. RACC2 partition details are from the RACC2 knowledge base as of October 2026; check `sinfo -s` for current values.

---

## Contents

1. [Why fsl_sub?](#1-why-fsl_sub)
2. [One-time setup](#2-one-time-setup)
3. [Your first job](#3-your-first-job)
4. [Choosing time and memory](#4-choosing-time-and-memory)
5. [Many subjects: array jobs](#5-many-subjects-array-jobs)
6. [Pipelines: job holds](#6-pipelines-job-holds)
7. [Monitoring, logs and cancelling](#7-monitoring-logs-and-cancelling)
8. [Using scavenger](#8-using-scavenger)
9. [Multi-threaded jobs](#9-multi-threaded-jobs)
10. [Known issues and gotchas](#10-known-issues-and-gotchas)
11. [Cheat sheet](#11-cheat-sheet)
12. [For maintainers: installing FSL on RACC2](#12-for-maintainers-installing-fsl-on-racc2)

You don't need to download anything: FSL and its settings are already installed on RACC2. The example scripts are here to read and copy from.

```
CINN_fsl_sub/
├── README.md                    ← this tutorial
├── examples/
│   ├── 01_single_job.sh         ← one bet job
│   ├── 02_array_bet.sh          ← bet for every subject as an array
│   ├── 03_pipeline_holds.sh     ← bet → fast → summary, chained with holds
│   └── bnu_speech_pipeline/     ← a complete real study: FEAT, FIX, group ICA, dual regression, seed-based connectivity
├── config/fsl_sub_racc2.yml     ← (maintainers) fsl_sub settings installed inside the CINN FSL
└── modules/fsl/6.0.7.23.lua     ← (maintainers) the module file behind `module load fsl/6.0.7.23`
```

---

## 1. Why fsl_sub?

RACC2 uses the **Slurm** scheduler. You *could* write an `sbatch` script for every FSL command, but `fsl_sub` lets you put a prefix in front of the command you already know:

```bash
bet T1.nii.gz T1_brain               # runs here, now
fsl_sub -T 15 -R 4 bet T1.nii.gz T1_brain   # runs on a compute node; prints a job ID
```

It is also what FSL's own tools use internally: `feat`, `melodic`, `bedpostx`, `probtrackx2`, `randomise_parallel`, `tbss` and others call `fsl_sub` themselves. **With the CINN config in place, those tools spread their work across the cluster automatically.**

`fsl_sub` is developed by FMRIB, Oxford: <https://git.fmrib.ox.ac.uk/fsl/fsl_sub>.

---

## 2. One-time setup

### 2.1 Log in

```bash
ssh -X <username>@racc.rdg.ac.uk
```

This is a load balancer that sends you to the least-busy login node. Mac users need XQuartz for `-X` (GUIs such as `fsleyes`); Windows users can use MobaXterm.

Login nodes are for editing, testing and submitting — each user is capped at 12 cores and 256 GB there, and background jobs are not allowed. Anything heavy goes through `fsl_sub`.

### 2.2 Load FSL

Add two lines to the end of your `~/.bashrc`, so every login (and every job) is set up the same way:

```bash
echo 'module load fsl/6.0.7.23' >> ~/.bashrc
echo 'export FSLSUB_EXTRA_TPC="--threads-per-core=1"' >> ~/.bashrc
source ~/.bashrc
```

| Line | Why |
|---|---|
| `module load fsl/6.0.7.23` | The CINN FSL install. It includes fsl_sub's Slurm plugin and the CINN RACC2 settings, so `fsl_sub` submits to Slurm with no extra setup. |
| `export FSLSUB_EXTRA_TPC="--threads-per-core=1"` | RACC2 asks every job to use whole physical cores. |

That's all the setup. Check it in a new login:

```bash
which fsl_sub                              # /software/CINN/fsl/6.0.7.23/share/fsl/bin/fsl_sub
fsl_sub --show_config | grep "^method"     # method: slurm
```

> **Use `fsl/6.0.7.23`, not the older `/software/CINN/fsl/6.0.7.12`.** The older install has no Slurm plugin, so its `fsl_sub` silently runs every job on the login node: FEAT still runs, but nothing appears in `squeue`. If your `~/.bashrc` adds `/software/CINN/fsl/6.0.7.12` to `PATH`, remove that line.

### 2.3 Shortcuts to scratch and research storage

Your data will mostly live outside your small home directory. Symbolic links let you reach it with `cd ~/scratch` instead of typing the full path:

```bash
ls -d /scratch2/$USER /scratch3/$USER            # find which scratch folder is yours
ln -s /scratch2/$USER ~/scratch                  # use the path the ls showed
ln -s /storage/research/<project> ~/research     # optional: your project's research storage
```

`ls -l ~` shows them as `scratch -> /scratch2/<username>`.

- **Getting scratch space:** request it through the DTS Self Service Portal. It may be on `/scratch2` or `/scratch3`, or under a project name; link whichever path you were given.
- **Removing a shortcut:** `rm ~/scratch` deletes only the link. Never `rm -r ~/scratch/` — the trailing slash deletes the folder's contents.
- **Scratch is not backed up** and can be cleared. Keep raw data and anything you can't regenerate in research storage.

---

## 3. Your first job

```bash
mkdir -p logs
fsl_sub -T 15 -R 4 -N bet_sub01 -l logs \
    bet sub-01_T1w.nii.gz sub-01_T1w_brain -R
```

`fsl_sub` prints a **job ID** (e.g. `4815162`) and returns immediately. The job waits in the queue, runs on a compute node, and writes:

```
logs/bet_sub01.o4815162   ← standard output
logs/bet_sub01.e4815162   ← errors (check this first if something goes wrong)
```

Full worked version: [`examples/01_single_job.sh`](examples/01_single_job.sh).

---

## 4. Choosing time and memory

**Always give `-T` (minutes) and `-R` (GB).** They do two jobs:

1. **Pick the partition for you.** You normally don't need `-q`:

   | `-T` you give | Partition chosen | Max time |
   |---|---|---|
   | up to 1440 (24 h) | `short` | 24 h |
   | over 1440 | `long` | 30 days |
   | none | `short` (RACC2's default) | 24 h |

   `long` is for small numbers of long jobs: RACC2 lets you run fewer jobs there and allocate less CPU and memory than in `short`. Split work into pieces under 24 h where you can.

   **RACC2 partitions at a glance**

   | Partition | Max time | Use for |
   |---|---|---|
   | `short` (default) | 24 h | most jobs; small/medium parallel and serial work |
   | `long` | 30 days | a few long serial or medium parallel jobs |
   | `scavenger` | 3 days (default 24 h) | big arrays of restartable jobs on all nodes — see [§8](#8-using-scavenger) |
   | `racc_<project>` | project-specific | paid project allocations; access via the `racc_<project>` security group — see [§8](#8-using-scavenger) |

2. **Set hard Slurm limits.** `-T` becomes `--time`, `-R` becomes `--mem`. A job that runs longer, or uses more memory, **is killed**. Over-estimate a little — but large over-estimates make your jobs wait longer in the queue.

**Memory buys cores.** RACC2 nodes have 8 GB per core, so fsl_sub requests `ceil(R / 8)` cores: `-R 4` → 1 core, `-R 32` → 4 cores, `-R 100` → 13 cores. Ask for what you need, not a round big number.

**How to estimate:** run one subject, then check what it actually used:

```bash
sacct -j <jobid> --format=JobName,Elapsed,MaxRSS,State
```

Rough starting points (single T1 / single run; adjust to your data):

| Tool | `-T` | `-R` |
|---|---|---|
| `bet` | 15 | 4 |
| `fast` | 30 | 8 |
| `flirt` | 15 | 4 |
| `fnirt` | 60 | 8 |
| first-level `feat` | 120 | 16 |

---

## 5. Many subjects: array jobs

Put one command per line in a text file and submit the file with `-t`:

```bash
# bet_tasks.txt
bet /data/sub-01/anat/sub-01_T1w.nii.gz /out/sub-01/sub-01_T1w_brain -R
bet /data/sub-02/anat/sub-02_T1w.nii.gz /out/sub-02/sub-02_T1w_brain -R
...
```

```bash
fsl_sub -t bet_tasks.txt -x 20 -T 15 -R 4 -N bet_all -l logs
```

- `-T` and `-R` apply to **each line**, not the whole array.
- `-x 20` runs at most 20 at once.
- Line *N* is task *N*; logs are `bet_all.o<jobid>.<N>`. To find which subject task 7 was: `sed -n 7p bet_tasks.txt`.
- RACC2 asks users to prefer arrays over hundreds of separate submissions.

Building the task file with a loop: [`examples/02_array_bet.sh`](examples/02_array_bet.sh).

> **Don't edit a task file after submitting it.** Each task reads its line when it *starts*, not when you submit. Write a new file for the next run.

---

## 6. Pipelines: job holds

`-j <jobid>` makes a job wait until another finishes. Submit the whole pipeline at once and log out:

```bash
export FSLSUB_STRICTDEPS=1      # only continue if the parent SUCCEEDED

bet_id=$(fsl_sub  -t bet_tasks.txt  -T 15 -R 4 -N bet  -l logs)
fast_id=$(fsl_sub -t fast_tasks.txt -T 30 -R 8 -N fast -l logs -j $bet_id)
fsl_sub -T 10 -R 2 -N summary -l logs -j $fast_id ./make_summary.sh
```

| Option | Slurm equivalent | Meaning |
|---|---|---|
| `-j 111` | `--dependency=afterany:111` | start after 111 ends, **even if it failed** |
| `-j 111` with `FSLSUB_STRICTDEPS=1` | `afterok:111` | start only if 111 succeeded |
| `-j 111,222` | `afterany:111:222` | wait for both |
| `--array_hold 111` | `aftercorr:111` | task *N* waits only for task *N* of array 111 |

The default (`afterany`) is a common trap: a failed `bet` still lets `fast` start on missing files. Use `FSLSUB_STRICTDEPS=1` for pipelines.

Full worked version: [`examples/03_pipeline_holds.sh`](examples/03_pipeline_holds.sh).

---

## 7. Monitoring, logs and cancelling

| Task | Command |
|---|---|
| My queued/running jobs | `squeue -u $USER` |
| Why is it pending? | `squeue -u $USER -o "%.10i %.20j %.8T %.20R"` (last column = reason) |
| Status via fsl_sub | `fsl_sub_report <jobid>` |
| What did a finished job use? | `sacct -j <jobid> --format=JobName,Elapsed,MaxRSS,State,ExitCode` |
| Cancel one job | `scancel <jobid>` (or `fsl_sub --delete_job <jobid>`) |
| Cancel one array task | `scancel <jobid>_<N>` |
| Cancel everything of mine | `scancel -u $USER` |

Common `State` values from `sacct`: `TIMEOUT` → raise `-T`; `OUT_OF_MEMORY` → raise `-R`; `FAILED` → read the `.e` log.

---

## 8. Using scavenger

`scavenger` runs on **all** RACC2 nodes (including the newest, most efficient ones and project-owned nodes), allows up to 3 days and has no cap on how much you use at once — but your job **can be killed and re-queued** if the node's owners need it. RACC2 recommends it whenever practical for experienced users with large resource needs, and advises keeping to its 24 h default time limit. Good for large arrays of short, restartable jobs.

It is deliberately excluded from automatic selection in our config, so you must ask for it:

```bash
fsl_sub -q scavenger -T 120 -R 8 -t tasks.txt -l logs
```

With `-q`, keep `-R` at 8 or below and don't use `-s` (see [known issues](#10-known-issues-and-gotchas)). For more memory or cores, pass them straight to Slurm:

```bash
fsl_sub -q scavenger -T 120 --extra="--mem=32G" --extra="--cpus-per-task=4" -t tasks.txt
```

### Project partitions

If your group pays for RACC2 capacity, you will have a partition named `racc_<project>` (access is controlled by a security group of the same name). See which partitions you can use with `sinfo -s`. To use one with fsl_sub, add it to `config/fsl_sub_racc2.yml` — there is a commented template at the bottom of the file — then select it with `-q racc_<project>`; the same `-q` caveat as scavenger applies.

---

## 9. Multi-threaded jobs

Some tools can use several cores (e.g. `eddy` CPU builds, `bedpostx`, MRtrix, ANTs). Request cores with `-s`:

```bash
fsl_sub -s 8 -T 240 -R 32 -N eddy_sub01 -l logs eddy --imain=... --nthr=8
```

Inside the job, fsl_sub sets `OMP_NUM_THREADS` (and similar) to the number of cores, and `$FSLSUB_NSLOTS` names the variable holding it (`${!FSLSUB_NSLOTS}` in bash). Single-threaded FSL tools (`bet`, `flirt`, `fast`) gain nothing from `-s`.

### A complete real-world example

[`examples/bnu_speech_pipeline/`](examples/bnu_speech_pipeline/) holds the scripts from a full task + resting-state fMRI study (48 participants): anatomical and fieldmap preprocessing, FEAT from template `.fsf` files, FIX cleaning, group ICA, dual regression, FreeSurfer and seed-based connectivity. They were written for FMRIB's jalapeño cluster, so their README explains how to translate each `fsl_sub` line to RACC2.

---

## 10. Known issues and gotchas

- **`-q <partition>` combined with `-R` > 8 or `-s` crashes** (`unhashable type: 'list'`) in fsl_sub 2.11.0 / plugin 1.7.0. Avoid `-q` for `short`/`long` — `-T` picks them for you — and use the `--extra` form in [§8](#8-using-scavenger) for scavenger.
- **Jobs run but don't appear in `squeue`?** You're using an FSL without the Slurm plugin (e.g. 6.0.7.12), so fsl_sub is running them on the login node. Run `which fsl_sub` and `fsl_sub --show_config | grep "^method"`; you want `/software/CINN/fsl/6.0.7.23/...` and `method: slurm`.
- **Jobs inherit your login environment** (`copy_environment: True`). Load FSL and any modules *before* submitting; activate the right conda env too.
- **Shell syntax** (pipes, `>`, `;`, loops) must be wrapped: `fsl_sub -n bash -c "fslstats img -M > mean.txt"`. `-n` skips fsl_sub's "does this program exist?" check.
- **Scratch is not backed up.** `/scratch2` and `/scratch3` are free and fast but can be cleared. Keep raw data in research storage (`/storage/research/...`) and copy final results back.
- **`--extra` needs `=`** when its value starts with `-`: `--extra="--qos=..."`, not `--extra "--qos=..."`.
- Email options (`-m`, `-M`) are ignored on RACC2's config.

---

## 11. Cheat sheet

```text
fsl_sub [options] <command and its arguments>

  -T MIN        expected run time (minutes)       → picks partition, sets --time
  -R GB         memory (GB)                       → --mem (and ceil(GB/8) cores)
  -N NAME       job name (for squeue and logs)
  -l DIR        log directory
  -t FILE       array job: one command per line
  -x N          max simultaneous array tasks
  -j ID[,ID]    wait for job(s) to finish
  --array_hold ID   task N waits for task N of array ID
  -s N          request N cores (multi-threaded tools)
  -q NAME       force a partition (only needed for scavenger)
  -n            don't check the command exists (use with bash -c "...")
  --export VAR=VALUE    set a variable inside the job
  --keep_jobscript      save the generated sbatch script (reproducibility)
  --show_config         print the configuration fsl_sub is using
  --has_queues          exit 0 if connected to Slurm

  FSLSUB_STRICTDEPS=1   held jobs need parents to succeed
  fsl_sub_report ID     job status
```

---

## 12. For maintainers: installing FSL on RACC2

How `/software/CINN/fsl/6.0.7.23` was set up, for whoever installs the next version. You need write access to `/software/CINN/fsl` and `/software/modules/CINN`.

**1. Install FSL** next to the existing versions. `getfsl.sh` needs `bzip2`, which RACC2 doesn't provide on `PATH`; borrow the anaconda module's copy:

```bash
mkdir -p ~/bin && ln -sf /software/applications/anaconda/2023.09-0/bin/bzip2 ~/bin/bzip2
export PATH=~/bin:$PATH

module purge; unset FSLDIR; umask 022
curl -Ls https://fsl.fmrib.ox.ac.uk/fsldownloads/fslconda/releases/getfsl.sh | sh -s -- /software/CINN/fsl/<version>
```

Give the destination after `-s --`, otherwise it installs to `~/fsl`. Wait for `FSL successfully installed`.

**2. Add the Slurm plugin and the CINN config:**

```bash
export FSLDIR=/software/CINN/fsl/<version>
$FSLDIR/bin/fsl_sub_config -h      # if it lists {shell,slurm}, skip the next line
$FSLDIR/bin/conda install -p $FSLDIR -c https://fsl.fmrib.ox.ac.uk/fslconda/public fsl_sub_plugin_slurm
curl -Ls https://raw.githubusercontent.com/simonyuanCINN/CINN_fsl_sub/main/config/fsl_sub_racc2.yml \
     -o $FSLDIR/etc/fslconf/fsl_sub.yml
```

**3. Add a module file:** copy [`modules/fsl/6.0.7.23.lua`](modules/fsl/6.0.7.23.lua) to `/software/modules/CINN/fsl/<version>.lua` and change the version in it. Lmod makes the highest version the default for `module load fsl`.

**4. Check in a fresh login:**

```bash
module load fsl/<version>
which fsl_sub feat                        # both under /software/CINN/fsl/<version>
fsl_sub --show_config | grep "^method"    # method: slurm
fsl_sub -T 10 -R 2 -N test hostname && squeue -u $USER
```

Then update the version number in this README.

---

### Further reading

- fsl_sub documentation: <https://git.fmrib.ox.ac.uk/fsl/fsl_sub>
- RACC2 batch jobs: <https://research.reading.ac.uk/act/knowledgebase/racc2-batch-jobs/>
- RACC2 introduction: <https://research.reading.ac.uk/act/knowledgebase/racc2-introduction/>

Licensed under GPL-3.0 (see `LICENSE`).
