#!/usr/bin/bash -l
mkdir -p input
module load csvkit
for a in $(csvcut -c 15 5kfungi_list.txt ); do 
	if [[ ! -f $a.fasta && ! -f $a.fasta.gz ]]; then
		ln -s $(realpath ../Fungi_5k/short_names_pep/$a.fasta) input/$a.fasta; 
	fi
done
