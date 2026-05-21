--############################################################################
--# Replication Environment Setting
--############################################################################

--############################################################################
--# SET UP three DB System
--############################################################################

--+DECLARE SERVER ALA_SERVER1 DB1;
--+DECLARE SERVER ALA_SERVER2 DB2;
--+DECLARE SERVER ALA_SERVER3 DB3;

--+DECLARE CLIENT DEFAULT P11 (SERVER=DB1);
--+DECLARE CLIENT DEFAULT P21 (SERVER=DB2);
--+DECLARE CLIENT DEFAULT P31 (SERVER=DB3);

--+SET_ENV PATH=$ATC_HOME/scripts:$PATH;
--+SET_ENV ALTIBASE_REPLICATION_LOCK_TIMEOUT=30;


    --+PROCESS P11;

    --########################################
    --# Set Up DB 1
    --########################################

    --+SET_ENV @DB1 PATH=$ATC_HOME/scripts:$PATH;
    --+SET_ENV @DB1 ALTIBASE_REPLICATION_LOCK_TIMEOUT=30;

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


            --+PROCESS P31;

            --########################################
            --# Set Up DB 3
            --########################################

            --+SET_ENV @DB3 PATH=$ATC_HOME/scripts:$PATH;
            --+SET_ENV @DB3 ALTIBASE_REPLICATION_LOCK_TIMEOUT=30;

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

--+PWAIT;
