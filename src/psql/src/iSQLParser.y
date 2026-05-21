/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iSQLParser.y 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/

/* ======================================================
   NAME
    iSQLParser.y

   DESCRIPTION
    iSQLPreLexer로부터 넘겨받은 입력버퍼를 parsing.
    이때 isql command만 파싱하고 sql command는 그대로 서버로 전송한다.

   PUBLIC FUNCTION(S)

   PRIVATE FUNCTION(S)

   NOTES

   MODIFIED   (MM/DD/YY)
 ====================================================== */

%pure_parser

%union
{
    char * str;
}

%{
/* This is YACC Source for syntax analysis of iSQL Command Line */
#include <idl.h>
#include <utString.h>
#include <iSQL.h>
#include <iSQLCommand.h>
#include <iSQLHostVarMgr.h>

/*BUGBUG_NT*/
#if defined(VC_WIN32)
#include <malloc.h>
#endif
/*BUGBUG_NT ADD*/

//#define YYINITDEPTH 30
//#define LEX_BODY    0
//#define ERROR_BODY  0

#define YYPARSE_PARAM param
#define YYLEX_PARAM   param

extern utString         gString;
extern iSQLCommand    * gCommand;
extern iSQLHostVarMgr   gHostVarMgr;

extern SChar * gTmpBuf;

iSQLVarType s_HostVarType;
SInt        s_HostVarPrecision;
SChar       s_HostVarScale[WORD_LEN];

void iSQLParserinput(void);
void iSQLParsererror(SChar * s);
SInt iSQLParser_yyinput(SChar *, SInt);
SInt iSQLParserlex(YYSTYPE * lvalp, void * param);
void chkID();

/* To Eliminate WIN32 Compiler making Stack Overflow 
 * with changing local static Array to global static Array
 * (by hjohn. 2003.6.3)
 */
%}

%token ISQL_S_ASSIGN ISQL_S_AT ISQL_T_HOME ISQL_S_COMMA ISQL_S_EQ ISQL_S_LPAREN 
%token ISQL_S_MINUS ISQL_S_PLUS ISQL_S_RPAREN ISQL_S_SEMICOLON

%token ISQL_T_ALL ISQL_T_AUTOCOMMIT ISQL_T_BIGINT 
%token ISQL_T_CHAR ISQL_T_COMMENT 
%token ISQL_T_DATE ISQL_T_DECIMAL ISQL_T_DESC 
%token ISQL_T_DISCONNECT ISQL_T_DOUBLE ISQL_T_EDIT 
%token ISQL_T_EXECUTE ISQL_T_EXIT ISQL_T_FLOAT ISQL_T_FOREIGNKEYS
%token ISQL_T_HEADING ISQL_T_HELP ISQL_T_PLANCOMMIT
%token ISQL_T_QUERYLOGGING
%token ISQL_T_HISTORY ISQL_T_BYTE ISQL_T_NIBBLE 
%token ISQL_T_INDEX ISQL_T_INTEGER ISQL_T_LINESIZE ISQL_T_LOAD 
%token ISQL_T_COLSIZE
%token ISQL_T_MICSEC ISQL_T_MILSEC ISQL_T_NANSEC 
%token ISQL_T_NULL ISQL_T_NUMBER ISQL_T_NUMERIC 
%token ISQL_T_OFF ISQL_T_ON ISQL_T_PAGESIZE ISQL_T_PRINT ISQL_T_QUIT    
%token ISQL_T_REAL ISQL_T_SAVE ISQL_T_SEC ISQL_T_SET ISQL_T_SHOW
%token ISQL_T_SMALLINT ISQL_T_SPOOL ISQL_T_START
%token ISQL_T_TERM ISQL_T_TIMESCALE ISQL_T_TIMING 
%token ISQL_T_USER ISQL_T_VARCHAR ISQL_T_VARIABLE ISQL_T_VERBOSE

%token ISQL_T_STARTUP ISQL_T_SHUTDOWN
%token ISQL_T_PROCESS ISQL_T_CONTROL ISQL_T_META ISQL_T_SERVICE
%token ISQL_T_NORMAL ISQL_T_IMMEDIATE ISQL_T_ABORT
%token ISQL_T_NORM ISQL_T_IMME ISQL_T_ABOR
%token ISQL_T_SESSION ISQL_T_PROPERTY ISQL_T_REPLICATION ISQL_T_DB ISQL_T_MEMORY

%token <str> ISQL_T_ALTER ISQL_T_CRT_PROC 
%token <str> ISQL_T_EXEC_NULL ISQL_T_EXEC_FUNC ISQL_T_EXEC_PROC 
%token <str> ISQL_T_PREPARE
%token <str> ISQL_T_SELECT ISQL_T_TABLES ISQL_T_SEQUENCE ISQL_T_TRANSACTION 
%token <str> ISQL_T_CHECK ISQL_T_COMMIT ISQL_T_CRT_OBJ ISQL_T_DELETE 
%token <str> ISQL_T_DROP ISQL_T_GRANT ISQL_T_INSERT 
%token <str> ISQL_T_LOCK ISQL_T_MOVE ISQL_T_RENAME ISQL_T_REVOKE ISQL_T_ROLLBACK 
%token <str> ISQL_T_SAVEPOINT ISQL_T_TRUNCATE ISQL_T_UPDATE    
%token <str> ISQL_T_CONNECT ISQL_T_SHELL ISQL_T_HISRUN ISQL_T_HISEDIT

%token <str> ISQL_T_CONSTSTR ISQL_T_FILENAME ISQL_T_HOSTVAR 
%token <str> ISQL_T_IDENTIFIER ISQL_T_NATURALNUM ISQL_T_REALNUM 

%token <str> ISQL_T_XTABLES ISQL_T_VTABLES ISQL_T_DOLLAR_ID

%type <str> FILENAME_STAT COMMON_FILENAME_STAT ONLY_FILENAME_STAT HOME_FILENAME_STAT
%type <str> AT_FILENAME_STAT 

%start ISQL_COMMAND

%%

ISQL_COMMAND 
    : ISQL_STATEMENT
    {
#ifdef _ISQL_DEBUG
        idlOS::fprintf(stderr, "%s:%d Rule Accept\n", __FILE__, __LINE__);
#endif
        YYACCEPT;
    }
    ;

ISQL_STATEMENT 
    : ALTER_STAT
    | AUTOCOMMIT_STAT
    //| CHANGE_STAT
    | CHECK_STAT
    | COMMIT_STAT
    | CONNECT_STAT
    | CRT_OBJ_STAT
    | CRT_PROC_STAT
    | DELETE_STAT
    | DESC_STAT
    | DISCONNECT_STAT
    | DROP_STAT
    | EDIT_STAT
    | EXEC_HOST_STAT
    | EXEC_FUNC_STAT
    | EXEC_PROC_STAT
    | EXEC_PREPARE_STAT
    | EXIT_STAT               
    | GRANT_STAT               
    | HELP_STAT
    | HISRUN_STAT
    | HISTORY_STAT
    | INSERT_STAT
    | LOAD_STAT
    | LOCK_STAT
    | MOVE_STAT
    | PRINT_STAT
    | RENAME_STAT
    | REVOKE_STAT
    | ROLLBACK_STAT
    | SAVE_STAT
    | SAVEPOINT_STAT
    | SCRIPT_RUN_STAT
    | SELECT_STAT
    | SET_STAT
    | SHELL_STAT
    | SPOOL_STAT
    | SHOW_STAT
    | TABLES_STAT
    | SEQUENCE_STAT
    | TRANSACTION_STAT
    | TRUNCATE_STAT
    | UPDATE_STAT
    | VAR_STAT
    | ADMIN_COMMAND
    | XTABLES_STAT
    | VTABLES_STAT
    ;

ADMIN_COMMAND 
    : STARTUP_COMMAND
    | SHUTDOWN_COMMAND
    ;

STARTUP_COMMAND 
    : ISQL_T_STARTUP
    {
        gCommand->SetCommandKind(STARTUP_COM);
        idlOS::sprintf(gTmpBuf, "startup\n");
        gCommand->SetCommandStr(gTmpBuf);
    }
    | ISQL_T_STARTUP ISQL_T_PROCESS 
    {
        gCommand->SetCommandKind(STARTUP_PROCESS_COM);
        idlOS::sprintf(gTmpBuf, "startup process\n");
        gCommand->SetCommandStr(gTmpBuf);
    }
    | ISQL_T_STARTUP ISQL_T_CONTROL 
    {
        gCommand->SetCommandKind(STARTUP_CONTROL_COM);
        idlOS::sprintf(gTmpBuf, "startup control\n");
        gCommand->SetCommandStr(gTmpBuf);
    }
    | ISQL_T_STARTUP ISQL_T_META 
    {
        gCommand->SetCommandKind(STARTUP_META_COM);
        idlOS::sprintf(gTmpBuf, "startup meta\n");
        gCommand->SetCommandStr(gTmpBuf);
    }
    | ISQL_T_STARTUP ISQL_T_SERVICE 
    {
        gCommand->SetCommandKind(STARTUP_SERVICE_COM);
        idlOS::sprintf(gTmpBuf, "startup service\n");
        gCommand->SetCommandStr(gTmpBuf);
    }
    | ISQL_T_STARTUP ISQL_T_IDENTIFIER 
    {
        YYABORT;
    }
    ;

SHUTDOWN_COMMAND 
    : ISQL_T_SHUTDOWN ISQL_T_NORMAL 
    {
        gCommand->SetCommandKind(SHUTDOWN_NORMAL_COM);
        idlOS::sprintf(gTmpBuf, "shutdown normal\n");
        gCommand->SetCommandStr(gTmpBuf);
    }
    | ISQL_T_SHUTDOWN ISQL_T_IMMEDIATE 
    {
        gCommand->SetCommandKind(SHUTDOWN_IMMEDIATE_COM);
        idlOS::sprintf(gTmpBuf, "shutdown immediate\n");
        gCommand->SetCommandStr(gTmpBuf);
    }
    | ISQL_T_SHUTDOWN ISQL_T_ABORT 
    {
        gCommand->SetCommandKind(SHUTDOWN_ABORT_COM);
        idlOS::sprintf(gTmpBuf, "shutdown abort\n");
        gCommand->SetCommandStr(gTmpBuf);
    }
    | ISQL_T_SHUTDOWN ISQL_T_EXIT 
    {
        gCommand->SetCommandKind(SHUTDOWN_EXIT_COM);
        idlOS::sprintf(gTmpBuf, "shutdown exit\n");
        gCommand->SetCommandStr(gTmpBuf);
    }
    ;

ALTER_STAT 
    : ISQL_T_ALTER 
    {
        gCommand->SetCommandKind(ALTER_COM);
        gCommand->SetCommandStr($<str>1);
        if ( gCommand->SetQuery($<str>1) != IDE_SUCCESS )
        {
            return ISQL_UNTERMINATED;
        }
    }
    ;

AUTOCOMMIT_STAT 
    : ISQL_T_AUTOCOMMIT on_off end_stmt
    {
        gCommand->SetCommandKind(AUTOCOMMIT_COM);
        idlOS::sprintf(gTmpBuf, "%s %s%s\n", $<str>1, $<str>2, $<str>3);
        gCommand->SetCommandStr(gTmpBuf);
        gCommand->SetOnOff($<str>2);
    }
    ;
/*
CHANGE_STAT 
    : ISQL_T_CHANGECOM
    {
        gCommand->SetCommandKind(CHANGE_COM);
        gCommand->SetCommandStr($<str>1);
        gCommand->SetChangeCommand($<str>1);
    }
    ;
*/
CHECK_STAT 
    : ISQL_T_CHECK 
    {
        gCommand->SetCommandKind(CHECK_COM);
        gCommand->SetCommandStr($<str>1);
        if ( gCommand->SetQuery($<str>1) != IDE_SUCCESS )
        {
            return ISQL_UNTERMINATED;
        }
    }
    ;

COMMIT_STAT 
    : ISQL_T_COMMIT 
    {
        gCommand->SetCommandKind(COMMIT_COM);
        gCommand->SetCommandStr($<str>1);
        if ( gCommand->SetQuery($<str>1) != IDE_SUCCESS )
        {
            return ISQL_UNTERMINATED;
        }
    }
    ;

CONNECT_STAT 
    : ISQL_T_CONNECT 
    {
        SChar * pos1;
        SChar * pos2;
        SChar * pos3;
        SInt    sLen;

        gCommand->SetCommandKind(CONNECT_COM);
        idlOS::sprintf(gTmpBuf, "%s\n", $<str>1);
        gCommand->SetCommandStr(gTmpBuf);

        pos1 = idlOS::strtok(gTmpBuf, " \t");
        if ( pos1 != NULL )
        {
            pos1 = idlOS::strtok(NULL, "\n");
            if ( pos1 != NULL )
            {
                pos2 = idlOS::strchr(pos1, '/');
                if ( pos2 != NULL )
                {
                    *pos2 = '\0';
                    gString.eraseWhiteSpace(pos1);
                    gCommand->SetUserName(pos1);

                    pos2++;
                    gString.eraseWhiteSpace(pos2);
                    sLen = idlOS::strlen(pos2);
                    if ( pos2[sLen-1] == ';' )
                    {
                        pos2[sLen-1] = '\0';
                    }
                    pos3 = idlOS::strtok(pos2, " \t");
                    if ( pos3 != NULL )
                    {
                        gCommand->SetPasswd(pos2);
                        pos1 = idlOS::strtok(NULL, " \t");
                        if ( pos1 != NULL ) // connect user/manager as sysdba
                        {
                            if (idlOS::strcasecmp(pos1, "AS") != 0)
                            {
                                YYABORT;
                            }
                            pos1 = idlOS::strtok(NULL, " \t");
                            if ( pos1 != NULL )
                            {
                                if (idlOS::strcasecmp(pos1, "SYSDBA") == 0)
                                {
                                    gCommand->setSysdba(ID_TRUE);
                                }
                                else
                                {
                                    YYABORT;
                                }
                            }
                            else
                            {
                                YYABORT;
                            }
                        }
                        else // connect user/passwd
                        {
                            gCommand->setSysdba(ID_FALSE);
                        }
                    }
                    else
                    {
                        YYABORT;
                    }
                }
                else
                {
                    YYABORT;
                }
            }
            else
            {
                YYABORT;
            }
        }
        else
        {
            YYABORT;
        }
    }
    ;

CRT_OBJ_STAT 
    : ISQL_T_CRT_OBJ 
    {
        gCommand->SetCommandKind(CRT_OBJ_COM);
        gCommand->SetCommandStr($<str>1);
        if ( gCommand->SetQuery($<str>1) != IDE_SUCCESS )
        {
            return ISQL_UNTERMINATED;
        }
    }
    ;

CRT_PROC_STAT 
    : ISQL_T_CRT_PROC
    {
        SInt    len;

        idlOS::strcpy(gTmpBuf, $<str>1);
        len = idlOS::strlen(gTmpBuf);
        *(gTmpBuf + len - 1) = '\0';
        gString.eraseWhiteSpace(gTmpBuf);
        len = idlOS::strlen(gTmpBuf);

        if ( *(gTmpBuf + len - 1) == '/' )
        {
            gCommand->SetCommandKind(CRT_PROC_COM);
            gCommand->SetCommandStr($<str>1);
            if ( gCommand->SetQuery($<str>1) != IDE_SUCCESS )
            {
                return ISQL_UNTERMINATED;
            }
        }
        else
        {
            return ISQL_UNTERMINATED;
        }
    }
    ;

DELETE_STAT 
    : ISQL_T_DELETE 
    {
        gCommand->SetCommandKind(DELETE_COM);
        gCommand->SetCommandStr($<str>1);
        if ( gCommand->SetQuery($<str>1) != IDE_SUCCESS )
        {
            return ISQL_UNTERMINATED;
        }
    }
    ;

DESC_STAT 
    : ISQL_T_DESC identifier end_stmt
    {
        gCommand->SetCommandKind(DESC_COM);
        idlOS::sprintf(gTmpBuf, "%s %s%s\n", $<str>1, $<str>2, $<str>3);
        gCommand->SetCommandStr(gTmpBuf);
        gCommand->SetUserName((SChar*)"");
        gCommand->SetTableName($<str>2);
    }
    | ISQL_T_DESC ISQL_T_DOLLAR_ID end_stmt
    {
        gCommand->SetCommandKind(DESC_DOLLAR_COM);
        idlOS::sprintf(gTmpBuf, "%s %s%s\n", $<str>1, $<str>2, $<str>3);
        gCommand->SetCommandStr(gTmpBuf);
        gCommand->SetUserName((SChar*)"");
        gCommand->SetTableName($<str>2);
    }
    | ISQL_T_DESC ISQL_T_NULL end_stmt
    {
        gCommand->SetCommandKind(DESC_COM);
        idlOS::sprintf(gTmpBuf, "%s %s%s\n", $<str>1, $<str>2, $<str>3);
        gCommand->SetCommandStr(gTmpBuf);
        gCommand->SetUserName((SChar*)"");
        gCommand->SetTableName($<str>2);
    }
    | ISQL_T_DESC ISQL_T_FILENAME end_stmt
    {
        SChar *pos;

        gCommand->SetCommandKind(DESC_COM);
        idlOS::sprintf(gTmpBuf, "%s %s%s\n", $<str>1, $<str>2, $<str>3);
        gCommand->SetCommandStr(gTmpBuf);

        idlOS::strcpy(gTmpBuf, $<str>2);
        pos = idlOS::strchr(gTmpBuf, '.');
        if (pos != NULL)
        {
            // case : desc username.tablename
            *pos = '\0';
            gCommand->SetUserName(gTmpBuf);
            gCommand->SetTableName(pos+1);
        }   
        else
        {
            // case : desc tablename
            gCommand->SetUserName((SChar*)"");
            gCommand->SetTableName($<str>2);
        }
    }
    ;

DISCONNECT_STAT 
    : ISQL_T_DISCONNECT end_stmt
    {
        gCommand->SetCommandKind(DISCONNECT_COM);
        idlOS::sprintf(gTmpBuf, "%s%s\n", $<str>1, $<str>2);
        gCommand->SetCommandStr(gTmpBuf);
    }
    ;

DROP_STAT 
    : ISQL_T_DROP 
    {
        gCommand->SetCommandKind(DROP_COM);
        gCommand->SetCommandStr($<str>1);
        if ( gCommand->SetQuery($<str>1) != IDE_SUCCESS )
        {
            return ISQL_UNTERMINATED;
        }
    }
    ;

EDIT_STAT
    : ISQL_T_EDIT end_stmt
    {
        gCommand->SetCommandKind(EDIT_COM);
        idlOS::sprintf(gTmpBuf, "%s%s\n", $<str>1, $<str>2);
        gCommand->SetCommandStr(gTmpBuf);
        gCommand->SetFileName((SChar*)"");
    }   
    | ISQL_T_EDIT COMMON_FILENAME_STAT end_stmt
    { 
        gCommand->SetCommandKind(EDIT_COM);
        if ( gCommand->GetPathType() == ISQL_PATH_HOME )
        {
            idlOS::sprintf(gTmpBuf, "%s ?%s%s\n", $<str>1, $<str>2, $<str>3);
        }
        else
        {
            idlOS::sprintf(gTmpBuf, "%s %s%s\n", $<str>1, $<str>2, $<str>3);
        }
        gCommand->SetCommandStr(gTmpBuf);
    }   
    | ISQL_T_HISEDIT 
    {
        SChar * pos;

        gCommand->SetCommandKind(HISEDIT_COM);
        idlOS::sprintf(gTmpBuf, "%s\n", $<str>1);
        gCommand->SetCommandStr(gTmpBuf);

        pos = idlOS::strchr(gTmpBuf, 'E');
        if ( pos == NULL )
        {
            pos = idlOS::strchr(gTmpBuf, 'e');
            if (pos != NULL)
            {
                *pos = '\0';
                gString.eraseWhiteSpace(gTmpBuf);
                gCommand->SetHistoryNo(gTmpBuf);
            }
            else
            {
                // impossible
            }
        }
        else
        {
            *pos = '\0';
            gString.eraseWhiteSpace(gTmpBuf);
            gCommand->SetHistoryNo(gTmpBuf);
        }
    }
    ;

EXEC_HOST_STAT
    : ISQL_T_EXEC_NULL 
    {
        SChar * pos;
        SChar * pos2;

        gCommand->SetCommandKind(EXEC_HOST_COM);
        idlOS::strcpy(gTmpBuf, $<str>1);
        gCommand->SetCommandStr(gTmpBuf);

        pos = idlOS::strchr(gTmpBuf, ':');
        if ( pos != NULL )
        {
            pos2 = idlOS::strtok(pos, " \t:");
            if ( pos2 != NULL )
            {
                gHostVarMgr.setValue(pos2);
            }
        }
    }
    | ISQL_T_EXECUTE ISQL_T_HOSTVAR ISQL_S_ASSIGN ISQL_T_REALNUM end_stmt
    {
        gCommand->SetCommandKind(EXEC_HOST_COM);
        idlOS::sprintf(gTmpBuf, "%s %s %s %s%s\n", 
                $<str>1, $<str>2, $<str>3, $<str>4, $<str>5);
        gCommand->SetCommandStr(gTmpBuf);
        gHostVarMgr.setValue($<str>2+1, $<str>4);
    }
    | ISQL_T_EXECUTE ISQL_T_HOSTVAR ISQL_S_ASSIGN ISQL_T_NATURALNUM end_stmt
    {
        gCommand->SetCommandKind(EXEC_HOST_COM);
        idlOS::sprintf(gTmpBuf, "%s %s %s %s%s\n", 
                $<str>1, $<str>2, $<str>3, $<str>4, $<str>5);
        gCommand->SetCommandStr(gTmpBuf);
        gHostVarMgr.setValue($<str>2+1, $<str>4);
    }
    | ISQL_T_EXECUTE ISQL_T_HOSTVAR ISQL_S_ASSIGN ISQL_T_CONSTSTR end_stmt
    {
        gCommand->SetCommandKind(EXEC_HOST_COM);
        idlOS::sprintf(gTmpBuf, "%s %s %s %s%s\n", 
                $<str>1, $<str>2, $<str>3, $<str>4, $<str>5);
        gCommand->SetCommandStr(gTmpBuf);
        gHostVarMgr.setValue($<str>2+1, $<str>4);
    }
    ;

EXEC_FUNC_STAT
    : ISQL_T_EXEC_FUNC 
    {
        SChar *pos1, *pos2, *pos3;

        gCommand->SetCommandKind(EXEC_FUNC_COM);
        gCommand->SetCommandStr($<str>1);
        if ( gCommand->SetQuery($<str>1) != IDE_SUCCESS )
        {
            return ISQL_UNTERMINATED;
        }

        // pos1 : '='
        // pos2 : '('
        // pos3 : '.'
        idlOS::strcpy(gTmpBuf, $<str>1);
        pos1 = idlOS::strchr(gTmpBuf, '=');
        if (pos1 != NULL)
        {
            pos2 = idlOS::strchr(pos1+1, '(');
            pos3 = idlOS::strchr(pos1+1, '.');
    
            if (pos2 != NULL && pos3 != NULL)
            {
                if (pos2 < pos3)
                {
                    // case : exec :a := funcname(...);
                    *pos2 = '\0';
                    gString.eraseWhiteSpace(pos1+1);
                    gCommand->SetProcName(pos1+1);
                    gCommand->SetUserName((SChar*)"");
                }
                else 
                {
                    // case : exec :a := username.funcname(...);
                    *pos2 = '\0';
                    gString.eraseWhiteSpace(pos3+1);
                    gCommand->SetProcName(pos3+1);
                    *pos3 = '\0';
                    gString.eraseWhiteSpace(pos1+1);
                    gCommand->SetUserName(pos1+1);
                }
            }
            else if (pos2 != NULL)
            {
                // case : exec :a := funcname(...);
                *pos2 = '\0';
                gString.eraseWhiteSpace(pos1+1);
                gCommand->SetProcName(pos1+1);
                gCommand->SetUserName((SChar*)"");
            }
            else if (pos3 != NULL)
            {
                // case : exec :a := username.funcname;
                gString.eraseWhiteSpace(pos3+1);
                gCommand->SetProcName(pos3+1);
                *pos3 = '\0';
                gString.eraseWhiteSpace(pos1+1);
                gCommand->SetUserName(pos1+1);
            }
            else 
            {
                // case : exec :a := funcname;
                gString.eraseWhiteSpace(pos1+1);
                gCommand->SetProcName(pos1+1);
                gCommand->SetUserName((SChar*)"");
            }
        }
        else
        {
            // impossible
        }
    }
    ;

EXEC_PREPARE_STAT
    : ISQL_T_PREPARE ISQL_T_SELECT
    {
        gCommand->SetCommandKind(PREP_SELECT_COM);
        gCommand->SetCommandStr($<str>1, $<str>2);
        if ( gCommand->SetQuery($<str>2) != IDE_SUCCESS )
        {
            return ISQL_UNTERMINATED;
        }
    }
    | ISQL_T_PREPARE ISQL_T_INSERT
    {
        gCommand->SetCommandKind(PREP_INSERT_COM);
        gCommand->SetCommandStr($<str>1, $<str>2);
        if ( gCommand->SetQuery($<str>2) != IDE_SUCCESS )
        {
            return ISQL_UNTERMINATED;
        }
    }
    | ISQL_T_PREPARE ISQL_T_UPDATE
    {
        gCommand->SetCommandKind(PREP_UPDATE_COM);
        gCommand->SetCommandStr($<str>1, $<str>2);
        if ( gCommand->SetQuery($<str>2) != IDE_SUCCESS )
        {
            return ISQL_UNTERMINATED;
        }
    }
    | ISQL_T_PREPARE ISQL_T_DELETE
    {
        gCommand->SetCommandKind(PREP_DELETE_COM);
        gCommand->SetCommandStr($<str>1, $<str>2);
        if ( gCommand->SetQuery($<str>2) != IDE_SUCCESS )
        {
            return ISQL_UNTERMINATED;
        }
    }
    ;

EXEC_PROC_STAT
    : ISQL_T_EXEC_PROC 
    {
        SChar *pos1, *pos2, *pos3;

        gCommand->SetCommandKind(EXEC_PROC_COM);
        gCommand->SetCommandStr($<str>1);
        if ( gCommand->SetQuery($<str>1) != IDE_SUCCESS )
        {
            return ISQL_UNTERMINATED;
        }

        // pos1 : username or procname
        // pos2 : '('
        // pos3 : '.'
        idlOS::strcpy(gTmpBuf, $<str>1);
        pos1 = idlOS::strtok(gTmpBuf, " \t\n");
        if (pos1 != NULL)
        {
            pos1 = idlOS::strtok(NULL, " \t\n");
            if (pos1 != NULL)
            {
                pos2 = idlOS::strchr(pos1, '(');
                pos3 = idlOS::strchr(pos1, '.');
            
                if (pos2 != NULL && pos3 != NULL)
                {
                    if (pos2 < pos3)
                    {
                        // case : exec procname(...);
                        *pos2 = '\0';
                        gString.eraseWhiteSpace(pos1);
                        gCommand->SetProcName(pos1);
                        gCommand->SetUserName((SChar*)"");
                    }
                    else 
                    {
                        // case : exec username.procname(...);
                        *pos2 = '\0';
                        gString.eraseWhiteSpace(pos3+1);
                        gCommand->SetProcName(pos3+1);
                        *pos3 = '\0';
                        gString.eraseWhiteSpace(pos1);
                        gCommand->SetUserName(pos1);
                    }
                }
                else if (pos2 != NULL)
                {
                    // case : exec procname(...);
                    *pos2 = '\0';
                    gString.eraseWhiteSpace(pos1);
                    gCommand->SetProcName(pos1);
                    gCommand->SetUserName((SChar*)"");
                }
                else if (pos3 != NULL)
                {
                    // case : exec username.procname;
                    gString.eraseWhiteSpace(pos3+1);
                    gCommand->SetProcName(pos3+1);
                    *pos3 = '\0';
                    gString.eraseWhiteSpace(pos1);
                    gCommand->SetUserName(pos1);
                }
                else 
                {
                    // case : exec procname;
                    gString.eraseWhiteSpace(pos1);
                    gCommand->SetProcName(pos1);
                    gCommand->SetUserName((SChar*)"");
                }
            }
            else
            {
                // impossible
            }
        }
        else
        {
            // impossible
        }
    }
    ;

EXIT_STAT 
    : ISQL_T_EXIT end_stmt
    {
        gCommand->SetCommandKind(EXIT_COM);
        idlOS::sprintf(gTmpBuf, "%s%s\n", $<str>1, $<str>2);
        gCommand->SetCommandStr(gTmpBuf);
    }
    | ISQL_T_QUIT end_stmt
    {
        gCommand->SetCommandKind(EXIT_COM);
        idlOS::sprintf(gTmpBuf, "%s%s\n", $<str>1, $<str>2);
        gCommand->SetCommandStr(gTmpBuf);
    }
    ;

GRANT_STAT 
    : ISQL_T_GRANT
    {
        gCommand->SetCommandKind(GRANT_COM);
        gCommand->SetCommandStr($<str>1);
        if ( gCommand->SetQuery($<str>1) != IDE_SUCCESS )
        {
            return ISQL_UNTERMINATED;
        }
    }
    ;

HELP_STAT 
    : ISQL_T_HELP end_stmt
    {
        gCommand->SetCommandKind(HELP_COM);
        gCommand->SetHelpKind(NON_COM);
        sprintf(gTmpBuf, "%s%s\n", $<str>1, $<str>2);
        gCommand->SetCommandStr(gTmpBuf);
    }
    | ISQL_T_HELP ISQL_S_AT end_stmt
    {
        gCommand->SetCommandKind(HELP_COM);
        gCommand->SetHelpKind(SCRIPTRUN_COM);
        sprintf(gTmpBuf, "%s %s%s\n", $<str>1, $<str>2, $<str>3);
        gCommand->SetCommandStr(gTmpBuf);
    }
    | ISQL_T_HELP ISQL_T_HISRUN end_stmt
    {
        gCommand->SetCommandKind(HELP_COM);
        gCommand->SetHelpKind(HISRUN_COM);
        sprintf(gTmpBuf, "%s %s%s\n", $<str>1, $<str>2, $<str>3);
        gCommand->SetCommandStr(gTmpBuf);
    }
    | ISQL_T_HELP ISQL_T_SHELL end_stmt
    {
        gCommand->SetCommandKind(HELP_COM);
        gCommand->SetHelpKind(SHELL_COM);
        sprintf(gTmpBuf, "%s %s%s\n", $<str>1, $<str>2, $<str>3);
        gCommand->SetCommandStr(gTmpBuf);
    }
    | ISQL_T_HELP ISQL_T_NULL end_stmt
    {
        gCommand->SetCommandKind(HELP_COM);
        gCommand->SetHelpKind(OTHER_COM);
        sprintf(gTmpBuf, "%s %s%s\n", $<str>1, $<str>2, $<str>3);
        gCommand->SetCommandStr(gTmpBuf);
    }
    | ISQL_T_HELP identifier end_stmt
    {
        gCommand->SetCommandKind(HELP_COM);
        sprintf(gTmpBuf, "%s %s%s\n", $<str>1, $<str>2, $<str>3);
        gCommand->SetCommandStr(gTmpBuf);
    }
    ;

HISRUN_STAT 
    : ISQL_T_HISRUN 
    {
        SChar * pos;

        gCommand->SetCommandKind(HISRUN_COM);
        sprintf(gTmpBuf, "%s\n", $<str>1);
        gString.eraseWhiteSpace(gTmpBuf);
        pos = idlOS::strchr(gTmpBuf, '/');
        if ( pos != NULL )
        {
            if ( gTmpBuf == pos )
            {
                gCommand->SetHistoryNo((SChar*)"0");
            }
            else
            {
                *pos = '\0';
                gString.eraseWhiteSpace(gTmpBuf);
                gCommand->SetHistoryNo(gTmpBuf);
            }
        }
        else
        {
            // impossible
        }
    }
    ;

HISTORY_STAT 
    : ISQL_T_HISTORY end_stmt
    {
        gCommand->SetCommandKind(HISTORY_COM);
        idlOS::sprintf(gTmpBuf, "%s%s\n", $<str>1, $<str>2);
        gCommand->SetCommandStr(gTmpBuf);
    }
    ;

INSERT_STAT 
    : ISQL_T_INSERT 
    {
        gCommand->SetCommandKind(INSERT_COM);
        gCommand->SetCommandStr($<str>1);
        if ( gCommand->SetQuery($<str>1) != IDE_SUCCESS )
        {
            return ISQL_UNTERMINATED;
        }
    }
    ;

LOAD_STAT 
    : ISQL_T_LOAD COMMON_FILENAME_STAT end_stmt
    {
        gCommand->SetCommandKind(LOAD_COM);
        if ( gCommand->GetPathType() == ISQL_PATH_HOME )
        {
            idlOS::sprintf(gTmpBuf, "%s ?%s%s\n", $<str>1, $<str>2, $<str>3);
        }
        else
        {
            idlOS::sprintf(gTmpBuf, "%s %s%s\n", $<str>1, $<str>2, $<str>3);
        }
        gCommand->SetCommandStr(gTmpBuf);
    }
    ;

LOCK_STAT 
    : ISQL_T_LOCK
    {
        gCommand->SetCommandKind(LOCK_COM);
        gCommand->SetCommandStr($<str>1);
        if ( gCommand->SetQuery($<str>1) != IDE_SUCCESS )
        {
            return ISQL_UNTERMINATED;
        }
    }
    ;

MOVE_STAT 
    : ISQL_T_MOVE 
    {
        gCommand->SetCommandKind(MOVE_COM);
        gCommand->SetCommandStr($<str>1);
        if ( gCommand->SetQuery($<str>1) != IDE_SUCCESS )
        {
            return ISQL_UNTERMINATED;
        }
    }
    ;

PRINT_STAT
    : ISQL_T_PRINT identifier end_stmt 
    {
        if ( idlOS::strcasecmp($<str>2, "var") == 0 ||
             idlOS::strcasecmp($<str>2, "variable") == 0 )
        {
            gCommand->SetCommandKind(PRINT_VAR_COM);
        }
        else
        {
            gCommand->SetCommandKind(PRINT_IDENT_COM);
            gCommand->SetHostVarName($<str>2);
        }
        idlOS::sprintf(gTmpBuf, "%s %s%s\n", $<str>1, $<str>2, $<str>3);
        gCommand->SetCommandStr((SChar*)gTmpBuf);
    }
    | ISQL_T_PRINT ISQL_T_NULL end_stmt 
    {
        gCommand->SetCommandKind(PRINT_IDENT_COM);
        gCommand->SetHostVarName($<str>2);
        idlOS::sprintf(gTmpBuf, "%s %s%s\n", $<str>1, $<str>2, $<str>3);
        gCommand->SetCommandStr((SChar*)gTmpBuf);
    }
    ;

RENAME_STAT 
    : ISQL_T_RENAME
    {
        gCommand->SetCommandKind(RENAME_COM);
        gCommand->SetCommandStr($<str>1);
        if ( gCommand->SetQuery($<str>1) != IDE_SUCCESS )
        {
            return ISQL_UNTERMINATED;
        }
    }
    ;

REVOKE_STAT 
    : ISQL_T_REVOKE
    {
        gCommand->SetCommandKind(REVOKE_COM);
        gCommand->SetCommandStr($<str>1);
        if ( gCommand->SetQuery($<str>1) != IDE_SUCCESS )
        {
            return ISQL_UNTERMINATED;
        }
    }
    ;

ROLLBACK_STAT 
    : ISQL_T_ROLLBACK 
    {
        gCommand->SetCommandKind(ROLLBACK_COM);
        gCommand->SetCommandStr($<str>1);
        if ( gCommand->SetQuery($<str>1) != IDE_SUCCESS )
        {
            return ISQL_UNTERMINATED;
        }
    }
    ;

SAVE_STAT 
    : ISQL_T_SAVE COMMON_FILENAME_STAT end_stmt
    {
        gCommand->SetCommandKind(SAVE_COM);
        if ( gCommand->GetPathType() == ISQL_PATH_HOME )
        {
            idlOS::sprintf(gTmpBuf, "%s ?%s%s\n", $<str>1, $<str>2, $<str>3);
        }
        else
        {
            idlOS::sprintf(gTmpBuf, "%s %s%s\n", $<str>1, $<str>2, $<str>3);
        }
        gCommand->SetCommandStr(gTmpBuf);
    }
    ;

SAVEPOINT_STAT 
    : ISQL_T_SAVEPOINT 
    {
        gCommand->SetCommandKind(SAVEPOINT_COM);
        gCommand->SetCommandStr($<str>1);
        if ( gCommand->SetQuery($<str>1) != IDE_SUCCESS )
        {
            return ISQL_UNTERMINATED;
        }
    }
    ;

SCRIPT_RUN_STAT 
    : ISQL_T_START COMMON_FILENAME_STAT end_stmt  
    { 
        gCommand->SetCommandKind(SCRIPTRUN_COM);
        if ( gCommand->GetPathType() == ISQL_PATH_HOME )
        {
            idlOS::sprintf(gTmpBuf, "%s ?%s%s\n", $<str>1, $<str>2, $<str>3);
        }
        else
        {
            idlOS::sprintf(gTmpBuf, "%s %s%s\n", $<str>1, $<str>2, $<str>3);
        }
        gCommand->SetCommandStr(gTmpBuf);
    }
    | ISQL_S_AT FILENAME_STAT end_stmt  
    { 
        gCommand->SetCommandKind(SCRIPTRUN_COM);
        if ( gCommand->GetPathType() == ISQL_PATH_AT )
        {
            idlOS::sprintf(gTmpBuf, "%s@%s%s\n", $<str>1, $<str>2, $<str>3);
        }
        else if ( gCommand->GetPathType() == ISQL_PATH_HOME )
        {
            idlOS::sprintf(gTmpBuf, "%s?%s%s\n", $<str>1, $<str>2, $<str>3);
        }
        else
        {
            idlOS::sprintf(gTmpBuf, "%s %s%s\n", $<str>1, $<str>2, $<str>3);
        }
        gCommand->SetCommandStr(gTmpBuf);
    }
    ;

COMMON_FILENAME_STAT
    : ONLY_FILENAME_STAT 
    {
        $$ = $<str>1;
    }
    | HOME_FILENAME_STAT 
    {
        $$ = $<str>1;
    }
    ;

FILENAME_STAT
    : ONLY_FILENAME_STAT 
    {
        $$ = $<str>1;
    }
    | HOME_FILENAME_STAT 
    {
        $$ = $<str>1;
    }
    | AT_FILENAME_STAT 
    {
        $$ = $<str>1;
    }
    ;

ONLY_FILENAME_STAT
    : identifier 
    {
        gCommand->SetFileName($<str>1);
        $$ = $<str>1;
    }
    | ISQL_T_NULL 
    {
        gCommand->SetFileName($<str>1);
        $$ = $<str>1;
    }
    | ISQL_T_FILENAME 
    {
        gCommand->SetFileName($<str>1);
        $$ = $<str>1;
    }
    ;

HOME_FILENAME_STAT
    : ISQL_T_HOME identifier 
    {
        gCommand->SetFileName($<str>2, ISQL_PATH_HOME);
        $$ = $<str>2;
    }
    | ISQL_T_HOME ISQL_T_NULL 
    {
        gCommand->SetFileName($<str>2, ISQL_PATH_HOME);
        $$ = $<str>2;
    }
    | ISQL_T_HOME ISQL_T_FILENAME 
    {
        gCommand->SetFileName($<str>2, ISQL_PATH_HOME);
        $$ = $<str>2;
    }
    ;

AT_FILENAME_STAT
    : ISQL_S_AT identifier 
    {
        gCommand->SetFileName($<str>2, ISQL_PATH_AT);
        $$ = $<str>2;
    }
    | ISQL_S_AT ISQL_T_NULL 
    {
        gCommand->SetFileName($<str>2, ISQL_PATH_AT);
        $$ = $<str>2;
    }
    | ISQL_S_AT ISQL_T_FILENAME 
    {
        gCommand->SetFileName($<str>2, ISQL_PATH_AT);
        $$ = $<str>2;
    }
    ;

SELECT_STAT 
    : ISQL_T_SELECT 
    {
        gCommand->SetCommandKind(SELECT_COM);
        gCommand->SetCommandStr($<str>1);
        if ( gCommand->SetQuery($<str>1) != IDE_SUCCESS )
        {
            return ISQL_UNTERMINATED;
        }
    }
    ;

SET_STAT 
    : ISQL_T_SET identifier ISQL_S_EQ identifier ISQL_S_SEMICOLON
    {
        gCommand->SetCommandKind(SET_COM);
        gCommand->SetiSQLOptionKind(iSQL_NON);
        idlOS::sprintf(gTmpBuf, "%s %s %s %s%s\n", 
                $<str>1, $<str>2, $<str>3, $<str>4, $<str>5);
        gCommand->SetCommandStr(gTmpBuf);
        gCommand->SetQuery(gTmpBuf);
    }
    | ISQL_T_SET ISQL_T_COMMENT on_off end_stmt
    {
        gCommand->SetCommandKind(SET_COM);
        gCommand->SetiSQLOptionKind(iSQL_COMMENT);
        idlOS::sprintf(gTmpBuf, "%s %s %s%s\n", 
                $<str>1, $<str>2, $<str>3, $<str>4);
        gCommand->SetCommandStr(gTmpBuf);
        gCommand->SetOnOff($<str>3);
    }
    | ISQL_T_SET ISQL_T_HEADING on_off end_stmt
    {
        gCommand->SetCommandKind(SET_COM);
        gCommand->SetiSQLOptionKind(iSQL_HEADING);
        idlOS::sprintf(gTmpBuf, "%s %s %s%s\n", 
                $<str>1, $<str>2, $<str>3, $<str>4);
        gCommand->SetCommandStr(gTmpBuf);
        gCommand->SetOnOff($<str>3);
    }
    | ISQL_T_SET ISQL_T_FOREIGNKEYS on_off end_stmt
    {
        gCommand->SetCommandKind(SET_COM);
        gCommand->SetiSQLOptionKind(iSQL_FOREIGNKEYS);
        idlOS::sprintf(gTmpBuf, "%s %s %s%s\n", 
                $<str>1, $<str>2, $<str>3, $<str>4);
        gCommand->SetCommandStr(gTmpBuf);
        gCommand->SetOnOff($<str>3);
    }
    | ISQL_T_SET ISQL_T_PLANCOMMIT on_off end_stmt
    {
        gCommand->SetCommandKind(SET_COM);
        gCommand->SetiSQLOptionKind(iSQL_PLANCOMMIT);
        idlOS::sprintf(gTmpBuf, "%s %s %s%s\n", 
                $<str>1, $<str>2, $<str>3, $<str>4);
        gCommand->SetCommandStr(gTmpBuf);
        gCommand->SetOnOff($<str>3);
    }
    | ISQL_T_SET ISQL_T_QUERYLOGGING on_off end_stmt
    {
        gCommand->SetCommandKind(SET_COM);
        gCommand->SetiSQLOptionKind(iSQL_QUERYLOGGING);
        idlOS::sprintf(gTmpBuf, "%s %s %s%s\n", 
                $<str>1, $<str>2, $<str>3, $<str>4);
        gCommand->SetCommandStr(gTmpBuf);
        gCommand->SetOnOff($<str>3);
    }
    | ISQL_T_SET ISQL_T_COLSIZE ISQL_T_NATURALNUM end_stmt
    {
        gCommand->SetCommandKind(SET_COM);
        gCommand->SetiSQLOptionKind(iSQL_COLSIZE);
        idlOS::sprintf(gTmpBuf, "%s %s %s%s\n", 
                $<str>1, $<str>2, $<str>3, $<str>4);
        gCommand->SetCommandStr(gTmpBuf);
        gCommand->SetColsize($<str>3);
    }
    | ISQL_T_SET ISQL_T_LINESIZE ISQL_T_NATURALNUM end_stmt
    {
        gCommand->SetCommandKind(SET_COM);
        gCommand->SetiSQLOptionKind(iSQL_LINESIZE);
        idlOS::sprintf(gTmpBuf, "%s %s %s%s\n", 
                $<str>1, $<str>2, $<str>3, $<str>4);
        gCommand->SetCommandStr(gTmpBuf);
        gCommand->SetLinesize($<str>3);
    }
    | ISQL_T_SET ISQL_T_PAGESIZE ISQL_T_NATURALNUM end_stmt
    {
        gCommand->SetCommandKind(SET_COM);
        gCommand->SetiSQLOptionKind(iSQL_PAGESIZE);
        idlOS::sprintf(gTmpBuf, "%s %s %s%s\n", 
                $<str>1, $<str>2, $<str>3, $<str>4);
        gCommand->SetCommandStr(gTmpBuf);
        gCommand->SetPagesize($<str>3);
    }
    | ISQL_T_SET ISQL_T_TERM on_off end_stmt
    {
        gCommand->SetCommandKind(SET_COM);
        gCommand->SetiSQLOptionKind(iSQL_TERM);
        idlOS::sprintf(gTmpBuf, "%s %s %s%s\n", 
                $<str>1, $<str>2, $<str>3, $<str>4);
        gCommand->SetCommandStr(gTmpBuf);
        gCommand->SetOnOff($<str>3);
    }
    | ISQL_T_SET ISQL_T_TIMESCALE time_scale end_stmt
    {
        gCommand->SetCommandKind(SET_COM);
        gCommand->SetiSQLOptionKind(iSQL_TIMESCALE);
        idlOS::sprintf(gTmpBuf, "%s %s %s%s\n", 
                $<str>1, $<str>2, $<str>3, $<str>4);
        gCommand->SetCommandStr(gTmpBuf);
    }
    | ISQL_T_SET ISQL_T_TIMING on_off end_stmt
    {
        gCommand->SetCommandKind(SET_COM);
        gCommand->SetiSQLOptionKind(iSQL_TIMING);
        idlOS::sprintf(gTmpBuf, "%s %s %s%s\n", 
                $<str>1, $<str>2, $<str>3, $<str>4);
        gCommand->SetCommandStr(gTmpBuf);
        gCommand->SetOnOff($<str>3);
    }
    | ISQL_T_SET ISQL_T_VERBOSE on_off end_stmt
    {
        gCommand->SetCommandKind(SET_COM);
        gCommand->SetiSQLOptionKind(iSQL_VERBOSE);
        idlOS::sprintf(gTmpBuf, "%s %s %s%s\n", 
                $<str>1, $<str>2, $<str>3, $<str>4);
        gCommand->SetCommandStr(gTmpBuf);
        gCommand->SetOnOff($<str>3);
    }
    ;

SHELL_STAT
    : ISQL_T_SHELL
    {
        SChar *pos;

        gCommand->SetCommandKind(SHELL_COM);
        idlOS::sprintf(gTmpBuf, "%s\n", $<str>1);
        gCommand->SetCommandStr(gTmpBuf);
        pos = idlOS::strrchr(gTmpBuf, '!');
        if (pos != NULL)
        {
            gCommand->SetShellCommand(pos+1);
        }
        else
        {
            // impossible
        }
    }
    ;

SPOOL_STAT 
    : ISQL_T_SPOOL identifier end_stmt   
    {
        if ( idlOS::strcasecmp($<str>2, "off") == 0 )
        {
            gCommand->SetCommandKind(SPOOLOFF_COM);
        }
        else
        {
            gCommand->SetCommandKind(SPOOL_COM);
            gCommand->SetFileName($<str>2);
        }
        idlOS::sprintf(gTmpBuf, "%s %s%s\n", $<str>1, $<str>2, $<str>3);
        gCommand->SetCommandStr(gTmpBuf);
    }
    | ISQL_T_SPOOL ISQL_T_NULL end_stmt   
    {
        gCommand->SetCommandKind(SPOOL_COM);
        gCommand->SetFileName($<str>2);
        idlOS::sprintf(gTmpBuf, "%s %s%s\n", $<str>1, $<str>2, $<str>3);
        gCommand->SetCommandStr(gTmpBuf);
    }
    | ISQL_T_SPOOL ISQL_T_FILENAME end_stmt   
    {
        gCommand->SetCommandKind(SPOOL_COM);
        gCommand->SetFileName($<str>2);
        idlOS::sprintf(gTmpBuf, "%s %s%s\n", $<str>1, $<str>2, $<str>3);
        gCommand->SetCommandStr(gTmpBuf);
    }
    | ISQL_T_SPOOL HOME_FILENAME_STAT end_stmt   
    {
        gCommand->SetCommandKind(SPOOL_COM);
        idlOS::sprintf(gTmpBuf, "%s ?%s%s\n", $<str>1, $<str>2, $<str>3);
        gCommand->SetCommandStr(gTmpBuf);
    }
    ;

SHOW_STAT 
    : ISQL_T_SHOW ISQL_T_ALL end_stmt
    {
        gCommand->SetCommandKind(SHOW_COM);
        gCommand->SetiSQLOptionKind(iSQL_SHOW_ALL);
        idlOS::sprintf(gTmpBuf, "%s %s%s\n", $<str>1, $<str>2, $<str>3);
        gCommand->SetCommandStr(gTmpBuf);
    }
    | ISQL_T_SHOW ISQL_T_COMMENT end_stmt
    {
        gCommand->SetCommandKind(SHOW_COM);
        gCommand->SetiSQLOptionKind(iSQL_COMMENT);
        idlOS::sprintf(gTmpBuf, "%s %s%s\n", $<str>1, $<str>2, $<str>3);
        gCommand->SetCommandStr(gTmpBuf);
    }
    | ISQL_T_SHOW ISQL_T_HEADING end_stmt
    {
        gCommand->SetCommandKind(SHOW_COM);
        gCommand->SetiSQLOptionKind(iSQL_HEADING);
        idlOS::sprintf(gTmpBuf, "%s %s%s\n", $<str>1, $<str>2, $<str>3);
        gCommand->SetCommandStr(gTmpBuf);
    }
    | ISQL_T_SHOW ISQL_T_FOREIGNKEYS end_stmt
    {
        gCommand->SetCommandKind(SHOW_COM);
        gCommand->SetiSQLOptionKind(iSQL_FOREIGNKEYS);
        idlOS::sprintf(gTmpBuf, "%s %s%s\n", $<str>1, $<str>2, $<str>3);
        gCommand->SetCommandStr(gTmpBuf);
    }
    | ISQL_T_SHOW ISQL_T_COLSIZE end_stmt
    {
        gCommand->SetCommandKind(SHOW_COM);
        gCommand->SetiSQLOptionKind(iSQL_COLSIZE);
        idlOS::sprintf(gTmpBuf, "%s %s%s\n", $<str>1, $<str>2, $<str>3);
        gCommand->SetCommandStr(gTmpBuf);
    }
    | ISQL_T_SHOW ISQL_T_LINESIZE end_stmt
    {
        gCommand->SetCommandKind(SHOW_COM);
        gCommand->SetiSQLOptionKind(iSQL_LINESIZE);
        idlOS::sprintf(gTmpBuf, "%s %s%s\n", $<str>1, $<str>2, $<str>3);
        gCommand->SetCommandStr(gTmpBuf);
    }
    | ISQL_T_SHOW ISQL_T_PAGESIZE end_stmt
    {
        gCommand->SetCommandKind(SHOW_COM);
        gCommand->SetiSQLOptionKind(iSQL_PAGESIZE);
        idlOS::sprintf(gTmpBuf, "%s %s%s\n", $<str>1, $<str>2, $<str>3);
        gCommand->SetCommandStr(gTmpBuf);
    }
    | ISQL_T_SHOW ISQL_T_TERM end_stmt
    {
        gCommand->SetCommandKind(SHOW_COM);
        gCommand->SetiSQLOptionKind(iSQL_TERM);
        idlOS::sprintf(gTmpBuf, "%s %s%s\n", $<str>1, $<str>2, $<str>3);
        gCommand->SetCommandStr(gTmpBuf);
    }
    | ISQL_T_SHOW ISQL_T_TIMESCALE end_stmt
    {
        gCommand->SetCommandKind(SHOW_COM);
        gCommand->SetiSQLOptionKind(iSQL_TIMESCALE);
        idlOS::sprintf(gTmpBuf, "%s %s%s\n", $<str>1, $<str>2, $<str>3);
        gCommand->SetCommandStr(gTmpBuf);
    }
    | ISQL_T_SHOW ISQL_T_TIMING end_stmt
    {
        gCommand->SetCommandKind(SHOW_COM);
        gCommand->SetiSQLOptionKind(iSQL_TIMING);
        idlOS::sprintf(gTmpBuf, "%s %s%s\n", $<str>1, $<str>2, $<str>3);
        gCommand->SetCommandStr(gTmpBuf);
    }
    | ISQL_T_SHOW ISQL_T_USER end_stmt
    {
        gCommand->SetCommandKind(SHOW_COM);
        gCommand->SetiSQLOptionKind(iSQL_USER);
        idlOS::sprintf(gTmpBuf, "%s %s%s\n", $<str>1, $<str>2, $<str>3);
        gCommand->SetCommandStr(gTmpBuf);
    }
    | ISQL_T_SHOW ISQL_T_VERBOSE end_stmt
    {
        gCommand->SetCommandKind(SHOW_COM);
        gCommand->SetiSQLOptionKind(iSQL_VERBOSE);
        idlOS::sprintf(gTmpBuf, "%s %s%s\n", $<str>1, $<str>2, $<str>3);
        gCommand->SetCommandStr(gTmpBuf);
    }
    ;

TABLES_STAT 
    : ISQL_T_TABLES 
    {
        gCommand->SetCommandKind(TABLES_COM);
        gCommand->SetCommandStr($<str>1);
    }
    ;

XTABLES_STAT 
    : ISQL_T_XTABLES 
    {
        gCommand->SetCommandKind(XTABLES_COM);
        gCommand->SetCommandStr($<str>1);
    }
    ;

VTABLES_STAT 
    : ISQL_T_VTABLES 
    {
        gCommand->SetCommandKind(VTABLES_COM);
        gCommand->SetCommandStr($<str>1);
    }
    ;

SEQUENCE_STAT
    : ISQL_T_SEQUENCE 
    {
        gCommand->SetCommandKind(SEQUENCE_COM);
        gCommand->SetCommandStr($<str>1);
    }
    ;

TRANSACTION_STAT
    : ISQL_T_TRANSACTION
    {
        gCommand->SetCommandKind(TRANSACTION_COM);
        gCommand->SetCommandStr($<str>1);
        if ( gCommand->SetQuery($<str>1) != IDE_SUCCESS )
        {
            return ISQL_UNTERMINATED;
        }
    }
    ;

TRUNCATE_STAT
    : ISQL_T_TRUNCATE 
    {
        gCommand->SetCommandKind(TRUNCATE_COM);
        gCommand->SetCommandStr($<str>1);
        if ( gCommand->SetQuery($<str>1) != IDE_SUCCESS )
        {
            return ISQL_UNTERMINATED;
        }
    }
    ;

UPDATE_STAT 
    : ISQL_T_UPDATE 
    {
        gCommand->SetCommandKind(UPDATE_COM);
        gCommand->SetCommandStr($<str>1);
        if ( gCommand->SetQuery($<str>1) != IDE_SUCCESS )
        {
            return ISQL_UNTERMINATED;
        }
    }
    ;

VAR_STAT
    : ISQL_T_VARIABLE identifier rule_data_type end_stmt 
    {
        gCommand->SetCommandKind(VAR_DEC_COM);
        idlOS::sprintf(gTmpBuf, "%s %s %s%s\n", 
                $<str>1, $<str>2, $<str>3, $<str>4);
        gCommand->SetCommandStr(gTmpBuf);
        gHostVarMgr.add($<str>2, s_HostVarType, 
                        s_HostVarPrecision, s_HostVarScale);
    }
    ;

rule_data_type
    : ISQL_T_BIGINT
    {
        s_HostVarType = iSQL_BIGINT;
        s_HostVarPrecision = -1;
        idlOS::strcpy(s_HostVarScale, (SChar*)"");
        idlOS::strcpy($<str>$, $<str>1); 
    }
/*    | ISQL_T_BLOB
    {
        s_HostVarType = iSQL_BLOB;
        s_HostVarPrecision = 1;
        idlOS::strcpy(s_HostVarScale, (SChar*)"");
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_BLOB ISQL_S_LPAREN ISQL_T_NATURALNUM ISQL_S_RPAREN
    {
        s_HostVarType = iSQL_BLOB;
        s_HostVarPrecision = atoi($<str>3);
        idlOS::strcpy(s_HostVarScale, (SChar*)"");
        idlOS::sprintf(gTmpBuf, "%s%s%s%s", 
                $<str>1, $<str>2, $<str>3, $<str>4);
        idlOS::strcpy($<str>$, gTmpBuf); 
    }
*/    | ISQL_T_CHAR
    {
        s_HostVarType = iSQL_CHAR;
        s_HostVarPrecision = 1;
        idlOS::strcpy(s_HostVarScale, (SChar*)"");
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_CHAR ISQL_S_LPAREN ISQL_T_NATURALNUM ISQL_S_RPAREN
    {
        s_HostVarType = iSQL_CHAR;
        s_HostVarPrecision = atoi($<str>3);
        idlOS::strcpy(s_HostVarScale, (SChar*)"");
        idlOS::sprintf(gTmpBuf, "%s%s%s%s", 
                $<str>1, $<str>2, $<str>3, $<str>4);
        idlOS::strcpy($<str>$, gTmpBuf); 
    }
    | ISQL_T_DATE
    {
        s_HostVarType = iSQL_DATE;
        s_HostVarPrecision = -1;
        idlOS::strcpy(s_HostVarScale, (SChar*)"");
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_DECIMAL
    {
        s_HostVarType = iSQL_DECIMAL;
        s_HostVarPrecision = -1;
        idlOS::strcpy(s_HostVarScale, (SChar*)"");
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_DECIMAL ISQL_S_LPAREN ISQL_T_NATURALNUM ISQL_S_RPAREN
    {
        s_HostVarType = iSQL_DECIMAL;
        s_HostVarPrecision = atoi($<str>3);
        idlOS::strcpy(s_HostVarScale, (SChar*)"");
        idlOS::sprintf(gTmpBuf, "%s%s%s%s", 
                $<str>1, $<str>2, $<str>3, $<str>4);
        idlOS::strcpy($<str>$, gTmpBuf); 
    }
    | ISQL_T_DECIMAL ISQL_S_LPAREN ISQL_T_NATURALNUM  ISQL_S_COMMA 
      ISQL_T_NATURALNUM ISQL_S_RPAREN
    {
        s_HostVarType = iSQL_DECIMAL;
        s_HostVarPrecision = atoi($<str>3);
        idlOS::strcpy(s_HostVarScale, $<str>5);
        idlOS::sprintf(gTmpBuf, "%s%s%s%s %s%s", 
                $<str>1, $<str>2, $<str>3, $<str>4, $<str>5, $<str>6);
        idlOS::strcpy($<str>$, gTmpBuf); 
    }
    | ISQL_T_DECIMAL ISQL_S_LPAREN ISQL_T_NATURALNUM  ISQL_S_COMMA 
      ISQL_S_PLUS ISQL_T_NATURALNUM ISQL_S_RPAREN
    {
        s_HostVarType = iSQL_DECIMAL;
        s_HostVarPrecision = atoi($<str>3);
        idlOS::sprintf(gTmpBuf, "%s%s", $<str>5, $<str>6);
        idlOS::strcpy(s_HostVarScale, gTmpBuf);
        idlOS::sprintf(gTmpBuf, "%s%s%s%s %s%s%s", 
                $<str>1, $<str>2, $<str>3, $<str>4, $<str>5, $<str>6, $<str>7);
        idlOS::strcpy($<str>$, gTmpBuf); 
    }
    | ISQL_T_DECIMAL ISQL_S_LPAREN ISQL_T_NATURALNUM  ISQL_S_COMMA 
      ISQL_S_MINUS ISQL_T_NATURALNUM ISQL_S_RPAREN
    {
        s_HostVarType = iSQL_DECIMAL;
        s_HostVarPrecision = atoi($<str>3);
        idlOS::sprintf(gTmpBuf, "%s%s", $<str>5, $<str>6);
        idlOS::strcpy(s_HostVarScale, gTmpBuf);
        idlOS::sprintf(gTmpBuf, "%s%s%s%s %s%s%s", 
                $<str>1, $<str>2, $<str>3, $<str>4, $<str>5, $<str>6, $<str>7);
        idlOS::strcpy($<str>$, gTmpBuf); 
    }
    | ISQL_T_DOUBLE
    {
        s_HostVarType = iSQL_DOUBLE;
        s_HostVarPrecision = -1;
        idlOS::strcpy(s_HostVarScale, (SChar*)"");
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_FLOAT
    {
        s_HostVarType = iSQL_FLOAT;
        s_HostVarPrecision = -1;
        idlOS::strcpy(s_HostVarScale, (SChar*)"");
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_FLOAT ISQL_S_LPAREN ISQL_T_NATURALNUM ISQL_S_RPAREN
    {
        s_HostVarType = iSQL_FLOAT;
        s_HostVarPrecision = atoi($<str>3);
        idlOS::strcpy(s_HostVarScale, (SChar*)"");
        idlOS::sprintf(gTmpBuf, "%s%s%s%s", 
                $<str>1, $<str>2, $<str>3, $<str>4);
        idlOS::strcpy($<str>$, gTmpBuf); 
    }
    | ISQL_T_BYTE
    {
        s_HostVarType = iSQL_BYTE;
        s_HostVarPrecision = 1;
        idlOS::strcpy(s_HostVarScale, (SChar*)"");
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_BYTE ISQL_S_LPAREN ISQL_T_NATURALNUM ISQL_S_RPAREN
    {
        s_HostVarType = iSQL_BYTE;
        s_HostVarPrecision = atoi($<str>3);
        idlOS::strcpy(s_HostVarScale, (SChar*)"");
        idlOS::sprintf(gTmpBuf, "%s%s%s%s", 
                $<str>1, $<str>2, $<str>3, $<str>4);
        idlOS::strcpy($<str>$, gTmpBuf); 
    }
    | ISQL_T_NIBBLE
    {
        s_HostVarType = iSQL_NIBBLE;
        s_HostVarPrecision = 1;
        idlOS::strcpy(s_HostVarScale, (SChar*)"");
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_NIBBLE ISQL_S_LPAREN ISQL_T_NATURALNUM ISQL_S_RPAREN
    {
        s_HostVarType = iSQL_NIBBLE;
        s_HostVarPrecision = atoi($<str>3);
        idlOS::strcpy(s_HostVarScale, (SChar*)"");
        idlOS::sprintf(gTmpBuf, "%s%s%s%s", 
                $<str>1, $<str>2, $<str>3, $<str>4);
        idlOS::strcpy($<str>$, gTmpBuf); 
    }
    | ISQL_T_INTEGER
    {
        s_HostVarType = iSQL_INTEGER;
        s_HostVarPrecision = -1;
        idlOS::strcpy(s_HostVarScale, (SChar*)"");
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_NUMBER
    {
        s_HostVarType = iSQL_NUMBER;
        s_HostVarPrecision = -1;
        idlOS::strcpy(s_HostVarScale, (SChar*)"");
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_NUMBER ISQL_S_LPAREN ISQL_T_NATURALNUM ISQL_S_RPAREN
    {
        s_HostVarType = iSQL_NUMBER;
        s_HostVarPrecision = atoi($<str>3);
        idlOS::strcpy(s_HostVarScale, (SChar*)"");
        idlOS::sprintf(gTmpBuf, "%s%s%s%s", 
                $<str>1, $<str>2, $<str>3, $<str>4);
        idlOS::strcpy($<str>$, gTmpBuf); 
    }
    | ISQL_T_NUMBER ISQL_S_LPAREN ISQL_T_NATURALNUM  ISQL_S_COMMA 
      ISQL_T_NATURALNUM ISQL_S_RPAREN
    {
        s_HostVarType = iSQL_NUMBER;
        s_HostVarPrecision = atoi($<str>3);
        idlOS::strcpy(s_HostVarScale, $<str>5);
        idlOS::sprintf(gTmpBuf, "%s%s%s%s %s%s", 
                $<str>1, $<str>2, $<str>3, $<str>4, $<str>5, $<str>6);
        idlOS::strcpy($<str>$, gTmpBuf); 
    }
    | ISQL_T_NUMBER ISQL_S_LPAREN ISQL_T_NATURALNUM  ISQL_S_COMMA 
      ISQL_S_PLUS ISQL_T_NATURALNUM ISQL_S_RPAREN
    {
        s_HostVarType = iSQL_NUMBER;
        s_HostVarPrecision = atoi($<str>3);
        idlOS::sprintf(gTmpBuf, "%s%s", $<str>5, $<str>6);
        idlOS::strcpy(s_HostVarScale, gTmpBuf);
        idlOS::sprintf(gTmpBuf, "%s%s%s%s %s%s%s", 
                $<str>1, $<str>2, $<str>3, $<str>4, $<str>5, $<str>6, $<str>7);
        idlOS::strcpy($<str>$, gTmpBuf); 
    }
    | ISQL_T_NUMBER ISQL_S_LPAREN ISQL_T_NATURALNUM  ISQL_S_COMMA 
      ISQL_S_MINUS ISQL_T_NATURALNUM ISQL_S_RPAREN
    {
        s_HostVarType = iSQL_NUMBER;
        s_HostVarPrecision = atoi($<str>3);
        idlOS::sprintf(gTmpBuf, "%s%s", $<str>5, $<str>6);
        idlOS::strcpy(s_HostVarScale, gTmpBuf);
        idlOS::sprintf(gTmpBuf, "%s%s%s%s %s%s%s", 
                $<str>1, $<str>2, $<str>3, $<str>4, $<str>5, $<str>6, $<str>7);
        idlOS::strcpy($<str>$, gTmpBuf); 
    }
    | ISQL_T_NUMERIC
    {
        s_HostVarType = iSQL_NUMERIC;
        s_HostVarPrecision = -1;
        idlOS::strcpy(s_HostVarScale, (SChar*)"");
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_NUMERIC ISQL_S_LPAREN ISQL_T_NATURALNUM ISQL_S_RPAREN
    {
        s_HostVarType = iSQL_NUMERIC;
        s_HostVarPrecision = atoi($<str>3);
        idlOS::strcpy(s_HostVarScale, (SChar*)"");
        idlOS::sprintf(gTmpBuf, "%s%s%s%s", 
                $<str>1, $<str>2, $<str>3, $<str>4);
        idlOS::strcpy($<str>$, gTmpBuf); 
    }
    | ISQL_T_NUMERIC ISQL_S_LPAREN ISQL_T_NATURALNUM  ISQL_S_COMMA 
      ISQL_T_NATURALNUM ISQL_S_RPAREN
    {
        s_HostVarType = iSQL_NUMERIC;
        s_HostVarPrecision = atoi($<str>3);
        idlOS::strcpy(s_HostVarScale, $<str>5);
        idlOS::sprintf(gTmpBuf, "%s%s%s%s %s%s", 
                $<str>1, $<str>2, $<str>3, $<str>4, $<str>5, $<str>6);
        idlOS::strcpy($<str>$, gTmpBuf); 
    }
    | ISQL_T_NUMERIC ISQL_S_LPAREN ISQL_T_NATURALNUM  ISQL_S_COMMA 
      ISQL_S_PLUS ISQL_T_NATURALNUM ISQL_S_RPAREN
    {
        s_HostVarType = iSQL_NUMERIC;
        s_HostVarPrecision = atoi($<str>3);
        idlOS::sprintf(gTmpBuf, "%s%s", $<str>5, $<str>6);
        idlOS::strcpy(s_HostVarScale, gTmpBuf);
        idlOS::sprintf(gTmpBuf, "%s%s%s%s %s%s%s", 
                $<str>1, $<str>2, $<str>3, $<str>4, $<str>5, $<str>6, $<str>7);
        idlOS::strcpy($<str>$, gTmpBuf); 
    }
    | ISQL_T_NUMERIC ISQL_S_LPAREN ISQL_T_NATURALNUM  ISQL_S_COMMA 
      ISQL_S_MINUS ISQL_T_NATURALNUM ISQL_S_RPAREN
    {
        s_HostVarType = iSQL_NUMERIC;
        s_HostVarPrecision = atoi($<str>3);
        idlOS::sprintf(gTmpBuf, "%s%s", $<str>5, $<str>6);
        idlOS::strcpy(s_HostVarScale, gTmpBuf);
        idlOS::sprintf(gTmpBuf, "%s%s%s%s %s%s%s", 
                $<str>1, $<str>2, $<str>3, $<str>4, $<str>5, $<str>6, $<str>7);
        idlOS::strcpy($<str>$, gTmpBuf); 
    }
    | ISQL_T_REAL
    {
        s_HostVarType = iSQL_REAL;
        s_HostVarPrecision = -1;
        idlOS::strcpy(s_HostVarScale, (SChar*)"");
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_SMALLINT
    {
        s_HostVarType = iSQL_SMALLINT;
        s_HostVarPrecision = -1;
        idlOS::strcpy(s_HostVarScale, (SChar*)"");
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_VARCHAR
    {
        s_HostVarType = iSQL_VARCHAR;
        s_HostVarPrecision = 1;
        idlOS::strcpy(s_HostVarScale, (SChar*)"");
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_VARCHAR ISQL_S_LPAREN ISQL_T_NATURALNUM ISQL_S_RPAREN
    {
        s_HostVarType = iSQL_VARCHAR;
        s_HostVarPrecision = 1;
        idlOS::strcpy(s_HostVarScale, (SChar*)"");
        s_HostVarType = iSQL_VARCHAR;
        s_HostVarPrecision = atoi($<str>3);
        idlOS::strcpy(s_HostVarScale, (SChar*)"");
        idlOS::sprintf(gTmpBuf, "%s%s%s%s", 
                $<str>1, $<str>2, $<str>3, $<str>4);
        idlOS::strcpy($<str>$, gTmpBuf); 
    }
    | ISQL_T_IDENTIFIER
    { 
        s_HostVarType = iSQL_BAD;
        s_HostVarPrecision = 1;
        idlOS::strcpy(s_HostVarScale, (SChar*)"");
        idlOS::strcpy($<str>$, $<str>1); 
    }   
    | ISQL_T_IDENTIFIER ISQL_S_LPAREN ISQL_T_NATURALNUM ISQL_S_RPAREN
    { 
        s_HostVarType = iSQL_BAD;
        s_HostVarPrecision = 1;
        idlOS::strcpy(s_HostVarScale, (SChar*)"");
        idlOS::sprintf(gTmpBuf, "%s%s%s%s", 
                $<str>1, $<str>2, $<str>3, $<str>4);
        idlOS::strcpy($<str>$, gTmpBuf); 
    } 
    | ISQL_T_IDENTIFIER ISQL_S_LPAREN ISQL_T_NATURALNUM  ISQL_S_COMMA
      ISQL_T_NATURALNUM ISQL_S_RPAREN
    {   
        s_HostVarType = iSQL_BAD;
        s_HostVarPrecision = 1;
        idlOS::strcpy(s_HostVarScale, (SChar*)"");
        idlOS::sprintf(gTmpBuf, "%s%s%s%s %s%s", 
                $<str>1, $<str>2, $<str>3, $<str>4, $<str>5, $<str>6);
        idlOS::strcpy($<str>$, gTmpBuf); 
    }   
    | ISQL_T_IDENTIFIER ISQL_S_LPAREN ISQL_T_NATURALNUM  ISQL_S_COMMA 
      ISQL_S_PLUS ISQL_T_NATURALNUM ISQL_S_RPAREN
    {
        s_HostVarType = iSQL_BAD;
        s_HostVarPrecision = 1;
        idlOS::strcpy(s_HostVarScale, (SChar*)"");
        idlOS::sprintf(gTmpBuf, "%s%s%s%s %s%s%s", 
                $<str>1, $<str>2, $<str>3, $<str>4, $<str>5, $<str>6, $<str>7);
        idlOS::strcpy($<str>$, gTmpBuf); 
    }
    | ISQL_T_IDENTIFIER ISQL_S_LPAREN ISQL_T_NATURALNUM  ISQL_S_COMMA 
      ISQL_S_MINUS ISQL_T_NATURALNUM ISQL_S_RPAREN
    {
        s_HostVarType = iSQL_BAD;
        s_HostVarPrecision = 1;
        idlOS::strcpy(s_HostVarScale, (SChar*)"");
        idlOS::sprintf(gTmpBuf, "%s%s%s%s %s%s%s", 
                $<str>1, $<str>2, $<str>3, $<str>4, $<str>5, $<str>6, $<str>7);
        idlOS::strcpy($<str>$, gTmpBuf); 
    }
    ;

on_off
    : ISQL_T_ON
    {
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_OFF
    {
        idlOS::strcpy($<str>$, $<str>1); 
    }
    ;

time_scale
    : ISQL_T_SEC
    {
        gCommand->SetTimescale(iSQL_SEC);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_MILSEC
    {
        gCommand->SetTimescale(iSQL_MILSEC);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_MICSEC
    {
        gCommand->SetTimescale(iSQL_MICSEC);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_NANSEC
    {
        gCommand->SetTimescale(iSQL_NANSEC);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    ;

end_stmt
    : /* empty */
    {
        $<str>$ = (SChar*)"";
    }
    | ISQL_S_SEMICOLON
    {
        idlOS::strcpy($<str>$, $<str>1); 
    }
    ;

identifier
    : ISQL_T_ALL    
    {
        gCommand->SetHelpKind(OTHER_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_AUTOCOMMIT 
    {
        gCommand->SetHelpKind(AUTOCOMMIT_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_BIGINT   
    {
        gCommand->SetHelpKind(OTHER_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_CHAR 
    {
        gCommand->SetHelpKind(OTHER_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_COMMENT 
    {
        gCommand->SetHelpKind(COMMENT_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_DATE   
    {
        gCommand->SetHelpKind(OTHER_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_DECIMAL  
    {
        gCommand->SetHelpKind(OTHER_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_DESC    
    {
        gCommand->SetHelpKind(DESC_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_DISCONNECT    
    {
        gCommand->SetHelpKind(DISCONNECT_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_DOUBLE 
    {
        gCommand->SetHelpKind(OTHER_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_EDIT
    {
        gCommand->SetHelpKind(EDIT_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_EXECUTE
    {
        gCommand->SetHelpKind(EXECUTE_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_EXIT      
    {
        gCommand->SetHelpKind(EXIT_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_FLOAT    
    {
        gCommand->SetHelpKind(OTHER_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_HEADING 
    {
        gCommand->SetHelpKind(HEADING_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_FOREIGNKEYS 
    {
        gCommand->SetHelpKind(FOREIGNKEYS_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_HELP   
    {
        gCommand->SetHelpKind(HELP_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_HISTORY     
    {
        gCommand->SetHelpKind(HISTORY_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_BYTE  
    {
        gCommand->SetHelpKind(OTHER_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_NIBBLE   
    {
        gCommand->SetHelpKind(OTHER_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_INDEX     
    {
        gCommand->SetHelpKind(INDEX_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_INTEGER  
    {
        gCommand->SetHelpKind(OTHER_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_COLSIZE 
    {
        gCommand->SetHelpKind(COLSIZE_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_LINESIZE 
    {
        gCommand->SetHelpKind(LINESIZE_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_LOAD    
    {
        gCommand->SetHelpKind(LOAD_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_MICSEC 
    {
        gCommand->SetHelpKind(OTHER_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_MILSEC
    {
        gCommand->SetHelpKind(OTHER_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_NANSEC  
    {
        gCommand->SetHelpKind(OTHER_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_NUMBER  
    {
        gCommand->SetHelpKind(OTHER_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_NUMERIC 
    {
        gCommand->SetHelpKind(OTHER_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_OFF    
    {
        gCommand->SetHelpKind(OTHER_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_ON    
    {
        gCommand->SetHelpKind(OTHER_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_PAGESIZE     
    {
        gCommand->SetHelpKind(PAGESIZE_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_PRINT       
    {
        gCommand->SetHelpKind(PRINT_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_QUIT       
    {
        gCommand->SetHelpKind(EXIT_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_REAL      
    {
        gCommand->SetHelpKind(OTHER_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_SAVE      
    {
        gCommand->SetHelpKind(SAVE_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_SEC      
    {
        gCommand->SetHelpKind(OTHER_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_SET     
    {
        gCommand->SetHelpKind(SET_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_SHOW   
    {
        gCommand->SetHelpKind(SHOW_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_SMALLINT  
    {
        gCommand->SetHelpKind(OTHER_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_SPOOL    
    {
        gCommand->SetHelpKind(SPOOL_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_START   
    {
        gCommand->SetHelpKind(SCRIPTRUN_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_TERM      
    {
        gCommand->SetHelpKind(TERM_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_TIMESCALE     
    {
        gCommand->SetHelpKind(TIMESCALE_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_TIMING      
    {
        gCommand->SetHelpKind(TIMING_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_USER       
    {
        gCommand->SetHelpKind(USER_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_VARCHAR 
    {
        gCommand->SetHelpKind(OTHER_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_VARIABLE 
    {
        gCommand->SetHelpKind(VAR_DEC_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_VERBOSE
    {
        gCommand->SetHelpKind(VERBOSE_COM);
        idlOS::strcpy($<str>$, $<str>1); 
    }
    | ISQL_T_SELECT
    {
        gCommand->SetHelpKind(SELECT_COM);
        idlOS::strcpy(gTmpBuf, $<str>1);
        chkID();
        idlOS::strcpy($<str>$, gTmpBuf);
    }
    | ISQL_T_ALTER
    {
        gCommand->SetHelpKind(ALTER_COM);
        idlOS::strcpy(gTmpBuf, $<str>1);
        chkID();
        idlOS::strcpy($<str>$, gTmpBuf);
    }
    | ISQL_T_CHECK
    {
        gCommand->SetHelpKind(CHECK_COM);
        idlOS::strcpy(gTmpBuf, $<str>1);
        chkID();
        idlOS::strcpy($<str>$, gTmpBuf);
    }
    | ISQL_T_COMMIT
    {
        gCommand->SetHelpKind(COMMIT_COM);
        idlOS::strcpy(gTmpBuf, $<str>1);
        chkID();
        idlOS::strcpy($<str>$, gTmpBuf);
    }
    | ISQL_T_CRT_OBJ
    {
        gCommand->SetHelpKind(CRT_OBJ_COM);
        idlOS::strcpy(gTmpBuf, $<str>1);
        chkID();
        idlOS::strcpy($<str>$, gTmpBuf);
    }
    | ISQL_T_DELETE
    {
        gCommand->SetHelpKind(DELETE_COM);
        idlOS::strcpy(gTmpBuf, $<str>1);
        chkID();
        idlOS::strcpy($<str>$, gTmpBuf);
    }
    | ISQL_T_DROP
    {
        gCommand->SetHelpKind(DROP_COM);
        idlOS::strcpy(gTmpBuf, $<str>1);
        chkID();
        idlOS::strcpy($<str>$, gTmpBuf);
    }
    | ISQL_T_GRANT
    {
        gCommand->SetHelpKind(GRANT_COM);
        idlOS::strcpy(gTmpBuf, $<str>1);
        chkID();
        idlOS::strcpy($<str>$, gTmpBuf);
    }
    | ISQL_T_INSERT
    {
        gCommand->SetHelpKind(INSERT_COM);
        idlOS::strcpy(gTmpBuf, $<str>1);
        chkID();
        idlOS::strcpy($<str>$, gTmpBuf);
    }
    | ISQL_T_LOCK
    {
        gCommand->SetHelpKind(LOCK_COM);
        idlOS::strcpy(gTmpBuf, $<str>1);
        chkID();
        idlOS::strcpy($<str>$, gTmpBuf);
    }
    | ISQL_T_MOVE
    {
        gCommand->SetHelpKind(MOVE_COM);
        idlOS::strcpy(gTmpBuf, $<str>1);
        chkID();
        idlOS::strcpy($<str>$, gTmpBuf);
    }
    | ISQL_T_RENAME
    {
        gCommand->SetHelpKind(RENAME_COM);
        idlOS::strcpy(gTmpBuf, $<str>1);
        chkID();
        idlOS::strcpy($<str>$, gTmpBuf);
    }
    | ISQL_T_REVOKE
    {
        gCommand->SetHelpKind(REVOKE_COM);
        idlOS::strcpy(gTmpBuf, $<str>1);
        chkID();
        idlOS::strcpy($<str>$, gTmpBuf);
    }
    | ISQL_T_ROLLBACK
    {
        gCommand->SetHelpKind(ROLLBACK_COM);
        idlOS::strcpy(gTmpBuf, $<str>1);
        chkID();
        idlOS::strcpy($<str>$, gTmpBuf);
    }
    | ISQL_T_SAVEPOINT
    {
        gCommand->SetHelpKind(SAVEPOINT_COM);
        idlOS::strcpy(gTmpBuf, $<str>1);
        chkID();
        idlOS::strcpy($<str>$, gTmpBuf);
    }
    | ISQL_T_TRUNCATE
    {
        gCommand->SetHelpKind(TRUNCATE_COM);
        idlOS::strcpy(gTmpBuf, $<str>1);
        chkID();
        idlOS::strcpy($<str>$, gTmpBuf);
    }
    | ISQL_T_UPDATE
    {
        gCommand->SetHelpKind(UPDATE_COM);
        idlOS::strcpy(gTmpBuf, $<str>1);
        chkID();
        idlOS::strcpy($<str>$, gTmpBuf);
    }
    | ISQL_T_CONNECT 
    {
        gCommand->SetHelpKind(CONNECT_COM);
        idlOS::strcpy(gTmpBuf, $<str>1);
        chkID();
        idlOS::strcpy($<str>$, gTmpBuf);
    }
    | ISQL_T_HISEDIT
    {
        gCommand->SetHelpKind(OTHER_COM);
        idlOS::strcpy(gTmpBuf, $<str>1);
        chkID();
        idlOS::strcpy($<str>$, gTmpBuf);
    }
    | ISQL_T_NATURALNUM
    {
        gCommand->SetHelpKind(OTHER_COM);
        idlOS::strcpy($<str>$, $<str>1);
    }
    | ISQL_T_IDENTIFIER
    {
        gCommand->SetHelpKind(OTHER_COM);
        idlOS::strcpy($<str>$, $<str>1);
    }
    ;

%%

void chkID()
{
    SChar * pos;
    SChar * pos2;

    pos = idlOS::strrchr(gTmpBuf, '\n'); 
    if ( pos != NULL )
    {
        pos2 = idlOS::strrchr(gTmpBuf, ';'); 
        if ( pos2 != NULL )
        {
            *pos2 = '\0';
        }
        else
        {
            *pos = '\0';
        }
    } 
    else
    {
        pos2 = idlOS::strrchr(gTmpBuf, ';'); 
        if ( pos2 != NULL )
        {
            *pos2 = '\0';
        }
    }
}
