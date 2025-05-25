#!/usr/bin/bash -l
#SBATCH -p short -c 96 -N 1 -n 1 --mem 64gb --out logs/busco_pep_funannotate.log

module load busco
CPU=96
CPU_PER=16
OUT=busco_pep/funannotate
mkdir -p $OUT
parallel -j 6 busco --offline --download_path /srv/projects/db/BUSCO/v10_alt -m prot -c $CPU_PER -i {} -o $OUT/{/.} -l fungi_odb10 ::: $(ls -U Annotation/annotate/*/predict_results/*.proteins.fa)
