---
layout: default
title: Modules Reference
nav_order: 3
---

# Module Reference Guide

## Module 1: Distribution Analysis

Extracts genome-wide and feature distributions from an insertion VCF file.

### Input Files
- VCF with insertion data (`--file_path`)
- Chromosome lengths table (`--chromosome_length`)
- *(Optional)* Window size in base pairs (default: `1,000,000` / 1Mb)

### Output Files
- `Genome_Wide_Distribution.tsv`
- `Insertion_Features.tsv`
- `Probabilities.tsv`
- `Separated_Motifs.tsv`
- `SVA_VNTR_Motifs.txt`

### Command
```bash
Module1.py \
    --file_path VCF_Insertions.vcf \
    --chromosome_length chr_length.txt
```

---

## Module 2: Event Generation

Generates synthetic insertion event sequences based on feature distributions derived from Module 1 or user-defined tables.

### Input Files
- `--genome_wide_path`: `Genome_Wide_Distribution.tsv`
- `--insertion_features_path`: `Insertion_Features.tsv`
- `--probabilities_numbers_path`: `Probabilities.tsv` or event counts
- `--source_L1_path`: `source_loci_LINE1.tsv`
- `--source_SVA_path`: `source_loci_SVA.tsv`
- `--consensus_path`: `consensus_sequences_complete.fa`
- `--reference_fasta_path`: Reference FASTA (e.g., `chm13v2.0.fa`)
- `--motifs_path`: `Separated_Motifs.tsv`
- `--SVA_VNTR_path`: `SVA_VNTR_Motifs.txt`
- `--chromosome_length_path`: `chr_length.txt`

### Output Files
- `Insertions_table.tsv`
- *(Optional)* Variant Calling File (VCF) when using `--VCF`

### Command
```bash
Module2.py \
    --consensus_path consensus_sequences_complete.fa \
    --probabilities_numbers_path Number_events.tsv \
    --insertion_features_path Insertion_Features.tsv \
    --genome_wide_path Genome_Wide_Distribution.tsv \
    --source_L1_path source_loci_LINE1.tsv \
    --source_SVA_path source_loci_SVA.tsv \
    --motifs_path VNTR_with_start_position.txt \
    --SVA_VNTR_path SVA_VNTR_Motifs.txt \
    --reference_fasta_path chm13v2.0.fa \
    --chromosome_length_path chr_length.txt \
    --VCF
```

---

## Module 3: Deletion Processing

Selects regions to be deleted based on a VCF containing deletion events.

### Input Files
- `--vcf_path`: `VCF_Deletions.vcf`
- `--path_chromosome_length`: `chr_length.txt`
- `--num_events`: Number of deletion events to simulate
- *(Optional)* `--reference_fasta_path`: Reference genome FASTA

### Output Files
- `Deletions_table.tsv`
- *(Optional)* VCF output when using `--VCF`

### Command
```bash
Module3.py \
    --vcf_path VCF_Deletions.vcf \
    --path_chromosome_length chr_length.txt \
    --num_events 1000 \
    --VCF \
    --reference_fasta_path chm13v2.0.fa
```

---

## Module 4: Reference Modification

Applies insertion and deletion events (from Modules 2 and 3) to a reference genome to generate a modified synthetic genome.

### Input Files
- `--file1`: `Insertions_table.tsv`
- `--fasta_file`: Reference FASTA
- `--file2`: `Deletions_table.tsv`

### Output Files
- `Modified_Reference_Genome.fasta`
- `Sorted_Genomic_Events.tsv`

### Command
```bash
Module4.py \
    --file1 Insertions_table.tsv \
    --fasta_file chm13v2.0.fa \
    --file2 Deletions_table.tsv
```

---

## Module 5: Sub-clonal Read Simulation & BAM Generation

Simulates sequencing reads at designated coverage and allele frequency levels using `pbsim3`, aligns reads with `minimap2`, and sorts/indexes BAM files with `samtools`.

### Input Parameters
- `--reference_genome`: Reference FASTA
- `--modified_genome`: Modified FASTA (from Module 4)
- `--method`: `error_model`, `quality_score`, or `training`
- `--method_file`: Model file (e.g., `ERRHMM-ONT-HQ.model`)
- `--coverage`: Depth of coverage (e.g., `30`)
- `--allele_frequency`: Allele frequency between 0 and 1 (e.g., `0.5`)
- `--technology`: `ONT`, `PB`, or `HiFi`
- `--output_dir`: Output directory
- `--threads`: Number of threads (e.g., `8`)

### Output Files
- `combined_final_alignment.bam` (and `.bam.bai`)
- Modified genome reads (`.fastq`)
- Reference genome reads (`.fastq`)

### Command
```bash
Module5.py \
    --reference_genome chm13v2.0.fa \
    --modified_genome Modified_Reference_Genome.fasta \
    --method_file ERRHMM-ONT-HQ.model \
    --method error_model \
    --coverage 30 \
    --allele_frequency 0.5 \
    --output_dir BAM_Output \
    --technology ONT \
    --threads 8
```

---

## Additional Scripts

### `Filter_VCF_information.py`
Removes standard VCF INFO fields while retaining event length information.

```bash
Filter_VCF_information.py input.vcf output_filtered.vcf
```

---

## MultiQC & Methods Section Reporting

The Nextflow pipeline automatically integrates **MultiQC** to compile and present alignment quality statistics along with an auto-generated methods citation section.

### BAM Statistics (BAM2STATS)
After Module 5 completes read simulation and alignment, the pipeline runs the `BAM2STATS` module to calculate sequencing alignment and quality statistics. These stats are merged via `JOIN_BAM_STATS` and displayed as the **Alignment QC** table in the MultiQC report.

### Auto-Generated Methods Section
The pipeline extracts the parameters used for execution and utilizes the `METHODS_SECTION` module to automatically compile a methods description including references/citations for the tools used (`pbsim3`, `minimap2`, `samtools`, and `svmodeller`).

This results in a `methods_description_mqc.yml` file which MultiQC renders under the **Methods description** section.

### Outputs
- `results/report/multiqc_report.html`: The interactive HTML report summarizing the pipeline run, alignment QC stats, and citations.
- `results/report/multiqc_data/`: The directory containing raw statistics tables and structured JSON data.
