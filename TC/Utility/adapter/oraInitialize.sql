--############################################################################
--# oraAdapter Environment Setting
--############################################################################

--+DECLARE SERVER ORAADAPTER_SERVER1 DB1;
--+DECLARE SERVER ORAADAPTER_SERVER2 DB2;
--+DECLARE SERVER ORAADAPTER_SERVER3 DB3;

--+DECLARE CLIENT DEFAULT P1 (SERVER=DB1);
--+DECLARE CLIENT DEFAULT P2 (SERVER=DB2);
--+DECLARE CLIENT DEFAULT P3 (SERVER=DB3);

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

        --+SET_ENV @DB1 PATH=$ATC_HOME/scripts:$PATH;
        --+SYSTEM rm -rf Adapter;
        --+SYSTEM cp -r $ALTIDEV_HOME/ut/adapter/src/dist    Adapter;
        --+SYSTEM cp -f $ALTIDEV_HOME/ut/adapter/src/conf/oalogin.sql Adapter/conf/oalogin.sql;
        --+SYSTEM cp -f $ALTIDEV_HOME/ut/adapter/src/conf/ora_dbms_skip_error_include.list Adapter/conf/dbms_skip_error_include.list;
        --+SYSTEM cp -f $ALTIDEV_HOME/ut/adapter/src/conf/ora_dbms_skip_error_exclude.list Adapter/conf/dbms_skip_error_exclude.list;

        --+SYSTEM @DB2 sed -e "s/ALTIBASE_PORT = 20090/ALTIBASE_PORT = ${ALTIBASE_PORT_NO@DB1}/g" -e "s/ALA_RECEIVER_PORT = 25090/ALA_RECEIVER_PORT = ${ALTIBASE_REPLICATION_PORT_NO}/g" conf/oraAdapter.conf.big5         > Adapter/conf/oraAdapter.conf.big5;
        --+SYSTEM @DB2 sed -e "s/ALTIBASE_PORT = 20090/ALTIBASE_PORT = ${ALTIBASE_PORT_NO@DB1}/g" -e "s/ALA_RECEIVER_PORT = 25090/ALA_RECEIVER_PORT = ${ALTIBASE_REPLICATION_PORT_NO}/g" conf/oraAdapter.conf.eucjpNutf16  > Adapter/conf/oraAdapter.conf.eucjpNutf16;
        --+SYSTEM @DB2 sed -e "s/ALTIBASE_PORT = 20090/ALTIBASE_PORT = ${ALTIBASE_PORT_NO@DB1}/g" -e "s/ALA_RECEIVER_PORT = 25090/ALA_RECEIVER_PORT = ${ALTIBASE_REPLICATION_PORT_NO}/g" conf/oraAdapter.conf.gb231280     > Adapter/conf/oraAdapter.conf.gb231280;
        --+SYSTEM @DB2 sed -e "s/ALTIBASE_PORT = 20090/ALTIBASE_PORT = ${ALTIBASE_PORT_NO@DB1}/g" -e "s/ALA_RECEIVER_PORT = 25090/ALA_RECEIVER_PORT = ${ALTIBASE_REPLICATION_PORT_NO}/g" conf/oraAdapter.conf.ksc5601utf16 > Adapter/conf/oraAdapter.conf.ksc5601utf16;
        --+SYSTEM @DB2 sed -e "s/ALTIBASE_PORT = 20090/ALTIBASE_PORT = ${ALTIBASE_PORT_NO@DB1}/g" -e "s/ALA_RECEIVER_PORT = 25090/ALA_RECEIVER_PORT = ${ALTIBASE_REPLICATION_PORT_NO}/g" conf/oraAdapter.conf.ms949        > Adapter/conf/oraAdapter.conf.ms949;
        --+SYSTEM @DB2 sed -e "s/ALTIBASE_PORT = 20090/ALTIBASE_PORT = ${ALTIBASE_PORT_NO@DB1}/g" -e "s/ALA_RECEIVER_PORT = 25090/ALA_RECEIVER_PORT = ${ALTIBASE_REPLICATION_PORT_NO}/g" conf/oraAdapter.conf.shiftjis     > Adapter/conf/oraAdapter.conf.shiftjis;
        --+SYSTEM @DB2 sed -e "s/ALTIBASE_PORT = 20090/ALTIBASE_PORT = ${ALTIBASE_PORT_NO@DB1}/g" -e "s/ALA_RECEIVER_PORT = 25090/ALA_RECEIVER_PORT = ${ALTIBASE_REPLICATION_PORT_NO}/g" conf/oraAdapter.conf.us7ascii     > Adapter/conf/oraAdapter.conf.us7ascii;
        --+SYSTEM @DB2 sed -e "s/ALTIBASE_PORT = 20090/ALTIBASE_PORT = ${ALTIBASE_PORT_NO@DB1}/g" -e "s/ALA_RECEIVER_PORT = 25090/ALA_RECEIVER_PORT = ${ALTIBASE_REPLICATION_PORT_NO}/g" conf/oraAdapter.conf.utf8utf8     > Adapter/conf/oraAdapter.conf.utf8utf8;
        --+SYSTEM @DB2 sed -e "s/ALTIBASE_PORT = 20090/ALTIBASE_PORT = ${ALTIBASE_PORT_NO@DB1}/g" -e "s/ALA_RECEIVER_PORT = 25090/ALA_RECEIVER_PORT = ${ALTIBASE_REPLICATION_PORT_NO}/g" conf/oraAdapter.conf.passwd     > Adapter/conf/oraAdapter.conf.passwd;
        --+SYSTEM @DB2 sed -e "s/ORACLE_SERVER_ALIAS =/ORACLE_SERVER_ALIAS = ksc5601utf16_server/g" -e "s/ALTIBASE_USER = guest/ALTIBASE_USER = sys/g" -e "s/ALTIBASE_PASSWORD = guest/ALTIBASE_PASSWORD = manager/g" -e "s/ALTIBASE_PORT = 20300/ALTIBASE_PORT = ${ALTIBASE_PORT_NO@DB1}/g" -e "s/ALA_RECEIVER_PORT = 25090/ALA_RECEIVER_PORT = ${ALTIBASE_REPLICATION_PORT_NO}/g" $ALTIDEV_HOME/ut/adapter/src/dist/conf/oraAdapter.conf    > Adapter/conf/oraAdapter.conf.org;
        
            --+PROCESS P3;
        
            --########################################
            --# Set Up ALTIBASE
            --########################################   
        
            --+SET_ENV @DB3 PATH=$ATC_HOME/scripts:$PATH;
            --+SET_ENV @DB3 ALTIBASE_REPLICATION_LOCK_TIMEOUT=30;
            --+SYSTEM rm -rf db3;

            --+SYSTEM mkdir db3;
            --+SYSTEM cp -r $ALTIBASE_HOME/bin                      db3/bin;
            --+SYSTEM cp -r $ALTIBASE_HOME/msg                      db3/msg;
            --+SYSTEM cp -r $ALTIBASE_HOME/lib                      db3/lib;

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
            --+SYSTEM @DB3 echo y | createdb -M 10 ksc5601 utf16;
            --+SET_ENV @DB3 ALTIBASE_NLS_USE=KSC5601;
            --+SYSTEM @DB3 server start;
--+PWAIT;

