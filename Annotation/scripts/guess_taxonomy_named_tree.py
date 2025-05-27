#!/usr/bin/env python3
# -*- coding: utf-8 -*-
""" Read in phylogenetic trees and guess the taxonomy of the leaves
    based on the leaf names. The taxonomy is guessed by looking up
    the leaf names in a taxonomy database. The taxonomy database
    is a CSV file with the following columns:
    - name: the name of the taxon 
    - rank: the rank of the taxon (e.g. species, genus, family, etc.)
    - parent: the parent taxon of the taxon
    - id: the id of the taxon"""


import os
import sys
import argparse
import pandas as pd
import numpy as np
import ete3
from ete3 import NCBITaxa
import pprint
import csv
import math

from collections import defaultdict, Counter
from typing import List, Dict, Any, Tuple
from pathlib import Path

def parse_args() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Guess the taxonomy of the leaves in a phylogenetic tree based on the leaf names."
    )
    parser.add_argument(
        "-t",
        "--tree",
        type=str,
        required=True,
        help="Path to the input tree file (Newick format).",
    )
    parser.add_argument(
        "-d",
        "--database",
        type=str,
        required=True,
        help="Path to the taxonomy database file (CSV format).",
    )
    parser.add_argument(
        "-o",
        "--output",
        type=str,
        required=True,
        help="Path to the output file (CSV format).",
    )
    return parser.parse_args()

def read_taxonomy_database(database_path: str) -> pd.DataFrame:
    """Read the taxonomy database from a CSV file."""
    try:
        df = pd.read_csv(database_path,keep_default_na=False, na_values=[""])
        if not all(col in df.columns for col in ["ASMID","SPECIES", "STRAIN", "BIOPROJECT",
                                                "NCBI_TAXONID", "BUSCO_LINEAGE", "PHYLUM", "SUBPHYLUM", "CLASS", "SUBCLASS", 
                                                "ORDER", "FAMILY", "GENUS", "SPECIES", "LOCUSTAG"]):
            raise ValueError("CSV file must contain these columns columns.")        
        return df
    except Exception as e:
        print(f"Error reading taxonomy database: {e}")
        sys.exit(1)

# a function within a function to get the majority consensus of taxo ranks
def get_majority_taxon(children, rank, taxonomy):
    #print(f"querying {rank} for {len(children)} children {children}")
    taxa = []
    for ch in children:
        if ch.is_leaf() and rank in taxonomy[ch.name]:
            if rank in taxonomy[ch.name]:
                taxon = taxonomy[ch.name][rank]
                #if taxon is not np.nan:
                taxa.append(taxon)
    #taxa = [taxonomy[ch.name].get(rank) for ch in children if ch.is_leaf() and rank in taxonomy[ch.name]]
    if not taxa:
        return None
    counter = Counter(taxa)
    most_common, count = counter.most_common(1)[0]
    #print(f"most common {rank} is {most_common} with count {count} for taxa {taxa}")
    if count > len(taxa) / 2:  # Majority rule
        return most_common
    return None

def infer_taxonomy(tree: ete3.Tree, known_taxonomy: pd.DataFrame) -> Dict[str, Dict[str, str]]:

    """Guess the taxonomy of the leaves in the tree based on the leaf names."""
    target_ranks= ['BUSCO_LINEAGE', 'PHYLUM', 'SUBPHYLUM', 'CLASS', 'SUBCLASS', 'ORDER', 'FAMILY', 'GENUS']
    taxonomy_dict = {}
    n = 1
    for leaf in tree.get_leaves():
        leaf_name = leaf.name
        # Try to find the leaf name in the taxonomy database
        match = known_taxonomy[known_taxonomy['LOCUSTAG'].str.contains(leaf_name, na=False)]
        if not match.empty:
            # If a match is found, get the taxonomy information
            tax_info = match.iloc[0]
            # print(f'storing taxonomy for leaf ({n}th): {leaf_name}')
            n+=1
            taxonomy_dict[leaf_name] = {
#                "ASMID": tax_info["ASMID"],
#                "SPECIESIN": tax_info["SPECIESIN"],
#                "BIOPROJECT": tax_info["BIOPROJECT"],
#                "NCBI_TAXONID": tax_info["NCBI_TAXONID"],
                "BUSCO_LINEAGE": tax_info["BUSCO_LINEAGE"],
                "PHYLUM": tax_info["PHYLUM"],
                "SUBPHYLUM": tax_info["SUBPHYLUM"],
                "CLASS": tax_info["CLASS"],
                "SUBCLASS": tax_info["SUBCLASS"],
                "ORDER": tax_info["ORDER"],
                "FAMILY": tax_info["FAMILY"],
                "GENUS": tax_info["GENUS"],
                "SPECIES": tax_info["SPECIES"],
                "STRAIN": tax_info["STRAIN"],
                "LOCUSTAG": tax_info["LOCUSTAG"]
            }
        else:
            # If no match is found, set the taxonomy to None
            taxonomy_dict[leaf_name] = {'LOCUSTAG': leaf_name}

    # Traverse from leaves to root (post-order)
    for node in tree.traverse("postorder"):
        if node.is_leaf():
            continue
        #children = node.get_children()
        children = node.get_descendants()
        for ch in children:
            ch_name = ch.name
            if ch.is_leaf():
                # Try to infer taxonomy from siblings
                for rank in target_ranks:
                    if rank not in taxonomy_dict[ch_name]:                        
                        inferred = get_majority_taxon(children, rank, taxonomy_dict)
                        if inferred:
                            print(f" --> Found {inferred} {rank} for {ch_name}")
                            taxonomy_dict[ch_name][rank] = inferred

    return taxonomy_dict

def write_output(output_path: str, taxonomy_dict: Dict[str, Dict[str, str]]) -> None:
    """Write the taxonomy information to a CSV file."""

    with open(output_path, "w", newline="") as csvfile:
        fieldnames = ["leaf_name", "BUSCO_LINEAGE", "PHYLUM", "SUBPHYLUM",
                    "CLASS", "SUBCLASS", "ORDER", "FAMILY", "GENUS", 
                    "SPECIES", "STRAIN", "LOCUSTAG"]
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        for leaf_name, tax_info in taxonomy_dict.items():
            if tax_info is not None:
                row = {"leaf_name": leaf_name}
                row.update(tax_info)
                for key in tax_info.keys():
                    if tax_info[key] is np.nan:
                        row[key] = ''
                writer.writerow(row)
            else:
                writer.writerow({"leaf_name": leaf_name})

                        
def main() -> None:
    """Main function to run the script."""
    argparse = parse_args()
    tree_path = argparse.tree
    database_path = argparse.database
    output_path = argparse.output
    # Read the tree file
    try:
        tree = ete3.Tree(tree_path)
    except Exception as e:
        print(f"Error reading tree file: {e}")
        sys.exit(1)
    # Read the taxonomy database
    taxonomy_df = read_taxonomy_database(database_path)
    # Guess the taxonomy of the leaves in the tree
    taxonomy_dict = infer_taxonomy(tree, taxonomy_df)
    # Write the output to a CSV file
    write_output(output_path, taxonomy_dict)
    print(f"Taxonomy information written to {output_path}")

if __name__ == "__main__":  
    main()

# This script is designed to be run from the command line.
# It takes a phylogenetic tree file and a taxonomy database file as input,  
# and outputs a CSV file with the taxonomy information for each leaf in the tree.
# The script uses the ETE3 library to read and manipulate the phylogenetic tree,
# and the pandas library to read and write the taxonomy database.
# The script is designed to be run in a Python 3 environment.
