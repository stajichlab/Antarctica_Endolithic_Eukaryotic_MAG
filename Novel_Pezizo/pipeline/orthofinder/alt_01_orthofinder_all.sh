#!/usr/bin/bash -l
#SBATCH -p epyc -c 48 -N 1 -n 1 --out logs/orthofinder.log --mem 64gb

module load orthofinder
CPU=2

if [ $SLURM_CPUS_ON_NODE ]; then
 CPU=$SLURM_CPUS_ON_NODE
fi

time orthofinder -f input_orthofinder -t $CPU -a 16 -o OrthoFinder
