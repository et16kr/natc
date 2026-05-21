#!/usr/local/bin/bash

if [ $# == 3 ]
then
ORACLE_SERVER_ALIAS=$1
NLS_LANG_SET=$2
TABLE_NAME=$3
fi

. adapterCommand.sh

export NLS_LANG=${NLS_LANG_SET}
$exec_command<<EOF>>dropNcreation.res
set linesize 100
set pagesize 50

DROP TABLE ${TABLE_NAME};

EXIT;
EOF

