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
include { GUNZIP             } from './modules/nf-core/gunzip/main'
include { logColours          } from './subworkflows/nf-core/utils_nfcore_pipeline/main'

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
${c.green}chr_length${c.reset}                : ${params.chr_length}
${c.green}ref_fasta${c.reset}                 : ${params.ref_fasta}
${c.green}consensus${c.reset}                 : ${params.consensus}
${c.green}number_events${c.reset}             : ${params.number_events ?: 'None (Module1 probabilities)'}
${c.green}source_l1${c.reset}                 : ${params.source_l1 ?: 'Default package loci'}
${c.green}source_sva${c.reset}                : ${params.source_sva ?: 'Default package loci'}
${c.green}motifs${c.reset}                    : ${params.motifs ?: 'Default package motifs'}
${c.green}sva_vntr${c.reset}                  : ${params.sva_vntr ?: 'Default package motifs'}
${c.green}num_events${c.reset}                : ${params.num_events}
${c.green}bin_size${c.reset}                  : ${params.bin_size}
${c.green}outdir${c.reset}                    : ${params.outdir}
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
  ${c.bold}${c.green}--chr_length${c.reset}            : ${c.cyan}<path>${c.reset}  ${c.gray}# Path to chromosome length text file${c.reset}
  ${c.bold}${c.green}--ref_fasta${c.reset}             : ${c.cyan}<path>${c.reset}  ${c.gray}# Path to reference genome FASTA file${c.reset}
  ${c.bold}${c.green}--consensus${c.reset}             : ${c.cyan}<path>${c.reset}  ${c.gray}# Path to consensus sequences FASTA file${c.reset}

${c.bold}${c.yellow}OPTIONAL PARAMETERS:${c.reset}
  ${c.bold}${c.green}--number_events${c.reset}         : ${c.cyan}<path>${c.reset}  ${c.gray}# TSV file with custom event frequencies${c.reset}
  ${c.bold}${c.green}--source_l1${c.reset}             : ${c.cyan}<path>${c.reset}  ${c.gray}# TSV file with LINE-1 source loci${c.reset}
  ${c.bold}${c.green}--source_sva${c.reset}            : ${c.cyan}<path>${c.reset}  ${c.gray}# TSV file with SVA source loci${c.reset}
  ${c.bold}${c.green}--motifs${c.reset}                : ${c.cyan}<path>${c.reset}  ${c.gray}# Text file with VNTR motifs & start positions${c.reset}
  ${c.bold}${c.green}--sva_vntr${c.reset}              : ${c.cyan}<path>${c.reset}  ${c.gray}# Text file with SVA VNTR motifs${c.reset}
  ${c.bold}${c.green}--num_events${c.reset}            : ${c.cyan}<int>${c.reset}   ${c.gray}# Number of events to simulate (default: 10)${c.reset}
  ${c.bold}${c.green}--bin_size${c.reset}              : ${c.cyan}<int>${c.reset}   ${c.gray}# Size of genomic bins in bp (default: 1000000)${c.reset}
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
    chr_length
    ref_fasta
    consensus
    number_events
    source_l1
    source_sva
    motifs
    sva_vntr
    num_events
    bin_size

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

    // Module 1: Build insertion model
    SVMODELLER_MODULE1(
        vcf_insertions,
        chr_length,
        bin_size
    )

    // Module 2: Simulate insertions
    // Use output probabilities from Module 1 if number_events input is not provided
    ch_prob_num = number_events ?: SVMODELLER_MODULE1.out.probabilities

    SVMODELLER_MODULE2(
        consensus,
        ch_prob_num,
        SVMODELLER_MODULE1.out.insertion_features,
        SVMODELLER_MODULE1.out.genome_wide_distribution,
        source_l1,
        source_sva,
        motifs,
        sva_vntr,
        ch_ref_fasta_decompressed,
        chr_length,
        num_events
    )

    // Module 3: Build deletion model & simulate deletions
    SVMODELLER_MODULE3(
        vcf_deletions,
        chr_length,
        num_events,
        bin_size
    )

    // Module 4: Embed SVs into reference genome
    SVMODELLER_MODULE4(
        SVMODELLER_MODULE2.out.insertions_table,
        ch_ref_fasta_decompressed,
        SVMODELLER_MODULE3.out.deletions_table
    )

    emit:
    modified_genome = SVMODELLER_MODULE4.out.modified_genome
    sorted_events   = SVMODELLER_MODULE4.out.sorted_events
}

workflow {
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

    // Validate inputs
    if (!params.vcf_insertions) { error "Parameter --vcf_insertions is required!" }
    if (!params.vcf_deletions)  { error "Parameter --vcf_deletions is required!" }
    if (!params.chr_length)     { error "Parameter --chr_length is required!" }
    if (!params.ref_fasta)      { error "Parameter --ref_fasta is required!" }
    if (!params.consensus)      { error "Parameter --consensus is required!" }

    // Channel preparation
    ch_vcf_insertions = Channel.fromPath(params.vcf_insertions).map { file -> [ [ id:'svmodeller' ], file ] }
    ch_vcf_deletions  = Channel.fromPath(params.vcf_deletions).map  { file -> [ [ id:'svmodeller' ], file ] }
    ch_chr_length     = Channel.fromPath(params.chr_length).map     { file -> [ [ id:'svmodeller' ], file ] }
    ch_ref_fasta      = Channel.fromPath(params.ref_fasta).map      { file -> [ [ id:'svmodeller' ], file ] }
    ch_consensus      = Channel.fromPath(params.consensus).map      { file -> [ [ id:'svmodeller' ], file ] }

    ch_number_events  = params.number_events ? Channel.fromPath(params.number_events).map { file -> [ [ id:'svmodeller' ], file ] } : Channel.empty()
    ch_source_l1      = params.source_l1 ? Channel.fromPath(params.source_l1).map { file -> [ [ id:'svmodeller' ], file ] } : Channel.fromPath("$projectDir/test_data/source_loci_LINE1.tsv").map { file -> [ [ id:'svmodeller' ], file ] }
    ch_source_sva     = params.source_sva ? Channel.fromPath(params.source_sva).map { file -> [ [ id:'svmodeller' ], file ] } : Channel.fromPath("$projectDir/test_data/source_loci_SVA.tsv").map { file -> [ [ id:'svmodeller' ], file ] }
    ch_motifs         = params.motifs ? Channel.fromPath(params.motifs).map { file -> [ [ id:'svmodeller' ], file ] } : Channel.fromPath("$projectDir/test_data/VNTR_with_start_position.txt").map { file -> [ [ id:'svmodeller' ], file ] }
    ch_sva_vntr       = params.sva_vntr ? Channel.fromPath(params.sva_vntr).map { file -> [ [ id:'svmodeller' ], file ] } : Channel.fromPath("$projectDir/test_data/SVA_VNTR_Motifs.txt").map { file -> [ [ id:'svmodeller' ], file ] }

    SVMODELLER (
        ch_vcf_insertions,
        ch_vcf_deletions,
        ch_chr_length,
        ch_ref_fasta,
        ch_consensus,
        ch_number_events,
        ch_source_l1,
        ch_source_sva,
        ch_motifs,
        ch_sva_vntr,
        params.num_events,
        params.bin_size
    )
}
