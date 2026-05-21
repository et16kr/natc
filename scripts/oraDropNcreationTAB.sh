#!/usr/local/bin/bash

ORACLE_SERVER_ALIAS=$1
NLS_LANG_SET=$2
TABLE_NAME=$3
export NLS_LANG=${NLS_LANG_SET}

. adapterCommand.sh

if [ $# == 3 ]
then
    if [ "${ADAPTER_TYPE}" == "3" ]
    then
    ${exec_command}<<EOF>>dropNcreation.res
    DROP TABLE IF EXISTS ${TABLE_NAME};
    CREATE TABLE ${TABLE_NAME}(
    I1  INTEGER PRIMARY KEY,
    I2  CHAR(20),
    I3  VARCHAR(20),
    I4  CHAR(20),
    I5  VARCHAR(20)
    );
    exit;
EOF
    elif [ "${ADAPTER_TYPE}" == "1" ]
    then
    ${exec_command}<<EOF>>dropNcreation.res
    set linesize 100
    set pagesize 50
    DROP TABLE ${TABLE_NAME};
    CREATE TABLE ${TABLE_NAME}(
    I1  INTEGER PRIMARY KEY,
    I2  CHAR(20),
    I3  VARCHAR2(20),
    I4  NCHAR(20),
    I5  NVARCHAR2(20)
    );
    exit;
EOF
    else
    ${exec_command}<<EOF>>dropNcreation.res
    set linesize 100
    set pagesize 50
    
    DROP TABLE ${TABLE_NAME};
    CREATE TABLE ${TABLE_NAME}(
    I1  INTEGER PRIMARY KEY,
    I2  CHAR(20),
    I3  VARCHAR2(20),
    I4  NCHAR(20),
    I5  NVARCHAR(20)
    );
    exit;
EOF
    fi
fi

if [[ "$4" == "char30" ]]
then
     if [ "${ADAPTER_TYPE}" == "3" ]
    then
    ${exec_command}<<EOF>>dropNcreation.res
    DROP TABLE IF EXISTS ${TABLE_NAME};
    CREATE TABLE ${TABLE_NAME}(
    I1  INTEGER PRIMARY KEY,
    I2  CHAR(30),
    I3  VARCHAR(20),
    I4  CHAR(20),
    I5  VARCHAR(20)
    );
    exit;
EOF
    elif [ "${ADAPTER_TYPE}" == "1" ]
    then
    ${exec_command}<<EOF>>dropNcreation.res
    set linesize 100
    set pagesize 50
    DROP TABLE ${TABLE_NAME};
    CREATE TABLE ${TABLE_NAME}(
    I1  INTEGER PRIMARY KEY,
    I2  CHAR(30),
    I3  VARCHAR2(20),
    I4  NCHAR(20),
    I5  NVARCHAR2(20)
    );
    exit;
EOF
    else
    ${exec_command}<<EOF>>dropNcreation.res
    set linesize 100
    set pagesize 50
    
    DROP TABLE ${TABLE_NAME};
    CREATE TABLE ${TABLE_NAME}(
    I1  INTEGER PRIMARY KEY,
    I2  CHAR(30),
    I3  VARCHAR2(20),
    I4  NCHAR(20),
    I5  NVARCHAR(20)
    );
    exit;
EOF
    fi
fi

if [[ "$4" == "char10" ]]
then
 if [ "${ADAPTER_TYPE}" == "3" ]
    then
    ${exec_command}<<EOF>>dropNcreation.res
    DROP TABLE IF EXISTS ${TABLE_NAME};
    CREATE TABLE ${TABLE_NAME}(
    I1  INTEGER PRIMARY KEY,
    I2  CHAR(10),
    I3  VARCHAR(20),
    I4  CHAR(20),
    I5  VARCHAR(20)
    );
    exit;
EOF
    elif [ "${ADAPTER_TYPE}" == "1" ]
    then
    ${exec_command}<<EOF>>dropNcreation.res
    set linesize 100
    set pagesize 50
    DROP TABLE ${TABLE_NAME};
    CREATE TABLE ${TABLE_NAME}(
    I1  INTEGER PRIMARY KEY,
    I2  CHAR(10),
    I3  VARCHAR2(20),
    I4  NCHAR(20),
    I5  NVARCHAR2(20)
    );
    exit;
EOF
    else
    ${exec_command}<<EOF>>dropNcreation.res
    set linesize 100
    set pagesize 50
    
    DROP TABLE ${TABLE_NAME};
    CREATE TABLE ${TABLE_NAME}(
    I1  INTEGER PRIMARY KEY,
    I2  CHAR(10),
    I3  VARCHAR2(20),
    I4  NCHAR(20),
    I5  NVARCHAR(20)
    );
    exit;
EOF
    fi
fi

if [[ "$4" == "nchar40nvarchar40" ]]
then
 if [ "${ADAPTER_TYPE}" == "3" ]
    then
    ${exec_command}<<EOF>>dropNcreation.res
    DROP TABLE IF EXISTS ${TABLE_NAME};
    CREATE TABLE ${TABLE_NAME}(
    I1  INTEGER PRIMARY KEY,
    I2  CHAR(20),
    I3  VARCHAR(20),
    I4  CHAR(40),
    I5  VARCHAR(40)
    );
    exit;
EOF
    elif [ "${ADAPTER_TYPE}" == "1" ]
    then
    ${exec_command}<<EOF>>dropNcreation.res
    set linesize 100
    set pagesize 50
    DROP TABLE ${TABLE_NAME};
    CREATE TABLE ${TABLE_NAME}(
    I1  INTEGER PRIMARY KEY,
    I2  CHAR(20),
    I3  VARCHAR2(20),
    I4  NCHAR(40),
    I5  NVARCHAR2(40)
    );
    exit;
EOF
    else
    ${exec_command}<<EOF>>dropNcreation.res
    set linesize 100
    set pagesize 50
    
    DROP TABLE ${TABLE_NAME};
    CREATE TABLE ${TABLE_NAME}(
    I1  INTEGER PRIMARY KEY,
    I2  CHAR(20),
    I3  VARCHAR2(20),
    I4  NCHAR(40),
    I5  NVARCHAR(40)
    );
    exit;
EOF
    fi
fi
