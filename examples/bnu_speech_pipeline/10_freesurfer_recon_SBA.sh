#!/bin/bash
# 10_freesurfer_recon_SBA.sh
# Recon_all structure images and run Seed-based Analysis

export FREESURFER_HOME=/Applications/freesurfer/7.2.0
export SUBJECTS_DIR=$FREESURFER_HOME/subjects
module load freesurfer/7.2.0
export SUBJECTS_DIR=/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/Recon_all

# 1. Freesurfer Recon_all

for subj in $(seq -f "sub-%03g" 101 148); do
    echo "Reconstruct $subj"

    ANATVOL=/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/$subj/anat/T1w_biascorr.nii.gz

    fsl_sub -q verylong.q recon-all -subject $subj -i $ANATVOL -all

done

# 2. Change to FSL/MNI space

for subj in $(seq -f "sub-%03g" 101 148); do

    echo "Processing $subj"
    
    atlas=a2009s
    subjDir=/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/$subj
    fsDir=/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/Recon_all/$subj

    # Convert atlas to native T1 spaceqstat
    mri_label2vol --seg $fsDir/mri/aparc.${atlas}+aseg.mgz --temp $fsDir/mri/rawavg.mgz --o $fsDir/mri/aparc.${atlas}+aseg_inT1.mgz --regheader $fsDir/mri/aseg.mgz
    mri_convert --in_type mgz --out_type nii $fsDir/mri/aparc.${atlas}+aseg_inT1.mgz $fsDir/aparc.${atlas}+aseg_inT1.nii.gz

    # Warp to functional space with nearest neighbor interpolation
    fsl_sub -q veryshort.q applywarp -r $subjDir/rs1.ica/reg/example_func.nii.gz \
          -i $fsDir/aparc.${atlas}+aseg_inT1.nii.gz \
          -o $fsDir/aparc.${atlas}+aseg_fxn.nii.gz \
          --premat=$subjDir/rs1.ica/reg/highres2example_func.mat \
          --interp=nn 

done

# 3. Making mask images from task-state fmri (optional)
fslstats cluster_mask_zstat1.nii.gz -R

for cluster_id in $(seq 1 $(fslstats cluster_mask_zstat1.nii.gz -R | awk '{print int($2)}')); do
    fslmaths cluster_mask_zstat1.nii.gz -thr ${cluster_id} -uthr ${cluster_id} -bin cluster_mask${cluster_id}_zstat1.nii.gz
done

# 4. Export Seed timeseries (based on task-state group results)
areas=( '12112;ctx_rh_G_front_inf-Opercular' \
        '12114;ctx_rh_G_front_inf-Triangul' \
        '11128;ctx_lh_G_postcentral' \
        '12128;ctx_rh_G_postcentral' \
        '11129;ctx_lh_G_precentral' \
        '12129;ctx_rh_G_precentral' \
        '12125;ctx_rh_G_pariet_inf-Angular' \
        '12126;ctx_rh_G_pariet_inf-Supramar' \
        '8;Left-Cerebellum-Cortex' )
         
for subj in $(seq -f "sub-%03g" 101 148); do
   
    atlas=a2009s
    #DKTatlas
    #a2009s
	
    subjDir=/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/$subj
    fsDir=/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/Recon_all/$subj
    maskDir=/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/masks
    outputDir=/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/timeseries
	
	mkdir ${maskDir}
	mkdir ${outputDir}/rs1
	mkdir ${outputDir}/rs2
   
        for a in "${areas[@]}"
        do

           num=${a%;*}
           region=${a#*;} 


           lower=$(echo "$num" | awk '{printf "%.1f \n", $1-.5}')
           upper=$(echo "$num" | awk '{printf "%.1f \n", $1+.5}')
           
           fslmaths $fsDir/aparc.${atlas}+aseg_fxn.nii.gz -thr $lower -uthr $upper -bin $maskDir/${subj}_$num
           echo $outputDir/${subj}-${num}-${region}.csv
           fslmeants -i $subjDir/rs1.ica/filtered_func_data_clean -o $outputDir/rs1/${subj}_${num}_${region}.csv -m $maskDir/${subj}_$num
		   fslmeants -i $subjDir/rs2.ica/filtered_func_data_clean -o $outputDir/rs2/${subj}_${num}_${region}.csv -m $maskDir/${subj}_$num
		   done
		   
done
  
 
#5. Seed-based Analysis (SCA) USING FSL

cd /vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS

areas=( '12112;ctx_rh_G_front_inf-Opercular' \
        '12114;ctx_rh_G_front_inf-Triangul' \
        '11128;ctx_lh_G_postcentral' \
        '12128;ctx_rh_G_postcentral' \
        '11129;ctx_lh_G_precentral' \
        '12129;ctx_rh_G_precentral' \
        '12125;ctx_rh_G_pariet_inf-Angular' \
        '12126;ctx_rh_G_pariet_inf-Supramar' \
        '8;Left-Cerebellum-Cortex' )

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

# Define areas
areas=( '12112;ctx_rh_G_front_inf-Opercular' \
        '12114;ctx_rh_G_front_inf-Triangul' \
        '11128;ctx_lh_G_postcentral' \
        '12128;ctx_rh_G_postcentral' \
        '11129;ctx_lh_G_precentral' \
        '12129;ctx_rh_G_precentral' \
        '12125;ctx_rh_G_pariet_inf-Angular' \
        '12126;ctx_rh_G_pariet_inf-Supramar' \
        '8;Left-Cerebellum-Cortex' )

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

seedDir=12126_ctx_rh_G_pariet_inf-Supramar

cd /vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS

for subj in $(seq -f "sub-%03g" 101 148); do
	
    fslDir=/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/SBA/${seedDir}
	subjDir=${fslDir}/${subj}

	for session in rs1 rs2; do
	
    fsl_sub feat SBA/${seedDir}/${subj}/${session}/${subj}_${session}_design.fsf
	
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

START_DIR=//vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/SBA/${seedDir}

find "$START_DIR" -type d -path "*/sub*/rs*.feat" | grep "/rs1.feat" | sort -t '/' -k2 -n > inputFeat.txt
find "$START_DIR" -type d -path "*/sub*/rs*.feat" | grep "/rs2.feat" | sort -t '/' -k2 -n >> inputFeat.txt

#Run group level analysis using Feat-higher level Analysis

cd /vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/SBA/${seedDir}

fsf_file=/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/SBA/${seedDir}/pairT.fsf
input_file=/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/SBA/${seedDir}/inputFeat.txt
output_file=/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/SBA/${seedDir}/pairT.fsf
new_output_dir=/vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/SBA/${seedDir}/pairT

awk 'NR==FNR {
     a[NR]=$0
     next
}
/set feat_files\([1-9][0-9]*\)/ {
     n++
     print "set feat_files("n") "a[n]""
     next
}
{
     print
}' "$input_file" "$fsf_file" > "$output_file"

sed -i "s|set fmri(outputdir) .*|set fmri(outputdir) $new_output_dir|" "$output_file"

#Run the higher level Feat analysis

cd /vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/SBA/${seedDir}

fsl_sub feat /vols/Scratch/jlb080/Projects/BNU_speech/Data_analysis/RS/SBA/${seedDir}/pairT.fsf


#############ALL LABELS IN DKTatlas#####################
     
areas=( '11;Left-Caudate' \
        '12;Left-Putamen' \
        '17;Left-Hippocampus' \
        '50;Right-Caudate' \
        '51;Right-Putamen' \
        '53;Right-Hippocampus ' \
        '11112;ctx_lh_G_front_inf-Opercular' \
        '11114;ctx_lh_G_front_inf-Triangul' \
        '12112;ctx_rh_G_front_inf-Opercular' \
        '12114;ctx_rh_G_front_inf-Triangul' \
        
        '11100;ctx_lh_Unknown' \
        '11101;ctx_lh_G_and_S_frontomargin' \
        '11102;ctx_lh_G_and_S_occipital_inf' \
        '11103;ctx_lh_G_and_S_paracentral' \
        '11104;ctx_lh_G_and_S_subcentral' \
        '11105;ctx_lh_G_and_S_transv_frontopol' \
        '11106;ctx_lh_G_and_S_cingul-Ant' \
        '11107;ctx_lh_G_and_S_cingul-Mid-Ant' \
        '11108;ctx_lh_G_and_S_cingul-Mid-Post' \
        '11109;ctx_lh_G_cingul-Post-dorsal' \
        '11110;ctx_lh_G_cingul-Post-ventral' \
        '11111;ctx_lh_G_cuneus' \
        '11115;ctx_lh_G_front_middle' \
        '11116;ctx_lh_G_front_sup' \
        '11117;ctx_lh_G_Ins_lg_and_S_cent_ins' \
        '11118;ctx_lh_G_insular_short' \
        '11119;ctx_lh_G_occipital_middle' \
        '11120;ctx_lh_G_occipital_sup' \
        '11121;ctx_lh_G_oc-temp_lat-fusifor' \
        '11122;ctx_lh_G_oc-temp_med-Lingual' \
        '11123;ctx_lh_G_oc-temp_med-Parahip' \
        '11124;ctx_lh_G_orbital' \
        '11125;ctx_lh_G_pariet_inf-Angular' \
        '11126;ctx_lh_G_pariet_inf-Supramar' \
        '11127;ctx_lh_G_parietal_sup' \
        '11128;ctx_lh_G_postcentral' \
        '11129;ctx_lh_G_precentral' \
        '11130;ctx_lh_G_precuneus' \
        '11131;ctx_lh_G_rectus' \
        '11132;ctx_lh_G_subcallosal' \
        '11133;ctx_lh_G_temp_sup-G_T_transv' \
        '11134;ctx_lh_G_temp_sup-Lateral' \
        '11135;ctx_lh_G_temp_sup-Plan_polar' \
        '11136;ctx_lh_G_temp_sup-Plan_tempo' \
        '11137;ctx_lh_G_temporal_inf' \
        '11138;ctx_lh_G_temporal_middle' \
        '11139;ctx_lh_Lat_Fis-ant-Horizont' \
        '11140;ctx_lh_Lat_Fis-ant-Vertical' \
        '11141;ctx_lh_Lat_Fis-post' \
        '11142;ctx_lh_Medial_wall' \
        '11143;ctx_lh_Pole_occipital' \
        '11144;ctx_lh_Pole_temporal' \
        '11145;ctx_lh_S_calcarine' \
        '11146;ctx_lh_S_central' \
        '11147;ctx_lh_S_cingul-Marginalis' \
        '11148;ctx_lh_S_circular_insula_ant' \
        '11149;ctx_lh_S_circular_insula_inf' \
        '11150;ctx_lh_S_circular_insula_sup' \
        '11151;ctx_lh_S_collat_transv_ant' \
        '11152;ctx_lh_S_collat_transv_post' \
        '11153;ctx_lh_S_front_inf' \
        '11154;ctx_lh_S_front_middle' \
        '11155;ctx_lh_S_front_sup' \
        '11156;ctx_lh_S_interm_prim-Jensen' \
        '11157;ctx_lh_S_intrapariet_and_P_trans' \
        '11158;ctx_lh_S_oc_middle_and_Lunatus' \
        '11159;ctx_lh_S_oc_sup_and_transversal' \
        '11160;ctx_lh_S_occipital_ant' \
        '11161;ctx_lh_S_oc-temp_lat' \
        '11162;ctx_lh_S_oc-temp_med_and_Lingual' \
        '11163;ctx_lh_S_orbital_lateral' \
        '11164;ctx_lh_S_orbital_med-olfact' \
        '11165;ctx_lh_S_orbital-H_Shaped' \
        '11166;ctx_lh_S_parieto_occipital' \
        '11167;ctx_lh_S_pericallosal' \
        '11168;ctx_lh_S_postcentral' \
        '11169;ctx_lh_S_precentral-inf-part' \
        '11170;ctx_lh_S_precentral-sup-part' \
        '11171;ctx_lh_S_suborbital' \
        '11172;ctx_lh_S_subparietal' \
        '11173;ctx_lh_S_temporal_inf' \
        '11174;ctx_lh_S_temporal_sup' \
        '11175;ctx_lh_S_temporal_transverse' \
        '12100;ctx_rh_Unknown' \
        '12101;ctx_rh_G_and_S_frontomargin' \
        '12102;ctx_rh_G_and_S_occipital_inf' \
        '12103;ctx_rh_G_and_S_paracentral' \
        '12104;ctx_rh_G_and_S_subcentral' \
        '12105;ctx_rh_G_and_S_transv_frontopol' \
        '12106;ctx_rh_G_and_S_cingul-Ant' \
        '12107;ctx_rh_G_and_S_cingul-Mid-Ant' \
        '12108;ctx_rh_G_and_S_cingul-Mid-Post' \
        '12109;ctx_rh_G_cingul-Post-dorsal' \
        '12110;ctx_rh_G_cingul-Post-ventral' \
        '12111;ctx_rh_G_cuneus' \

        '12115;ctx_rh_G_front_middle' \
        '12116;ctx_rh_G_front_sup' \
        '12117;ctx_rh_G_Ins_lg_and_S_cent_ins' \
        '12118;ctx_rh_G_insular_short' \
        '12119;ctx_rh_G_occipital_middle' \
        '12120;ctx_rh_G_occipital_sup' \
        '12121;ctx_rh_G_oc-temp_lat-fusifor' \
        '12122;ctx_rh_G_oc-temp_med-Lingual' \
        '12123;ctx_rh_G_oc-temp_med-Parahip' \
        '12124;ctx_rh_G_orbital' \
        '12125;ctx_rh_G_pariet_inf-Angular' \
        '12126;ctx_rh_G_pariet_inf-Supramar' \
        '12127;ctx_rh_G_parietal_sup' \
        '12128;ctx_rh_G_postcentral' \
        '12129;ctx_rh_G_precentral' \
        '12130;ctx_rh_G_precuneus' \
        '12131;ctx_rh_G_rectus' \
        '12132;ctx_rh_G_subcallosal' \
        '12133;ctx_rh_G_temp_sup-G_T_transv' \
        '12134;ctx_rh_G_temp_sup-Lateral' \
        '12135;ctx_rh_G_temp_sup-Plan_polar' \
        '12136;ctx_rh_G_temp_sup-Plan_tempo' \
        '12137;ctx_rh_G_temporal_inf' \
        '12138;ctx_rh_G_temporal_middle' \
        '12139;ctx_rh_Lat_Fis-ant-Horizont' \
        '12140;ctx_rh_Lat_Fis-ant-Vertical' \
        '12141;ctx_rh_Lat_Fis-post' \
        '12142;ctx_rh_Medial_wall' \
        '12143;ctx_rh_Pole_occipital' \
        '12144;ctx_rh_Pole_temporal' \
        '12145;ctx_rh_S_calcarine' \
        '12146;ctx_rh_S_central' \
        '12147;ctx_rh_S_cingul-Marginalis' \
        '12148;ctx_rh_S_circular_insula_ant' \
        '12149;ctx_rh_S_circular_insula_inf' \
        '12150;ctx_rh_S_circular_insula_sup' \
        '12151;ctx_rh_S_collat_transv_ant' \
        '12152;ctx_rh_S_collat_transv_post' \
        '12153;ctx_rh_S_front_inf' \
        '12154;ctx_rh_S_front_middle' \
        '12155;ctx_rh_S_front_sup' \
        '12156;ctx_rh_S_interm_prim-Jensen' \
        '12157;ctx_rh_S_intrapariet_and_P_trans' \
        '12158;ctx_rh_S_oc_middle_and_Lunatus' \
        '12159;ctx_rh_S_oc_sup_and_transversal' \
        '12160;ctx_rh_S_occipital_ant' \
        '12161;ctx_rh_S_oc-temp_lat' \
        '12162;ctx_rh_S_oc-temp_med_and_Lingual' \
        '12163;ctx_rh_S_orbital_lateral' \
        '12164;ctx_rh_S_orbital_med-olfact' \
        '12165;ctx_rh_S_orbital-H_Shaped' \
        '12166;ctx_rh_S_parieto_occipital' \
        '12167;ctx_rh_S_pericallosal' \
        '12168;ctx_rh_S_postcentral' \
        '12169;ctx_rh_S_precentral-inf-part' \
        '12170;ctx_rh_S_precentral-sup-part' \
        '12171;ctx_rh_S_suborbital' \
        '12172;ctx_rh_S_subparietal' \
        '12173;ctx_rh_S_temporal_inf' \
        '12174;ctx_rh_S_temporal_sup' \
        '12175;ctx_rh_S_temporal_transverse')





    





fsleyes sig.mgz rh.pial -r sig.mgz 




################## all regions ##################
 
areas=( '0;Unknown ' \
        '1;Left-Cerebral-Exterior ' \
        '2;Left-Cerebral-White-Matter ' \
        '3;Left-Cerebral-Cortex ' \
        '4;Left-Lateral-Ventricle ' \
        '5;Left-Inf-Lat-Vent ' \
        '6;Left-Cerebellum-Exterior ' \
        '7;Left-Cerebellum-White-Matter ' \
        '8;Left-Cerebellum-Cortex ' \
        '9;Left-Thalamus ' \
        '10;Left-Thalamus-Proper* ' \
        '11;Left-Caudate ' \
        '12;Left-Putamen ' \
        '13;Left-Pallidum ' \
        '14;3rd-Ventricle ' \
        '15;4th-Ventricle ' \
        '16;Brain-Stem ' \
        '17;Left-Hippocampus ' \
        '18;Left-Amygdala ' \
        '19;Left-Insula ' \
        '20;Left-Operculum ' \
        '21;Line-1 ' \
        '22;Line-2 ' \
        '23;Line-3 ' \
        '24;CSF ' \
        '25;Left-Lesion ' \
        '26;Left-Accumbens-area ' \
        '27;Left-Substancia-Nigra ' \
        '28;Left-VentralDC ' \
        '29;Left-undetermined ' \
        '30;Left-vessel ' \
        '31;Left-choroid-plexus ' \
        '32;Left-F3orb ' \
        '33;Left-lOg ' \
        '34;Left-aOg ' \
        '35;Left-mOg ' \
        '36;Left-pOg ' \
        '37;Left-Stellate ' \
        '38;Left-Porg ' \
        '39;Left-Aorg ' \
        '40;Right-Cerebral-Exterior ' \
        '41;Right-Cerebral-White-Matter ' \
        '42;Right-Cerebral-Cortex ' \
        '43;Right-Lateral-Ventricle ' \
        '44;Right-Inf-Lat-Vent ' \
        '45;Right-Cerebellum-Exterior ' \
        '46;Right-Cerebellum-White-Matter ' \
        '47;Right-Cerebellum-Cortex ' \
        '48;Right-Thalamus ' \
        '49;Right-Thalamus-Proper* ' \
        '50;Right-Caudate ' \
        '51;Right-Putamen ' \
        '52;Right-Pallidum ' \
        '53;Right-Hippocampus ' \
        '54;Right-Amygdala ' \
        '55;Right-Insula ' \
        '56;Right-Operculum ' \
        '57;Right-Lesion ' \
        '58;Right-Accumbens-area ' \
        '59;Right-Substancia-Nigra ' \
        '60;Right-VentralDC ' \
        '61;Right-undetermined ' \
        '62;Right-vessel ' \
        '63;Right-choroid-plexus ' \
        '64;Right-F3orb ' \
        '65;Right-lOg ' \
        '66;Right-aOg ' \
        '67;Right-mOg ' \
        '68;Right-pOg ' \
        '69;Right-Stellate ' \
        '70;Right-Porg ' \
        '71;Right-Aorg ' \
        '72;5th-Ventricle ' \
        '73;Left-Interior ' \
        '74;Right-Interior ' \
        '77;WM-hypointensities ' \
        '78;Left-WM-hypointensities ' \
        '79;Right-WM-hypointensities ' \
        '80;non-WM-hypointensities ' \
        '81;Left-non-WM-hypointensities ' \
        '82;Right-non-WM-hypointensities ' \
        '83;Left-F1 ' \
        '84;Right-F1 ' \
        '85;Optic-Chiasm ' \
        '192;Corpus_Callosum ' \
        '86;Left_future_WMSA ' \
        '87;Right_future_WMSA ' \
        '88;future_WMSA ' \
        '96;Left-Amygdala-Anterior ' \
        '97;Right-Amygdala-Anterior ' \
        '98;Dura ' \
        '11100;ctx_lh_Unknown' \
        '11101;ctx_lh_G_and_S_frontomargin' \
        '11102;ctx_lh_G_and_S_occipital_inf' \
        '11103;ctx_lh_G_and_S_paracentral' \
        '11104;ctx_lh_G_and_S_subcentral' \
        '11105;ctx_lh_G_and_S_transv_frontopol' \
        '11106;ctx_lh_G_and_S_cingul-Ant' \
        '11107;ctx_lh_G_and_S_cingul-Mid-Ant' \
        '11108;ctx_lh_G_and_S_cingul-Mid-Post' \
        '11109;ctx_lh_G_cingul-Post-dorsal' \
        '11110;ctx_lh_G_cingul-Post-ventral' \
        '11111;ctx_lh_G_cuneus' \
        '11112;ctx_lh_G_front_inf-Opercular' \
        '11113;ctx_lh_G_front_inf-Orbital' \
        '11114;ctx_lh_G_front_inf-Triangul' \
        '11115;ctx_lh_G_front_middle' \
        '11116;ctx_lh_G_front_sup' \
        '11117;ctx_lh_G_Ins_lg_and_S_cent_ins' \
        '11118;ctx_lh_G_insular_short' \
        '11119;ctx_lh_G_occipital_middle' \
        '11120;ctx_lh_G_occipital_sup' \
        '11121;ctx_lh_G_oc-temp_lat-fusifor' \
        '11122;ctx_lh_G_oc-temp_med-Lingual' \
        '11123;ctx_lh_G_oc-temp_med-Parahip' \
        '11124;ctx_lh_G_orbital' \
        '11125;ctx_lh_G_pariet_inf-Angular' \
        '11126;ctx_lh_G_pariet_inf-Supramar' \
        '11127;ctx_lh_G_parietal_sup' \
        '11128;ctx_lh_G_postcentral' \
        '11129;ctx_lh_G_precentral' \
        '11130;ctx_lh_G_precuneus' \
        '11131;ctx_lh_G_rectus' \
        '11132;ctx_lh_G_subcallosal' \
        '11133;ctx_lh_G_temp_sup-G_T_transv' \
        '11134;ctx_lh_G_temp_sup-Lateral' \
        '11135;ctx_lh_G_temp_sup-Plan_polar' \
        '11136;ctx_lh_G_temp_sup-Plan_tempo' \
        '11137;ctx_lh_G_temporal_inf' \
        '11138;ctx_lh_G_temporal_middle' \
        '11139;ctx_lh_Lat_Fis-ant-Horizont' \
        '11140;ctx_lh_Lat_Fis-ant-Vertical' \
        '11141;ctx_lh_Lat_Fis-post' \
        '11142;ctx_lh_Medial_wall' \
        '11143;ctx_lh_Pole_occipital' \
        '11144;ctx_lh_Pole_temporal' \
        '11145;ctx_lh_S_calcarine' \
        '11146;ctx_lh_S_central' \
        '11147;ctx_lh_S_cingul-Marginalis' \
        '11148;ctx_lh_S_circular_insula_ant' \
        '11149;ctx_lh_S_circular_insula_inf' \
        '11150;ctx_lh_S_circular_insula_sup' \
        '11151;ctx_lh_S_collat_transv_ant' \
        '11152;ctx_lh_S_collat_transv_post' \
        '11153;ctx_lh_S_front_inf' \
        '11154;ctx_lh_S_front_middle' \
        '11155;ctx_lh_S_front_sup' \
        '11156;ctx_lh_S_interm_prim-Jensen' \
        '11157;ctx_lh_S_intrapariet_and_P_trans' \
        '11158;ctx_lh_S_oc_middle_and_Lunatus' \
        '11159;ctx_lh_S_oc_sup_and_transversal' \
        '11160;ctx_lh_S_occipital_ant' \
        '11161;ctx_lh_S_oc-temp_lat' \
        '11162;ctx_lh_S_oc-temp_med_and_Lingual' \
        '11163;ctx_lh_S_orbital_lateral' \
        '11164;ctx_lh_S_orbital_med-olfact' \
        '11165;ctx_lh_S_orbital-H_Shaped' \
        '11166;ctx_lh_S_parieto_occipital' \
        '11167;ctx_lh_S_pericallosal' \
        '11168;ctx_lh_S_postcentral' \
        '11169;ctx_lh_S_precentral-inf-part' \
        '11170;ctx_lh_S_precentral-sup-part' \
        '11171;ctx_lh_S_suborbital' \
        '11172;ctx_lh_S_subparietal' \
        '11173;ctx_lh_S_temporal_inf' \
        '11174;ctx_lh_S_temporal_sup' \
        '11175;ctx_lh_S_temporal_transverse' \
        '12100;ctx_rh_Unknown' \
        '12101;ctx_rh_G_and_S_frontomargin' \
        '12102;ctx_rh_G_and_S_occipital_inf' \
        '12103;ctx_rh_G_and_S_paracentral' \
        '12104;ctx_rh_G_and_S_subcentral' \
        '12105;ctx_rh_G_and_S_transv_frontopol' \
        '12106;ctx_rh_G_and_S_cingul-Ant' \
        '12107;ctx_rh_G_and_S_cingul-Mid-Ant' \
        '12108;ctx_rh_G_and_S_cingul-Mid-Post' \
        '12109;ctx_rh_G_cingul-Post-dorsal' \
        '12110;ctx_rh_G_cingul-Post-ventral' \
        '12111;ctx_rh_G_cuneus' \
        '12112;ctx_rh_G_front_inf-Opercular' \
        '12113;ctx_rh_G_front_inf-Orbital' \
        '12114;ctx_rh_G_front_inf-Triangul' \
        '12115;ctx_rh_G_front_middle' \
        '12116;ctx_rh_G_front_sup' \
        '12117;ctx_rh_G_Ins_lg_and_S_cent_ins' \
        '12118;ctx_rh_G_insular_short' \
        '12119;ctx_rh_G_occipital_middle' \
        '12120;ctx_rh_G_occipital_sup' \
        '12121;ctx_rh_G_oc-temp_lat-fusifor' \
        '12122;ctx_rh_G_oc-temp_med-Lingual' \
        '12123;ctx_rh_G_oc-temp_med-Parahip' \
        '12124;ctx_rh_G_orbital' \
        '12125;ctx_rh_G_pariet_inf-Angular' \
        '12126;ctx_rh_G_pariet_inf-Supramar' \
        '12127;ctx_rh_G_parietal_sup' \
        '12128;ctx_rh_G_postcentral' \
        '12129;ctx_rh_G_precentral' \
        '12130;ctx_rh_G_precuneus' \
        '12131;ctx_rh_G_rectus' \
        '12132;ctx_rh_G_subcallosal' \
        '12133;ctx_rh_G_temp_sup-G_T_transv' \
        '12134;ctx_rh_G_temp_sup-Lateral' \
        '12135;ctx_rh_G_temp_sup-Plan_polar' \
        '12136;ctx_rh_G_temp_sup-Plan_tempo' \
        '12137;ctx_rh_G_temporal_inf' \
        '12138;ctx_rh_G_temporal_middle' \
        '12139;ctx_rh_Lat_Fis-ant-Horizont' \
        '12140;ctx_rh_Lat_Fis-ant-Vertical' \
        '12141;ctx_rh_Lat_Fis-post' \
        '12142;ctx_rh_Medial_wall' \
        '12143;ctx_rh_Pole_occipital' \
        '12144;ctx_rh_Pole_temporal' \
        '12145;ctx_rh_S_calcarine' \
        '12146;ctx_rh_S_central' \
        '12147;ctx_rh_S_cingul-Marginalis' \
        '12148;ctx_rh_S_circular_insula_ant' \
        '12149;ctx_rh_S_circular_insula_inf' \
        '12150;ctx_rh_S_circular_insula_sup' \
        '12151;ctx_rh_S_collat_transv_ant' \
        '12152;ctx_rh_S_collat_transv_post' \
        '12153;ctx_rh_S_front_inf' \
        '12154;ctx_rh_S_front_middle' \
        '12155;ctx_rh_S_front_sup' \
        '12156;ctx_rh_S_interm_prim-Jensen' \
        '12157;ctx_rh_S_intrapariet_and_P_trans' \
        '12158;ctx_rh_S_oc_middle_and_Lunatus' \
        '12159;ctx_rh_S_oc_sup_and_transversal' \
        '12160;ctx_rh_S_occipital_ant' \
        '12161;ctx_rh_S_oc-temp_lat' \
        '12162;ctx_rh_S_oc-temp_med_and_Lingual' \
        '12163;ctx_rh_S_orbital_lateral' \
        '12164;ctx_rh_S_orbital_med-olfact' \
        '12165;ctx_rh_S_orbital-H_Shaped' \
        '12166;ctx_rh_S_parieto_occipital' \
        '12167;ctx_rh_S_pericallosal' \
        '12168;ctx_rh_S_postcentral' \
        '12169;ctx_rh_S_precentral-inf-part' \
        '12170;ctx_rh_S_precentral-sup-part' \
        '12171;ctx_rh_S_suborbital' \
        '12172;ctx_rh_S_subparietal' \
        '12173;ctx_rh_S_temporal_inf' \
        '12174;ctx_rh_S_temporal_sup' \
        '12175;ctx_rh_S_temporal_transverse')
