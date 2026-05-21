--############################################################################
--# Database Link Environment Setting
--############################################################################

--############################################################################
--# SET UP three DB System
--############################################################################

--+DECLARE SERVER LIMIT_DBLINK_SERVER1 DB1;
--+DECLARE SERVER LIMIT_DBLINK_SERVER2 DB2;

--+DECLARE CLIENT DEFAULT P1 (SERVER=DB1);
--+DECLARE CLIENT DEFAULT P2 (SERVER=DB2);

--+SET_ENV PATH=$ATC_HOME/scripts:$PATH;


    --+PROCESS P1;

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


        --+PROCESS P2;

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

--+PWAIT;
