--############################################################################
--# Replication Environment Setting
--############################################################################

--############################################################################
--# SET UP three DB System
--############################################################################

--+DECLARE SERVER REPL_ART_SERVER1 DB1;
--+DECLARE SERVER REPL_ART_SERVER2 DB2;
--+DECLARE SERVER REPL_ART_SERVER3 DB3;

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
    --+SYSTEM cp -f $ALTIBASE_HOME/conf/recovery.dat        db1/conf;

    --+SYSTEM mkdir db1/dbs;
    --+SYSTEM mkdir db1/logs;
    --+SYSTEM mkdir db1/trc;
    --+SYSTEM mkdir db1/arch_logs;

    --+SYSTEM @DB1 server kill;
    --+SYSTEM @DB1 echo y | shmutil -e;
    --+SYSTEM @DB1 echo y | destroydb -n mydb;
    --+SYSTEM @DB1 echo y | createdb -M 10;

    --+SYSTEM @DB1 server start;


        --+PROCESS P21;

        --########################################
        --# Set Up DB 2
        --########################################

        --+SET_ENV @DB2 PATH=$ATC_HOME/scripts:$PATH;
        --+SET_ENV @DB2 ALTIBASE_REPLICATION_LOCK_TIMEOUT=30;

        --+SYSTEM rm -rf db2;

        --+SYSTEM mkdir db2;
        --+SYSTEM ln -s $ALTIBASE_HOME/bin                      db2/bin;
        --+SYSTEM ln -s $ALTIBASE_HOME/msg                      db2/msg;
        --+SYSTEM ln -s $ALTIBASE_HOME/dlib                     db2/dlib;

        --+SYSTEM mkdir db2/conf;
        --+SYSTEM cp -f $ALTIBASE_HOME/conf/altibase.properties db2/conf;
        --+SYSTEM cp -f $ALTIBASE_HOME/conf/license             db2/conf;
        --+SYSTEM cp -f $ALTIBASE_HOME/conf/recovery.dat        db2/conf;

        --+SYSTEM mkdir db2/dbs;
        --+SYSTEM mkdir db2/logs;
        --+SYSTEM mkdir db2/trc;
        --+SYSTEM mkdir db2/arch_logs;

        --+SYSTEM @DB2 server kill;
        --+SYSTEM @DB2 echo y | shmutil -e;
        --+SYSTEM @DB2 echo y | destroydb -n mydb;
        --+SYSTEM @DB2 echo y | createdb -M 10;

        --+SYSTEM @DB2 server start;


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
            --+SYSTEM cp -f $ALTIBASE_HOME/conf/recovery.dat        db3/conf;

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
