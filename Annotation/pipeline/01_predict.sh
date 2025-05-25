#!/usr/bin/bash -l
#SBATCH -N 1 -n 1 -c 16 --mem 32gb --out logs/funannotate_predict.%a.log --time 32:00:00

module load funannotate
SAMPLES=samples.csv
SOURCE=final_genomes
TARGET=annotate
SEQCENTER=FMACH
export AUGUSTUS_CONFIG_PATH=$(realpath lib/augustus/3.5/config)
mkdir -p $TARGET
CPU=2
if [ ! -z $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi
N=$SLURM_ARRAY_TASK_ID
if [ -z $N ]; then
    N=$1
    if [ -z $N ]; then
        echo "need to provide a number by --array or cmdline"
        exit
    fi
fi
export FUNANNOTATE_DB=/bigdata/stajichlab/shared/lib/funannotate_db
IFS=,
BUSCO_LINEAGE=fungi_odb10
tail -n +2 $SAMPLES | sed -n ${N}p | while read ASMID SPECIES LOCUSTAG
do
    LOCUSTAG=$(echo -n "$LOCUSTAG" | perl -p -e 's/[\r\n]//g')
    echo "Running $ASMID for $SPECIES $STRAIN ( $BUSCO_LINEAGE, $LOCUSTAG )"
    GENOME=$(realpath $SOURCE)/$ASMID.masked.fasta
    F=$(ls $TARGET/$ASMID/predict_results/*.gbk | head -n 1)
    if [ -z $F ]; then
    	time funannotate predict --name $LOCUSTAG -i $GENOME --strain "$ASMID" -o $TARGET/$ASMID -s "$SPECIES" --cpu $CPU --busco_db $BUSCO_LINEAGE \
        --AUGUSTUS_CONFIG_PATH $AUGUSTUS_CONFIG_PATH -w codingquarry:0 --min_training_models 30 --tmpdir $SCRATCH --SeqCenter $SEQCENTER --keep_no_stops --header_length 24
    fi
    F=$(ls $TARGET/$ASMID/predict_results/*.gbk | head -n 1)
    if [ ! -z $F ]; then
        rm -rf $TARGET/$ASMID/predict_misc/EVM $TARGET/$ASMID/predict_misc/proteins.combined.fa
        rm -rf $TARGET/$ASMID/predict_misc/glimmerhmm
        rm -rf $TARGET/$ASMID/predict_misc/busco
        rm -rf $TARGET/$ASMID/predict_misc/busco_proteins
    fi
done
