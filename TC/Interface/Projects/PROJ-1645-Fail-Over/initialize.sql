--############################################################################
--# UL-FailOver  Environment Setting
--############################################################################

--############################################################################
--# SET UP three DB System
--############################################################################

--+DECLARE SERVER UL_FAILOVER_SERVER1 DB1;
--+DECLARE SERVER UL_FAILOVER_SERVER2 DB2;
--+DECLARE SERVER UL_FAILOVER_SERVER3 DB3;

--+DECLARE CLIENT DEFAULT P11 (SERVER=DB1);
--+DECLARE CLIENT DEFAULT P21 (SERVER=DB2);
--+DECLARE CLIENT DEFAULT P31 (SERVER=DB3);

--+SET_ENV PATH=$ATC_HOME/scripts:$PATH;

--+SKIP BEGIN;
DROP TABLE T1;
DROP TABLE T2;
DROP USER  mcybtb cascade;
--+SKIP END;
    CREATE TABLE T1 (C1 INTEGER);
    CREATE TABLE T2 (C1 CHAR(8000) , C2 INTEGER);

    INSERT INTO T1 VALUES(100);
    INSERT INTO T1 VALUES(100);
    INSERT INTO T2 VALUES('100',1);
    INSERT INTO T2 VALUES('200',2);
    INSERT INTO T2 VALUES('300',3);
    INSERT INTO T2 VALUES('400',4);
    INSERT INTO T2 VALUES('500',5);
    INSERT INTO T2 VALUES('600',6);
    INSERT INTO T2 VALUES('700',7);
    INSERT INTO T2 VALUES('800',8);
  
create user mcybtb identified  by mcybtb;

connect mcybtb/mcybtb;   
    CREATE TABLE  A_TTT(DAY_LIM      FLOAT,           
                        DAY_USE      FLOAT,           
                        LAST_SERV    VARCHAR(14),     
                        OUTTIME      CHAR(1),         
                        CUST_CODE     VARCHAR(10)  NOT NULL,
                        USE           VARCHAR(20),     
                        NEW_FLAG      CHAR(1),         
                        NOTIYN        CHAR(1),        
                        ALIMI_TYPE    CHAR(1) );
    
    CREATE TABLE  CUST_TTT (CUST_CODE   VARCHAR(10)     FIXED       NOT NULL);

disconnect;


    --+PROCESS P11;

    --########################################
    --# Set Up DB 1
    --########################################

    --+SET_ENV @DB1 PATH=$ATC_HOME/scripts:$PATH;

    --+SYSTEM rm -rf db1;

    --+SYSTEM mkdir db1;
    --+SYSTEM ln -s $ALTIBASE_HOME/bin                      db1/bin;
    --+SYSTEM ln -s $ALTIBASE_HOME/msg                      db1/msg;
    --+SYSTEM ln -s $ALTIBASE_HOME/dlib                     db1/dlib;

    --+SYSTEM mkdir db1/conf;
    --+SYSTEM cp -f $ALTIBASE_HOME/conf/altibase.properties db1/conf;
    --+SYSTEM cp -f $ALTIBASE_HOME/conf/license             db1/conf;

    --+SYSTEM mkdir db1/dbs;
    --+SYSTEM mkdir db1/logs;
    --+SYSTEM mkdir db1/trc;
    --+SYSTEM mkdir db1/arch_logs;

    --+SYSTEM @DB1 server kill;
    --+SYSTEM @DB1 echo y | shmutil -e;
    --+SYSTEM @DB1 echo y | destroydb -n mydb;
    --+SYSTEM @DB1 echo y | createdb -M 10;

    --+SYSTEM @DB1 server start;
    CREATE TABLE T1 (C1 INTEGER);
    INSERT INTO T1 VALUES(10);
    INSERT INTO T1 VALUES(10);

    CREATE TABLE T2 (C1 CHAR(8000) , C2 INTEGER);
    INSERT INTO T2 VALUES('100',1);
    INSERT INTO T2 VALUES('200',2);
    INSERT INTO T2 VALUES('300',3);
    INSERT INTO T2 VALUES('400',4);
    INSERT INTO T2 VALUES('500',5);
    INSERT INTO T2 VALUES('600',6);
    INSERT INTO T2 VALUES('700',7);
    INSERT INTO T2 VALUES('800',8);
    create user mcybtb identified by mcybtb;

    connect mcybtb/mcybtb;   
    CREATE TABLE  A_TTT(DAY_LIM      FLOAT,           
                        DAY_USE      FLOAT,           
                        LAST_SERV    VARCHAR(14),     
                        OUTTIME      CHAR(1),         
                        CUST_CODE     VARCHAR(10)  NOT NULL,
                        USE           VARCHAR(20),     
                        NEW_FLAG      CHAR(1),         
                        NOTIYN        CHAR(1),        
                        ALIMI_TYPE    CHAR(1) );
    
    CREATE TABLE  CUST_TTT (CUST_CODE   VARCHAR(10)     FIXED       NOT NULL);
    disconnect;

        --+PROCESS P21;

        --########################################
        --# Set Up DB 2
        --########################################

        --+SET_ENV @DB2 PATH=$ATC_HOME/scripts:$PATH;

        --+SYSTEM rm -rf db2;

        --+SYSTEM mkdir db2;
        --+SYSTEM ln -s $ALTIBASE_HOME/bin                      db2/bin;
        --+SYSTEM ln -s $ALTIBASE_HOME/msg                      db2/msg;
        --+SYSTEM ln -s $ALTIBASE_HOME/dlib                     db2/dlib;

        --+SYSTEM mkdir db2/conf;
        --+SYSTEM cp -f $ALTIBASE_HOME/conf/altibase.properties db2/conf;
        --+SYSTEM cp -f $ALTIBASE_HOME/conf/license             db2/conf;

        --+SYSTEM mkdir db2/dbs;
        --+SYSTEM mkdir db2/logs;
        --+SYSTEM mkdir db2/trc;
        --+SYSTEM mkdir db2/arch_logs;

        --+SYSTEM @DB2 server kill;
        --+SYSTEM @DB2 echo y | shmutil -e;
        --+SYSTEM @DB2 echo y | destroydb -n mydb;
        --+SYSTEM @DB2 echo y | createdb -M 10;

        --+SYSTEM @DB2 server start;
        CREATE TABLE T1 (C1 INTEGER);
        INSERT INTO T1 VALUES(20);
        INSERT INTO T1 VALUES(2);

        CREATE TABLE T2 (C1 CHAR(8000) , C2 INTEGER);
        INSERT INTO T2 VALUES('100',1);
        INSERT INTO T2 VALUES('200',2);
        INSERT INTO T2 VALUES('300',3);
        INSERT INTO T2 VALUES('400',4);
        INSERT INTO T2 VALUES('500',5);
        INSERT INTO T2 VALUES('600',6);
        INSERT INTO T2 VALUES('700',7);
        INSERT INTO T2 VALUES('800',8);
        create user mcybtb identified by mcybtb;

        connect mcybtb/mcybtb;   
        CREATE TABLE  A_TTT(DAY_LIM      FLOAT,           
                            DAY_USE      FLOAT,           
                            LAST_SERV    VARCHAR(14),     
                            OUTTIME      CHAR(1),         
                            CUST_CODE     VARCHAR(10)  NOT NULL,
                            USE           VARCHAR(20),     
                            NEW_FLAG      CHAR(1),         
                            NOTIYN        CHAR(1),        
                            ALIMI_TYPE    CHAR(1) );
    
        CREATE TABLE  CUST_TTT (CUST_CODE   VARCHAR(10)     FIXED       NOT NULL);
        disconnect;

            --+PROCESS P31;

            --########################################
            --# Set Up DB 3
            --########################################

            --+SET_ENV @DB3 PATH=$ATC_HOME/scripts:$PATH;

            --+SYSTEM rm -rf db3;

            --+SYSTEM mkdir db3;
            --+SYSTEM ln -s $ALTIBASE_HOME/bin                      db3/bin;
            --+SYSTEM ln -s $ALTIBASE_HOME/msg                      db3/msg;
            --+SYSTEM ln -s $ALTIBASE_HOME/dlib                     db3/dlib;

            --+SYSTEM mkdir db3/conf;
            --+SYSTEM cp -f $ALTIBASE_HOME/conf/altibase.properties db3/conf;
            --+SYSTEM cp -f $ALTIBASE_HOME/conf/license             db3/conf;

            --+SYSTEM mkdir db3/dbs;
            --+SYSTEM mkdir db3/logs;
            --+SYSTEM mkdir db3/trc;
            --+SYSTEM mkdir db3/arch_logs;

            --+SYSTEM @DB3 server kill;
            --+SYSTEM @DB3 echo y | shmutil -e;
            --+SYSTEM @DB3 echo y | destroydb -n mydb;
            --+SYSTEM @DB3 echo y | createdb -M 10;

            --+SYSTEM @DB3 server start;
            CREATE TABLE T1 (C1 INTEGER);
            INSERT INTO T1 VALUES(3);
            INSERT INTO T1 VALUES(30);

            CREATE TABLE T2 (C1 CHAR(8000) , C2 INTEGER);
            INSERT INTO T2 VALUES('100',1);
            INSERT INTO T2 VALUES('200',2);
            INSERT INTO T2 VALUES('300',3);
            INSERT INTO T2 VALUES('400',4);
            INSERT INTO T2 VALUES('500',5);
            INSERT INTO T2 VALUES('600',6);
            INSERT INTO T2 VALUES('700',7);
            INSERT INTO T2 VALUES('800',8);

            create user mcybtb identified by mcybtb;
            connect mcybtb/mcybtb;   
            CREATE TABLE  A_TTT(DAY_LIM      FLOAT,           
                            DAY_USE      FLOAT,           
                            LAST_SERV    VARCHAR(14),     
                            OUTTIME      CHAR(1),         
                            CUST_CODE     VARCHAR(10)  NOT NULL,
                            USE           VARCHAR(20),     
                            NEW_FLAG      CHAR(1),         
                            NOTIYN        CHAR(1),        
                            ALIMI_TYPE    CHAR(1) );
    
            CREATE TABLE  CUST_TTT (CUST_CODE   VARCHAR(10)  FIXED   NOT NULL);
            disconnect;

--+PWAIT;
