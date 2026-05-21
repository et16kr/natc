#!/bin/sh

i=1;
k=0;
tmp=0;
MAX=30;

while [ $i -ne $k ]
do
  SC QUERY ${ALTIBASE_SERVICE} > tmp
  k=`grep STOPPED tmp | wc -l`
  sleep 1
  tmp=`expr $tmp + 1`
  if [ $tmp -gt $MAX ]
  then
      break
  else
      continue
  fi
done

if [ $tmp -gt $MAX ] 
then
   echo "FAILED";
else
   echo "SUCCESS";
fi

