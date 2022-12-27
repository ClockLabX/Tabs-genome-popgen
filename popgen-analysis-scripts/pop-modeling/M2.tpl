//Number of population samples (demes)
3
//Population effective sizes (number of genes)
N0END$
N1END$
N2END$
//Samples sizes and samples age and samples inbreeding
40
20
40
//Growth rates  : growth rate backwards in time
R0$
R1$
R2$
//Number of migration matrices : 0 implies no migration between demes
0
//historical event: time, source, sink, migrants, new deme size, new growth rate, migration matrix
3 historical event
T0$ 0 2 1 1 keep 0
T1$ 1 2 1 1 keep 0
T2$ 2 2 0 1 0 0
//Number of independent loci [chromosome]
1 0
//Per chromosome: Number of contiguous linkage Block: a block is a set of contiguous loci
1
//per Block:data type, number of loci, per generation recombination and mutation rates and optional parameters
FREQ 1 0 2.9e-9 OUTEXP
