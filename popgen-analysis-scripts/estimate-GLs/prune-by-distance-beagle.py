# Code to prune input beagle file by position, by a set "distance".
# If the next SNP is on a different chromosome, it will be printed.
# Outputs in beagle format.
# input/output data format
    # chromo_position other_fields(will be ignored, but printed)

# libraries
import sys
import getopt

# parse options
arglist = sys.argv[1:] #skip element 0, which is script name.
if len(arglist)==0:
    print("script.py -i <input beagle txt, or '-' for STDIN> -d <distance>")
    sys.exit()
try:
    opts, args = getopt.getopt(arglist, "i:d:")
   #opts is list of option,value pairs
   #args is list of just the values.
except getopt.GetoptError: #print error if -i or -d not specified
    print("script.py -i <input beagle txt, or '-' for STDIN> -d <distance>")
    sys.exit(2)
for opt,arg in opts:
    if opt == ("-i"):
        if arg == "-":
            infile = sys.stdin
        else:
           infile = open(arg,"r")
    elif opt == ("-d"):
        distance = int(arg)

# print header line
header = infile.readline()
print(header.rstrip())

# get and print the first line of data
old_line = infile.readline()
old_line = old_line.rstrip()
old_marker = old_line.split()[0:1]
old_chrom, old_pos =old_marker[0].split("_")
old_pos = int(old_pos)
print(old_line)

# compare next line to previous line. print out if on diff chr or far apart
for line in infile:
    current_line = line.rstrip()
    current_marker = current_line.split()[0:1]
    current_chrom, current_pos = current_marker[0].split("_")
    current_pos = int(current_pos)
    if current_chrom != old_chrom:
        print(current_line)
        old_chrom = current_chrom
        old_pos = current_pos
    elif current_pos - old_pos > distance:
        print(current_line)
        old_chrom = current_chrom
        old_pos = current_pos
    else:
        continue
infile.close()
