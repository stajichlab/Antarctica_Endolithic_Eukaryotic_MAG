#!/usr/bin/bash -l
#SBATCH -p short -C ryzen -c 96 --mem 48gb

CPU=96
if [ ! -z $SLURM_CPUS_ON_NODE ]; then
	CPU=$SLURM_CPUS_ON_NODE
fi

module load aster

if [ ! -f all_trees.tre ]; then
	cat ../fungi_msa_filter/*.tre > all_trees.tre
fi

astral4 -t $CPU -i all_trees.tre -o all_trees.astral.tre


