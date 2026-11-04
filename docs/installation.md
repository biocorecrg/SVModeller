---
layout: default
---

# Installation Guide

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
    preprocess_sv_callset.py --file_path /data/VCF_Insertions.vcf --chromosome_length /data/chr_length.txt
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

## 4. Running Nextflow Pipelines

SVModeller provides two Nextflow pipelines:
- **`svmodeller/`**: Automates all 5 modules end-to-end.
- **`simulate_wgs_data/`**: Standalone pipeline dedicated to sub-clonal WGS read simulation and alignment from reference and modified FASTA files.

### Run Commands

#### Running the End-to-End Pipeline (`svmodeller`):
```bash
cd svmodeller
nextflow run main.nf -profile applecontainer -params-file params.test.yaml -resume
```

#### Running the Standalone Read Simulator (`simulate_wgs_data`):
```bash
cd simulate_wgs_data
nextflow run main.nf -profile applecontainer -params-file params.test.yaml -resume
```

### Profiles
- `applecontainer`: Native Apple Silicon container virtualization (highly recommended for Apple Silicon Macs).
- `docker`: Standard Docker containerization.
- `singularity`: Standard Singularity containerization.
- `crg`: SLURM cluster profile for CRG HPC environment.

### Parameters Configuration
The pipeline inputs and settings are configured via YAML parameters files located inside each pipeline directory (`svmodeller/params.yaml` and `simulate_wgs_data/params.yaml`).
