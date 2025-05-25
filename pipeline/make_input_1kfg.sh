#!/usr/bin/bash -l
mkdir -p input
for a in $(cat 1kfg_list.txt ); do ln -s $(realpath ../Phylogeny/input/$a.fasta) input/$a.fasta; done
