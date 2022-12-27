#!/bin/bash

#options for sbatch/slurm
#SBATCH --nodes=1
#SBATCH --job-name=pcangsd
#SBATCH --ntasks=1 # Number of tasks (typically one)
#SBATCH --cpus-per-task=4 # number of CPUs for multithreaded programs (variable is $SLURM_CPUS_PER_TASK)
#SBATCH --mem=8G # Memory pool for all cores combined. G=gigabytes. (see also --mem-per-cpu)
#SBATCH --time=1-0 # format: 3-0 means 3 days, 0 hours. 3:10:20 means 3 hours, 10 minutes, 20 seconds.
#SBATCH --partition=med #which node are you using?
#SBATCH --output=slurmout/%x-%j.out # File to which STDOUT will be written, with job name and Job ID
#SBATCH --error=slurmout/%x-%j.err # File to which STDERR will be written, with job name and Job ID


# for calculating the amount of time the job takes
begin=`date +%s`
echo $HOSTNAME

# summary
cat << EOF
Purpose of this script:
Run PCangsd on input to do PCA.
Will also attempt to do cluster asignment for a given value of "k" to determine cluster identity.
As inputs supply
        -a beagle genotype likelihood file
        -a text file consisting of 0s or 1s to indicate which samples in beagle file to analyze (in order as presented
in beagle file)
        -value of "k" to use for clustering.
-Kyle Lewald
EOF

# checking for and setting up variables
if (($#!=4)); then
        echo "Usage: script.sh beagle.gz_file text_file_specifying_samples output_filename k_value" >&2
        exit 2
fi

#set input parameters
BEAGLE=$1
SAMPLES=$2
OUTPUT=$3
K=$4

# loading desired modules/conda environment
module load bio3
PCANGSD=~/programs/pcangsd-1.0/pcangsd.py
# running commands

echo "running PCA with indiv allele frq estimation; and admixture estimation"
python $PCANGSD -beagle $BEAGLE \
        -sites_save \
        -filter $SAMPLES \
        -threads $SLURM_CPUS_PER_TASK \
        -o $OUTPUT \
        -admix \
        -admix_seed $RANDOM \
        -admix_auto 500 \
        -admix_K $K 
#sites_save will output record of which SNPs were kept/used
#filter needs a input file, containing 0 or 1 to tell which samples to use; same order as beagle file.
#admix will auto-calc admixture proportions. Will use K=e=1, e=# PCs kept based on MAP test.
#admix-seed sets the random starting point (default is 0 otherwise). I'm using bash $RANDOM (0-32767)
#admix_auto will search for optimal alpha, to reduce error.

# getting end time to calculate time elapsed
end=`date +%s`
elapsed=`expr $end - $begin`
echo Time taken: $elapsed
