
NODISPLAY ON;
$gStdIsqlSys = "${ALTIBASE_HOME}/bin/isql -silent -u sys -p MANAGER -sysdba -noprompt -ataf";
$gStdIsql = "${ALTIBASE_HOME}/bin/isql -s localhost -u sys -p MANAGER -silent -noprompt -ataf";
NODISPLAY OFF;

DEF stdClean()
{
    IF ( IS_CLUSTER )
    {
        PRINT "It is on cluster mode";
        # cluster mode라면 모든 서버에 대해서 실행해주기
        FOR $sServerAlias in SERVER_IN_CLUSTER
        {
            THREAD T1 $sServerAlias
            {
                CALL stdCleanForOneServer();
            }

            JOIN;
        }
    }
    ELSE
    {
        CALL stdCleanForOneServer();
    }
}

DEF stdServerStart()
{
    IF ( IS_CLUSTER )
    {
        PRINT "It is on cluster mode";
        # cluster mode라면 모든 서버에 대해서 실행해주기
        FOR $sServerAlias in SERVER_IN_CLUSTER
        {
            THREAD T1 $sServerAlias
            {
                CALL stdServerStartForOneServer();
            }

            JOIN;
        }

        # 모두 server start 했다면 CLUSTER 연결 쿼리 날려주기
        FOR $sServerAlias in SERVER_IN_CLUSTER
        {
            THREAD T1 $sServerAlias
            {
                CALL stdConnectCluster();
            }

            JOIN;
        }
    }
    ELSE
    {
        CALL stdServerStartForOneServer();
    }
}

DEF stdServerKill()
{
    IF ( IS_CLUSTER )
    {
        # cluster mode라면 모든 서버에 대해서 실행해주기
        FOR $sServerAlias in SERVER_IN_CLUSTER
        {
            THREAD T1 $sServerAlias
            {
                CALL stdServerKillForOneServer();
            }

            JOIN;
        }
    }
    ELSE
    {
        CALL stdServerKillForOneServer();
    }
}

DEF stdServerStop()
{
    IF ( IS_CLUSTER )
    {
        # cluster mode라면 모든 서버에 대해서 실행해주기
        FOR $sServerAlias in SERVER_IN_CLUSTER
        {
            THREAD T1 $sServerAlias
            {
                CALL stdServerStopForOneServer();
            }

            JOIN;
        }
    }
    ELSE
    {
        CALL stdServerStopForOneServer();
    }
}

DEF stdServerCreate( @aCharSet, @aNCharSet )
{
    IF ( IS_CLUSTER )
    {
        # cluster mode라면 모든 서버에 대해서 실행해주기
        FOR $sServerAlias in SERVER_IN_CLUSTER
        {
            THREAD T1 $sServerAlias
            {
                CALL stdServerCreateForOneServer( @aCharSet, @aNCharSet );
            }

            JOIN;
        }
    }
    ELSE
    {
        CALL stdServerCreateForOneServer( @aCharSet, @aNCharSet );
    }
}

DEF stdServerRestart()
{
    IF ( IS_CLUSTER )
    {
        # cluster mode라면 모든 서버에 대해서 실행해주기
        FOR $sServerAlias in SERVER_IN_CLUSTER
        {
            THREAD T1 $sServerAlias
            {
                CALL stdServerRestartForOneServer();
            }

            JOIN;
        }

        # 모두 server restart 했다면 CLUSTER 연결 쿼리 날려주기
        FOR $sServerAlias in SERVER_IN_CLUSTER
        {
            THREAD T1 $sServerAlias
            {
                CALL stdConnectCluster();
            }

            JOIN;
        }
    }
    ELSE
    {
        CALL stdServerRestartForOneServer();
    }
}

DEF stdDestroydb( @aDBName )
{
    IF ( IS_CLUSTER )
    {
        # cluster mode라면 모든 서버에 대해서 실행해주기
        FOR $sServerAlias in SERVER_IN_CLUSTER
        {
            THREAD T1 $sServerAlias
            {
                CALL stdDestroydbForOneServer( @aDBName );
            }

            JOIN;
        }
    }
    ELSE
    {
        CALL stdDestroydbForOneServer( @aDBName );
    }
}

DEF stdCreatedb( @aDBName, @aDBSize, @aDBCharSet, @aNCharSet )
{
    IF ( IS_CLUSTER )
    {
        # cluster mode라면 모든 서버에 대해서 실행해주기
        FOR $sServerAlias in SERVER_IN_CLUSTER
        {
            THREAD T1 $sServerAlias
            {
                CALL stdCreatedbForOneServer( @aDBName, @aDBSize, @aDBCharSet, @aNCharSet );
            }

            JOIN;
        }
    }
    ELSE
    {
        CALL stdCreatedbForOneServer( @aDBName, @aDBSize, @aDBCharSet, @aNCharSet );
    }
}

DEF stdCleanForOneServer()
{
    #ipcrm.sh : not work. check shared memory, do not remove shared memeory

    #${ATC_HOME}/bin/destroydb -n mydb : drop database and remove logs, arch_logs, dbs
    CALL stdDestroydbForOneServer( "mydb" );
    
    #echo 'y' | ${ATC_HOME}/bin/createdb -M 4 $1 $2
    CALL stdCreatedbForOneServer( "mydb", 4, "KO16KSC5601", "UTF16");
}

DEF stdServerStartForOneServer()
{
    #get unique process name for multithread;
    #get unique process number;
    RAND $sProcNum 10000;
    $sProcName = "P" || $sProcNum;

    POUT_LOG ON;

    $ALTIBASE_HOME;

    # for windows
    if ( FEXIST "${ALTIBASE_HOME}/bin/chkFileLock" )
    {
        EXEC $sProcName "chkFileLock";
        P_WAIT $sProcName;
    }
    else
    {
        # DO NOTHING
    }

    EXEC $sProcName -t 1800 $gStdIsqlSys;

    SEND $sProcName "startup";

    SEND $sProcName "quit";

    --# Waiting Process Termination
    P_WAIT $sProcName;

    POUT_LOG OFF;
}

DEF stdServerKillForOneServer()
{
    #get unique process name for multithread;
    #get unique process number;
    RAND $sProcNum 10000;
    $sProcName = "P" || $sProcNum;

    POUT_LOG ON;

    $ALTIBASE_HOME;

    EXEC $sProcName -t 1800 $gStdIsqlSys;

    SEND $sProcName "shutdown abort";

    SEND $sProcName "quit";

    --# Waiting Process Termination
    P_WAIT $sProcName;

    POUT_LOG OFF;
}

DEF stdServerStopForOneServer()
{
    #get unique process name for multithread;
    #get unique process number;
    RAND $sProcNum 10000;
    $sProcName = "P" || $sProcNum;
    $sProcName2 = "KILL" || $sProcName;

    POUT_LOG ON;

    $ALTIBASE_HOME;

    EXEC $sProcName -t 1800 $gStdIsqlSys;

    SEND $sProcName "ALTER SYSTEM SET CHECKPOINT_BULK_WRITE_PAGE_COUNT = 0;";

    SEND $sProcName "ALTER SYSTEM SET CHECKPOINT_BULK_WRITE_SLEEP_SEC  = 0;";

    SEND $sProcName "ALTER SYSTEM SET CHECKPOINT_BULK_WRITE_SLEEP_USEC = 0;";

    --# kill the CheckServer
    EXEC $sProcName2 "killCheckServer";
    P_WAIT $sProcName2;

    SEND $sProcName "shutdown immediate";

    SEND $sProcName "quit";

    --# Waiting Process Termination
    P_WAIT $sProcName;

    POUT_LOG OFF;
}

DEF stdServerCreateForOneServer( @aCharSet, @aNCharSet )
{
    #get unique process name for multithread;
    #get unique process number;
    RAND $sProcNum 10000;
    $sProcName = "P" || $sProcNum;

    POUT_LOG ON;

    $ALTIBASE_HOME;

    --# stdDestroydb check whether server is running
    CALL stdDestroydbForOneServer( "mydb" );

    --# Server is not running
    EXEC $sProcName -t 1800 $gStdIsqlSys;

    SEND $sProcName "startup process";

    SEND $sProcName "create database mydb INITSIZE=10M noarchivelog character set @{aCharSet} national character set @{aNCharSet};";

    SEND $sProcName "ALTER SYSTEM SET CHECKPOINT_BULK_WRITE_PAGE_COUNT = 0;";

    SEND $sProcName "ALTER SYSTEM SET CHECKPOINT_BULK_WRITE_SLEEP_SEC  = 0;";

    SEND $sProcName "ALTER SYSTEM SET CHECKPOINT_BULK_WRITE_SLEEP_USEC = 0;";

    SEND $sProcName "shutdown abort";

    SEND $sProcName "quit";

    --# Waiting Process Termination
    P_WAIT $sProcName;

    POUT_LOG OFF;
}

DEF stdServerRestartForOneServer()
{
    #get unique process name for multithread;
    #get unique process number;
    RAND $sProcNum 10000;
    $sProcName = "P" || $sProcNum;

    POUT_LOG ON;

    $ALTIBASE_HOME;

    EXEC $sProcName -t 1800 $gStdIsqlSys;

    SEND $sProcName "ALTER SYSTEM SET CHECKPOINT_BULK_WRITE_PAGE_COUNT = 0;";

    SEND $sProcName "ALTER SYSTEM SET CHECKPOINT_BULK_WRITE_SLEEP_SEC  = 0;";

    SEND $sProcName "ALTER SYSTEM SET CHECKPOINT_BULK_WRITE_SLEEP_USEC = 0;";

    SEND $sProcName "shutdown immediate";

    SEND $sProcName "startup";

    SEND $sProcName "quit";
    --# Waiting Process Termination
    P_WAIT $sProcName;

    POUT_LOG OFF;
}

DEF stdDestroydbForOneServer( @aDBName )
{
    #get unique process name for multithread;
    #get unique process number;
    RAND $sProcNum 10000;
    $sProcName = "P" || $sProcNum;

    POUT_LOG ON;

    $ALTIBASE_HOME;

    --# Check Server Alive
    EXEC $sProcName -t 1800 $gStdIsql;
    SEND $sProcName "spool live-altibase.txt;";
    P_WAIT $sProcName -t 10 "ERR";
    $stdRet = $Ret_;

    if ( $stdRet == "" )
    {
        --# If spool is success, Server is alive
        SEND $sProcName "quit";
        P_WAIT $sProcName; 

        --# Remove live-altibase.txt
        RM -f "live-altibase.txt";

        --# shutdown server
        EXEC $sProcName -t 1800 $gStdIsqlSys;
        SEND $sProcName "shutdown abort";

        SEND $sProcName "quit";
        P_WAIT $sProcName;
    }
    else
    {
        # DO NOTHING
        P_WAIT $sProcName; 
    }

    EXEC $sProcName -t 1800 $gStdIsqlSys;

    SEND $sProcName "startup process";

    SEND $sProcName "drop database @{aDBName};";

    SEND $sProcName "shutdown abort";

    SEND $sProcName "quit";

    P_WAIT $sProcName;

    RM -rf "${ALTIBASE_HOME}/dbs/*";
    RM -rf "${ALTIBASE_HOME}/logs/*";
    RM -rf "${ALTIBASE_HOME}/arch_logs/*";

    # for LFG
    $i = 0;
    LOOP 32
    {
        if ( FEXIST "${ALTIBASE_HOME}/logs${i}" )
        {
            RM -rf "${ALTIBASE_HOME}/logs${i}/*";
        }
        ELSE
        {
            # DO NOTHING
        }

        if ( FEXIST "${ALTIBASE_HOME}/arch_logs${i}" )
        {
            RM -rf "${ALTIBASE_HOME}/arch_logs${i}/*";
        }
        ELSE
        {
            # DO NOTHING
        }

        $i = $i + 1;
    }

    POUT_LOG OFF;
}

DEF stdCreatedbForOneServer( @aDBName, @aDBSize, @aDBCharSet, @aNCharSet )
{
    #get unique process name for multithread;
    #get unique process number;
    RAND $sProcNum 10000;
    $sProcName = "P" || $sProcNum;

    POUT_LOG ON;

    $ALTIBASE_HOME;

    # for align 4M
    $sDBSize = @aDBSize / 4 * 4;

    EXEC $sProcName -t 1800 $gStdIsqlSys;

    SEND $sProcName "startup process";

    SEND $sProcName "create database @{aDBName} INITSIZE=${sDBSize}M noarchivelog character set @{aDBCharSet} national character set @{aNCharSet};";

    SEND $sProcName "shutdown abort";

    SEND $sProcName "quit";

    P_WAIT $sProcName;

    POUT_LOG OFF;
}

DEF stdConnectCluster()
{
    #get unique process name for multithread;
    #get unique process number;
    RAND $sProcNum 10000;
    $sProcName = "P" || $sProcNum;

    POUT_LOG ON;

    $ALTIBASE_HOME;

    EXEC $sProcName -t 1800 $gStdIsqlSys;

    SEND $sProcName "ALTER SYSTEM CONNECT CLUSTER;";

    SEND $sProcName "quit";

    --# Waiting Process Termination
    P_WAIT $sProcName;

    POUT_LOG OFF;
}

DEF stdDisconnectCluster()
{
    #get unique process name for multithread;
    #get unique process number;
    RAND $sProcNum 10000;
    $sProcName = "P" || $sProcNum;

    POUT_LOG ON;

    $ALTIBASE_HOME;

    EXEC $sProcName -t 1800 $gStdIsqlSys;

    SEND $sProcName "ALTER SYSTEM DISCONNECT CLUSTER;";

    SEND $sProcName "quit";

    --# Waiting Process Termination
    P_WAIT $sProcName;

    POUT_LOG OFF;
}
