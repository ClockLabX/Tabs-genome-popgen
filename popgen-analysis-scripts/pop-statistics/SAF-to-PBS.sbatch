#!/bin/bash
#options for sbatch
#SBATCH --nodes=1
#SBATCH --job-name=PBS
#SBATCH --ntasks=1 # Number of tasks (typically one)
#SBATCH --cpus-per-task=1 # number of CPUs for multithreaded programs ($SLURM_CPUS_PER_TASK)
#SBATCH --mem=8G # Memory pool for all cores (see also --mem-per-cpu)
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
Calculate PBS between three populations, from the 2D-SFS files of those three pops.
Script assumes that the input 2d-SFS files were named:
        "$pop1"-"$pop2".global.sfs 
        "$pop1"-"$pop3".global.sfs 
        "$pop2"-"$pop3".global.sfs
        (replace $pop# with your used population prefixes)
-Kyle Lewald
EOF

#check if slurmout directory exists
if [[ ! -d slurmout ]]
then
    echo "Missing a slurmout directory"
    exit 1
fi

# checking for and setting up variables
if (($#!=6)); then
        echo "Usage: script.sh pop1-prefix pop2-prefix pop3-prefix saf_input_dir sfs__input_dir pbs__output_dir" >&2
        exit 2
fi

pop1=$1
pop2=$2
pop3=$3
saf=$4
sfs=$5
pbs=$6

# run programs
echo "Index 3 pops for Fst/PBS: " $(date)
~/programs/angsd933/misc/realSFS fst index $saf/$pop1.saf.idx $saf/$pop2.saf.idx $saf/$pop3.saf.idx \
        -sfs $sfs/"$pop1"-"$pop2".global.sfs \
        -sfs $sfs/"$pop1"-"$pop3".global.sfs \
        -sfs $sfs/"$pop2"-"$pop3".global.sfs \
        -fstout $pbs/"$pop1"-"$pop2"-"$pop3"

echo "Global estimate of Fst and PBS: " $(date)
~/programs/angsd933/misc/realSFS fst stats $pbs/"$pop1"-"$pop2"-"$pop3".fst.idx

echo "Sliding window of Fst and PBS: " $(date)
~/programs/angsd933/misc/realSFS fst stats2 $pbs/"$pop1"-"$pop2"-"$pop3".fst.idx \
        -win 5000 -step 500 > $pbs/"$pop1"-"$pop2"-"$pop3".win5kb.step500bp.pbs

echo "Done: " $(date)

# getting end time to calculate time elapsed
end=`date +%s`
elapsed=`expr $end - $begin`
echo Time taken: $elapsed
