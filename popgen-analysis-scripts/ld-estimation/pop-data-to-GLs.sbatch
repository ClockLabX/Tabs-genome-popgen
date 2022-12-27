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

# checking for and setting up variables
if (($#!=4)); then
        echo "Usage: script.sh ref bamfilelist.txt regions_file output_prefix" >&2
        exit 2
fi

REF=$1
BAMFILELIST=$2
REGION=$3
OUTFILE=$4


# loading modules
source activate angsd

# summary
cat << EOF
Purpose of this script:
Estimate genotype likelihoods from BAM file, filtering out SNPs with p>1e-6
Outputs a 10% subset beagle file and a MAF file.
Designed to be used for estimating GLs across multiple populations, 
polarizing by using the "reference" allele as the "major" allele.
Intended to be used for LD estimation.

Inputs:
        ANGSD-indexed regions file that contains "chromosome:start-stop" regions to call GLs from.
        reference genome
        text file containing paths to all BAM files in the population being analyzed.

Since I want to make sure the genotypes are polarized correctly, I'll use majorminor 4
to force the "major" to be the reference allele.
-Kyle Lewald
EOF

# running commands
echo "estimating genotype likelihoods (beagle) with angsd."
angsd -nThreads $SLURM_CPUS_PER_TASK -bam $BAMFILELIST -ref $REF \
    -rf $REGION \
    -doMaf 1 -doMajorMinor 4 -GL 1 -doGlf 2 \
    -SNP_pval 1e-6 -C 50 -minMapQ 20 -minQ 20 -uniqueOnly 1 -only_proper_pairs 1 \
    -remove_bads 1 \
    -out $OUTFILE

echo "make a 10% subset of beagle file"
zcat $OUTFILE.beagle.gz| awk 'NR==1 {print} NR>1 {if (rand()<0.1) {print}}' | \
        gzip -c > $OUTFILE.10perc.beagle.gz

# to call SNPs, need allele freqs. doMaf estimates minor allele frq.
# majorminor 4 calls the major/minor allele based on the reference allele.
# GL specifies likelihood model. doGlf 2 specifies likelihood output file type to be beagle text.
# SNP_pval, minMaf, minInd, minMapQ, minQ, and uniqueOnly are various filters.
# remove_bads and only_proper_pairs should be on by default, by I add it anyways.

# getting end time to calculate time elapsed
end=`date +%s`
elapsed=`expr $end - $begin`
echo Time taken: $elapsed
