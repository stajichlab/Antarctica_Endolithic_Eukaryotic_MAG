#!/usr/bin/bash -l
mkdir -p input
SOURCE=/bigdata/stajichlab/shared/projects/1KFG/2023/NCBI_fungi/source/NCBI_ASM
module load csvkit
IFS=,
csvcut -c 1,15 5kfungi_list.txt | while read ASM TAG
do
    if [[ ! -f input/$TAG.fasta && ! -f input/$TAG.fasta.gz ]]; then
	if [ -f $SOURCE/$ASM/${ASM}_protein.faa.gz ]; then
	    ln -s $SOURCE/$ASM/${ASM}_protein.faa.gz :q
	    :q!
	    input/$TAG.fasta.gz
	fi
    fi
#	ln -s $(realpath ../Fungi_5k/short_names_pep/$a.fasta) input/$a.fasta; 
done
