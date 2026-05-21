#!/usr/local/bin/bash

LOG_DIR=$ATC_WORK

DATE_STRING=`date '+%y%m%d'`

#[ ! -d $LOG_DIR ] && mkdir $LOG_DIR

make $* &> $LOG_DIR/build.$DATE_STRING 

exit $?
