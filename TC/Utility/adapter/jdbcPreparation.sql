--############################################################################
--# SECTOR;
--############################################################################

--+DECLARE SERVER ORAADAPTER_SERVER1 DB1;
--+DECLARE SERVER ORAADAPTER_SERVER2 DB2;

--+DECLARE CLIENT DEFAULT P1 (SERVER=DB1);
--+DECLARE CLIENT DEFAULT P2 (SERVER=DB2);

    --+PROCESS P1;
    CONNECT SCOTT/TIGER;
    CREATE TABLE TEST1 (
    I1  CHAR(100),
    I2  VARCHAR(4000),
    I3  VARCHAR2(4000),
    I4  NCHAR(100),
    I5  NVARCHAR(2000),
    I6  NUMBER(38,5),
    I7  REAL,
    I8  DOUBLE,
    I9  DATE );
    ALTER TABLE TEST1 ADD PRIMARY KEY ( I6 );

    CREATE TABLE TEST2 (
    C1  DATE,
    CC2  NCHAR(100),
    CCC3  VARCHAR2(4000),
    CCCC4  VARCHAR(4000),
    CCCCC5  NVARCHAR(2000),
    CCCCCC6  NUMBER(38,5),
    CCCCCCC7  FLOAT,
    CCCCCCCC8  DOUBLE,
    CCCCCCCCC9 CHAR(100) );
    ALTER TABLE TEST2 ADD PRIMARY KEY ( C1 );

    CREATE TABLE TEST3 (
    C1  DATE,
    CC2  NCHAR(100),
    CCC3  VARCHAR2(4000),
    CCCC4  VARCHAR(4000),
    CCCCC5  NVARCHAR(2000),
    CCCCCC6  NUMBER(38,5),
    CCCCCCC7  FLOAT,
    CCCCCCCC8  DOUBLE,
    CCCCCCCCC9 CHAR(100) );
    ALTER TABLE TEST3 ADD PRIMARY KEY ( C1 );

    CREATE TABLE TEST4 (
    C1  DATE,
    CC2  NCHAR(100),
    CCC3  VARCHAR2(4000),
    CCCC4  VARCHAR(4000),
    CCCCC5  NVARCHAR(2000),
    CCCCCC6  NUMBER(38,5),
    CCCCCCC7  FLOAT,
    CCCCCCCC8  DOUBLE,
    CCCCCCCCC9 CHAR(100) );
    ALTER TABLE TEST4 ADD PRIMARY KEY ( C1 );

    CREATE TABLE ALTI_TO_ORA_DATATYPE (
    I1 INTEGER PRIMARY KEY,
    I2 NUMERIC,
    I3 DOUBLE,
    I4 REAL,
    I5 BIGINT,
    I6 FLOAT,
    I7 SMALLINT,
    I8 DATE,
    I9 CHAR(100),
    I10 VARCHAR(100),
    I11 VARCHAR2(100),
    I12 NCHAR(100),
    I13 NVARCHAR(100),
    I14 DOUBLE,
    I15 REAL
    );

    CREATE TABLE TX_TYPE_BEGIN_TAB (
    I1 INTEGER PRIMARY KEY );

    CREATE TABLE TX_TYPE_COMMIT_TAB (
    I1 INTEGER PRIMARY KEY );

    CREATE TABLE TX_TYPE_ROLLBACK_TAB (
    I1 INTEGER PRIMARY KEY );

    CREATE TABLE savept (
    num INTEGER PRIMARY KEY );

    CREATE TABLE COMMIT_MODE_TAB (
    I1 CHAR(50) PRIMARY KEY );

    CREATE TABLE ALTER_TAB (
    I1 INTEGER PRIMARY KEY,
    I2 CHAR(20),
    I3 VARCHAR(20),
    I4 NCHAR(20),
    I5 NVARCHAR(20)
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

    CREATE TABLE CHAR_TABLE (
    I1 CHAR(2000) PRIMARY KEY);

    CREATE TABLE VARCHAR_TABLE (
    I1 VARCHAR(4000) PRIMARY KEY);

    CREATE TABLE VARCHAR2_TABLE (
    I1 VARCHAR2(4000) PRIMARY KEY);
--+PWAIT;
    

    --+PROCESS P1;

    --############################################################################
    --#SECTOR;
    --############################################################################
    CONNECT SYS/MANAGER;
    --+SKIP BEGIN;
    CREATE TABLE TEST1 (
    I1  CHAR(100),
    I2  VARCHAR(4000),
    I3  VARCHAR2(4000),
    I4  NCHAR(100),
    I5  NVARCHAR(2000),
    I6  NUMBER(38,5),
    I7  REAL,
    I8  DOUBLE,
    I9  DATE );
    ALTER TABLE TEST1 ADD PRIMARY KEY ( I6 );

    CREATE TABLE TEST2 (
    C1  DATE,
    CC2  NCHAR(100),
    CCC3  VARCHAR2(4000),
    CCCC4  VARCHAR(4000),
    CCCCC5  NVARCHAR(2000),
    CCCCCC6  NUMBER(38,5),
    CCCCCCC7  FLOAT,
    CCCCCCCC8  DOUBLE,
    CCCCCCCCC9 CHAR(100) );
    ALTER TABLE TEST2 ADD PRIMARY KEY ( C1 );

    CREATE TABLE TEST3 (
    C1  DATE,
    CC2  NCHAR(100),
    CCC3  VARCHAR2(4000),
    CCCC4  VARCHAR(4000),
    CCCCC5  NVARCHAR(2000),
    CCCCCC6  NUMBER(38,5),
    CCCCCCC7  FLOAT,
    CCCCCCCC8  DOUBLE,
    CCCCCCCCC9 CHAR(100) );
    ALTER TABLE TEST3 ADD PRIMARY KEY ( C1 );

    CREATE TABLE TEST4 (
    C1  DATE,
    CC2  NCHAR(100),
    CCC3  VARCHAR2(4000),
    CCCC4  VARCHAR(4000),
    CCCCC5  NVARCHAR(2000),
    CCCCCC6  NUMBER(38,5),
    CCCCCCC7  FLOAT,
    CCCCCCCC8  DOUBLE,
    CCCCCCCCC9 CHAR(100) );
    ALTER TABLE TEST4 ADD PRIMARY KEY ( C1 );

    CREATE TABLE ALTI_TO_ORA_DATATYPE (
    I1 INTEGER PRIMARY KEY,
    I2 NUMERIC,
    I3 DOUBLE,
    I4 REAL,
    I5 BIGINT,
    I6 FLOAT,
    I7 SMALLINT,
    I8 DATE,
    I9 CHAR(100),
    I10 VARCHAR(100),
    I11 VARCHAR2(100),
    I12 NCHAR(100),
    I13 NVARCHAR(100),
    I14 DOUBLE,
    I15 REAL
    );

    CREATE TABLE TX_TYPE_BEGIN_TAB (
    I1 INTEGER PRIMARY KEY );

    CREATE TABLE TX_TYPE_COMMIT_TAB (
    I1 INTEGER PRIMARY KEY );

    CREATE TABLE TX_TYPE_ROLLBACK_TAB (
    I1 INTEGER PRIMARY KEY );

    CREATE TABLE savept (
    num INTEGER PRIMARY KEY );

    CREATE TABLE COMMIT_MODE_TAB (
    I1 CHAR(50) PRIMARY KEY );

    CREATE TABLE ALTER_TAB (
    I1 INTEGER PRIMARY KEY,
    I2 CHAR(20),
    I3 VARCHAR(20),
    I4 NCHAR(20),
    I5 NVARCHAR(20)
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

    CREATE TABLE CHAR_TABLE (
    I1 CHAR(2000) PRIMARY KEY);

    CREATE TABLE VARCHAR_TABLE (
    I1 VARCHAR(4000) PRIMARY KEY);

    CREATE TABLE VARCHAR2_TABLE (
    I1 VARCHAR2(4000) PRIMARY KEY);
    
    --+SKIP END;

    CREATE REPLICATION ALA FOR ANALYSIS
    WITH '${HOST_IP@DB2}', ${ALTIBASE_REPLICATION_PORT_NO@DB2}
    from sys.test1 to scott.test1, from sys.test2 to scott.test2,
    from sys.test3 to scott.test3, from sys.test4 to scott.test4,
    from sys.alti_to_ora_datatype to scott.alti_to_ora_datatype,
    from sys.tx_type_begin_tab to scott.tx_type_begin_tab,
    from sys.tx_type_commit_tab to scott.tx_type_commit_tab,
    from sys.tx_type_rollback_tab to scott.tx_type_rollback_tab,
    from sys.savept to scott.savept,
    from sys.commit_mode_tab to scott.commit_mode_tab,
    from sys.char_table to scott.char_table,
    from sys.alter_tab to scott.alter_tab,
    from sys.varchar_table to scott.varchar_table,
    from sys.varchar2_table to scott.varchar2_table,
    from sys.concurrent_tx_tab to scott.concurrent_tx_tab,
    from sys.concurrent_tx_tab2 to scott.concurrent_tx_tab2,
    from sys.concurrent_tx_tab3 to scott.concurrent_tx_tab3;

--+PWAIT;

--############################################################################
--# oraAdapter Env Setting 나중에 바꿔야함.
--############################################################################

        --+PROCESS P2;

        --+SYSTEM rm -f *.res;
        --+SYSTEM crtOracleTab.sh ksc5601utf16_server AMERICAN_AMERICA.KO16KSC5601;
        --+SYSTEM grep -v "SQL\*Plus" crtOracleTab.res > crtOracleTab2.res;
        --+SYSTEM rm -f *.res;

        --+SET_ENV @DB2 ORA_ADAPTER_HOME=$ALTIBASE_HOME/../Adapter;
        --+SET_ENV @DB2 ALTIBASE_ADAPTER_HOME=${ORA_ADAPTER_HOME};
        --+SET_ENV @DB2 JDBC_ADAPTER_HOME=${ORA_ADAPTER_HOME};
        --+SET_ENV @DB2 PATH=$ORA_ADAPTER_HOME/bin:$PATH;
        --+SET_ENV @DB2 NLS_LANG=AMERICAN_AMERICA.KO16KSC5601;
        --+SET_ENV @DB2 ALTIBASE_NLS_USE=KSC5601;
        --+SET_ENV @DB2 OTHER_ALTIBASE_NLS_USE=KSC5601;

        --+SYSTEM @DB2 cp $ORA_ADAPTER_HOME/conf/oraAdapter.conf.ksc5601utf16 $ORA_ADAPTER_HOME/conf/oraAdapter.conf;
        --+SYSTEM @DB2 cp $ALTIBASE_ADAPTER_HOME/conf/altiAdapter.conf $ORA_ADAPTER_HOME/conf/altiAdapter.conf;
        --+SYSTEM @DB2 cp $JDBC_ADAPTER_HOME/conf/jdbcAdapter.conf $JDBC_ADAPTER_HOME/conf/jdbcAdapter.conf;
        --+SYSTEM @DB2 oaUtility start;

--+PWAIT;

    --+PROCESS P1;

    ALTER REPLICATION ALA START;

--+PWAIT;

