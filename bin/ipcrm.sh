#!/bin/sh

if [ $# -eq 0 ]; then
  userid=`whoami`
else
  userid=$1
fi

ipcs | grep $userid | awk '{print "ipcrm -" $1 " " $2}' | while read line
do
#	echo $line
	eval $line
done

ipcs -m | grep $userid | awk '{print "ipcrm shm " $2}' | while read line
do
#	echo $line
	eval $line
done

ipcs -s | grep $userid | awk '{print "ipcrm sem " $2}' | while read line
do
#	echo $line
	eval $line
done

ipcs -q | grep $userid | awk '{print "ipcrm msg " $2}' | while read line
do
#	echo $line
	eval $line
done

