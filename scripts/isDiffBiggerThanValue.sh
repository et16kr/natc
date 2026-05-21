#!/bin/sh

if [ $# != 3 ]; then
    echo "usage: isDiffBiggerThanValue value1 value2 value3"
    exit
fi

diffValue=`expr $1 - $2`

if [ "$diffValue" -lt 0 ]; then
    diffValue=`expr 0 - $diffValue`
fi

if [ "$3" -lt "$diffvalue" ]; then
    echo "Yes. Diff is bigger than $3"
else
    echo "No. Diff is smaller than $3"
fi

