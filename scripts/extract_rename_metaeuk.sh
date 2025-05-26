#!/usr/bin/bash -l
#SBATCH -p short -c 64

CPU=2
if [ ! -z $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

IN=metaeuk
OUT=metaeuk_proteins
mkdir -p $OUT
do_rename() {
	BIN=$1
	OUT=metaeuk_proteins
	IN=metaeuk
	PEPIN=$IN/$BIN/$BIN.fas
	if [ ! -f $PEPIN ]; then
		echo "No protein file $PEPIN for $BIN"
		continue
	fi
	echo $PEPIN $OUT/$BIN.fasta
	perl -p -e 's/^>(([^\|]+\|){2}[^\|])+\|.+/>$1 /; s/\*//g;' $PEPIN > $OUT/$BIN.fasta
}
export -f do_rename
parallel -j $CPU do_rename ::: $(ls $IN)



