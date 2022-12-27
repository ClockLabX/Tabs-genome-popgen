#!/bin/bash

#options for sbatch/slurm
#SBATCH --nodes=1
#SBATCH --job-name=GT-inbreed
#SBATCH --ntasks=1 # Number of tasks (typically one)
#SBATCH --cpus-per-task=12 # number of CPUs for multithreaded programs (variable is $SLURM_CPUS_PER_TASK)
#SBATCH --mem=20G # Memory pool for all cores combined. G=gigabytes. (see also --mem-per-cpu)
#SBATCH --time=1-0 # format: 3-0 means 3 days, 0 hours. 3:10:20 means 3 hours, 10 minutes, 20 seconds.
#SBATCH --partition=bigmemht #which node are you using?
#SBATCH --output=slurmout/%x-%j.out # File to which STDOUT will be written, with job name and Job ID
#SBATCH --error=slurmout/%x-%j.err # File to which STDERR will be written, with job name and Job ID


# for calculating the amount of time the job takes
begin=`date +%s`
echo $HOSTNAME

# summary
cat << EOF
Purpose of this script:
Take a beagle genotype file, estimate inbreeding values per individual, and call genotypes using inbreeding as a prior.
As inputs:
        beagle.gz file
        file of 0/1's to specify which samples in beagle.gz to analyze
        file containing names of each sample to use for genotype output.
        genotype confidence threshold value (between 0-1).

-Kyle Lewald
EOF

# checking for and setting up variables
if (($#!=5)); then
        echo "Usage: script.sh beagle.gz_file text_file_specifying_samples sample_names.txt output_filename genotype_confidence" >&2
        exit 2
fi

#set input parameters
BEAGLE=$1
SAMPLES=$2
SAMPLES_NAME=$3
#sample_names file contains sample names, 1/line, in same order as beagle.gz file.
OUTPUT=$4
THRESHOLD=$5

# loading desired modules/conda environment
module load bio3/1.0
PCANGSD=~/programs/pcangsd-1.0/pcangsd.py

# running commands

echo "running PCA to estimate inbreeding F and output genotypes"
python $PCANGSD -beagle $BEAGLE \
        -filter $SAMPLES \
        -threads $SLURM_CPUS_PER_TASK \
        -o $OUTPUT \
        -inbreedSamples \
        -genoInbreed $THRESHOLD \
        -sites_save \
        -iter 500 \
        -inbreed_iter 1000
#filter needs a input file, containing 0 or 1 to tell which samples to use; same order as beagle file.
#inbreedSamples will estimate inbreeding coefficient of each sample, using estimated indiv allele freqs.
#genoInbreed calls genotypes, using inbreeding values as priors. Using 95% probability cutoff for genotype.

echo "cleaning up output files"
#attach sample names/info to inbreeding file
paste $SAMPLES_NAME $OUTPUT.inbreed.samples > $OUTPUT.inbreed.txt
rm $OUTPUT.inbreed.samples

#converting genotype npy file to text
python3 - <<HERE
import numpy as np
data = np.load("$OUTPUT.geno.inbreed.npy")
np.savetxt("$OUTPUT.temp.txt", data, fmt='%d', delimiter = '\t')
HERE

#add samples as headers to genotype text file.
cat $SAMPLES_NAME | tr "\n" "\t" | sed 's/\t$/\n/' > $OUTPUT.geno.inbreed.txt

cat $OUTPUT.temp.txt >> $OUTPUT.geno.inbreed.txt
rm $OUTPUT.temp.txt

# getting end time to calculate time elapsed
end=`date +%s`
elapsed=`expr $end - $begin`
echo Time taken: $elapsed
