/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: common.h 1140 2007-02-08 06:21:13Z leekmo $
 **********************************************************************/

#ifndef _O_COMMON_H_
#define _O_COMMON_H_ 1

#include "STAF.h"
#include <deque>
#include <map>
#include <list>
#include "STAFMutexSem.h"
#include "STAFCommandParser.h"
#include "STAFServiceInterface.h"
#include "STAFUtil.h"


#if !defined(STAF_OS_NAME_WIN32)
#include <sys/wait.h>
#else
#include "win32.h" 
#endif

#include <sys/types.h>
#include <signal.h>
#include <assert.h>

#include "idFake.h"
#include "atsBaseThread.h"

/*  PRJ-1552 
    ATS에 ART 기능을 추가하기 위해
    Test를 구분할 수 있도록
    Test Type 정의  */

enum ATSTestKind
{
    ATS_TEST_NULL = 0,
    ATS_TEST_NORMAL,      // natc normal test type
    ATS_TEST_REGRESSIVE,  // ART Regressive test type
    ATS_TEST_SEQUENTIAL,  // art Sequential test type
    ATS_TEST_FULL         // art full test type
};

enum StringKind
{
    SCRIPT_STR = 0,
    SQL_STR,
    RESPONSE_STR
};

enum CommandKind 
{
    SYSTEM_COM = 0, 

    ALTER_COM,
    CREATE_OBJ_COM, 
    CREATE_PROC_COM,
    DROP_COM, 
    GRANT_COM,
    RENAME_COM,  
    REVOKE_COM,
    TRUNCATE_COM,

    DELETE_COM, 
    DEQUEUE_COM,
    ENQUEUE_COM,
    INSERT_COM,
    LOCK_COM,
    SELECT_COM, 
    TABLES_COM,
    XTABLES_COM,
    DTABLES_COM,
    VTABLES_COM,
    SEQUENCE_COM,
    UPDATE_COM, 
    MOVE_COM,
    COMMENT_SQL_COM,

    ALTER_SYSTEM_COM,
    ALTER_SESSION_COM,
    COMMIT_COM,
    ROLLBACK_COM,
    ROLLBACK_TO_SAVEPOINT_COM,
    SAVEPOINT_COM,
    SET_TRANSACTION_COM,
    SET_AGER_COM,
    SET_VERTICAL_COM,

    DESC_COM,
    DESC_DOLLAR_COM,
    AUTOCOMMIT_COM,
    CONNECT_COM,
    DISCONNECT_COM,

    TIMING_COM, 
    HEADING_COM,
    FOREIGNKEYS_COM, 
    SYMBOL_COM,
    PRINT_COM,
    SHELL_COM,
    EXECUTE_COM,
    EXEC_FUNC_COM,
    EXEC_PROC_COM,
    
    CHECK_COM,
    OTHER_COM,

    PREP_SELECT_COM, 
    PREP_INSERT_COM, 
    PREP_UPDATE_COM, 
    PREP_DELETE_COM, 
    PREP_MOVE_COM,
    PREP_ENQUEUE_COM,
    PREP_DEQUEUE_COM,

    SKIP_COM,
    STRING_COM,
    POST_COM,
    WAIT_COM,
    APPEND_COM,
    LOAD_SQL_COM,
    START1_COM,
    START2_COM,
    RESTART_COM,
    ENV_COM,
    
/* PRJ-1552
   ART의 복구지점 관련 명령 타입 추가 */
    RECPOINT_COM,

    // alter session set explain plan
    EXPLAIN_PLAN_COM,

    // alter session set default_date_format
    DATEFORMAT_COM,

    RSYSTEM_COM
};

enum SessionKind
{
    EXPLAIN_PLAN_OFF=0, EXPLAIN_PLAN_ON=1, EXPLAIN_PLAN_ONLY=2
};

// following CONSTANTs are defined in iduFixedTableDef.h
#define IDU_FT_TYPE_MASK       (0x00FF)
#define IDU_FT_TYPE_CHAR       (0x0000)
#define IDU_FT_TYPE_BIGINT     (0x0001)
#define IDU_FT_TYPE_SMALLINT   (0x0002)
#define IDU_FT_TYPE_INTEGER    (0x0003)
#define IDU_FT_TYPE_DOUBLE     (0x0004)
#define IDU_FT_TYPE_UBIGINT    (0x0005)
#define IDU_FT_TYPE_USMALLINT  (0x0006)
#define IDU_FT_TYPE_UINTEGER   (0x0007)
#define IDU_FT_TYPE_VARCHAR    (0x0008)
#define IDU_FT_TYPE_POINTER    (0x1000)

struct ServiceData
{
    UInt                 debugMode;
    STAFString           shortName;
    STAFString           name;
    STAFHandlePtr        handlePtr;
    STAFString           localMachineName;
    STAFCommandParserPtr helpParser;
    STAFCommandParserPtr versionParser;
    STAFCommandParserPtr runParser;
    STAFCommandParserPtr killParser;
    STAFCommandParserPtr statusParser;
};

#ifdef __cplusplus
extern "C"
{
#endif

typedef enum STAFServiceError_e
{
    // add service-specific return codes here
    kServieInvalidOption = 4001
} STAFServiceError_t;

#ifdef __cplusplus
}
#endif

typedef struct symbolData
{
    STAFString name;
    STAFString type;
    STAFString precision;
    STAFString scale;
} symbolData;

typedef struct queryData
{
    STAFString query;
    STAFString table;
    CommandKind type; // 0: system, 1: query
    STAFString user;
    STAFString password;
    STAFString sysdba;
    symbolData symbol;
    STAFString realQuery;
    UInt       loc;
} queryData;

typedef std::list<queryData> QueryList;
typedef std::list<queryData>::iterator QueryIterator;

typedef struct logonData
{
    SChar      host[128];
    SChar      user[128];
    SChar      password[128];
    SChar      nls[128];
    UInt       port;
    UInt       conn_type;
    SChar      env[1024];
    SChar      home[1024];
} logonData;

class Laborer;

typedef std::map<STAFString, Laborer *> LaborerList;
typedef std::map<STAFString, Laborer *>::iterator LaborerIterator;

typedef std::map<STAFString, std::list<queryData> > LaborerQueryList;
typedef std::map<STAFString, std::list<queryData> >::iterator LaborerQueryIterator;

enum LogType
{
    LOG_ERROR,
    LOG_REPORT,
    LOG_EXCEPTION,
    LOG_DEBUG,
    LOG_FAIL,
    LOG_LSTOUT,
    LOG_SYSTEM,
    
/*  PRJ-1552
    ART의 복구테스트 결과중 CRASH 발생하는
    테스트케이스 목록을 저장하는 파일 */
    LOG_CRASH
};

#define SYSTEM_LOG        "system.log"
#define ERROR_LOG         "error.log"
#define EXCEPTION_LOG     "exception.log"
#define REPORT_LOG        "report.log"
#define DEBUG_LOG         "debug.log"
#define FAIL_LOG          "TS999999.ts"
#define PLATFORM_FILE     "platform.conf"
#define SERVER_FILE       "server.conf"
#define VALGRIND_LOG      "valgrind.log"
#define LSTOUT_LOG        "lstout.log"

/*  PRJ-1552
    
    ART 복구테스트 수행에 필요한 파일
    
    1) RECPOINT_FILE : 복구지점목록 파일
    2) CRASH_LOG     : 복구실패한 테스트케이스 목록 파일
    3) BOOT_LOG      : 복구지점비정상종료인지 판단하기 위해
                       altibase_boot.log를 판독 */
#define RECPOINT_FILE     "recovery.dat"
#define CRASH_LOG         "CR999999.ts"
#define BOOT_LOG          "altibase_boot.log"


#define PLAT_OFF 0
#define PLAT_ON  1

#define SQL 1
#define TS  2
#define TL  3
#define XML 4

#define RUNABLE 0
#define NOTRUNABLE 1
#define RUNSKIP 2


typedef struct caseInfo
{
    STAFString  caseName;
    SInt        caseFlag;   //PLAT_OFF: default, PLAT_ON: ignore the system
    STAFString  casePlatformName;
    STAFString  caseComment;
    SInt        caseType;   //SQL:1 TS:2 TL:3 XML:4
    SInt        caseMark;   //RUNABLE:0 NOTRUNABLE:1
    STAFString  tsName;
} caseInfo;

typedef std::list<caseInfo> CaseList;
typedef std::list<caseInfo>::iterator CaseIterator;

typedef std::map<STAFString,  std::list<STAFString> >  mPlatform;

typedef std::map<STAFString, STAFString> ServerParam;
typedef ServerParam::iterator ParamIterator;

typedef std::map<STAFString,  ServerParam> ServerMap;
typedef ServerMap::iterator ServerParamIterator;

typedef std::map<STAFString, STAFString> ServerAlias;
typedef std::map<STAFString, STAFString> DefaultServer;
typedef std::map<STAFString, STAFString> DefaultType;

#if defined(STAF_OS_NAME_WIN32)
#define FILE_SEPARATOR '\\'
#define FILE_SEPARATOR2 "\\"
#else
#define FILE_SEPARATOR '/'
#define FILE_SEPARATOR2 "/"
#endif

//extern PDL_thread_key_t psmKey;

#define BUFFER_SIZE (65536)
#define VAR_SIZE (1024)

/* PRJ-1552
   ART의 Sequential Test를 하기 위해 atsc에서
   복구지점 목록을 STL list로 관리 */

typedef std::list<STAFString> RecPtrList;
typedef RecPtrList::iterator  RecPtrListIter;

/* PRJ-1552
   ART의 Sequential Test를 하기 위해 atsc에서
   복구지점 목록을 STL list로 관리 */

typedef struct recPointData
{
    STAFString    recPointID;
    STAFString    filename;
    UInt          lineNumber;
    STAFString    testType;
    UInt          applyValue;
    UInt          skipFlagAtStartup;
    STAFString    queryString;
} recPointData;


/* PRJ-1552
   ART의 Regression Test, Sequential Test를 하기 위해
   ats에서 복구지점 목록을 STL map 으로 관리 */

typedef std::map<STAFString, recPointData> RecPtrMap;
typedef RecPtrMap::iterator RecPtrMapIter;

/* PRJ-1552
   복구지점목록에 대한 map을 전역으로 cache해둠 */

typedef struct recPointCache
{
    RecPtrMap   recpointMap;
} recPointCache;

#define copyData( a, b, c ) { memcpy( a, b, c ); a[c] = '\0'; }

enum iSQLVarType
{
    iSQL_BAD=-1, iSQL_BIGINT=1, iSQL_BLOB_LOCATOR=2, iSQL_CHAR,
    iSQL_CLOB_LOCATOR, iSQL_DATE, iSQL_DECIMAL, iSQL_DOUBLE, iSQL_FLOAT,
    iSQL_BYTE, iSQL_NIBBLE, iSQL_INTEGER, iSQL_NUMBER, iSQL_NUMERIC, iSQL_REAL,
    iSQL_SMALLINT, iSQL_VARCHAR, iSQL_GEOMETRY, iSQL_NCHAR, iSQL_NVARCHAR
};

#if defined(STAF_OS_NAME_WIN32)
#define FILE_SEPARATORS "\\"
#else
#define FILE_SEPARATORS "/"
#endif

typedef struct rsystemData
{
    char ip[1024];
    int  port; 
} rsystemData;

typedef std::map<STAFString, rsystemData> RsystemMap;

#endif
