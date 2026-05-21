#!/usr/local/bin/bash

if [ $# == 3 ]
then
ORACLE_SERVER_ALIAS=$1
NLS_LANG_SET=$2
TABLE_NAME=$3
fi

. adapterCommand.sh

export NLS_LANG=${NLS_LANG_SET}

if [ "${ADAPTER_TYPE}" != "3" ]
then
    $exec_command<<EOF>>dropNcreation.res
    set linesize 100
    set pagesize 50
    
    DROP TABLE ${TABLE_NAME};
    
    CREATE TABLE ${TABLE_NAME}(
    I1  INTEGER,
    I2  CHAR(20),
    I3  VARCHAR(20)
    );
    ALTER TABLE ${TABLE_NAME} ADD PRIMARY KEY ( I1 );
    
    EXIT;
EOF
else
    $exec_command<<EOF>>dropNcreation.res
    
    DROP TABLE IF EXISTS ${TABLE_NAME};
    CREATE TABLE ${TABLE_NAME}(
    I1  INTEGER,
    I2  CHAR(20),
    I3  VARCHAR(20)
    );
    ALTER TABLE ${TABLE_NAME} ADD PRIMARY KEY ( I1 );

    EXIT;
EOF
fi
