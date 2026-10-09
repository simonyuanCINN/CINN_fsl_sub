#!/bin/bash
# 6_FEAT_fsf_gen.sh
# FEAT fsf file generation for Single subject ICA

# 1. RS 1
# Define the base paths
TEMPLATE_PATH="./template/rs1/rs1.fsf"
OUTPUT_FOLDER="./FEAT/rs1"
BASE_PATH="/home/qyuan/Projects/BNU_speech/Data_analysis"

# Ensure the output directory exists
mkdir -p "$OUTPUT_FOLDER"

# Loop over each subject from sub-101 to sub-148
for subject_id in $(seq 101 148); do
    subject="sub-${subject_id}"
    subject_path="${BASE_PATH}/${subject}"
    rs1_path="${subject_path}/rs1"
    fmap_path="${subject_path}/fmap"
    anat_path="${subject_path}/anat"
    
    # Define output .fsf path for this subject
    output_fsf="${OUTPUT_FOLDER}/${subject}_rs1.fsf"

    # Copy the template .fsf file to the new location to modify it
    cp "$TEMPLATE_PATH" "$output_fsf"

    # Find the MB6 and SB1 files within the run1 directory
    feat_files=$(find "$rs1_path" -type f -name "*MB6*.nii.gz" | head -n 1)
    alt_ex_func=$(find "$rs1_path" -type f -name "*SB1*.nii.gz" | head -n 1)

    # Substitute paths in the copied .fsf file
    sed -i "s|set fmri(outputdir) \".*\"|set fmri(outputdir) \"$rs1_path\"|" "$output_fsf"
    sed -i "s|set feat_files(1) \".*\"|set feat_files(1) \"$feat_files\"|" "$output_fsf"
    sed -i "s|set alt_ex_func(1) \".*\"|set alt_ex_func(1) \"$alt_ex_func\"|" "$output_fsf"
    sed -i "s|set unwarp_files(1) \".*\"|set unwarp_files(1) \"$fmap_path/fieldmap_rads\"|" "$output_fsf"
    sed -i "s|set unwarp_files_mag(1) \".*\"|set unwarp_files_mag(1) \"$fmap_path/fmap_mag_brain_ero2\"|" "$output_fsf"
    sed -i "s|set highres_files(1) \".*\"|set highres_files(1) \"$anat_path/T1w_biascorr_brain\"|" "$output_fsf"
    
    echo "Generated FSF file for ${subject} at ${output_fsf}"
done

echo "FSF file generation completed for all subjects in RS 1."

# 2. RS 2
# Define the base paths
TEMPLATE_PATH="./template/rs2/rs2.fsf"
OUTPUT_FOLDER="./FEAT/rs2"
BASE_PATH="/home/qyuan/Projects/BNU_speech/Data_analysis"

# Ensure the output directory exists
mkdir -p "$OUTPUT_FOLDER"

# Loop over each subject from sub-101 to sub-148
for subject_id in $(seq 101 148); do
    subject="sub-${subject_id}"
    subject_path="${BASE_PATH}/${subject}"
    rs2_path="${subject_path}/rs2"
    fmap_path="${subject_path}/fmap"
    anat_path="${subject_path}/anat"
    
    # Define output .fsf path for this subject
    output_fsf="${OUTPUT_FOLDER}/${subject}_rs2.fsf"

    # Copy the template .fsf file to the new location to modify it
    cp "$TEMPLATE_PATH" "$output_fsf"

    # Find the MB6 and SB1 files within the run1 directory
    feat_files=$(find "$rs2_path" -type f -name "*MB6*.nii.gz" | head -n 1)
    alt_ex_func=$(find "$rs2_path" -type f -name "*SB1*.nii.gz" | head -n 1)

    # Substitute paths in the copied .fsf file
    sed -i "s|set fmri(outputdir) \".*\"|set fmri(outputdir) \"$rs2_path\"|" "$output_fsf"
    sed -i "s|set feat_files(1) \".*\"|set feat_files(1) \"$feat_files\"|" "$output_fsf"
    sed -i "s|set alt_ex_func(1) \".*\"|set alt_ex_func(1) \"$alt_ex_func\"|" "$output_fsf"
    sed -i "s|set unwarp_files(1) \".*\"|set unwarp_files(1) \"$fmap_path/fieldmap_rads\"|" "$output_fsf"
    sed -i "s|set unwarp_files_mag(1) \".*\"|set unwarp_files_mag(1) \"$fmap_path/fmap_mag_brain_ero2\"|" "$output_fsf"
    sed -i "s|set highres_files(1) \".*\"|set highres_files(1) \"$anat_path/T1w_biascorr_brain\"|" "$output_fsf"

    echo "Generated FSF file for ${subject} at ${output_fsf}"
done

echo "FSF file generation completed for all subjects in RS 2."