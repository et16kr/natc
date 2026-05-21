--############################################################################
--# Replication Environment Setting
--############################################################################

--############################################################################
--# SET UP 2 DB System 
--############################################################################

--+DECLARE SERVER HG_REPL_SERVER1 DB1;
--+DECLARE SERVER HG_REPL_SERVER2 DB2;

--+DECLARE CLIENT DEFAULT P11 (SERVER=DB1);
--+DECLARE CLIENT DEFAULT P12 (SERVER=DB1);

--+DECLARE CLIENT DEFAULT P21 (SERVER=DB2);
--+DECLARE CLIENT DEFAULT P22 (SERVER=DB2);

--########################################
--+SECTOR; Set Up DB 1
--########################################

--+SYSTEM @DB1 server kill;
--+SYSTEM @DB1 echo y | shmutil -e;
--+SYSTEM @DB1 echo y | destroydb -n mydb;
--+SYSTEM @DB1 echo y | createdb -M 10;

--+SYSTEM @DB1 server start;

--########################################
--+SECTOR; Set Up DB 2
--########################################

--+SYSTEM @DB2 server kill;
--+SYSTEM @DB2 echo y | shmutil -e;
--+SYSTEM @DB2 echo y | destroydb -n mydb;
--+SYSTEM @DB2 echo y | createdb -M 10;

--+SYSTEM @DB2 server start;
