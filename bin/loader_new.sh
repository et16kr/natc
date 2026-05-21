#!/bin/sh
#
# program loader # 	with excution environment setting
#
# $Id: loader_new.sh 2 2006-04-13 15:48:39Z copyrei $

#trap : 2 
help_exit()
{
	eval "$PRG_NAME -h"
	echo "\n"
	echo "============================================================"
	echo "Usage: $0 <prg> <prg options> [-D<environment defintions>]"
	echo "============================================================"
	exit 0;
}

PRG_NAME=" "
while [ $# -gt 0 ] 
do
	case $1 in
		-h)
			help_exit
			;;
		-D)	# Environment Variable Definitions
			eval $2
			export `echo $2 | cut -f 1 -d '='`
			shift 2
			;;
		*)
		    if [ "$PRG_NAME" = " " ]
			then
				PRG_NAME=$1
			else
			    PRG_OPT="$PRG_OPT $1"
			fi
			shift
			;;
	esac
done

eval $PRG_NAME $PRG_OPT
