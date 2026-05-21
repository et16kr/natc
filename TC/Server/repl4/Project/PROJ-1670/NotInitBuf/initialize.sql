--##########################################################################
--# ACTIVE-STANDBY REPLICATION START
--##########################################################################

--##########################################################################
--# PROJ-1670 INIT 
--##########################################################################

--+DECLARE SERVER REPL_SERVER1 DB1;

--+DECLARE CLIENT DEFAULT P1 (SERVER=DB1);

    --+PROCESS P1;
    --+SYSTEM @DB1 server stop;
    --+SET_ENV @DB1 ALTIBASE_REPLICATION_LOG_BUFFER_SIZE=0;
    --+SYSTEM @DB1 server start;

    SELECT NAME, VALUE1 FROM V$PROPERTY WHERE NAME='REPLICATION_LOG_BUFFER_SIZE';

--+PWAIT;

