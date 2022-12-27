#!/bin/bash

#options for sbatch
#SBATCH --nodes=1
#SBATCH --job-name=beagle-gl
#SBATCH --ntasks=1 # Number of tasks (typically one)
#SBATCH --cpus-per-task=4 # number of CPUs for multithreaded programs (FARM CPUs can handle 2 threads/core simultaneously)
#SBATCH --mem=10G # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --time=7-0 # 0 days, 2 hours
#SBATCH --partition=bigmemht
#SBATCH --output=slurmout/%x-%j.out # File to which STDOUT will be written, with job name and Job ID
#SBATCH --error=slurmout/%x-%j.err # File to which STDERR will be written, with job name and Job ID

# for calculating the amount of time the job takes
begin=`date +%s`
echo $HOSTNAME

# summary
cat << EOF
Purpose of this script:
Estimate genotype likelihoods from BAM file. Outputs beagle format.
For input, takes the reference genome, text file containing filepaths of all BAMs,
and achromosome name to run on. ie "contig001".

-Kyle Lewald
EOF

# checking for and setting up variables
if (($#!=4)); then
        echo "Usage: script.sh ref bamfilelist.txt contig_name output_prefix" >&2
        exit 2
fi

REF=$1
BAMFILELIST=$2
CONTIG=$3
OUTFILE=$4

# loading modules
source activate angsd

# running commands
echo "estimating genotype likelihoods (beagle) with angsd."
angsd -nThreads $SLURM_CPUS_PER_TASK -bam $BAMFILELIST -ref $REF \
    -r $CONTIG: \
    -doMaf 1 -doMajorMinor 1 -GL 1 -doGlf 2 \
    -SNP_pval 1e-6 -minMaf 0.05 -C 50 -minMapQ 20 -minQ 20 -uniqueOnly 1 -only_proper_pairs 1 \
    -remove_bads 1 \
    -out $OUTFILE

# to call SNPs, need allele freqs. doMaf estimates minor allele frq.
# majorminor 1 calls the major/minor allele from GLs. GL specifies likelihood model. doGlf specifies likelihood output file type. 2=beagle text.
# SNP_pval, minMaf, minInd, minMapQ, minQ, and uniqueOnly are various filters.
# remove_bads and only_proper_pairs should be on by default, by I add it anyways.
# OUTPUTS .mafs.gz - SNP file.
#         .beagle.gz - likelihood file.

# getting end time to calculate time elapsed
end=`date +%s`
elapsed=`expr $end - $begin`
echo Time taken: $elapsed
