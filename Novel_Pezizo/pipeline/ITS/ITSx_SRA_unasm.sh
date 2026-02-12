#!/usr/bin/bash -l
#SBATCH -c 48 --mem 48gb --out logs/ITSx_SRA_unasm.%a.log

module load ITSx
module load minimap2
module load samtools

CPU=2
if [ $SLURM_CPUS_ON_NODE ]; then
  CPU=$SLURM_CPUS_ON_NODE
fi
N=${SLURM_ARRAY_TASK_ID}
if [ -z $N ]; then
    N=$1
fi
if [ -z $N ]; then
    echo "cannot run without a number provided either cmdline or --array in sbatch"
    exit
fi
SRAFILE=lib/sra.txt

MAX=$(wc -l $SRAFILE | awk '{print $1}')
if [ $N -gt $MAX ]; then
    echo "$N is too big, only $MAX lines in $SRAFILE"
    exit
fi
if [ ! -s $SRAFILE ]; then
	echo "No SRA file $SRAFILE"
	exit
fi
OUTDIR=results/SRA_ITSx_unasm
mkdir -p $OUTDIR
IFS=,

minimap2 -d $SCRATCH/UNITE.mmi /srv/projects/db/UNITE/current/UNITE_public_FUNGI_19.02.2025.fasta -x sr -t $CPU
run_search() {
    SRAID=$1
    DIRECTION=$2
    minimap2 -x sr -t 24 $SCRATCH/UNITE.mmi SRA/${SRAID}_${DIRECTION}.fa.gz > $OUTDIR/${SRAID}_${DIRECTION}.minimap.paf
    pigz -d SRA/${SRAID}_${DIRECTION}.fa.gz > $SCRATCH/${SRAID}_${DIRECTION}.fa
    cut -f1 $OUTDIR/${SRAID}_${DIRECTION}.minimap.paf | samtools faidx -r - $SCRATCH/${SRAID}_${DIRECTION}.fa  > $OUTDIR/${SRAID}_${DIRECTION}.minimap_hits.fa    
    ITSx --table T --temp $SCRATCH --fasta T --save_regions all --only_full F -i $SCRATCH/${SRAID}_${DIRECTION}.fa  --cpu $CPU -t F -o $OUTDIR/${SRAID}_${DIRECTION}.ITSx.out
}
export -f run_search

parallel -j 2 --env SCRATCH --env OUTDIR --env CPU run_search {2} {1} ::: 0 1 ::: $(sed -n ${N}p $SRAFILE | cut -f2 -d,)
