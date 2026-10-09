#!/bin/bash
# 3_FEAT_fsf_gen.sh
# Generate .fsf files for FEAT Analysis

#!/bin/bash

# 1. RUN 1
# Define the base paths
TEMPLATE_PATH="./template/run1_extmotion/run1_extmotion.fsf"
OUTPUT_FOLDER="./FEAT/run1_extmotion"
BASE_PATH="/home/qyuan/Projects/BNU_speech/Data_analysis"

# Ensure the output directory exists
mkdir -p "$OUTPUT_FOLDER"

# Loop over each subject from sub-101 to sub-148
for subject_id in $(seq 101 148); do
    subject="sub-${subject_id}"
    subject_path="${BASE_PATH}/${subject}"
    run1_path="${subject_path}/run1"
	run1_output="${subject_path}/run1_extmotion"
    fmap_path="${subject_path}/fmap"
    anat_path="${subject_path}/anat"
    
    # Define output .fsf path for this subject
    output_fsf="${OUTPUT_FOLDER}/${subject}_run1_extmotion.fsf"

    # Copy the template .fsf file to the new location to modify it
    cp "$TEMPLATE_PATH" "$output_fsf"

    # Find the MB6 and SB1 files within the run1 directory
    feat_files=$(find "$run1_path" -type f -name "*MB6*.nii.gz" | head -n 1)
    alt_ex_func=$(find "$run1_path" -type f -name "*SB1*.nii.gz" | head -n 1)

    # Substitute paths in the copied .fsf file
    sed -i "s|set fmri(outputdir) \".*\"|set fmri(outputdir) \"$run1_output\"|" "$output_fsf"
    sed -i "s|set feat_files(1) \".*\"|set feat_files(1) \"$feat_files\"|" "$output_fsf"
    sed -i "s|set alt_ex_func(1) \".*\"|set alt_ex_func(1) \"$alt_ex_func\"|" "$output_fsf"
    sed -i "s|set unwarp_files(1) \".*\"|set unwarp_files(1) \"$fmap_path/fieldmap_rads\"|" "$output_fsf"
    sed -i "s|set unwarp_files_mag(1) \".*\"|set unwarp_files_mag(1) \"$fmap_path/fmap_mag_brain_ero2\"|" "$output_fsf"
    sed -i "s|set highres_files(1) \".*\"|set highres_files(1) \"$anat_path/T1w_biascorr_brain\"|" "$output_fsf"
    
    echo "Generated FSF file for ${subject} at ${output_fsf}"
done

echo "FSF file generation completed for all subjects in Run 1."

# 2. RUN 2
# Define the base paths
TEMPLATE_PATH="./template/run2_extmotion/run2_extmotion.fsf"
OUTPUT_FOLDER="./FEAT/run2_extmotion"
BASE_PATH="/home/qyuan/Projects/BNU_speech/Data_analysis"

# Ensure the output directory exists
mkdir -p "$OUTPUT_FOLDER"

# Loop over each subject from sub-101 to sub-148
for subject_id in $(seq 101 148); do
    subject="sub-${subject_id}"
    subject_path="${BASE_PATH}/${subject}"
    run2_path="${subject_path}/run2"
	run2_output="${subject_path}/run2_extmotion"
    fmap_path="${subject_path}/fmap"
    anat_path="${subject_path}/anat"
    
    # Define output .fsf path for this subject
    output_fsf="${OUTPUT_FOLDER}/${subject}_run2_extmotion.fsf"

    # Copy the template .fsf file to the new location to modify it
    cp "$TEMPLATE_PATH" "$output_fsf"

    # Find the MB6 and SB1 files within the run1 directory
    feat_files=$(find "$run2_path" -type f -name "*MB6*.nii.gz" | head -n 1)
    alt_ex_func=$(find "$run2_path" -type f -name "*SB1*.nii.gz" | head -n 1)

    # Substitute paths in the copied .fsf file
    sed -i "s|set fmri(outputdir) \".*\"|set fmri(outputdir) \"$run2_output\"|" "$output_fsf"
    sed -i "s|set feat_files(1) \".*\"|set feat_files(1) \"$feat_files\"|" "$output_fsf"
    sed -i "s|set alt_ex_func(1) \".*\"|set alt_ex_func(1) \"$alt_ex_func\"|" "$output_fsf"
    sed -i "s|set unwarp_files(1) \".*\"|set unwarp_files(1) \"$fmap_path/fieldmap_rads\"|" "$output_fsf"
    sed -i "s|set unwarp_files_mag(1) \".*\"|set unwarp_files_mag(1) \"$fmap_path/fmap_mag_brain_ero2\"|" "$output_fsf"
    sed -i "s|set highres_files(1) \".*\"|set highres_files(1) \"$anat_path/T1w_biascorr_brain\"|" "$output_fsf"

    echo "Generated FSF file for ${subject} at ${output_fsf}"
done

echo "FSF file generation completed for all subjects in Run 2."



