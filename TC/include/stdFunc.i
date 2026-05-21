
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
    $sFileName = "F" || $sProcNum;

    #Open Log File
    OPEN $sFileName -m a "Altibase.log";
    WRITE $sFileName "\n\n\n##############################\n";
    WRITE $sFileName "#   CALL stdServerStart()    #\n";
    WRITE $sFileName "##############################\n";
    WRITE $sFileName "PROCESS NAME : ${sProcName}\n\n";

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

    $sRet = "";
    $sRet = $sRet || "iSQL> startup\n";
    $sRet = $sRet || $Ret_;

    WRITE $sFileName $sRet;

    SEND $sProcName "quit";

    $sRet = "iSQL> quit\n";
    WRITE $sFileName $sRet;

    CLOSE $sFileName;

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
    $sFileName = "F" || $sProcNum;

    #Open Log File
    OPEN $sFileName -m a "Altibase.log";
    WRITE $sFileName "\n\n\n##############################\n";
    WRITE $sFileName "#   CALL stdServerStop()     #\n";
    WRITE $sFileName "##############################\n";
    WRITE $sFileName "PROCESS NAME : ${sProcName}\n\n";

    $ALTIBASE_HOME;
    $sPrompt = "$$EOF$$";

    EXEC $sProcName -t 1800 $gStdIsqlSys;

    SEND $sProcName "ALTER SYSTEM SET CHECKPOINT_BULK_WRITE_PAGE_COUNT = 0;";
    P_WAIT $sProcName $sPrompt;

    $sRet = "";
    $sRet = $sRet || "iSQL> ALTER SYSTEM SET CHECKPOINT_BULK_WRITE_PAGE_COUNT = 0;\n";
    $sRet = $sRet || $Ret_;

    WRITE $sFileName $sRet;

    SEND $sProcName "ALTER SYSTEM SET CHECKPOINT_BULK_WRITE_SLEEP_SEC  = 0;";
    P_WAIT $sProcName $sPrompt;

    $sRet = "";
    $sRet = $sRet || "iSQL> ALTER SYSTEM SET CHECKPOINT_BULK_WRITE_SLEEP_SEC  = 0;\n";
    $sRet = $sRet || $Ret_;

    WRITE $sFileName $sRet;

    SEND $sProcName "ALTER SYSTEM SET CHECKPOINT_BULK_WRITE_SLEEP_USEC = 0;";
    P_WAIT $sProcName $sPrompt;

    $sRet = "";
    $sRet = $sRet || "iSQL> ALTER SYSTEM SET CHECKPOINT_BULK_WRITE_SLEEP_USEC = 0;\n";
    $sRet = $sRet || $Ret_;

    WRITE $sFileName $sRet;

    --# kill the CheckServer
    EXEC $sProcName2 "killCheckServer";
    P_WAIT $sProcName2;

    SEND $sProcName "shutdown immediate";
    P_WAIT $sProcName $sPrompt;

    $sRet = "";
    $sRet = $sRet || "iSQL> shutdown immediate\n";
    $sRet = $sRet || $Ret_;

    WRITE $sFileName $sRet;

    SEND $sProcName "quit";

    $sRet = "";
    $sRet = $sRet || "iSQL> quit\n";

    WRITE $sFileName $sRet;
    CLOSE $sFileName;

    --# Waiting Process Termination
    P_WAIT $sProcName;
}

DEF stdServerCreate( @aCharSet, @aNCharSet )
{
    #get unique process name for multithread;
    #get unique process number;
    RAND $sProcNum 10000;
    $sProcName = "P" || $sProcNum;
    $sFileName = "F" || $sProcNum;

    #Open Log File
    OPEN $sFileName -m a "Altibase.log";
    WRITE $sFileName "\n\n\n##############################\n";
    WRITE $sFileName "#   CALL stdServerCreate()   #\n";
    WRITE $sFileName "##############################\n";
    WRITE $sFileName "PROCESS NAME : ${sProcName}\n\n";

    $ALTIBASE_HOME;
    $sPrompt = "$$EOF$$";

    # fix BUG-37508
    WRITE $sFileName "# Destroy database before create database";
    CLOSE $sFileName;

    --# stdDestroydb check whether server is running
    CALL stdDestroydb( "mydb" );
    OPEN $sFileName -m a "Altibase.log";

    --# Server is not running
    EXEC $sProcName -t 1800 $gStdIsqlSys;

    SEND $sProcName "startup process";
    P_WAIT $sProcName $sPrompt;

    $sRet = "";
    $sRet = $sRet || "iSQL> startup process\n";
    $sRet = $sRet || $Ret_;

    WRITE $sFileName $sRet;

    SEND $sProcName "create database mydb INITSIZE=10M noarchivelog character set @{aCharSet} national character set @{aNCharSet};";
    P_WAIT $sProcName $sPrompt;

    $sRet = "";
    $sRet = $sRet || "iSQL> create database mydb INITSIZE=10M noarchivelog character set @{aCharSet} national character set @{aNCharSet};";
    $sRet = $sRet || $Ret_;

    WRITE $sFileName $sRet;

    SEND $sProcName "ALTER SYSTEM SET CHECKPOINT_BULK_WRITE_PAGE_COUNT = 0;";
    P_WAIT $sProcName $sPrompt;

    $sRet = "";
    $sRet = $sRet || "iSQL> ALTER SYSTEM SET CHECKPOINT_BULK_WRITE_PAGE_COUNT = 0;\n";
    $sRet = $sRet || $Ret_;

    WRITE $sFileName $sRet;

    SEND $sProcName "ALTER SYSTEM SET CHECKPOINT_BULK_WRITE_SLEEP_SEC  = 0;";
    P_WAIT $sProcName $sPrompt;

    $sRet = "";
    $sRet = $sRet || "iSQL> ALTER SYSTEM SET CHECKPOINT_BULK_WRITE_SLEEP_SEC  = 0;\n";
    $sRet = $sRet || $Ret_;

    WRITE $sFileName $sRet;

    SEND $sProcName "ALTER SYSTEM SET CHECKPOINT_BULK_WRITE_SLEEP_USEC = 0;";
    P_WAIT $sProcName $sPrompt;

    $sRet = "";
    $sRet = $sRet || "iSQL> ALTER SYSTEM SET CHECKPOINT_BULK_WRITE_SLEEP_USEC = 0;\n";
    $sRet = $sRet || $Ret_;

    WRITE $sFileName $sRet;

    SEND $sProcName "shutdown abort";
    P_WAIT $sProcName $sPrompt;

    $sRet = "";
    $sRet = $sRet || "iSQL> shutdown abort\n";
    $sRet = $sRet || $Ret_;

    WRITE $sFileName $sRet;

    SEND $sProcName "quit";
    $sRet = "";
    $sRet = $sRet || "iSQL> quit\n";

    WRITE $sFileName $sRet;

    --# Waiting Process Termination
    P_WAIT $sProcName;

    CLOSE $sFileName;
}

DEF stdServerRestart()
{
    #get unique process name for multithread;
    #get unique process number;
    RAND $sProcNum 10000;
    $sProcName = "P" || $sProcNum;
    $sFileName = "F" || $sProcNum;

    #Open Log File
    OPEN $sFileName -m a "Altibase.log";
    WRITE $sFileName "\n\n\n##############################\n";
    WRITE $sFileName "#   CALL stdServerRestart()  #\n";
    WRITE $sFileName "##############################\n";
    WRITE $sFileName "PROCESS NAME : ${sProcName}\n\n";

    $ALTIBASE_HOME;
    $sPrompt = "$$EOF$$";

    EXEC $sProcName -t 1800 $gStdIsqlSys;

    SEND $sProcName "ALTER SYSTEM SET CHECKPOINT_BULK_WRITE_PAGE_COUNT = 0;";
    P_WAIT $sProcName $sPrompt;

    $sRet = "";
    $sRet = $sRet || "iSQL> ALTER SYSTEM SET CHECKPOINT_BULK_WRITE_PAGE_COUNT = 0;\n";
    $sRet = $sRet || $Ret_;
    WRITE $sFileName $sRet;

    SEND $sProcName "ALTER SYSTEM SET CHECKPOINT_BULK_WRITE_SLEEP_SEC  = 0;";
    P_WAIT $sProcName $sPrompt;

    $sRet = "";
    $sRet = $sRet || "iSQL> ALTER SYSTEM SET CHECKPOINT_BULK_WRITE_SLEEP_SEC  = 0;\n";
    $sRet = $sRet || $Ret_;
    WRITE $sFileName $sRet;

    SEND $sProcName "ALTER SYSTEM SET CHECKPOINT_BULK_WRITE_SLEEP_USEC = 0;";
    P_WAIT $sProcName $sPrompt;

    $sRet = "";
    $sRet = $sRet || "iSQL> ALTER SYSTEM SET CHECKPOINT_BULK_WRITE_SLEEP_USEC = 0;\n";
    $sRet = $sRet || $Ret_;
    WRITE $sFileName $sRet;

    SEND $sProcName "shutdown immediate";
    P_WAIT $sProcName $sPrompt;

    $sRet = "";
    $sRet = $sRet || "iSQL> shutdown immediate\n";
    $sRet = $sRet || $Ret_;
    WRITE $sFileName $sRet;

    SEND $sProcName "startup";
    P_WAIT $sProcName $sPrompt;

    $sRet = "";
    $sRet = $sRet || "iSQL> startup\n";
    $sRet = $sRet || $Ret_;
    WRITE $sFileName $sRet;

    SEND $sProcName "quit";

    WRITE $sFileName "iSQL> quit\n";
    CLOSE $sFileName;

    --# Waiting Process Termination
    P_WAIT $sProcName;
}

DEF stdDestroydb( @aDBName )
{
    #get unique process name for multithread;
    #get unique process number;
    RAND $sProcNum 10000;
    $sProcName = "P" || $sProcNum;
    $sFileName = "F" || $sProcNum;

    #Open Log File
    OPEN $sFileName -m a "Altibase.log";
    WRITE $sFileName "\n\n\n##############################\n";
    WRITE $sFileName "#   CALL stdDestroydb()      #\n";
    WRITE $sFileName "##############################\n";
    WRITE $sFileName "PROCESS NAME : ${sProcName}\n\n";

    $ALTIBASE_HOME;
    $sPrompt = "$$EOF$$";

    --# Check Server Alive
    EXEC $sProcName -t 1800 $gStdIsql;
    SEND $sProcName "spool live-altibase.txt;";
    P_WAIT $sProcName -t 10 "ERR";
    $stdRet = $Ret_;

    WRITE $sFileName "iSQL> spool live-altibase.txt;\n";
    WRITE $sFileName $stdRet;

    if ( $stdRet == "" )
    {
        --# If spool is success, Server is alive
        SEND $sProcName "quit";
        P_WAIT $sProcName; 

        WRITE $sFileName "iSQL> quit\n";

        --# Remove live-altibase.txt
        RM -f "live-altibase.txt";

        --# shutdown server
        EXEC $sProcName -t 1800 $gStdIsqlSys;
        SEND $sProcName "shutdown abort";
        P_WAIT $sProcName $sPrompt;

	$sRet = $Ret_;
        WRITE $sFileName "iSQL> shutdown abort\n";
        WRITE $sFileName $sRet;

        SEND $sProcName "quit";
        P_WAIT $sProcName;

        WRITE $sFileName "iSQL> quit\n";
    }
    else
    {
        # DO NOTHING
        P_WAIT $sProcName; 
    }

    EXEC $sProcName -t 1800 $gStdIsqlSys;

    SEND $sProcName "startup process";
    P_WAIT $sProcName $sPrompt;
    $sRet = $Ret_;

    WRITE $sFileName "iSQL> startup process\n";
    WRITE $sFileName $sRet;

    SEND $sProcName "drop database @{aDBName};";
    P_WAIT $sProcName $sPrompt;
    $sRet = $Ret_;

    WRITE $sFileName "iSQL> drop database @{aDBName};\n";
    WRITE $sFileName $sRet;

    SEND $sProcName "shutdown abort";
    P_WAIT $sProcName $sPrompt;
    $sRet = $Ret_;

    WRITE $sFileName "iSQL> shutdown abort;\n";
    WRITE $sFileName $sRet;

    SEND $sProcName "quit";
    WRITE $sFileName "iSQL> quit\n";
    CLOSE $sFileName;

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
    $sFileName = "F" || $sProcNum;

    #Open Log File
    OPEN $sFileName -m a "Altibase.log";
    WRITE $sFileName "\n\n\n##############################\n";
    WRITE $sFileName "#   CALL stdCreatedb()       #\n";
    WRITE $sFileName "##############################\n";
    WRITE $sFileName "PROCESS NAME : ${sProcName}\n\n";

    $ALTIBASE_HOME;
    $sPrompt = "$$EOF$$";

    # for align 4M
    $sDBSize = @aDBSize / 4 * 4;

    EXEC $sProcName -t 1800 $gStdIsqlSys;

    SEND $sProcName "startup process";
    P_WAIT $sProcName $sPrompt;
    $sRet = $Ret_;

    WRITE $sFileName "iSQL> startup process\n";
    WRITE $sFileName $sRet;

    SEND $sProcName "create database @{aDBName} INITSIZE=${sDBSize}M noarchivelog character set @{aDBCharSet} national character set @{aNCharSet};";
    P_WAIT $sProcName $sPrompt;
    $sRet = $Ret_;

    WRITE $sFileName "iSQL> create database @{aDBName} INITSIZE=${sDBSize}M noarchivelog character set @{aDBCharSet} national character set @{aNCharSet};\n";
    WRITE $sFileName $sRet;

    SEND $sProcName "shutdown abort";
    P_WAIT $sProcName $sPrompt;
    $sRet = $Ret_;

    WRITE $sFileName "iSQL> shutdown abort\n";
    WRITE $sFileName $sRet;

    SEND $sProcName "quit";
    WRITE $sFileName "iSQL> quit\n";
    CLOSE $sFileName;

    P_WAIT $sProcName;

}

DEF stdStartSysdbaSession()
{
    # execute isql as sysdba
    SET_ENV CLIENT CLIENT_COMMAND="isql -u sys -p manager -sysdba";
    RESTART_CLIENT;
}

DEF stdStopSysdbaSession()
{
    # disconnect sysdba
    UNSET_ENV CLIENT CLIENT_COMMAND;
    #RESTART_CLIENT;
    DISCONNECT;
}

DEF stdRunRPQ( @startRandomSeed , @testCount , @testQuery , @displayMode )
{
    $sRandomSeed = @startRandomSeed;
    $sPrint = "";

    ################################################
    #               Random Plan Test               #
    ################################################

    nodisplay on;
    drop procedure getPlanCacheSize;
    drop procedure setPlanCacheSize;
    var planCacheSize integer;

    create or replace procedure getPlanCacheSize( p1 out integer ) as
    planCacheSize integer;
    begin
    select MAX_CACHE_SIZE into p1 from v$sql_plan_cache;
    end;
    /

    create or replace procedure setPlanCacheSize( p1 integer ) as
    begin
    execute immediate 'alter system set sql_plan_cache_size = ' || p1;
    end;
    /

    -- get plan cache size
    exec getPlanCacheSize( :planCacheSize );

    print planCacheSize;

    -- plan cache size 0으로 변경
    exec setPlanCacheSize( 0 );
    select MAX_CACHE_SIZE from v$sql_plan_cache;
    nodisplay off;

    ################################################
    #              [ TEST INFOMATION ]             #
    ################################################

    PRINT "Execute Query            : @{testQuery}";
    PRINT "Start Random Seed Number : ${sRandomSeed}";
    PRINT "Test Count               : @{testCount}";

    ################################################
    #              [ Original Result ]             #
    ################################################

    --@@{testQuery}; > $sOriRet;
    PRINT $sOriRet;
    QUERY_SORT -o $sOriRet_sort $sOriRet;

    ################################################
    #                [ Test Result ]               #
    ################################################

    loop @testCount
    {
        nodisplay on;
        alter system set __plan_random_seed = ${sRandomSeed};
        -- Query 실행
        --@@{testQuery}; > $sRet;
        PRINT $sRet;
        QUERY_SORT -o $sRet_sort $sRet;
        nodisplay off;
        -- compare result
        if( $sOriRet_sort == $sRet_sort )
        {
            $sCompRet = "TRUE";
        }
        else
        {
            $sCompRet = "FALSE";
        }
        $sPrint = "[ Random Seed " || $sRandomSeed || " ] " || $sCompRet;
        PRINT $sPrint;
        if( $sCompRet == "FALSE" )
        {
            if( @displayMode == "TRUE" )
            {
                PRINT $sRet;
            }
            else
            {

            }
        }
        else
        {

        }
        nodisplay on;
        -- random seed 증가 
        $sRandomSeed = $sRandomSeed + 1;
        nodisplay off;
    }
    nodisplay on;
    -- property default로 셋팅
    alter system set __plan_random_seed = 0;

    -- original sql_plan_cache_size 
    exec setPlanCacheSize( :planCacheSize );
    select MAX_CACHE_SIZE from v$sql_plan_cache;

    drop procedure getPlanCacheSize;
    drop procedure setPlanCacheSize;
    nodisplay off;
}
