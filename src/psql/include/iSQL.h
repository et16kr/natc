/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iSQL.h 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/

#ifndef _O_ISQL_H_
#define _O_ISQL_H_ 1

#define ISQL_BUF     "iSQL.buf"
#define ISQL_EDITOR  "/usr/bin/vi"

#define ISQL_EMPTY           1
#define ISQL_COMMENT         2
#define ISQL_COMMENT2        3
#define ISQL_UNTERMINATED    4

#define WORD_LEN             256
#define HELP_MSG_CNT         50
#define MAX_PASS_LEN         40
#define COM_QUEUE_SIZE       21
#define MAX_TABLE_ELEMENTS   32

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
#define IDU_FT_TYPE_POINTER    (0x1000)
       

enum iSQLCommandKind  
{ 
    NON_COM=-1, ALTER_COM=1, AUTOCOMMIT_COM=2, 
    CHANGE_COM, CHECK_COM, COLSIZE_COM, COMMENT_COM, COMMIT_COM, CONNECT_COM, 
    CRT_OBJ_COM, CRT_PROC_COM,
    DELETE_COM, DESC_COM, DESC_DOLLAR_COM, DISCONNECT_COM, DROP_COM, 
    EDIT_COM, 
    EXECUTE_COM, EXEC_FUNC_COM, EXEC_HOST_COM, EXEC_PROC_COM, 
    EXIT_COM, FOREIGNKEYS_COM,
    GRANT_COM, HEADING_COM, HELP_COM, HISEDIT_COM, HISRUN_COM, HISTORY_COM,
    INDEX_COM, INSERT_COM, LINESIZE_COM, LOAD_COM, LOCK_COM, MOVE_COM,
    OTHER_COM, PAGESIZE_COM, 
    PRINT_COM, PRINT_IDENT_COM, PRINT_VAR_COM, 
    RENAME_COM, REVOKE_COM, ROLLBACK_COM, 
    SAVE_COM, SAVEPOINT_COM, SCRIPTRUN_COM, SELECT_COM, SET_COM, 
    SHELL_COM, SHOW_COM, SPOOL_COM, SPOOLOFF_COM, 
    TABLES_COM, TERM_COM, TIMESCALE_COM, TIMING_COM, TRANSACTION_COM, TRUNCATE_COM, 
    UPDATE_COM, USER_COM, VAR_DEC_COM, VERBOSE_COM, SEQUENCE_COM,
    XTABLES_COM, VTABLES_COM,
    
    PREP_SELECT_COM, PREP_INSERT_COM, PREP_UPDATE_COM, PREP_DELETE_COM,

    STAT_COM,

    STARTUP_COM,
    STARTUP_PROCESS_COM,
    STARTUP_CONTROL_COM,
    STARTUP_META_COM,
    STARTUP_SERVICE_COM,

    SHUTDOWN_COM,
    SHUTDOWN_NORMAL_COM,
    SHUTDOWN_ABORT_COM,
    SHUTDOWN_IMMEDIATE_COM,
    SHUTDOWN_EXIT_COM,

    TERMINATE_COM
};

enum iSQLOptionKind  
{ 
    iSQL_NON=-1, iSQL_COMMENT=1, iSQL_HEADING=2,
    iSQL_COLSIZE, iSQL_LINESIZE, iSQL_PAGESIZE, 
    iSQL_SHOW_ALL, iSQL_TERM, iSQL_TIMESCALE, iSQL_TIMING, iSQL_USER, iSQL_VERBOSE,
    iSQL_FOREIGNKEYS, iSQL_PLANCOMMIT, iSQL_QUERYLOGGING
};

enum iSQLTimeScale  
{ 
    iSQL_SEC=1, iSQL_MILSEC=2, iSQL_MICSEC, iSQL_NANSEC 
};

enum iSQLVarType
{
    iSQL_BAD=-1, iSQL_BIGINT=1, iSQL_BLOB=2, iSQL_CHAR, iSQL_DATE, 
    iSQL_DECIMAL, iSQL_DOUBLE, iSQL_FLOAT, iSQL_BYTE, iSQL_NIBBLE, 
    iSQL_INTEGER, iSQL_NUMBER, iSQL_NUMERIC, iSQL_REAL, iSQL_SMALLINT, 
    iSQL_VARCHAR, iSQL_GEOMETRY
};

enum iSQLChangeKind
{
    NON_COMMAND=0, CHANGE_COMMAND=1, FIRST_ADD_COMMAND=2, 
    LAST_ADD_COMMAND, DELETE_COMMAND
};

enum iSQLSessionKind
{
    EXPLAIN_PLAN_OFF=0, EXPLAIN_PLAN_ON=1, EXPLAIN_PLAN_ONLY=2
};

enum iSQLPathType
{
    ISQL_PATH_CWD=0, ISQL_PATH_AT=1, ISQL_PATH_HOME=2
};

#ifdef VC_WIN32 
inline void changeSeparator(const char *aFileName, char *aNewFileName)
{
    SInt i = 0;

    for (i=0; aFileName[i]; i++)
    {
        if ( aFileName[i] == '/' )
        {
            aNewFileName[i] = IDL_FILE_SEPARATOR;
        }
        else
        {
            aNewFileName[i] = aFileName[i];
        }
    }
    aNewFileName[i] = 0;
}
#endif

inline FILE *isql_fopen(const char *aFileName, const char *aMode)
{
#ifdef VC_WIN32
    SChar aNewFileName[256];
    
    changeSeparator(aFileName, aNewFileName);

    return idlOS::fopen(aNewFileName, aMode);
#else
    return idlOS::fopen(aFileName, aMode);
#endif
}

#endif // _O_ISQL_H_


