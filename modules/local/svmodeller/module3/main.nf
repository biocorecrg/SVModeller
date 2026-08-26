process SVMODELLER_MODULE3 {
    tag "$meta.id"
    label 'process_single'

    container 'ghcr.io/biocorecrg/svmodeller:sha-09ab4c7'

    input:
    tuple val(meta), path(vcf)
    tuple val(meta2), path(chr_length)
    val num_events
    val bin_size

    output:
    tuple val(meta), path("Deletions_table.tsv.gz"), emit: deletions_table
    tuple val("${task.process}"), val('svmodeller'), val('0.5.0'), topic: versions, emit: versions_svmodeller

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def num_events_arg = num_events ? "--num_events ${num_events}" : ''
    def bin_size_arg = bin_size ? "--bin_size ${bin_size}" : ''
    """
    mkdir -p \$PWD/tmp
    export MPLCONFIGDIR=\$PWD/tmp

    Module3.py \\
        --vcf_path ${vcf} \\
        --path_chromosome_length ${chr_length} \\
        ${num_events_arg} \\
        ${bin_size_arg} \\
        ${args}

    gzip Deletions_table.tsv
    """
}
