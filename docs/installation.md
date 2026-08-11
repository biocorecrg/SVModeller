# Installation Guide

[Home](index.html) | [Modules](modules.html) | [Data](data.html)

---

## 1. Docker Installation (Recommended)

Using Docker avoids manual installation of native bioinformatics tools (`samtools`, `minimap2`, `pbsim3`) and Python libraries.

### Pull Image
```bash
docker pull ghcr.io/biocorecrg/svmodeller:0.5.0
```

### Run Container
Mount your local working directory containing input datasets into `/data`:

```bash
docker run --rm -v $(pwd):/data ghcr.io/biocorecrg/svmodeller:0.5.0 \
    Module1.py --file_path /data/VCF_Insertions.vcf --chromosome_length /data/chr_length.txt
```

---

## 2. Conda / Micromamba Setup

Conda automatically creates an isolated environment with exact software dependencies:

```bash
# Clone repository
git clone https://github.com/biocorecrg/SVModeller.git
cd SVModeller

# Create Conda environment
conda env create -f environment.yml
conda activate svmodeller
```

---

## 3. Manual Installation (Pip)

### Prerequisites
Ensure the following bioinformatic tools are installed and in your system `PATH`:
- **Python** >= 3.10
- **samtools** >= 1.19.2
- **minimap2** >= 2.22
- **pbsim3** >= 3.0.4

### Install Python Dependencies
```bash
pip install -r requirements.txt
```

`requirements.txt` installs:
- `pandas >= 2.0.0`
- `numpy >= 1.24.0`
- `distfit >= 1.8.9`
- `pysam >= 0.21.0`
- `GAPI >= 1.0.4` (from GitHub repository)

---

## 4. Running as a Nextflow Pipeline

The entire modular workflow can also be executed end-to-end as a single Nextflow pipeline. This automatically orchestrates all 5 modules.

### Run Command
To run the pipeline using the test dataset:
```bash
nextflow run . -profile applecontainer -params-file params.test.yaml -resume
```

### Profiles
- `applecontainer`: Native Apple Silicon container virtualization (highly recommended for Apple Silicon Macs).
- `docker`: Standard Docker containerization.
- `singularity`: Standard Singularity containerization.

### Parameters Configuration
The pipeline inputs and settings are configured via a YAML parameters file (e.g. `params.test.yaml`):
```yaml
vcf_insertions: "pipeline_inputs/VCF_Insertions.chr20.vcf.gz"
vcf_deletions:  "pipeline_inputs/VCF_Deletions.chr20.vcf.gz"
ref_fasta:      "pipeline_inputs/chm13v2.0.chr20.fa.gz"
consensus:      "pipeline_inputs/consensus_sequences_complete.fa.gz"
source_l1:      "pipeline_inputs/source_loci_LINE1_chr20.tsv.gz"
source_sva:     "pipeline_inputs/source_loci_SVA_chr20.tsv.gz"
motifs:         "pipeline_inputs/VNTR_with_start_position_chr20.tsv.gz"
sva_vntr:       "pipeline_inputs/SVA_VNTR_Motifs_chr20.tsv.gz"
num_events:     1000
bin_size:       1000000
sim_method:     "qshmm"
coverage:       30
allele_frequency: 0.5
```
