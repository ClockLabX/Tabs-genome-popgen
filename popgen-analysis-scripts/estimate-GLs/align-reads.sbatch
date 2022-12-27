#!/bin/bash

#options for sbatch/slurm
#SBATCH --job-name=bwa-mem
#SBATCH --cpus-per-task=8 # number of CPUs for multithreaded programs (variable is $SLURM_CPUS_PER_TASK)
#SBATCH --mem=16G # Memory pool for all cores combined. G=gigabytes. (see also --mem-per-cpu)
#SBATCH --time=1-0:00 # format: 3-0 means 3 days, 0 hours. 3:10:20 means 3 hours, 10 minutes, 20 seconds.
#SBATCH --partition=med #which node are you using?
#SBATCH --output=slurmout/%x-%j.out # File to which STDOUT will be written, with job name and Job ID
#SBATCH --error=slurmout/%x-%j.err # File to which STDERR will be written, with job name and Job ID
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
Align reads to assembly with bwa-mem.
Use samtools to then group reads by readname, add mate-pair scores/info,
re-sort by position, and mark duplicates.
Dup info can be used to filter out by ANGSD/other software.
As input, needs reference genome, and the forward and reverse read fastqs.
-Kyle Lewald
EOF

# checking for and setting up variables
if (($#!=4)); then
        echo "Usage: script.sh ref out-prefix read1 read2" >&2
        exit 2
fi

#set input parameters
reference=$1
outprefix=$2
read1=$3
read2=$4

sample=$(basename $outprefix)

# loading desired modules/conda environment
source activate alignment

# running commands
echo "+++ Running BWA and marking dups in bams"
bwa mem \
        -t $SLURM_CPUS_PER_TASK \
        -R "@RG\tID:${sample}_ID\tSM:${sample}" \
        $reference \
        $read1 $read2 |
samtools collate -@ $SLURM_CPUS_PER_TASK -u -O - | \
samtools fixmate -@ $SLURM_CPUS_PER_TASK -u -m - - | \
samtools sort -@ $SLURM_CPUS_PER_TASK -u - | \
samtools markdup -@ $SLURM_CPUS_PER_TASK -s -f ${outprefix}.dupstats -O bam - ${outprefix}.markdup.bam

echo "indexing bam file"
samtools index ${outprefix}.markdup.bam

echo "get stats"
samtools stats ${outprefix}.markdup.bam > ${outprefix}.markdup.bam.stat
plot-bamstats -p ${outprefix}-stats/ ${outprefix}.markdup.bam.stat

echo "done"
# getting end time to calculate time elapsed
end=$(date +%s)
elapsed=$(expr $end - $begin)
echo Time taken: $elapsed
