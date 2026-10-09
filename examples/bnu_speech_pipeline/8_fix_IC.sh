#!/bin/bash
# 8_fix_ICC.sh
# Using fix to clean rs_data and registered to standard space 
# https://fsl.fmrib.ox.ac.uk/fsl/docs/#/resting_state/fix

# 1. Fix feature extraction
for sub_num in {101..148}
do
  # Set the directory paths for rs1.ica and rs2.ica
  rs1_dir="sub-$sub_num/rs1.ica"
  rs2_dir="sub-$sub_num/rs2.ica"

  # Check if the fix directory exists in rs1.ica
  if [ ! -d "$rs1_dir/fix" ]; then
    echo "Running fix feature extraction on $rs1_dir"
    fsl_sub -q bigmem.q fix -f "$rs1_dir"
  else
    echo "Skipping $rs1_dir as 'fix' directory already exists."
  fi

  # Check if the fix directory exists in rs2.ica
  if [ ! -d "$rs2_dir/fix" ]; then
    echo "Running fix feature extraction on $rs2_dir"
    fsl_sub -q bigmem.q fix -f "$rs2_dir"
  else
    echo "Skipping $rs2_dir as 'fix' directory already exists."
  fi
done

# 2. Training fix using hand labels on the first 10 subjects
# https://www.caroline-nettekoven.com/post/ica-cleaning/

ica_path="/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis"

fsl_sub -q bigmem.q fix -t bnu_speech_rs -l ${ica_path}/sub-101/rs1.ica \
${ica_path}/sub-102/rs1.ica ${ica_path}/sub-103/rs1.ica ${ica_path}/sub-104/rs1.ica ${ica_path}/sub-105/rs1.ica \
${ica_path}/sub-106/rs1.ica ${ica_path}/sub-107/rs1.ica ${ica_path}/sub-108/rs1.ica ${ica_path}/sub-109/rs1.ica \
${ica_path}/sub-110/rs1.ica
 
 # 3. Cleaning all resting state data using trained fix model
 for sub_num in {101..148}
do
  # Set the directory paths for rs1.ica and rs2.ica
  rs1_dir="sub-$sub_num/rs1.ica"
  rs2_dir="sub-$sub_num/rs2.ica"

  # Check if the fix directory exists in rs1.ica
  if [ ! -d "$rs1_dir/filtered_func_data_clean.nii.gz" ]; then
    echo "Running fix cleaning on $rs1_dir"
    fsl_sub -q bigmem.q fix "$rs1_dir" bnu_speech_rs.pyfix_model 20
  else
    echo "Skipping $rs1_dir as fix cleaned data already exists."
  fi

  # Check if the fix directory exists in rs2.ica
  if [ ! -d "$rs2_dir/filtered_func_data_clean.nii.gz" ]; then
    echo "Running fix cleaning on $rs2_dir"
    fsl_sub -q bigmem.q fix "$rs2_dir" bnu_speech_rs.pyfix_model 20
  else
    echo "Skipping $rs2_dir as fix cleaned data already exists."
  fi
done

# 4. Register clean data to standard MNI space
for sub_num in {101..148}
do
  # Set the directory paths for rs1.ica and rs2.ica
  rs1_dir="sub-$sub_num/rs1.ica"
  rs2_dir="sub-$sub_num/rs2.ica"

  # Set output directories
  rs1_out="RS/standard/rs1"
  rs2_out="RS/standard/rs2"

  # Ensure the output directory exists
  mkdir -p "$rs1_out"
  mkdir -p "$rs2_out"

  echo "Registering sub-${sub_num} to standard space"

  # Check and process rs1
  if [ -f "${rs1_dir}/filtered_func_data_clean.nii.gz" ]; then
    fsl_sub -q short.q applywarp -r "${rs1_dir}/reg/standard.nii.gz" \
            -i "${rs1_dir}/filtered_func_data_clean.nii.gz" \
            -o "${rs1_out}/sub-${sub_num}_rs1_filtered_func_data_clean_standard.nii.gz" \
            --premat="${rs1_dir}/reg/example_func2highres.mat" \
            -w "${rs1_dir}/reg/highres2standard_warp.nii.gz"
  else
    echo "File not found: ${rs1_dir}/filtered_func_data_clean.nii.gz for sub-${sub_num}, skipping rs1"
  fi

  # Check and process rs2
  if [ -f "${rs2_dir}/filtered_func_data_clean.nii.gz" ]; then
    fsl_sub -q short.q applywarp -r "${rs2_dir}/reg/standard.nii.gz" \
            -i "${rs2_dir}/filtered_func_data_clean.nii.gz" \
            -o "${rs2_out}/sub-${sub_num}_rs2_filtered_func_data_clean_standard.nii.gz" \
            --premat="${rs2_dir}/reg/example_func2highres.mat" \
            -w "${rs2_dir}/reg/highres2standard_warp.nii.gz"
  else
    echo "File not found: ${rs2_dir}/filtered_func_data_clean.nii.gz for sub-${sub_num}, skipping rs2"
  fi

done