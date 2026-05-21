#!/usr/local/bin/bash

if [[ $# == 3 || $# == 4 ]]
then

if [[ $4 == 1 ]]
then
  rm -f sqlExec.res
fi
ORACLE_SERVER_ALIAS=$1
NLS_LANG_SET=$2
SQL_STR=$3

export NLS_LANG=${NLS_LANG_SET}
echo "${SQL_STR}";

. adapterCommand.sh

if [ "${ADAPTER_TYPE}" == "3" ]
then
RES1=$(echo "$SQL_STR" | sed 's/CHAR(2000)/CHAR(255)/g')
RES2=$(echo "$RES1" | sed 's/NCHAR/CHAR/g')
RES3=$(echo "$RES2" | sed 's/NVARCHAR/VARCHAR/g')
$exec_command<<EOF>>sqlExec.res
${RES3};
EXIT
EOF

else

$exec_command<<EOF>>sqlExec.res
set linesize 100
set pagesize 50
set timing off
${SQL_STR};

EXIT;
EOF

fi

if [[ $4 == 1 ]]
then
  cat sqlExec.res
fi
else
    echo "USAGE $0 <ORACLE_SERVER_ALIAS> <NLS_LANG_SET> <SQL_STR> <PRINT_OPTION:0 or 1>"
    exit 255;
fi
rm -f sqlExec.res
