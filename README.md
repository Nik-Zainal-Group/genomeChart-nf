# genomeChart nextflow pipeline

## Table of content

- [Introduction to the package](#intro)
- [Versions](#version)
- [Requirements](#req)
- [Example runs](#example)

## Introduction to the package

<a name="intro"></a>

This repository contains a nextflow pipeline to produce genomeCharts using the 
genomeChart command line script from signature.tools.lib. It also uses the
prepareData function from utility.scripts to filter and format data from a
variety to somatic mutation callers.

## Versions

<a name="version"></a>

0.1.0

- basic pipeline running with default options supporting the Sanger and Illumina
mutation callers

## Requirements

<a name="req"></a>

This is a Nextflow pipeline, so it requires Nextflow, and optionally Docker.

The pipeline can be run locally or using docker. When running locally it requires
that ```utility.scripts``` and ```signature.tools.lib``` are installed locally and
that the ```prepareData``` and ```genomeChart``` command line scripts are accessible
from command line. Otherwise, a Docker image with these packages already installed 
will be pulled from Docker Hub.


## Example runs

<a name="example"></a>

You can test the package by entering the package main directory and
typing from the R environment:

```
nextflow run main.nf \
  -profile local \
  --data_tsv_file test.tsv \
  --genomev hg38 \
  --data_rootdir /path/to/mutation/calling/ \
  --outdir ./results

nextflow run main.nf \
  -profile docker \
  --data_tsv_file test.tsv \
  --genomev hg38 \
  --data_rootdir /path/to/mutation/calling/ \
  --outdir ./results_docker

```

The ```data_tsv_file``` should be tab delimited and contain the following columns:

```
sampleid	snvs	indels	cnvs	svs
...
```

Each row should contain a sample id and the corresponding locations of the vcf files
relative to the ```data_rootdir``` folder.
