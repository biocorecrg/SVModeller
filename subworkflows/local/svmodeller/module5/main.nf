include { PBSIM3                          } from '../../../../BioNextflow3/modules/local/pbsim3/main'
include { PBSIM3         as PBSIM3_MOD   } from '../../../../BioNextflow3/modules/local/pbsim3/main'
include { MINIMAP2_ALIGN                  } from '../../../../modules/nf-core/minimap2/align/main'
include { MINIMAP2_ALIGN as MINIMAP2_ALIGN_MOD } from '../../../../modules/nf-core/minimap2/align/main'
include { SAMTOOLS_MERGE                  } from '../../../../modules/nf-core/samtools/merge/main'
include { SAMTOOLS_INDEX                  } from '../../../../modules/nf-core/samtools/index/main'

workflow SVMODELLER_MODULE5 {
    take:
    modified_genome     // tuple val(meta), path(modified_genome)
    ref_fasta           // tuple val(meta), path(ref_fasta)
    method_file         // tuple val(meta), path(method_file)
    sim_method          // val: qshmm | errhmm | sample
    coverage            // val
    allele_frequency    // val

    main:
    // Compute per-haplotype depths
    def ref_depth = (coverage * (1.0 - allele_frequency)) as Integer
    def mod_depth = (coverage * allele_frequency) as Integer

    ch_mf = method_file.map { it[1] }

    // 1. Simulate reads from the reference genome
    ch_ref_sim = ref_fasta
        .combine(ch_mf)
        .map { it -> [ [ id: "${it[0].id}_ref" ], it[1], [ id: 'method' ], it[2] ?: [] ] }

    PBSIM3(
        ch_ref_sim.map { it -> [ it[0], it[1] ] },
        ch_ref_sim.map { it -> [ it[2], it[3] ] },
        sim_method,
        ref_depth
    )

    // 2. Simulate reads from the modified genome
    ch_mod_sim = modified_genome
        .combine(ch_mf)
        .map { it -> [ [ id: "${it[0].id}_mod" ], it[1], [ id: 'method' ], it[2] ?: [] ] }

    PBSIM3_MOD(
        ch_mod_sim.map { it -> [ it[0], it[1] ] },
        ch_mod_sim.map { it -> [ it[2], it[3] ] },
        sim_method,
        mod_depth
    )

    // 3. Align reference reads → reference genome
    MINIMAP2_ALIGN(
        PBSIM3.out.fastq,
        ref_fasta,
        true,   // bam_format
        'bai',  // bam_index_extension
        false,  // cigar_paf_format
        false   // cigar_bam
    )

    // 4. Align modified reads → reference genome
    MINIMAP2_ALIGN_MOD(
        PBSIM3_MOD.out.fastq,
        ref_fasta,
        true,
        'bai',
        false,
        false
    )

    // 5. Collect all BAMs, strip _ref/_mod suffix, group by sample ID
    ch_all_bams = MINIMAP2_ALIGN.out.bam
        .mix(MINIMAP2_ALIGN_MOD.out.bam)
        .map { it ->
            def meta = it[0]
            def bam = it[1]
            def sample_id = meta.id.replaceAll(/_ref$|_mod$/, '')
            [ [ id: sample_id ], bam ]
        }
        .groupTuple()

    // SAMTOOLS_MERGE: tuple val(meta), path(bams), path(indices) + reference tuple
    ch_merge_input = ch_all_bams.map { it -> [ it[0], it[1], [] ] }

    SAMTOOLS_MERGE(
        ch_merge_input,
        [ [], [], [], [] ]   // no reference FASTA (BAM output, not CRAM)
    )

    // 6. Index the merged BAM
    SAMTOOLS_INDEX(SAMTOOLS_MERGE.out.bam)

    emit:
    bam = SAMTOOLS_MERGE.out.bam
    bai = SAMTOOLS_INDEX.out.index
}
