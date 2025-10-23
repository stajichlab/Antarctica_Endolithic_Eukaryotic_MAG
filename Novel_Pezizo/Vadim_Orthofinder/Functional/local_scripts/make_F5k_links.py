#!/usr/bin/env python3

import sys
import re
import os
import argparse
import csv
from pathlib import Path

# read protein filenames to get species names
def read_protein_filenames(protein_dir):
    """ Read protein filenames to get species names. """
    speciesnames = {}
    for protein_file in Path(protein_dir).glob("*.proteins.fa"):
        species_name = re.sub(r'\.(proteins|scaffolds|cds-transcripts)$','',protein_file.stem)
        tag = "LOCUSTAG_NOT_FOUND"
        with open(protein_file, 'r') as pf:
            for line in pf:
                if line.startswith(">"):
                    tag = line.replace('>',"").split()[0]
                    break
        speciesnames[species_name] = {'proteins': os.path.basename(protein_file),
                                    'LOCUSTAG': tag,
                                    'seen': False}
    return speciesnames


def main():

    # parse args

    parser = argparse.ArgumentParser(description="Make symlinks for Fungi5k orthoset.")
    parser.add_argument("-d", "--protein_dir", default="input",  
                        type=str, help="Path to the protein directory which gives names of files.")
    parser.add_argument("-i", "--indir", default="orig_function", 
                        type=str, help="Path to the original Fungi5k results (with strain name included).")
    parser.add_argument("-o", "--out_results", default="results/function", 
                        type=str, help="Path to the output directory of function files.")
    parser.add_argument("-s", "--samples", default="orig_samples.csv",
                        type=str, help="Path to the samples CSV file.")
    parser.add_argument("-os", "--outsamples", default="samples.csv",
                        type=str, help="Path to the new samples CSV file.")

    args = parser.parse_args()
    args.indir = os.path.realpath(args.indir)
    os.makedirs(args.out_results, exist_ok=True)
    protein_speciesnames = read_protein_filenames(args.protein_dir)

    with open(args.samples, 'r') as infile, open(args.outsamples, 'w') as outfile:
        incsv = csv.DictReader(infile, delimiter=',')
        outcsv = csv.DictWriter(outfile, delimiter=',',fieldnames=incsv.fieldnames)
        outcsv.writeheader()
        for datarow in incsv:
            if datarow['STRAIN'] == '':
                spname = datarow["SPECIES"].replace(' ','_')
            else:
                spname= f'{datarow["SPECIES"]} {datarow["STRAIN"]}'.replace(' ','_')
            if spname in protein_speciesnames:
                protein_speciesnames[spname]['seen'] = True
                outcsv.writerow(datarow)
    for speciesname in protein_speciesnames:
        if not protein_speciesnames[speciesname]['seen']:
            print(f'Warning: species {speciesname} not found in samples file, skipping linking.')
    return

    for fdir in os.listdir(args.indir):
        functiondir = os.path.join(args.indir, fdir)
        targetdir = os.path.join(args.out_results, fdir)
        if not os.path.isdir(targetdir):
            os.makedirs(targetdir, exist_ok=True)
        
        for tfile in os.listdir(functiondir):
            sourcefile = os.path.join(functiondir, tfile)
            targetfile =  os.path.join(targetdir, tfile)
            tname = tfile
            found = False
            for r in range(5):
#                print(f'tname: {tname} for {tfile} in {functiondir}')                
                if tname in protein_speciesnames or tname.replace('_summary','') in protein_speciesnames:
                    if not os.path.exists(targetfile):
                        print(f'Linking {sourcefile} to {targetfile}')
                        os.symlink(sourcefile, targetfile)
                    found = True
                    break
                if found:
                    print('secondary break!')
                    break
                tname = Path(tname).stem

    
                
if __name__ == "__main__":
    main()
    