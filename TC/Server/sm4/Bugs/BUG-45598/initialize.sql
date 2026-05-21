--############################################################################
--# Replication Environment Setting
--############################################################################

--############################################################################
--# SET UP three DB System
--############################################################################

--+DECLARE SERVER BUG_45598_SERVER1 DB1;
--+DECLARE SERVER BUG_45598_SERVER2 DB2;

--+DECLARE CLIENT DEFAULT P11 (SERVER=DB1);
--+DECLARE CLIENT DEFAULT P21 (SERVER=DB2);

--+SET_ENV PATH=$ATC_HOME/scripts:$PATH;
--+SET_ENV ALTIBASE_REPLICATION_LOCK_TIMEOUT=30;


    --+PROCESS P11;

    --########################################
    --# Set Up DB 1
    --########################################

    --+SET_ENV @DB1 PATH=$ATC_HOME/scripts:$PATH;
    --+SET_ENV @DB1 ALTIBASE_REPLICATION_LOCK_TIMEOUT=30;
    --+SET_ENV @DB1 ALTIBASE_CORRUPT_PAGE_ERR_POLICY = 0;
    --+SET_ENV @DB1 ALTIBASE_CHECKSUM_METHOD=1;

    --+SYSTEM rm -rf db1;

    --+SYSTEM mkdir db1;
    --+SYSTEM ln -s $ALTIBASE_HOME/bin                      db1/bin;
    --+SYSTEM ln -s $ALTIBASE_HOME/msg                      db1/msg;
    --+SYSTEM ln -s $ALTIBASE_HOME/dlib                     db1/dlib;
    --+SYSTEM ln -s $ALTIBASE_HOME/install                  db1/install;
    --+SYSTEM ln -s $ALTIBASE_HOME/include                  db1/include;
    --+SYSTEM ln -s $ALTIBASE_HOME/lib                      db1/lib;

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

    SELECT * FROM DUAL;

        --+PROCESS P21;

        --########################################
        --# Set Up DB 2
        --########################################

        --+SET_ENV @DB2 PATH=$ATC_HOME/scripts:$PATH;
        --+SET_ENV @DB2 ALTIBASE_REPLICATION_LOCK_TIMEOUT=30;
        --+SET_ENV @DB2 ALTIBASE_CORRUPT_PAGE_ERR_POLICY = 0;

        --+SYSTEM rm -rf db2;

        --+SYSTEM mkdir db2;
        --+SYSTEM ln -s $ALTIBASE_HOME/bin                      db2/bin;
        --+SYSTEM ln -s $ALTIBASE_HOME/msg                      db2/msg;
        --+SYSTEM ln -s $ALTIBASE_HOME/dlib                     db2/dlib;
        --+SYSTEM ln -s $ALTIBASE_HOME/install                  db2/install;
        --+SYSTEM ln -s $ALTIBASE_HOME/include                  db2/include;
        --+SYSTEM ln -s $ALTIBASE_HOME/lib                      db2/lib;

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
        
        SELECT * FROM DUAL;

--+PWAIT;
