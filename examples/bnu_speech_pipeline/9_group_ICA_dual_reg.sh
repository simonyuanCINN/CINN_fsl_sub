#!/bin/bash
# 9_group_ICA_dual_reg.sh
# Running group ICA and dual regression

# Step 1: Smooth data to 5 FWHM (convert FWHM to sigma 2.1)
cd /vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis || exit

stdDir="/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/standard"
smtDir="/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/smoothed"

for sub_num in {101..148}
do 
    mkdir -p "${smtDir}/rs1" "${smtDir}/rs2"

    echo "Smoothing data for sub-${sub_num}..."

    # Check if input files exist
    if [[ -f "${stdDir}/rs1/sub-${sub_num}_rs1_filtered_func_data_clean_standard.nii.gz" ]]; then
        fsl_sub -q veryshort.q fslmaths \
        "${stdDir}/rs1/sub-${sub_num}_rs1_filtered_func_data_clean_standard.nii.gz" \
        -s 2.1 \
        "${smtDir}/rs1/sub-${sub_num}_rs1_filtered_func_data_clean_standard_s.nii.gz"
    else
        echo "File not found: ${stdDir}/rs1/sub-${sub_num}_rs1_filtered_func_data_clean_standard.nii.gz"
    fi

    if [[ -f "${stdDir}/rs2/sub-${sub_num}_rs2_filtered_func_data_clean_standard.nii.gz" ]]; then
        fsl_sub -q veryshort.q fslmaths \
        "${stdDir}/rs2/sub-${sub_num}_rs2_filtered_func_data_clean_standard.nii.gz" \
        -s 2.1 \
        "${smtDir}/rs2/sub-${sub_num}_rs2_filtered_func_data_clean_standard_s.nii.gz"
    else
        echo "File not found: ${stdDir}/rs2/sub-${sub_num}_rs2_filtered_func_data_clean_standard.nii.gz"
    fi
done

# Step 2: Prepare input list for group ICA
echo "Generating input list for group ICA..."
smtDir="/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/smoothed"
ls -1 "${smtDir}/rs1/"*filtered_func_data_clean_standard_s.nii.gz > inputGroupICA.txt

# Run group ICA with 50 components
fsl_sub melodic \
  -i inputGroupICA.txt \
  -o groupICA50 \
  --tr=0.80 \
  --nobet \
  -a concat \
  -m $FSLDIR/data/standard/MNI152_T1_2mm_brain_mask.nii.gz \
  --report --Oall -d 50
  
fsl_sub melodic \
  -i inputGroupICA_outliers.txt \
  -o groupICA50_outliers \
  --tr=0.80 \
  --nobet \
  -a concat \
  -m $FSLDIR/data/standard/MNI152_T1_2mm_brain_mask.nii.gz \
  --report --Oall -d 50
  
fsl_sub melodic \
  -i inputGroupICA_adapters.txt \
  -o groupICA50_adapters \
  --tr=0.80 \
  --nobet \
  -a concat \
  -m $FSLDIR/data/standard/MNI152_T1_2mm_brain_mask.nii.gz \
  --report --Oall -d 50

# Run group ICA with 25 components
fsl_sub melodic \
  -i inputGroupICA.txt \
  -o groupICA25 \
  --tr=0.80 \
  --nobet \
  -a concat \
  -m $FSLDIR/data/standard/MNI152_T1_2mm_brain_mask.nii.gz \
  --report --Oall -d 25
  
# Run group ICA with 20 components
fsl_sub melodic \
  -i inputGroupICA.txt \
  -o groupICA20 \
  --tr=0.80 \
  --nobet \
  -a concat \
  -m $FSLDIR/data/standard/MNI152_T1_2mm_brain_mask.nii.gz \
  --report --Oall -d 20 
  
# Run group ICA with 150 components
fsl_sub melodic \
  -i inputGroupICA.txt \
  -o groupICA150 \
  --tr=0.80 \
  --nobet \
  -a concat \
  -m $FSLDIR/data/standard/MNI152_T1_2mm_brain_mask.nii.gz \
  --report --Oall -d 150

# Step 3: Correlate ICs with standard RSNs

rsDir="/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS"

fslcc --noabs -p 3 -t .204 \
  "${rsDir}/networks/PNAS_Smith09_rsn10.nii.gz" \
  "${rsDir}/groupICA50/melodic_IC.nii.gz" \
  >> "${rsDir}/groupICA50/nets_of_interest_Smith10.txt"

fslcc --noabs -p 3 -t .204 \
  "${rsDir}/networks/PNAS_Smith09_rsn10.nii.gz" \
  "${rsDir}/groupICA25/melodic_IC.nii.gz" \
  >> "${rsDir}/groupICA25/nets_of_interest_Smith10.txt"

# Step 4: Run dual regression

rsDir="/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS"
inputList="${rsDir}/input_dual_reg.txt"

ls -1 "${smtDir}/"*/*filtered_func_data_clean_standard_s.nii.gz > "$inputList"

# Dual regression for group ICA 25
fsl_sub -q verylong.q dual_regression \
  "${rsDir}/groupICA25/melodic_IC.nii.gz" 1 \
  "${rsDir}/glm/rs.mat" \
  "${rsDir}/glm/rs.con" 5000 \
  "${rsDir}/groupICA25_DR" \
  `cat /vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/input_dual_reg.txt`

# Dual regression for group ICA 50
fsl_sub -q verylong.q dual_regression \
  "${rsDir}/groupICA50/melodic_IC.nii.gz" 1 \
  "${rsDir}/glm/rs.mat" \
  "${rsDir}/glm/rs.con" 5000 \
  "${rsDir}/groupICA50_DR" \
  `cat /vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/input_dual_reg.txt`
  
  # Dual regression for group ICA 50 (remove outliers)
fsl_sub -T 9000 -R 50 dual_regression \
  "${rsDir}/groupICA50_outliers/melodic_IC.nii.gz" 1 \
  "${rsDir}/glm/rs_outliers.mat" \
  "${rsDir}/glm/rs_outliers.con" 5000 \
  "${rsDir}/groupICA50_outliers_DR" \
  `cat /vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/input_dual_reg_outliers.txt`
  
# Dual regression for group ICA 20
fsl_sub -q long dual_regression \
  "${rsDir}/groupICA20/melodic_IC.nii.gz" 1 \
  "${rsDir}/glm/rs.mat" \
  "${rsDir}/glm/rs.con" 5000 \
  "${rsDir}/groupICA20_DR" \
  `cat /vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/input_dual_reg.txt`
  
# Dual regression (first 2 steps) for group ICA 150 for FSLNests
fsl_sub -q verylong.q dual_regression \
  "${rsDir}/groupICA150/melodic_IC.nii.gz" 1 \
  "${rsDir}/glm/rs.mat" \
  "${rsDir}/glm/rs.con" 0 \
  "${rsDir}/groupICA150_DR" \
  `cat /vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/input_dual_reg.txt`

# Screen results of dual regression
# 1. pre>post 2. post>pre
rsDir="/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS"
cd "${rsDir}/groupICA25_DR"
for i in dr_stage3_ic00??_tfce_corrp_tstat?.nii.gz; do
    echo "$i $(fslstats "$i" -R)"
done

dr_stage3_ic0002_tfce_corrp_tstat2.nii.gz 0.000000 0.999600
dr_stage3_ic0010_tfce_corrp_tstat2.nii.gz 0.000000 0.998200

cd "${rsDir}/groupICA50_DR"
for i in dr_stage3_ic00??_tfce_corrp_tstat?.nii.gz; do
    echo "$i $(fslstats "$i" -R)"
done

dr_stage3_ic0000_tfce_corrp_tstat2.nii.gz 0.000000 0.999800
dr_stage3_ic0006_tfce_corrp_tstat2.nii.gz 0.000000 0.991200
dr_stage3_ic0007_tfce_corrp_tstat2.nii.gz 0.000000 0.998600
dr_stage3_ic0023_tfce_corrp_tstat2.nii.gz 0.000000 0.998200

cd "${rsDir}/groupICA50_outliers_DR"
for i in dr_stage3_ic00??_tfce_corrp_tstat?.nii.gz; do
    echo "$i $(fslstats "$i" -R)"
done

dr_stage3_ic0000_tfce_corrp_tstat2.nii.gz 0.000000 0.999400
dr_stage3_ic0005_tfce_corrp_tstat2.nii.gz 0.000000 0.986800
dr_stage3_ic0007_tfce_corrp_tstat2.nii.gz 0.000000 0.989400
dr_stage3_ic0014_tfce_corrp_tstat2.nii.gz 0.000000 0.995400
dr_stage3_ic0015_tfce_corrp_tstat2.nii.gz 0.000000 0.951400
dr_stage3_ic0019_tfce_corrp_tstat2.nii.gz 0.000000 0.984400

cd "${rsDir}/groupICA50_adapters_DR"
for i in dr_stage3_ic00??_tfce_corrp_tstat?.nii.gz; do
    echo "$i $(fslstats "$i" -R)"
done

dr_stage3_ic0000_tfce_corrp_tstat2.nii.gz 0.000000 0.999000
dr_stage3_ic0008_tfce_corrp_tstat2.nii.gz 0.000000 0.998800
dr_stage3_ic0009_tfce_corrp_tstat2.nii.gz 0.000000 0.989600
dr_stage3_ic0013_tfce_corrp_tstat2.nii.gz 0.000000 0.957000
dr_stage3_ic0015_tfce_corrp_tstat2.nii.gz 0.000000 0.964200


cd "${rsDir}/groupICA20_DR"
for i in dr_stage3_ic00??_tfce_corrp_tstat?.nii.gz; do
    echo "$i $(fslstats "$i" -R)"
done
dr_stage3_ic0000_tfce_corrp_tstat2.nii.gz 0.000000 0.977600
dr_stage3_ic0001_tfce_corrp_tstat2.nii.gz 0.000000 0.997000
dr_stage3_ic0005_tfce_corrp_tstat2.nii.gz 0.000000 0.968800
dr_stage3_ic0007_tfce_corrp_tstat2.nii.gz 0.000000 0.998400
dr_stage3_ic0008_tfce_corrp_tstat2.nii.gz 0.000000 0.997200
dr_stage3_ic0010_tfce_corrp_tstat2.nii.gz 0.000000 0.997200
dr_stage3_ic0011_tfce_corrp_tstat2.nii.gz 0.000000 0.957400
dr_stage3_ic0014_tfce_corrp_tstat2.nii.gz 0.000000 0.978400
dr_stage3_ic0019_tfce_corrp_tstat2.nii.gz 0.000000 0.986000

# View results in FSLeyes
fsleyes -std groupICA20/melodic_IC \
  -un -cm red-yellow -nc blue-lightblue -dr 4 15 \
  groupICA20_DR/dr_stage3_ic0019_tfce_corrp_tstat2.nii.gz \
  -cm green -dr 0.95 1 &

fsleyes -std groupICA50/melodic_IC \
  -un -cm red-yellow -nc blue-lightblue -dr 4 15 \
  groupICA50_DR/dr_stage3_ic0000_tfce_corrp_tstat2.nii.gz \
  -cm green -dr 0.95 1 &
  
fsleyes -std groupICA50/melodic_IC \
  -un -cm red-yellow -nc blue-lightblue -dr 4 15 \
  groupICA50_DR/dr_stage3_ic0007_tfce_corrp_tstat2.nii.gz \
  -cm green -dr 0.95 1 &
 
fsleyes -std groupICA50/melodic_IC \
  -un -cm red-yellow -nc blue-lightblue -dr 4 15 \
  groupICA50_DR/dr_stage3_ic0006_tfce_corrp_tstat2.nii.gz \
  -cm green -dr 0.95 1 &
  
fsleyes -std groupICA50/melodic_IC \
  -un -cm red-yellow -nc blue-lightblue -dr 4 15 \
  groupICA50_DR/dr_stage3_ic0023_tfce_corrp_tstat2.nii.gz \
  -cm green -dr 0.95 1 &
  
fsleyes -std groupICA50_outliers/melodic_IC \
  -un -cm red-yellow -nc blue-lightblue -dr 4 15 \
  groupICA50_outliers_DR/dr_stage3_ic0000_tfce_corrp_tstat2.nii.gz \
  -cm green -dr 0.95 1 &
  
fsleyes -std groupICA50_outliers/melodic_IC \
  -un -cm red-yellow -nc blue-lightblue -dr 4 15 \
  groupICA50_outliers_DR/dr_stage3_ic0005_tfce_corrp_tstat2.nii.gz \
  -cm green -dr 0.95 1 &
  
fsleyes -std groupICA50_outliers/melodic_IC \
  -un -cm red-yellow -nc blue-lightblue -dr 4 15 \
  groupICA50_outliers_DR/dr_stage3_ic0007_tfce_corrp_tstat2.nii.gz \
  -cm green -dr 0.95 1 &
  
fsleyes -std groupICA50_outliers/melodic_IC \
  -un -cm red-yellow -nc blue-lightblue -dr 4 15 \
  groupICA50_outliers_DR/dr_stage3_ic0014_tfce_corrp_tstat2.nii.gz \
  -cm green -dr 0.95 1 &
  
fsleyes -std groupICA50_outliers/melodic_IC \
  -un -cm red-yellow -nc blue-lightblue -dr 4 15 \
  groupICA50_outliers_DR/dr_stage3_ic0015_tfce_corrp_tstat2.nii.gz \
  -cm green -dr 0.95 1 &
  
fsleyes -std groupICA50_outliers/melodic_IC \
  -un -cm red-yellow -nc blue-lightblue -dr 4 15 \
  groupICA50_outliers_DR/dr_stage3_ic0019_tfce_corrp_tstat2.nii.gz \
  -cm green -dr 0.95 1 &
  
  
fsleyes -std groupICA50_adapters/melodic_IC \
  -un -cm red-yellow -nc blue-lightblue -dr 4 15 \
  groupICA50_adapters_DR/dr_stage3_ic0000_tfce_corrp_tstat2.nii.gz \
  -cm green -dr 0.95 1 &
  
fsleyes -std groupICA50_adapters/melodic_IC \
  -un -cm red-yellow -nc blue-lightblue -dr 4 15 \
  groupICA50_adapters_DR/dr_stage3_ic0008_tfce_corrp_tstat2.nii.gz \
  -cm green -dr 0.95 1 &
  
fsleyes -std groupICA50_adapters/melodic_IC \
  -un -cm red-yellow -nc blue-lightblue -dr 4 15 \
  groupICA50_adapters_DR/dr_stage3_ic0009_tfce_corrp_tstat2.nii.gz \
  -cm green -dr 0.95 1 &
  
fsleyes -std groupICA50_adapters/melodic_IC \
  -un -cm red-yellow -nc blue-lightblue -dr 4 15 \
  groupICA50_adapters_DR/dr_stage3_ic0013_tfce_corrp_tstat2.nii.gz \
  -cm green -dr 0.95 1 &
  
fsleyes -std groupICA50_adapters/melodic_IC \
  -un -cm red-yellow -nc blue-lightblue -dr 4 15 \
  groupICA50_adapters_DR/dr_stage3_ic0015_tfce_corrp_tstat2.nii.gz \
  -cm green -dr 0.95 1 &
  
 # Making mask
 fslmaths groupICA50_DR/dr_stage3_ic0023_tfce_corrp_tstat2.nii.gz \
  -thr 0.95 -uthr 1 \
  -bin mask_ic0023_thresh.nii.gz
  
 fslmaths groupICA50_DR/dr_stage3_ic0006_tfce_corrp_tstat2.nii.gz \
  -thr 0.95 -uthr 1 \
  -bin mask_ic0006_thresh.nii.gz
  
 # Extract median values for all sugjects
 #!/bin/bash

MASK="correlation/mask_ic0023_thresh.nii.gz"
OUTPUT="median_values_ic0023.txt"

> $OUTPUT  # Clear or create the output file

for i in $(seq -w 00000 00095); do
  SUBJECT="groupICA50_DR/dr_stage2_subject${i}_Z.nii.gz"
  if [ -f "$SUBJECT" ]; then
    MEDIAN=$(fslstats "$SUBJECT" -k "$MASK" -p 50)
    echo "${i} ${MEDIAN}" >> $OUTPUT
  else
    echo "${i} FILE NOT FOUND" >> $OUTPUT
  fi
done

MASK="correlation/mask_ic0006_thresh.nii.gz"
OUTPUT="median_values_ic0006.txt"

> $OUTPUT  # Clear or create the output file

for i in $(seq -w 00000 00095); do
  SUBJECT="groupICA50_DR/dr_stage2_subject${i}_Z.nii.gz"
  if [ -f "$SUBJECT" ]; then
    MEDIAN=$(fslstats "$SUBJECT" -k "$MASK" -p 50)
    echo "${i} ${MEDIAN}" >> $OUTPUT
  else
    echo "${i} FILE NOT FOUND" >> $OUTPUT
  fi
done

#Extract mean values

MASK="correlation/mask_ic0023_thresh.nii.gz"
OUTPUT="mean_values_ic0023.txt"

> $OUTPUT  # Clear or create the output file

for i in $(seq -w 00000 00095); do
  SUBJECT="groupICA50_DR/dr_stage2_subject${i}_Z.nii.gz"
  if [ -f "$SUBJECT" ]; then
    MEAN=$(fslstats "$SUBJECT" -k "$MASK" -M)
    echo "${i} ${MEAN}" >> $OUTPUT
  else
    echo "${i} FILE NOT FOUND" >> $OUTPUT
  fi
done

MASK="correlation/mask_ic0006_thresh.nii.gz"
OUTPUT="mean_values_ic0006.txt"

> $OUTPUT  # Clear or create the output file

for i in $(seq -w 00000 00095); do
  SUBJECT="groupICA50_DR/dr_stage2_subject${i}_Z.nii.gz"
  if [ -f "$SUBJECT" ]; then
    MEAN=$(fslstats "$SUBJECT" -k "$MASK" -M)
    echo "${i} ${MEAN}" >> $OUTPUT
  else
    echo "${i} FILE NOT FOUND" >> $OUTPUT
  fi
done


for i in $(seq 140 148); do
    mkdir -p sub-${i}
    scp -r jlb080@clint.fmrib.ox.ac.uk:/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/sub-${i}/run2_f1.feat ./sub-${i}/
done