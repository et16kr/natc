#!/bin/sh

if [ $# -ne 1 ]
then 
    echo "USAGE : execute-sysdba.sh <command>"
    echo "Current number of arguments => $#"
    echo "1=>$1"
    echo "1=>$2"
    echo "1=>$3"
    exit
fi

COMMAND=$1

ADMIN="${ALTIBASE_HOME}/bin/isql -atc -silent -u sys -p MANAGER -sysdba"

	${ADMIN} << EOF
$COMMAND;
quit
EOF
