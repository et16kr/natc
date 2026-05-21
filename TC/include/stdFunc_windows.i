
NODISPLAY ON;
$gStdIsqlSys = "${ALTIBASE_HOME}/bin/isql -silent -u sys -p MANAGER -sysdba -noprompt -ataf";
$gStdIsql = "${ALTIBASE_HOME}/bin/isql -s localhost -u sys -p MANAGER -silent -noprompt -ataf";
NODISPLAY OFF;

DEF stdClean()
{
    #ipcrm.sh : not work. check shared memory, do not remove shared memeory

    #${ATC_HOME}/bin/destroydb -n mydb : drop database and remove logs, arch_logs, dbs
    CALL stdDestroydb( "mydb" );
    
    #echo 'y' | ${ATC_HOME}/bin/createdb -M 4 $1 $2
    CALL stdCreatedb( "mydb", 4, "KO16KSC5601", "UTF16");
}

DEF stdServerStart()
{
    #get unique process name for multithread;
    #get unique process number;
    RAND $sProcNum 10000;
    $sProcName = "P" || $sProcNum;

    $ALTIBASE_HOME;
    $sPrompt = "$$EOF$$";

    $OS_NAME;

    # for windows
    if ( $OS_NAME == "win32" )
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
    P_WAIT $sProcName $sPrompt;

    SEND $sProcName "quit";

    --# Waiting Process Termination
    P_WAIT $sProcName;
}

DEF stdServerKill()
{
    #get unique process name for multithread;
    #get unique process number;
    RAND $sProcNum 10000;
    $sProcName = "P" || $sProcNum;

    $ALTIBASE_HOME;

    EXEC $sProcName -t 1800 $gStdIsqlSys;

    SEND $sProcName "shutdown abort";

    SEND $sProcName "quit";

    --# Waiting Process Termination
    P_WAIT $sProcName;
}

DEF stdServerStop()
{
    #get unique process name for multithread;
    #get unique process number;
    RAND $sProcNum 10000;
    $sProcName = "P" || $sProcNum;
    $sProcName2 = "KILL" || $sProcName;

    $ALTIBASE_HOME;
    $sPrompt = "$$EOF$$";

    EXEC $sProcName -t 1800 $gStdIsqlSys;

    SEND $sProcName "ALTER SYSTEM SET CHECKPOINT_BULK_WRITE_PAGE_COUNT = 0;";
    P_WAIT $sProcName $sPrompt;

    SEND $sProcName "ALTER SYSTEM SET CHECKPOINT_BULK_WRITE_SLEEP_SEC  = 0;";
    P_WAIT $sProcName $sPrompt;

    SEND $sProcName "ALTER SYSTEM SET CHECKPOINT_BULK_WRITE_SLEEP_USEC = 0;";
    P_WAIT $sProcName $sPrompt;

    --# kill the CheckServer
    EXEC $sProcName2 "killCheckServer";
    P_WAIT $sProcName2;

    SEND $sProcName "shutdown immediate";
    P_WAIT $sProcName $sPrompt;

    SEND $sProcName "quit";

    --# Waiting Process Termination
    P_WAIT $sProcName;
}

DEF stdServerCreate( @aCharSet, @aNCharSet )
{
    #get unique process name for multithread;
    #get unique process number;
    RAND $sProcNum 10000;
    $sProcName = "P" || $sProcNum;

    $ALTIBASE_HOME;
    $sPrompt = "$$EOF$$";

    --# stdDestroydb check whether server is running
    CALL stdDestroydb( "mydb" );

    --# Server is not running
    EXEC $sProcName -t 1800 $gStdIsqlSys;

    SEND $sProcName "startup process";
    P_WAIT $sProcName $sPrompt;

    SEND $sProcName "create database mydb INITSIZE=10M noarchivelog character set @{aCharSet} national character set @{aNCharSet};";
    P_WAIT $sProcName $sPrompt;

    SEND $sProcName "ALTER SYSTEM SET CHECKPOINT_BULK_WRITE_PAGE_COUNT = 0;";
    P_WAIT $sProcName $sPrompt;

    SEND $sProcName "ALTER SYSTEM SET CHECKPOINT_BULK_WRITE_SLEEP_SEC  = 0;";
    P_WAIT $sProcName $sPrompt;

    SEND $sProcName "ALTER SYSTEM SET CHECKPOINT_BULK_WRITE_SLEEP_USEC = 0;";
    P_WAIT $sProcName $sPrompt;

    SEND $sProcName "shutdown abort";
    P_WAIT $sProcName $sPrompt;

    SEND $sProcName "quit";

    --# Waiting Process Termination
    P_WAIT $sProcName;
}

DEF stdServerRestart()
{
    #get unique process name for multithread;
    #get unique process number;
    RAND $sProcNum 10000;
    $sProcName = "P" || $sProcNum;

    $ALTIBASE_HOME;
    $sPrompt = "$$EOF$$";

    EXEC $sProcName -t 1800 $gStdIsqlSys;

    SEND $sProcName "ALTER SYSTEM SET CHECKPOINT_BULK_WRITE_PAGE_COUNT = 0;";
    P_WAIT $sProcName $sPrompt;

    SEND $sProcName "ALTER SYSTEM SET CHECKPOINT_BULK_WRITE_SLEEP_SEC  = 0;";
    P_WAIT $sProcName $sPrompt;

    SEND $sProcName "ALTER SYSTEM SET CHECKPOINT_BULK_WRITE_SLEEP_USEC = 0;";
    P_WAIT $sProcName $sPrompt;

    SEND $sProcName "shutdown immediate";
    P_WAIT $sProcName $sPrompt;

    SEND $sProcName "startup";
    P_WAIT $sProcName $sPrompt;

    SEND $sProcName "quit";

    --# Waiting Process Termination
    P_WAIT $sProcName;
}

DEF stdDestroydb( @aDBName )
{
    #get unique process name for multithread;
    #get unique process number;
    RAND $sProcNum 10000;
    $sProcName = "P" || $sProcNum;

    $ALTIBASE_HOME;
    $sPrompt = "$$EOF$$";

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
        P_WAIT $sProcName $sPrompt;

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
    P_WAIT $sProcName $sPrompt;

    SEND $sProcName "drop database @{aDBName};";
    P_WAIT $sProcName $sPrompt;

    SEND $sProcName "shutdown abort";
    P_WAIT $sProcName $sPrompt;

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
}

DEF stdCreatedb( @aDBName, @aDBSize, @aDBCharSet, @aNCharSet )
{
    #get unique process name for multithread;
    #get unique process number;
    RAND $sProcNum 10000;
    $sProcName = "P" || $sProcNum;

    $ALTIBASE_HOME;
    $sPrompt = "$$EOF$$";

    # for align 4M
    $sDBSize = @aDBSize / 4 * 4;

    EXEC $sProcName -t 1800 $gStdIsqlSys;

    SEND $sProcName "startup process";
    P_WAIT $sProcName $sPrompt;

    SEND $sProcName "create database @{aDBName} INITSIZE=${sDBSize}M noarchivelog character set @{aDBCharSet} national character set @{aNCharSet};";
    P_WAIT $sProcName $sPrompt;


    SEND $sProcName "shutdown abort";
    P_WAIT $sProcName $sPrompt;

    SEND $sProcName "quit";

    P_WAIT $sProcName;
}
