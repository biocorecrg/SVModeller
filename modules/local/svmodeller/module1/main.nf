process SVMODELLER_MODULE1 {
    tag "$meta.id"
    label 'process_single'

    input:
    tuple val(meta), path(vcf)
    tuple val(meta2), path(chr_length)
    val bin_size

    output:
    tuple val(meta), path("Genome_Wide_Distribution.tsv.gz")  , emit: genome_wide_distribution
    tuple val(meta), path("Insertion_Features.tsv.gz")        , emit: insertion_features
    tuple val(meta), path("Probabilities.tsv.gz")             , emit: probabilities
    tuple val(meta), path("SVA_VNTR_Motifs.txt.gz")           , emit: sva_vntr_motifs
    tuple val(meta), path("VNTR_with_start_position.txt.gz")  , emit: vntr_with_start_position
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

    for i in *.tsv; do gzip \$i; done
    for i in *.txt; do gzip \$i; done
    """
}
