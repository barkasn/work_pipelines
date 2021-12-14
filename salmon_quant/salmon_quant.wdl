version 1.0

task bam_to_fastq {
  input {
    File input_bam

    String docker = "us.gcr.io/broad-gotc-prod/samtools-picard-bwa:1.0.0-0.7.15-2.23.8-1626449438"
    Int machine_mem_mb = 8250
    Int cpu = 1
    Int disk = ceil(size(input_bam, "Gi") * 10) + 10
    Int preemptible = 3
  }
  String picard_exec = "/usr/gitc/picard.jar"
  String output_fastq_1_filename = "output_1.fq"
  String output_fastq_2_filename = "output_2.fq"
  command <<<
    java -jar ~{picard_exec} SamToFastq I=~{input_bam} FASTQ=~{output_fastq_1_filename} SECOND_END_FASTQ=~{output_fastq_2_filename} 
  >>>
  runtime {
    docker: docker
    memory: "~{machine_mem_mb} MiB"
    disks: "local-disk ~{disk} HDD"
    cpu: cpu
    preemptible: preemptible
  }
  output {
    File fastq1 = "~{output_fastq_1_filename}"
    File fastq2 = "~{output_fastq_2_filename}"
  }
}


task salmon_build_index {
  input {
    File transcripts_fastq
    Int kmer = "31"

    String docker = "quay.io/nbarkas_1/salmon_quant:0.0.1"
    Int machine_mem_mb = 16000
    Int cpu = 2
    Int disk = ceil(size(transcripts_fastq, "Gi") * 10) + 10
    Int preemptible = 3
  }

  String salmon_exec = "/opt/salmon/bin/salmon"

  command <<<
    ~{salmon_exec} index -t ~{transcripts_fastq} -i transcripts_index -k ~{kmer}
    tar cvf transcripts_index.tar transcripts_index
  >>>

  runtime {
    docker: docker
    memory: "~{machine_mem_mb} MiB"
    disks: "local-disk ~{disk} HDD"
    cpu: cpu
    preemptible: preemptible
  }

  output {
    File index_tar = "transcripts_index.tar"
  } 
}

task salmon_count {
  input {
    File fastq1
    File fastq2
    File salmon_index_tar

    String docker = "quay.io/nbarkas_1/salmon_quant:0.0.1"
    Int machine_mem_mb = 16000
    Int cpu = 2
    Int disk = ceil(size(salmon_index_tar, "Gi") * 10) + ceil(size(fastq1, "Gi")) + ceil(size(fastq2, "Gi")) + 10
    Int preemptible = 3
  }

  String salmon_exec = "/opt/salmon/bin/salmon"

  command <<<
    tar xf ~{salmon_index_tar}
    ~{salmon_exec} quant -i transcripts_index -l A -1 ~{fastq1} -2 ~{fastq2} -o salmon_output
  >>>

  runtime {
    docker: docker
    memory: "~{machine_mem_mb} MiB"
    disks: "local-disk ~{disk} HDD"
    cpu: cpu
    preemptible: preemptible
  }

  output {
    File salmon_quant = "salmon_output/quant.sf"
  }
}

workflow salmon_quant_from_ubam {
  input {
    File input_bam
    File transcripts_fastq
  }

  call bam_to_fastq {
    input:
      input_bam = input_bam
  }

  call salmon_build_index {
    input:
      transcripts_fastq = transcripts_fastq
  }

  call salmon_count {
    input:
      fastq1 = bam_to_fastq.fastq1,
      fastq2 = bam_to_fastq.fastq2,
      salmon_index_tar = salmon_build_index.index_tar
  }

  output {
    File salmon_out = salmon_count.salmon_quant
  }
}

