#!/usr/local/bin/bash

ORACLE_SERVER_ALIAS=$1
NLS_LANG_SET=$2
TABLE_NAME=$3

. adapterCommand.sh

if [ $# == 3 ]
then

    export NLS_LANG=${NLS_LANG_SET}

    if [ "${ADAPTER_TYPE}" == "3" ]
    then 
        $exec_command<<EOF>>oracle.res
        select * from ${TABLE_NAME};
        exit
EOF
    else
        $exec_command<<EOF>>oracle.res
        set linesize 100
        set pagesize 50
        select * from ${TABLE_NAME};
        exit;
EOF
    fi
fi

if [[ "$4" == "count" ]]
then

    export NLS_LANG=${NLS_LANG_SET}

    if [ "${ADAPTER_TYPE}" == "3" ]
    then 
        $exec_command<<EOF>>oracle.res
        select count(*) from ${TABLE_NAME} order by 1;
        exit
EOF
    else
        $exec_command<<EOF>>oracle.res
        set linesize 100
        set pagesize 50
        select count(*) from ${TABLE_NAME} order by 1;
        exit;        
EOF
    fi
fi
