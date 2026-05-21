#!/bin/sh

if [ $# != 1 ]; then
    echo "usage: getEndLogOffset.sh LogFileSize"
    exit
fi

dumpla ${ALTIBASE_HOME}/logs/loganchor0 | grep "End LSN"  | sed 's/End LSN//g' | sed 's/\[//g' | sed 's/\]//g' | sed 's/,/ /g' | awk '{print $1 " " $2}' > log.txt

fileID=`cat log.txt | awk '{print $1}'`
offset=`cat log.txt | awk '{print $2}'`
logsize=$1

totalsize=`expr $logsize \* $fileID + $offset`

echo $totalsize
