#!/usr/bin/bash -l
#SBATCH -c 96 -N 1 -n 1 --mem 256gb --out logs/phyling_align.log -p short

module load phyling
CPU=96
if  [ $SLURM_CPUS_ON_NODE ]; then
 CPU=$SLURM_CPUS_ON_NODE
fi
phyling align -I input -m ascomycota_odb10 -t $CPU -o ascomycota_phyling_align -v 

