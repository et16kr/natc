--############################################################################
--# Replication Environment Setting
--############################################################################

--############################################################################
--# SET UP three DB System
--############################################################################

--+DECLARE SERVER COMPATI_REPL_SERVER1_HDB DB1;
--+DECLARE SERVER COMPATI_REPL_SERVER2_XDB DB2;
--+DECLARE SERVER COMPATI_REPL_SERVER3_HDB DB3;

--+DECLARE CLIENT DEFAULT P11 (SERVER=DB1);
--+DECLARE CLIENT DEFAULT P21 (SERVER=DB2);
--+DECLARE CLIENT DEFAULT P31 (SERVER=DB3);

--+SET_ENV PATH=$ATC_HOME/scripts:$PATH;
--+SET_ENV ALTIBASE_REPLICATION_LOCK_TIMEOUT=30;


    --+PROCESS P11;

    --########################################
    --# Set Up DB 1
    --########################################


    --+SYSTEM @DB1 server kill;
    --+SYSTEM @DB1 echo y | shmutil -e;
    --+SYSTEM @DB1 echo y | destroydb -n mydb;
    --+SYSTEM @DB1 echo y | createdb -M 10;

    --+SYSTEM @DB1 server start;


        --+PROCESS P21;

        --########################################
        --# Set Up DB 2
        --########################################


        --+SYSTEM @DB2 xdbserver kill;
        --+SYSTEM @DB2 echo y | xdbshmutil -e;
        --+SYSTEM @DB2 echo y | xdbdestroydb -n mydb;
        --+SYSTEM @DB2 echo y | xdbcreatedb -M 10;

        --+SYSTEM @DB2 xdbserver start;


            --+PROCESS P31;

            --########################################
            --# Set Up DB 3
            --########################################


            --+SYSTEM @DB3 server kill;
            --+SYSTEM @DB3 echo y | shmutil -e;
            --+SYSTEM @DB3 echo y | destroydb -n mydb;
            --+SYSTEM @DB3 echo y | createdb -M 10;

            --+SYSTEM @DB3 server start;

--+PWAIT;
