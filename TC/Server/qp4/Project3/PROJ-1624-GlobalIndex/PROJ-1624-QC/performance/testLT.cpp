#include <sqlcli.h>
#include <time.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <share.h>
#include <idFake.h>

#define SQL_LEN 1000
#define MSG_LEN 1024

SQLHENV env;
SQLHDBC con;

SQLCHAR connStr[MSG_LEN];

SChar   gType;
SInt    gCount;

SQLLEN  len = SQL_NTS;

typedef struct timeval timeval;
timeval startTime, endTime;
double  elapsedtime;
double  totalTime = 0.00;
char   *gLogFileName = (char*)"./test.log";

void    usage();
void    parseEnv(SChar **aEnv);

void    checkTime();
SInt    waitForSync();

UInt    runInsert();
UInt    runUpdate();
UInt    runUpdateRowMovement();
UInt    runSelect();
UInt    runDelete();

void    db_connect();
void    db_disconnect();
int     db_error( SQLHSTMT hstmt );

void    showTotal(SInt, SDouble);
void    log(char *aFormat, ...);
void    setLogFileName( SChar *aLogFileName );


static void print_diagnostic(SQLSMALLINT , SQLHANDLE );
void execute_err(SQLHDBC , SQLHSTMT , SQLCHAR *);

static void print_diagnostic(SQLSMALLINT aHandleType, SQLHANDLE aHandle)
{
    SQLRETURN   rc;
    SQLSMALLINT sRecordNo;
    SQLCHAR     sSQLSTATE[6];
    SQLCHAR     sMessage[2048];
    SQLSMALLINT sMessageLength;
    SQLINTEGER  sNativeError;

    sRecordNo = 1;

    while ((rc = SQLGetDiagRec(aHandleType,
                               aHandle,
                               sRecordNo,
                               sSQLSTATE,
                               &sNativeError,
                               sMessage,
                               sizeof(sMessage),
                               &sMessageLength)) != SQL_NO_DATA)
    {
        printf("Diagnostic Record %d\n", sRecordNo);
        printf("     SQLSTATE     : %s\n", sSQLSTATE);
        printf("     Message text : %s\n", sMessage);
        printf("     Message len  : %d\n", sMessageLength);
        printf("     Native error : 0x%X\n", sNativeError);

        log((char*)"Diagnostic Record %d\n", sRecordNo);
        log((char*)"     SQLSTATE     : %s\n", sSQLSTATE);
        log((char*)"     Message text : %s\n", sMessage);
        log((char*)"     Message len  : %d\n", sMessageLength);
        log((char*)"     Native error : 0x%X\n", sNativeError);

        if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO)
        {
            break;
        }

        sRecordNo++;
    }
}

void execute_err(SQLHDBC aCon, SQLHSTMT aStmt, SQLCHAR* q )
{
    printf("Error : %s\n",q);

    if (aStmt == SQL_NULL_HSTMT)
    {
        if (aCon != SQL_NULL_HDBC)
        {
            print_diagnostic(SQL_HANDLE_DBC, aCon);
        }
    }
    else
    {
        print_diagnostic(SQL_HANDLE_STMT, aStmt);
    }
}

/*----------------------------------------------------------------------------
  NAME
  usage

  DESCRIPTION
  usage를 표시한다.

  ARGUMENTS
  없음

  RETURNS
  없음
  ----------------------------------------------------------------------------*/
void usage()
{
    printf("============================================\n");
    printf("Partitioned Disk Table Test Program \n");
    printf("============================================\n");
    printf("usage: testLT [type] [count]\n");
    printf(" \t[type] I   : insert\n");
    printf(" \t       U   : update\n");
    printf(" \t       R   : update row movement\n");
    printf(" \t       S   : select\n");
    printf(" \t       D   : delete\n");
    printf(" \t[exec count] 1000\n");

    exit(-1);
}

/*----------------------------------------------------------------------------
  NAME
  parseEnv

  DESCRIPTION
  인자 값을 분석한다.

  ARGUMENTS
  aEnv: main 실행시에 넘겨지는 argv

  RETURNS
  없음
  ----------------------------------------------------------------------------*/
void  parseEnv(SChar **aEnv)
{
    gType  = (SChar)aEnv[1][0];
    gCount = (SInt)atoi(aEnv[2]);
}

/*----------------------------------------------------------------------------
  NAME
  log

  DESCRIPTION
  로그를 기록한다.

  ARGUMENTS
  format: 로그 포맷

  RETURNS
  없음
  ----------------------------------------------------------------------------*/
void log(char *format, ...)
{
    FILE   *fp ;
    char    s[255];
    va_list ap;

    sprintf(s, "%s", gLogFileName);
    fp = fopen(s, "a+");
    if (fp == NULL)
    {
        perror("fopen");
        exit(-1);
    }

    va_start(ap, format);
    vfprintf (fp, format, ap);
    va_end(ap);

    fclose(fp);
}

/*----------------------------------------------------------------------------
  NAME
  setLogFileName

  DESCRIPTION
  로그 파일 이름을 지정한다.

  ARGUMENTS
  aLogFileName: 로그 파일 이름

  RETURNS
  없음
  ----------------------------------------------------------------------------*/
void setLogFileName( SChar *aLogFileName )
{
    gLogFileName = aLogFileName;
}


/*----------------------------------------------------------------------------
  NAME
  showTotal

  DESCRIPTION
  경과 시간에 대한 TPS를 기록한다.

  ARGUMENTS
  aProcessed: 처리 건수
  aTotalTime: 경과 시간

  RETURNS
  없음
  ----------------------------------------------------------------------------*/
void showTotal(SInt aProcessed, SDouble aTotalTime )
{
    log((char*)" Total Elapsed Time ==> %15.2f seconds \n", aTotalTime/1000000.00);
    log((char*)" TPS(Transaction per Second) ==> %8.2f TPS \n", (SDouble)((aProcessed-1)*1000000.0/aTotalTime));
}

/*----------------------------------------------------------------------------
  NAME
  checkTime

  DESCRIPTION
  총 경과시간을 구한다.

  ARGUMENTS
  없음

  RETURNS
  없음
  ----------------------------------------------------------------------------*/
void checkTime()
{
    timeval v_timeval;
    gettimeofday(&endTime, NULL);
    elapsedtime = 0;
    v_timeval.tv_sec  = endTime.tv_sec  - startTime.tv_sec;
    v_timeval.tv_usec = endTime.tv_usec - startTime.tv_usec;

    if (v_timeval.tv_usec < 0)
    {
        v_timeval.tv_sec -= 1;
        v_timeval.tv_usec = 999999 - v_timeval.tv_usec * (-1);
    }

    elapsedtime = v_timeval.tv_sec*1000000+v_timeval.tv_usec;
    totalTime += elapsedtime;
}

/*----------------------------------------------------------------------------
  NAME
  waitForSync

  DESCRIPTION
  프로세스 간의 sync를 맞추기 위한 함수.

  ARGUMENTS
  없음

  RETURNS
  IDE_SUCCESS: 성공
  IDE_FAILURE: 실패
  ----------------------------------------------------------------------------*/
SInt waitForSync()
{
    SInt         sError;
    SInt         sFd;
    struct flock sLock;

    sFd = open( LOCK_FILE, O_RDONLY );

    if( sFd < 0 )
    {
        return -1;
    }

    sLock.l_type   = F_RDLCK;
    sLock.l_whence = SEEK_SET;
    sLock.l_start  = sLock.l_len = 0;

    while( 1 )
    {
        sError  = fcntl( sFd, F_SETLK, &sLock );

        if( (sError < 0) && ((errno == EACCES) || (errno == EAGAIN)) )
        {
            usleep( 1000 );
        }
        else
        {
            break;
        }
    }

    return 0;
}

/*----------------------------------------------------------------------------
  NAME
  db_connect

  DESCRIPTION
  TCP를 통하여 데이터베이스에 접속한다.

  ARGUMENTS
  없음

  RETURNS
  없음
  ----------------------------------------------------------------------------*/
void db_connect()
{
    if (SQL_ERROR == SQLAllocEnv(&env))
    {
        printf("SQLAllocEnv error!!\n");
        exit(1);
    }

    if (SQL_ERROR == SQLAllocConnect(env, &con))
    {
        printf("ispAllocConnect error!!\n");
        SQLFreeEnv(env);
        exit(1);
    }

    sprintf((SChar*)connStr, "DSN=127.0.0.1;UID=SYS;PWD=MANAGER;CONNTYPE=1");
    printf("-- Connecting with TCP ...\n");

    if (SQL_ERROR == SQLDriverConnect( con, NULL, connStr, SQL_NTS,
                                       NULL, 0, NULL, SQL_DRIVER_NOPROMPT ))
    {
        printf(" connection error\n");
        SQLINTEGER errNo;
        SQLSMALLINT msgLength;
        SQLCHAR errMsg[MSG_LEN];

        if (SQL_SUCCESS == SQLError ( env, con, NULL, NULL, &errNo,
                                      errMsg, MSG_LEN, &msgLength ))
        {
            printf(" rCM_-%d : %s\n", errNo, errMsg);
        }

        SQLFreeEnv(env);
        exit(1);
    }

    SQLSetConnectAttr(con, SQL_ATTR_AUTOCOMMIT, (void *)SQL_AUTOCOMMIT_ON, 0);
    printf("-- Connection has established ...\n");

}

/*----------------------------------------------------------------------------
  NAME
  db_disconnect

  DESCRIPTION
  서버와의 연견을 해제한다.

  ARGUMENTS
  없음

  RETURNS
  없음
  ----------------------------------------------------------------------------*/
void db_disconnect()
{
    printf("-- Disconnecting ...\n");

    if (SQL_ERROR == SQLDisconnect(con))
    {
        printf("disconnect error\n");
    }

    printf("-- Disconnection has completed ...\n");

    SQLFreeConnect(con);
    SQLFreeEnv(env);
}

/*----------------------------------------------------------------------------
  NAME
  db_error

  DESCRIPTION
  에러 정보를 출력한다.

  ARGUMENTS
  hstmt : 에러가 발생된 statement handle

  RETURNS
  -1 : 성공
  ----------------------------------------------------------------------------*/
int db_error(SQLHSTMT hstmt)
{
    SQLCHAR     errMsg[MSG_LEN];
    SQLINTEGER  errNo;
    SQLSMALLINT msgLength;

    printf("ExecDirect error!!!\n");

    if (SQL_SUCCESS == SQLError ( env, con, hstmt, NULL, &errNo,
                                  errMsg, MSG_LEN, &msgLength ))
    {
        printf(" rCM_-%d : %s\n", errNo, errMsg);
    }
    return -1;
}

/*----------------------------------------------------------------------------
  NAME
  main

  DESCRIPTION
  인자를 분석해서 각 타입에 따른 테스트를 실행한다.

  ARGUMENTS
  argc, argv

  RETURNS
  0: 성공
  -1: 실패
  ----------------------------------------------------------------------------*/
int main(int argc,char **argv)
{
    UInt ret;

    if( argc != 3 )
    {
        usage();
    }

    parseEnv(argv);

    /* 로그 파일 이름을 지정한다. */
    (void)setLogFileName((char*)"./test.log" );

    db_connect();

    /* 각 타입에 따른 연산을 수행한다. */
    switch( gType )
    {
        case 'I':
            ret = runInsert();
            break;
        case 'U':
            ret = runUpdate();
            break;
        case 'R':
            ret = runUpdateRowMovement();
            break;
        case 'D':
            ret = runDelete();
            break;
        case 'S':
            ret = runSelect();
            break;
        default :
            log( (char*)"Unsupported Option\n" );
            return -1;
    }

    db_disconnect();

    exit(0);
}

/*----------------------------------------------------------------------------
  NAME
  runInsert

  DESCRIPTION
  주어진 경계에 대해서 insert 연산을 수행한다.

  ARGUMENTS
  없음

  RETURNS
  0 : 성공
  -1: 실패
  ----------------------------------------------------------------------------*/
UInt runInsert()
{
    SQLCHAR        sql_str[SQL_LEN];
    SQLHSTMT       stmt;
    UInt           ret;

    SQLINTEGER     i1;
    SQLINTEGER     i2;
    SQLCHAR        i3[30+1];

    log((char*)"============================\n");
    log((char*)"[INSERT] start [%d] \n", gCount);

    printf("-- Inserting record ...\n");

    //if ( waitForSync() != 0 )
    //{
    //    printf("waitForSync error!!\n");
    //    return -1;
    //}

    if (SQL_ERROR == SQLAllocStmt(con, &stmt))
    {
        printf("SQLAllocEnv error!!\n");
        SQLFreeEnv(env);
        exit(1);
    }

    sprintf((SChar*)sql_str,
            "INSERT /*+keep_plan*/ INTO LT VALUES (?, ?, ?);" );

    if (SQL_ERROR == SQLPrepare(stmt, sql_str, SQL_NTS))
    {
        printf("Prepare error!!! ==> %s \n",sql_str);
        ret = db_error(stmt);
        return ret;
    }

    if (SQL_ERROR == SQLBindParameter(stmt, 1, SQL_PARAM_INPUT,
                                      SQL_C_SLONG, SQL_INTEGER,
                                      0, 0,
                                      &i1, 0, &len))
    {
        printf("BindParameter error!!! ==> %s \n",sql_str);
        return -1;
    }

    if (SQL_ERROR == SQLBindParameter(stmt, 2, SQL_PARAM_INPUT,
                                      SQL_C_SLONG, SQL_INTEGER,
                                      0, 0,
                                      &i2, 0, &len))
    {
        printf("BindParameter error!!! ==> %s \n",sql_str);
        return -1;
    }

    if (SQL_ERROR == SQLBindParameter(stmt, 3, SQL_PARAM_INPUT,
                                      SQL_C_CHAR, SQL_VARCHAR,
                                      30, 0,
                                      i3, sizeof(i3), &len))
    {
        printf("BindParameter error!!! ==> %s \n",sql_str);
        return -1;
    }

    gettimeofday(&startTime, NULL );

    for (i1 = 1, i2 = 1; i1 <= gCount; i1++, i2++)
    {
        if (i2 > 100)
        {
            i2 = 1;
        }

        snprintf( (char*)i3, sizeof(i3), "altibase%d", i1 );
        
        if( SQLExecute(stmt) != SQL_SUCCESS )
        {
            execute_err(con, stmt, sql_str);
            SQLFreeStmt(stmt, SQL_DROP);
            return SQL_ERROR;
        }
    }

    checkTime();
    showTotal( gCount, totalTime );

    printf("-- Insert has completed ...\n");

    SQLFreeStmt(stmt,SQL_DROP);

    return 0;
}

/*----------------------------------------------------------------------------
  NAME
  runUpdate

  DESCRIPTION
  주어진 경계에 대해서 update 연산을 수행한다.

  ARGUMENTS
  없음

  RETURNS
  0 : 성공
  -1: 실패
  ----------------------------------------------------------------------------*/
UInt runUpdate()
{
    SQLCHAR        sql_str[SQL_LEN];
    SQLHSTMT       stmt;
    UInt           ret;

    SQLINTEGER     i1;
    SQLCHAR        i3_old[30+1];
    SQLCHAR        i3_new[30+1];

    log((char*)"============================\n");
    log((char*)"[UPDATE] start [%d] \n", gCount);

    printf("-- Updating record ...\n");

    //if ( waitForSync() != 0 )
    //{
    //    printf("waitForSync error!!\n");
    //    return -1;
    //}

    if (SQL_ERROR == SQLAllocStmt(con, &stmt))
    {
        printf("SQLAllocEnv error!!\n");
        SQLFreeEnv(env);
        exit(1);
    }

    sprintf((SChar*)sql_str,
            "UPDATE /*+keep_plan*/ LT SET I1 = I1 + 5, I3 = ? WHERE I3 = ?;" );

    if (SQL_ERROR == SQLPrepare(stmt, sql_str, SQL_NTS))
    {
        printf("Prepare error!!! ==> %s \n",sql_str);
        ret = db_error(stmt);
        return ret;
    }

    if (SQL_ERROR == SQLBindParameter(stmt, 1, SQL_PARAM_INPUT,
                                      SQL_C_CHAR, SQL_VARCHAR,
                                      30, 0,
                                      i3_new, sizeof(i3_new), &len))
    {
        printf("BindParameter error!!! ==> %s \n",sql_str);
        return -1;
    }
    
    if (SQL_ERROR == SQLBindParameter(stmt, 2, SQL_PARAM_INPUT,
                                      SQL_C_CHAR, SQL_VARCHAR,
                                      30, 0,
                                      i3_old, sizeof(i3_old), &len))
    {
        printf("BindParameter error!!! ==> %s \n",sql_str);
        return -1;
    }

    gettimeofday(&startTime, NULL );

    for (i1 = 1; i1 <= gCount ; i1++)
    {
        snprintf( (char*)i3_old, sizeof(i3_old), "altibase%d", i1 );
        snprintf( (char*)i3_new, sizeof(i3_new), "esabitla%d", i1 );
        
        if( SQLExecute(stmt) != SQL_SUCCESS )
        {
            execute_err(con, stmt, sql_str);
            SQLFreeStmt(stmt, SQL_DROP);
            return SQL_ERROR;
        }
    }

    checkTime();
    showTotal( gCount, totalTime );

    printf("-- Update has completed ...\n");

    SQLFreeStmt(stmt,SQL_DROP);

    return 0;
}

/*----------------------------------------------------------------------------
  NAME
  runUpdate

  DESCRIPTION
  주어진 경계에 대해서 update 연산을 수행한다.

  ARGUMENTS
  없음

  RETURNS
  0 : 성공
  -1: 실패
  ----------------------------------------------------------------------------*/
UInt runUpdateRowMovement()
{
    SQLCHAR        sql_str[SQL_LEN];
    SQLHSTMT       stmt;
    UInt           ret;

    SQLINTEGER     i1;
    SQLCHAR        i3_old[30+1];
    SQLCHAR        i3_new[30+1];

    log((char*)"============================\n");
    log((char*)"[UPDATE] start [%d] \n", gCount);

    printf("-- Updating Row Movement record ...\n");

    //if ( waitForSync() != 0 )
    //{
    //    printf("waitForSync error!!\n");
    //    return -1;
    //}

    if (SQL_ERROR == SQLAllocStmt(con, &stmt))
    {
        printf("SQLAllocEnv error!!\n");
        SQLFreeEnv(env);
        exit(1);
    }

    sprintf((SChar*)sql_str,
            "UPDATE /*+keep_plan*/ LT SET I2 = I2 + 5, I3 = ? WHERE I3 = ?;" );

    if (SQL_ERROR == SQLPrepare(stmt, sql_str, SQL_NTS))
    {
        printf("Prepare error!!! ==> %s \n",sql_str);
        ret = db_error(stmt);
        return ret;
    }

    if (SQL_ERROR == SQLBindParameter(stmt, 1, SQL_PARAM_INPUT,
                                      SQL_C_CHAR, SQL_VARCHAR,
                                      30, 0,
                                      i3_new, sizeof(i3_new), &len))
    {
        printf("BindParameter error!!! ==> %s \n",sql_str);
        return -1;
    }
    
    if (SQL_ERROR == SQLBindParameter(stmt, 2, SQL_PARAM_INPUT,
                                      SQL_C_CHAR, SQL_VARCHAR,
                                      30, 0,
                                      i3_old, sizeof(i3_old), &len))
    {
        printf("BindParameter error!!! ==> %s \n",sql_str);
        return -1;
    }

    gettimeofday(&startTime, NULL );

    for (i1 = 1; i1 <= gCount ; i1++)
    {
        snprintf( (char*)i3_old, sizeof(i3_old), "esabitla%d", i1 );
        snprintf( (char*)i3_new, sizeof(i3_new), "altibase%d", i1 );
        
        if( SQLExecute(stmt) != SQL_SUCCESS )
        {
            execute_err(con, stmt, sql_str);
            SQLFreeStmt(stmt, SQL_DROP);
            return SQL_ERROR;
        }
    }

    checkTime();
    showTotal( gCount, totalTime );

    printf("-- Update Row Movement has completed ...\n");

    SQLFreeStmt(stmt,SQL_DROP);

    return 0;
}

/*----------------------------------------------------------------------------
  NAME
  runDelete

  DESCRIPTION
  주어진 경계에 대해서 delete 연산을 수행한다.

  ARGUMENTS
  없음

  RETURNS
  0  : 성공
  -1 : 실패
  ----------------------------------------------------------------------------*/
UInt runDelete()
{
    SQLCHAR        sql_str[SQL_LEN];
    SQLHSTMT       stmt;
    UInt           ret;

    SQLINTEGER     i1;
    SQLCHAR        i3[30+1];
    
    log((char*)"============================\n");
    log((char*)"[DELETE] start [%d] \n", gCount);

    printf("-- Deleting record ...\n");

    //if ( waitForSync() != 0 )
    //{
    //    printf("waitForSync error!!\n");
    //    return -1;
    //}

    if (SQL_ERROR == SQLAllocStmt(con, &stmt))
    {
        printf("SQLAllocEnv error!!\n");
        SQLFreeEnv(env);
        exit(1);
    }

    sprintf((SChar*)sql_str,
            "DELETE /*+keep_plan*/ FROM LT WHERE I3 = ?;" );

    if (SQL_ERROR == SQLPrepare(stmt, sql_str, SQL_NTS))
    {
        printf("Prepare error!!! ==> %s \n",sql_str);
        ret = db_error(stmt);
        return ret;
    }

    if (SQL_ERROR == SQLBindParameter(stmt, 1, SQL_PARAM_INPUT,
                                      SQL_C_CHAR, SQL_VARCHAR,
                                      30, 0,
                                      i3, sizeof(i3), &len))
    {
        printf("BindParameter error!!! ==> %s \n",sql_str);
        return -1;
    }

    gettimeofday(&startTime, NULL );

    for (i1 = 1; i1 <= gCount ; i1++)
    {
        snprintf( (char*)i3, sizeof(i3), "altibase%d", i1 );
        
        if( SQLExecute(stmt) != SQL_SUCCESS )
        {
            execute_err(con, stmt, sql_str);
            SQLFreeStmt(stmt, SQL_DROP);
            return SQL_ERROR;
        }
    }

    checkTime();
    showTotal( gCount, totalTime );

    printf("-- Deletion has completed ...\n");

    SQLFreeStmt(stmt,SQL_DROP);

    return 0;
}

/*----------------------------------------------------------------------------
  NAME
  runSelect

  DESCRIPTION
  주어진 경계에 대해서 select 연산을 수행한다.

  ARGUMENTS
  없음

  RETURNS
  0  : 성공
  -1 : 실패
  ----------------------------------------------------------------------------*/
UInt runSelect()
{
    SQLCHAR        sql_str[SQL_LEN];
    SQLHSTMT       stmt;
    UInt           ret;

    SQLINTEGER     i1;
    SQLCHAR        i3[30+1];

    log((char*)"============================\n");
    log((char*)"[SELECT] start [%d] \n", gCount);

    printf("-- Selecting record ...\n");

    //if ( waitForSync() != 0 )
    //{
    //    printf("waitForSync error!!\n");
    //    return -1;
    //}

    if (SQL_ERROR == SQLAllocStmt(con, &stmt))
    {
        printf("SQLAllocEnv error!!\n");
        SQLFreeEnv(env);
        exit(1);
    }

    sprintf((SChar*)sql_str,
            "SELECT /*+keep_plan*/ I1 FROM LT WHERE I3 = ?" );

    if (SQL_ERROR == SQLPrepare(stmt, sql_str, SQL_NTS))
    {
        printf("Prepare error!!! ==> %s \n",sql_str);
        ret = db_error(stmt);
        return ret;
    }

    if (SQL_ERROR == SQLBindParameter(stmt, 1, SQL_PARAM_INPUT,
                                      SQL_C_CHAR, SQL_VARCHAR,
                                      30, 0,
                                      i3, sizeof(i3), &len))
    {
        printf("BindParameter error!!! ==> %s \n",sql_str);
        return -1;
    }

    gettimeofday(&startTime, NULL );

    for (i1 = 1; i1 <= gCount ; i1++)
    {
        snprintf( (char*)i3, sizeof(i3), "altibase%d", i1 );
        
        if( SQLExecute(stmt) != SQL_SUCCESS )
        {
            execute_err(con, stmt, sql_str);
            SQLFreeStmt(stmt, SQL_DROP);
            return SQL_ERROR;
        }

        if( SQLFreeStmt(stmt,SQL_CLOSE) == SQL_ERROR )
        {
            db_error(stmt);
            return -1;
        }
    }

    checkTime();
    showTotal( gCount, totalTime );

    printf("-- Selection has completed ...\n");

    SQLFreeStmt(stmt,SQL_DROP);

    return 0;
}
