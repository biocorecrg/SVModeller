#!/usr/bin/env nextflow

nextflow.enable.moduleBinaries = true

/*
 * simulate_wgs_data Pipeline
 * Generates sub-clonal long read sequencing data and alignments
 * from reference and modified haplotype genomes
 */

include { SIMULATE_WGS_DATA     } from '../subworkflows/local/svmodeller/simulate_wgs_data/main'
include { GUNZIP as GUNZIP_REF  } from '../modules/nf-core/gunzip/main'
include { GUNZIP as GUNZIP_MOD  } from '../modules/nf-core/gunzip/main'
include { logColours             } from '../subworkflows/nf-core/utils_nfcore_pipeline/main'
include { end_messaged ; fromStringToNFCoreSeqs } from '../BioNextflow3/global_functions.nf'
include { BAM2STATS              } from '../BioNextflow3/modules/local/bam2stats/main'
include { JOIN_BAM_STATS         } from '../BioNextflow3/modules/local/stats/join_bam_stats/main'
include { METHODS_SECTION        } from '../BioNextflow3/modules/local/methods/main'
include { MULTIQC                } from '../modules/nf-core/multiqc/main'
include { make_yaml_methods ; makeSoftwareVersionYamlFile ; add_report_header_info ; fromParToValueFileChannel } from '../BioNextflow3/global_functions.nf'

workflow {

    main:
    params.help = false
    params.resume = false

    if (params.help) {
        log.info(helpMessage("help"))
        exit(0)
    }
    else {
        log.info(helpMessage("log"))
    }

    if (params.resume) {
        exit(1, "Are you making the classical --resume typo? Be careful!!!! ;)")
    }

    // Validate required inputs
    if (!params.ref_fasta) {
        error("Parameter --ref_fasta is required!")
    }
    if (!params.modified_genome) {
        error("Parameter --modified_genome is required!")
    }
    if (!params.sim_method) {
        error("Parameter --sim_method is required!")
    }
    if (params.coverage == null) {
        error("Parameter --coverage is required!")
    }
    if (params.allele_frequency == null) {
        error("Parameter --allele_frequency is required!")
    }
    if (!params.method_file) {
        log.warn("Parameter --method_file not set; PBSIM3 will use the model bundled in the container.")
    }

    // Channel preparation
    ch_ref_fasta = fromStringToNFCoreSeqs(params.ref_fasta, true).map { meta, files ->
        def new_meta = meta.clone()
        new_meta.id = meta.id.replaceAll(/\.fa(\.gz)?$|\.fasta(\.gz)?$/, '')
        [new_meta, files[0]]
    }

    ch_modified_genome = fromStringToNFCoreSeqs(params.modified_genome, true).map { meta, files ->
        def new_meta = meta.clone()
        new_meta.id = meta.id.replaceAll(/\.fa(\.gz)?$|\.fasta(\.gz)?$/, '')
        [new_meta, files[0]]
    }

    ch_method_file = params.method_file
        ? fromStringToNFCoreSeqs(params.method_file, true).map { meta, files -> [meta, files[0]] }
        : Channel.value([[id: 'no_model'], []])

    // Decompress ref_fasta if gzipped
    ch_ref_fasta_ready = ch_ref_fasta.branch {
        compressed: it[1].name.endsWith('.gz')
        uncompressed: true
    }
    GUNZIP_REF(ch_ref_fasta_ready.compressed)
    ch_ref_fasta_decompressed = ch_ref_fasta_ready.uncompressed.mix(GUNZIP_REF.out.gunzip)

    // Decompress modified_genome if gzipped
    ch_mod_genome_ready = ch_modified_genome.branch {
        compressed: it[1].name.endsWith('.gz')
        uncompressed: true
    }
    GUNZIP_MOD(ch_mod_genome_ready.compressed)
    ch_mod_genome_decompressed = ch_mod_genome_ready.uncompressed.mix(GUNZIP_MOD.out.gunzip)

    // Align modified genome meta with ref fasta ID for sample grouping
    ch_modified_genome_aligned_meta = ch_mod_genome_decompressed
        .combine(ch_ref_fasta_decompressed)
        .map { meta_mod, fasta_mod, meta_ref, fasta_ref -> [ meta_ref, fasta_mod ] }

    SIMULATE_WGS_DATA(
        ch_modified_genome_aligned_meta,
        ch_ref_fasta_decompressed,
        ch_method_file,
        params.sim_method,
        params.coverage,
        params.allele_frequency,
    )

    // BAM2STATS & JOIN_BAM_STATS
    bam2stats_out = BAM2STATS(SIMULATE_WGS_DATA.out.bam, ch_ref_fasta_decompressed.collect())
    join_bam_stats = JOIN_BAM_STATS(bam2stats_out.stats.map { it[1] }.collect()).join_stats

    // Gather versions
    ch_versions = Channel.topic("versions")
    ch_collated_versions = makeSoftwareVersionYamlFile(ch_versions)

    // Methods section
    module_paths = channel.fromPath(["${projectDir}/../modules", "${projectDir}/../BioNextflow3/modules/local"]).collect()

    def mypars = [:]
    mypars.sim_method = params.sim_method
    mypars.coverage = params.coverage
    mypars.allele_frequency = params.allele_frequency
    mypars.technology = params.technology
    def yaml_methods = make_yaml_methods(mypars, "progPars")
    meth_file = channel.of(yaml_methods).collectFile(name: 'methods.yaml', newLine: true)

    template = channel.fromPath("${projectDir}/template.yml", checkIfExists: true)

    METHODS_SECTION(module_paths, meth_file, template, ch_collated_versions)

    // Mix MultiQC data
    multiqc_data = channel.of()
    multiqc_data = multiqc_data.mix(join_bam_stats)
    multiqc_data = multiqc_data.mix(METHODS_SECTION.out).collect()
    multiqc_data = multiqc_data.mix(ch_collated_versions)

    // Run MultiQC
    def header_map = [:]
    header_map.project = "simulate_wgs_data"
    def multiconfig = add_report_header_info("${projectDir}/../multiqc_config.yaml", header_map)
    def logo = fromParToValueFileChannel("${projectDir}/../logo_svmodeller.png")

    multiqc_files = multiqc_data
        .collect()
        .map { files ->
            def flat_files = files.flatten()
            def sorted_files = flat_files.sort { a, b -> a?.name <=> b?.name }
            [['id': "all"], sorted_files]
        }
        .combine(multiconfig)
        .combine(logo)
        .map { meta, files, config, lg ->
            [meta, files, config, lg, [], []]
        }

    multiout = MULTIQC(multiqc_files)

    publish:
    bam         = SIMULATE_WGS_DATA.out.bam
    bai         = SIMULATE_WGS_DATA.out.bai
    report      = multiout.report
    report_data = multiout.data

    onComplete:
    end_messaged(params.slack_url)
}

output {
    bam {
        mode 'copy'
        path { meta, file ->
            "simulate_wgs_data/${file.name}"
        }
    }
    bai {
        mode 'copy'
        path { meta, file ->
            "simulate_wgs_data/${file.name}"
        }
    }
    report {
        mode 'copy'
        path "report"
    }
    report_data {
        mode 'copy'
        path "report"
    }
}

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
BIOCORE@CRG simulate_wgs_data Pipeline  ~  version ${version}
=====================================================================
${c.reset}
${c.bold}Input Parameters${c.reset}
----------------------------------------------------
${c.green}ref_fasta${c.reset}                 : ${params.ref_fasta}
${c.green}modified_genome${c.reset}           : ${params.modified_genome}
${c.green}sim_method${c.reset}                : ${params.sim_method}
${c.green}coverage${c.reset}                  : ${params.coverage}
${c.green}allele_frequency${c.reset}          : ${params.allele_frequency}
${c.green}technology${c.reset}                : ${params.technology}
${c.green}method_file${c.reset}               : ${params.method_file}
${c.green}outdir${c.reset}                    : ${params.outdir}
=====================================================================
"""
    }
    else if (type == "help") {
        message = """
${c.yellow}${c.bold}
╔═╗╦  ╦┌┬┐┌─┐┌┬┐┌─┐┬  ┬  ┌─┐┬─┐
╚═╗╚╗╔╝││││ │ ││├┤ │  │  ├┤ ├┬┘
╚═╝ ╚╝ ┴ ┴└─┘─┴┘└─┘┴─┘┴─┘└─┘┴└─
=====================================================================
BIOCORE@CRG simulate_wgs_data Pipeline  ~  version ${version}
=====================================================================
${c.reset}
${c.bold}${c.yellow}USAGE:${c.reset}
  nextflow run . -params-file params.yaml -profile <profile> [options]

${c.bold}${c.yellow}DESCRIPTION:${c.reset}
  Sub-clonal long read simulator using PBSIM3, Minimap2 alignment,
  Samtools merge/index, and comprehensive MultiQC reporting.

${c.bold}${c.yellow}REQUIRED PARAMETERS:${c.reset}
  ${c.bold}${c.green}--ref_fasta${c.reset}             : ${c.cyan}<path>${c.reset}  ${c.gray}# Path to reference genome FASTA file (.fa, .fasta, .fa.gz)${c.reset}
  ${c.bold}${c.green}--modified_genome${c.reset}       : ${c.cyan}<path>${c.reset}  ${c.gray}# Path to modified haplotype genome FASTA file (.fa, .fasta, .fa.gz)${c.reset}
  ${c.bold}${c.green}--sim_method${c.reset}            : ${c.cyan}<str>${c.reset}   ${c.gray}# Simulation method: qshmm | errhmm | sample (default: qshmm)${c.reset}
  ${c.bold}${c.green}--coverage${c.reset}              : ${c.cyan}<int>${c.reset}   ${c.gray}# Total sequencing coverage depth (e.g. 30)${c.reset}
  ${c.bold}${c.green}--allele_frequency${c.reset}      : ${c.cyan}<float>${c.reset} ${c.gray}# Fraction of reads from the modified genome (0.0-1.0)${c.reset}

${c.bold}${c.yellow}OPTIONAL PARAMETERS:${c.reset}
  ${c.bold}${c.green}--technology${c.reset}            : ${c.cyan}<str>${c.reset}   ${c.gray}# Sequencing technology: HiFi | ONT | PB (default: HiFi)${c.reset}
  ${c.bold}${c.green}--method_file${c.reset}           : ${c.cyan}<path>${c.reset}  ${c.gray}# PBSIM3 model file (.qshmm, .errhmm, or sample FASTQ)${c.reset}
  ${c.bold}${c.green}--outdir${c.reset}                : ${c.cyan}<path>${c.reset}  ${c.gray}# Output directory (default: 'results')${c.reset}

=====================================================================
"""
    }
    return message
}

