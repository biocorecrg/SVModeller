# Installation Guide

[Home](index.html) | [Modules](modules.html) | [Data](data.html)

---

## 1. Docker Installation (Recommended)

Using Docker avoids manual installation of native bioinformatics tools (`samtools`, `minimap2`, `pbsim3`) and Python libraries.

### Pull Image
```bash
docker pull ghcr.io/repbio-lab/svmodeller:0.5.0
```

### Run Container
Mount your local working directory containing input datasets into `/data`:

```bash
docker run --rm -v $(pwd):/data ghcr.io/repbio-lab/svmodeller:0.5.0 \
    Module1.py --file_path /data/VCF_Insertions.vcf --chromosome_length /data/chr_length.txt
```

---

## 2. Conda / Micromamba Setup

Conda automatically creates an isolated environment with exact software dependencies:

```bash
# Clone repository
git clone https://github.com/REPBIO-LAB/SVModeller.git
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
