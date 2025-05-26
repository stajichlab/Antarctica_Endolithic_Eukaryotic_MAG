#!/usr/bin/bash -l
#SBATCH -p short -c 96 --mem 32gb -C ryzen --out logs/extract_ITS.log

module load barrnap
module load ITSx
CPU=24
SCRIPT=Extract-ITS-sequences-from-a-fungal-genome/extractITS.py
OUTDIR=extract_ITS
mkdir -p $OUTDIR
ls -U genomes/*.fa | 
    parallel -j 4 python $SCRIPT -i {} -o $OUTDIR/{/.} -name {/.}.ITS2 -cpu $CPU -which ITS2

ls -U genomes/*.fa | 
    parallel -j 4 python $SCRIPT -i {} -o $OUTDIR/{/.} -name {/.}.ITS1 -cpu $CPU -which ITS1


