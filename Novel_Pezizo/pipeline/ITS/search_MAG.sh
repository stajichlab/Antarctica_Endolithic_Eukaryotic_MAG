#!/usr/bin/bash -l
#SBATCH -p short -c 48 --mem 128gb --out logs/mag_search_SRA.log
CPU=2
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

module load minimap2
module load samtools
pushd SRA/asm
for a in $(ls *.zst); do zstd -dc $a > $SCRATCH/$(basename $a .zst); done
pushd $SCRATCH
perl -i -p -e 's/>/>SRR22405836_/' SRR22405836.unitigs.fa
perl -i -p -e 's/>/>SRR22405891_/' SRR22405891.unitigs.fa
perl -i -p -e 's/>/>SRR22405841_/' SRR22405841.unitigs.fa
cat *.fa > Mars.fasta
samtools faidx Mars.fasta &
mmseqs -t $CPU -d Mars.mmi Mars.fasta

popd
cd genome_MAG
for MAG in $(ls *.sorted.fasta)
do
	IN=$(basename $MAG .sorted.fasta)
	minimap2 --cs=long -t $CPU -x asm20 $SCRATCH/Mars.mmi $MAG > ../SRA/refmap/${IN}_vs_MarsSRA_logantigs.paf
	cut -f6 ../SRA/refmap/${IN}_vs_MarsSRA_logantigs.paf | sort | uniq > ../SRA/refmap/${IN}_vs_MarsSRA_logantigs.ids
	samtools faidx -r ../SRA/refmap/${IN}_vs_MarsSRA_logantigs.ids $SCRATCH/Mars.fasta  > ../SRA/refmap/${IN}_vs_MarsSRA_logantigs.unitigs.fa
done
