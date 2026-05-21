#!/usr/local/bin/bash

if [ "${ADAPTER_TYPE}" == "1" ]
then
#    echo "oraAdapter"
    exec_command="${ORACLE_HOME}/bin/sqlplus -silent scott/tiger@${ORACLE_SERVER_ALIAS}"
elif [ "${ADAPTER_TYPE}" == "2" ]
then
#    echo "jdbcAdapter"
    exec_command="${ALTIBASE_HOME}/bin/isql -silent -s localhost -u scott -p tiger -port ${ALTIBASE_PORT_NO}"
elif [ "${ADAPTER_TYPE}" == "3" ]
then
#    echo "jdbcAdapter for mariadb"
    exec_command="${MARIADB_HOME}/bin/mysql -uscott -ptiger mydb -A -h192.168.1.187 --port 4304"
else
#    echo "jdbcAdapter"
    exec_command="${ALTIBASE_HOME}/bin/isql -silent -s localhost -u scott -p tiger -port ${ALTIBASE_PORT_NO}"
fi
