#!/bin/bash

#options for sbatch/slurm
#SBATCH --nodes=1
#SBATCH --job-name=ngsadmix
#SBATCH --ntasks=1 # Number of tasks (typically one)
#SBATCH --cpus-per-task=4 # number of CPUs for multithreaded programs (variable is $SLURM_CPUS_PER_TASK)
#SBATCH --mem=8G # Memory pool for all cores combined. G=gigabytes. (see also --mem-per-cpu)
#SBATCH --time=12:00:00 # format: 3-0 means 3 days, 0 hours. 3:10:20 means 3 hours, 10 minutes, 20 seconds.
#SBATCH --partition=med #which node are you using?
#SBATCH --output=slurmout/%x-%j.out # File to which STDOUT will be written, with job name and Job ID
#SBATCH --error=slurmout/%x-%j.err # File to which STDERR will be written, with job name and Job ID

# for calculating the amount of time the job takes
begin=`date +%s`
echo $HOSTNAME

# summary
cat << EOF
Purpose of this script:
Run NGSadmix on a beagle file and given value of "k" to assign cluster identity.
Need to filter the beagle file to only include samples you want to cluster.
-Kyle Lewald
EOF
# checking for and setting up variables
if (($#!=3)); then
        echo "Usage: script.sh beagle.gz k_value output_location_prefix" >&2
        exit 2
fi

#set input parameters
BEAGLE=$1
K=$2
OUT=$3
# loading desired modules/conda environment

# running NGSadmix
NGSadmix \
        -likes $BEAGLE \
        -K $K \
        -outfiles $OUT \
        -printInfo 1 \
        -P $SLURM_CPUS_PER_TASK \
        -seed $RANDOM \
        -minMaf 0.05 \
        -maxiter 6000

# getting end time to calculate time elapsed
end=`date +%s`
elapsed=`expr $end - $begin`
echo Time taken: $elapsed
