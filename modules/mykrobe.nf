process mykrobe {
  tag           "${sample}"
  stageInMode   "copy"
  publishDir    path: params.outdir, mode: 'copy'
  container     'staphb/mykrobe:0.13.0'
  maxForks      10
  //#UPHLICA errorStrategy { task.attempt < 2 ? 'retry' : 'ignore'}
  //#UPHLICA pod annotation: 'scheduler.illumina.com/presetSize', value: 'standard-medium'
  //#UPHLICA memory 1.GB
  //#UPHLICA cpus 3
  //#UPHLICA time '24h'

  when:
  flag =~ 'found'

  input:
  tuple val(sample), file(contigs), val(flag)

  output:
  path "mykrobe/${sample}.csv"                                   , emit: collect
  path "mykrobe/${sample}.json"
  path "logs/${task.process}/${sample}.${workflow.sessionId}.log", emit: log

  shell:
  '''
    mkdir -p tmp/ logs/!{task.process}
    log_file=logs/!{task.process}/!{sample}.!{workflow.sessionId}.log

    # time stamp + capturing tool versions
    date > $log_file
    echo "container : !{task.container}" >> $log_file
    mykrobe --version >> $log_file
    mykrobe panels describe >> $log_file
    echo "Nextflow command : " >> $log_file
    cat .command.sh >> $log_file

    mykrobe predict !{params.mykrobe_options} \
      --species tb \
      --sample !{sample} \
      --output mykrobe/!{sample} \
      --seq !{contigs} \
      --threads !{task.cpus} \
      --format json_and_csv \
      | tee -a $log_file
  '''
}