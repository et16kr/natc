--############################################################################
--# Audit Environment Setting
--############################################################################

--############################################################################
--# SET UP 1 DB System 
--############################################################################

--+DECLARE SERVER HG_REPL_SYNC_LOG_SERVER1 DB1;
--+DECLARE SERVER HG_REPL_SERVER2 DB2;

--+SYSTEM rm -rf ../../../db4;

--########################################
--+SECTOR; Set Up DB 1
--########################################

--+SYSTEM mkdir ../../../db4;
--+SYSTEM mkdir ../../../db4/bin;
--+SYSTEM mkdir ../../../db4/conf;
--+SYSTEM mkdir ../../../db4/msg;
--+SYSTEM mkdir ../../../db4/dbs;
--+SYSTEM mkdir ../../../db4/logs;
--+SYSTEM mkdir ../../../db4/trc;

--+SYSTEM cp $ALTIBASE_HOME/bin/clean                ../../../db4/bin;
--+SYSTEM cp $ALTIBASE_HOME/bin/createdb             ../../../db4/bin;
--+SYSTEM cp $ALTIBASE_HOME/bin/destroydb            ../../../db4/bin;
--+SYSTEM cp $ALTIBASE_HOME/bin/shmutil              ../../../db4/bin;
--+SYSTEM cp $ALTIBASE_HOME/bin/altibase             ../../../db4/bin;
--+SYSTEM cp $ALTIBASE_HOME/bin/server               ../../../db4/bin;
--+SYSTEM cp $ALTIBASE_HOME/bin/dbadmin              ../../../db4/bin;
--+SYSTEM cp $ALTIBASE_HOME/bin/isql                 ../../../db4/bin;
--+SYSTEM cp $ALTIBASE_HOME/bin/is                   ../../../db4/bin;
--+SYSTEM cp $ALTIBASE_HOME/bin/iloader              ../../../db4/bin;
--+SYSTEM cp $ALTIBASE_HOME/bin/il                   ../../../db4/bin;
--+SYSTEM cp $ALTIBASE_HOME/bin/altiComp             ../../../db4/bin;

--+SYSTEM cp $ALTIBASE_HOME/msg/*                    ../../../db4/msg;
--+SYSTEM cp $ALTIBASE_HOME/conf/altibase.properties ../../../db4/conf;
--+SYSTEM cp $ALTIBASE_HOME/conf/license             ../../../db4/conf;

--+SYSTEM @DB1 server kill;
--+SYSTEM @DB1 echo y | shmutil -e;
--+SYSTEM @DB1 echo y | destroydb -n $ALTIBASE_DB_NAME;
--+SYSTEM @DB1 echo y | createdb -M 10;

--+SYSTEM @DB1 server start;
