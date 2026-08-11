SVModeller Documentation
========================

**SVModeller** is a computational simulator designed to create synthetic human haplotypes containing embedded structural variants (SVs). The simulator has been trained on an extensive catalogue of curated polymorphic SVs identified across 1,019 samples from the 1000 Genomes Project sequenced with Oxford Nanopore long-read technology.

.. toctree::
   :maxdepth: 2
   :caption: Table of Contents:

   intro
   installation
   modules
   data

Key Features
------------

* **Realistic SV Embeddings**: Includes repetitive insertions such as Variable Number of Tandem Repeats (VNTRs), Mobile Element Insertions (MEIs: Alu, LINE-1, SVA), transductions, and mitochondrial insertions (NUMTs).
* **Structural Variant Types**: Supports Alu, LINE-1, SVA, transductions, NUMTs, VNTRs, duplications, inversions, deletions, inverted duplications, orphan insertions, and deletions.
* **Modular Design**: 5 independent modules covering distribution extraction, event generation, deletion processing, genome modification, and sub-clonal read simulation.
* **Containerized**: Run easily via Docker, Conda, or Python environment.
