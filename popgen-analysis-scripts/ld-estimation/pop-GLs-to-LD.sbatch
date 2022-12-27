#!/bin/bash

#options for sbatch
#SBATCH --nodes=1
#SBATCH --job-name=ngsLD
#SBATCH --ntasks=1 # Number of tasks (typically one)
#SBATCH --cpus-per-task=12 # number of CPUs for multithreaded programs (FARM CPUs can handle 2 threads/core simultaneously)
#SBATCH --mem=24G # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --time=1-0:00 # 0 days, 2 hours
#SBATCH --partition=bigmemht
#SBATCH --output=slurmout/%x-%j.out # File to which STDOUT will be written, with job name and Job ID
#SBATCH --error=slurmout/%x-%j.err # File to which STDERR will be written, with job name and Job ID

# for calculating the amount of time the job takes
begin=`date +%s`
echo $HOSTNAME

# summary
cat << EOF
Purpose of this script:
Calculate LD between SNPs pairwise from a beagle.gz genotype likelihood file
Only uses 1% of pairwise LD values to generate decay estimates.

Inputs:
        file prefix of the beagle.gz
        input directory where the beagle file is located
        desired output directory
Outputs:
        pairwise LD values for SNPs within 10kb distance.
        LD decay estimates (see log files)
        image of decay rate.

-Kyle Lewald
EOF

# checking for and setting up variables
if (($#!=3)); then
        echo "Usage: script.sh input-beagle-prefix GL_directory Output_directory" >&2
        exit 2
fi

BASENAME=$1
INDIR=$2
OUTDIR=$3


#load modules
module load R/3.6

#get number of SNPs
SNPCOUNT=$(expr $(zcat $INDIR/$BASENAME.beagle.gz | wc -l) - 1)
echo "Number of SNPs used: " $SNPCOUNT

#get number of individuals
NIND=$(( ($(zcat $INDIR/$BASENAME.beagle.gz | \
        head | \
        awk 'NR==1 {print NF}' ) - 3)/3))
echo "Number of individuals: " $NIND

echo "Generating positions file"
zcat $INDIR/$BASENAME.beagle.gz | cut -f1 | awk 'NR==1 {print("chr\tpos")} NR>1 {gsub("_","\t"); print}'> $OUTDIR/$BASENAME.pos

POSITIONS=$OUTDIR/$BASENAME.pos

echo "Running ngsLD to estimate LD"
ngsLD --n_threads $SLURM_CPUS_PER_TASK \
    --geno $INDIR/$BASENAME.beagle.gz \
    --probs \
    --n_ind $NIND \
    --posH $POSITIONS \
    --n_sites $SNPCOUNT \
    --max_kb_dist 10 \
    --outH $OUTDIR/$BASENAME.10kb.ld

echo "Making 1% subsampled file for LD decay"
awk 'rand()<0.01 {print}' $OUTDIR/$BASENAME.10kb.ld | pigz -p $SLURM_CPUS_PER_TASK -c > $OUTDIR/$BASENAME.10kb.1%.ld.gz

echo "Plot LD Decay"
echo $OUTDIR/$BASENAME.10kb.1%.ld.gz | \
        Rscript --vanilla \
        --slave \
        _fit_LDdecay.R \
        --ld r2 \
        --fit_bin_size 100 \
        --recomb_rate 2.97 \
        --fit_boot 100 \
        --plot_size 1.5,4.5 \
        -o $OUTDIR/${BASENAME}-1perc.lddecay-10kb.png \
        --max_kb_dist=10 \
        --fit_level 10 \
        --plot_data

echo "Gzipping ld file"
pigz -p $SLURM_CPUS_PER_TASK $OUTDIR/$BASENAME.10kb.ld

# estimating linkage. Need to supply ngsLD with number of individuals, number of sites, GLs.
# also supplying SNP locations, so it doesn't waste time to calc LD for monomorphics.
# using max distance of 10kb for calculation.
#using outH to output with headers.

# getting end time to calculate time elapsed
end=`date +%s`
elapsed=`expr $end - $begin`
echo Time taken: $elapsed
