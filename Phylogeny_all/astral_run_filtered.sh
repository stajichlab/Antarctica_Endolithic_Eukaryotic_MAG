#!/usr/bin/bash -l
#SBATCH -p short -C ryzen -c 96 --mem 48gb

CPU=96
if [ ! -z $SLURM_CPUS_ON_NODE ]; then
	CPU=$SLURM_CPUS_ON_NODE
fi

module load aster
pushd fungi_msa_filter/selected_MSAs

astral4 -t $CPU -i all_trees.tre -o all_trees.astral.tre
