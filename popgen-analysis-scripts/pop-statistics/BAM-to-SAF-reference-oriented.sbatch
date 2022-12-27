#!/bin/bash

#options for sbatch
#SBATCH --nodes=1
#SBATCH --job-name=maf-SNPs
#SBATCH --ntasks=1 # Number of tasks (typically one)
#SBATCH --cpus-per-task=16 # number of CPUs for multithreaded programs ($SLURM_CPUS_PER_TASK)
#SBATCH --mem=16G # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --time=12:00:00 # 0 days, 2 hours
#SBATCH --partition=med
#SBATCH --output=slurmout/%x-%j.out # File to which STDOUT will be written, with job name and Job ID
#SBATCH --error=slurmout/%x-%j.err # File to which STDERR will be written, with job name and Job ID


# for calculating the amount of time the job takes
begin=`date +%s`
echo $HOSTNAME

#warn if slurmout directory doesn't exist
if [[ ! -d slurmout ]]
then
        echo "error: slurmout directory does not exist"
        exit 1
fi

# for calculating the amount of time the job takes
begin=$(date +%s)
echo $HOSTNAME

# summary
cat << EOF
Purpose of this script:
Output allele frequencies in a "mafs" format of a population, but forces the "major allele" 
to be the reference allele. This allows easier comparison of frequencies between pops.
Was used primarily to compare SNP frequencies identified by PBS to be under selection.
Inputs:
	reference genome
	text file of BAMs of individuals to analyze
	optional region file specifying genomic intervals (in ANGSD format)
-Kyle Lewald
EOF

# checking for and setting up variables
if (($#==0)); then
        echo "Usage: script.sh ref output_prefix bamfilelist '-rf region_file'(optional)" >&2
        exit 2
fi

ref=$1
prefix=$2
bamlist=$3
region=$4

# loading modules/programs
angsd="~programs/angsd933/angsd"

# running commands
echo "Calculating MAF:" $(date)

$angsd -P $SLURM_CPUS_PER_TASK \
	-minQ 20 \
	-minmapQ 20 \
	-uniqueOnly 1 \
	-only_proper_pairs 1 \
	-remove_bads 1 \
	-bam $bamlist \
	-doMaf 1 \
	-domajorminor 5 \
	-SNP_pval 1e-3 \
	-anc $ref \
	-GL 1 \
	-out $prefix $region
echo "done:" $(date)

#will output a .maf.gz file, filtered to only include SNPs with pval lower than threshold.
#major/minor needed to properly "orient" the .maf output. Here, we orient by reference genome as the "ancestral".

# getting end time to calculate time elapsed
end=`date +%s`
elapsed=`expr $end - $begin`
echo Time taken: $elapsed
