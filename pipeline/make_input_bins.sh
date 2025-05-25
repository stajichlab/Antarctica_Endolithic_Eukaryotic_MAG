#!/usr/bin/bash -l
mkdir -p input
for a in $(cat taxa_list.txt ); do ln -s $(realpath ../metaeuk/$a/$a.fas) input/$a.fasta; done
