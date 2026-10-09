#!/bin/bash
# 1_process_anat.sh
# Preprocessing T1w images (fslreorient2std, robustfov, fsl_anat, move and rename files, bet)

# Root directory where the subject folders are located
ROOT_DIR="/Users/qimingyuan/OneDrive/BNU_project/BNU_scan/Data_analysis"

# Loop over subject folders
for sub in {101..148}; do
    # Define the subject's anat directory
    ANAT_DIR="${ROOT_DIR}/sub-${sub}/anat"
    
    # Check if the anat directory exists
    if [ -d "${ANAT_DIR}" ]; then
        echo "Processing anat directory for sub-${sub}"

        # Loop through all .nii.gz files in the anat directory
        for nii_file in "${ANAT_DIR}"/2024*.nii.gz; do
        
            # Check if any .nii.gz files are found
            if [ -e "$nii_file" ]; then
                echo "Found file: $nii_file"

                # Step 1: Run fslreorient2std
                fslreorient2std "$nii_file" "${ANAT_DIR}/T1w_reoriented.nii.gz"

                # Step 2: Run robustfov
                fov_output="${ANAT_DIR}/T1w.nii.gz"
                robustfov -i "${ANAT_DIR}/T1w_reoriented.nii.gz" -r "$fov_output"
                echo "Completed robustfov: $fov_output"

                # Step 3: Run fsl_anat for advanced preprocessing
                fsl_anat -i "$fov_output" -o "${ANAT_DIR}/T1w.anat" --strongbias  --nocrop  --noreg  --nosubcortseg  --noseg
                echo "Completed fsl_anat processing"

                # Step 4: Move and rename T1_biascorr.nii.gz to T1w_biascorr.nii.gz
                biascorr_file="${ANAT_DIR}/T1w.anat/T1_biascorr.nii.gz"
                if [ -f "$biascorr_file" ]; then
                    mv "$biascorr_file" "${ANAT_DIR}/T1w_biascorr.nii.gz"
                    echo "Moved and renamed T1_biascorr.nii.gz to T1w_biascorr.nii.gz"
                else
                    echo "T1_biascorr.nii.gz not found, skipping..."
                    continue
                fi

                # Step 5: Run BET on T1w_biascorr.nii.gz
                brain_output="${ANAT_DIR}/T1w_biascorr_brain.nii.gz"
                bet "${ANAT_DIR}/T1w_biascorr.nii.gz" "$brain_output" -f 0.35
                echo "Completed BET: $brain_output"
            fi
        done
    else
        echo "Anat directory not found for sub-${sub}, skipping..."
    fi
done

echo "Processing completed for all subjects."


# Log for T1w data processing
# Head motion: sub-104, sub-106, sub-116
