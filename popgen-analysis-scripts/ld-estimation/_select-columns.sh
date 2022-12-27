#!/bin/bash

# summary
cat << EOF
Purpose: filter a space-delimited table by columns, by searching for a keyterm.
NOTE: column order is NOT preserved, due to the way i recall columns from an array.

-Kyle Lewald
EOF
# checking for and setting up variables
if (($#!=2)); then
        echo -e "Usage: script.sh <header-searchterm> <input-file>\nNote that column order is NOT preserved in output" >&2
        exit 2
fi



awk -v TERM=$1 '
    BEGIN {OFS="\t"}
    NR==1 {
        for(i=1;i<=NF;i++){
            if($i~TERM){
                ARRAY[$i]=i
            }
        }
    }
    NR>1 {
        for(j in ARRAY){
            printf $ARRAY[j]" "
        }
        print ""
    }
' $2
