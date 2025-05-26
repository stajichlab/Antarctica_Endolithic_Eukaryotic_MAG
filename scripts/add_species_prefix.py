#!/usr/bin/env python

import sys
import argparse
import csv
import re
from Bio import Phylo
parser = argparse.ArgumentParser(description = 'Add species prefix to gene names')

parser.add_argument('-s','--samples', type = str, default = 'samples.csv', help = 'species prefix')
parser.add_argument('infile', nargs='?', type=argparse.FileType('r'), default=sys.stdin)
parser.add_argument('outfile', nargs='?', type=argparse.FileType('w'), default=sys.stdout)

args = parser.parse_args()

samples = {}
with open(args.samples, 'r') as fh:
    sampleinfo = csv.DictReader(fh, delimiter=",")
    for row in sampleinfo:
        strain = row['STRAIN']
        if len(strain) >= 0:
            strain = '_' + strain
        samples[row['LOCUSTAG']] = row['CLASS'] + '_' + re.sub(' ','_',row['SPECIES'] + strain)
        
tree = Phylo.read(args.infile,'newick')

names = {}
for node in tree.get_terminals():
    key = node.name
    if key in samples:
        node.name = samples[key]
    if node.name in names:
        names[node.name] += 1
        node.name += f"_{names[node.name]}"
    else:
        names[node.name] = 1
Phylo.write(tree,args.outfile,'newick')
#if locustag in samples:
#    species = samples[locustag]
#print(f'>{species}__{locustag}_{geneid}', file=args.outfile)

