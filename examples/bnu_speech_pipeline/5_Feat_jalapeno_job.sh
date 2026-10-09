#!/bin/bash
# 5_FEAT_jalapeno_job.sh
# Run FEAT/Melodic analysis on jalapeno

# Running for Run 1
FSF_DIRECTORY="./FEAT_jalapeno/run1"

# Loop through each .fsf file in the specified directory
for fsf_file in "$FSF_DIRECTORY"/*.fsf; do
    echo "Running FEAT analysis on $fsf_file"
    
    # Execute FEAT with the current .fsf file
    fsl_sub -q long.q feat "$fsf_file"
    
done

# Running for Run 2
FSF_DIRECTORY="./FEAT_jalapeno/run2"

# Loop through each .fsf file in the specified directory
for fsf_file in "$FSF_DIRECTORY"/*.fsf; do
    echo "Running FEAT analysis on $fsf_file"
    
    # Execute FEAT with the current .fsf file
    fsl_sub -q long.q feat "$fsf_file"
    
done

# Running for Run 1 rsa
FSF_DIRECTORY="./FEAT_jalapeno/run1_rsa"

# Loop through each .fsf file in the specified directory
for fsf_file in "$FSF_DIRECTORY"/*.fsf; do
    echo "Running FEAT analysis on $fsf_file"
    
    # Execute FEAT with the current .fsf file
    fsl_sub -q long.q feat "$fsf_file"
    
done

# Running for Run 1 extmotion
FSF_DIRECTORY="./FEAT_jalapeno/run1_extmotion"

# Loop through each .fsf file in the specified directory
for fsf_file in "$FSF_DIRECTORY"/*.fsf; do
    echo "Running FEAT analysis on $fsf_file"
    
    # Execute FEAT with the current .fsf file
    fsl_sub -q short feat "$fsf_file"
    
done

# Running for Run 2 extmotion
FSF_DIRECTORY="./FEAT_jalapeno/run2_f1f2_only_extmotion"

# Loop through each .fsf file in the specified directory
for fsf_file in "$FSF_DIRECTORY"/*.fsf; do
    echo "Running FEAT analysis on $fsf_file"
    
    # Execute FEAT with the current .fsf file
    fsl_sub -q short feat "$fsf_file"
    
done

# Running for Run 2 rsa
FSF_DIRECTORY="./FEAT_jalapeno/run2_rsa"

# Loop through each .fsf file in the specified directory
for fsf_file in "$FSF_DIRECTORY"/*.fsf; do
    echo "Running FEAT analysis on $fsf_file"
    
    # Execute FEAT with the current .fsf file
    fsl_sub -q long.q feat "$fsf_file"
    
done

# Running for Run 2 F1 trial
FSF_DIRECTORY="./FEAT_jalapeno/run2_f1_trial"

# Loop through each .fsf file in the specified directory
for fsf_file in "$FSF_DIRECTORY"/*.fsf; do
    echo "Running FEAT analysis on $fsf_file"
    
    # Execute FEAT with the current .fsf file
    fsl_sub -q short feat "$fsf_file"
    
done

# Running for Run 2 F1F2
FSF_DIRECTORY="./FEAT_jalapeno/run2_f1f2"

# Loop through each .fsf file in the specified directory
for fsf_file in "$FSF_DIRECTORY"/*.fsf; do
    echo "Running FEAT analysis on $fsf_file"
    
    # Execute FEAT with the current .fsf file
    fsl_sub -q short feat "$fsf_file"
    
done


# Running for RS 1
FSF_DIRECTORY="./FEAT_jalapeno/rs1"

# Loop through each .fsf file in the specified directory
for fsf_file in "$FSF_DIRECTORY"/*.fsf; do
    echo "Running FEAT analysis on $fsf_file"
    
    # Execute FEAT with the current .fsf file
    fsl_sub -q long.q feat "$fsf_file"
    
done

# Running for RS 2
FSF_DIRECTORY="./FEAT_jalapeno/rs2"

# Loop through each .fsf file in the specified directory
for fsf_file in "$FSF_DIRECTORY"/*.fsf; do
    echo "Running FEAT analysis on $fsf_file"
    
    # Execute FEAT with the current .fsf file
    fsl_sub -q long.q feat "$fsf_file"
    
done
