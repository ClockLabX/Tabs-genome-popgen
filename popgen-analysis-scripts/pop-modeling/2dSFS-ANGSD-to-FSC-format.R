# script to convert angsd-style single-line folded 2D-SFS into fsc26-style multi-line 2D-SFS.
# fastsimcoal refers to populations by number, from 0,1,2...So decide ahead of time which pops are which numbers, and supply here as inputs.
# The "first pop" in ANGSD's SFS wil be the pop that was supplied to the realSFS program first.
# the "second pop" in ANGSD's SFS will be the pop that was supplied to the realSFS program second.
# Also need to supply number of individuals in each pop, so that the single-line SFS is properly converted to matrix format.
####INPUTS####

args <- commandArgs(trailingOnly = TRUE)

if(length(args) != 6){
  print("usage: Rscript script.R angsd-SFS-file output-prefix 1stpop's_fsc_number 2ndpop's_fsc_number 1stpop_size 2ndpop_size")
  quit()
}

raw <- args[1]
file.prefix <- args[2]

#fsc's numerical name of 1st and 2nd pop
pop1st <- as.integer(args[3])
pop2nd <- as.integer(args[4])

# number of individuals in 1st and 2nd pop
pop1st.N <- as.integer(args[5])
pop2nd.N <- as.integer(args[6])

####PROCESSING####

# read in SFS as a matrix, then as a data frame.
x <- matrix(read.table(raw), nrow = pop1st.N*2+1, byrow = TRUE)

#decide which pop will be rows (m) and columns (n). Flip matrix if needed, then name rows/columns.
if(pop1st < pop2nd){
  x <- t(x)
}

#set values for which pop is m or n.
m <- max(pop1st, pop2nd)
n <- min(pop1st, pop2nd)

##add 2 rows on top. top one will be blank. 2nd one will be "NA d0_0 D0_1 ..."
col.prefix <- paste0("d", n,"_")
col.names <- c(paste0(col.prefix, seq(0,ncol(x)-1)))
x <- rbind(rep("",ncol(x)), col.names, x)

##add 1 column to left. "1 observation NA d1_0 d1_1 ..."
row.prefix <- paste0("d", m, "_")
row.names <- c("1 observation", "", paste0(row.prefix,seq(0,nrow(x)-3)))
x <- cbind(row.names, x)

#write out final table
write.table(x, file = paste0(file.prefix,"_jointMAFpop",m,"_",n,".obs"), row.names = FALSE, col.names = FALSE, sep = "\t", na = "")
