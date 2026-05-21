--############################################################################
--# SET UP three DB System 
--############################################################################

--+DECLARE SERVER REPL_SERVER1 DB1;
--+DECLARE SERVER REPL_SERVER2 DB2;
--+DECLARE SERVER REPL_SERVER3 DB3;

--+SYSTEM @DB2 server stop;
--+SYSTEM @DB2 echo y | shmutil -e;
 

