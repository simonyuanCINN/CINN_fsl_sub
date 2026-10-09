#!/bin/bash
# 2_fieldmap.sh
# Prepare fieldmap image for FEAT analysis

# Root directory where the subject folders are located
ROOT_DIR="/Users/qimingyuan/OneDrive/BNU_project/BNU_scan/Data_analysis"

# TE difference for fsl_prepare_fieldmap
DELTATE=2.46          #TE difference in ms

# Loop over subject folders
for sub in {101..148}; do
    # Define the subject's fmap directory
    FMAP_DIR="${ROOT_DIR}/sub-${sub}/fmap"
    
    # Check if the fmap directory exists
    if [ -d "${FMAP_DIR}" ]; then
        # Find the magnitude and phase images
        magnitude_image=$(find "${FMAP_DIR}" -type f -name "*e1.nii.gz" | head -n 1)
        phase_image=$(find "${FMAP_DIR}" -type f -name "*ph.nii.gz" | head -n 1)

        # Print out what has been found
        echo "Processing subject sub-${sub}"
        echo "Magnitude image found: $magnitude_image"
        echo "Phase image found: $phase_image"
		
        # FSL reorient2std fieldmap
        fslreorient2std "$magnitude_image" "${FMAP_DIR}/fmap_mag"
		fslreorient2std "$phase_image" "${FMAP_DIR}/fmap_phase"
		
		# Run bias correction using FSL_anat
		if [ ! -d ${FMAP_DIR}/anat/fmap.anat ]; then
			fsl_anat \
			--strongbias  --nocrop  --noreg  --nosubcortseg  --noseg \
			-i ${FMAP_DIR}/fmap_mag \
			-o ${FMAP_DIR}/fmap
			echo "Running fsl_anat on fmap"
		else 
			echo "fsl_anat on fmap already run";
		fi

        echo "Running BET on bias corrected magnitude image for sub-${sub}..."
        # Run bet on the magnitude image
        bet "${FMAP_DIR}/fmap.anat/T1_biascorr" "${FMAP_DIR}/fmap_mag_brain" -R
            
        echo "Running fslmaths to erode edge on magnitude image for sub-${sub}..."
        # Erode two voxels from the edge
        fslmaths "${FMAP_DIR}/fmap_mag_brain" -ero "${FMAP_DIR}/fmap_mag_brain_ero1"
			
	    fslmaths "${FMAP_DIR}/fmap_mag_brain_ero1" -ero "${FMAP_DIR}/fmap_mag_brain_ero2"

        echo "Running fsl_prepare_fieldmap for sub-${sub}..."
        # Run fsl_prepare_fieldmap using phase and brain-extracted magnitude image
        fsl_prepare_fieldmap SIEMENS \
        "${FMAP_DIR}/fmap_phase" "${FMAP_DIR}/fmap_mag_brain_ero2" \
        "${FMAP_DIR}/fieldmap_rads" $DELTATE

        echo "Processing completed for subject sub-${sub}!"    
    else
        echo "Fmap directory not found for subject sub-${sub}, skipping..."
    fi
done
