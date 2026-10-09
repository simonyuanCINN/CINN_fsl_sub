# CINN_fsl_sub

**Running FSL jobs on the University of Reading RACC2 cluster with `fsl_sub`**

A teaching template for members of the Centre for Integrative Neuroscience and Neurodynamics (CINN). Work through it top to bottom the first time; afterwards, copy the example scripts and edit the paths.

> Maintainer: Simon Yuan (CINN). Tested against fsl_sub 2.11.0 with fsl_sub_plugin_slurm 1.7.0. RACC2 partition details are from the RACC2 knowledge base as of October 2026; check `sinfo -s` for current values.

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

```
CINN_fsl_sub/
├── README.md                    ← this tutorial
├── config/fsl_sub_racc2.yml     ← fsl_sub settings for RACC2's Slurm partitions
├── setup/racc2_fsl_env.sh       ← source from ~/.bashrc: loads FSL, points to the config
└── examples/
    ├── 00_check_setup.sh        ← is everything wired up?
    ├── 01_single_job.sh         ← one bet job
    ├── 02_array_bet.sh          ← bet for every subject as an array
    └── 03_pipeline_holds.sh     ← bet → fast → summary, chained with holds
```

---

## 1. Why fsl_sub?

RACC2 uses the **Slurm** scheduler. You *could* write an `sbatch` script for every FSL command, but `fsl_sub` lets you put a prefix in front of the command you already know:

```bash
bet T1.nii.gz T1_brain               # runs here, now
fsl_sub -T 15 -R 4 bet T1.nii.gz T1_brain   # runs on a compute node; prints a job ID
```

It is also what FSL's own tools use internally: `feat`, `melodic`, `bedpostx`, `probtrackx2`, `randomise_parallel`, `tbss` and others call `fsl_sub` themselves. **Once fsl_sub is configured for Slurm, those tools spread their work across the cluster automatically.** If it is *not* configured, they run everything on the login node — which RACC2 does not permit for heavy work.

`fsl_sub` is developed by FMRIB, Oxford: <https://git.fmrib.ox.ac.uk/fsl/fsl_sub>.

---

## 2. One-time setup

### 2.1 Log in

```bash
ssh -X <username>@racc.rdg.ac.uk
```

This is a load balancer that sends you to the least-busy login node. Mac users need XQuartz for `-X` (GUIs such as `fsleyes`); Windows users can use MobaXterm.

Login nodes are for editing, testing and submitting — each user is capped at 12 cores and 256 GB there, and background jobs are not allowed. Anything heavy goes through `fsl_sub`.

### 2.2 Get this repository

```bash
cd ~
git clone https://github.com/simonyuanCINN/CINN_fsl_sub.git
```

### 2.3 Make FSL and fsl_sub available

Edit the lines marked `EDIT ME` in `setup/racc2_fsl_env.sh`, then add it to your `~/.bashrc`:

```bash
echo 'source ~/CINN_fsl_sub/setup/racc2_fsl_env.sh' >> ~/.bashrc
source ~/.bashrc
```

The script does three things:

| What | Why |
|---|---|
| Loads FSL (`module load fsl`, or your own `$FSLDIR`) | Check what exists with `module avail fsl` |
| `export FSLSUB_CONF=.../config/fsl_sub_racc2.yml` | Tells fsl_sub about RACC2's partitions |
| `export FSLSUB_EXTRA_TPC="--threads-per-core=1"` | RACC2 asks every job to use whole physical cores |

### 2.4 Install the Slurm plugin (if needed)

`fsl_sub` ships with FSL, but the **Slurm plugin** is separate. Without it, fsl_sub silently falls back to running jobs locally. Check:

```bash
fsl_sub --has_queues && echo "Slurm OK" || echo "running locally - plugin/config missing"
```

If it says "running locally", install the plugin into the same environment as fsl_sub:

```bash
# FSL's own conda environment (FSL ≥ 6.0.6):
$FSLDIR/bin/conda install -p $FSLDIR -c https://fsl.fmrib.ox.ac.uk/fslconda/public fsl_sub_plugin_slurm
# or, if fsl_sub was installed with pip:
pip install --user fsl_sub_plugin_slurm
```

If FSL is a central module you can't write to, ask DTS (or the module maintainer) to add `fsl_sub_plugin_slurm`.

### 2.5 Check

```bash
bash ~/CINN_fsl_sub/examples/00_check_setup.sh
```

It confirms FSL is loaded, that fsl_sub sees the Slurm queues, and submits a tiny test job.

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

`scavenger` runs on **all** RACC2 nodes (including newer and project-owned ones), allows up to 3 days and has no cap on how much you use at once — but your job **can be killed and re-queued** if the node's owners need it. Good for large arrays of short, restartable jobs.

It is deliberately excluded from automatic selection in our config, so you must ask for it:

```bash
fsl_sub -q scavenger -T 120 -R 8 -t tasks.txt -l logs
```

With `-q`, keep `-R` at 8 or below and don't use `-s` (see [known issues](#10-known-issues-and-gotchas)). For more memory or cores, pass them straight to Slurm:

```bash
fsl_sub -q scavenger -T 120 --extra="--mem=32G" --extra="--cpus-per-task=4" -t tasks.txt
```

---

## 9. Multi-threaded jobs

Some tools can use several cores (e.g. `eddy` CPU builds, `bedpostx`, MRtrix, ANTs). Request cores with `-s`:

```bash
fsl_sub -s 8 -T 240 -R 32 -N eddy_sub01 -l logs eddy --imain=... --nthr=8
```

Inside the job, fsl_sub sets `OMP_NUM_THREADS` (and similar) to the number of cores, and `$FSLSUB_NSLOTS` names the variable holding it (`${!FSLSUB_NSLOTS}` in bash). Single-threaded FSL tools (`bet`, `flirt`, `fast`) gain nothing from `-s`.

---

## 10. Known issues and gotchas

- **`-q <partition>` combined with `-R` > 8 or `-s` crashes** (`unhashable type: 'list'`) in fsl_sub 2.11.0 / plugin 1.7.0. Avoid `-q` for `short`/`long` — `-T` picks them for you — and use the `--extra` form in [§8](#8-using-scavenger) for scavenger.
- **No Slurm plugin = jobs run on the login node.** Always check `fsl_sub --has_queues` on a new account.
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

### Further reading

- fsl_sub documentation: <https://git.fmrib.ox.ac.uk/fsl/fsl_sub>
- RACC2 batch jobs: <https://research.reading.ac.uk/act/knowledgebase/racc2-batch-jobs/>
- RACC2 introduction: <https://research.reading.ac.uk/act/knowledgebase/racc2-introduction/>

Licensed under GPL-3.0 (see `LICENSE`).
