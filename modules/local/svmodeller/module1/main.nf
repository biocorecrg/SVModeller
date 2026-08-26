process SVMODELLER_MODULE1 {
    tag "$meta.id"
    label 'process_single'

    container 'ghcr.io/biocorecrg/svmodeller:sha-09ab4c7'

    input:
    tuple val(meta), path(vcf)
    tuple val(meta2), path(chr_length)
    val bin_size

    output:
    tuple val(meta), path("Genome_Wide_Distribution.tsv.gz"), emit: genome_wide_distribution
    tuple val(meta), path("Insertion_Features.tsv.gz")      , emit: insertion_features
    tuple val(meta), path("Probabilities.tsv.gz")           , emit: probabilities
    tuple val("${task.process}"), val('svmodeller'), val('0.5.0'), topic: versions, emit: versions_svmodeller

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def bin_size_arg = bin_size ? "--bin_size ${bin_size}" : ''
    """
    mkdir -p \$PWD/tmp
    export MPLCONFIGDIR=\$PWD/tmp

    Module1.py \\
        --file_path ${vcf} \\
        --chromosome_length ${chr_length} \\
        ${bin_size_arg} \\
        ${args}

    gzip Genome_Wide_Distribution.tsv
    gzip Insertion_Features.tsv
    gzip Probabilities.tsv
    """
}
