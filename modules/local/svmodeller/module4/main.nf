process SVMODELLER_MODULE4 {
    tag "$meta.id"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'ghcr.io/biocorecrg/svmodeller:0.5.0' :
        'ghcr.io/biocorecrg/svmodeller:0.5.0' }"

    input:
    tuple val(meta), path(insertions_table)
    tuple val(meta2), path(ref_fasta)
    tuple val(meta3), path(deletions_table)

    output:
    tuple val(meta), path("Modified_Reference_Genome.fasta"), emit: modified_genome
    tuple val(meta), path("Sorted_Genomic_Events.tsv")     , emit: sorted_events
    path "versions.yml"                                   , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def del_arg = deletions_table ? "--file2 ${deletions_table}" : ''
    """
    Module4.py \\
        --file1 ${insertions_table} \\
        --fasta_file ${ref_fasta} \\
        ${del_arg} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        svmodeller: "0.5.0"
    END_VERSIONS
    """
}
