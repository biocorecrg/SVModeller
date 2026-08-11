process SVMODELLER_MODULE5 {
    tag "$meta.id"
    label 'process_high'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'ghcr.io/biocorecrg/svmodeller:sha-09ab4c7' :
        'ghcr.io/biocorecrg/svmodeller:sha-09ab4c7' }"

    input:
    tuple val(meta),  path(modified_genome)
    tuple val(meta2), path(ref_fasta)
    val  method_file
    val  method
    val  coverage
    val  allele_frequency
    val  technology

    output:
    tuple val(meta), path("${meta.id}/combined_final_alignment.bam")    , emit: bam
    tuple val(meta), path("${meta.id}/combined_final_alignment.bam.bai"), emit: bai
    tuple val("${task.process}"), val('svmodeller'), val('0.5.0'), topic: versions, emit: versions_svmodeller

    when:
    task.ext.when == null || task.ext.when

    script:
    def args           = task.ext.args ?: ''
    def threads_arg    = task.cpus ?: 1
    def ref_arg        = ref_fasta ? "--reference_genome ${ref_fasta}" : ''
    // PBSIM does not support gzipped FASTA - decompress on the fly if needed
    def mod_fasta      = modified_genome.name.endsWith('.gz') ? modified_genome.baseName : modified_genome.name
    def decompress_cmd = modified_genome.name.endsWith('.gz') ? "gunzip -k ${modified_genome}" : ''
    """
    mkdir -p \$PWD/tmp
    export MPLCONFIGDIR=\$PWD/tmp

    ${decompress_cmd}

    Module5.py \\
        ${ref_arg} \\
        --modified_genome  ${mod_fasta} \\
        --method_file      ${method_file} \\
        --method           ${method} \\
        --coverage         ${coverage} \\
        --allele_frequency ${allele_frequency} \\
        --technology       ${technology} \\
        --threads          ${threads_arg} \\
        --output_dir       ${meta.id} \\
        ${args}
    """
}
