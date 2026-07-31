#!/usr/bin/env python3
# SVModeller 

# Additional script to remove information from VCF file keeping just the event length

# Input:
# - VCF input file
# - VCF output file

# Output:
# - Modified VCF file without information field, just keeping the event length

import os
import sys
import argparse

# Add parent directory to sys.path to locate functions module
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from functions import filter_vcf_info

def main(input_vcf, output_vcf):
    # Print the paths of the input files
    print(f'VCF file path: {input_vcf}')
    print(f'VCF output path: {output_vcf}')
    
    # Ensure .vcf extension
    if not output_vcf.endswith('.vcf'):
        output_vcf += '.vcf'
    
    filter_vcf_info(input_vcf, output_vcf)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Process VCF file to remove all information except from the length of the events')
    parser.add_argument('input_vcf', type=str, help='Path to the VCF.')
    parser.add_argument('output_vcf', type=str, help='Resulting VCF without information name.')

    args = parser.parse_args()
    main(args.input_vcf, args.output_vcf)
