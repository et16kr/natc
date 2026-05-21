--##########################################################################
--# ACTIVE-STANDBY REPLICATION START
--##########################################################################

--##########################################################################
--# BEFORE TEST
--##########################################################################

--########################################################
--+SECTOR; PREPARATION
--########################################################

--+DECLARE SERVER COMPATI_REPL_SERVER1_HDB DB1;
--+DECLARE SERVER COMPATI_REPL_SERVER2_XDB DB2;

--+DECLARE CLIENT DEFAULT P3 (SERVER=DB2);

    --+PROCESS P3;

    --###################################
    --# ON STANDBY SYSTEM
    --###################################
    --+SYSTEM @DB2 xdbserver kill;
    --+SET_ENV @DB2 ALTIBASE_XDB_REPLICATION_LOCK_TIMEOUT=10;
    --+SYSTEM @DB2 xdbserver start;

--+PWAIT;
