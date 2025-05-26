#!/usr/bin/bash -l
#SBATCH -c 24 --mem 96gb -p epyc --out logs/make_tree_pep_custom.%A.log
module load phyling
CPU=${SLURM_CPUS_ON_NODE}
if [ -z $CPU ]; then
    CPU=1
fi

phyling tree -I ascomycota_msa_filter/selected_MSAs -M raxml -t $CPU -o ascomycota_tree_rax --verbose 
