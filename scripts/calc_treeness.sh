#!/usr/bin/bash -l
#SBATCH -p short -c 64 --mem 8gb --out logs/treeness.log
CPU=4
if [ ! -z $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi
module load phykit

parallel -j $CPU phykit treeness {} \> {.}.treeness ::: $(ls *.tre)

for file in $(ls *.treeness)
do
    b=$(basename $file .treeness)
    n=$(head -n 1 $file)
    echo -e "$b\t$n"
done > | sort -k2,2nr treeness2.tsv