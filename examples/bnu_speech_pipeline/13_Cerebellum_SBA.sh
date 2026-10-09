#!/bin/bash
## 13_Cerebellum_SBA.sh

# ---------- 0. Buckner cerebellar atlas ----------

# Original 17-network cerebellar atlas (MNI, neurological)
buckner_atlas_orig=/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/cerebellar_atlases/Buckner_2011/atl-Buckner17_space-MNI_dseg.nii

# Reoriented version to match FSL's MNI152 ("radiological") standard
buckner_atlas=/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/cerebellar_atlases/Buckner_2011/atl-Buckner17_space-MNI_dseg_fslstd.nii
buckner_atlas_L=/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/cerebellar_atlases/Buckner_2011/atl-Buckner17_space-MNI_dseg_fslstd_L.nii
buckner_atlas_R=/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/cerebellar_atlases/Buckner_2011/atl-Buckner17_space-MNI_dseg_fslstd_R.nii

# Do this once: aligns header/orientation to FSL's MNI 2mm standard
flirt \
  -in ${buckner_atlas_orig} \
  -ref $FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz \
  -out ${buckner_atlas}\
  -applyxfm -usesqform -interp nearestneighbour
  
fslmaths ${buckner_atlas} -roi 45 -1 0 -1 0 -1 0 -1 ${buckner_atlas_L}
fslmaths ${buckner_atlas} -roi 0 45 0 -1 0 -1 0 -1 ${buckner_atlas_R}

# ----------0. Define Left or Right Hemi ---------------
buckner_atlas=${buckner_atlas_R} 

# ---------- 1. Define cerebellar Buckner ROIs ----------
areas=('13;Buckner17_ContC_R')

# ---------- 2. Loop over subjects, process rs1 and rs2 ----------
for subj in $(seq -f "sub-%03g" 101 148); do

    subjDir=/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/$subj
    maskDir=/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/masks
    outputDir=/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/timeseries

    mkdir -p "${maskDir}"
    mkdir -p "${outputDir}/rs1"
    mkdir -p "${outputDir}/rs2"

    echo "=== Subject ${subj} ==="

    # -------- helper function-ish (inline) for one run --------
    for run in rs1 rs2; do

        echo "  -> Processing ${run}"

        runDir=${subjDir}/${run}.ica
        regdir=${runDir}/reg

        # ----- 2a. Bring Buckner (MNI) into functional space of this run -----
        flirt \
          -in  "${buckner_atlas}" \
          -ref "${runDir}/example_func" \
          -applyxfm \
          -init "${regdir}/standard2example_func.mat" \
          -interp nearestneighbour \
          -out "${maskDir}/${subj}_Buckner17_R_in_${run}"

        # ----- 2b. Make ROI masks and extract time series for this run -----
        for a in "${areas[@]}"; do

            num=${a%;*}
            region=${a#*;}

            lower=$(echo "$num" | awk '{printf "%.1f\n", $1 - 0.5}')
            upper=$(echo "$num" | awk '{printf "%.1f\n", $1 + 0.5}')

            # Mask for this run
            fslmaths "${maskDir}/${subj}_Buckner17_R_in_${run}" \
              -thr "${lower}" -uthr "${upper}" -bin \
              "${maskDir}/${subj}_${run}_${num}_${region}"

            # Time series for this run
            fsl_sub -q short fslmeants \
              -i "${runDir}/filtered_func_data_clean" \
              -o "${outputDir}/${run}/${subj}_${num}_${region}.csv" \
              -m "${maskDir}/${subj}_${run}_${num}_${region}"

        done

    done

done


#3. Seed-based Analysis (SCA) USING FSL

cd /vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS

# Loop through areas array
for area in "${areas[@]}"; do
    # Replace ; with _ to get seedDir and seedName
    seedDir=$(echo "$area" | tr ';' '_')
    seedName=$(echo "$area" | tr ';' '_')

    # Make directories for each seed
    mkdir -p /vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/SBA/${seedDir}
    ts1Dir=/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/timeseries/rs1
    ts2Dir=/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/timeseries/rs2
    rs1Dir=/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/SBA/${seedDir}/rs1
    rs2Dir=/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/SBA/${seedDir}/rs2

    mkdir -p ${rs1Dir}
    mkdir -p ${rs2Dir}

    # Loop through subjects
    for subj in $(seq -f "sub-%03g" 101 148); do

        input_rs1=${ts1Dir}/${subj}_${seedName}.csv
        output_rs1=${rs1Dir}/${subj}_${seedName}.txt
        input_rs2=${ts2Dir}/${subj}_${seedName}.csv
        output_rs2=${rs2Dir}/${subj}_${seedName}.txt

        # Compute the mean
        if [ -f "$input_rs1" ]; then
            mean1=$(awk -F, '{ sum += $1; n++ } END { if (n > 0) print sum / n; else print "0" }' "$input_rs1")
            awk -F, -v mean="$mean1" '{print $1 - mean}' "$input_rs1" > "$output_rs1"
        else
            echo "File $input_rs1 does not exist. Skipping."
        fi

        if [ -f "$input_rs2" ]; then
            mean2=$(awk -F, '{ sum += $1; n++ } END { if (n > 0) print sum / n; else print "0" }' "$input_rs2")
            awk -F, -v mean="$mean2" '{print $1 - mean}' "$input_rs2" > "$output_rs2"
        else
            echo "File $input_rs2 does not exist. Skipping."
        fi
    done
done

#Creating .fsf files for FEAT Analysis	

# Loop through areas
for area in "${areas[@]}"; do

    # Replace ';' with '_' for seedDir and seedName
    seedDir=$(echo "$area" | tr ';' '_')
    seedName=$(echo "$area" | tr ';' '_')

    # Loop through sessions
    for session in rs1 rs2; do

        # Loop through subjects
        for subj in $(seq -f "sub-%03g" 101 148); do

            subjDir=/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/smoothed/${session}
            seedDirPath=/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/SBA/${seedDir}
            rsDir=${seedDirPath}/${subj}/${session}

            # Create directories if they don't exist
            mkdir -p ${rsDir}

            # Define paths for files
            template_fsf=/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/SBA/Template.fsf
            new_input_file=${subjDir}/${subj}_${session}_filtered_func_data_clean_standard_s.nii.gz
            new_output_dir=${rsDir}
            new_ev_file=${seedDirPath}/${session}/${subj}_${seedName}.txt
            new_fsf_file=${rsDir}/${subj}_${session}_design.fsf

            # Update .fsf file with new paths
            sed -e "s|set feat_files(1) .*|set feat_files(1) \"$new_input_file\"|g" \
                -e "s|set fmri(outputdir) .*|set fmri(outputdir) \"$new_output_dir\"|g" \
                -e "s|set fmri(custom1) .*|set fmri(custom1) \"$new_ev_file\"|g" \
                "$template_fsf" > "$new_fsf_file"

        done

    done

done

#Run FEAT First Level Analysis on each subject for each seed (avoid quota limit, run each seed seperately)

seedDir=13_Buckner17_ContC_R

cd /vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS

for subj in $(seq -f "sub-%03g" 101 148); do
	
    fslDir=/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/SBA/${seedDir}
	subjDir=${fslDir}/${subj}

	for session in rs1 rs2; do
	
    fsl_sub -q short feat SBA/${seedDir}/${subj}/${session}/${subj}_${session}_design.fsf
	
	done
	
done

#Copy reg folder to each Feat Directories
#https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=fsl;a779b3b8.1408

cd /vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/SBA/${seedDir}
sourceDir=/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/SBA/dummy.ica/reg
baseDir=/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/SBA/${seedDir}

# Iterate over each directory matching the pattern "sub*"
for subDir in "$baseDir"/sub*; do
    # Check if the directory actually exists
    if [[ -d $subDir ]]; then
        # Iterate over each directory inside subDir matching the pattern "rs*.feat"
        for target in "$subDir"/rs*.feat; do
            # Check if the directory actually exists
            if [[ -d $target ]]; then
                cp -r "$sourceDir" "$target/"
            fi
        done
    fi
done

#Get first-level Feat directories for the higher level Feat analysis
cd /vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/SBA/${seedDir}

START_DIR=/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/SBA/${seedDir}

find "$START_DIR" -type d -path "*/sub*/rs*.feat" | grep "/rs1.feat" | sort -t '/' -k2 -n > inputFeat.txt
find "$START_DIR" -type d -path "*/sub*/rs*.feat" | grep "/rs2.feat" | sort -t '/' -k2 -n >> inputFeat.txt

#Run the higher level Feat analysis

cd /vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/SBA/${seedDir}

fsl_sub -q short feat /vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/SBA/${seedDir}/pairT.fsf