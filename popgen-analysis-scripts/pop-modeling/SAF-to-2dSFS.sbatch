#!/bin/bash

#options for sbatch
#SBATCH --nodes=1
#SBATCH --job-name=2dsfs
#SBATCH --ntasks=1 # Number of tasks (typically one)
#SBATCH --cpus-per-task=32 # number of CPUs for multithreaded programs ($SLURM_CPUS_PER_TASK)
#SBATCH --mem=128G # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --time=14-0 # 0 days, 2 hours
#SBATCH --partition=bigmemht
#SBATCH --output=slurmout/%x-%j.out # File to which STDOUT will be written, with job name and Job ID
#SBATCH --error=slurmout/%x-%j.err # File to which STDERR will be written, with job name and Job ID

# for calculating the amount of time the job takes
begin=`date +%s`
echo $HOSTNAME

# summary
cat << EOF
Purpose of this script:
Take SAF files of two populations from ANGSD, and calculate 2D-SFS between the two.
Will calculate 2D-SFS in 50Mb intervals, and sum all counts together at the end.
As inputs:
        -$pop1.saf.idx and $pop2.saf.idx, saved in a $saf directory.
        -angsd-indexed site file to specify which intervals to use in SFS calculation. Used to avoid genic regions.
-Kyle Lewald
EOF

#warn if slurmout directory doesn't exist
if [[ ! -d slurmout ]]
then
	echo "error: slurmout directory does not exist"
	exit 1
fi

# checking for and setting up variables
if (($#!=5)); then
        echo "Usage: script.sh sample1_saf_prefix sample2_saf_prefix saf_dir sfs_output_dir sites.txt(angsd indexed)" >&2
        exit 2
fi

pop1=$1
pop2=$2
saf=$3
sfs=$4
sites=$5

# load module
realSFS="/home/kmlewald/programs/angsd933/misc/realSFS"

# running commands
echo "running realSFS on 2 pops:" $pop1 $pop2 $(date)
$realSFS $saf/$pop1.saf.idx $saf/$pop2.saf.idx \
	-P $SLURM_CPUS_PER_TASK \
	-fold 1 \
	-nSites 50000000 \
	-maxIter 400 \
	-sites $sites \
	-tole 1e-10 > $sfs/"$pop1"-"$pop2".sfs

echo "merge multi-line SFS into global SFS by summing"
awk 'BEGIN {OFMT="%f"} {for (i=1; i<=NF; i++) total[i] += $i} END {for (i=1; i<=NF; i++) print total[i]}' $sfs/"$pop1"-"$pop2".sfs| \
	paste -s -d ' ' > $sfs/"$pop1"-"$pop2".global.sfs

echo "done"
# getting end time to calculate time elapsed
end=`date +%s`
elapsed=`expr $end - $begin`
echo Time taken: $elapsed
