#!/usr/bin/env python3

import sys
import os
import re
import argparse
from pathlib import Path

# read protein filenames to get species names
def read_protein_filenames(protein_dir):
    """ Read protein filenames to get species names. """
    
    speciesnames= set()
    for protein_file in Path(protein_dir).glob("*.pep"):
        species_name = protein_file.stem
        speciesnames.add(species_name)
    return speciesnames

def read_filenames(infolder):
    """ Read filenames and get simplified species name to subdivide. """

    remap_speciesnames= dict()
    for gff_file in Path(infolder).glob("*.gff3"):
        fname = gff_file.stem
#        print(fname)
        speciesname = re.sub(r'Fungi_sp\._', '', fname)
        speciesname = re.sub(r'\.', '_', speciesname)
#        print('adding gff for speciesname:', speciesname)
        remap_speciesnames[speciesname] = { 'gff': os.path.basename(gff_file) }

    for fasta_file in Path(infolder).glob("*.fa"):
        fname = fasta_file.stem
        ftype = fname.split('.')[-1]
#        print(f'fname: {fname}, ftype: {ftype}')
        fname = re.sub(r'Fungi_sp\._', '', fname)
        fname = re.sub(fr'\.{ftype}', '', fname)
        speciesname = re.sub(r'\.', '_', fname)
#        print(f'adding {ftype} for speciesname:', speciesname)        
        remap_speciesnames[speciesname][ftype] = os.path.basename(fasta_file)

    return remap_speciesnames

def main():
    parser = argparse.ArgumentParser(description="Remap species names in GFF files.")
    parser.add_argument("-d", "--protein_dir", default="input_orthofinder",  type=str, help="Path to the protein directory which gives names of files.")
    parser.add_argument("-i", "--indir", default="Mars", type=str, help="Path to the original Mars files in one folder (with strain name included).")
    parser.add_argument("-op", "--out_pep", default="input", type=str, help="Path to the output directory for the used pep files.")
    parser.add_argument("-oc", "--out_cds", default="input_cds", type=str, help="Path to the output directory for the used cds files.")
    parser.add_argument("-of", "--out_gff3", default="gff3", type=str, help="Path to the output directory for the used gff3 files.")
    parser.add_argument("-og", "--out_genome", default="genomes", type=str, help="Path to the output directory for the used genome files.")
    
    args = parser.parse_args()

    args.indir = os.path.realpath(args.indir)

    protein_speciesnames = read_protein_filenames(args.protein_dir)
    mars_filenames = read_filenames(args.indir)

    # here are fungi5k set
    
    for speciesname in protein_speciesnames:
        if not speciesname.startswith("Mars-"):
            continue
        print(f'processing {speciesname}')
        if speciesname not in mars_filenames:
            print(f"Warning: Species '{speciesname}' not found in Mars filenames.")
            continue
        for suffix, outfolder in [('cds-transcripts', args.out_cds),
                                ('proteins', args.out_pep),
                                ('gff', args.out_gff3),
                                ('scaffolds', args.out_genome)]:
            os.makedirs(outfolder, exist_ok=True)            
            if speciesname in mars_filenames and suffix in mars_filenames[speciesname]:
                data_file = mars_filenames[speciesname][suffix]
                print(f"Found species '{speciesname}' in folder '{args.indir}'")
                output_file = os.path.join(outfolder, os.path.basename(data_file))
                print(f"Processing species '{speciesname}' with data file '{data_file}' to '{output_file}'")
                if not os.path.exists(output_file):
                    os.symlink(os.path.join(args.indir, data_file), output_file)
            else:
                print(f"Warning: No data file {suffix} found for species '{speciesname}' in folder '{infolder}'")


if __name__ == "__main__":
    main()