#!/bin/bash
# 7_FEAT_jalapeno.sh
# FEAT fsf file generation for Single subject ICA on jalapeno

# Define the original and new paths
OLD_REGSTANDARD="/home/qyuan/fsl/data/standard/MNI152_T1_2mm_brain"
NEW_REGSTANDARD="/opt/fmrib/fsl/data/standard/MNI152_T1_2mm_brain"
OLD_PROJECT_PATH="/home/qyuan/Projects"
NEW_PROJECT_PATH="/vols/Scratch/jlb080/Projects"

# Define the original and new output folders
ORIGINAL_FEAT_FOLDER="./FEAT/rs1"
NEW_FEAT_FOLDER="./FEAT_jalapeno/rs1"

# Ensure the new output directory exists
mkdir -p "$NEW_FEAT_FOLDER"

# Find all .fsf files in the original FEAT/run1 folder
for fsf_file in "$ORIGINAL_FEAT_FOLDER"/*.fsf; do
    # Get the base filename (e.g., sub-101_run1.fsf)
    base_filename=$(basename "$fsf_file")

    # Define the path for the new .fsf file
    new_fsf_file="$NEW_FEAT_FOLDER/$base_filename"

    # Copy the original .fsf file to the new location
    cp "$fsf_file" "$new_fsf_file"

    # Make the necessary replacements
    sed -i "s|$OLD_REGSTANDARD|$NEW_REGSTANDARD|g" "$new_fsf_file"
    sed -i "s|$OLD_PROJECT_PATH|$NEW_PROJECT_PATH|g" "$new_fsf_file"

    echo "Updated FSF file created at ${new_fsf_file}"
done

echo "All FSF files for rs 1 have been modified and saved to $NEW_FEAT_FOLDER."

# Define the original and new output folders
ORIGINAL_FEAT_FOLDER="./FEAT/rs2"
NEW_FEAT_FOLDER="./FEAT_jalapeno/rs2"

# Ensure the new output directory exists
mkdir -p "$NEW_FEAT_FOLDER"

# Find all .fsf files in the original FEAT/run1 folder
for fsf_file in "$ORIGINAL_FEAT_FOLDER"/*.fsf; do
    # Get the base filename (e.g., sub-101_run1.fsf)
    base_filename=$(basename "$fsf_file")

    # Define the path for the new .fsf file
    new_fsf_file="$NEW_FEAT_FOLDER/$base_filename"

    # Copy the original .fsf file to the new location
    cp "$fsf_file" "$new_fsf_file"

    # Make the necessary replacements
    sed -i "s|$OLD_REGSTANDARD|$NEW_REGSTANDARD|g" "$new_fsf_file"
    sed -i "s|$OLD_PROJECT_PATH|$NEW_PROJECT_PATH|g" "$new_fsf_file"

    echo "Updated FSF file created at ${new_fsf_file}"
done

echo "All FSF files for rs 2 have been modified and saved to $NEW_FEAT_FOLDER."