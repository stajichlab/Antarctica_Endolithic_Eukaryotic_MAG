#!/usr/bin/env python3

import sys
import os
import re
import argparse
from pathlib import Path

# read protein filenames to get species names
def read_orthoprotein_filenames(protein_dir):
    """ Read protein filenames to get species names. """
    
    speciesnames= set()
    for protein_file in Path(protein_dir).glob("*.pep"):
        species_name = protein_file.stem
        speciesnames.add(species_name)
    return speciesnames

def read_fasta_filenames(orig_fasta_folder):
    """ Read FASTA filenames and get simplified species names. """

    remap_speciesnames= dict()
    for fasta_file in Path(orig_fasta_folder).glob("*.fa"):
        fname = re.sub(r'\.(proteins|scaffolds|cds-transcripts)$','',fasta_file.stem)
#        print(f'fname: {fname}')
        chunked = fname.split('_')
        genus = chunked[0]
        species = chunked[1]
        if "sp." in fname or "sp_" in fname and len(chunked) > 2:
            species = "_".join(chunked[1:3])
        speciesname = f"{genus}_{species}"
        remap_speciesnames[speciesname] = os.path.join(orig_fasta_folder, os.path.basename(fasta_file))
#       print(f'adding for speciesname ({orig_fasta_folder}): {fname}, {speciesname}')
    return remap_speciesnames

def read_gff_filenames(orig_gff):
    """ Read GFF filenames and get simplified species names. """

    remap_speciesnames= dict()
    for gff_file in Path(orig_gff).glob("*.gff3"):
        fname = re.sub(r'\.gff3?$', '', gff_file.stem)

        chunked = fname.split('_')
        genus = chunked[0]
        species = chunked[1]
        if "sp." in fname or "sp_" in fname and len(chunked) > 2:
            species = "_".join(chunked[1:3])
        speciesname = f"{genus}_{species}"
        remap_speciesnames[speciesname] = os.path.basename(gff_file)
    return remap_speciesnames

def main():
    parser = argparse.ArgumentParser(description="Remap species names in GFF files.")
    parser.add_argument("-d", "--protein_dir", default="input_orthofinder",  type=str, help="Path to the protein directory which gives names of files.")
    parser.add_argument("-c", "--in_cds", default="orig_cds", type=str, help="Path to the original CDS files (with strain name included).")
    parser.add_argument("-f", "--in_gff3", default="orig_gff3", type=str, help="Path to the original GFF3 files (with strain name included).")
    parser.add_argument("-p", "--in_pep", default="orig_pep", type=str, help="Path to the original pep files (with strain name included).")
    parser.add_argument("-g", "--in_genomes", default="orig_genomes", type=str, help="Path to the original genome files (with strain name included).")    
    parser.add_argument("-op", "--out_pep", default="input", type=str, help="Path to the output directory for the used pep files.")
    parser.add_argument("-oc", "--out_cds", default="input_cds", type=str, help="Path to the output directory for the used cds files.")
    parser.add_argument("-of", "--out_gff3", default="gff3", type=str, help="Path to the output directory for the used gff3 files.")
    parser.add_argument("-og", "--out_genome", default="genomes", type=str, help="Path to the output directory for the used genome files.")
    
    args = parser.parse_args()

    protein_speciesnames = read_orthoprotein_filenames(args.protein_dir)


    # here are fungi5k set
    args.in_pep = os.path.realpath(args.in_pep)
    args.in_cds = os.path.realpath(args.in_cds)
    args.in_genomes = os.path.realpath(args.in_genomes)
    args.in_gff3 = os.path.realpath(args.in_gff3)
    for speciesname in protein_speciesnames:
        if speciesname.startswith("Mars-"):
            # treat Mars samples differently
            continue
        print(f'processing {speciesname}')
        for infolder, outfolder in [(args.in_pep, args.out_pep),
                                    (args.in_cds, args.out_cds),                                    
                                    (args.in_genomes, args.out_genome)]:
            os.makedirs(outfolder, exist_ok=True)
            fasta_filenames = read_fasta_filenames(infolder)
            
            if speciesname in fasta_filenames:
                fasta_file = fasta_filenames[speciesname]
                output_file = os.path.join(outfolder, os.path.basename(fasta_file))
                # print(f"Processing species '{speciesname}' with fasta file '{longname}/{fasta_file}' to '{output_file}'")
                if not os.path.exists(output_file):
                    os.symlink(fasta_file, output_file)
            else:
                print(f"Warning: No species '{speciesname}' in folder '{infolder}'")
                #print(fasta_filenames.keys())
                return 

    # now treat gff3 files
        gff_speciesnames = read_gff_filenames(args.in_gff3)
        os.makedirs(args.out_gff3, exist_ok=True)
        
        if speciesname not in gff_speciesnames:
            print(f"Warning: No GFF file found for species '{speciesname}' in folder '{args.in_gff3}'")
            continue
        gff_file = gff_speciesnames[speciesname]
        output_file = os.path.join(args.out_gff3, os.path.basename(gff_file))
        # print(f"Processing species '{speciesname}' with GFF file '{gff_file}' to '{output_file}'")
        if not os.path.exists(output_file):
            os.symlink(os.path.join(args.in_gff3, gff_file), output_file)

if __name__ == "__main__":
    main()