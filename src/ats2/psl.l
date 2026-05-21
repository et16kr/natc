/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: psl.l 853 2006-08-31 01:24:14Z orc $
 **********************************************************************/

%option c++
%option 8bit
%option caseless
%option never-interactive
%option noreject
%option noyymore
%option noyywrap
%option nostdinit
%option prefix="ps"
%option yyclass="psLexer"

%{
#include "common.h"
#include "pslx.h"
#include "psl.h"
#include "psy.cpp.h"

#undef ECHO

int pslex(YYSTYPE* lvalp, void* param );

psLexer::psLexer( SChar*  aBuffer,
                  UInt    aBufferLength )
{
    mBuffer       = aBuffer;
    mBufferCursor = mBuffer;
    mBufferLength = aBufferLength;
    mBufferRemain = aBufferLength;
}

int psLexer::LexerInput( char* aBuffer, int aMaximum )
{
    aMaximum       =
        ( (int)mBufferRemain < aMaximum ) ? (int)mBufferRemain : aMaximum ;
    aMaximum       = ( aMaximum > 0 ) ? aMaximum : 0 ;
    mBufferRemain -= aMaximum;

    memcpy( aBuffer, mBufferCursor, aMaximum );

    mBufferLast    = mBufferCursor;

    mBufferCursor += aMaximum;

    mBufferInput   = aBuffer;

    return aMaximum;
}

void 
psLexer::getPosition( psNamePosition* aPosition )
{
    aPosition->offset = (mBufferLast-mBuffer)+(YYText()-mBufferInput);
    aPosition->size   = YYLeng();
}

SChar *
psLexer::getLexLastError( SChar *aMessage )
{
    psNamePosition sPosition;
    UInt           sLineOffset;
    UInt           sLineNo;
    UInt           sBufferIterator;
    UInt           sBufferFence;
    UInt           sMessageIterator;
    UInt           sMessageFence;

    getPosition( &sPosition );

    sLineOffset = 0 ;
    sLineNo     = 1;
    for( sBufferIterator = 0;
         sBufferIterator < (UInt)(sPosition.offset);
         sBufferIterator++ )
    {
        if( mBuffer[sBufferIterator] == '\n' )
        {
            sLineOffset = sBufferIterator + 1;
            sLineNo++;
        }
    }

    sprintf( mMessage, 
             "\n\nline %d: %s\n", sLineNo, aMessage );

    sMessageIterator  = strlen( mMessage );
    sMessageFence     = sMessageIterator + sPosition.size;
    if( sMessageFence >= ERROR_SIZE )
    {
        sMessageFence = ERROR_SIZE - 8;
    }
    for( sBufferIterator  = sLineOffset;
         sMessageIterator < sMessageFence &&
         sBufferIterator  < mBufferLength;
         sBufferIterator++, sMessageIterator++ )
    {
        mMessage[sMessageIterator] = mBuffer[sBufferIterator];
    }

    for( sMessageFence    = ERROR_SIZE - 8;
         sMessageIterator < sMessageFence &&
         sBufferIterator  < mBufferLength &&
         mBuffer[sBufferIterator] != '\n';
         sBufferIterator++, sMessageIterator++ )
    {
        mMessage[sMessageIterator] = mBuffer[sBufferIterator];
    }

    if( sMessageIterator < sMessageFence )
    {
        mMessage[sMessageIterator] = '\n';
        sMessageIterator++;
    }

    for( sBufferFence    = sBufferIterator,
         sBufferIterator = sLineNo;
         sMessageIterator < sMessageFence &&
         sBufferIterator  < mBufferLength;
         sBufferIterator++, sMessageIterator++ )
    {
         if( sBufferIterator == (UInt)(sPosition.offset)                    ||
             sBufferIterator == (UInt)(sPosition.offset + sPosition.size - 1) )
         {
             mMessage[sMessageIterator] = '^';
         }
         else
         {
             mMessage[sMessageIterator] = ( mBuffer[sBufferIterator] == '\n' )
                                        ? '\n' : ' ' ;
         }
    }

    mMessage[sMessageIterator] = '\n';
    sMessageIterator++;
    mMessage[sMessageIterator] = '\n';
    sMessageIterator++;
    mMessage[sMessageIterator] = '\0';

    return mMessage;
}

int pslex( YYSTYPE* lvalp, void* param )
{
    int       sSize;
    int       sToken;
    psLexer* sLexer = ((pslx *)param)->lexer;

    sToken = sLexer->yylex();

    sLexer->getPosition( &lvalp->position );

    return sToken;
}

%}

SQL_ANY [^;]*

%%
"CREATE"[ \t\n]+("PROCEDURE"|"FUNCTION"|"TRIGGER"|"TYPESET")[^/]*"/" { return T_OBJECT; }
"CREATE"[ \t\n]+"OR"[ \t\n]+"REPLACE"[ \t\n]+("PROCEDURE"|"FUNCTION"|"TRIGGER"|"TYPESET")[^/]*"/" { return T_OBJECT; }
"CREATE"[ \t\n]+"OR"[ \t\n]+"REPLACE"[ \t\n]+("NO"|"FORCE"|"VIEW")[^;]*";" { return T_OBJECT; }
("EXECUTE"|"EXEC")[ \t\n]+[_A-Z\200-\377][_A-Z\200-\3770-9]*[^;]* { return T_EXECUTE_PROCEDURE; }
("EXECUTE"|"EXEC")[ \t\n]+":"[_A-Z][_A-Z0-9]*[ \t\n]*":="[ \t\n]*"NULL"[^;]* { return T_EXECUTE_NULL; } 
("EXECUTE"|"EXEC")[ \t\n]+":"[_A-Z][_A-Z0-9]*[ \t\n]*":="[ \t\n]*[_A-Z\200-\377][_A-Z\200-\3770-9]*[^;]* { return T_EXECUTE_FUNCTION; }
("EXECUTE"|"EXEC")[ \t\n]+":"[_A-Z][_A-Z0-9]*[ \t\n]*"="[ \t\n]*[_A-Z\200-\377][_A-Z\200-\3770-9]*[^;]* { return T_EXECUTE_FUNCTION2; }

"SET_ENV"[^\n]* { return T_SET_ENV; }
"UNSET_ENV"[^\n]* { return T_UNSET_ENV; }
"SET_RESTART"   { return T_SET_RESTART; }
"SYSTEM"[^\n]*  { return T_SYSTEM; }
"RSYSTEM"[^\n]*  { return T_RSYSTEM; }
"APPEND_LST"[^\n]*    { return T_APPEND_LST; }
"CHECK"[^\n]*    { return T_CHECK2; }
"DECLARE"       { return T_DECLARE; }
"SERVER"        { return T_SERVER; }
"CLIENT"        { return T_CLIENT; }
"DEFAULT"       { return T_DEFAULT2; }
"ISQL_CONNECTION"       { return T_ISQL_CONNECTION; }
"LOAD_SQL"      { return T_LOAD_SQL; }
"TEST_RECPTR"[^\n]* { return T_TEST_RECPTR; }

"--+"	        { return T_COMMAND; }
"--"[^+].*\n	{ return T_COMMENT; }
#.*\n	        { return T_COMMENT; }
"//".*\n	    { return T_COMMENT; }

"SKIP"          { return T_SKIP; }
"BEGIN"         { return T_BEGIN; }
"END"           { return T_END; }

"IGNORE"        { return T_IGNORE; }

"POST"          { return T_POST; }
"WAIT"          { return T_WAIT; }

"PROCESS"       { return T_PROCESS; }
"SECTOR"[^\n]*  { return T_SECTOR; }
"PWAIT"         { return T_PWAIT; }

"CREATE"{SQL_ANY}            { return T_CREATE; }
"INSERT"{SQL_ANY}            { return T_INSERT; }
"SELECT"{SQL_ANY}            { return T_SELECT; }
([(][ \t\n]*)*"SELECT"{SQL_ANY}            { return T_SELECT; }
"DESC"{SQL_ANY}            { return T_DESC; }
"UPDATE"{SQL_ANY}              { return T_UPDATE; }
"DELETE"{SQL_ANY}              { return T_DELETE; }
"MOVE"{SQL_ANY}                { return T_MOVE; }

"COMMIT"{SQL_ANY}              { return T_COMMIT; }
"ROLLBACK"{SQL_ANY}            { return T_ROLLBACK; }
"SAVEPOINT"{SQL_ANY}           { return T_SAVEPOINT; }

"DROP"{SQL_ANY}                { return T_DROP; }

"GRANT"{SQL_ANY}               { return T_GRANT; }
"REVOKE"{SQL_ANY}              { return T_REVOKE; }

"ENQUEUE"{SQL_ANY}             { return T_ENQUEUE; }
"DEQUEUE"{SQL_ANY}             { return T_DEQUEUE; }

"ALTER"{SQL_ANY}               { return T_ALTER; }
"RENAME"{SQL_ANY}              { return T_RENAME; }
"TRUNCATE"{SQL_ANY}            { return T_TRUNCATE; }
"LOCK"{SQL_ANY}                { return T_LOCK; }

"PREPARE"{SQL_ANY}             { return T_PREPARE; }
"COMMENT"{SQL_ANY}             { return T_COMMENT_SQL; }


"CONNECT"[^\n]*                    { return T_LOGON; }
"DISCONNECT"                    { return T_LOGOFF; }
"!"[^;]*                        { return T_SHELL; }
"AUTOCOMMIT"[^;]*               { return T_AUTOCOMMIT; }
"SPOOL"    { return T_SPOOL; }
"START"    { return T_START; }
"SET"[^\n]*    { return T_SET; }

"VAR"    { return T_VARIABLE; }
"VARIABLE"    { return T_VARIABLE; }

"BIGINT" { return T_TYPE_BIGINT; }
"BLOB"   { return T_TYPE_BLOB; }
"HSS_BLOB"   { return T_TYPE_HSS_BLOB; }
"CHAR"   { return T_TYPE_CHAR; }
"NCHAR"   { return T_TYPE_NCHAR; }
"DATE"   { return T_TYPE_DATE; }
"DECIMAL" { return T_TYPE_DECIMAL; }
"DOUBLE" { return T_TYPE_DOUBLE; }
"FLOAT"  { return T_TYPE_FLOAT; }
"BYTE"   { return T_TYPE_BYTE; }
"HSS_BYTE"   { return T_TYPE_HSS_BYTE; }
"NIBBLE" { return T_TYPE_NIBBLE; }
"HSS_NIBBLE" { return T_TYPE_HSS_NIBBLE; }
"INTEGER" { return T_TYPE_INTEGER; }
"NUMBER" { return T_TYPE_NUMBER; }
"NUMERIC" { return T_TYPE_NUMERIC; }
"REAL"   { return T_TYPE_REAL; }
"SMALLINT" { return T_TYPE_SMALLINT; }
"VARCHAR" { return T_TYPE_VARCHAR; }
"NVARCHAR" { return T_TYPE_NVARCHAR; }

-?[0-9]+                              { return T_INTEGER;      }
-?[0-9]+("."[0-9]*)?([Ee][+-]?[0-9]+)?  |
-?"."[0-9]+([Ee][+-]?[0-9]+)?           { return T_NUMERIC;      }
'("''"|[^'])*'                        { return T_STRING; }


":"[_A-Z][_0-9A-Z]*                   { return T_HOSTVARIABLE; }

"EXEC"    { return T_EXECUTE; }
"EXECUTE"    { return T_EXECUTE; }
":="        { return T_ASSIGN; }
"PRINT"[^\n]*        { return T_PRINT; }

;                                   { return T_SEMICOLON; }
"/"                                   { return T_SLASH; }
,                                   { return T_COMMA; }
"-"                                   { return T_MINUS; }
"+"                                   { return T_PLUS; }
"ON"            { return T_ON; }
"OFF"           { return T_OFF; }

[\t ]+          ;      
\n            ; { return T_EMPTY; }

[_A-Z\200-\377][_0-9A-Z\200-\377$]*  { return T_IDENTIFIER; }
[_0-9A-Z\200-\377./][_A-Z\200-\3770-9./-]* { return T_FILE; }
"("          { return T_LEFT_PARENTHESIS; }
")"          { return T_RIGHT_PARENTHESIS; }
"@"          { return T_AT_SIGN; }
"="          { return T_EQUAL; }

%%
