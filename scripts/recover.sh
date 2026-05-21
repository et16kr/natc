#!/bin/sh

ADMIN="${ALTIBASE_HOME}/bin/isql -atc -silent -u sys -p MANAGER -sysdba"


	${ADMIN} << EOF
startup control
alter database recover database $1 $2;
shutdown abort
quit
EOF   
