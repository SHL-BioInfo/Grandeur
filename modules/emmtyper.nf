process emmtyper {
  tag           "${sample}"
  stageInMode   "copy"
  publishDir    path: params.outdir, mode: 'copy'
  container     'staphb/emmtyper:0.2.0'
  maxForks      10
  //#UPHLICA errorStrategy { task.attempt < 2 ? 'retry' : 'ignore'}
  //#UPHLICA pod annotation: 'scheduler.illumina.com/presetSize', value: 'standard-medium'
  //#UPHLICA memory 1.GB
  //#UPHLICA cpus 3
  //#UPHLICA time '24h'
  
  when:
  flag =~ 'found'

  input:
  tuple val(sample), file(contigs), val(flag), file(script)

  output:
  path "emmtyper/${sample}_emmtyper.txt"                         , emit: collect
  path "emmtyper/*"                                              , emit: everything
  path "logs/${task.process}/${sample}.${workflow.sessionId}.log", emit: log

  shell:
  '''
    mkdir -p emmtyper logs/!{task.process}
    log_file=logs/!{task.process}/!{sample}.!{workflow.sessionId}.log

    # time stamp + capturing tool versions
    PATH=/opt/conda/envs/emmtyper/bin:$PATH
    date > $log_file
    echo "container : !{task.container}" >> $log_file
    emmtyper --version >> $log_file
    echo "Nextflow command : " >> $log_file
    cat .command.sh >> $log_file
    
    emmtyper !{params.emmtyper_options} \
      --output-format 'verbose' \
      !{contigs} \
      | tee -a $log_file \
      > !{sample}_emmtyper.txt

    python3 !{script} !{sample}_emmtyper.txt emmtyper/!{sample}_emmtyper.txt emmtyper !{sample}
  '''
}
