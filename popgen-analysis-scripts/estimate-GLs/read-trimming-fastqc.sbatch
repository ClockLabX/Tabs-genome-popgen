#!/bin/bash

# options for sbatch
#SBATCH -J scythe_sickle_interweaved
#SBATCH -o slurmout/Scythe_Sickle-%j.out
#SBATCH -e slurmout/Scythe_Sickle-%j.err
#SBATCH -t 1-0
#SBATCH -p bigmemht
#SBATCH --mail-type=END # Type of email notification- BEGIN,END,FAIL,ALL

#if slurmout directory doesn't exist, stops script.
if [[ ! -d slurmout ]]
then
    echo "Missing a slurmout directory"
    exit 1
fi

# for calculating the amount of time the job takes
begin=$(date +%s)
echo $HOSTNAME

# summary
cat << EOF
Purpose of this script:
Run scythe to trim off adapters, and run scickle to trim bad-quality bases.
For this script to work, make a "scythed", "sickled", and "fastq" folder.
As input, uses paired-end fastq that is INTERWEAVED (not 2 sep files).
Also needs fasta of adapter sequences.
-Kyle Lewald
EOF

# checking for and setting up variables
if (($#!=3)); then
        echo "Usage: script.sh FASTQ-interweave adapters.fa output-prefix" >&2
        exit 2
fi

# loading modules

module load scythe/0.991
module load sickle/1.33
module load fastqc/0.11.9

#variables
FASTQ=$1
ADAPTERS=$2
PREFIX=$3
# running commands

#scythe to trim off adapters
scythe -a $ADAPTERS -o 01-scythed/$PREFIX.scythed.fq $FASTQ

#sickle to trim reads by quality score. Taking a interweaved paired-end fastq file.
sickle pe -g -t sanger -c 02-scythed/$PREFIX.scythed.fq -m 01-sickled/$PREFIX.pe.sickle.fq.gz -s 01-sickled/$PREFIX.singles.sickle.fq.gz

#run fastqc
fastqc 02-sickled/$PREFIX.pe.sickle.fq.gz -o fastqc
