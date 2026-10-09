#!/bin/bash

# Loop through each subject from sub-101 to sub-148
for i in $(seq -w 101 148); do
    # Define the subject directory and anat folder path
    subject_dir="sub-${i}/anat"
    
    # Check if the anat directory exists
    if [ -d "$subject_dir" ]; then
        # Check if T1w_brain_new.nii.gz exists in the anat folder
        if [ -f "$subject_dir/T1w_brain_new.nii.gz" ]; then
            # Remove T1w_brain.nii.gz if it exists
            if [ -f "$subject_dir/T1w_brain.nii.gz" ]; then
                rm "$subject_dir/T1w_brain.nii.gz"
            fi
            # Rename T1w_brain_new.nii.gz to T1w_brain.nii.gz
            mv "$subject_dir/T1w_brain_new.nii.gz" "$subject_dir/T1w_brain.nii.gz"
            echo "Updated T1w_brain.nii.gz for subject sub-${i}"
        fi
    fi
done

# Updated T1w_brain.nii.gz for subject sub-109
# Updated T1w_brain.nii.gz for subject sub-111
# Updated T1w_brain.nii.gz for subject sub-112
# Updated T1w_brain.nii.gz for subject sub-114
# Updated T1w_brain.nii.gz for subject sub-115
# Updated T1w_brain.nii.gz for subject sub-119
# Updated T1w_brain.nii.gz for subject sub-120
# Updated T1w_brain.nii.gz for subject sub-121
# Updated T1w_brain.nii.gz for subject sub-123
# Updated T1w_brain.nii.gz for subject sub-124
# Updated T1w_brain.nii.gz for subject sub-125
# Updated T1w_brain.nii.gz for subject sub-126
# Updated T1w_brain.nii.gz for subject sub-127
# Updated T1w_brain.nii.gz for subject sub-128
# Updated T1w_brain.nii.gz for subject sub-129
# Updated T1w_brain.nii.gz for subject sub-130
# Updated T1w_brain.nii.gz for subject sub-131
# Updated T1w_brain.nii.gz for subject sub-133
# Updated T1w_brain.nii.gz for subject sub-135
# Updated T1w_brain.nii.gz for subject sub-136
# Updated T1w_brain.nii.gz for subject sub-137
# Updated T1w_brain.nii.gz for subject sub-138
# Updated T1w_brain.nii.gz for subject sub-139
# Updated T1w_brain.nii.gz for subject sub-140
# Updated T1w_brain.nii.gz for subject sub-141
# Updated T1w_brain.nii.gz for subject sub-142
# Updated T1w_brain.nii.gz for subject sub-143
# Updated T1w_brain.nii.gz for subject sub-144
# Updated T1w_brain.nii.gz for subject sub-145
# Updated T1w_brain.nii.gz for subject sub-146
# Updated T1w_brain.nii.gz for subject sub-147
# Updated T1w_brain.nii.gz for subject sub-148


# Move fsl_anat output to the anat folder and rename betted image

# Define the range of participant subfolders
for i in $(seq 101 148); do
    # Define the paths
    sub_folder="sub-${i}/anat"
    biascorr_file="${sub_folder}/T1w.anat/T1_biascorr.nii.gz"
    brain_file="${sub_folder}/T1w_brain.nii.gz"

    # Check if the bias-corrected file exists
    if [[ -f "$biascorr_file" ]]; then
        # Copy the bias-corrected file to the anat folder and rename it
        cp "$biascorr_file" "${sub_folder}/T1w_biascorr.nii.gz"
        echo "Copied and renamed T1_biascorr.nii.gz to T1w_biascorr.nii.gz for sub-${i}"
    else
        echo "Warning: T1_biascorr.nii.gz not found for sub-${i}"
    fi

    # Check if the brain file exists
    if [[ -f "$brain_file" ]]; then
        # Rename the brain file
        mv "$brain_file" "${sub_folder}/T1w_biascorr_brain.nii.gz"
        echo "Renamed T1w_brain.nii.gz to T1w_biascorr_brain.nii.gz for sub-${i}"
    else
        echo "Warning: T1w_brain.nii.gz not found for sub-${i}"
    fi
done
