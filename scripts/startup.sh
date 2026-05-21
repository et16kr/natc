#!/bin/sh

ADMIN="${ALTIBASE_HOME}/bin/isql -atc -silent -u sys -p MANAGER -sysdba"


	${ADMIN} << EOF
startup $1 $2
quit
EOF   
sleep 2
