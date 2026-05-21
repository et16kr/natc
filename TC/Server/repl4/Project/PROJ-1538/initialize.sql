--########################################################
--# PROJ-1538 IPV6 Support
--########################################################

--+DECLARE SERVER REPL_SERVER1 DB1;
--+DECLARE SERVER REPL_SERVER2 DB2;

--+DECLARE CLIENT DEFAULT P1 (SERVER=DB1);
--+DECLARE CLIENT DEFAULT P2 (SERVER=DB2);

--########################################################
--+SECTOR; PREPARATION
--########################################################
    
    --+PROCESS P1;
    --+SYSTEM @DB1 server kill;
    --+SET_ENV @DB1 ALTIBASE_NET_CONN_IP_STACK=0;
    --+SYSTEM @DB1 server start;

        --+PROCESS P2;
        --+SYSTEM @DB2 server kill;
        --+SET_ENV @DB2 ALTIBASE_NET_CONN_IP_STACK=0;
        --+SYSTEM @DB2 server start;

--+PWAIT;
