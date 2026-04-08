#!/usr/bin/bash -l
#SBATCH -p short -c 24 --mem 24gb --out logs/bwamem.%a.log


CPU=${SLURM_CPUS_ON_NODE}
if [ -z $CPU ]; then 
    CPU=2
fi
IFS=,
N=${SLURM_ARRAY_TASK_ID}
if [ -z $N ]; then
    N=$1
    if [ -z $N ]; then
        echo "cannot find a cmdline option or array/-a option"
        exit
    fi
fi
echo "N is $N"
SAMPLES=mars.csv
tail -n +2 $SAMPLES | sed -n ${N}p | while read ID MAG SRABIOSAMPLE SRA ORG BIOSAMPLE LOCUSTAG
do
    if [ ! -s ${ID}.bam ]; then
        module load bwa-mem2
        module load samtools
        bwa-mem2 mem -o ${SCRATCH}/${ID}.sam -t ${CPU} db/${ID}.sorted.fasta ../SRA_fqdump/${SRA}_1.fastq.gz ../SRA_fqdump/${SRA}_2.fastq.gz
        samtools view -OBAM -F 12 -o ${SCRATCH}/${ID}.bam ${SCRATCH}/${ID}.sam
        samtools sort -OBAM -@${CPU} -o ${ID}.bam ${SCRATCH}/${ID}.bam
    fi 
    
    if [ ! -f $ID.bam.bai ]; then
        samtools index ${ID}.bam
    fi
    module load mosdepth
    mosdepth -x -t $CPU $ID $ID.bam
done
