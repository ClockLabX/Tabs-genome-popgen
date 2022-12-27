#!/bin/bash

#options for sbatch
#SBATCH --nodes=1
#SBATCH --job-name=fst
#SBATCH --ntasks=1 # Number of tasks (typically one)
#SBATCH --cpus-per-task=16 # number of CPUs for multithreaded programs ($SLURM_CPUS_PER_TASK)
#SBATCH --mem=64G # Memory pool for all cores (see also --mem-per-cpu)
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
Take input SAF files of two populations, and output the 2d-SFS and Fst values.
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
        echo "Usage: script.sh sample1_saf_prefix sample2_saf_prefix saf_input_dir 2d-SFS-output-dir fst-output_dir" >&2
        exit 2
fi

pop1=$1
pop2=$2
saf=$3
sfs=$4
fst=$5

# load module
realSFS="~/programs/angsd933/misc/realSFS"

# running commands
echo "running realSFS on 2 pops:" $pop1 $pop2 $(date)
$realSFS $saf/$pop1.saf.idx $saf/$pop2.saf.idx \
        -P $SLURM_CPUS_PER_TASK \
        -fold 1 \
        -nSites 100000000 \
        -maxIter 800 \
        -tole 1e-10 > $sfs/"$pop1"-"$pop2".sfs

echo "merge multi-line SFS into global SFS by summing"
awk 'BEGIN {OFMT="%f"} {for (i=1; i<=NF; i++) total[i] += $i} END {for (i=1; i<=NF; i++) print total[i]}' $sfs/"$pop1"-"$pop2".sfs| \
        paste -s -d ' ' > $sfs/"$pop1"-"$pop2".global.sfs

echo "indexing/generating fst calculations:" $(date)
$realSFS fst index $saf/$pop1.saf.idx $saf/$pop2.saf.idx \
        -sfs $sfs/"$pop1"-"$pop2".global.sfs \
        -fstout $fst/"$pop1"-"$pop2"

echo "save global Fst estimate:" $(date)
echo 'pop1' 'pop2' 'fst_unweighted' 'fst_weighted' > $fst/"$pop1"-"$pop2".global.fst
echo $pop1 $pop2 $($realSFS fst stats $fst/"$pop1"-"$pop2".fst.idx) >> $fst/"$pop1"-"$pop2".global.fst

echo "done"
# getting end time to calculate time elapsed
end=`date +%s`
elapsed=`expr $end - $begin`
echo Time taken: $elapsed
