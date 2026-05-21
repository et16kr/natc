#!/usr/local/bin/bash

if [ $# == 1 ]
then
COMMIT_MODE=$1
fi

export NLS_LANG=KOREAN_KOREA.KO16KSC5601
$ORACLE_HOME/bin/sqlplus -silent scott/tiger@ksc5601utf16_server<<EOF
set linesize 100
set pagesize 50

SET AUTOCOMMIT ${COMMIT_MODE};


exit;
EOF
