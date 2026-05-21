--############################################################################
--# oraAdapter Environment Setting
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


        --+PROCESS P2;

        --########################################
        --# Set Up oraAdapter
        --########################################

        --+SYSTEM rm -rf oraAdapter;
        --+SYSTEM cp -r $ALTIDEV_HOME/ut/oraAdapter/src/dist    oraAdapter;

        --+SYSTEM @DB2 sed -e "s/ALTIBASE_PORT = 20090/ALTIBASE_PORT = ${ALTIBASE_PORT_NO@DB1}/g" -e "s/ALA_RECEIVER_PORT = 25090/ALA_RECEIVER_PORT = ${ALTIBASE_REPLICATION_PORT_NO}/g" conf/oraAdapter.conf.big5         > oraAdapter/conf/oraAdapter.conf.big5;
        --+SYSTEM @DB2 sed -e "s/ALTIBASE_PORT = 20090/ALTIBASE_PORT = ${ALTIBASE_PORT_NO@DB1}/g" -e "s/ALA_RECEIVER_PORT = 25090/ALA_RECEIVER_PORT = ${ALTIBASE_REPLICATION_PORT_NO}/g" conf/oraAdapter.conf.eucjpNutf16  > oraAdapter/conf/oraAdapter.conf.eucjpNutf16;
        --+SYSTEM @DB2 sed -e "s/ALTIBASE_PORT = 20090/ALTIBASE_PORT = ${ALTIBASE_PORT_NO@DB1}/g" -e "s/ALA_RECEIVER_PORT = 25090/ALA_RECEIVER_PORT = ${ALTIBASE_REPLICATION_PORT_NO}/g" conf/oraAdapter.conf.gb231280     > oraAdapter/conf/oraAdapter.conf.gb231280;
        --+SYSTEM @DB2 sed -e "s/ALTIBASE_PORT = 20090/ALTIBASE_PORT = ${ALTIBASE_PORT_NO@DB1}/g" -e "s/ALA_RECEIVER_PORT = 25090/ALA_RECEIVER_PORT = ${ALTIBASE_REPLICATION_PORT_NO}/g" conf/oraAdapter.conf.ksc5601utf16 > oraAdapter/conf/oraAdapter.conf.ksc5601utf16;
        --+SYSTEM @DB2 sed -e "s/ALTIBASE_PORT = 20090/ALTIBASE_PORT = ${ALTIBASE_PORT_NO@DB1}/g" -e "s/ALA_RECEIVER_PORT = 25090/ALA_RECEIVER_PORT = ${ALTIBASE_REPLICATION_PORT_NO}/g" conf/oraAdapter.conf.ms949        > oraAdapter/conf/oraAdapter.conf.ms949;
        --+SYSTEM @DB2 sed -e "s/ALTIBASE_PORT = 20090/ALTIBASE_PORT = ${ALTIBASE_PORT_NO@DB1}/g" -e "s/ALA_RECEIVER_PORT = 25090/ALA_RECEIVER_PORT = ${ALTIBASE_REPLICATION_PORT_NO}/g" conf/oraAdapter.conf.shiftjis     > oraAdapter/conf/oraAdapter.conf.shiftjis;
        --+SYSTEM @DB2 sed -e "s/ALTIBASE_PORT = 20090/ALTIBASE_PORT = ${ALTIBASE_PORT_NO@DB1}/g" -e "s/ALA_RECEIVER_PORT = 25090/ALA_RECEIVER_PORT = ${ALTIBASE_REPLICATION_PORT_NO}/g" conf/oraAdapter.conf.us7ascii     > oraAdapter/conf/oraAdapter.conf.us7ascii;
        --+SYSTEM @DB2 sed -e "s/ALTIBASE_PORT = 20090/ALTIBASE_PORT = ${ALTIBASE_PORT_NO@DB1}/g" -e "s/ALA_RECEIVER_PORT = 25090/ALA_RECEIVER_PORT = ${ALTIBASE_REPLICATION_PORT_NO}/g" conf/oraAdapter.conf.utf8utf8     > oraAdapter/conf/oraAdapter.conf.utf8utf8;

--+PWAIT;

