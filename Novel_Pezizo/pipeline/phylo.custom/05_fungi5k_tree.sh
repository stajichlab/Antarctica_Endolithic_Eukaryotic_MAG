#!/usr/bin/bash -l
#SBATCH -p epyc -c 40 --mem 128gb --out logs/fungi5k_raxml_custom.log

module load raxml-ng

pushd ascomycota_msa_filter-buildtree
raxml-ng 

raxml-ng --all --msa AntarcticEUKMAG.ascomycota.fa --model AntarcticEUKMAG.ascomycota.fa.part.aic --tree pars{10} -d aa --bs-trees 100 --threads auto{40} \
	--workers auto{5}


#raxml-ng --all --msa NovelPezizo_v1.ascomycota.fa.raxml.rba --tree pars{10} -d aa --bs-trees 200 --threads auto{40} --workers auto{4}
