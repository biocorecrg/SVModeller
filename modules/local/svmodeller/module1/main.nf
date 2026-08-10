process SVMODELLER_MODULE1 {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'ghcr.io/biocorecrg/svmodeller:0.5.0' :
        'ghcr.io/biocorecrg/svmodeller:0.5.0' }"

    input:
    tuple val(meta), path(vcf)
    tuple val(meta2), path(chr_length)
    val bin_size

    output:
    tuple val(meta), path("Genome_Wide_Distribution.tsv"), emit: genome_wide_distribution
    tuple val(meta), path("Insertion_Features.tsv")      , emit: insertion_features
    tuple val(meta), path("Probabilities.tsv")           , emit: probabilities
    path "versions.yml"                                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def bin_size_arg = bin_size ? "--bin_size ${bin_size}" : ''
    """
    Module1.py \\
        --file_path ${vcf} \\
        --chromosome_length ${chr_length} \\
        ${bin_size_arg} \\
        ${args}

    cat <<EOF > versions.yml
    "${task.process}":
        svmodeller: "0.5.0"
    EOF
    """
}
