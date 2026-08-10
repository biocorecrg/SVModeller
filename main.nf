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
        ref_fasta,
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
        ref_fasta,
        SVMODELLER_MODULE3.out.deletions_table
    )

    emit:
    modified_genome = SVMODELLER_MODULE4.out.modified_genome
    sorted_events   = SVMODELLER_MODULE4.out.sorted_events
}

workflow {
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
