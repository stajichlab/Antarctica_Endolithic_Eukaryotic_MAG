#!/bin/bash -l
#SBATCH -c 32 -N 1 -n 1 --mem 80G -p epyc --time 48:00:00
#SBATCH --out logs/iprscan.%a.log
hostname
CPU=1
if [ ! -z "$SLURM_CPUS_ON_NODE" ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi
# let's pick this more hard-codeed based on the number of embeded workers that will run
SPLIT_CPU=8
JOBSPLIT=100
OUTDIR=annotate
SAMPFILE=samples.csv
N=${SLURM_ARRAY_TASK_ID}
if [ -z "$N" ]; then
    N=$1
    if [ -z "$N" ]; then
        echo "need to provide a number by --array or cmdline"
        exit
    fi
fi
MAX=`wc -l $SAMPFILE | awk '{print $1}'`

if [ $N -gt $MAX ]; then
    echo "$N is too big, only $MAX lines in $SAMPFILE"
    exit
fi

IFS=, # set the delimiter to be ,
INPUTFOLDER=predict_results
tail -n +2 $SAMPFILE | sed -n ${N}p | while read ASMID SPECIES LOCUSTAG
do    
    echo "processing $ASMID $SPECIES"
    if [[ ! -d $OUTDIR/$ASMID || ! -d $OUTDIR/$ASMID/$INPUTFOLDER ]]; then
        echo "No annotation dir for '$OUTDIR/${ASMID}'"
        exit
    fi

    if [ ! -d $OUTDIR/${ASMID} ]; then
        echo "No annotation dir for $OUTDIR/${ASMID}"
        exit
    fi

    mkdir -p $OUTDIR/$ASMID/annotate_misc
    XML=$OUTDIR/$ASMID/annotate_misc/iprscan.xml
    echo "checking $OUTDIR/$ASMID"
    if [ ! -s $XML ]; then
        module load iprscan
        module load funannotate
        module load workspace/scratch
        export TMPDIR=$SCRATCH
        export TEMP=$SCRATCH
        export TMP=$SCRATCH
        IPRPATH=$(which interproscan.sh)
        echo $IPRPATH
        time funannotate iprscan -i $OUTDIR/$ASMID -o $XML -m local -c $SPLIT_CPU --iprscan_path $IPRPATH -n $JOBSPLIT
    fi
done
