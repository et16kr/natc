#!/bin/sh

ADMIN="${ALTIBASE_HOME}/bin/isql -atc -silent -u sys -p MANAGER -sysdba"


	${ADMIN} << EOF
startup control;
alter database mydb meta resetlogs;
quit
EOF   
