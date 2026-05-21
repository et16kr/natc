#!/bin/sh

FILE='time.txt'
TIME=`grep - $FILE`

ADMIN="${ALTIBASE_HOME}/bin/isql -atc -silent -u sys -p MANAGER -sysdba"


	${ADMIN} << EOF
startup control
alter database recover database until time '$TIME';
startup
quit
EOF   
