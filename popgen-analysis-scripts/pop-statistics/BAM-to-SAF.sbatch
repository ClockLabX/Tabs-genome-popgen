#!/bin/bash
# this version of SAF estimation will take inbreeding coefficients into account.
# can affect downstream estimates (SFS, Fst, theta, TajimaD, etc. Anything SFS-based).
# requires inbreeding coefficients, minor allele frq, and major/minor calling (in addition to usual doSAF needs).

#options for sbatch
#SBATCH --nodes=1
#SBATCH --job-name=saf
#SBATCH --ntasks=1 # Number of tasks (typically one)
#SBATCH --cpus-per-task=8 # number of CPUs for multithreaded programs ($SLURM_CPUS_PER_TASK)
#SBATCH --mem=16G # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --time=1-0 # 0 days, 2 hours
#SBATCH --partition=bigmemht
#SBATCH --output=slurmout/%x-%j.out # File to which STDOUT will be written, with job name and Job ID
#SBATCH --error=slurmout/%x-%j.err # File to which STDERR will be written, with job name and Job ID

# for calculating the amount of time the job takes
begin=`date +%s`
echo $HOSTNAME

# summary
cat << EOF
Purpose of this script:
Calculate site allele frquences (SAF) in ANGSD.
As inputs:
        -reference genome
        -text file containing paths to each BAM
        -text file containing inbreeding values per sample to use as priors from PCAngsd, in same order as BAM file list.
        -optionally, text file containing all contigs/regions to estimate SAF from.
-Kyle Lewald
EOF

# checking for and setting up variables
if (($#==0)); then
        echo "Usage: script.sh ref output_prefix bamfilelist '-rf region_file'(optional) inbreeding.txt" >&2
        exit 2
fi

ref=$1
prefix=$2
bamlist=$3
region=$4
inbreed=$5
# loading modules/programs
angsd="/home/kmlewald/programs/angsd933/angsd"

# running commands
echo "Calculating SAF:" $(date)
$angsd -P $SLURM_CPUS_PER_TASK \
        -minQ 20 \
        -minmapQ 20 \
        -uniqueOnly 1 \
        -only_proper_pairs 1 \
        -remove_bads 1 \
        -bam $bamlist \
        -doSaf 2 \
        -indF $inbreed \
        -doMaf 1 \
        -domajorminor 1 \
        -anc $ref \
        -GL 1 \
        -out $prefix $region
echo "done:" $(date)
#will output a .saf.gz and .saf.idx files for the SAF.
#will output a .maf.gz file, which is needed to estimate inbreeding during SAF estimation.
#major/minor needed to properly "orient" the .maf output.

# getting end time to calculate time elapsed
end=`date +%s`
elapsed=`expr $end - $begin`
echo Time taken: $elapsed

#getting runtime stats on job
/share/apps/bin/jobinfo $SLURM_JOB_ID
