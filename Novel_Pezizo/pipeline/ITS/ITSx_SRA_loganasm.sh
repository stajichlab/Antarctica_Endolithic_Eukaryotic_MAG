#!/usr/bin/bash -l
#SBATCH -c 24 --mem 48gb --out logs/ITSx_SRA_unasm.%a.log

module load aws

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
OUTDIR=results/SRA_ITSx_asm
ASMDIR=SRA/asm
BARRNAP=SRA/barrnap
ITSXDIR=SRA/ITSx
mkdir -p $OUTDIR $ASMDIR $BARRNAP $ITSXDIR
IFS=,
sed -n ${N}p $SRAFILE | while read NAME SRAID
do
    if [ ! -f $ASMDIR/${SRAID}.unitigs_filter.fa ]; then
        module load aws
        aws s3 cp s3://logan-pub/u/${SRAID}/${SRAID}.unitigs.fa.zst $ASMDIR --no-sign-request
        #aws s3 cp s3://logan-pub/u/${SRAID}/${SRAID}.contigs.fa.zst $ASMDIR --no-sign-request
        zstd -d $ASMDIR/${SRAID}.unitigs.fa.zst
        #zstd -d $ASMDIR/${SRAID}.contigs.fa.zst
        python scripts/filter_unitigs_len_ntcomposition.py $ASMDIR/${SRAID}.unitigs.fa $ASMDIR/${SRAID}.unitigs_filter.fa --min_len 120
        rm $ASMDIR/${SRAID}.unitigs.fa # we will just keep the filtered set
        #python scripts/filter_unitigs_len_ntcomposition.py $ASMDIR/${SRAID}.contigs.fa $ASMDIR/${SRAID}.contigs_filter.fa --min_len 120
        module unload aws
    fi
    if [ ! -s $BARRNAP/${SRAID}.barrnap.fasta ]; then
        module load barrnap
        barrnap  --kingdom euk --threads $CPU $ASMDIR/${SRAID}.unitigs_filter.fa \
        --outseq $BARRNAP/${SRAID}.barrnap.fasta \
        --reject 0.01 --lencutoff 0.1 > $BARRNAP/${SRAID}.barrnap.gff3
        module unload barrnap
    fi
    if [ ! -s $ITSXDIR/${SRAID}.ITSx.fasta ]; then
        module load ITSx
        module load samtools
        cut -f1 $BARRNAP/${SRAID}.barrnap.gff3 | \
        samtools faidx $BARRNAP/${SRAID}.barrnap.fasta -r - > $ITSXDIR/${SRAID}.only_rRNA.fasta
        ITSx --table T --temp $SCRATCH --fasta T --save_regions all \
        --only_full F -i $ITSXDIR/${SRAID}.only_rRNA.fasta --cpu $CPU 
        -o $ITSXDIR/${SRAID}
    fi
done
