# Developer/Agent Instructions for SVModeller

Welcome! This document provides context, architectural guidelines, coding standards, and verification procedures for developer agents working on the SVModeller repository.

---

## 1. Project Overview & Context
- **Name**: SVModeller
- **Domain**: Bioinformatics / Structural Variant (SV) Simulation using Oxford Nanopore and PacBio long-read technology.
- **Workflow Manager**: Nextflow (strict syntax mode enabled).
- **Required Nextflow Version**: `DSL2` and Nextflow version `\ge 26.04.1`.

SVModeller is structured into 5 independent Python modules designed to extract polymorphic SV distribution features, simulate event profiles, modify reference genomes, and simulate sub-clonal reads.

---

## 2. Directory Structure
The repository is structured with the end-to-end Nextflow pipeline files, the standalone Python modules, and shared configurations:

- `main.nf`: The main entrypoint Nextflow pipeline script.
- `nextflow.config`: Global configuration file containing profiles, parameters, and container settings.
- `modules/`: Standardized process-level Nextflow modules:
  - `local/svmodeller/`: Modules 1 through 5 of SVModeller.
  - `nf-core/`: Standard public modules (like `gunzip`, `samtools`, `multiqc`).
- `BioNextflow3/`: Shared library subdirectory mapping to helper functions and local bio-informatics process definitions:
  - `BioNextflow3/modules/local/`: Shared modules (`bam2stats`, `stats/join_bam_stats`, `methods`).
  - `BioNextflow3/global_functions.nf`: Common pipeline utilities and reporting functions.
- `docs/`: Markdown documentation served via Jekyll under the Read the Docs theme.

---

## 3. Strict Coding Guidelines for Agents

### Nextflow DSL2 Strict Mode
- Always write valid Nextflow DSL2 code.
- **Groovy Closure Signatures**: Operators like `.branch` and `.map` do not automatically spread list elements to multiple arguments. Always use a single-parameter closure `it` (e.g. `it[1]`) or explicit destructuring to prevent Groovy signature mismatch errors.
- **Binary Scripts Pathing**: Ensure `nextflow.enable.moduleBinaries = true` is declared at the top of [`main.nf`](file:///Users/lcozzuto/git/SVModeller/main.nf) to expose local binaries (e.g. `bam2stats.py` inside local modules) on the system `PATH` during execution.

### Local Modules Integrity
- **Do not modify the shared local modules** inside `BioNextflow3/modules/local/`. These modules are shared across multiple repositories (including `MOP4-G`).
- If you need to clean up metadata or rename files, do it by manipulating channels and mapping values directly in [`main.nf`](file:///Users/lcozzuto/git/SVModeller/main.nf) (e.g. stripping `.fa.gz` extensions using channel maps before calling modules).

### Config & Environment Portability
- **Do not hardcode paths or parameters** directly inside workflows or process scripts. Use `params.parameterName` instead.
- Define default values for params in `nextflow.config` or inside `params.yaml`.

---

## 4. Verification and Testing Instructions
Before marking any task as complete or submitting a pull request:

1. **Linting & Syntax Validation**:
   Check nextflow parsing and ensure no deprecated syntax or variables are used.
2. **Local Testing Execution**:
   To test changes, run the pipeline with the test profile and test dataset.
   ```bash
   nextflow run . -profile applecontainer -params-file params.test.yaml -resume
   ```
3. **Execution Profiles**:
   - Use `-profile standard` for standard Docker environments.
   - Use `-profile applecontainer` for local virtualized environments (Lima) on macOS / Apple Silicon.
   - Use `-profile test` for testing configurations.
