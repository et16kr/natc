/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iSQLHelp.cpp 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/

#include <ideMsgLog.h>
#include <iSQLHelp.h>

typedef struct isqlHelp
{
    SChar *HelpMsg;
    SInt   HelpKind;
}isqlHelp;

isqlHelp HelpStr[HELP_MSG_CNT] =
{
    {
    (SChar*)
    "Use 'help [command]'\n"                                              
    "Enter 'help index' for a list of command\n",                   NON_COM       // 0
    },

    {
    (SChar*)
    "@             EXECUTE       ROLLBACK\n"
    "/             EDIT          SAVE\n"
    "A[DD]         EXIT          SELECT\n"
    "C[HANGE]      HEADING       SPOOL\n"
    "ALTER         H[ISTORY]     START\n"
    "AUTOCOMMIT    INSERT        TIMING\n"
    "COMMIT        LINESIZE      UPDATE\n"
    "CREATE        LOAD          VAR[IABLE]\n"
    "DELETE        MOVE          TERM\n"
    "DESC          PAGESIZE      COLSIZE\n"
    "DROP          QUIT\n",                                         INDEX_COM      // 1    
    },
    
    {
    (SChar*)
    "have no help mesage\n",                                        OTHER_COM        // 2
    },

    {
    (SChar*)
    "exit;\n"                                            
    "or\n"
    "quit; - exit iSQL\n",                                          EXIT_COM       // 3
    },
    {
    (SChar*)
    "history;\n" 
    "or\n"
    "h;       - display late command\n",                            HISTORY_COM    // 4
    },
    {
    (SChar*)
    "/    - run the last command\n"                                       
    "NUM/ - run the command that history number is NUM\n",          HISRUN_COM     // 5
    },
    
    {
    (SChar*)
    "desc table_name; - display attribute and index list\n",        DESC_COM       // 6
    },
    {
    (SChar*)
    "select * from tab; - display table list\n"                 
    "select * from x$tab; - display fixed-table/performance-view list\n"                 
    "select ...;        - display result of query execution\n",     SELECT_COM     // 7           
    },
    {
    (SChar*)
    "update ...; - update record\n",                                UPDATE_COM     // 8
    },
    {
    (SChar*)
    "delete ...; - delete record\n",                                DELETE_COM     // 9
    },
    {
    (SChar*)
    "insert ...; - insert record\n",                                INSERT_COM     // 10
    },
    {
    (SChar*)
    "create ...; - create object\n",                                CRT_OBJ_COM    // 11
    },
    {
    (SChar*)
    "create ...; - create object\n",                                CRT_PROC_COM    // 12
    },
    {
    (SChar*)
    "drop ...; - drop object\n",                                    DROP_COM       // 13
    },
    {
    (SChar*)
    "alter ...; - alter object\n",                                  ALTER_COM      // 14
    },
    {
    (SChar*)
    "execute ...; - execute procedure or function\n",               EXECUTE_COM    // 15
    },

    {
    (SChar*)
    "spool file_name; - spool start\n"                                 
    "spool off;       - spool end\n",                               SPOOL_COM      // 16
    },

    {
    (SChar*)
    "start file_name; - run script file\n"                    
    "@file_name;      - run script file\n",                         SCRIPTRUN_COM  // 17
    },
    
    {
    (SChar*)
    "autocommit on;  - specify autocommit mode is on\n"
    "autocommit off; - specify autocommit mode is off\n",           AUTOCOMMIT_COM // 18
    },
    {
    (SChar*)
    "commit; - execute commit\n"
    "          autocommit mode should be off\n",                    COMMIT_COM     // 19
    },

    {
    (SChar*)
    "rollback; - execute rollback\n"
    "            autocommit mode should be off\n",                  ROLLBACK_COM   // 20
    },

    {
    (SChar*)
    "check; - check log \n"
    "         check open_logfile_info \n"
    "         check replication_gap \n"
    "         check properties \n"
    "         check session_properties \n"
    "         check session_status \n"
    "         check statement_status \n"
    "         check trans_lock_info \n"
    "         check statement_tarce \n"
    "         check statement_phase \n"
    "         check table_lock_info \n"
    "         check memory \n"
    "         check sequence seq_name \n"
    "         check ipc \n",                                        CHECK_COM   // 21
    },

    {
    (SChar*)
    "ed; - edit prior query \n"
    "      default editor : ed\n"
    "      or if environment EDIT=vi then  vi editor \n"
    "      ex) ed; - the lastest history query      \n"
    "          1 ed; - given history query edit    \n"
    "          1ed; - given history query edit    \n"
    "          ed file_name(.sql); - given file name edit   \n",    EDIT_COM        // 22
    },
    
    {
    (SChar*)
    "move ...; - move record\n",                                    MOVE_COM     // 23
    }
};

SChar * 
iSQLHelp::GetHelpString( iSQLCommandKind eHelpOption )
{
    SInt i;
    for (i=0; i<HELP_MSG_CNT; i++)
    {
        if (HelpStr[i].HelpKind == eHelpOption)
        {
            return HelpStr[i].HelpMsg; 
        }
    }

    return HelpStr[2].HelpMsg;
}

