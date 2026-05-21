--############################################################################
--# altiAdapter Environment Setting
--############################################################################

--+DECLARE SERVER ORAADAPTER_SERVER1 DB1;
--+DECLARE SERVER ORAADAPTER_SERVER2 DB2;

--+DECLARE CLIENT DEFAULT P1 (SERVER=DB1);
--+DECLARE CLIENT DEFAULT P2 (SERVER=DB2);

--+SET_ENV PATH=$ATC_HOME/scripts:$PATH;

    --+PROCESS P1;

    --########################################
    --# Set Up ALTIBASE
    --########################################

    --+SET_ENV @DB1 PATH=$ATC_HOME/scripts:$PATH;
    --+SET_ENV @DB1 ALTIBASE_REPLICATION_LOCK_TIMEOUT=30;
    --+SYSTEM rm -rf db1;

    --+SYSTEM mkdir db1;
    --+SYSTEM cp -r $ALTIBASE_HOME/bin                      db1/bin;
    --+SYSTEM cp -r $ALTIBASE_HOME/msg                      db1/msg;
    --+SYSTEM cp -r $ALTIBASE_HOME/lib                      db1/lib;

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
    --+SYSTEM @DB1 echo y | createdb -M 10 ksc5601 utf16;
    --+SET_ENV @DB1 ALTIBASE_NLS_USE=KSC5601;
    --+SYSTEM @DB1 server start;
    CREATE USER SCOTT IDENTIFIED BY TIGER;

        --+PROCESS P2;

        --########################################
        --# Set Up oraAdapter
        --########################################
        --+SET_ENV @DB1 PATH=$ATC_HOME/scripts:$PATH;
        --+SYSTEM rm -rf Adapter;
        --+SYSTEM cp -r $ALTIDEV_HOME/ut/adapter/src/dist    Adapter;

        --+SYSTEM @DB2 sed -e "s/ALTIBASE_USER = guest/ALTIBASE_USER = sys/g" -e "s/ALTIBASE_PASSWORD = guest/ALTIBASE_PASSWORD = manager/g" -e "s/ALTIBASE_PORT = 20300/ALTIBASE_PORT = ${ALTIBASE_PORT_NO@DB1}/g" -e "s/ALA_RECEIVER_PORT = 25090/ALA_RECEIVER_PORT = ${ALTIBASE_REPLICATION_PORT_NO}/g" -e "s/OTHER_ALTIBASE_PORT = 20090/OTHER_ALTIBASE_PORT = ${ALTIBASE_PORT_NO@DB1}/g" -e "s/OTHER_ALTIBASE_USER = guest/OTHER_ALTIBASE_USER = scott/g" -e "s/OTHER_ALTIBASE_PASSWORD = guest/OTHER_ALTIBASE_PASSWORD = tiger/g" $ALTIDEV_HOME/ut/adapter/src/dist/conf/altiAdapter.conf         > Adapter/conf/altiAdapter.conf;
        --+SYSTEM cp -f Adapter/conf/altiAdapter.conf Adapter/conf/altiAdapter.conf.org;
        --+SYSTEM @DB2 sed -e "s/ALTIBASE_PORT = 20090/ALTIBASE_PORT = ${ALTIBASE_PORT_NO@DB1}/g" -e "s/ALA_RECEIVER_PORT = 25090/ALA_RECEIVER_PORT = ${ALTIBASE_REPLICATION_PORT_NO}/g" -e "s/OTHER_ALTIBASE_PORT = 20090/OTHER_ALTIBASE_PORT = ${ALTIBASE_PORT_NO@DB1}/g" conf/altiAdapter.conf.passwd         > Adapter/conf/altiAdapter.conf.passwd;

--+PWAIT;

