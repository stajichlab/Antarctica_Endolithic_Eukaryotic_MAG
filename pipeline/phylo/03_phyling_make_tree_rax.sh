#!/usr/bin/bash -l
#SBATCH -c 24 --mem 96gb -p epyc --out logs/make_tree_pep.%A.log
module load phyling
CPU=${SLURM_CPUS_ON_NODE}
if [ -z $CPU ]; then
    CPU=1
fi

phyling tree -I fungi_msa_filter/selected_MSAs -M raxml -t $CPU -o fungi_tree_rax --verbose 
