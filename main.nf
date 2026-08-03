#!/usr/bin/env nextflow

nextflow.enable.dsl=2

params.data_tsv_file = "./input.tsv"
params.data_rootdir  = "."
params.outdir        = "./results"
params.genomev       = "hg38"
params.snv_caller    = "caveman"
params.indel_caller  = "pindel"
params.cnv_caller    = "ascat"
params.sv_caller     = "brass"


process PREPARE_DATA {
  tag "${sample_id}"
  publishDir path: { "${params.outdir}/${sample_id}/prepared_data" }, mode: 'copy'

  input:
  tuple val(sample_id), path(snvs_vcf), path(indels_vcf), path(cnvs_vcf), path(svs_vcf)

  output:
  tuple val(sample_id), path("samples_prepared"), path("samples_prepared/preparedFilesTable.tsv"), emit: prepared_data

  script:
  // Determine appropriate flags based on the callers used
  // strelka -N flag is default for SNVs, change otherwise
  def snv_flag = "-N"
  if(params.snv_caller?.toLowerCase()=='caveman'){
    snv_flag = '-C'
  }
  // strelka -I flag is default for Indels, change otherwise
  def indel_flag = "-I"
  if(params.indel_caller?.toLowerCase()=='pindel'){
    indel_flag = '-P'
  }
  // canvas -V flag is default for CNVs, change otherwise
  def cnv_flag = "-V"
  if(params.cnv_caller?.toLowerCase()=='ascat'){
    cnv_flag = '-A'
  }
  // manta -M flag is default for SVs, change otherwise
  def sv_flag = "-M"
  if(params.sv_caller?.toLowerCase()=='brass'){
    sv_flag = '-B'
  }

  """
  # Prepare files and flags for prepareData
  ADDITIONAL_FLAGS="-c -p -s -m"

  SNV_ARG=""
  if [ -f "${snvs_vcf}" ]; then
    echo -e "${sample_id}\t${snvs_vcf}" > snvs.txt
    SNV_ARG="${snv_flag} snvs.txt"
  fi

  INDEL_ARG=""
  if [ -f "${indels_vcf}" ]; then
    echo -e "${sample_id}\t${indels_vcf}" > indels.txt
    INDEL_ARG="${indel_flag} indels.txt"
  fi

  CNV_ARG=""
  if [ -f "${cnvs_vcf}" ]; then
    echo -e "${sample_id}\t${cnvs_vcf}" > cnvs.txt
    CNV_ARG="${cnv_flag} cnvs.txt"
  fi

  SV_ARG=""
  if [ -f "${svs_vcf}" ]; then
    echo -e "${sample_id}\t${svs_vcf}" > svs.txt
    SV_ARG="${sv_flag} svs.txt"
  fi

  # 2. Run prepareData with mapped flags
  prepareData \
    -o samples_prepared/ \
    -g ${params.genomev} \
    \${SNV_ARG} \
    \${INDEL_ARG} \
    \${CNV_ARG} \
    \${SV_ARG} \
    \${ADDITIONAL_FLAGS} \
    -O
  """
}

process GENOME_CHART {
  tag "${sample_id}"
  publishDir path: { "${params.outdir}/${sample_id}/genome_charts" }, mode: 'copy'

  input:
  tuple val(sample_id), path(prepared_dir), path(prepared_table)

  output:
  path "genomeCharts/*"

  script:
  """
  genomeChart \
    -i ${prepared_table} \
    -o genomeCharts \
    -e ${params.genomev}
  """
}

workflow {

  log.info """
  ###############################################
  Signature Tools Pipeline - GenomeChart
  TSV Input File  : ${params.data_tsv_file}
  VCF Root Dir    : ${params.data_rootdir}
  Genome Version  : ${params.genomev}
  Output Dir      : ${params.outdir}
  -----------------------------------------------
  SNVs Caller   : ${params.snv_caller}
  Indels Caller : ${params.indel_caller}
  CNVs Caller   : ${params.cnv_caller}
  SVs Caller    : ${params.sv_caller}
  ###############################################
"""

  // fail-fast protection in case params.datarootdir is not reachable
  file(params.data_rootdir, checkIfExists: true)

  // 1. Read the data
  ch_samples = channel.fromPath(params.data_tsv_file, checkIfExists: true)
    | splitCsv(header: true,sep: "\t")
    | map { row ->
      tuple(
        row.sampleid,
        row.snvs?.trim()   ? file("${params.data_rootdir}/${row.snvs.trim()}", checkIfExists: true)   : [],
        row.indels?.trim() ? file("${params.data_rootdir}/${row.indels.trim()}", checkIfExists: true) : [],
        row.cnvs?.trim()   ? file("${params.data_rootdir}/${row.cnvs.trim()}", checkIfExists: true)   : [],
        row.svs?.trim()    ? file("${params.data_rootdir}/${row.svs.trim()}", checkIfExists: true)    : []
      )
    }
    |view()

  // 2. Run prepareData
  PREPARE_DATA(ch_samples)

  // 3. Run genomeChart
  GENOME_CHART(PREPARE_DATA.out.prepared_data)
}
