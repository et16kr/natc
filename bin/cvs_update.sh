#!/bin/sh

LOG_DIR=$ATC_WORK

DATE_STRING=`date '+%y%m%d'`

#[ ! -d $LOG_DIR ] && mkdir $LOG_DIR

cvs update -dPA 1> $LOG_DIR/cvsupdate.$DATE_STRING.log 2> $LOG_DIR/cvsupdate.$DATE_STRING.err 
grep "^rcsmerge: warning: conflicts during merge$" $LOG_DIR/cvsupdate.$DATE_STRING.log | awk 'BEGIN{cnt=0}{cnt++}END{if (cnt > 0) exit 1; else exit 0;}' 
grep "^rcsmerge: warning: conflicts during merge$" $LOG_DIR/cvsupdate.$DATE_STRING.err | awk 'BEGIN{cnt=0}{cnt++}END{if (cnt > 0) exit 1; else exit 0;}' 

exit $?
