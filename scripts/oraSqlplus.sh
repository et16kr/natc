#!/usr/local/bin/bash

if [[ $# == 3 ]]
then

ORACLE_SERVER_ALIAS=$1
NLS_LANG_SET=$2
SQL_STR=$3

export NLS_LANG=${NLS_LANG_SET}
echo "${SQL_STR}";

$ORACLE_HOME/bin/sqlplus -silent scott/tiger@${ORACLE_SERVER_ALIAS}<<EOF
set linesize 100
set pagesize 50

${SQL_STR};

EXIT;
EOF

else
    echo "USAGE $0 <ORACLE_SERVER_ALIAS> <NLS_LANG_SET> <SQL_STR>"
    exit 255;
fi
