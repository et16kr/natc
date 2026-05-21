#!/usr/local/bin/bash

result=natc_result

if [ $# -eq 2 ]
then
result=natc_result_"$2"
fi


if [ $# -ge 1 ]
then
export ATAF_TEST_RESULT=$ATAF_TEST_RESULT/result_$1
fi

echo "ATAF_TEST_RESULT : $ATAF_TEST_RESULT"
viewdiff

