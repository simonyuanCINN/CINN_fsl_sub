# Real-world example: BNU speech fMRI pipeline

Simon Yuan's analysis scripts for a task + resting-state fMRI study (48 participants, `sub-101` … `sub-148`, two task runs and two resting-state runs each). They are shared **as written** to show how `fsl_sub` fits into a complete FSL pipeline, from T1 preprocessing to group ICA, dual regression and seed-based connectivity.

> These scripts were run on FMRIB's **jalapeño** cluster in Oxford, not on RACC2. Paths and queue names are jalapeño's. Read [Adapting to RACC2](#adapting-to-racc2) before reusing any `fsl_sub` line.

They are working notebooks, not push-button pipelines: several scripts contain steps that were run once, results pasted in as notes, interactive `fsleyes` / `fslipython` sessions, and alternative analyses. Run them **section by section**, not top to bottom.

---

## The pipeline

| Script | What it does | Runs where | fsl_sub? |
|---|---|---|---|
| `1_process_anat.sh` | T1: `fslreorient2std` → `robustfov` → `fsl_anat` (bias correction) → `bet` | local loop | — |
| `1a_rename_brain.sh` | Swap in hand-corrected brain masks; tidy `fsl_anat` outputs | local | — |
| `2_fieldmap.sh` | Fieldmap: reorient, bias-correct magnitude, `bet`, erode ×2, `fsl_prepare_fieldmap` (Siemens, ΔTE 2.46 ms) | local loop | — |
| `3_FEAT_fsf_gen.sh` | Make one first-level FEAT `.fsf` per subject from a template with `sed` | local | — |
| `4_Feat_jalapeno.sh` | Rewrite `.fsf` paths from laptop to cluster paths | local | — |
| `5_Feat_jalapeno_job.sh` | **Submit one FEAT job per `.fsf`** | cluster | ✅ |
| `6_Melodic_fsf_gen.sh` | Make single-subject resting-state `.fsf` files | local | — |
| `7_Melodic_jalapeno.sh` | Rewrite resting-state `.fsf` paths for the cluster | local | — |
| `8_fix_IC.sh` | FIX: feature extraction → train on 10 hand-labelled subjects → clean → warp to MNI | cluster | ✅ |
| `9_group_ICA_dual_reg.sh` | Smooth → group MELODIC (d = 20/25/50/150) → match to Smith 2009 RSNs → dual regression → extract values | cluster | ✅ |
| `10_freesurfer_recon_SBA.sh` | FreeSurfer `recon-all` → Destrieux (a2009s) seeds → seed-based connectivity with FEAT | cluster | ✅ |
| `11_ROI_dual_reg.sh` | Dual regression using task-fMRI clusters as spatial maps; FSLNets | cluster | ✅ |
| `13_Cerebellum_SBA.sh` | Seed-based connectivity from a Buckner-17 cerebellar network | cluster | ✅ |
| `14_Cortex_SBA.sh` | Seed-based connectivity from a Yeo-17 cortical network | cluster | ✅ |

### Patterns worth copying

- **Template `.fsf` + `sed` (scripts 3, 6, 13, 14).** Set up one subject in the FEAT GUI, save the `.fsf`, then generate the rest by substituting `feat_files`, `outputdir`, fieldmap and structural paths. Far less error-prone than clicking through the GUI 48 times.
- **One job per subject (scripts 5, 13, 14).** Loop over `.fsf` files and call `fsl_sub … feat file.fsf`. FEAT then submits its own internal stages through fsl_sub too.
- **Skip work that's already done (scripts 2, 8).** `if [ ! -d … ]` checks let you re-run a script after a failure without redoing finished subjects.
- **Big single jobs (scripts 9, 11).** Group MELODIC and dual regression with 5000 permutations run as one long, memory-hungry job — the case for `-T` and `-R`.

---

## Adapting to RACC2

### Queue names

jalapeño used Grid Engine queues with its own names. On RACC2, the `.q` queues (`veryshort.q`, `short.q`, `long.q`, `verylong.q`, `bigmem.q`) don't exist and fail with `Unrecognised queue`. `short` and `long` do exist, but with RACC2's limits (24 h and 30 days), and combining `-q` with `-R` above 8 GB hits the fsl_sub bug described in the main tutorial (§10). **Replace `-q` with `-T` (minutes) and `-R` (GB)** and let fsl_sub pick the partition:

| In these scripts | Used for | On RACC2 use |
|---|---|---|
| `-q veryshort.q` | smoothing, `applywarp` | `-T 30 -R 8` |
| `-q short.q`, `-q short` | `applywarp`, `fslmeants`, first-level FEAT | `-T 240 -R 8` (FEAT: `-T 240 -R 16`) |
| `-q long.q`, `-q long` | FEAT, dual regression | FEAT: `-T 240 -R 16`; dual regression (5000 perms): `-T 2880 -R 50` → `long` |
| `-q verylong.q` | `recon-all`, dual regression | `recon-all`: `-T 1080 -R 8`; dual regression: `-T 2880 -R 50` → `long` |
| `-q bigmem.q` | FIX | `-T 240 -R 64` |
| *(no options)* `fsl_sub melodic …` | group ICA | `-T 720 -R 64` for 48 subjects |

The numbers are starting points. After one subject finishes, check what it used with `sacct -j <jobid> --format=Elapsed,MaxRSS` and adjust.

Example — line 13 of `5_Feat_jalapeno_job.sh`:

```bash
# jalapeño
fsl_sub -q long.q feat "$fsf_file"
# RACC2
fsl_sub -T 240 -R 16 -N feat_$(basename "$fsf_file" .fsf) -l logs feat "$fsf_file"
```

### Paths

| In these scripts | Replace with |
|---|---|
| `/vols/Scratch/jlb080/Projects/...` (jalapeño scratch) | `/scratch2/$USER/...` or your `/storage/research/...` project space |
| `/cvmfs/fsl.fmrib.ox.ac.uk/...` or `/opt/fmrib/fsl/...` (FSL install) | `$FSLDIR` — e.g. `$FSLDIR/data/standard/MNI152_T1_2mm_brain` |
| `/Users/qimingyuan/...`, `/home/qyuan/...` (laptop) | wherever your data lives |

Scripts 4 and 7 exist only to rewrite laptop paths into cluster paths. If you build the `.fsf` files on RACC2 in the first place, you can skip them.

### FreeSurfer (script 10)

`module load freesurfer/7.2.0` is jalapeño's module. Check `module avail freesurfer` on RACC2. `recon-all` takes roughly 6–12 h per subject, so use `-T 1080 -R 8` — and submit it as an array (see the main tutorial, §5) rather than 48 separate jobs.

---

## Things to fix if you reuse these

Spotted while preparing this example; left unchanged in the scripts so they stay a faithful record.

- **`8_fix_IC.sh`, cleaning step:** `[ ! -d "$rs1_dir/filtered_func_data_clean.nii.gz" ]` tests for a *directory*, so it is always true and FIX re-runs every subject. Use `-f`.
- **`8_fix_IC.sh`, ordering:** steps 1→2→3→4 depend on each other but are submitted without holds. Run them one at a time, or capture job IDs and chain with `-j` (main tutorial, §6).
- **`9_group_ICA_dual_reg.sh` and `11_ROI_dual_reg.sh`:** contain pasted output lines (`dr_stage3_ic00…`) and an interactive Python session. Executing the whole file will error at those lines.
- **`10_freesurfer_recon_SBA.sh`:** `mkdir ${maskDir}` without `-p` errors on re-runs; the steps after `recon-all` must wait for it to finish (use `-j`).
- **`5_Feat_jalapeno_job.sh`:** submits ten analysis folders (`run1`, `run2`, `run1_rsa`, `rs1`, …), but scripts 4 and 7 only create `run1_extmotion`, `run2_extmotion`, `rs1` and `rs2` (script 5 looks for `run2_f1f2_only_extmotion`, not `run2_extmotion`). The others came from earlier versions of the scripts; comment out folders you haven't generated.
- **Line endings:** seven of these scripts were saved with Windows (CRLF) line endings, which make bash fail on Linux with errors like `syntax error near unexpected token $'do\r'`. They have been converted to Unix (LF) here. If you edit scripts on Windows, set your editor to LF, or run `sed -i 's/\r$//' script.sh` on RACC2.
- **Many small jobs:** scripts 9, 13 and 14 submit one `fslmaths`/`fslmeants` job per subject per run (~96 jobs that each take seconds). On RACC2, put the commands in a task file and submit one array instead.
