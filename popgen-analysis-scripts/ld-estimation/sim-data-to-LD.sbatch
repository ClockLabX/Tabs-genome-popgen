#!/bin/bash

# summary
cat << EOF
Purpose of this script:
Helper script to use fastsimcoal to simulate genotypes from a par file 100 times,
then run ngsLD to estimate linkage and LD decay.

Requires the scripts "_select-columns.sh" and "_ngsLD-genotype.sbatch".
Also needs the "_fit_LDdecay.R" script from ngsLD.

As input, takes the .par file from fastsimcoal, containing the model and best parameter estimates.
-Kyle Lewald
EOF

# checking for and setting up variables
if (($#!=3)); then
        echo "Usage: script.sh Par-file-prefix" >&2
        exit 2
fi

#set input parameters
PREFIX=$1

echo "simulating SNPs on 1Mb of DNA under the model 100 times"

srun -J $PREFIX.sim -p bigmemht -t 1-0 \
	fsc2708.2 --ifile $PREFIX.par --numsims 100 --noarloutput --indgenot --genotypic -c 1 -k 1000000 --quiet
#output will be in a folder named $PREFIX

echo "Converting genotype outputs into the ngsLD input format"

#get rid of blank line at end of genotype file
for i in $PREFIX/*gen; do sed '$d' -i $i; done

#selecting each "gen" file, and splitting it by population. Here I have three populations to split by.
#also make a "positions" file that ngsLD needs.
for i in {1..100}
do
	cut -f1,2 $PREFIX/"$PREFIX"_1_$i.gen > $PREFIX/"$PREFIX"_$i.pos
	_select-columns.sh G_1 $PREFIX/"$PREFIX"_1_$i.gen | gzip -c > $PREFIX/"$PREFIX"_pop0_$i.gen.gz
	_select-columns.sh G_2 $PREFIX/"$PREFIX"_1_$i.gen | gzip -c > $PREFIX/"$PREFIX"_pop1_$i.gen.gz
	_select-columns.sh G_3 $PREFIX/"$PREFIX"_1_$i.gen | gzip -c > $PREFIX/"$PREFIX"_pop2_$i.gen.gz
done

#calculate LD and estimate LD decay rates for each pop, using ngsLD and accompanying R script.

for i in {1..100}
do
	sbatch -J pop0_"$i"_1Mb _ngsLD-genotype.sbatch \
	$PREFIX/"$PREFIX"_pop0_$i.gen.gz  \
	$PREFIX/"$PREFIX"_$i.pos \
	$PREFIX/LD-estimates/pop0_$i

	sbatch -J pop1_"$i"_1Mb _ngsLD-genotype.sbatch \
	$PREFIX/"$PREFIX"_pop1_$i.gen.gz  \
	$PREFIX/"$PREFIX"_$i.pos \
	$PREFIX/LD-estimates/pop1_$i

	sbatch -J pop2_"$i"_1Mb _ngsLD-genotype.sbatch \
	$PREFIX/"$PREFIX"_pop2_$i.gen.gz  \
	$PREFIX/"$PREFIX"_$i.pos \
	$PREFIX/LD-estimates/pop2_$i
done
