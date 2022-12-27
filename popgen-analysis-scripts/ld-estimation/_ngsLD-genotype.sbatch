#!/bin/bash

#options for sbatch
#SBATCH --nodes=1
#SBATCH --job-name=ngsLD
#SBATCH --ntasks=1 # Number of tasks (typically one)
#SBATCH --cpus-per-task=4 # number of CPUs for multithreaded programs (FARM CPUs can handle 2 threads/core simultaneously)
#SBATCH --mem=4G # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --time=1-0:00 # 0 days, 2 hours
#SBATCH --partition=med
#SBATCH --output=slurmout/%x-%j.out # File to which STDOUT will be written, with job name and Job ID
#SBATCH --error=slurmout/%x-%j.err # File to which STDERR will be written, with job name and Job ID


# for calculating the amount of time the job takes
begin=`date +%s`
echo $HOSTNAME

# summary
cat << EOF
Purpose of this script:
Calculate LD between SNPs pairwise from a genotype file and position file.
Genotype file should be gzipped tsv; 1 row/site, 1 column/individual, value={0,1,2}.
position file = "chromosome pos", with header assumed to be included.
Only going out to 10kb distance for pairwise LD estimates. But will use all input SNPs.
Also estimates LD decay using 1% subsample of LD values.

As input, needs a genotype file, a file of positions, and the output name prefix.
-Kyle Lewald
EOF

# checking for and setting up variables
if (($#!=3)); then
        echo "Usage: script.sh genotypes positions Output_prefix" >&2
        exit 2
fi

GENOTYPES=$1
POSITIONS=$2
OUTPUT=$3

# load modules
module load R/3.6.3

# get number of SNPs from file, subtract header line.
SNPCOUNT=$(expr $(cat $POSITIONS | wc -l) - 1)
echo "Number of SNPs used: " $SNPCOUNT

#number of individuals?
NIND=$(zcat $GENOTYPES |head | awk 'END {print NF}')

echo "Running ngsLD to estimate LD"
ngsLD --n_threads $SLURM_CPUS_PER_TASK \
    --geno $GENOTYPES \
    --n_ind $NIND \
    --posH $POSITIONS \
    --n_sites $SNPCOUNT \
    --max_kb_dist 10 \
    --outH $OUTPUT.10kb.ld

echo "Making 1% subsampled file for LD decay"
awk 'rand()<0.1 {print}' $OUTPUT.10kb.ld | pigz -p $SLURM_CPUS_PER_TASK -c > $OUTPUT.10kb.1%.ld.gz

echo "Plot LD Decay on 1% data"

echo $OUTPUT.10kb.1%.ld.gz | \
        Rscript --vanilla --slave \
        fit_LDdecay.R \
        --ld r2 \
        --fit_bin_size 100 \
        --recomb_rate 2.97 \
        --plot_size 1.5,4.5 \
        -o "$OUTPUT"-1perc.lddecay-10kb.png \
        --max_kb_dist=10 \
        --fit_level 10 \
        --plot_data

echo "Deleting the full ld file"
rm $OUTPUT.10kb.ld

# estimating linkage. Need to supply ngsLD with number of individuals, number of sites, GLs.
# also supplying SNP locations, so it doesn't waste time to calc LD for monomorphics.
# using max distance of 10kb for calculation.
#using outH to output with headers.

# getting end time to calculate time elapsed
end=`date +%s`
elapsed=`expr $end - $begin`
echo Time taken: $elapsed
