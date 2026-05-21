#!/bin/sh

ADMIN="${ALTIBASE_HOME}/bin/isql -atc -silent -u sys -p MANAGER -sysdba"


	${ADMIN} << EOF
startup control
alter database create checkpoint image '$1';
shutdown abort;
quit
EOF   
#sleep 3
