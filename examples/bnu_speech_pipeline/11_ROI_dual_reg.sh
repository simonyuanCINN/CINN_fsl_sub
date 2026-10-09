#!/bin/bash
# 11_ROI_dual_reg.sh
# Running dual regression based on task MRI results

# ---- settings ----
map=zstat1.nii.gz      # spatial/stat map in standard space
thr=3.1                # threshold
minvox=50              # minimum cluster size in voxels

# 1) keep only positive values above threshold
fslmaths "$map" -thr $thr pos.nii.gz

# 2) label positive clusters (26-connected) and drop tiny ones
cluster -i pos.nii.gz -t $thr --minextent=$minvox --connectivity=26 \
  --oindex=pos_index.nii.gz --olmax=pos_lmax.txt

# 3) build weighted cluster maps (each volume keeps original Z values)
#    (Parse actual label IDs from the cluster report to be safe)
labels=$(awk 'NR>1{print $1}' pos_lmax.txt | sort -n | uniq)

for i in $labels; do
  # binary mask for the i-th cluster label
  fslmaths pos_index.nii.gz -thr $i -uthr $i -bin tmp_mask.nii.gz
  # apply mask to the weighted (thresholded) positive map
  fslmaths pos.nii.gz -mas tmp_mask.nii.gz "pos_wcl${i}.nii.gz"
done
rm -f tmp_mask.nii.gz

# 4) merge weighted clusters into one 4D file for dual regression
fslmerge -t task_clusters_pos_weighted_4D.nii.gz pos_wcl*.nii.gz

# 5) run dual regression on task template
rsDir="/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS"

fsl_sub -q long -R 100 dual_regression \
  "${rsDir}/task_template/f1_extmotion/task_clusters_pos_weighted_4D.nii.gz" 1 \
  "${rsDir}/glm/rs.mat" \
  "${rsDir}/glm/rs.con" 5000 \
  "${rsDir}/task_f1_extmotion.DR" \
  `cat /vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/input_dual_reg.txt`
  
# 6) view dual regression results
cd "${rsDir}/task_f1_extmotion.DR"
for i in dr_stage3_ic00??_tfce_corrp_tstat?.nii.gz; do
    echo "$i $(fslstats "$i" -R)"
done

dr_stage3_ic0000_tfce_corrp_tstat2.nii.gz 0.000000 0.974600
dr_stage3_ic0004_tfce_corrp_tstat2.nii.gz 0.000000 0.988800
dr_stage3_ic0006_tfce_corrp_tstat2.nii.gz 0.000000 0.992000
dr_stage3_ic0008_tfce_corrp_tstat2.nii.gz 0.000000 0.950400
dr_stage3_ic0009_tfce_corrp_tstat2.nii.gz 0.000000 0.964400

fsleyes -std task_template/f1_extmotion/task_clusters_pos_weighted_4D.nii.gz \
  -un -cm red-yellow -nc blue-lightblue -dr 3.1 6 \
  task_f1_extmotion.DR/dr_stage3_ic0004_tfce_corrp_tstat2.nii.gz \
  -cm green -dr 0.95 1 &
  
fsleyes -std task_template/f1_extmotion/task_clusters_pos_weighted_4D.nii.gz \
  -un -cm red-yellow -nc blue-lightblue -dr 3.1 6 \
  task_f1_extmotion.DR/dr_stage3_ic0006_tfce_corrp_tstat2.nii.gz \
  -cm green -dr 0.95 1 &
  
fsleyes -std task_template/f1_extmotion/task_clusters_pos_weighted_4D.nii.gz \
  -un -cm red-yellow -nc blue-lightblue -dr 3.1 6 \
  task_f1_extmotion.DR/dr_stage3_ic0009_tfce_corrp_tstat2.nii.gz \
  -cm green -dr 0.95 1 &
  
# 6) run fsl_nets on intrested clusters

# generate figure for visualisation
slices_summary task_template/f1_extmotion/task_clusters_pos_weighted_4D.nii.gz 3.1 $FSLDIR/data/standard/MNI152_T1_2mm task_f1_extmotion.sum -1

fslipython
%matplotlib
import fsl.nets as nets
ts = nets.load('./task_f1_extmotion.DR/',
               tr=0.8,
               thumbnaildir='./task_f1_extmotion.sum/')

nets.plot_spectra(ts)
nets.plot_timeseries(ts)

Fnetmats = nets.netmats(ts, method='corr')
Pnetmats = nets.netmats(ts, method='ridgep')

import numpy as np
np.seterr(divide='ignore', invalid='ignore')

Znet_F, Mnet_F = nets.groupmean(ts,
                                Fnetmats,
                                plot=False)
Znet_P, Mnet_P = nets.groupmean(ts,
                                Pnetmats,
                                plot=True,
                                title='Partial correlation')
								
nets.plot_hierarchy(ts, Znet_F, Znet_P,
                    lowlabel='Full correlations',
                    highlabel='Partial correlations')
					
p_corr,p_uncorr = nets.glm(ts,
                           Pnetmats,
                           'glm/rs.mat',
                           'glm/rs.con');

nets.boxplots(ts, Pnetmats, Znet_P, p_corr[1], groups=(6, 6))