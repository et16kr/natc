--############################################################################
--# Replication Environment Setting
--############################################################################

--############################################################################
--# SET UP three DB System 
--############################################################################

--+DECLARE SERVER STRESS_REPL_SERVER1 DB1;
--+DECLARE SERVER STRESS_REPL_SERVER2 DB2;

--+DECLARE CLIENT DEFAULT P11 (SERVER=DB1);
--+DECLARE CLIENT DEFAULT P12 (SERVER=DB1);

--+DECLARE CLIENT DEFAULT P21 (SERVER=DB2);
--+DECLARE CLIENT DEFAULT P22 (SERVER=DB2);

--+SYSTEM rm -rf db1;
--+SYSTEM rm -rf db2;

--########################################
--+SECTOR; Set Up DB 1
--########################################

--+SYSTEM mkdir db1;
--+SYSTEM mkdir db1/bin;
--+SYSTEM mkdir db1/conf;
--+SYSTEM mkdir db1/msg;
--+SYSTEM mkdir db1/dbs;
--+SYSTEM mkdir db1/logs;
--+SYSTEM mkdir db1/trc;
--+SYSTEM mkdir db1/arch_logs;

--+SYSTEM cp $ATC_HOME/bin/clean                db1/bin;
--+SYSTEM cp $ATC_HOME/bin/createdb             db1/bin;
--+SYSTEM cp $ATC_HOME/bin/destroydb            db1/bin;
--+SYSTEM cp $ALTIBASE_HOME/bin/shmutil              db1/bin;
--+SYSTEM cp $ALTIBASE_HOME/bin/altibase             db1/bin;
--+SYSTEM cp $ALTIBASE_HOME/bin/server               db1/bin;
--+SYSTEM cp $ALTIBASE_HOME/bin/dbadmin              db1/bin;
--+SYSTEM cp $ALTIBASE_HOME/bin/isql                 db1/bin;
--+SYSTEM cp $ALTIBASE_HOME/bin/is                   db1/bin;
--+SYSTEM cp $ALTIBASE_HOME/bin/iloader              db1/bin;
--+SYSTEM cp $ALTIBASE_HOME/bin/il                   db1/bin;

--+SYSTEM cp $ALTIBASE_HOME/msg/*                    db1/msg;
--+SYSTEM cp $ALTIBASE_HOME/conf/altibase.properties db1/conf;
--+SYSTEM cp $ALTIBASE_HOME/conf/license             db1/conf;

--+SYSTEM @DB1 server kill;
--+SYSTEM @DB1 echo y | shmutil -e;
--+SYSTEM @DB1 echo y | destroydb -n mydb;
--+SYSTEM @DB1 echo y | createdb -M 10;

--+SYSTEM @DB1 server start;

--########################################
--+SECTOR; Set Up DB 2
--########################################

--+SYSTEM mkdir db2;
--+SYSTEM mkdir db2/bin;
--+SYSTEM mkdir db2/conf;
--+SYSTEM mkdir db2/msg;
--+SYSTEM mkdir db2/dbs;
--+SYSTEM mkdir db2/logs;
--+SYSTEM mkdir db2/trc;
--+SYSTEM mkdir db2/arch_logs;

--+SYSTEM cp $ATC_HOME/bin/clean                db2/bin;
--+SYSTEM cp $ATC_HOME/bin/createdb             db2/bin;
--+SYSTEM cp $ATC_HOME/bin/destroydb            db2/bin;
--+SYSTEM cp $ALTIBASE_HOME/bin/shmutil              db2/bin;
--+SYSTEM cp $ALTIBASE_HOME/bin/altibase             db2/bin;
--+SYSTEM cp $ALTIBASE_HOME/bin/server               db2/bin;
--+SYSTEM cp $ALTIBASE_HOME/bin/dbadmin              db2/bin;
--+SYSTEM cp $ALTIBASE_HOME/bin/isql                 db2/bin;
--+SYSTEM cp $ALTIBASE_HOME/bin/is                   db2/bin;
--+SYSTEM cp $ALTIBASE_HOME/bin/iloader              db2/bin;
--+SYSTEM cp $ALTIBASE_HOME/bin/il                   db2/bin;

--+SYSTEM cp $ALTIBASE_HOME/msg/*                    db2/msg;
--+SYSTEM cp $ALTIBASE_HOME/conf/altibase.properties db2/conf;
--+SYSTEM cp $ALTIBASE_HOME/conf/license             db2/conf;

--+SYSTEM @DB2 server kill;
--+SYSTEM @DB2 echo y | shmutil -e;
--+SYSTEM @DB2 echo y | destroydb -n mydb;
--+SYSTEM @DB2 echo y | createdb -s 10;

--+SYSTEM @DB2 server start;

