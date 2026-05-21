/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iSQLLexer.l 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/

/* ======================================================
   NAME
    iSQLLexer.l

   DESCRIPTION
    iSQLPreLexer로부터 넘겨받은 입력버퍼를 scan하여 token단위로 나눈다.
    이때 isql command만 token으로 분해하고 
    sql command는 하나의 토큰으로 처리한다.

   PUBLIC FUNCTION(S)

   PRIVATE FUNCTION(S)

   NOTES

   MODIFIED   (MM/DD/YY)
 ====================================================== */

%option 8bit
%option caseless
%option prefix="iSQLLexer"
%option noyywrap
%option noyymore

%{
#include <idl.h>
#include <uttMemory.h>
#include <iSQL.h>

#if defined(BISON_POSTFIX_HPP)
#include <iSQLParser.hpp>
#else /* BISON_POSTFIX_CPP_H */
#include <iSQLParser.cpp.h>
#endif

//#define _ISQL_DEBUG

#undef  YY_INPUT
#define YY_INPUT(b, r, m) ( r = iSQLParser_yyinput((SChar *)b, m) )

extern uttMemory * g_memmgr;

extern iSQLSessionKind gSessionKind;

SChar * g_input_strptr;
SChar * g_length_input_str;

void gSetInputStr(SChar * s);
SInt iSQLParser_yyinput(SChar *, SInt);
void iSQLParsererror(SChar * s);
%}

%x xc
%x xc2

%%

"/*"                        { /* multi line comment */ BEGIN xc; }
<xc>[*]+                    { BEGIN xc2;     }
<xc>[^*\n]*                        
<xc>\n                             
<xc2>"/"                    { BEGIN INITIAL; }
<xc2>[^/\n]                 { BEGIN xc;      }
<xc2>\n                     { BEGIN xc;      }

"--"[^\n]*\n                { /* single line comment */ }
"//"[^\n]*\n                { /* single line comment */ }

'("''"|[^'])*'              { /* string in query */ return ISQL_T_CONSTSTR; }

":="                        { return ISQL_S_ASSIGN; }
"@"                         { return ISQL_S_AT; }
","                         { return ISQL_S_COMMA; }
"="                         { return ISQL_S_EQ; }
"("                         { return ISQL_S_LPAREN; }
")"                         { return ISQL_S_RPAREN; }
"+"                         { return ISQL_S_PLUS; }
"-"                         { return ISQL_S_MINUS; }
";"                         { return ISQL_S_SEMICOLON; }

ALL                         { return ISQL_T_ALL; }
AUTOCOMMIT                  { return ISQL_T_AUTOCOMMIT; }
BIGINT                      { return ISQL_T_BIGINT; }       /* A3 */
CHAR                        { return ISQL_T_CHAR; }
COLSIZE                     { return ISQL_T_COLSIZE; }
COMMENT                     { return ISQL_T_COMMENT; }
DATE                        { return ISQL_T_DATE; }
DECIMAL                     { return ISQL_T_DECIMAL; }      /* A3 */
DESC                        { return ISQL_T_DESC; }
DISCONNECT                  { return ISQL_T_DISCONNECT; }
DOUBLE                      { return ISQL_T_DOUBLE; }       /* A3 */
ED                          { return ISQL_T_EDIT; }
EDIT                        { return ISQL_T_EDIT; }
EXEC                        { return ISQL_T_EXECUTE; }
EXECUTE                     { return ISQL_T_EXECUTE; }
EXIT                        { return ISQL_T_EXIT; }
FLOAT                       { return ISQL_T_FLOAT; }        /* A3 */
FOREIGNKEYS                 { return ISQL_T_FOREIGNKEYS; }  /* A3 */
H                           { return ISQL_T_HISTORY; }
HEADING                     { return ISQL_T_HEADING; }
HELP                        { return ISQL_T_HELP; }    
HISTORY                     { return ISQL_T_HISTORY; }
BYTE                   { return ISQL_T_BYTE; }    /* A3 */
NIBBLE                  { return ISQL_T_NIBBLE; }   /* A3 */
INDEX                       { return ISQL_T_INDEX; }
INTEGER                     { return ISQL_T_INTEGER; }
LINESIZE                    { return ISQL_T_LINESIZE; }
LOAD                        { return ISQL_T_LOAD; }
MICSEC                      { return ISQL_T_MICSEC; }
MILSEC                      { return ISQL_T_MILSEC; }
NANSEC                      { return ISQL_T_NANSEC; }
NULL                        { return ISQL_T_NULL; }
NUMBER                      { return ISQL_T_NUMBER; }
NUMERIC                     { return ISQL_T_NUMERIC; }
OFF                         { return ISQL_T_OFF; }
ON                          { return ISQL_T_ON; }
PAGESIZE                    { return ISQL_T_PAGESIZE; }
PLANCOMMIT                  { return ISQL_T_PLANCOMMIT; }
QUERYLOGGING                { return ISQL_T_QUERYLOGGING; }
PRINT                       { return ISQL_T_PRINT; }
QUIT                        { return ISQL_T_QUIT; }
REAL                        { return ISQL_T_REAL; }         /* A3 */
SAVE                        { return ISQL_T_SAVE; }
SEC                         { return ISQL_T_SEC; }
SET                         { return ISQL_T_SET; }
SHOW                        { return ISQL_T_SHOW; }
SMALLINT                    { return ISQL_T_SMALLINT; }     /* A3 */
SPOOL                       { return ISQL_T_SPOOL; }
START                       { return ISQL_T_START; }
TERM                        { return ISQL_T_TERM; }
TIMESCALE                   { return ISQL_T_TIMESCALE; }
TIMING                      { return ISQL_T_TIMING; }
TMSC                        { return ISQL_T_TIMESCALE; }
USER                        { return ISQL_T_USER; }
VAR                         { return ISQL_T_VARIABLE; }
VARCHAR                     { return ISQL_T_VARCHAR; }
VARIABLE                    { return ISQL_T_VARIABLE; }
VERBOSE                     { return ISQL_T_VERBOSE; }

STARTUP                     { return ISQL_T_STARTUP; }
PROCESS                     { return ISQL_T_PROCESS; }
CONTROL                     { return ISQL_T_CONTROL; }
META                        { return ISQL_T_META; }
SERVICE                     { return ISQL_T_SERVICE; }

SESSION                     { return ISQL_T_SESSION; }
PROPERTY                    { return ISQL_T_PROPERTY; }
REPLICATION                 { return ISQL_T_REPLICATION; }
DB                          { return ISQL_T_DB; }
MEMORY                      { return ISQL_T_MEMORY; }

SHUTDOWN                    { return ISQL_T_SHUTDOWN; }
NORM                        { return ISQL_T_NORM; }
NORMAL                      { return ISQL_T_NORMAL; }
IMME                        { return ISQL_T_IMME; }
IMMEDIATE                   { return ISQL_T_IMMEDIATE; }
ABOR                        { return ISQL_T_ABOR; }
ABORT                       { return ISQL_T_ABORT; }

"ALTER"[ \t\n]+"SESSION"[ \t\n]+"SET"[ \t\n]+"EXPLAIN"[ \t\n]+"PLAN"[ \t\n]*[=][ \t\n]*"ON"[ \t\n]*;(.|\n)*          { gSessionKind = EXPLAIN_PLAN_ON; 
                                       return ISQL_T_ALTER; }
"ALTER"[ \t\n]+"SESSION"[ \t\n]+"SET"[ \t\n]+"EXPLAIN"[ \t\n]+"PLAN"[ \t\n]*[=][ \t\n]*"OFF"[ \t\n]*;(.|\n)*         { gSessionKind = EXPLAIN_PLAN_OFF; 
                                       return ISQL_T_ALTER; }
"ALTER"[ \t\n]+"SESSION"[ \t\n]+"SET"[ \t\n]+"EXPLAIN"[ \t\n]+"PLAN"[ \t\n]*[=][ \t\n]*"ONLY"[ \t\n]*;(.|\n)*        { gSessionKind = EXPLAIN_PLAN_ONLY; 
                                       return ISQL_T_ALTER; }

"CREATE"[ \t\n]+("PROCEDURE"|"FUNCTION"|"TRIGGER")(.|\n)* { 
                                       return ISQL_T_CRT_PROC; }
"CREATE"[ \t\n]+"OR"[ \t\n]+"REPLACE"[ \t\n]+("PROCEDURE"|"FUNCTION")(.|\n)* { 
                                       return ISQL_T_CRT_PROC; }
"CREATE"[ \t\n]+"OR"[ \t\n]+"REPLACE"[ \t\n]+("NO"|"FORCE"|"VIEW")(.|\n)* { 
                                       return ISQL_T_CRT_OBJ; }

("EXECUTE"|"EXEC")[ \t\n]+[_A-Z\200-\377][_A-Z\200-\3770-9]*(.|\n)* {
                                       return ISQL_T_EXEC_PROC; }
("EXECUTE"|"EXEC")[ \t\n]+":"[_A-Z][_A-Z0-9]*[ \t\n]*":="[ \t\n]*"NULL"[ \t\n]*;[ \t]*\n                             { return ISQL_T_EXEC_NULL; }
("EXECUTE"|"EXEC")[ \t\n]+":"[_A-Z][_A-Z0-9]*[ \t\n]*":="[ \t\n]*[_A-Z\200-\377][_A-Z\200-\3770-9]*(.|\n)*           { return ISQL_T_EXEC_FUNC; }

"SELECT"[ \t\n]+[*][ \t\n]+"FROM"[ \t\n]+"TAB"[ \t\n]*;(.|\n)* { 
                                       return ISQL_T_TABLES; }
"SELECT"[ \t\n]+[*][ \t\n]+"FROM"[ \t\n]+"X$TAB"[ \t\n]*;(.|\n)* { 
                                       return ISQL_T_XTABLES; }
"SELECT"[ \t\n]+[*][ \t\n]+"FROM"[ \t\n]+"V$TAB"[ \t\n]*;(.|\n)* { 
                                       return ISQL_T_VTABLES; }

"SELECT"[ \t\n]+[*][ \t\n]+"FROM"[ \t\n]+"SEQ"[ \t\n]*;(.|\n)* { 
                                       return ISQL_T_SEQUENCE; }
([(][ \t\n]*)*"SELECT"(.|\n)*        { return ISQL_T_SELECT; }

"SET"[ \t\n]+"TRANSACTION"(.|\n)*    { return ISQL_T_TRANSACTION; }

"PREPARE"                    { return ISQL_T_PREPARE; }

"ALTER"(.|\n)*               { return ISQL_T_ALTER; }
"CHECK"(.|\n)*               { return ISQL_T_COMMIT; }
"COMMIT"(.|\n)*              { return ISQL_T_COMMIT; }
"CREATE"(.|\n)*              { return ISQL_T_CRT_OBJ; }
"DELETE"(.|\n)*              { return ISQL_T_DELETE; }
"DROP"(.|\n)*                { return ISQL_T_DROP; }
"GRANT"(.|\n)*               { return ISQL_T_GRANT; }
"INSERT"(.|\n)*              { return ISQL_T_INSERT; }
"LOCK"(.|\n)*                { return ISQL_T_LOCK; }
"MOVE"(.|\n)*                { return ISQL_T_MOVE; }
"RENAME"(.|\n)*              { return ISQL_T_RENAME; }
"REVOKE"(.|\n)*              { return ISQL_T_REVOKE; }
"ROLLBACK"(.|\n)*            { return ISQL_T_ROLLBACK; }
"SAVEPOINT"(.|\n)*           { return ISQL_T_SAVEPOINT; }
"TRUNCATE"(.|\n)*            { return ISQL_T_TRUNCATE; }
"UPDATE"(.|\n)*              { return ISQL_T_UPDATE; }
"CONNECT".*                  { return ISQL_T_CONNECT; }
"!".*                        { return ISQL_T_SHELL; }
[0-9]+[ \t]*"/"[ \t]*;?      { return ISQL_T_HISRUN; }
"/"                          { return ISQL_T_HISRUN; }
"?"                          { return ISQL_T_HOME; }

[0-9]+[ \t]*("ED"|"EDIT")[ \t]*;?                { return ISQL_T_HISEDIT; }
[0-9]+                                           { return ISQL_T_NATURALNUM; }
-?[0-9]+("."[0-9]*)?([Ee][+-]?[0-9]+)? |
"."[0-9]+([Ee][+-]?[0-9]+)?                      { return ISQL_T_REALNUM; }
[_A-Z\200-\377][_A-Z\200-\3770-9]*               { return ISQL_T_IDENTIFIER; }
[_A-Z\200-\377][_A-Z\200-\3770-9$]*               { return ISQL_T_DOLLAR_ID; }
[_0-9A-Z\200-\377./][_A-Z\200-\3770-9./-]*       { return ISQL_T_FILENAME; }
":"[_A-Z][_A-Z0-9]*                              { return ISQL_T_HOSTVAR; }

[ \t\n\r]+
.            { return yytext[0]; }

%%

void 
iSQLParsererror( SChar * /* s */ )
{
#ifdef _ISQL_DEBUG
    idlOS::fprintf(stderr, 
            "%s:%d Error:%s:\n", __FILE__, __LINE__, 
            iSQLLexertext); 
    idlOS::fflush(stderr);
#endif
    iSQLLexer_flush_buffer( yy_current_buffer );
}

void 
gSetInputStr( SChar * s )
{
#ifdef _ISQL_DEBUG
    idlOS::fprintf(stderr, "%s:%d Error:%s:\n", __FILE__, __LINE__, s); 
    idlOS::fflush(stderr);
#endif

    iSQLLexer_flush_buffer( yy_current_buffer );

    g_length_input_str = s + idlOS::strlen(s);
    g_input_strptr = s;

#ifdef _ISQL_DEBUG
    idlOS::fprintf(stderr, 
            "%s:%d strptr:%s: str:%s:\n", 
            __FILE__, __LINE__, g_input_strptr, g_length_input_str); 
    idlOS::fflush(stderr);
#endif
}

SInt 
iSQLParser_yyinput( SChar * buf, 
                    SInt    max_size )
{
    SInt n = 0;

#ifdef _ISQL_DEBUG
    idlOS::fprintf(stderr, 
            "%s:%d strptr:%s: str:%s: max_size:%d: buf:%s: n:%d:\n",
            __FILE__, __LINE__, 
            g_input_strptr, g_length_input_str, max_size, buf, n); 
    idlOS::fflush(stderr);
#endif

    if ( max_size < (g_length_input_str - g_input_strptr) ) 
    {
        n = max_size;
    }
    else
    {
        n = g_length_input_str - g_input_strptr;
    }

    if(n > 0) 
    {
        idlOS::memcpy(buf, g_input_strptr, n);
        g_input_strptr += n;
        buf[n]=0;
    }

#ifdef _ISQL_DEBUG
    idlOS::fprintf(stderr, 
            "%s:%d buf:%s: n:%d:\n", __FILE__, __LINE__, 
            buf, n); 
    idlOS::fflush(stderr);
#endif
    
    return n;
}

SInt 
iSQLParserlex( YYSTYPE * lvalp, 
               void    * /* param */ )
{
    SInt rc;
    SInt t_len;

    rc = yylex();
    t_len = idlOS::strlen(yytext);
    lvalp->str = (SChar*)(g_memmgr->alloc(t_len+1));
    idlOS::memcpy(lvalp->str, yytext, t_len);
    (lvalp->str)[t_len] = '\0';

#ifdef _ISQL_DEBUG
    idlOS::fprintf(stderr, 
            "%s:%d yytext:%s: lvalp->str:%s: t_len:%d:\n", 
            __FILE__, __LINE__, yytext, lvalp->str, t_len); 
    idlOS::fflush(stderr);
#endif

    return rc;
}
