#!/bin/bash

#options for sbatch
#SBATCH --nodes=1
#SBATCH --job-name=treemix
#SBATCH --ntasks=1 # Number of tasks (typically one)
#SBATCH --cpus-per-task=1 # number of CPUs for multithreaded programs (FARM CPUs can handle 2 threads/core simultaneously)
#SBATCH --mem=4G # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --time=4:00:00 # 0 days, 2 hours
#SBATCH --partition=med
#SBATCH --output=slurmout/%x-%A-%a.out # File to which STDOUT will be written, with job name and Job ID
#SBATCH --error=slurmout/%x-%A-%a.err # File to which STDERR will be written, with job name and Job ID
#SBATCH --array=00-99 #Use $SLURM_ARRAY_TASK_ID to refer to array index in script

# for calculating the amount of time the job takes
begin=`date +%s`
echo $HOSTNAME

# summary
cat << EOF
Purpose of this script:
Run Treemix in bootstrap mode, using the $SLURM_ARRAY_TASK_ID to iterate.
As inputs:
        the input genotype file (in treemix format)
        number of migration edges to allow
        Population to root by
        blocksize (for SE calculation/bootstrapping)
-Kyle Lewald
EOF

# checking for and setting up variables
if (($#!=5)); then
    echo "Usage: script.sh input_filename migration_edges output_file_prefix root blocksize" >&2
    exit 2
fi

INFILE=$1
EDGES=$2
OUTSTEM=$3
ROOT=$4
BLOCKSIZE=$5
# running commands
treemix \
        -i $INFILE \
        -m $EDGES \
        -o $OUTSTEM.rep${SLURM_ARRAY_TASK_ID} \
        -root $ROOT \
        -k $BLOCKSIZE \
        -bootstrap \
        -global \
        -se \
        > $OUTSTEM.rep${SLURM_ARRAY_TASK_ID}.log

# getting end time to calculate time elapsed
end=`date +%s`
elapsed=`expr $end - $begin`
echo Time taken: $elapsed
