#!/bin/sh

ADMIN="${ALTIBASE_HOME}/bin/isql -atc -silent -u sys -p MANAGER -sysdba"


	${ADMIN} << EOF
startup process;
create database mydb INITSIZE=$1M $2 character set ksc5601 national character set utf16;
shutdown abort
quit
EOF   

sleep 3
