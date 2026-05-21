#!/usr/local/bin/bash

ORACLE_SERVER_ALIAS=$1
NLS_LANG_SET=$2
TABLE_NAME=$3

. adapterCommand.sh

if [ $# -ge 3 ]
then
    if [ $# -eq 3 ]
    then
        if [ "${ADAPTER_TYPE}" == "3" ]
        then
            TABLE_SCHEMA="I1 CHAR(255) PRIMARY KEY"
        else
            TABLE_SCHEMA="I1 CHAR(2000) PRIMARY KEY"
        fi
    
    elif [ $# -eq 4 ] 
    then
        TABLE_SCHEMA=$4

    else
        echo "not allowed arguments count" >>crtOracleTab.res 
        exit
    fi
    
    export NLS_LANG=${NLS_LANG_SET}
    
    if [ "${ADAPTER_TYPE}" == "3" ]
    then
        SQL_STR="CREATE TABLE ${TABLE_NAME}(${TABLE_SCHEMA})"
        RES1=$(echo "$SQL_STR" | sed 's/CHAR(2000)/CHAR(255)/g')
        RES2=$(echo "$RES1" | sed 's/NCHAR/CHAR/g')
        RES3=$(echo "$RES2" | sed 's/NVARCHAR/VARCHAR/g')
        RES4=$(echo "$RES3" | sed 's/VARCHAR2/VARCHAR/g')
        echo $RES4
        $exec_command<<EOF>>sqlExec.res
        DROP TABLE IF EXISTS ${TABLE_NAME};
        ${RES4};
        exit
EOF
    else
        $exec_command<<EOF>>crtOracleTab.res
        set linesize 100
        set pagesize 50

        DROP TABLE ${TABLE_NAME};
        CREATE TABLE ${TABLE_NAME}(${TABLE_SCHEMA});
        exit;
EOF
    fi
    
else
    export NLS_LANG=${NLS_LANG_SET}
    
    if [ "${ADAPTER_TYPE}" == "1" ]
    then    
        $exec_command<<EOF>>crtOracleTab.res
        set linesize 100
        set pagesize 50
        
        DROP TABLE TEST1;
        CREATE TABLE TEST1 (
        I1  CHAR(100),
        I2  VARCHAR(4000),
        I3  VARCHAR2(4000),
        I4  NCHAR(100),     
        I5  NVARCHAR2(2000),
        I6  NUMBER(38,5),
        I7  BINARY_FLOAT,
        I8  BINARY_DOUBLE,
        I9  DATE );
        ALTER TABLE TEST1 ADD PRIMARY KEY ( I6 );
        
        DROP TABLE TEST2;
        CREATE TABLE TEST2 (
        C1  DATE,
        CC2  NCHAR(100),
        CCC3  VARCHAR2(4000),
        CCCC4  VARCHAR(4000),     
        CCCCC5  NVARCHAR2(2000),
        CCCCCC6  NUMBER(38,5),
        CCCCCCC7  BINARY_FLOAT,
        CCCCCCCC8  BINARY_DOUBLE,
        CCCCCCCCC9 CHAR(100) );
        ALTER TABLE TEST2 ADD PRIMARY KEY ( C1 );

        DROP TABLE TEST3;
        CREATE TABLE TEST3 (
        C1  DATE,
        CC2  NCHAR(100),
        CCC3  VARCHAR2(4000),
        CCCC4  VARCHAR(4000),     
        CCCCC5  NVARCHAR2(2000),
        CCCCCC6  NUMBER(38,5),
        CCCCCCC7  BINARY_FLOAT,
        CCCCCCCC8  BINARY_DOUBLE,
        CCCCCCCCC9 CHAR(100) );
        ALTER TABLE TEST3 ADD PRIMARY KEY ( C1 );
        
        DROP TABLE TEST4;
        CREATE TABLE TEST4 (
        C1  DATE,
        CC2  NCHAR(100),
        CCC3  VARCHAR2(4000),
        CCCC4  VARCHAR(4000),     
        CCCCC5  NVARCHAR2(2000),
        CCCCCC6  NUMBER(38,5),
        CCCCCCC7  BINARY_FLOAT,
        CCCCCCCC8  BINARY_DOUBLE,
        CCCCCCCCC9 CHAR(100) );
        ALTER TABLE TEST4 ADD PRIMARY KEY ( C1 );
        
        DROP TABLE ALTI_TO_ORA_DATATYPE;
        CREATE TABLE ALTI_TO_ORA_DATATYPE (
        I1 NUMBER PRIMARY KEY,
        I2 NUMBER,
        I3 NUMBER,
        I4 NUMBER,
        I5 NUMBER,
        I6 NUMBER,
        I7 NUMBER,
        I8 DATE,
        I9 CHAR(100),
        I10 VARCHAR(100),
        I11 VARCHAR2(100),
        I12 NCHAR(100),
        I13 NVARCHAR2(100),
        I14 BINARY_DOUBLE,
        I15 BINARY_FLOAT
        );
        
        DROP TABLE TX_TYPE_BEGIN_TAB;
        CREATE TABLE TX_TYPE_BEGIN_TAB (
        I1 INTEGER PRIMARY KEY );
        
        DROP TABLE TX_TYPE_COMMIT_TAB;
        CREATE TABLE TX_TYPE_COMMIT_TAB (
        I1 INTEGER PRIMARY KEY );
        
        DROP TABLE TX_TYPE_ROLLBACK_TAB;
        CREATE TABLE TX_TYPE_ROLLBACK_TAB (
        I1 INTEGER PRIMARY KEY );
        
        DROP TABLE SAVEPT;
        CREATE TABLE SAVEPT(num INTEGER PRIMARY KEY);
        
        DROP TABLE COMMIT_MODE_TAB;
        CREATE TABLE COMMIT_MODE_TAB(
        I1 CHAR(50) PRIMARY KEY );
        
        DROP TABLE ALTER_TAB;
        CREATE TABLE ALTER_TAB(
        I1 INTEGER PRIMARY KEY,
        I2 CHAR(20),
        I3 VARCHAR2(20),
        I4 NCHAR(20),
        I5 NVARCHAR2(20)
        );
        
        DROP TABLE CONCURRENT_TX_TAB;
        CREATE TABLE CONCURRENT_TX_TAB(
        I1 INTEGER PRIMARY KEY,
        I2 CHAR(20));
        
        DROP TABLE CONCURRENT_TX_TAB2;
        CREATE TABLE CONCURRENT_TX_TAB2(
        I1 INTEGER PRIMARY KEY,
        I2 CHAR(20));
        
        DROP TABLE CONCURRENT_TX_TAB3;
        CREATE TABLE CONCURRENT_TX_TAB3(
        I1 INTEGER PRIMARY KEY,
        I2 CHAR(20));
        
        DROP TABLE VARCHAR_TABLE;
        CREATE TABLE VARCHAR_TABLE (
        I1 VARCHAR(4000) PRIMARY KEY);
        
        DROP TABLE VARCHAR2_TABLE;
        CREATE TABLE VARCHAR2_TABLE (
        I1 VARCHAR2(2000) PRIMARY KEY);
        
        exit;
EOF
    elif [ "${ADAPTER_TYPE}" == "3" ]
    then 
        $exec_command <<EOF>>crtOracleTab.res
        
        DROP TABLE IF EXISTS TEST1;
        CREATE TABLE TEST1 (
        I1  CHAR(100),
        I2  VARCHAR(4000),
        I3  VARCHAR(4000),
        I4  CHAR(100),     
        I5  VARCHAR(2000),
        I6  NUMERIC(38,5),
        I7  REAL,
        I8  DOUBLE,
        I9  DATE );
        ALTER TABLE TEST1 ADD PRIMARY KEY ( I6 );
        
        DROP TABLE IF EXISTS TEST2;
        CREATE TABLE TEST2 (
        C1  DATE,
        CC2  CHAR(100),
        CCC3  VARCHAR(4000),
        CCCC4  VARCHAR(4000),     
        CCCCC5  VARCHAR(2000),
        CCCCCC6  NUMERIC(38,5),
        CCCCCCC7  REAL,
        CCCCCCCC8  DOUBLE,
        CCCCCCCCC9 CHAR(100) );
        ALTER TABLE TEST2 ADD PRIMARY KEY ( C1 );

        DROP TABLE IF EXISTS TEST3;
        CREATE TABLE TEST3 (
        C1  DATE,
        CC2  CHAR(100),
        CCC3  VARCHAR(4000),
        CCCC4  VARCHAR(4000),     
        CCCCC5  VARCHAR(2000),
        CCCCCC6  NUMERIC(38,5),
        CCCCCCC7  REAL,
        CCCCCCCC8  DOUBLE,
        CCCCCCCCC9 CHAR(100) );
        ALTER TABLE TEST3 ADD PRIMARY KEY ( C1 );
        
        DROP TABLE IF EXISTS TEST4;
        CREATE TABLE TEST4 (
        C1  DATE,
        CC2  CHAR(100),
        CCC3  VARCHAR(4000),
        CCCC4  VARCHAR(4000),     
        CCCCC5  VARCHAR(2000),
        CCCCCC6  NUMERIC(38,5),
        CCCCCCC7  REAL,
        CCCCCCCC8  DOUBLE,
        CCCCCCCCC9 CHAR(100) );
        ALTER TABLE TEST4 ADD PRIMARY KEY ( C1 );
        
        DROP TABLE IF EXISTS ALTI_TO_ORA_DATATYPE;
        CREATE TABLE ALTI_TO_ORA_DATATYPE (
        I1 NUMERIC PRIMARY KEY,
        I2 NUMERIC,
        I3 NUMERIC,
        I4 NUMERIC,
        I5 NUMERIC,
        I6 NUMERIC,
        I7 NUMERIC,
        I8 DATE,
        I9 CHAR(100),
        I10 VARCHAR(100),
        I11 VARCHAR(100),
        I12 CHAR(100),
        I13 VARCHAR(100),
        I14 DOUBLE,
        I15 REAL
        );
        
        DROP TABLE IF EXISTS TX_TYPE_BEGIN_TAB;
        CREATE TABLE TX_TYPE_BEGIN_TAB (
        I1 INTEGER PRIMARY KEY );
        
        DROP TABLE IF EXISTS TX_TYPE_COMMIT_TAB;
        CREATE TABLE TX_TYPE_COMMIT_TAB (
        I1 INTEGER PRIMARY KEY );
        
        DROP TABLE IF EXISTS TX_TYPE_ROLLBACK_TAB;
        CREATE TABLE TX_TYPE_ROLLBACK_TAB (
        I1 INTEGER PRIMARY KEY );
        
        DROP TABLE IF EXISTS SAVEPT;
        CREATE TABLE SAVEPT(num INTEGER PRIMARY KEY);
        
        DROP TABLE IF EXISTS COMMIT_MODE_TAB;
        CREATE TABLE COMMIT_MODE_TAB(
        I1 CHAR(50) PRIMARY KEY );
        
        DROP TABLE IF EXISTS ALTER_TAB;
        CREATE TABLE ALTER_TAB(
        I1 INTEGER PRIMARY KEY,
        I2 CHAR(20),
        I3 VARCHAR(20),
        I4 CHAR(20),
        I5 VARCHAR(20)
        );
        
        DROP TABLE IF EXISTS CONCURRENT_TX_TAB;
        CREATE TABLE CONCURRENT_TX_TAB(
        I1 INTEGER PRIMARY KEY,
        I2 CHAR(20));
        
        DROP TABLE IF EXISTS CONCURRENT_TX_TAB2;
        CREATE TABLE CONCURRENT_TX_TAB2(
        I1 INTEGER PRIMARY KEY,
        I2 CHAR(20));
        
        DROP TABLE IF EXISTS CONCURRENT_TX_TAB3;
        CREATE TABLE CONCURRENT_TX_TAB3(
        I1 INTEGER PRIMARY KEY,
        I2 CHAR(20));
        
        DROP TABLE IF EXISTS VARCHAR_TABLE;
        CREATE TABLE VARCHAR_TABLE (
        I1 VARCHAR(200) PRIMARY KEY);
        exit
EOF
    else
        echo "jdbcAdapter not allowed this DDL"
        exit
    fi
    
fi

