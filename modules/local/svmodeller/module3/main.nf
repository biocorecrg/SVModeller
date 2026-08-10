process SVMODELLER_MODULE3 {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'ghcr.io/biocorecrg/svmodeller:0.5.0' :
        'ghcr.io/biocorecrg/svmodeller:0.5.0' }"

    input:
    tuple val(meta), path(vcf)
    tuple val(meta2), path(chr_length)
    val num_events
    val bin_size

    output:
    tuple val(meta), path("Deletions_table.tsv"), emit: deletions_table
    path "versions.yml"                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def num_events_arg = num_events ? "--num_events ${num_events}" : ''
    def bin_size_arg = bin_size ? "--bin_size ${bin_size}" : ''
    """
    Module3.py \\
        --vcf_path ${vcf} \\
        --path_chromosome_length ${chr_length} \\
        ${num_events_arg} \\
        ${bin_size_arg} \\
        ${args}

    cat <<EOF > versions.yml
    "${task.process}":
        svmodeller: "0.5.0"
    EOF
    """
}
