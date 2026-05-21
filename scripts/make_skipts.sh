#!/bin/sh

#get diff suites list for AT-F1 skip.ts
#run this shell at $ATAF_TEST_RESULT/work/log

cat report.log | 
awk 'BEGIN {FS ="|";} { if( $2 == "FAIL" || $2 == "FATAL" || $2 == "ERROR" ) { print $7; } }' | 
uniq |
awk -F/TC/ '{print $2}' > skip.ts
