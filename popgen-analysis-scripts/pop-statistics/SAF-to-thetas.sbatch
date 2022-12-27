#!/bin/bash


#options for sbatch
#SBATCH --nodes=1
#SBATCH --job-name=saf-to-theta
#SBATCH --ntasks=1 # Number of tasks (typically one)
#SBATCH --cpus-per-task=16 # number of CPUs for multithreaded programs ($SLURM_CPUS_PER_TASK)
#SBATCH --mem=64G # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --time=14-0 # 0 days, 2 hours
#SBATCH --partition=bigmemht
#SBATCH --output=slurmout/%x-%j.out # File to which STDOUT will be written, with job name and Job ID
#SBATCH --error=slurmout/%x-%j.err # File to which STDERR will be written, with job name and Job ID
#SBATCH --mail-type=END # Type of email notification- BEGIN,END,FAIL,ALL
#SBATCH --mail-user=kmlewald@ucdavis.edu # Email to which notifications will be sent


# for calculating the amount of time the job takes
begin=`date +%s`
echo $HOSTNAME

# summary
cat << EOF
Purpose of this script:
Take a SAF file for a population, and create a 1D-SFS, and estimate theta/Tajima in windows.
Inputs:
        saf file prefix name
        saf file directory
        output directories for SFS and thetas.

-Kyle Lewald
EOF

#warn if slurmout directory doesn't exist
if [[ ! -d slurmout ]]
then
        echo "error: slurmout directory does not exist"
        exit 1
fi

# checking for and setting up variables
if (($#!=4)); then
        echo "Usage: script.sh saf_file_prefix saf_directory sfs_output_directory theta_output_directory" >&2
        exit 2
fi

prefix=$1
saf=$2
sfs=$3
theta=$4

# running commands
echo "running realSFS to estimate folded 1D-SFS"
~/programs/angsd933/misc/realSFS $saf/$prefix.saf.idx \
       -P $SLURM_CPUS_PER_TASK \
       -fold 1 \
       -nSites 100000000 \
       -maxIter 400 > $sfs/$prefix.sfs

echo "merge multi-line SFS into global SFS by summing"
awk 'BEGIN {OFMT="%f"} {for (i=1; i<=NF; i++) total[i] += $i} END {for (i=1; i<=NF; i++) print total[i]}' $sfs/$prefix.sfs| paste -s -d ' ' > $sfs/$prefix.global.sfs

echo "calculating thetas per site"
~/programs/angsd933/misc/realSFS saf2theta $saf/$prefix.saf.idx \
        -P $SLURM_CPUS_PER_TASK \
        -sfs $sfs/$prefix.global.sfs \
        -outname $theta/$prefix

echo "calc theta stat block windows"
~/programs/angsd933/misc/thetaStat do_stat $theta/$prefix.thetas.idx \
        -win 20000 \
        -step 20000 \
        -outnames $theta/"$prefix"-win20000

~/programs/angsd933/misc/thetaStat do_stat $theta/$prefix.thetas.idx  \
        -win 20000 \
        -step 5000 \
        -outnames $theta/"$prefix"-win20000-step5000

echo "done"

# getting end time to calculate time elapsed
end=`date +%s`
elapsed=`expr $end - $begin`
echo Time taken: $elapsed
