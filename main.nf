#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

/*
 * SVModeller Pipeline
 * Simulates synthetic human haplotypes with structural variants
 */

include { SVMODELLER_MODULE1 } from './modules/local/svmodeller/module1/main'
include { SVMODELLER_MODULE2 } from './modules/local/svmodeller/module2/main'
include { SVMODELLER_MODULE3 } from './modules/local/svmodeller/module3/main'
include { SVMODELLER_MODULE4 } from './modules/local/svmodeller/module4/main'
include { SVMODELLER_MODULE5 } from './modules/local/svmodeller/module5/main'
include { GUNZIP             } from './modules/nf-core/gunzip/main'
include { SAMTOOLS_FAIDX     } from './modules/nf-core/samtools/faidx/main'
include { logColours          } from './subworkflows/nf-core/utils_nfcore_pipeline/main'
include { end_messaged; fromStringToNFCoreSeqs } from './BioNextflow3/global_functions.nf'

def helpMessage(type) {
    def c = logColours(params.monochrome_logs ?: false)
    def version = '0.5.0'
    def message = ""

    if (type == "log") {
        message = """
${c.yellow}${c.bold}
╔═╗╦  ╦┌┬┐┌─┐┌┬┐┌─┐┬  ┬  ┌─┐┬─┐
╚═╗╚╗╔╝││││ │ ││├┤ │  │  ├┤ ├┬┘
╚═╝ ╚╝ ┴ ┴└─┘─┴┘└─┘┴─┘┴─┘└─┘┴└─
=====================================================================
BIOCORE@CRG SVModeller Pipeline  ~  version ${version}
=====================================================================
${c.reset}
${c.bold}Input Parameters${c.reset}
----------------------------------------------------
${c.green}vcf_insertions${c.reset}            : ${params.vcf_insertions}
${c.green}vcf_deletions${c.reset}             : ${params.vcf_deletions}
${c.green}ref_fasta${c.reset}                 : ${params.ref_fasta}
${c.green}consensus${c.reset}                 : ${params.consensus}
${c.green}source_l1${c.reset}                 : ${params.source_l1 ?: 'Default package loci'}
${c.green}source_sva${c.reset}                : ${params.source_sva ?: 'Default package loci'}
${c.green}motifs${c.reset}                    : ${params.motifs ?: 'Default package motifs'}
${c.green}sva_vntr${c.reset}                  : ${params.sva_vntr ?: 'Default package motifs'}
${c.green}num_events${c.reset}                : ${params.num_events}
${c.green}bin_size${c.reset}                  : ${params.bin_size}
${c.green}outdir${c.reset}                    : ${params.outdir}
${c.bold}Module 5 Parameters${c.reset}
----------------------------------------------------
${c.green}method_file${c.reset}               : ${params.method_file}
${c.green}sim_method${c.reset}                : ${params.sim_method}
${c.green}coverage${c.reset}                  : ${params.coverage}
${c.green}allele_frequency${c.reset}          : ${params.allele_frequency}
=====================================================================
"""
    } else if (type == "help") {
        message = """
${c.yellow}${c.bold}
╔═╗╦  ╦┌┬┐┌─┐┌┬┐┌─┐┬  ┬  ┌─┐┬─┐
╚═╗╚╗╔╝││││ │ ││├┤ │  │  ├┤ ├┬┘
╚═╝ ╚╝ ┴ ┴└─┘─┴┘└─┘┴─┘┴─┘└─┘┴└─
=====================================================================
BIOCORE@CRG SVModeller Pipeline  ~  version ${version}
=====================================================================
${c.reset}
${c.bold}${c.yellow}USAGE:${c.reset}
  nextflow run . -params-file params.yaml -profile <profile> [options]

${c.bold}${c.yellow}DESCRIPTION:${c.reset}
  Simulator of synthetic human haplotypes containing embedded structural
  variants (SV). Handles insertion feature modeling, insertion/deletion
  simulation, and reference genome sequence modification.

${c.bold}${c.yellow}REQUIRED PARAMETERS:${c.reset}
  ${c.bold}${c.green}--vcf_insertions${c.reset}        : ${c.cyan}<path>${c.reset}  ${c.gray}# Path to VCF file with insertion SVs${c.reset}
  ${c.bold}${c.green}--vcf_deletions${c.reset}         : ${c.cyan}<path>${c.reset}  ${c.gray}# Path to VCF file with deletion SVs${c.reset}
  ${c.bold}${c.green}--ref_fasta${c.reset}             : ${c.cyan}<path>${c.reset}  ${c.gray}# Path to reference genome FASTA file${c.reset}
  ${c.bold}${c.green}--consensus${c.reset}             : ${c.cyan}<path>${c.reset}  ${c.gray}# Path to consensus sequences FASTA file${c.reset}

${c.bold}${c.yellow}OPTIONAL PARAMETERS:${c.reset}
  ${c.bold}${c.green}--source_l1${c.reset}             : ${c.cyan}<path>${c.reset}  ${c.gray}# TSV file with LINE-1 source loci${c.reset}
  ${c.bold}${c.green}--source_sva${c.reset}            : ${c.cyan}<path>${c.reset}  ${c.gray}# TSV file with SVA source loci${c.reset}
  ${c.bold}${c.green}--motifs${c.reset}                : ${c.cyan}<path>${c.reset}  ${c.gray}# Text file with VNTR motifs & start positions${c.reset}
  ${c.bold}${c.green}--sva_vntr${c.reset}              : ${c.cyan}<path>${c.reset}  ${c.gray}# Text file with SVA VNTR motifs${c.reset}
  ${c.bold}${c.green}--num_events${c.reset}            : ${c.cyan}<int>${c.reset}   ${c.gray}# Number of events to simulate (default: 10)${c.reset}
  ${c.bold}${c.green}--bin_size${c.reset}              : ${c.cyan}<int>${c.reset}   ${c.gray}# Size of genomic bins in bp (default: 1000000)${c.reset}

${c.bold}${c.yellow}MODULE 5 PARAMETERS:${c.reset}
  ${c.bold}${c.green}--method_file${c.reset}           : ${c.cyan}<path>${c.reset}  ${c.gray}# PBSIM3 model file (.qshmm, .errhmm, or sample)${c.reset}
  ${c.bold}${c.green}--sim_method${c.reset}            : ${c.cyan}<str>${c.reset}   ${c.gray}# Simulation method: qshmm | errhmm | sample${c.reset}
  ${c.bold}${c.green}--coverage${c.reset}              : ${c.cyan}<int>${c.reset}   ${c.gray}# Total sequencing coverage depth${c.reset}
  ${c.bold}${c.green}--allele_frequency${c.reset}      : ${c.cyan}<float>${c.reset} ${c.gray}# Fraction of reads from the modified genome (0.0-1.0)${c.reset}
  ${c.bold}${c.green}--outdir${c.reset}                : ${c.cyan}<path>${c.reset}  ${c.gray}# Output directory (default: 'results')${c.reset}

=====================================================================
"""
    }
    return message
}

workflow SVMODELLER {
    take:
    vcf_insertions
    vcf_deletions
    ref_fasta
    consensus
    source_l1
    source_sva
    motifs
    sva_vntr
    num_events
    bin_size
    method_file
    sim_method
    coverage
    allele_frequency

    main:
    // Decompress ref_fasta with the nf-core GUNZIP module if gzipped
    ch_ref_fasta_ready = ref_fasta
        .branch {
            meta, fasta ->
            compressed:   fasta.name.endsWith('.gz')
            uncompressed: true
        }

    GUNZIP(ch_ref_fasta_ready.compressed)

    ch_ref_fasta_decompressed = ch_ref_fasta_ready.uncompressed
        .mix(GUNZIP.out.gunzip)

    // Build FASTA index (.fai) and chromosome sizes (.sizes) dynamically from the reference genome
    ch_faidx_input = ch_ref_fasta_decompressed.map { meta, fasta -> [ meta, fasta, [] ] }
    SAMTOOLS_FAIDX(ch_faidx_input, true)
    ch_chr_length_ready = SAMTOOLS_FAIDX.out.sizes

    // Module 1: Build insertion model
    SVMODELLER_MODULE1(
        vcf_insertions,
        ch_chr_length_ready,
        bin_size
    )

    // Module 2: Simulate insertions
    SVMODELLER_MODULE2(
        consensus,
        SVMODELLER_MODULE1.out.probabilities,
        SVMODELLER_MODULE1.out.insertion_features,
        SVMODELLER_MODULE1.out.genome_wide_distribution,
        source_l1,
        source_sva,
        motifs,
        sva_vntr,
        ch_ref_fasta_decompressed,
        ch_chr_length_ready,
        num_events
    )

    // Module 3: Build deletion model & simulate deletions
    SVMODELLER_MODULE3(
        vcf_deletions,
        ch_chr_length_ready,
        num_events,
        bin_size
    )

    // Module 4: Embed SVs into reference genome
    SVMODELLER_MODULE4(
        SVMODELLER_MODULE2.out.insertions_table,
        ch_ref_fasta_decompressed,
        SVMODELLER_MODULE3.out.deletions_table
    )

    // Module 5: Simulate long reads from reference & modified genomes, align, merge
    SVMODELLER_MODULE5(
        SVMODELLER_MODULE4.out.modified_genome,
        ch_ref_fasta_decompressed,
        method_file,
        sim_method,
        coverage,
        allele_frequency
    )

    // Assign output channels for publishing
    genome_wide_distribution = SVMODELLER_MODULE1.out.genome_wide_distribution
    insertion_features       = SVMODELLER_MODULE1.out.insertion_features
    probabilities            = SVMODELLER_MODULE1.out.probabilities
    insertions_table         = SVMODELLER_MODULE2.out.insertions_table
    deletions_table          = SVMODELLER_MODULE3.out.deletions_table
    modified_genome          = SVMODELLER_MODULE4.out.modified_genome
    sorted_events            = SVMODELLER_MODULE4.out.sorted_events
    bam                      = SVMODELLER_MODULE5.out.bam
    bai                      = SVMODELLER_MODULE5.out.bai

    emit:
    genome_wide_distribution
    insertion_features
    probabilities
    insertions_table
    deletions_table
    modified_genome
    sorted_events
    bam
    bai
}

workflow {
    main:
    params.help = false
    params.resume = false

    if (params.help) {
        log.info(helpMessage("help"))
        exit(0)
    } else {
        log.info(helpMessage("log"))
    }

    if (params.resume) {
        exit(1, "Are you making the classical --resume typo? Be careful!!!! ;)")
    }

    // Validate required inputs
    if (!params.vcf_insertions)   { error "Parameter --vcf_insertions is required!" }
    if (!params.vcf_deletions)    { error "Parameter --vcf_deletions is required!" }
    if (!params.ref_fasta)        { error "Parameter --ref_fasta is required!" }
    if (!params.consensus)        { error "Parameter --consensus is required!" }
    if (!params.source_l1)        { error "Parameter --source_l1 is required!" }
    if (!params.source_sva)       { error "Parameter --source_sva is required!" }
    if (!params.motifs)           { error "Parameter --motifs is required!" }
    if (!params.sva_vntr)         { error "Parameter --sva_vntr is required!" }
    if (!params.method_file)            { log.warn "Parameter --method_file not set; PBSIM3 will use the model bundled in the container." }
    if (!params.sim_method)             { error "Parameter --sim_method is required!" }
    if (params.coverage == null)        { error "Parameter --coverage is required!" }
    if (params.allele_frequency == null){ error "Parameter --allele_frequency is required!" }

    // Channel preparation
    ch_vcf_insertions = fromStringToNFCoreSeqs(params.vcf_insertions, true).map { meta, files -> [ meta, files[0] ] }
    ch_vcf_deletions  = fromStringToNFCoreSeqs(params.vcf_deletions, true).map  { meta, files -> [ meta, files[0] ] }
    ch_ref_fasta      = fromStringToNFCoreSeqs(params.ref_fasta, true).map      { meta, files -> [ meta, files[0] ] }
    ch_consensus      = fromStringToNFCoreSeqs(params.consensus, true).map      { meta, files -> [ meta, files[0] ] }

    ch_source_l1      = fromStringToNFCoreSeqs(params.source_l1, true).map      { meta, files -> [ meta, files[0] ] }
    ch_source_sva     = fromStringToNFCoreSeqs(params.source_sva, true).map     { meta, files -> [ meta, files[0] ] }
    ch_motifs         = fromStringToNFCoreSeqs(params.motifs, true).map         { meta, files -> [ meta, files[0] ] }
    ch_sva_vntr       = fromStringToNFCoreSeqs(params.sva_vntr, true).map       { meta, files -> [ meta, files[0] ] }
    ch_method_file    = params.method_file
        ? fromStringToNFCoreSeqs(params.method_file, true).map { meta, files -> [ meta, files[0] ] }
        : Channel.of( [ [id: 'no_model'], [] ] )

    SVMODELLER (
        ch_vcf_insertions,
        ch_vcf_deletions,
        ch_ref_fasta,
        ch_consensus,
        ch_source_l1,
        ch_source_sva,
        ch_motifs,
        ch_sva_vntr,
        params.num_events,
        params.bin_size,
        ch_method_file,
        params.sim_method,
        params.coverage,
        params.allele_frequency
    )

    publish:
    genome_wide_distribution = SVMODELLER.out.genome_wide_distribution
    insertion_features       = SVMODELLER.out.insertion_features
    probabilities            = SVMODELLER.out.probabilities
    insertions_table         = SVMODELLER.out.insertions_table
    deletions_table          = SVMODELLER.out.deletions_table
    modified_genome          = SVMODELLER.out.modified_genome
    sorted_events            = SVMODELLER.out.sorted_events
    bam                      = SVMODELLER.out.bam
    bai                      = SVMODELLER.out.bai

    onComplete:
    end_messaged(params.slack_url)
}

output {
    genome_wide_distribution {
        mode 'copy'
        path { meta, file ->
            file >> "module1/${file.name}"
        }
    }
    insertion_features {
        mode 'copy'
        path { meta, file ->
            file >> "module1/${file.name}"
        }
    }
    probabilities {
        mode 'copy'
        path { meta, file ->
            file >> "module1/${file.name}"
        }
    }
    insertions_table {
        mode 'copy'
        path { meta, file ->
            file >> "module2/${file.name}"
        }
    }
    deletions_table {
        mode 'copy'
        path { meta, file ->
            file >> "module3/${file.name}"
        }
    }
    modified_genome {
        mode 'copy'
        path { meta, file ->
            file >> "module4/${file.name}"
        }
    }
    sorted_events {
        mode 'copy'
        path { meta, file ->
            file >> "module4/${file.name}"
        }
    }
    bam {
        mode 'copy'
        path { meta, file ->
            file >> "module5/${file.name}"
        }
    }
    bai {
        mode 'copy'
        path { meta, file ->
            file >> "module5/${file.name}"
        }
    }
}
