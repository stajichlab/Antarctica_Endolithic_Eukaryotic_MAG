#!/usr/bin/bash -l
#SBATCH -p short -c 48 --mem 128gb --out logs/mag_search_SRA.log
CPU=2
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

module load minimap2
module load samtools
RDNA=SRA/ITSx/all.fa
OUTDIR=SRA/rDNA_to_MAG

mkdir -p $OUTDIR
for MAG in $(ls genome_MAG/*.sorted.fasta)
do
	IN=$(basename $MAG .sorted.fasta)
	minimap2 --cs=long -t $CPU -x asm20 $MAG $RDNA > $OUTDIR/${IN}_vs_rDNAcandidates.paf
done
