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
0
0
0
//Number of migration matrices : 0 implies no migration between demes
0
//historical event: time, source, sink, migrants, new deme size, new growth rate, migration matrix
5 historical event
T1$ 1 1 0 N1START$ 0 0 absoluteResize
T0$ 0 0 0 N0START$ 0 0 absoluteResize
T1OUT$ 1 2 1 1 0 0
T0OUT$ 0 2 1 1 0 0
T2$ 2 2 0 NANC$ 0 0 absoluteResize
//Number of independent loci [chromosome]
1 0
//Per chromosome: Number of contiguous linkage Block: a block is a set of contiguous loci
1
//per Block:data type, number of loci, per generation recombination and mutation rates and optional parameters
FREQ 1 0 2.9e-9 OUTEXP
