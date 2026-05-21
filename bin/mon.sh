#!/usr/local/bin/bash

if [ $# -eq 1 ]
then
ATAF_TEST_RESULT=$1
fi

if [ "$HOSTNAME" = "m5000" ]; then
count=15
else
count=2
fi

echo "STAF_INSTANCE_NAME is STAF"$LOGNAME;
STAF local ats status;

i=1;
while [ $i -ne $count ]
do

echo "STAF_INSTANCE_NAME is STAF"$LOGNAME"_p"$i;
export STAF_INSTANCE_NAME=STAF"$LOGNAME"_p$i;
STAF local ats status;

i=`expr $i + 1`
done
