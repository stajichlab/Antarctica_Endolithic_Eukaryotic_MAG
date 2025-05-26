#!/usr/bin/env python3

"""
Parse BUSCO concatenated reports to extract relevant information into a table for
each MAG and the metaeuk and funannotate BUSCO results.
"""
import os
import pandas as pd
import re
import argparse
import sys

def parse_busco_concatreports(input_file, source_annotation):
    """
    Parse the BUSCO concatenated report file and extract relevant information.
    
    Args:
        input_file (str): Path to the BUSCO concatenated report file.
        source_annotation (str): Source of the annotation (e.g., 'metaeuk', 'funannotate').
    
    Returns:
        pd.DataFrame: DataFrame containing the parsed BUSCO results.
    """
    data = []
    busco_match = re.compile(r'C:(\d+\.?\d*)%\[S:(\d+\.?\d*)%,D:(\d+\.?\d*)%\],F:(\d+\.?\d*)%,M:(\d+\.?\d*)%,n:(\d+)')
    with open(input_file, 'r') as file:
        MAG_ID = ""
        for line in file:
            if line.startswith('# Summarized benchmarking'):
                # Extract the source annotation from the line
                match = re.search(r'for\s+file\s+(\S+)', line)
                if match:
                    source_file = match.group(1).strip()
                    filename = os.path.basename(source_file)
                    # NOTE THIS IS HARDCODED FOR THIS MAG DATASET
                    m = re.search(r'_(Mars\S+)\.proteins\.fa',filename)
                    if m:
                        MAG_ID = m.group(1)
                    else:
                        # Fallback for different naming conventions
                        m = re.search(r'(\S+).fasta',filename)
                        if m:
                            MAG_ID = m.group(1)
                        else:
                            print("cannot find MAG ID in filename:", filename)
                            MAG_ID = 'unknown_MAG'
                else:
                    print("Unexpected BUSCO report format line:", line)
                continue
            if line.startswith('#'):
                continue
            m = busco_match.search(line.strip())
            if m:
                # Extract the BUSCO ID and status
                complete = m.group(1)
                single = m.group(2)
                duplicated = m.group(3)
                fragmented = m.group(4)
                missing = m.group(5)
                numberbuscos = m.group(6)
#                print(f"Processing MAG: {MAG_ID}, Complete: {complete}, Single: {single}, "
#                    f"Duplicated: {duplicated}, Fragmented: {fragmented}, Missing: {missing}, "
#                    f"Number of BUSCOs: {numberbuscos}")
                data.append([MAG_ID, complete, single, duplicated, fragmented, missing, 
                            numberbuscos, source_annotation])
#            else:
#                print(line.strip())


    df = pd.DataFrame(data, columns=['MAG_ID', 'BUSCO_Complete', 'BUSCO_SINGLE', 'BUSCO_DUPLICATED', 
                                    'BUSCO_FRAGMENTED', 'BUSCO_MISSING', 'BUSCO_NUMBER', 
                                    'Source_Annotation'])
    return df


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Parse BUSCO concatenated reports.')
    parser.add_argument('input_file', type=str, help='Path to the BUSCO concatenated report file.')
    parser.add_argument('source_annotation', type=str, help='Source of the annotation (e.g., "metaeuk", "funannotate").')
    parser.add_argument('outfile', nargs='?', type=argparse.FileType('w'),default=sys.stdout)
    
    args = parser.parse_args()
    
    # Parse the BUSCO report
    busco_df = parse_busco_concatreports(args.input_file, args.source_annotation)
    
    # Print the DataFrame
    busco_df.to_csv(args.outfile, index=False)