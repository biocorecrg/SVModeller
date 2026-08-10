#!/usr/bin/env python3
"""
Script to generate a self-contained, minimal toy dataset for fast testing of SVModeller.
Creates all required inputs in toy_data/
"""

import os
import random

def create_toy_dataset(output_dir="toy_data"):
    os.makedirs(output_dir, exist_ok=True)

    # 1. Chromosome length file
    chr_length_path = os.path.join(output_dir, "chr_length.txt")
    with open(chr_length_path, "w") as f:
        f.write("chr22\t100000\n")
    print(f"Created {chr_length_path}")

    # 2. Reference FASTA file (chr22 100,000 bp)
    ref_fasta_path = os.path.join(output_dir, "toy_ref.fa")
    bases = ['A', 'C', 'G', 'T']
    random.seed(42)
    seq = "".join(random.choices(bases, k=100000))
    with open(ref_fasta_path, "w") as f:
        f.write(">chr22\n")
        for i in range(0, len(seq), 80):
            f.write(seq[i:i+80] + "\n")
    print(f"Created {ref_fasta_path}")

    # 3. VCF Insertions
    vcf_ins_path = os.path.join(output_dir, "VCF_Insertions.vcf")
    vcf_ins_content = """##fileformat=VCFv4.2
##INFO=<ID=ITYPE_N,Number=1,Type=String,Description="SV Insertion Type">
##INFO=<ID=FAM_N,Number=1,Type=String,Description="Family">
##INFO=<ID=CONFORMATION,Number=1,Type=String,Description="Conformation">
##INFO=<ID=POLYA_LEN,Number=1,Type=Integer,Description="PolyA Length">
##INFO=<ID=TSD_LEN,Number=1,Type=Integer,Description="TSD Length">
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO
chr22	10000	.	A	ACGTACGTACGT	.	PASS	ITYPE_N=Alu;FAM_N=AluY;CONFORMATION=FOR_POLYA;POLYA_LEN=15;TSD_LEN=12
chr22	25000	.	G	GACGTACGTACGTACGT	.	PASS	ITYPE_N=L1;FAM_N=L1HS;CONFORMATION=FOR_POLYA;POLYA_LEN=20;TSD_LEN=15
chr22	40000	.	T	TACGTACGTACGT	.	PASS	ITYPE_N=SVA;FAM_N=SVA_E;CONFORMATION=FOR_POLYA;POLYA_LEN=10;TSD_LEN=10
chr22	55000	.	C	CACGTACGT	.	PASS	ITYPE_N=Alu;FAM_N=AluY;CONFORMATION=REV_POLYA;POLYA_LEN=12;TSD_LEN=8
chr22	70000	.	A	AACGTACGTACGT	.	PASS	ITYPE_N=NUMT;FAM_N=NA;CONFORMATION=NA;POLYA_LEN=NA;TSD_LEN=NA
"""
    with open(vcf_ins_path, "w") as f:
        f.write(vcf_ins_content)
    print(f"Created {vcf_ins_path}")

    # 4. VCF Deletions
    vcf_del_path = os.path.join(output_dir, "VCF_Deletions.vcf")
    vcf_del_content = """##fileformat=VCFv4.2
##INFO=<ID=DTYPE_N,Number=1,Type=String,Description="SV Deletion Type">
##INFO=<ID=FAM_N,Number=1,Type=String,Description="Family">
##INFO=<ID=DEL_LEN,Number=1,Type=Integer,Description="Deletion Length">
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO
chr22	15000	.	ACGTACGTACGT	A	.	PASS	DTYPE_N=DEL;FAM_N=NA;DEL_LEN=11
chr22	35000	.	GACGTACGTACGTACGT	G	.	PASS	DTYPE_N=DEL;FAM_N=NA;DEL_LEN=16
chr22	60000	.	TACGTACGT	T	.	PASS	DTYPE_N=DEL;FAM_N=NA;DEL_LEN=8
"""
    with open(vcf_del_path, "w") as f:
        f.write(vcf_del_content)
    print(f"Created {vcf_del_path}")

    # 5. Consensus Sequences FASTA
    consensus_path = os.path.join(output_dir, "consensus_sequences_complete.fa")
    consensus_content = """>consensus|Alu|AluY
GCCGGGCGCGGTGGCTCACGCCTGTAATCCCAGCACTTTGGGAGGCCGAGGCGGGCGGATCACGAGGTCAGGAGATCGAGACCATCCTGGCTAACACGGTGAAACCCCGTCTCTACTAAAAATACAAAAAATTAGCCGGGCGTGGTGGCGGGCGCCTGTAGTCCCAGCTACTCGGGAGGCTGAGGCAGGAGAATGGCGTGAACCCGGGAGGCGGAGCTTGCAGTGAGCCGAGATCGCGCCACTGCACTCCAGCCTGGGCGACAGAGCGAGACTCCGTCTCAAAAAA
>consensus|LINE1|L1HS
GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG
>consensus|SVA|SVA_F|Alu-like
CCCTCTCCCTCTCCCTCTCCCTCTCCCTCT
>consensus|SVA|SVA_F|SINE-R
AGCTAGCTAGCTAGCTAGCTAGCTAGCTAG
>consensus|SVA|exon1|MAST2
ATGATGATGATGATGATGATGATGATGATG
>consensus|NC_012920.1
GATCACAGGTCTATCACCCTATTAACCACTCACGGGAGCTCTCCATGCATTTGGTATTTTCGTCTGGGGGGTGTGCACGCGATAGCATTGCGAGACGCTGGAGCCGGAGCACCCTATGTCGCAGTATCTGTCTTTGATTCCTGCCTCATCCTATTATTTATCGCACCTACGTTCAATATTACAGGCGAACATACCTACTAAAGTGTGTTAATTAATTAATGCTTGTAGGACATAATAATAACAATTGAATGTCTGCACAGCCACTTTCCACACAGACATCATAACAAAAAAT
"""
    with open(consensus_path, "w") as f:
        f.write(consensus_content)
    print(f"Created {consensus_path}")

    # 6. Event frequency table
    num_events_path = os.path.join(output_dir, "Number_events.tsv")
    num_events_content = "Event\tNumber\nAlu__FOR_POLYA\t3\nL1__FOR_POLYA\t3\nSVA__FOR_POLYA\t3\nNUMT\t2\n"
    with open(num_events_path, "w") as f:
        f.write(num_events_content)
    print(f"Created {num_events_path}")

    # 7. Source loci LINE1
    src_l1_path = os.path.join(output_dir, "source_loci_LINE1.tsv")
    src_l1_content = "#ref\tbeg\tend\tGene\tLength\nchr22\t5000\t6000\tL1HS_gene\t1000\n"
    with open(src_l1_path, "w") as f:
        f.write(src_l1_content)
    print(f"Created {src_l1_path}")

    # 8. Source loci SVA
    src_sva_path = os.path.join(output_dir, "source_loci_SVA.tsv")
    src_sva_content = "#ref\tbeg\tend\tGene\tLength\nchr22\t12000\t13000\tSVA_E_gene\t1000\n"
    with open(src_sva_path, "w") as f:
        f.write(src_sva_content)
    print(f"Created {src_sva_path}")

    # 9. VNTR with start position
    vntr_path = os.path.join(output_dir, "VNTR_with_start_position.txt")
    vntr_content = "Start\tComplete_Sequence\tVNTR_Num_Motifs\tVNTR_Motifs\n100\tAGCTAGCTAGCTAGCT\t4\tAGCT\n"
    with open(vntr_path, "w") as f:
        f.write(vntr_content)
    print(f"Created {vntr_path}")

    # 10. SVA VNTR Motifs
    sva_vntr_path = os.path.join(output_dir, "SVA_VNTR_Motifs.txt")
    sva_vntr_content = "CCCTCT\nAGCTAG\n"
    with open(sva_vntr_path, "w") as f:
        f.write(sva_vntr_content)
    print(f"Created {sva_vntr_path}")

if __name__ == "__main__":
    create_toy_dataset()
