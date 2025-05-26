#!/usr/bin/bash -l
#SBATCH -c 96 --mem 96gb --out logs/filter_aln_custom.%A.log
module load phyling
CPU=${SLURM_CPUS_ON_NODE}
if [ -z $CPU ]; then
    CPU=1
fi

phyling filter -I ascomycota_phyling_align -t $CPU -o ascomycota_msa_filter --verbose -n 30
