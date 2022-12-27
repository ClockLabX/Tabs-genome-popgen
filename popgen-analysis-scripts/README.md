# README.md

Scripts used to process and analyze population sequencing data of *Tuta absoluta* from Latin America.

## estimate-GLs

Raw reads were trimmed and checked for quality using `read-trimming-fastqc.sbatch` before being aligned to the genome assembly with `align-reads.sbatch`.
Next, SNPs and genotype likelihoods (GLs) were estimated using `genotype-likelihood-SNPs.sbatch`. The resulting "beagle" GL file was pruned using the `prune-by-distance-beagle.py` script.

## pop-structure

GLs were supplied to the `PCangsd-PCA.sbatch` script to conduct the PCA. GLs were supplied to `NGSadmix-pick-k.sbatch` to perform admixture analysis at varying cluster numbers (k). GLs were supplied to `PCangsd-genotype.sbatch` to estimate inbreeding values for each individual (used as priors in later site allele frequency estimations) and to output genotypes (used for Treemix analysis).

## pop-statistics

Aligned BAM files were converted into site allele frequency (SAF) files for each population in ANGSD using `BAM-to-SAF.sbatch`. This script requires an inbreeding file output from PCAngsd to use as priors when estimating the SAF. From here, SAF files were used to estimate nucleotide diversity (`SAF-to-thetas.sbatch`), Fst (`SAF-to-Fst.sbatch`), or the population branch statistic (`SAF-to-PBS.sbatch`). AFter the fact, in order to more easily compare allele frequencies on SNPs between populations, the `BAM-to-SAF-reference-oriented.sbatch` script was used to output minor allele frequencies, where the "major" allele was required to be the reference allele (in previous scripts the higher frequency allele was set as the "major").

## pop-modeling

The `SAF-to-2dSFS.sbatch` script converts the SAF files originally created under the "pop-statistics" directory to output a 2D-site frequency spectrum (2D-SFS) file per cluster combination (North, Andes, Central). It takes as inputs an indexed "site" file to only analyze non-genic regions. The `2dSFS-ANGSD-to-FSC-format.R` script then converts the 2d-SFS files into the fastsimcoal input format.
The ".est" and ".tpl" files specify the parameters and models for the three scenarios tested (M1, M2, M3). For each scenario, `FSC-estimate-parameters.sbatch` was used to calculate the maximum likelihood values of each parameter. The `FSC-parametric-bootstrapping.sbatch` Takes as input ".par" files that specify a scenario with maximum likelihood values, and simulates a 2D-SFS 100 times from a scenario. It then re-estimates best parameter values from each simulation 100 times, to provide a parametric bootstrap distribution. To do this, it uses the helper scripts `_FSC-estimate-parameters.sbatch` and `_bestrun.sh`.

## ld-estimation

These analyses were used to perform post-hoc tests on population models from fastsimcoal.

To estimate linkage disequilibrium from sequencing data, `pop-data-to-GLs.sbatch` was used to estimate GLs within each major cluster (North, Andes, Central) within the same genomic intervals used to estimate the SFS used for population modeling (at least 1kb away from gene-coding regions). This script also output a 10% subset of the GLs to reduce computational time for the LD estimation step. `pop-GLs-to-LD.sbatch` was then used to estimate LD between SNPs to a maximum of 10kb on the 10% subsetted data, as well as output LD decay plots and statistics using the helper script `fit_LDdecay.R` using a 1% subset of LD values.

The `sim-data-to-LD.sbatch` script takes a ".par" file from fastsimcoal which specifies a population model and parameters, and simulates SNPs under this model on 1Mb of DNA 100 times. It converts these fastsimcoal genotype files into a format readable by ngsLD with the help of `_select-columns.sh`. It then uses `ngsLD-genotype.sbatch` to calculate LD and estimate LD decay rates for all three populations' simulated genotypes.

## treemix
`pcangsd-to-treemix.R` was used to convert PCangsd genotype outputs into a treemix input format, with allele counts for each sampling site. The `treemix-bootstrap.sbatch` script takes the treemix-formatted genotype file, as well as a number of migration edges allowed, root population, and SNP blocksize, to create 100 bootstrapped maximum likelihood trees.
