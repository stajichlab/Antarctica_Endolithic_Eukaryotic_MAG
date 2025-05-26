#!/usr/bin/bash -l

ORIGFILES=/bigdata/stajichlab/shared/projects/Antarctica/Euk_MAGs_Claudio/Phylogeny_all/input
TARGET=$(realpath input)
SAMPLES=select_samples.csv
tail -n +2 $SAMPLES | cut -d, -f 15 | while read LOCUSTAG
do
	ln -s $ORIGFILES/$LOCUSTAG.fasta.gz $TARGET/
	echo $LOCUSTAG
done
