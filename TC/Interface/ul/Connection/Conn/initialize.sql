--############################################################################
--# Replication Environment Setting
--############################################################################

--############################################################################
--# SET UP three DB System 
--############################################################################

--+DECLARE SERVER CLI_SERVER1 DB1;
--+DECLARE SERVER CLI_SERVER2 DB2;
--+SYSTEM server kill;
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

--+SYSTEM cp $ALTIBASE_HOME/bin/*                    db1/bin;

--+SYSTEM cp $ALTIBASE_HOME/msg/*                    db1/msg;
--+SYSTEM cp $ALTIBASE_HOME/conf/altibase.properties db1/conf;
--+SYSTEM cp $ALTIBASE_HOME/conf/license             db1/conf;
--+SYSTEM cp $ALTIBASE_HOME/conf/syspassword         db1/conf;

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

--+SYSTEM cp $ALTIBASE_HOME/bin/*                    db2/bin;

--+SYSTEM cp $ALTIBASE_HOME/msg/*                    db2/msg;
--+SYSTEM cp $ALTIBASE_HOME/conf/altibase.properties db2/conf;
--+SYSTEM cp $ALTIBASE_HOME/conf/syspassword         db2/conf;
--+SYSTEM cp $ALTIBASE_HOME/conf/license             db2/conf;

--+SYSTEM @DB2 server kill;
--+SYSTEM @DB2 echo y | shmutil -e;
--+SYSTEM @DB2 echo y | destroydb -n mydb;
--+SYSTEM @DB2 echo y | createdb -M 10;

--+SYSTEM @DB2 server start;

