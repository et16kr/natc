#!/usr/local/bin/bash


ORACLE_SERVER_ALIAS=$1
NLS_LANG_SET=$2
TABLE_NAME=$3

. adapterCommand.sh

export NLS_LANG=${NLS_LANG_SET}
if [ "${ADAPTER_TYPE}" == "3" ]
then
    $exec_command<<EOF>>oraInitialize.res
    
    DROP TABLE ${TABLE_NAME};
    
    CREATE TABLE ${TABLE_NAME}(
        I1  CHAR(30),
        I2  VARCHAR(30),
        I3  CHAR (30),
        I4  VARCHAR(30));
    ALTER TABLE ${TABLE_NAME} ADD PRIMARY KEY ( I1 );
    EXIT;
EOF
else
    $exec_command<<EOF>>oraInitialize.res
    set linesize 100
    set pagesize 50
    
    DROP TABLE ${TABLE_NAME};
    
    CREATE TABLE ${TABLE_NAME}(
        I1  CHAR(30),
        I2  VARCHAR2(30),
        I3  NCHAR (30),
        I4  NVARCHAR2(30));

    ALTER TABLE ${TABLE_NAME} ADD PRIMARY KEY ( I1 );
    EXIT;
EOF
fi
