#!/bin/bash -l
#SBATCH -p short -C cascade -N 1 -c 24 -n 1 --mem 16G --out logs/antismash.%a.log -J antismash

CPU=1
if [ ! -z $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi
OUTDIR=annotate
SAMPFILE=samples.csv
N=${SLURM_ARRAY_TASK_ID}
if [ ! $N ]; then
    N=$1
    if [ ! $N ]; then
        echo "need to provide a number by --array or cmdline"
        exit
    fi
fi
MAX=`wc -l $SAMPFILE | awk '{print $1}'`

if [ $N -gt $MAX ]; then
    echo "$N is too big, only $MAX lines in $SAMPFILE"
    exit
fi

IFS=,
INPUTFOLDER=predict_results

IFS=,
tail -n +2 $SAMPFILE | sed -n ${N}p | while read ASMID SPECIES LOCUSTAG
do    
    if [[ ! -d $OUTDIR/$ASMID || ! -d $OUTDIR/$ASMID/$INPUTFOLDER ]]; then
        echo "No annotation dir for '$OUTDIR/${ASMID}'"
        exit
    fi
    
    if [[ ! -d $OUTDIR/$ASMID/antismash_local && ! -s $OUTDIR/$ASMID/antismash_local/index.html ]]; then
        module load antismash
        antismash --taxon fungi --output-dir $OUTDIR/$ASMID/antismash_local  --genefinding-tool none \
                --clusterhmmer --tigrfam --cb-general --pfam2go --rre --cc-mibig \
                --cb-subclusters --cb-knownclusters -c $CPU \
                $OUTDIR/$ASMID/$INPUTFOLDER/*.gbk
    else
        echo "folder $OUTDIR/$ASMID/antismash_local already exists, skipping."
    fi    
done
