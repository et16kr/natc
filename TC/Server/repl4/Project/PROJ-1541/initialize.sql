--############################################################################
--# Replication Environment Setting
--############################################################################

--############################################################################
--# SET UP three DB System 
--############################################################################

--+DECLARE SERVER REPL_SERVER1 DB1;
--+DECLARE SERVER REPL_SERVER2 DB2;

--+DECLARE CLIENT DEFAULT P21 (SERVER=DB2);

--+SET_ENV PATH=$ATC_HOME/scripts:$PATH;


--########################################################
--+SECTOR; SERVER KILL & START
--########################################################

        --+PROCESS P21;

        --########################################
        --+SECTOR; KILL & START DB 2
        --########################################
        --+SET_ENV @DB2 ALTIBASE_REPLICATION_LOCK_TIMEOUT=4;
        --+SYSTEM @DB2 server stop;
        --+SYSTEM @DB2 server start;

--+PWAIT;
