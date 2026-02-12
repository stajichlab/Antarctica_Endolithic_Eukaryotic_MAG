#!/usr/bin/bash -l
#SBATCH -p short -N 1 -n 8 --mem 48gb --out logs/download_sra_fq.%a.log

module load parallel-fastq-dump

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
FOLDER=SRA_fqdump

MAX=$(wc -l $SRAFILE | awk '{print $1}')
if [ $N -gt $MAX ]; then
  echo "$N is too big, only $MAX lines in $SRAFILE"
  exit
fi
if [ ! -s $SRAFILE ]; then
	echo "No SRA file $SRAFILE"
	exit
fi
SRA=$(sed -n ${N}p $SRAFILE | cut -f2 -d,)
if [ ! -s $FOLDER/${SRA}_1.fastq.gz ]; then
  #xsra prefetch SRR22405836
 # ~/.cargo/bin/xsra dump --threads $CPU --compression g --prefix ${SRA}_ -o $FOLDER -s -f a $SRA
  parallel-fastq-dump -T $SCRATCH -O $FOLDER  --threads $CPU --split-files --gzip --sra-id $SRA
fi
