#!/bin/sh

############################
#  USAGE
#  
#  chkrep.sh [.] [options]
#
#  .             : report the current directory
#
#  options : 
#    -m     : set mode
#           full : report the detailed checklist
#           desc : report the describe checklist
#           brief: report the summary.
#           *** default value is "brief"
#        
#    -p     : period
#           +n   : more than n days
#            n   : exactly n days
#           -n   : less than n days
#
##############################

if [ "$1" = "." ]
then
    perl $ATC_HOME/lib/CheckList.pm -d . $*
else
    cd $ATC_HOME
    perl $ATC_HOME/lib/CheckList.pm $*
fi
