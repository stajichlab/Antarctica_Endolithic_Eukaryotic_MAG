#!/usr/bin/bash -l
#SBATCH --mem 2gb -c 1 -n 1 -N 1

module load ete3

python3 ../Annotation/scripts/guess_taxonomy_named_tree.py -t fungi_tree_consensus/all_trees.astral.tre -d 5k_samples.csv -o 5k_updated_samples.csv
