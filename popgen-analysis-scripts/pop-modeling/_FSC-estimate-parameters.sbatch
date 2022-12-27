#!/bin/bash

#options for sbatch
#options for sbatch/slurm
#SBATCH --job-name=fsc2708.2-fast
#SBATCH --cpus-per-task=6 # number of CPUs for multithreaded programs (variable is $SLURM_CPUS_PER_TASK)
#SBATCH --mem=2G # Memory pool for all cores combined. G=gigabytes. (see also --mem-per-cpu)
#SBATCH --time=3-0:00 # format: 3-0 means 3 days, 0 hours. 3:10:20 means 3 hours, 10 minutes, 20 seconds.
#SBATCH --partition=med #which node are you using?
#SBATCH --output=slurmout/%x-%A-%a.out # File to which STDOUT will be written, with job name and Job ID
#SBATCH --error=slurmout/%x-%A-%a.err # File to which STDERR will be written, with job name and Job ID
#SBATCH --array=0-99 #Use $SLURM_ARRAY_TASK_ID to refer to array index in script

#if slurmout directory doesn't exist, stops script.
if [[ ! -d slurmout ]]
then
    echo "Missing a slurmout directory"
    exit 1
fi

# for calculating the amount of time the job takes
begin=$(date +%s)
echo $HOSTNAME

# summary
cat << EOF
Purpose of this script:
Run fastsimcoal 100 times on a single model, assuming a folded SFS created by angsd and formatted for fsc.
This script MUST be run in the same directory as where the tpl, est, and obs files are.
All output runs will be saved in this same directory, in their own run directory.
tpl, est, and all .obs files MUST use same prefix as their name.
tpl, est, and obs files must all be in the same directory.
-Kyle Lewald
EOF

# checking for and setting up variables
if (($#!=1)); then
        echo "Usage: script.sh path/to/prefix.tpl" >&2
        exit 2
fi

#input parameters
file=$1
prefix=$(basename $file .tpl)
dir=$(dirname $file)

echo "Moving to directory/model:" $dir
echo "Processing prefix:" $prefix
echo "Starting run"

# running commands
cd $dir
mkdir run${SLURM_ARRAY_TASK_ID}

#Have to copy input files into the run directory, since fsc27 doesn't understand filepaths.
cp $prefix.tpl $prefix.est ${prefix}_*.obs run${SLURM_ARRAY_TASK_ID}"/"
cd run${SLURM_ARRAY_TASK_ID}

#wrap fsc run in script, to capture the "tty" output as "stdout".
#this will also capture all stderr into the same output, unfortunately.
script -q -c "fsc2708.2 --tplfile "$prefix".tpl \
	  --estfile "$prefix".est \
  	  --msfs \
  	  --foldedSFS \
  	  --minSFSCount 10 \
  	  --numloops 100 \
  	  --maxlhood \
  	  --numsims 1000000 \
          --numBatches $SLURM_CPUS_PER_TASK \
          --cores $SLURM_CPUS_PER_TASK \
  	  --quiet"

#delete the tpl, est, and obs files, as they are duplicates
rm $prefix.tpl $prefix.est ${prefix}_*.obs
#remove the default "typescript" log output by the "script" command, as slurm will already have caught everything.
rm typescript

echo "Done"
# -msfs minor allele SFS -M parameter estimation -L optimizing cycles -C ignore low SNP count
# -c # threads -q quiet -n number of simulations --msfs use minor allele freq -H add header
# --foldedSFS ensures compatibility with the way ANGSD generates folded SFS.

# getting end time to calculate time elapsed
end=`date +%s`
elapsed=`expr $end - $begin`
echo Time taken: $elapsed
