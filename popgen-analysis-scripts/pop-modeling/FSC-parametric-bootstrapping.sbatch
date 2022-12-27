#!/bin/bash

#options for sbatch
#options for sbatch/slurm
#SBATCH --job-name=fsc2708.2-simulate
#SBATCH --cpus-per-task=3 # number of CPUs for multithreaded programs (variable is $SLURM_CPUS_PER_TASK)
#SBATCH --mem=3G # Memory pool for all cores combined. G=gigabytes. (see also --mem-per-cpu)
#SBATCH --time=14-0 # format: 3-0 means 3 days, 0 hours. 3:10:20 means 3 hours, 10 minutes, 20 seconds.
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
Use fastsimcoal to simulate 100 2D-SFS from model with the best estimated paraemeters.
Then, re-estimate parameters from each simulated 2D-SFS to build confidence intervals.

Script pre-reqs:
    Requires the "_FSC-estimate-parameters.sbatch" script and "_bestrun.sh" script to be
    able to re-estimate parameters from each newly simulated 2d-SFS.

As inputs,
    -".par" file containing model + parameter estimates,with output type set to "DNA" (not "FREQ").
	Also need to set how many loci to simulate in par file.

This script MUST be run in the same directory as where the .par file is.
Output:
    100 "rep" folders, inside containing the BEST run's .bestlhoods.
    The output SFS files will have same prefix as the ".par".
-Kyle Lewald
EOF

# checking for and setting up variables
if (($#!=1)); then
        echo "Usage: script.sh path/to/prefix.par" >&2
        exit 2
fi

#input parameters
file=$1
prefix=$(basename $file .par)
dir=$(dirname $file)

#script paths. check they exist too.
BESTRUN=_FSC-bestrun.sh
if [ ! -x "$BESTRUN" ]; then
    echo "$BESTRUN does not exist or is not executable."
fi
FSCCI=_FSC-estimate-parameters.sbatch
if [ ! -x "$FSCCI" ]; then
   echo "$FSCCI does not exist or is not executable."
fi

# running commands
echo "Moving to directory/model:" $dir
cd $dir

echo "Copying .par to $dir and simulating a 2D-SFS"
mkdir rep${SLURM_ARRAY_TASK_ID}
cp $prefix.par rep${SLURM_ARRAY_TASK_ID}
cd rep${SLURM_ARRAY_TASK_ID}

script -q -c "fsc2708.2 \
		  --ifile "$prefix".par \
		  --dnatosnp 0 \
		  --noarloutput \
		  --inf \
          --msfs \
          --foldedSFS \
          --numsims 1 \
          --numBatches $SLURM_CPUS_PER_TASK \
          --cores $SLURM_CPUS_PER_TASK \
          --quiet"

echo "removing par copy and typescript"
rm $prefix.par
#remove the default "typescript" log output by the "script" command, as slurm will already have caught everything.
rm typescript

#### Now starting the parameter estimation stage.

#copy the tpl and est files into the rep folder
echo "Copying est and tpl files from $dir into $prefix"
cp ../$prefix.tpl $prefix
cp ../$prefix.est $prefix
cd $prefix
mkdir slurmout

echo "running sbatch array command to re-estimate parameters"
#using --wait to prevent "sbatch" from exiting until all arrays are complete.
sbatch --wait $FSCCI $prefix.tpl

echo "Grab best run into a separate folder, and copy *bestlhoods into rep${SLURM_ARRAY_TASK_ID}"
$BESTRUN $prefix
cp bestrun/*bestlhoods ..

#remove the runs folders?
#rm -r run*/

echo "Done"

# getting end time to calculate time elapsed
end=`date +%s`
elapsed=`expr $end - $begin`
echo Time taken: $elapsed
