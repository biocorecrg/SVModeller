process SVMODELLER_MODULE2 {
    tag "$meta.id"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'ghcr.io/biocorecrg/svmodeller:0.5.0' :
        'ghcr.io/biocorecrg/svmodeller:0.5.0' }"

    input:
    tuple val(meta), path(consensus)
    tuple val(meta2), path(probabilities_numbers)
    tuple val(meta3), path(insertion_features)
    tuple val(meta4), path(genome_wide)
    tuple val(meta5), path(source_l1)
    tuple val(meta6), path(source_sva)
    tuple val(meta7), path(motifs)
    tuple val(meta8), path(sva_vntr)
    tuple val(meta9), path(ref_fasta)
    tuple val(meta10), path(chr_length)
    val num_events

    output:
    tuple val(meta), path("Insertions_table.tsv"), emit: insertions_table
    path "versions.yml"                          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def num_events_arg = num_events ? "--num_events ${num_events}" : ''
    """
    Module2.py \\
        --consensus_path ${consensus} \\
        --probabilities_numbers_path ${probabilities_numbers} \\
        --insertion_features_path ${insertion_features} \\
        --genome_wide_path ${genome_wide} \\
        --source_L1_path ${source_l1} \\
        --source_SVA_path ${source_sva} \\
        --motifs_path ${motifs} \\
        --SVA_VNTR_path ${sva_vntr} \\
        --reference_fasta_path ${ref_fasta} \\
        --chromosome_length_path ${chr_length} \\
        ${num_events_arg} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        svmodeller: "0.5.0"
    END_VERSIONS
    """
}
