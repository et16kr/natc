/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: psy.y 1140 2007-02-08 06:21:13Z leekmo $
 **********************************************************************/

%pure_parser

%{
#include "common.h"
#include "pslx.h"
%}

%union {
    psNamePosition position;
    char           data[1024];
}

%{
extern     int pslex( YYSTYPE *, void * );
extern     void addNode( pslx *, nodeType, STAFString );
extern     void addElement ( pslx *aPslx, elementType aType, KeyMap aKeyMap );
idBool     parseLogonRule( STAFString aData, KeyMap &aKeyMap );
void       strip( SChar *aData );
void       strip3( SChar *aData );
STAFString replace( STAFString sData ); 

#define YYPARSE_PARAM param
#define YYLEX_PARAM   param

#define PARAM  ((pslx*)param)
#define MEMORY (PARAM->memory)
#define TEXT_  (PARAM->parseTable->text)

#undef yyerror
#define yyerror(a) pserror((YYPARSE_PARAM), (a))
static void pserror( void *, char * );

%}

%token T_AT_SIGN
%token T_EQUAL
%token T_SLASH
%token T_EMPTY

%token T_SET_ENV
%token T_UNSET_ENV
%token T_SET_RESTART
%token T_ON
%token T_OFF
%token T_SYSTEM
%token T_RSYSTEM
%token T_APPEND_LST
%token T_CHECK2
%token T_DECLARE
%token T_SERVER
%token T_CLIENT
%token T_DEFAULT2
%token T_ISQL_CONNECTION
%token T_LOAD_SQL
%token T_TEST_RECPTR

%token T_COMMAND
%token T_COMMENT

%token T_SKIP
%token T_BEGIN
%token T_END

%token T_IGNORE

%token T_POST
%token T_WAIT

%token T_PROCESS
%token T_SECTOR
%token T_PWAIT

%token T_INTEGER
%token T_NUMERIC
%token T_STRING
%token T_IDENTIFIER
%token T_FILE
%token T_SEMICOLON
%token T_COMMA
%token T_PLUS
%token T_MINUS
%token T_RIGHT_PARENTHESIS
%token T_LEFT_PARENTHESIS

%token T_INSERT
%token T_CREATE
%token T_SELECT
%token T_DESC
%token T_UPDATE
%token T_DELETE
%token T_MOVE
%token T_COMMIT
%token T_ROLLBACK
%token T_SAVEPOINT
%token T_DROP
%token T_GRANT
%token T_REVOKE
%token T_ENQUEUE
%token T_DEQUEUE
%token T_ALTER
%token T_RENAME
%token T_TRUNCATE
%token T_LOCK
%token T_PREPARE
%token T_OBJECT
%token T_COMMENT_SQL

%token T_LOGON
%token T_LOGOFF
%token T_SHELL
%token T_AUTOCOMMIT
%token T_SPOOL
%token T_START
%token T_SET

%token T_VARIABLE
%token T_HOSTVARIABLE
%token T_EXECUTE
%token T_EXECUTE_FUNCTION
%token T_EXECUTE_FUNCTION2
%token T_EXECUTE_PROCEDURE
%token T_EXECUTE_NULL
%token T_ASSIGN
%token T_PRINT

%token T_TYPE_BIGINT
%token T_TYPE_BLOB
%token T_TYPE_HSS_BLOB
%token T_TYPE_CHAR
%token T_TYPE_NCHAR
%token T_TYPE_DATE
%token T_TYPE_DECIMAL
%token T_TYPE_DOUBLE
%token T_TYPE_FLOAT
%token T_TYPE_BYTE
%token T_TYPE_HSS_BYTE
%token T_TYPE_NIBBLE
%token T_TYPE_HSS_NIBBLE
%token T_TYPE_INTEGER
%token T_TYPE_NUMBER
%token T_TYPE_NUMERIC
%token T_TYPE_REAL
%token T_TYPE_SMALLINT
%token T_TYPE_VARCHAR
%token T_TYPE_NVARCHAR

%%

rule_list:
    rule |
    rule_list rule
    ;

rule:
    skip_rule |
    process_rule |
    sector_rule  | 
    comment_rule |
    pwait_rule |
    ignore_rule |
    post_rule |
    wait_rule |
    env_rule |
    system_rule |
    rsystem_rule |
    append_rule |
    check_rule |
    load_sql_rule |
    declare_rule |
    recptr_rule  | // PRJ-1552
    
    insert_rule |
    select_rule |
    desc_rule |
    update_rule |
    delete_rule |
    move_rule |
    commit_rule |
    rollback_rule |
    savepoint_rule |
    create_rule |
    drop_rule |
    grant_rule |
    revoke_rule |
    enqueue_rule |
    dequeue_rule |
    alter_rule |
    rename_rule |
    truncate_rule |
    lock_rule |
    prepare_rule |
    comment_sql_rule |

    connect_rule |
    disconnect_rule |
    autocommit_rule |
    spool_rule |
    start_rule |
    variable_rule |
    execute_rule |
    print_rule |
    shell_rule |
    set_rule | 
    empty_rule 
    ;
   
skip_rule:
    T_COMMAND T_SKIP T_BEGIN T_SEMICOLON
    {
        KeyMap sKeyMap;

        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = "begin";

        (void)addElement( PARAM, TYPE_SKIP, sKeyMap ); 
    }
    | T_COMMAND T_SKIP T_END T_SEMICOLON
    {
        KeyMap sKeyMap;

        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = "end";

        (void)addElement( PARAM, TYPE_SKIP, sKeyMap ); 
    }
    ;

ignore_rule:
    T_COMMAND T_IGNORE T_SEMICOLON
    {
        KeyMap sKeyMap;
        
        (void)addElement( PARAM, TYPE_IGNORE, sKeyMap ); 
    }
    ;

post_rule:
    T_COMMAND T_POST T_IDENTIFIER T_SEMICOLON
    {
        KeyMap sKeyMap;
        SChar  sData[BUFFER_SIZE];

        copyData( sData, 
                  TEXT_ + $<position>3.offset, 
                  $<position>3.size );

        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = sData;
        
        (void)addElement( PARAM, TYPE_POST, sKeyMap ); 
    }
    ;
 
wait_rule:
    T_COMMAND T_WAIT T_IDENTIFIER T_SEMICOLON
    {
        KeyMap sKeyMap;
        SChar  sData[BUFFER_SIZE];

        copyData( sData, 
                  TEXT_ + $<position>3.offset, 
                  $<position>3.size );

        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = sData;
        
        (void)addElement( PARAM, TYPE_WAIT, sKeyMap ); 
    }
    ;

env_rule:
    T_COMMAND T_SET_ENV
    {
        KeyMap sKeyMap;
        SChar  sData[BUFFER_SIZE];

        copyData( sData,
                  TEXT_ + $<position>2.offset + 7,
                  $<position>2.size - 7 );

        strip( sData );

        if( sData[strlen(sData) - 1] == ';' )
        {
            sData[strlen(sData) - 1] = '\0';
        }

        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = sData;

        (void)addElement( PARAM, TYPE_SET_ENV, sKeyMap );
    }
    | T_COMMAND T_UNSET_ENV
    {
        KeyMap sKeyMap;
        SChar  sData[BUFFER_SIZE];

        copyData( sData,
                  TEXT_ + $<position>2.offset + 9,
                  $<position>2.size - 9 );

        strip( sData );

        if( sData[strlen(sData) - 1] == ';' )
        {
            sData[strlen(sData) - 1] = '\0';
        }

        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = sData;

        (void)addElement( PARAM, TYPE_SET_ENV, sKeyMap );
    }
    ;

recptr_rule:
    T_COMMAND T_TEST_RECPTR
    {
        KeyMap              sKeyMap;
        SChar             * pos;
        SChar               sData1[BUFFER_SIZE];
        STAFString          sData2;
        STAFString          sData3;
        recPointData        sRecPointData;

        // TEST_RECPTR ENABLE   'ID', 'TYPE', 0, 0, 0, 'FN', 0;
        // TEST_RECPTR DISABLE  'ID', 'FN', 0;
        // TEST_RECPTR WAKEUP   'ID', 'FN', 0;
        // TEST_RECPTR CLEAR;
        // TEST_RECPTR DUMP;
        
        copyData( sData1,
                  TEXT_ + $<position>2.offset,
                  $<position>2.size);

        strip( sData1 );

        if( sData1[strlen(sData1) - 1] == ';' )
        {
            sData1[strlen(sData1) - 1] = '\0';
        }

        sKeyMap["loc"]  = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        
        if (STAFString( sData1 ).subWord(1,1).upperCase() == "ENABLE")
        {
            sKeyMap["key2"] = "enable_recptr";  // procedure name
        
        }
        else if (STAFString( sData1 ).subWord(1,1).upperCase() == "DISABLE")
        {
            sKeyMap["key2"] = "disable_recptr"; // procedure name
        }
        else if (STAFString( sData1 ).subWord(1,1).upperCase() == "WAKEUP")
        {
            sKeyMap["key2"] = "wakeup_recptr"; // procedure name
        }
        else if (STAFString( sData1 ).subWord(1,1).upperCase() == "CLEAR")
        {
            sKeyMap["key2"] = "clear_recptrs";  // procedure name
        }
        else
        {
            // syntax error
            
            YYABORT;
        }

        sData2 = "execute ";
        sData2 += sKeyMap["key2"];
        sData2 += "(";

        pos = strchr(sData1, '\'');

        if (pos != NULL)
        {
            strip(pos);
            sData2 += pos;
            
            sData3 = STAFString( sData1 ).subWord(2, 1).replace("\'", "").replace(",", "").strip();
            
            if ( (((PARAM->parseTable)->recpointCache)->recpointMap).find(sData3) !=
                 (((PARAM->parseTable)->recpointCache)->recpointMap).end() )
            {
                sRecPointData = (((PARAM->parseTable)->recpointCache)->recpointMap)[sData3];
                
                sData2 += ", '" + sRecPointData.filename + "', ";
                sData2 += sRecPointData.lineNumber;
                
            }
            else 
            {
                // not found	
                YYABORT;
            }
        }
        else
        {
            // clear or print
        }
        
        sData2 += ")";
		
        // query
        sKeyMap["key1"] = sData2;
        sKeyMap["key3"] = ""; // user name
        sKeyMap["key4"] = sData1; // orignal query 
        
        (void)addElement( PARAM, TYPE_TEST_RECPTR, sKeyMap );
    }
    ;

system_rule:
    T_COMMAND T_SYSTEM
    {
        KeyMap sKeyMap;
        SChar  sData[BUFFER_SIZE];

        copyData( sData,
                  TEXT_ + $<position>2.offset + 7,
                  $<position>2.size - 7 );

        strip( sData );

        if( sData[strlen(sData) - 1] == ';' )
        {
            sData[strlen(sData) - 1] = '\0';
        }

        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = replace(sData);

        (void)addElement( PARAM, TYPE_SYSTEM, sKeyMap );
    }
    ;

rsystem_rule:
    T_COMMAND T_RSYSTEM
    {
        KeyMap sKeyMap;
        SChar  sData[BUFFER_SIZE];

        copyData( sData,
                  TEXT_ + $<position>2.offset + 7,
                  $<position>2.size - 7 );

        strip( sData );

        if( sData[strlen(sData) - 1] == ';' )
        {
            sData[strlen(sData) - 1] = '\0';
        }

        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = replace(sData);

        (void)addElement( PARAM, TYPE_RSYSTEM, sKeyMap );
    }
    ;

append_rule:
    T_COMMAND T_APPEND_LST
    {
        KeyMap sKeyMap;
        SChar  sData[BUFFER_SIZE];

        copyData( sData,
                  TEXT_ + $<position>2.offset + 10,
                  $<position>2.size - 10 );

        strip( sData );

        if( sData[strlen(sData) - 1] == ';' )
        {
            sData[strlen(sData) - 1] = '\0';
        }

        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = sData;

        (void)addElement( PARAM, TYPE_APPEND_LST, sKeyMap );
    }
    ;

check_rule:
    T_CHECK2
    {
        KeyMap sKeyMap;
        SChar  sData[BUFFER_SIZE];

        copyData( sData,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        strip( sData );

        if( sData[strlen(sData) - 1] == ';' )
        {
            sData[strlen(sData) - 1] = '\0';
        }

        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = sData;

        (void)addElement( PARAM, TYPE_SYNTAX_ERROR, sKeyMap );
    }
    ;

load_sql_rule:
    T_COMMAND T_LOAD_SQL T_FILE T_SEMICOLON
    {
        KeyMap sKeyMap;
        SChar  sData[BUFFER_SIZE];

        copyData( sData,
                  TEXT_ + $<position>3.offset,
                  $<position>3.size );

        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = sData;

        (void)addElement( PARAM, TYPE_LOAD_SQL, sKeyMap );
    }
    ;

print_rule:
    T_COMMAND
    {
    }
    ;

declare_rule:
    T_COMMAND T_DECLARE T_SERVER T_IDENTIFIER T_IDENTIFIER T_SEMICOLON
    {
        KeyMap sKeyMap;
        SChar  sData[BUFFER_SIZE];

        copyData( sData,
                  TEXT_ + $<position>3.offset,
                  $<position>3.size );
        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = sData;
        copyData( sData,
                  TEXT_ + $<position>4.offset,
                  $<position>4.size );
        sKeyMap["key2"] = sData;
        copyData( sData,
                  TEXT_ + $<position>5.offset,
                  $<position>5.size );
        sKeyMap["key3"] = sData;

        (void)addElement( PARAM, TYPE_DECLARE, sKeyMap );
    }
    | T_COMMAND T_DECLARE T_CLIENT T_DEFAULT2 T_IDENTIFIER T_LEFT_PARENTHESIS T_SERVER T_EQUAL T_IDENTIFIER T_RIGHT_PARENTHESIS T_SEMICOLON
    {
        KeyMap sKeyMap;
        SChar  sData[BUFFER_SIZE];

        copyData( sData,
                  TEXT_ + $<position>3.offset,
                  $<position>3.size );
        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = sData;
        copyData( sData,
                  TEXT_ + $<position>4.offset,
                  $<position>4.size );
        sKeyMap["key2"] = sData;
        copyData( sData,
                  TEXT_ + $<position>5.offset,
                  $<position>5.size );
        sKeyMap["key3"] = sData;
        copyData( sData,
                  TEXT_ + $<position>7.offset,
                  $<position>7.size );
        sKeyMap["key4"] = sData;
        copyData( sData,
                  TEXT_ + $<position>9.offset,
                  $<position>9.size );
        sKeyMap["key5"] = sData;

        (void)addElement( PARAM, TYPE_DECLARE, sKeyMap );
    }
    | T_COMMAND T_DECLARE T_CLIENT T_DEFAULT2 T_IDENTIFIER T_LEFT_PARENTHESIS T_ISQL_CONNECTION T_EQUAL T_IDENTIFIER T_RIGHT_PARENTHESIS T_SEMICOLON
    {
        KeyMap sKeyMap;
        SChar  sData[BUFFER_SIZE];

        copyData( sData,
                  TEXT_ + $<position>3.offset,
                  $<position>3.size );
        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = sData;
        copyData( sData,
                  TEXT_ + $<position>4.offset,
                  $<position>4.size );
        sKeyMap["key2"] = sData;
        copyData( sData,
                  TEXT_ + $<position>5.offset,
                  $<position>5.size );
        sKeyMap["key3"] = sData;
        copyData( sData,
                  TEXT_ + $<position>7.offset,
                  $<position>7.size );
        sKeyMap["key4"] = sData;
        copyData( sData,
                  TEXT_ + $<position>9.offset,
                  $<position>9.size );
        sKeyMap["key5"] = sData;

        (void)addElement( PARAM, TYPE_DECLARE, sKeyMap );
    }
    ;

process_rule: 
    T_COMMAND T_PROCESS T_IDENTIFIER T_SEMICOLON
    {
        SChar sData[BUFFER_SIZE];

        copyData( sData, 
                  TEXT_ + $<position>3.offset,  
                  $<position>3.size );

        (void)addNode( PARAM, TYPE_NORMAL, sData );
    }
    ;
sector_rule: 
    T_COMMAND T_SECTOR
    {
        KeyMap sKeyMap;
        SChar  sData1[BUFFER_SIZE];
        SChar  sData2[BUFFER_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>2.offset + 7,
                  $<position>2.size - 7 ); 
        copyData( sData2,
                  TEXT_ + $<position>2.offset,
                  6 ); 

        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = sData1;
        sKeyMap["key2"] = sData2;

        (void)addElement( PARAM, TYPE_SECTOR, sKeyMap );
    } 
    ;

comment_rule:
    T_COMMENT
    {
        KeyMap sKeyMap;
        SChar  sData[BUFFER_SIZE];

        copyData( sData,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size - 1 );

        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = STAFString(sData).replace(INNER_SEMICOLON, ";");

        (void)addElement( PARAM, TYPE_COMMENT, sKeyMap ); 
    }
    ;

pwait_rule:
    T_COMMAND T_PWAIT T_IDENTIFIER T_SEMICOLON
    {
        SChar sData[BUFFER_SIZE];

        copyData( sData, 
                  TEXT_ + $<position>3.offset, 
                  $<position>3.size );

        (void)addNode( PARAM, TYPE_PWAIT, sData );
        (void)addNode( PARAM, TYPE_NORMAL, "P0" );
    }
    | T_COMMAND T_PWAIT T_INTEGER T_SEMICOLON
    {
        SChar  sData[BUFFER_SIZE];

        copyData( sData, 
                  TEXT_ + $<position>3.offset, 
                  $<position>3.size );

        (void)addNode( PARAM, TYPE_PWAIT, sData );
        (void)addNode( PARAM, TYPE_NORMAL, "P0" );
    }
    | T_COMMAND T_PWAIT T_SEMICOLON
    {
        (void)addNode( PARAM, TYPE_PWAIT, "all" );
        (void)addNode( PARAM, TYPE_NORMAL, "P0" );
    }
    ; 

insert_rule:
    T_INSERT T_SEMICOLON
    {
        SChar      sData[BUFFER_SIZE];
        KeyMap     sKeyMap;

        copyData( sData, 
                  TEXT_ + $<position>1.offset, 
                  $<position>1.size );
       
        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = replace(sData);
                
        (void)addElement( PARAM, TYPE_INSERT, sKeyMap );
    }
    ;

select_rule:
    T_SELECT T_SEMICOLON
    {
        SChar      sData[BUFFER_SIZE];
        STAFString sData3;
        STAFString sData4;
        KeyMap     sKeyMap;

        copyData( sData, 
                  TEXT_ + $<position>1.offset, 
                  $<position>1.size );

        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = replace(sData);

        sData3 = STAFString(sData).upperCase();
        sData4 = sData3.replace(" ", "" ).replace("\t", "").replace("\n", "");
   
        if( sData3.find( "*" ) != STAFString::kNPos )
        {
            if( ( sData3.find( "X$TAB" ) != STAFString::kNPos ) &&
                (sData4.length() == 16 ) )
            {
                (void)addElement( PARAM, TYPE_XTABLES, sKeyMap );
            }
            else if( ( sData3.find( "D$TAB" ) != STAFString::kNPos ) &&
                     (sData4.length() == 16 ) )
            {
                (void)addElement( PARAM, TYPE_DTABLES, sKeyMap );
            }
            else if( ( sData3.find( "V$TAB" ) != STAFString::kNPos ) &&
                     (sData4.length() == 16 ) )
            {
                (void)addElement( PARAM, TYPE_VTABLES, sKeyMap );
            }
            else if( (sData3.find( "TAB" ) != STAFString::kNPos) &&
                     (sData4.length() == 14 ) )
            {
                (void)addElement( PARAM, TYPE_TABLES, sKeyMap );
            }
            else if( ( sData3.find( "SEQ" ) != STAFString::kNPos  ) &&
                     (sData4.length() == 14 ) )
            {
                (void)addElement( PARAM, TYPE_SEQUENCE, sKeyMap );
            }
            else
            {
                (void)addElement( PARAM, TYPE_SELECT, sKeyMap );
            }
        } 
        else
        {
            (void)addElement( PARAM, TYPE_SELECT, sKeyMap );
        }
    }
    ;

desc_rule:
    T_DESC T_SEMICOLON
    {
        SChar      sData[BUFFER_SIZE];
        STAFString sData3;
        KeyMap     sKeyMap;

        copyData( sData, 
                  TEXT_ + $<position>1.offset, 
                  $<position>1.size );

        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = sData;

        sData3 = STAFString(sData + 4).upperCase().strip().replace( "\n", "\n     ");
   
        if( sData3.find( "X$" ) != STAFString::kNPos )
        {
            sKeyMap["key2"] = sData3;
            (void)addElement( PARAM, TYPE_XDESC, sKeyMap );
        }
        else if( sData3.find( "D$" ) != STAFString::kNPos )
        {
            sKeyMap["key2"] = sData3;
            (void)addElement( PARAM, TYPE_DDESC, sKeyMap );
        }
        else if( sData3.find( "V$" ) != STAFString::kNPos )
        {
            sKeyMap["key2"] = sData3;
            (void)addElement( PARAM, TYPE_VDESC, sKeyMap );
        }
        else
        {
            sKeyMap["key2"] = sData3;
            (void)addElement( PARAM, TYPE_DESC, sKeyMap );
        }
    }
    ;

update_rule:
    T_UPDATE T_SEMICOLON
    {
        SChar      sData[BUFFER_SIZE];
        KeyMap     sKeyMap;

        copyData( sData,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );
        
        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = replace(sData);

        (void)addElement( PARAM, TYPE_UPDATE, sKeyMap );
    }
    ;
     
delete_rule:
    T_DELETE T_SEMICOLON
    {
        SChar      sData[BUFFER_SIZE];
        KeyMap     sKeyMap;

        copyData( sData,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );
        
        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = replace(sData);

        (void)addElement( PARAM, TYPE_DELETE, sKeyMap );
    }
    ;

move_rule:
    T_MOVE T_SEMICOLON
    {
        SChar      sData[BUFFER_SIZE];
        KeyMap     sKeyMap;

        copyData( sData,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = replace(sData);

        (void)addElement( PARAM, TYPE_MOVE, sKeyMap );
    }
    ; 

commit_rule:
    T_COMMIT T_SEMICOLON
    {
        SChar      sData[BUFFER_SIZE];
        KeyMap     sKeyMap;

        copyData( sData,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = sData;

        (void)addElement( PARAM, TYPE_COMMIT, sKeyMap );
    }
    ; 

rollback_rule:
    T_ROLLBACK T_SEMICOLON
    {
        SChar      sData[BUFFER_SIZE];
        KeyMap     sKeyMap;

        copyData( sData,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = sData;

        (void)addElement( PARAM, TYPE_ABORT, sKeyMap );
    }
    ;
 
savepoint_rule:
    T_SAVEPOINT T_SEMICOLON
    {
        SChar      sData[BUFFER_SIZE];
        KeyMap     sKeyMap;

        copyData( sData,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = sData;

        (void)addElement( PARAM, TYPE_SAVEPOINT, sKeyMap );
    }
    ; 

create_rule:
    T_OBJECT
    {
        SChar      sData1[BUFFER_SIZE*4];
        SChar      sData2[BUFFER_SIZE*4];
        KeyMap     sKeyMap;
        SInt       sSize;

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );
        copyData( sData2,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size - 1 );

        strip3( sData2 );
        sSize = strlen( sData2 );
        if( sData2[sSize - 1] == ';' )
        {
            sData2[sSize - 1] = '\0';
        }

        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = replace(sData1);
        sKeyMap["key2"] = replace(sData2);

        (void)addElement( PARAM, TYPE_CREATE_OBJECT, sKeyMap );
    }
    | T_CREATE T_SEMICOLON
    {
        SChar      sData[BUFFER_SIZE];
        KeyMap     sKeyMap;

        copyData( sData,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = replace(sData);

        (void)addElement( PARAM, TYPE_CREATE, sKeyMap );
    }
    ;
 
drop_rule:
    T_DROP T_SEMICOLON
    {
        SChar      sData[BUFFER_SIZE];
        KeyMap     sKeyMap;

        copyData( sData,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = STAFString(sData).replace( "\n", "\n     ");

        (void)addElement( PARAM, TYPE_DROP, sKeyMap );
    }
    ;
 
grant_rule:
    T_GRANT T_SEMICOLON
    {
        SChar      sData[BUFFER_SIZE];
        KeyMap     sKeyMap;

        copyData( sData,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = STAFString(sData).replace( "\n", "\n     ");

        (void)addElement( PARAM, TYPE_GRANT, sKeyMap );
    }
    ;
 
revoke_rule:
    T_REVOKE T_SEMICOLON
    {
        SChar      sData[BUFFER_SIZE];
        KeyMap     sKeyMap;

        copyData( sData,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = STAFString(sData).replace( "\n", "\n     ");

        (void)addElement( PARAM, TYPE_REVOKE, sKeyMap );
    }
    ;
 
enqueue_rule:
    T_ENQUEUE T_SEMICOLON
    {
        SChar      sData[BUFFER_SIZE];
        KeyMap     sKeyMap;

        copyData( sData,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = STAFString(sData).replace( "\n", "\n     ");

        (void)addElement( PARAM, TYPE_ENQUEUE, sKeyMap );
    }
    ; 

dequeue_rule:
    T_DEQUEUE T_SEMICOLON
    {
        SChar      sData[BUFFER_SIZE];
        KeyMap     sKeyMap;

        copyData( sData,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = STAFString(sData).replace( "\n", "\n     ");

        (void)addElement( PARAM, TYPE_DEQUEUE, sKeyMap );
    }
    ;
 
alter_rule:
    T_ALTER T_SEMICOLON
    {
        SChar      sData[BUFFER_SIZE];
        KeyMap     sKeyMap;

        copyData( sData,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = replace(sData);

        (void)addElement( PARAM, TYPE_ALTER, sKeyMap );
    }
    ;
 
rename_rule:
    T_RENAME T_SEMICOLON
    {
        SChar      sData[BUFFER_SIZE];
        KeyMap     sKeyMap;

        copyData( sData,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = STAFString(sData).replace( "\n", "\n     ");

        (void)addElement( PARAM, TYPE_RENAME, sKeyMap );
    }
    ;
 
truncate_rule:
    T_TRUNCATE T_SEMICOLON
    {
        SChar      sData[BUFFER_SIZE];
        KeyMap     sKeyMap;

        copyData( sData,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = STAFString(sData).replace( "\n", "\n     ");

        (void)addElement( PARAM, TYPE_TRUNCATE, sKeyMap );
    }
    ;
 
lock_rule:
    T_LOCK T_SEMICOLON
    {
        SChar      sData[BUFFER_SIZE];
        KeyMap     sKeyMap;

        copyData( sData,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = STAFString(sData).replace( "\n", "\n     ");

        (void)addElement( PARAM, TYPE_LOCK, sKeyMap );
    }
    ;
 
prepare_rule:
    T_PREPARE T_SEMICOLON
    {
        SChar      sData1[BUFFER_SIZE];
        SChar      sData2[BUFFER_SIZE];
        KeyMap     sKeyMap;

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );
        copyData( sData2,
                  TEXT_ + $<position>1.offset + 8,
                  $<position>1.size - 8 );

        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = replace(sData1);
        sKeyMap["key2"] = replace(sData2);

        (void)addElement( PARAM, TYPE_PREPARE, sKeyMap );
    }
    ;

comment_sql_rule:
    T_COMMENT_SQL T_SEMICOLON
    {
        SChar      sData1[BUFFER_SIZE];
        KeyMap     sKeyMap;

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = replace(sData1);

        (void)addElement( PARAM, TYPE_COMMENT_SQL, sKeyMap );
    }
    ;
 
connect_rule:
    T_LOGON
    {
        SChar      sData1[BUFFER_SIZE];
        SChar      sData2[BUFFER_SIZE];
        KeyMap     sKeyMap;

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );
        strip( sData1 );
        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = replace(sData1);

        copyData( sData2,
                  sKeyMap["key1"].buffer(),
                  sKeyMap["key1"].length() );

        //BUGBUG 
        parseLogonRule( sData2, sKeyMap );
        (void)addElement( PARAM, TYPE_CONNECT, sKeyMap );
    }
    ;

disconnect_rule:
    T_LOGOFF T_SEMICOLON
    {
        SChar      sData[BUFFER_SIZE];
        KeyMap     sKeyMap;

        copyData( sData,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );
        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = sData;

        (void)addElement( PARAM, TYPE_DISCONNECT, sKeyMap );
    }
    ;

autocommit_rule:
    T_AUTOCOMMIT T_SEMICOLON
    {
        SChar      sData[BUFFER_SIZE];
        KeyMap     sKeyMap;

        copyData( sData,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );
        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = sData;

        (void)addElement( PARAM, TYPE_AUTOCOMMIT, sKeyMap );
    }
    ;

spool_rule:
    T_SPOOL T_FILE T_SEMICOLON
    {
        KeyMap sKeyMap;
        SChar  sData[BUFFER_SIZE];

        copyData( sData,
                  TEXT_ + $<position>2.offset,
                  $<position>2.size );
        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = sData;

        (void)addElement( PARAM, TYPE_SPOOL, sKeyMap );
    }
    | T_SPOOL T_OFF T_SEMICOLON 
    {
        KeyMap sKeyMap;
        SChar  sData[BUFFER_SIZE];

        copyData( sData,
                  TEXT_ + $<position>2.offset,
                  $<position>2.size );
        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = sData;

        (void)addElement( PARAM, TYPE_SPOOL, sKeyMap );
    }
    ;

start_rule:
    T_START T_FILE T_SEMICOLON
    {
        KeyMap sKeyMap;
        SChar  sData1[BUFFER_SIZE];
        SChar  sData2[BUFFER_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );
        copyData( sData2,
                  TEXT_ + $<position>2.offset,
                  $<position>2.size );
        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = sData2;
        sKeyMap["key2"] = "type1";
        sKeyMap["key3"] = sData1;

        (void)addElement( PARAM, TYPE_START, sKeyMap );
    }
    | T_AT_SIGN T_FILE T_SEMICOLON
    {
        KeyMap sKeyMap;
        SChar  sData[BUFFER_SIZE];

        copyData( sData,
                  TEXT_ + $<position>2.offset,
                  $<position>2.size );
        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = sData;
        sKeyMap["key2"] = "type2";

        (void)addElement( PARAM, TYPE_START, sKeyMap );
    }
    ;

variable_rule:
    T_VARIABLE T_IDENTIFIER type_rule T_SEMICOLON
    {
        KeyMap     sKeyMap;
        SChar      sData1[BUFFER_SIZE];
        SChar      sData2[BUFFER_SIZE];
        SChar      sData3[BUFFER_SIZE];
        STAFString sData4;

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );
        copyData( sData2,
                  TEXT_ + $<position>2.offset,
                  $<position>2.size );

        strcpy( sData3, $<data>3 );

        sData4 += STAFString(sData1);
        sData4 += " " + STAFString(sData2) + " " + STAFString(sData3) + ";";

        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = sData4; 
        sKeyMap["key2"] = sData2; 
        sKeyMap["key3"] = PARAM->type;
        sKeyMap["key4"] = PARAM->precision;
        sKeyMap["key5"] = PARAM->scale;
       
        (void)addElement( PARAM, TYPE_VARIABLE, sKeyMap );
    }
    ;

type_rule:
    T_TYPE_BIGINT
    {
        SChar sData1[VAR_SIZE];

        copyData( sData1, 
                  TEXT_ + $<position>1.offset, 
                  $<position>1.size );

        PARAM->type = iSQL_BIGINT;
        PARAM->precision = -1;
        strcpy( PARAM->scale, "" );

        sprintf( $<data>$, "%s", sData1 );
    }
    | T_TYPE_HSS_BLOB
    {
        SChar sData1[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        PARAM->type = iSQL_BAD;
        PARAM->precision = 1;
        strcpy( PARAM->scale, "" );

        sprintf( $<data>$, "%s", sData1 );
    }
    | T_TYPE_HSS_BLOB T_LEFT_PARENTHESIS T_INTEGER T_RIGHT_PARENTHESIS
    {
        SChar sData1[VAR_SIZE];
        SChar sData2[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );
        copyData( sData2,
                  TEXT_ + $<position>3.offset,
                  $<position>3.size );

        PARAM->type = iSQL_BAD;
        PARAM->precision = atoi(sData2);
        strcpy( PARAM->scale, "" );

        sprintf( $<data>$, "%s(%s)", sData1, sData2 );
    }



    | T_TYPE_BLOB
    {
        SChar sData1[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        PARAM->type = iSQL_BAD;
        PARAM->precision = 1;
        strcpy( PARAM->scale, "" );

        sprintf( $<data>$, "%s", sData1 );
    }
    | T_TYPE_BLOB T_LEFT_PARENTHESIS T_INTEGER T_RIGHT_PARENTHESIS
    {
        SChar sData1[VAR_SIZE];
        SChar sData2[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );
        copyData( sData2,
                  TEXT_ + $<position>3.offset,
                  $<position>3.size );

        PARAM->type = iSQL_BAD;
        PARAM->precision = atoi(sData2);
        strcpy( PARAM->scale, "" );

        sprintf( $<data>$, "%s(%s)", sData1, sData2 );
    }
    | T_TYPE_CHAR
    {
        SChar sData1[VAR_SIZE];

        copyData( sData1, 
                  TEXT_ + $<position>1.offset, 
                  $<position>1.size );

        PARAM->type = iSQL_CHAR;
        PARAM->precision = 1;
        strcpy( PARAM->scale, "" );

        sprintf( $<data>$, "%s", sData1 );
    } 
    | T_TYPE_CHAR T_LEFT_PARENTHESIS T_INTEGER T_RIGHT_PARENTHESIS
    {
        SChar sData1[VAR_SIZE];
        SChar sData2[VAR_SIZE];

        copyData( sData1, 
                  TEXT_ + $<position>1.offset, 
                  $<position>1.size );
        copyData( sData2, 
                  TEXT_ + $<position>3.offset, 
                  $<position>3.size );

        PARAM->type = iSQL_CHAR;
        PARAM->precision = atoi(sData2);
        strcpy( PARAM->scale, "" );

        sprintf( $<data>$, "%s(%s)", sData1, sData2 );
    } 
    | T_TYPE_NCHAR
    {
        SChar sData1[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        PARAM->type = iSQL_NCHAR;
        PARAM->precision = 1;
        strcpy( PARAM->scale, "" );

        sprintf( $<data>$, "%s", sData1 );
    }
    | T_TYPE_NCHAR T_LEFT_PARENTHESIS T_INTEGER T_RIGHT_PARENTHESIS
    {
        SChar sData1[VAR_SIZE];
        SChar sData2[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );
        copyData( sData2,
                  TEXT_ + $<position>3.offset,
                  $<position>3.size );

        PARAM->type = iSQL_NCHAR;
        PARAM->precision = atoi(sData2);
        strcpy( PARAM->scale, "" );

        sprintf( $<data>$, "%s(%s)", sData1, sData2 );
    }
    | T_TYPE_DATE
    {
        SChar sData1[VAR_SIZE];

        copyData( sData1, 
                  TEXT_ + $<position>1.offset, 
                  $<position>1.size );
 
        PARAM->type = iSQL_DATE;
        PARAM->precision = -1;
        strcpy( PARAM->scale, "" );
       
        sprintf( $<data>$, sData1 );       
    } 
    | T_TYPE_DECIMAL
    {
        SChar sData1[VAR_SIZE];

        copyData( sData1, 
                  TEXT_ + $<position>1.offset, 
                  $<position>1.size );

        PARAM->type = iSQL_DECIMAL;
        PARAM->precision = -1;
        strcpy( PARAM->scale, "" );

        sprintf( $<data>$, "%s", sData1 );
    } 
    | T_TYPE_DECIMAL T_LEFT_PARENTHESIS T_INTEGER T_RIGHT_PARENTHESIS
    {
        SChar sData1[VAR_SIZE];
        SChar sData2[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );
        copyData( sData2,
                  TEXT_ + $<position>3.offset,
                  $<position>3.size );

        PARAM->type = iSQL_DECIMAL;
        PARAM->precision = atoi(sData2);
        strcpy( PARAM->scale, "" );

        sprintf( $<data>$, "%s(%s)", sData1, sData2 );
    } 
    | T_TYPE_DECIMAL T_LEFT_PARENTHESIS T_INTEGER T_COMMA T_INTEGER T_RIGHT_PARENTHESIS
    {
        SChar sData1[VAR_SIZE];
        SChar sData2[VAR_SIZE];
        SChar sData3[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );
        copyData( sData2,
                  TEXT_ + $<position>3.offset,
                  $<position>3.size );
        copyData( sData3,
                  TEXT_ + $<position>5.offset,
                  $<position>5.size );

        PARAM->type = iSQL_DECIMAL;
        PARAM->precision = atoi(sData2);
        strcpy( PARAM->scale, sData3 );

        sprintf( $<data>$, "%s(%s, %s)", sData1, sData2, sData3 );
    } 
    | T_TYPE_DECIMAL T_LEFT_PARENTHESIS T_INTEGER T_COMMA T_PLUS T_INTEGER T_RIGHT_PARENTHESIS
    {
        SChar sData1[VAR_SIZE];
        SChar sData2[VAR_SIZE];
        SChar sData3[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );
        copyData( sData2,
                  TEXT_ + $<position>3.offset,
                  $<position>3.size );
        copyData( sData3,
                  TEXT_ + $<position>6.offset,
                  $<position>6.size );

        PARAM->type = iSQL_DECIMAL;
        PARAM->precision = atoi(sData2);
        sprintf( PARAM->scale, "+%s", sData3 );

        sprintf( $<data>$, "%s(%s, +%s)", sData1, sData2, sData3 );
    } 
    | T_TYPE_DECIMAL T_LEFT_PARENTHESIS T_INTEGER T_COMMA T_MINUS T_INTEGER T_RIGHT_PARENTHESIS
    {
        SChar sData1[VAR_SIZE];
        SChar sData2[VAR_SIZE];
        SChar sData3[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );
        copyData( sData2,
                  TEXT_ + $<position>3.offset,
                  $<position>3.size );
        copyData( sData3,
                  TEXT_ + $<position>6.offset,
                  $<position>6.size );

        PARAM->type = iSQL_DECIMAL;
        PARAM->precision = atoi(sData2);
        sprintf( PARAM->scale, "-%s", sData3 );

        sprintf( $<data>$, "%s(%s, -%s)", sData1, sData2, sData3 );
    } 
    | T_TYPE_DOUBLE 
    {
        SChar sData1[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        PARAM->type = iSQL_DOUBLE;
        PARAM->precision = -1;
        strcpy( PARAM->scale, "" );

        sprintf( $<data>$, "%s", sData1 );
    } 
    | T_TYPE_FLOAT
    {
        SChar sData1[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        PARAM->type = iSQL_FLOAT;
        PARAM->precision = -1;
        strcpy( PARAM->scale, "" );

        sprintf( $<data>$, "%s", sData1 );
    } 
    | T_TYPE_FLOAT T_LEFT_PARENTHESIS T_INTEGER T_RIGHT_PARENTHESIS
    {
        SChar sData1[VAR_SIZE];
        SChar sData2[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );
        copyData( sData2,
                  TEXT_ + $<position>3.offset,
                  $<position>3.size );

        PARAM->type = iSQL_FLOAT;
        PARAM->precision = atoi(sData2);
        strcpy( PARAM->scale, "" );

        sprintf( $<data>$, "%s(%s)", sData1, sData2 );
    } 
    | T_TYPE_HSS_BYTE 
    {
        SChar sData1[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        PARAM->type = iSQL_BAD;
        PARAM->precision = 1;
        strcpy( PARAM->scale, "" );

        sprintf( $<data>$, "%s", sData1 );
    } 
    | T_TYPE_HSS_BYTE T_LEFT_PARENTHESIS T_INTEGER T_RIGHT_PARENTHESIS
    {
        SChar sData1[VAR_SIZE];
        SChar sData2[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );
        copyData( sData2,
                  TEXT_ + $<position>3.offset,
                  $<position>3.size );

        PARAM->type = iSQL_BAD;
        PARAM->precision = atoi(sData2);
        strcpy( PARAM->scale, "" );

        sprintf( $<data>$, "%s(%s)", sData1, sData2 );
    } 
    | T_TYPE_HSS_NIBBLE
    {
        SChar sData1[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        PARAM->type = iSQL_BAD;
        PARAM->precision = 1;
        strcpy( PARAM->scale, "" );

        sprintf( $<data>$, "%s", sData1 );
    } 
    | T_TYPE_HSS_NIBBLE T_LEFT_PARENTHESIS T_INTEGER T_RIGHT_PARENTHESIS
    {
        SChar sData1[VAR_SIZE];
        SChar sData2[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );
        copyData( sData2,
                  TEXT_ + $<position>3.offset,
                  $<position>3.size );

        PARAM->type = iSQL_BAD;
        PARAM->precision = atoi(sData2);
        strcpy( PARAM->scale, "" );

        sprintf( $<data>$, "%s(%s)", sData1, sData2 );
    } 
    | T_TYPE_BYTE 
    {
        SChar sData1[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        PARAM->type = iSQL_BYTE;
        PARAM->precision = 1;
        strcpy( PARAM->scale, "" );

        sprintf( $<data>$, "%s", sData1 );
    } 
    | T_TYPE_BYTE T_LEFT_PARENTHESIS T_INTEGER T_RIGHT_PARENTHESIS
    {
        SChar sData1[VAR_SIZE];
        SChar sData2[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );
        copyData( sData2,
                  TEXT_ + $<position>3.offset,
                  $<position>3.size );

        PARAM->type = iSQL_BYTE;
        PARAM->precision = atoi(sData2);
        strcpy( PARAM->scale, "" );

        sprintf( $<data>$, "%s(%s)", sData1, sData2 );
    } 
    | T_TYPE_NIBBLE
    {
        SChar sData1[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        PARAM->type = iSQL_NIBBLE;
        PARAM->precision = 1;
        strcpy( PARAM->scale, "" );

        sprintf( $<data>$, "%s", sData1 );
    } 
    | T_TYPE_NIBBLE T_LEFT_PARENTHESIS T_INTEGER T_RIGHT_PARENTHESIS
    {
        SChar sData1[VAR_SIZE];
        SChar sData2[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );
        copyData( sData2,
                  TEXT_ + $<position>3.offset,
                  $<position>3.size );

        PARAM->type = iSQL_NIBBLE;
        PARAM->precision = atoi(sData2);
        strcpy( PARAM->scale, "" );

        sprintf( $<data>$, "%s(%s)", sData1, sData2 );
    } 
    | T_TYPE_INTEGER
    {
        SChar sData1[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        PARAM->type = iSQL_INTEGER;
        PARAM->precision = -1;
        strcpy( PARAM->scale, "" );

        sprintf( $<data>$, "%s", sData1 );
    } 
    | T_IDENTIFIER
    {
        SChar sData1[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        PARAM->type = iSQL_BAD;
        PARAM->precision = -1;
        strcpy( PARAM->scale, "" );

        sprintf( $<data>$, "%s", sData1 );
    }
    | T_TYPE_NUMBER
    {
        SChar sData1[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        PARAM->type = iSQL_NUMBER;
        PARAM->precision = -1;
        strcpy( PARAM->scale, "" );

        sprintf( $<data>$, "%s", sData1 );
    } 
    | T_TYPE_NUMBER T_LEFT_PARENTHESIS T_INTEGER T_RIGHT_PARENTHESIS
    {
        SChar sData1[VAR_SIZE];
        SChar sData2[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );
        copyData( sData2,
                  TEXT_ + $<position>3.offset,
                  $<position>3.size );

        PARAM->type = iSQL_NUMBER;
        PARAM->precision = atoi(sData2);
        strcpy( PARAM->scale, "" );

        sprintf( $<data>$, "%s(%s)", sData1, sData2 );
    } 
    | T_TYPE_NUMBER T_LEFT_PARENTHESIS T_INTEGER T_COMMA T_INTEGER T_RIGHT_PARENTHESIS
    {
        SChar sData1[VAR_SIZE];
        SChar sData2[VAR_SIZE];
        SChar sData3[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );
        copyData( sData2,
                  TEXT_ + $<position>3.offset,
                  $<position>3.size );
        copyData( sData3,
                  TEXT_ + $<position>5.offset,
                  $<position>5.size );

        PARAM->type = iSQL_NUMBER;
        PARAM->precision = atoi(sData2);
        strcpy( PARAM->scale, sData3 );

        sprintf( $<data>$, "%s(%s, %s)", sData1, sData2, sData3 );
    } 
    | T_TYPE_NUMBER T_LEFT_PARENTHESIS T_INTEGER T_COMMA T_PLUS T_INTEGER T_RIGHT_PARENTHESIS
    {
        SChar sData1[VAR_SIZE];
        SChar sData2[VAR_SIZE];
        SChar sData3[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );
        copyData( sData2,
                  TEXT_ + $<position>3.offset,
                  $<position>3.size );
        copyData( sData3,
                  TEXT_ + $<position>6.offset,
                  $<position>6.size );

        PARAM->type = iSQL_NUMBER;
        PARAM->precision = atoi(sData2);
        sprintf( PARAM->scale, "+%s", sData3 );

        sprintf( $<data>$, "%s(%s, +%s)", sData1, sData2, sData3 );
    } 
    | T_TYPE_NUMBER T_LEFT_PARENTHESIS T_INTEGER T_COMMA T_MINUS T_INTEGER T_RIGHT_PARENTHESIS
    {
        SChar sData1[VAR_SIZE];
        SChar sData2[VAR_SIZE];
        SChar sData3[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );
        copyData( sData2,
                  TEXT_ + $<position>3.offset,
                  $<position>3.size );
        copyData( sData3,
                  TEXT_ + $<position>6.offset,
                  $<position>6.size );

        PARAM->type = iSQL_NUMBER;
        PARAM->precision = atoi(sData2);
        sprintf( PARAM->scale, "-%s", sData3 );

        sprintf( $<data>$, "%s(%s, -%s)", sData1, sData2, sData3 );
    } 
    | T_TYPE_NUMERIC
    {
        SChar sData1[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        PARAM->type = iSQL_NUMERIC;
        PARAM->precision = -1;
        strcpy( PARAM->scale, "" );

        sprintf( $<data>$, "%s", sData1 );
    } 
    | T_TYPE_NUMERIC T_LEFT_PARENTHESIS T_INTEGER T_RIGHT_PARENTHESIS
    {
        SChar sData1[VAR_SIZE];
        SChar sData2[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );
        copyData( sData2,
                  TEXT_ + $<position>3.offset,
                  $<position>3.size );

        PARAM->type = iSQL_DECIMAL;
        PARAM->precision = atoi(sData2);
        strcpy( PARAM->scale, "" );

        sprintf( $<data>$, "%s(%s)", sData1, sData2 );
    } 
    | T_TYPE_NUMERIC T_LEFT_PARENTHESIS T_INTEGER T_COMMA T_INTEGER T_RIGHT_PARENTHESIS
    {
        SChar sData1[VAR_SIZE];
        SChar sData2[VAR_SIZE];
        SChar sData3[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );
        copyData( sData2,
                  TEXT_ + $<position>3.offset,
                  $<position>3.size );
        copyData( sData3,
                  TEXT_ + $<position>5.offset,
                  $<position>5.size );

        PARAM->type = iSQL_NUMERIC;
        PARAM->precision = atoi(sData2);
        strcpy( PARAM->scale, sData3 );

        sprintf( $<data>$, "%s(%s, %s)", sData1, sData2, sData3 );
    } 
    | T_TYPE_NUMERIC T_LEFT_PARENTHESIS T_INTEGER T_COMMA T_PLUS T_INTEGER T_RIGHT_PARENTHESIS
    {
        SChar sData1[VAR_SIZE];
        SChar sData2[VAR_SIZE];
        SChar sData3[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );
        copyData( sData2,
                  TEXT_ + $<position>3.offset,
                  $<position>3.size );
        copyData( sData3,
                  TEXT_ + $<position>6.offset,
                  $<position>6.size );

        PARAM->type = iSQL_DECIMAL;
        PARAM->precision = atoi(sData2);
        sprintf( PARAM->scale, "+%s", sData3 );

        sprintf( $<data>$, "%s(%s, +%s)", sData1, sData2, sData3 );
    } 
    | T_TYPE_NUMERIC T_LEFT_PARENTHESIS T_INTEGER T_COMMA T_MINUS T_INTEGER T_RIGHT_PARENTHESIS
    {
        SChar sData1[VAR_SIZE];
        SChar sData2[VAR_SIZE];
        SChar sData3[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );
        copyData( sData2,
                  TEXT_ + $<position>3.offset,
                  $<position>3.size );
        copyData( sData3,
                  TEXT_ + $<position>6.offset,
                  $<position>6.size );

        PARAM->type = iSQL_NUMERIC;
        PARAM->precision = atoi(sData2);
        sprintf( PARAM->scale, "+%s", sData3 );

        sprintf( $<data>$, "%s(%s, -%s)", sData1, sData2, sData3 );
    }
    | T_TYPE_REAL 
    {
        SChar sData1[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        PARAM->type = iSQL_REAL;
        PARAM->precision = -1;
        strcpy( PARAM->scale, "" );

        sprintf( $<data>$, "%s", sData1 );
    }
    | T_TYPE_SMALLINT
    {
        SChar sData1[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        PARAM->type = iSQL_SMALLINT;
        PARAM->precision = -1;
        strcpy( PARAM->scale, "" );

        sprintf( $<data>$, "%s", sData1 );
    }
    | T_TYPE_VARCHAR
    {
        SChar sData1[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        PARAM->type = iSQL_VARCHAR;
        PARAM->precision = 1;
        strcpy( PARAM->scale, "" );

        sprintf( $<data>$, "%s", sData1 );
    }
    | T_TYPE_VARCHAR T_LEFT_PARENTHESIS T_INTEGER T_RIGHT_PARENTHESIS
    {
        SChar sData1[VAR_SIZE];
        SChar sData2[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );
        copyData( sData2,
                  TEXT_ + $<position>3.offset,
                  $<position>3.size );

        PARAM->type = iSQL_VARCHAR;
        PARAM->precision = atoi(sData2);
        strcpy( PARAM->scale, "" );

        sprintf( $<data>$, "%s(%s)", sData1, sData2 );
    }
    | T_TYPE_NVARCHAR
    {
        SChar sData1[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        PARAM->type = iSQL_NVARCHAR;
        PARAM->precision = 1;
        strcpy( PARAM->scale, "" );

        sprintf( $<data>$, "%s", sData1 );
    }
    | T_TYPE_NVARCHAR T_LEFT_PARENTHESIS T_INTEGER T_RIGHT_PARENTHESIS
    {
        SChar sData1[VAR_SIZE];
        SChar sData2[VAR_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );
        copyData( sData2,
                  TEXT_ + $<position>3.offset,
                  $<position>3.size );

        PARAM->type = iSQL_NVARCHAR;
        PARAM->precision = atoi(sData2);
        strcpy( PARAM->scale, "" );

        sprintf( $<data>$, "%s(%s)", sData1, sData2 );
    }
    ;

execute_rule:
    T_EXECUTE_NULL T_SEMICOLON
    {
        KeyMap sKeyMap;
        SChar  sData1[BUFFER_SIZE];
        SChar *pos;
        SChar *pos2;
        
        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );
    
        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = sData1;

        pos = strchr( sData1, ':');
        if ( pos != NULL )
        {
            pos2 = strtok(pos, " \t:");
            if ( pos2 != NULL )
            {
                sKeyMap["key2"] = pos2;
            }
        }
        (void)addElement( PARAM, TYPE_EXECUTE, sKeyMap );
    }
    | T_EXECUTE T_HOSTVARIABLE T_ASSIGN T_INTEGER T_SEMICOLON
    {
        KeyMap sKeyMap;
        SChar  sData1[BUFFER_SIZE];
        SChar  sData2[BUFFER_SIZE];
        SChar  sData3[BUFFER_SIZE];
        SChar  sData4[BUFFER_SIZE];
        
        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );
        copyData( sData2,
                  TEXT_ + $<position>2.offset,
                  $<position>2.size );
        copyData( sData3,
                  TEXT_ + $<position>4.offset,
                  $<position>4.size );
   
        sprintf( sData4, "%s %s := %s", sData1, sData2, sData3 );
 
        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = sData4;
        sKeyMap["key2"] = sData2 + 1;
        sKeyMap["key3"] = sData3;

        (void)addElement( PARAM, TYPE_EXECUTE, sKeyMap );


    }
    | T_EXECUTE T_HOSTVARIABLE T_ASSIGN T_NUMERIC T_SEMICOLON
    {
        KeyMap sKeyMap;
        SChar  sData1[BUFFER_SIZE];
        SChar  sData2[BUFFER_SIZE];
        SChar  sData3[BUFFER_SIZE];
        SChar  sData4[BUFFER_SIZE];
        
        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );
        copyData( sData2,
                  TEXT_ + $<position>2.offset,
                  $<position>2.size );
        copyData( sData3,
                  TEXT_ + $<position>4.offset,
                  $<position>4.size );
   
        sprintf( sData4, "%s %s := %s", sData1, sData2, sData3 );
 
        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = sData4;
        sKeyMap["key2"] = sData2 + 1;
        sKeyMap["key3"] = sData3;

        (void)addElement( PARAM, TYPE_EXECUTE, sKeyMap );
    }
    | T_EXECUTE T_HOSTVARIABLE T_ASSIGN T_STRING T_SEMICOLON
    {
        KeyMap sKeyMap;
        SChar  sData1[BUFFER_SIZE];
        SChar  sData2[BUFFER_SIZE];
        SChar  sData3[BUFFER_SIZE];
        SChar  sData4[BUFFER_SIZE];
        
        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );
        copyData( sData2,
                  TEXT_ + $<position>2.offset,
                  $<position>2.size );
        copyData( sData3,
                  TEXT_ + $<position>4.offset,
                  $<position>4.size );
   
        sprintf( sData4, "%s %s := %s", sData1, sData2, sData3 );
 
        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = sData4;
        sKeyMap["key2"] = sData2 + 1;
        sKeyMap["key3"] = sData3;

        (void)addElement( PARAM, TYPE_EXECUTE, sKeyMap );
    }
    | T_EXECUTE_FUNCTION2 T_SEMICOLON
    {
        KeyMap sKeyMap;
        SChar  sData1[BUFFER_SIZE];

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = replace(sData1);
        
        (void)addElement( PARAM, TYPE_SYNTAX_ERROR, sKeyMap );
    }
    | T_EXECUTE_FUNCTION T_SEMICOLON
    {
        KeyMap sKeyMap;
        SChar  sData1[BUFFER_SIZE];
        SChar *pos1;
        SChar *pos2;
        SChar *pos3;

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = replace(sData1);

        /*
        // pos1 : '='
        // pos2 : '('
        // pos3 : '.'
        pos1 = strchr(sData1, '=');
        if (pos1 != NULL)
        {
            pos2 = strchr(pos1+1, '(');
            pos3 = strchr(pos1+1, '.');

            if (pos2 != NULL && pos3 != NULL)
            {
                if (pos2 < pos3)
                {
                    // case : exec :a := funcname(...);
                    *pos2 = '\0';
                    strip(pos1+1);
                    sKeyMap["key2"] = pos1 + 1;
                    sKeyMap["key3"] = "";
                }
                else
                {
                    // case : exec :a := username.funcname(...);
                    *pos2 = '\0';
                    strip(pos3+1);
                    sKeyMap["key2"] = pos3 + 1;
                    *pos3 = '\0';
                    strip(pos1+1);
                    sKeyMap["key3"] = pos1 + 1;
                }
            }
            else if (pos2 != NULL)
            {
                // case : exec :a := funcname(...);
                *pos2 = '\0';
                strip(pos1+1);
                sKeyMap["key2"] = pos1 + 1;
                sKeyMap["key3"] = "";
            }
            else if (pos3 != NULL)
            {
                // case : exec :a := username.funcname;
                strip(pos3+1);
                sKeyMap["key2"] = pos3 + 1;
                *pos3 = '\0';
                strip(pos1+1);
                sKeyMap["key3"] = pos1 + 1;
            }
            else
            {
                // case : exec :a := funcname;
                strip(pos1+1);
                sKeyMap["key2"] = pos1 + 1;
                sKeyMap["key3"] = "";
            }
        }
        else
        {
            // impossible
        }
        */
        
        (void)addElement( PARAM, TYPE_EXECUTE_FUNCTION, sKeyMap );

    }
    | T_EXECUTE_PROCEDURE T_SEMICOLON
    {
        KeyMap sKeyMap;
        SChar  sData1[BUFFER_SIZE];
        SChar *pos1;
        SChar *pos2;
        SChar *pos3;

        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        sKeyMap["loc"]  = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = replace(sData1);

        /*
        pos1 = strtok(sData1, " \t\n");
        if (pos1 != NULL)
        {
            pos1 = strtok(NULL, " \t\n");
            if (pos1 != NULL)
            {
                pos2 = strchr(pos1, '(');
                pos3 = strchr(pos1, '.');

                if (pos2 != NULL && pos3 != NULL)
                {
                    if (pos2 < pos3)
                    {
                        // case : exec procname(...);
                        *pos2 = '\0';
                        strip(pos1);
                        sKeyMap["key2"] = pos1;
                        sKeyMap["key3"] = "";
                    }
                    else
                    {
                        // case : exec username.procname(...);
                        *pos2 = '\0';
                        strip(pos3+1);
                        sKeyMap["key2"] = pos3+1;
                        *pos3 = '\0';
                        strip(pos1);
                        sKeyMap["key3"] = pos1;
                    }
                }
                else if (pos2 != NULL)
                {
                    // case : exec procname(...);
                    *pos2 = '\0';
                    strip(pos1);
                    sKeyMap["key2"] = pos1;
                    sKeyMap["key3"] = "";
                }
                else if (pos3 != NULL)
                {
                    // case : exec username.procname;
                    strip(pos3+1);
		    sKeyMap["key2"] = pos3+1;
                    *pos3 = '\0';
                    strip(pos1);
                    sKeyMap["key3"] = pos1;
                }
                else
                {
                    // case : exec procname;
                    strip(pos1);
                    sKeyMap["key2"] = pos1;
                    sKeyMap["key3"] = ""; 
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
        */
        
        (void)addElement( PARAM, TYPE_EXECUTE_PROCEDURE, sKeyMap );
    }
    ;

print_rule:
    T_PRINT
    {
        KeyMap     sKeyMap;
        SChar      sData1[BUFFER_SIZE];
        STAFString sData2;
        STAFString sData3;
        UInt       sData4;
       
        copyData( sData1,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = sData1;

        sData4 = STAFString(sData1).findFirstOf( ";" );

        sData2 = STAFString(sData1).subString( 0, sData4 ).strip();
        sData3 = sData2.subWord(1);

        if( sData3.length() == 0 )
        {
            sKeyMap["key2"] = "all";
        }
        else
        {
            sKeyMap["key2"] = sData3;

            if( (sData3.upperCase() == "VAR") ||
                (sData3.upperCase() == "VARIABLE") )
            {
                sKeyMap["key2"] = "all";
            }
        }
        
        (void)addElement( PARAM, TYPE_PRINT, sKeyMap );
    }
    ;

shell_rule:
    T_SHELL T_SEMICOLON
    { 
        KeyMap sKeyMap;
        SChar  sData[BUFFER_SIZE];

        copyData( sData,
                  TEXT_ + $<position>1.offset + 1,
                  $<position>1.size - 1 );
        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = replace(sData).replace("{","").replace("}","");
        
        (void)addElement( PARAM, TYPE_SHELL, sKeyMap );
    }
    ;

set_rule:
    T_SET 
    {
       KeyMap sKeyMap;
        SChar  sData[BUFFER_SIZE];

        copyData( sData,
                  TEXT_ + $<position>1.offset,
                  $<position>1.size );

        strip( sData );

        if( sData[strlen(sData) - 1] == ';' )
        {
            sData[strlen(sData) - 1] = '\0';
        }

        sKeyMap["loc"] = STAFString( TEXT_ ).subString( 0, $<position>1.offset + $<position>1.size ).count( "\n" ) + 1;
        sKeyMap["key1"] = sData;

        (void)addElement( PARAM, TYPE_SET, sKeyMap );
    }
    ;

empty_rule:
    T_EMPTY
    {
        KeyMap sKeyMap;

        (void)addElement( PARAM, TYPE_EMPTY, sKeyMap );
    }
    ;

%%

# undef yyFlexLexer
# define yyFlexLexer psFlexLexer

# include <FlexLexer.h>

#include "pslx.h"
#include "psl.h"

void pserror( void * param, char * aMessage )
{
    psLexer *sLexer = ((pslx *)param)->lexer;

    if( strcmp( aMessage, "syntax error") == 0 )
    {
        ((pslx *)param)->parseTable->error = sLexer->getLexLastError( (SChar*) "parse error" );
    }
    else
    {
        ((pslx *)param)->parseTable->error = sLexer->getLexLastError( aMessage );
    }
}

idBool parseLogonRule( STAFString aData, KeyMap &aKeyMap )
{
    SChar * pos1;
    SChar * pos2;
    SChar * pos3;
    SInt    sSize;
    SChar   sBuffer[BUFFER_SIZE];

    memcpy( sBuffer,
                   aData.buffer(),
                   aData.length() );
    sBuffer[aData.length()] = '\0';

    pos1 = strtok(sBuffer, " \t");
    if ( pos1 != NULL )
    {
        pos1 = strtok(NULL, "\n");
        if ( pos1 != NULL )
        {
            pos2 = strchr(pos1, '/');
            if ( pos2 != NULL )
            {
               *pos2 = '\0';
               strip(pos1);
               aKeyMap["key2"] = STAFString( pos1 );

                pos2++;
                strip(pos2);
                sSize = strlen(pos2);
                if ( pos2[sSize-1] == ';' )
                {
                    pos2[sSize-1] = '\0';
                }
                pos3 = strtok(pos2, " \t");
                if ( pos3 != NULL )
                {
                    aKeyMap["key3"] = STAFString( pos2 );
                    pos1 = strtok(NULL, " \t");
                    if ( pos1 != NULL ) // connect user/manager as sysdba
                    {
                        if (strcasecmp(pos1, "AS") != 0)
                        {
                            return ID_FALSE;
                        }
                        pos1 = strtok(NULL, " \t");
                        if ( pos1 != NULL )
                        {
                            if (strcasecmp(pos1, "SYSDBA") == 0)
                            {
                                aKeyMap["key4"] = "sysdba";
                            }
                            else
                            {
                                return ID_FALSE;
                            }
                        }
                        else
                        {
                            return ID_FALSE;
                        }
                    }
                    else // connect user/passwd
                    {
                        aKeyMap["key4"] = "";
                    }
                }
                else
                {
                    return ID_FALSE;
                }
            }
            else
            {
                return ID_FALSE;
            }
        }
        else
        {
            return ID_FALSE;
        }
    }
    else
    {
        return ID_FALSE;
    }

    return ID_TRUE;
}

void strip( SChar *aData ) 
{ 
    SInt i, j;
    SInt len;

    len = strlen(aData);
    if( len <= 0 )
    {
        return;
    }

    for (i=0; i<len && aData[i]; i++)
    {
        if (aData[i]==' ') // (v(,(!aAI(v(, AO
        {
            for (j=i; aData[j]; j++)
            {
                aData[j] = aData[j+1];
            }
            i--;
        }
        else
        {
            break;
        }
    }
   
    len = strlen(aData);
    if( len <= 0 )
    {
        return;
    }

    for (i=len-1; aData[i] && len>=0; i--)
    {
        if (aData[i]==' ') // (v(,(!aAI(v(, (z)*(zO!>a
        {
            aData[i] = 0;
        }
        else
        {
            break;
        }
    }
}

void strip3( SChar *aData ) 
{ 
    SInt i, j;
    SInt len;

    len = strlen(aData);
    if( len <= 0 )
    {
        return;
    }

    for (i=0; i<len && aData[i]; i++)
    {
        if ( (aData[i]==' ') || (aData[i]=='\n'))
        {
            for (j=i; aData[j]; j++)
            {
                aData[j] = aData[j+1];
            }
            i--;
        }
        else
        {
            break;
        }
    }
   
    len = strlen(aData);
    if( len <= 0 )
    {
        return;
    }

    for (i=len-1; aData[i] && len>=0; i--)
    {
        if ( (aData[i]==' ') || (aData[i]=='\n'))
        {
            aData[i] = 0;
        }
        else
        {
            break;
        }
    }
}

STAFString replace( STAFString aData )
{
    return aData.replace( "\n", "\n     ").replace(INNER_SEMICOLON, ";").replace(INNER_SLASH, "/");
}
