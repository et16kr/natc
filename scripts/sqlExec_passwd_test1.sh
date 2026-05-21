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

if [ "${ADAPTER_TYPE}" == "1" ]
then
    echo "oraAdapter"
    exec_command="${ORACLE_HOME}/bin/sqlplus -silent passwd_test1/\"#TI#GER!!###\"@${ORACLE_SERVER_ALIAS}"
elif [ "${ADAPTER_TYPE}" == "2" ]
then
#    echo "jdbcAdapter"
    exec_command="${ALTIBASE_HOME}/bin/isql -silent -s localhost -u passwd_test1 -p \"#TI#GER!!###\" -port ${ALTIBASE_PORT_NO}"
elif [ "${ADAPTER_TYPE}" == "3" ]
then
#    echo "jdbcAdapter for mariadb"
    exec_command="${MARIADB_HOME}/bin/mysql -upasswd_test1 -p#TI#GER!!### mydb -A -h192.168.1.183 --port 4304"    
else
#    echo "altiAdapter"
    exec_command="${ALTIBASE_HOME}/bin/isql -silent -s localhost -u passwd_test1 -p \"#TI#GER!!###\" -port ${ALTIBASE_PORT_NO}"
fi

if [ "${ADAPTER_TYPE}" == "3" ]
then
    $exec_command <<EOF>>sqlExec.res
    ${SQL_STR};
    EXIT
EOF
else
    $exec_command <<EOF>>sqlExec.res

    set linesize 100
    set pagesize 50
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
