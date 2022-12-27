#Goal: convert a GT counts table obtained from PCangsd into a table suitable for treemix.
#inputs:
  #GT counts tables with headers. Headers should be this format: sample1 sample2 sample3 ...
    #GT values can be -9, 0, 1, or 2 (missing, hom1, het, hom2)
  #location .tsv file. 1st column sample name, 2nd column pop name to group by. No headers.
  #output file name/path
  #also supply a line block size. How many lines should it read in per loop? larger value = more memory
    #but faster run time. Try 10000 to start with.
#ouputs: a treemix formatted file, with sites that have NO data within any 1 pop removed.

####parameters####
args = commandArgs(trailingOnly=TRUE)
if(length(args)!=4){
  stop("Supply 4 inputs; location file, genotype file, outfile name, and line block size")
}
locfile <- args[1]
gtcounts <- args[2]
outfile <- args[3]
chunksize <- args[4]

####libraries####
#library(tidyverse)
library(dplyr)
library(knitr)
library(tidyr)
library(readr)

####functions####
gtcounts_to_treemix <- function(raw, location) {
  #takes a genotype count table and table of sample-population.
  #
  require(dplyr)
  table <- as.data.frame(raw)%>%
    mutate(POS = as.numeric(rownames(raw)))%>%#Important fix! Forces the order of rows to stay as it came in
    gather(key = sample, value = GT, -POS)%>%
    left_join(location, by = "sample")%>% #add location site labels
    group_by(POS, site, GT)%>% #
    summarize(count = n())%>% #count the number of 0/0, 0/1, and 1/1. These indicate genotype
    ungroup()%>%
    spread(GT,count, fill = 0)
  
  #add in missing genotype columns, with empty "0" values. In case NO samples are in a genotype category.
  ifelse(!("0" %in% colnames(table)), table$`0` <- 0, NA)
  ifelse(!("1" %in% colnames(table)), table$`1` <- 0, NA)
  ifelse(!("2" %in% colnames(table)), table$`2` <- 0, NA)
  
  #deletes the "missing data" column if present.
  if("-9" %in% colnames(table)){table <- select(table, -`-9`)}
  
  table <- table%>%
    mutate(ref = 2*`0` + `1`,
           alt = 2*`2` + `1`)%>%
    #treemix2$ref <- 2*treemix2$`0/0` + treemix2$`0/1` #calcs the number of reference alleles present
    #treemix2$alt <- 2*treemix2$`1/1` + treemix2$`0/1` #calcs the number of alt alleles present
    mutate(ref_alt = paste(ref, ",", alt, sep = ""))%>% #combines ref and alt counts into 1 column
    select(POS, site, ref_alt)%>% #get rid of intermediate columns
    group_by(POS)%>%
    spread(site, ref_alt)%>% #spreads data across sample site
    ungroup()%>%
    arrange(POS)%>% ## CRITICAL: to keep table in same order as it started!
    select(-POS) #remove position info
  
  return(table)
}

line_to_df <- function(line, header){
  #takes a header line and the first line of the raw genotype file
  #outputs a dataframe of just that line, to then be added to in a for loop.
  x <- (strsplit(line, split = "\t"))[[1]]
  data <- as.data.frame(t(x))
  colnames(data) <- header
  return(data)
}

####read in name and population index####
location <- read.delim(locfile, header = F, stringsAsFactors = F)
colnames(location) <- c("sample", "site")

####read in genotypes header line####
con <- file(gtcounts, 'r')
header <- strsplit(readLines(con, n = 1), split= "\t")[[1]]

####create outfile, with first line####
line <- readLines(con, n = 1)
data <- line_to_df(line, header)
treemix <- gtcounts_to_treemix(data, location)
#remove the row if it contains missing data for any pop (0,0)
treemix <- filter_all(treemix, all_vars(.!="0,0"))
write_delim(treemix, file = outfile)

#read in rest of gtcounts, chunk by chunk, and output treemix formatted version. All chunks get appended together.
chunk=0
while(TRUE) {
  line <- readLines(con, n = chunksize)
  #exit once there are no lines left in file
  if(length(line) == 0){
    break
  }
  chunk=chunk+1
  #convert to a data frame
  line <- gsub("\t", " ", line)
  data <- as.data.frame(line)%>%
    separate(line, into = header, sep = " ")
  #convert to treemix-formatted table
  treemix <- gtcounts_to_treemix(data, location)
  #remove rows containing missing data for any pop (0,0)
  treemix <- filter_all(treemix, all_vars(.!="0,0"))
  #write out file, appending to the end.
  write_delim(treemix, file = outfile, append = TRUE, col_names = FALSE)
  message("Finished chunk ", chunk)
}
close(con)

R.utils::gzip(outfile, overwrite=TRUE)
