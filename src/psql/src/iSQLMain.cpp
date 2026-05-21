/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iSQLMain.cpp 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/

#include <idl.h>
#include <iduVersion.h>
#include <ideErrorMgr.h>
#include <iSQL.h>
#include <uttMemory.h>
#include <utString.h>
#include <iSQLProperty.h>
#include <iSQLProgOption.h>
#include <iSQLCompiler.h>
#include <iSQLCommand.h>
#include <iSQLCommandQueue.h>
#include <iSQLExecuteCommand.h>
#include <iSQLHostVarMgr.h>
#include <ulAmi.h>
#ifdef USE_READLINE
#include <histedit.h>
#endif

extern SInt iSQLParserparse(void *);
extern SInt iSQLPreLexerlex();

iSQLProgOption       gProgOption;
iSQLProperty         gProperty;
iSQLHostVarMgr       gHostVarMgr;
iSQLBufMgr         * gBufMgr;
iSQLCompiler       * gSQLCompiler;
iSQLCommand        * gCommand;
iSQLCommand        * gCommandTmp;
iSQLCommandQueue   * gCommandQueue;
iSQLExecuteCommand * gExecuteCommand;
iSQLSpool          * gSpool;
utString           gString;
uttMemory          * g_memmgr;

iSQLSessionKind gSessionKind = EXPLAIN_PLAN_OFF;  

SChar  * gTmpBuf; // for iSQLParserparse
idBool   g_glogin;      // $ALTIBASE_HOME/conf/glogin.sql
idBool   g_login;       // ./login.sql
idBool   g_inLoad;
idBool   g_inEdit;
idBool   gSameUser;
SChar    QUERY_LOGFILE[256];

#ifdef USE_READLINE
EditLine *gEdo;
History  *gHist;
HistEvent gEvent;
#endif

void   gSetInputStr(SChar * s);
void   ShowCopyRight(void);
IDE_RC gExecuteGlogin();
IDE_RC gExecuteLogin();
IDE_RC SaveCommandToFile(SChar * szCommand, SChar * szFile);

SInt LoadFileData(const SChar *file, UChar **buf);
void QueryLogging( const SChar *aQuery );
void InitQueryLogFile();

#ifdef USE_READLINE
char * isqlprompt(EditLine *el)
{
    return "iSQL> ";
}
#endif

SQLRETURN 
ProcedurePrintCallback( UChar * a_Message, 
                        UInt    a_length )
{
    idlOS::memcpy(gSpool->m_Buf, a_Message, a_length);
    gSpool->m_Buf[a_length] = '\0';
    gSpool->Print();
        
    return IDE_SUCCESS;
}

MESSAGE_CALLBACK_STRUCT gMessageCallbackStruct = 
{
    ProcedurePrintCallback
};

extern "C" 
{
    static void sigfunc( SInt /* signo */ )
    {
        idlOS::printf("\n");
        idlOS::signal(SIGINT, sigfunc);
        return;
    }
}
extern "C" void sigfuncSIGPIPE( SInt /* signo */ )
{
    idlOS::sprintf(gSpool->m_Buf,
                   "%s",
                   (char*)"Communication failure.\nConnection closed.\n");
    gSpool->Print();
    gExecuteCommand->DisconnectDB();
    exit(0);
}

IDE_RC connectCommand( SInt     aConnType )
{
    gExecuteCommand->ExecuteDisconnectStmt(
                gCommand->GetCommandStr(), ID_FALSE);

    IDE_TEST_RAISE( gCommand->IsSysdba() == ID_TRUE &&
                    gSameUser != ID_TRUE, sysdba_error );

    IDE_TEST_RAISE(gExecuteCommand->ExecuteConnectStmt(
                                       gCommand->GetCommandStr(), 
                                       gProgOption.GetServerName(), 
                                       gCommand->GetUserName(),
                                       gCommand->GetPasswd(),
                                       gProgOption.GetNLS(),
                                       gProgOption.GetPortNum(),
                                       (gCommand->IsSysdba() == ID_TRUE) ?
                                       5 : aConnType)
                != IDE_SUCCESS, connect_error);
    if ( gCommand->IsSysdba() == ID_TRUE )
    {
        gProgOption.setSysdba(ID_TRUE);
    }
    else
    {
        gProgOption.setSysdba(ID_FALSE);

        g_glogin = ID_TRUE;
        g_login  = ID_TRUE;
        if ( gExecuteLogin() == IDE_SUCCESS ) 
        { 
            g_login = ID_TRUE; 
        }
        else 
        {
            g_login = ID_FALSE;
        }
        if ( gExecuteGlogin() == IDE_SUCCESS ) 
        { 
            g_glogin = ID_TRUE; 
        }
        else 
        {
            g_glogin = ID_FALSE;
        }
    }
    return IDE_SUCCESS;

    IDE_EXCEPTION(sysdba_error);
    {
        idlOS::sprintf(gSpool->m_Buf, "\nTo connect to the Altibase, "
                       "you must a priveleged user who has installed it.\n"
                       "Warning: You are no longer connected to Altibase.\n");
        gSpool->Print();
    }
    IDE_EXCEPTION(connect_error);
    {
        idlOS::sprintf(gSpool->m_Buf, "\nWarning: You are no longer connected to Altibase.\n");
        gSpool->Print();
    }
    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC disconnectCommand(idBool aDisplayMode)
{
    gExecuteCommand->ExecuteDisconnectStmt(
                gCommand->GetCommandStr(), aDisplayMode);
    if ( gProgOption.IsSysdba() == ID_TRUE )
    {
        gProgOption.setSysdba(ID_FALSE);
    }
    return IDE_SUCCESS;
}

IDE_RC checkUser(SChar *aFileName)
{
    uid_t       uid;
    struct stat sBuf;
    SChar       sExFileName[256];

#ifndef VC_WIN32
    uid = idlOS::getuid();
#else
	uid = 0; //Win32's stat return uid as 0
#endif
    if ( idlOS::strcmp(aFileName, "isql") == 0 )
    {
#ifndef VC_WIN32
        idlOS::sprintf(sExFileName, "%s/bin/isql",
#else
        idlOS::sprintf(sExFileName, "%s\\bin\\isql.exe",
#endif
                       idlOS::getenv("ALTIBASE_HOME"));
    }
    else
    {
        idlOS::strcpy(sExFileName, aFileName);
    }

    IDE_TEST_RAISE( idlOS::stat(sExFileName, &sBuf) != 0,
                    stat_error );

    if ( uid == sBuf.st_uid )
    {
        gSameUser = ID_TRUE;
    }
    else
    {
        gSameUser = ID_FALSE;
    }
    return IDE_SUCCESS;

    IDE_EXCEPTION(stat_error);
    {
        idlOS::sprintf(gSpool->m_Buf, "ERROR stat(errno:%d)\n", errno);
        gSpool->Print();
    }
    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

int 
main( int     argc, 
      char ** argv )
{
    SChar  * empty; // for iSQLParserparse, but not use
    SChar    tmpFile[WORD_LEN];
    SChar    conntypeStr[10];
    SInt     conntype;   // 1: TCP/IP, 2: U/D, 3: IPC
    SInt     commandLen; // 1: TCP/IP, 2: U/D, 3: IPC
    SInt     ret;
    idBool   inChange;

    conntype = 1;
    ret      = IDE_FAILURE;
    g_inLoad = ID_FALSE;
    g_inEdit = ID_FALSE;
    inChange = ID_FALSE;
    g_glogin = ID_FALSE; // SetScriptFile에서 이값 체크 
    g_login  = ID_FALSE;
    empty    = NULL;
    gTmpBuf  = NULL;

	commandLen = gProperty.GetCommandLen();

    gBufMgr         = new iSQLBufMgr(commandLen);
    gSQLCompiler    = new iSQLCompiler();
    gCommand        = new iSQLCommand();
    gCommandTmp     = new iSQLCommand();
    gCommandQueue   = new iSQLCommandQueue();
    gExecuteCommand = new iSQLExecuteCommand(commandLen);
    gSpool          = new iSQLSpool();
    g_memmgr        = new uttMemory;

    g_memmgr->init();

    /* ============================================
     * gTmpBuf initialization 
     * ============================================ */
    if ( (gTmpBuf = (SChar*)idlOS::malloc(commandLen)) == NULL )
    {
        idlOS::fprintf(stderr, 
                "Memory allocation error!!! --- (%d, %s)\n", 
                __LINE__, __FILE__);
        exit(0);
    }
    idlOS::memset(gTmpBuf, 0x00, commandLen);

    /* ============================================
     * Signal Processing Setting 
     * Ignore ^C, ^Z, ... 
     * ============================================ */
    idlOS::signal(SIGINT, sigfunc);
    idlOS::signal(SIGPIPE, sigfuncSIGPIPE);
#ifdef _MSC_VER //BUGBUG I don't know what is needed instead of SIGTSTP
    idlOS::signal(SIGTERM, SIG_IGN);
#else
    idlOS::signal(SIGTSTP, SIG_IGN);
#endif

    /* ============================================
     * Get option with command line    
     * ============================================ */
    IDE_TEST(gProgOption.ParsingCommandLine(argc, argv) != IDE_SUCCESS);

    /* ============================================
     * If not silent option, print copyright    
     * ============================================ */
    if ( gProgOption.IsSilent() == ID_FALSE )
    {
        ShowCopyRight();
    }

    /* ============================================
     * Get option with interactive (-s, -u, -p)
     * ============================================ */
    IDE_TEST(gProgOption.ReadProgOptionInteractive() != IDE_SUCCESS);

    /* ============================================
     * Check ISQL_BUFFER_SIZE value
     * ============================================ */
    IDE_TEST_RAISE( commandLen < COMMAND_LEN, buffer_size_error );

    /* ============================================
     * Get option with altibase.properties
     * ============================================ */
    IDE_TEST(gProgOption.ReadEnvironment() != IDE_SUCCESS);


    IDE_TEST( checkUser(argv[0]) != IDE_SUCCESS );

    /* ============================================
     * Get & Set conntype 
     * ============================================ */
    idlOS::strcpy(conntypeStr, gProperty.GetConntype());
    if (idlOS::strcmp(conntypeStr, "TCP") == 0)
    {
        conntype = 1;
    }
    else if (idlOS::strcmp(conntypeStr, "UNIX") == 0)
    {
#if !defined(VC_WIN32) && !defined(NTO_QNX)
        conntype = 2;
#else
/*
        idlOS::fprintf(gProgOption.m_OutFile,
        "> QNX6.0/WIN32 cannot support UNIX Domain Socket.\
        \n> Instead of UNIX Domain Socket, Use TCP Socket!\
        \n> Maybe QNX6.2 support UNIX Domain Socket.\
        \n> And then we will support UNIX Domain Socket Method!\
        \n");
*/
        conntype = 1;
#endif
    }
    else if (idlOS::strcmp(conntypeStr, "IPC") == 0)
    {
        conntype = 3;
    }
    else
    {
        conntype = 1;
    }

    if ( gProgOption.IsSilent() == ID_FALSE )
    {
        idlOS::fprintf(gProgOption.m_OutFile, 
                       "ISQL_CONNECTION = %s, SERVER = %s, PORT_NO = %d\n",
                       conntypeStr,
                       gProgOption.GetServerName(),
                       gProgOption.GetPortNum());
    }

    /* ============================================
     * Connect to Altibase Server
     * ============================================ */
    IDE_TEST_RAISE( gProgOption.IsSysdba() == ID_TRUE &&
                    gSameUser != ID_TRUE, sysdba_error );

    IDE_TEST( gExecuteCommand->ConnectDB(gProgOption.GetServerName(),
                                        gProgOption.GetLoginID(),
                                        gProgOption.GetPassword(),
                                        gProgOption.GetNLS(),
                                        gProgOption.GetPortNum(),
                                        (gProgOption.IsSysdba() == ID_TRUE) ?
                                        5 : conntype)
            != IDE_SUCCESS );

    InitQueryLogFile();

    if ( gProgOption.IsInFile() == ID_TRUE )
    {
        /* ============================================
         * Case of -f option
         * SetFileRead   : 파일 실행이 끝나면 isql 종료하기 위해 
         * SetScriptFile : input file setting
         * ============================================ */
        gSQLCompiler->SetFileRead(ID_TRUE); 
        IDE_TEST_RAISE(gSQLCompiler->SetScriptFile(gProgOption.GetInFileName(),
                    ISQL_PATH_CWD)
                != IDE_SUCCESS, exit_pos);
    }
    else
    {
        /* ============================================
         * -f option이 아닌 경우
         * RegStdin : input file setting with stdin
         * ============================================ */
        gSQLCompiler->RegStdin();
    }

    g_glogin = ID_TRUE;
    g_login  = ID_TRUE;

    if ( gExecuteLogin() == IDE_SUCCESS ) 
    { 
        g_login = ID_TRUE; 
    }
    else 
    {
        g_login = ID_FALSE;
    }
    if ( gExecuteGlogin() == IDE_SUCCESS ) 
    { 
        g_glogin = ID_TRUE; 
    }
    else 
    {
        g_glogin = ID_FALSE;
    }

#ifdef USE_READLINE
    if ((gProgOption.IsATC() != ID_TRUE) && (gProgOption.IsInFile() != ID_TRUE))
    {
        SChar *sEditor;

        sEditor = idlOS::getenv("ALTIBASE_EDITOR");
        if (sEditor == NULL)
        {
            sEditor = "emacs";
        }

        gHist = history_init();

        history(gHist, &gEvent, H_SETSIZE,100);

        gEdo = el_init(*argv, stdin, stdout, stderr);
        el_set(gEdo, EL_PROMPT, isqlprompt);
        el_set(gEdo, EL_HIST, history, gHist);
        el_set(gEdo, EL_SIGNAL, 1);
        el_set(gEdo, EL_TERMINAL, NULL);
        el_set(gEdo, EL_EDITOR, sEditor);
    }
#endif

    while(1)
    {
        g_memmgr->freeAll();
        gBufMgr->Reset();
        gCommand->reset();
                // ISQL_COMMENT2이면 iSQL>에서 주석으로 시작하여 주석은 끝났으나 라인변경하지 않고 명령어를 이어서 사용한 경우.
                // 이 경우 프롬프트를 출력하지 않고 라인넘버ㅡ를 출력해야 함.
        if ( ret != ISQL_COMMENT2 && g_inEdit != ID_TRUE && !g_glogin && !g_login )
        {
            gSQLCompiler->PrintPrompt();
        }
        ret = iSQLPreLexerlex();
        if ( ret == ISQL_EMPTY )
        {
            continue;
        }
        else if ( ret == ISQL_COMMENT || ret == ISQL_COMMENT2 )
        {
    //        if ( gSQLCompiler->IsFileRead() == ID_TRUE )
     //       {
                gSQLCompiler->PrintCommand();
                continue;
      /*      }
            else
            {
                continue;
            }
       */ }
        else if ( ret == IDE_FAILURE )
        {
// only space
            idlOS::strcpy(gTmpBuf, gBufMgr->GetBuf());
            gString.eraseWhiteSpace(gTmpBuf); 
            if ( gTmpBuf[0] == '\n' ) 
            { 
                continue; 
            } 
        }
        else
        {
            gSetInputStr(gBufMgr->GetBuf());
        }

        gSQLCompiler->PrintCommand();
        
        ret = iSQLParserparse(empty);
        if ( ret == ISQL_UNTERMINATED )
        {
            idlOS::sprintf(gSpool->m_Buf, "[Error] Unterminated command.\n");
            gSpool->Print();
            if (gProgOption.IsInFile() ) /* 명령어가 끝나지 않고 파일이 종료한 경우 with @ */
            {
                IDE_RAISE(exit_pos);
            }
            else /* 명령어가 끝나지 않고 파일이 종료한 경우 with @ */
            {
                continue;
            }
        }
        else if ( ret == 1 )
        {
            idlOS::sprintf(gSpool->m_Buf, "Syntax error.\n");
            gSpool->Print();
            continue;
        }

        if (g_inLoad == ID_TRUE)
        {
            g_inLoad = ID_FALSE;
            gCommandQueue->AddCommand(gCommand);
            gSQLCompiler->ResetInput();
            idlOS::sprintf(gSpool->m_Buf, "Load completed.\n");
            gSpool->Print();
            continue;
        }

        if (g_inEdit == ID_TRUE)
        {
            g_inEdit = ID_FALSE;
            gCommandQueue->AddCommand(gCommand);
            gSQLCompiler->ResetInput();
            continue;
        }
/*
        if (inChange == ID_TRUE)
        {
            inChange = ID_FALSE;
            gCommandQueue->AddCommand(gCommand);
            idlOS::sprintf(gSpool->m_Buf, "%s\n", gCommand->GetCommandStr());
            gSpool->Print();
            idlOS::sprintf(gSpool->m_Buf, "Change success.\n");
            gSpool->Print();
            continue;
        }
*/
        if ( gCommand->GetCommandKind() == HISRUN_COM  || 
             gCommand->GetCommandKind() == SAVE_COM    || 
             gCommand->GetCommandKind() == LOAD_COM    || 
             gCommand->GetCommandKind() == HISTORY_COM || 
             gCommand->GetCommandKind() == EDIT_COM )
        {
            if ( gSQLCompiler->IsFileRead() == ID_TRUE )
            {
                idlOS::sprintf(gSpool->m_Buf, "The use of this command is not allowed in script file.\n");
                gSpool->Print();
                continue;
            }
        }

        if ( gCommand->GetCommandKind() == HISRUN_COM ) 
        {
            if ( gCommandQueue->GetCommand(gCommand->GetHistoryNo(), gCommand) == IDE_FAILURE )
            {
                continue;
            }
            else
            {
                gSetInputStr(gCommand->GetCommandStr());
                iSQLParserparse(empty);
            }
        }
        else if ( gCommand->GetCommandKind() == SAVE_COM )
        {
            if ( gCommandQueue->GetCommand(0, gCommandTmp) == IDE_SUCCESS )
            {
                gSQLCompiler->SaveCommandToFile(gCommandTmp->GetCommandStr(),
                                                gCommand->GetFileName(),
                                                gCommand->GetPathType());
            }
            continue;
        }
        else if ( gCommand->GetCommandKind() == LOAD_COM )
        {
            if ( gSQLCompiler->SetScriptFile(gCommand->GetFileName(),
                        gCommand->GetPathType()) == IDE_SUCCESS )
            {
                g_inLoad = ID_TRUE;
            }
            continue;
        }

        if (gSQLCompiler->IsFileRead() == ID_FALSE && 
            gCommand->GetCommandKind() != HISRUN_COM && 
            gCommand->GetCommandKind() != CHANGE_COM && 
            gCommand->GetCommandKind() != HELP_COM && 
            gCommand->GetCommandKind() != EDIT_COM && 
            gCommand->GetCommandKind() != HISEDIT_COM && 
            gCommand->GetCommandKind() != SHELL_COM && 
            gCommand->GetCommandKind() != HISTORY_COM ) // if -f option, not save in history
        {    
            gCommandQueue->AddCommand(gCommand);
        }

        switch (gCommand->GetCommandKind())
        {
        case ALTER_COM     :
        case CRT_OBJ_COM   :
        case CRT_PROC_COM  :
        case DROP_COM      :
        case GRANT_COM     :
        case LOCK_COM      :
        case RENAME_COM    :
        case REVOKE_COM    :
        case TRUNCATE_COM  :
        case SAVEPOINT_COM :
        case COMMIT_COM    :
        case ROLLBACK_COM  :
            gExecuteCommand->ExecuteDDLStmt(gCommand->GetCommandStr(), gCommand->GetQuery(), gCommand->GetCommandKind());
            break;
        case AUTOCOMMIT_COM :
            gExecuteCommand->ExecuteAutoCommitStmt(gCommand->GetCommandStr(), gCommand->GetOnOff());
            break;
        case CONNECT_COM :
            connectCommand(conntype);
            break;
        case DISCONNECT_COM :
            disconnectCommand(ID_TRUE);
            break;
        case DELETE_COM :
        case INSERT_COM :
        case UPDATE_COM :
        case MOVE_COM :        
            QueryLogging(gCommand->GetQuery());
            gExecuteCommand->ExecuteDMLStmt(gCommand->GetCommandStr(), gCommand->GetQuery(), gCommand->GetCommandKind());
            break;
        case DESC_COM :
            gExecuteCommand->DisplayAttributeList(gCommand->GetCommandStr(), 
                                                 gCommand->GetUserName(), 
                                                 gCommand->GetTableName());
            break;
        case DESC_DOLLAR_COM :
            gExecuteCommand->DisplayAttributeList4FTnPV(gCommand->GetCommandStr(), 
                                                        gCommand->GetUserName(), 
                                                        gCommand->GetTableName());
            break;
        case EXEC_FUNC_COM :
            if ( gSQLCompiler->ParsingExecProc(gCommand->GetQuery(), ID_TRUE, commandLen) == IDE_FAILURE )
                break;
            gExecuteCommand->ExecutePSMStmt(gCommand->GetCommandStr(), gCommand->GetQuery(), gCommand->GetUserName(), gCommand->GetProcName(), ID_TRUE);
            break;
        case EXEC_PROC_COM :
            if ( gSQLCompiler->ParsingExecProc(gCommand->GetQuery(), ID_FALSE, commandLen) == IDE_FAILURE )
                break;
            gExecuteCommand->ExecutePSMStmt(gCommand->GetCommandStr(), gCommand->GetQuery(), gCommand->GetUserName(), gCommand->GetProcName(), ID_FALSE);
            break;
        case EXIT_COM :
            idlOS::unlink(ISQL_BUF);
            IDE_RAISE(exit_pos);
       /* case CHANGE_COM :
            gCommandQueue->ChangeCommand(gCommand->GetChangeNo(), gCommand->GetOldStr(), gCommand->GetNewStr(), ChangeCommand);
            inChange = ID_TRUE;
            break;
        */ 
        case EDIT_COM :
            if ( idlOS::strlen(gCommand->GetFileName()) == 0 )
            {
                if ( gCommandQueue->GetCommand(0, gCommandTmp) == IDE_SUCCESS )
                {
                    gSQLCompiler->SaveCommandToFile2(gCommandTmp->GetCommandStr());
                }
                else
                {
                    break;
                }
            }
            gExecuteCommand->ExecuteEditStmt(gCommand->GetFileName(),
                                             gCommand->GetPathType(),
                                             tmpFile);
            if ( gSQLCompiler->SetScriptFile(tmpFile,
                        gCommand->GetPathType()) == IDE_SUCCESS )
            {
                g_inEdit = ID_TRUE;
            }
            break;
        case HELP_COM :
            gExecuteCommand->PrintHelpString(gCommand->GetCommandStr(), gCommand->GetHelpKind());
            break;
        case HISEDIT_COM :
            if ( gCommandQueue->GetCommand(gCommand->GetHistoryNo(), gCommandTmp) == IDE_SUCCESS )
            {
                gSQLCompiler->SaveCommandToFile2(gCommandTmp->GetCommandStr());
            }
            else
            {
                break;
            }
            gExecuteCommand->ExecuteEditStmt(gCommand->GetFileName(),
                                             gCommand->GetPathType(),
                                             tmpFile);
            if ( gSQLCompiler->SetScriptFile(tmpFile,
                        gCommand->GetPathType()) == IDE_SUCCESS )
            {
                g_inEdit = ID_TRUE;
            }
            break;
        case HISTORY_COM :
            if ( gSQLCompiler->IsFileRead() == ID_TRUE )
            {
                idlOS::sprintf(gSpool->m_Buf, "The use of this command is not allowed in script file.\n");
                gSpool->Print();
            }
            else
            {
                gCommandQueue->DisplayHistory();
            }
            break;
        case CHECK_COM :
        case OTHER_COM :
        case TRANSACTION_COM :
            QueryLogging(gCommand->GetQuery());
            gExecuteCommand->ExecuteOtherCommandStmt(gCommand->GetCommandStr(), gCommand->GetQuery());
            break;
        case PRINT_IDENT_COM :
            gExecuteCommand->ShowHostVar(gCommand->GetCommandStr(), gCommand->GetHostVarName());
            break;
        case PRINT_VAR_COM :
            gExecuteCommand->ShowHostVar(gCommand->GetCommandStr());
            break;
        case SCRIPTRUN_COM :
            gSQLCompiler->SetScriptFile(gCommand->GetFileName(),
                                        gCommand->GetPathType());
            break;
        case SELECT_COM :
            gExecuteCommand->ExecuteSelectStmt(gCommand->GetCommandStr(), gCommand->GetQuery());
            break;

        /* prepare, execute */
        case PREP_DELETE_COM :
        case PREP_INSERT_COM :
        case PREP_UPDATE_COM :
            QueryLogging(gCommand->GetQuery());
            if ( gSQLCompiler->ParsingPrepareSQL(gCommand->GetQuery(),
                                                 commandLen) == IDE_FAILURE )
            {
                break;
            }
            gExecuteCommand->PrepareDMLStmt(
                        gCommand->GetCommandStr(),
                        gCommand->GetQuery(),
                        gCommand->GetCommandKind());
            break;
        case PREP_SELECT_COM :
            if ( gSQLCompiler->ParsingPrepareSQL(gCommand->GetQuery(),
                                                 commandLen) == IDE_FAILURE )
            {
                break;
            }
            gExecuteCommand->PrepareSelectStmt(
                        gCommand->GetCommandStr(), gCommand->GetQuery());
            break;
        /* prepare, execute */

        case SET_COM :
            switch (gCommand->GetiSQLOptionKind())
            {
            case iSQL_NON       :
                gExecuteCommand->ExecuteOtherCommandStmt(gCommand->GetCommandStr(), gCommand->GetQuery());
                break;
            case iSQL_HEADING   :
                gProperty.SetHeading(gCommand->GetCommandStr(), gCommand->GetOnOff());
                break;
            case iSQL_FOREIGNKEYS   :
                gProperty.SetForeignKeys(gCommand->GetCommandStr(), gCommand->GetOnOff());
                break;
            case iSQL_PLANCOMMIT   :
                gProperty.SetPlanCommit(gCommand->GetCommandStr(), gCommand->GetOnOff());
                break;
            case iSQL_QUERYLOGGING   :
                gProperty.SetQueryLogging(gCommand->GetCommandStr(), gCommand->GetOnOff());
                break;
            case iSQL_COLSIZE  :
                gProperty.SetColSize(gCommand->GetCommandStr(), gCommand->GetColsize());
                break;
            case iSQL_LINESIZE  :
                gProperty.SetLineSize(gCommand->GetCommandStr(), gCommand->GetLinesize());
                break;
            case iSQL_PAGESIZE  :
                gProperty.SetPageSize(gCommand->GetCommandStr(), gCommand->GetPagesize());
                break;
            case iSQL_TERM    :
                gProperty.SetTerm(gCommand->GetCommandStr(), gCommand->GetOnOff());
                break;
            case iSQL_TIMING    :
                gProperty.SetTiming(gCommand->GetCommandStr(), gCommand->GetOnOff());
                break;
            case iSQL_TIMESCALE :
                gProperty.SetTimeScale(gCommand->GetCommandStr(), gCommand->GetTimescale());
                break;
            case iSQL_VERBOSE   :
                gProperty.SetVerbose(gCommand->GetCommandStr(), gCommand->GetOnOff());
                break;
            case iSQL_COMMENT   :
                gProperty.SetComment(gCommand->GetCommandStr(), gCommand->GetOnOff());
                break;
            default :
                break;
            }
            break;
        case SHELL_COM :
            gExecuteCommand->ExecuteShellStmt(gCommand->GetShellCommand());
            break;
        case SHOW_COM :
            gProperty.ShowStmt(gCommand->GetCommandStr(), gCommand->GetiSQLOptionKind());
            break;
        case SPOOL_COM :
            gExecuteCommand->ExecuteSpoolStmt(gCommand->GetFileName(),
                                              gCommand->GetPathType());
            break;
        case SPOOLOFF_COM :
            gExecuteCommand->ExecuteSpoolOffStmt();
            break;
        case TABLES_COM :
            gExecuteCommand->DisplayTableList(gCommand->GetCommandStr());
            break;
        case XTABLES_COM :
            gExecuteCommand->DisplayFixedTableList(gCommand->GetCommandStr(),
                                                   "X$",
                                                   "FIXED TABLE");
            break;
        case VTABLES_COM :
            gExecuteCommand->DisplayFixedTableList(gCommand->GetCommandStr(),
                                                   "V$",
                                                   "PERFORMANCE VIEW");
            break;
        case SEQUENCE_COM :
            gExecuteCommand->DisplaySequenceList(gCommand->GetCommandStr());
            break;
        case VAR_DEC_COM :
        case EXEC_HOST_COM :
            break;

        // admin
        case STARTUP_COM :
            if ( gProgOption.IsSysdba() == ID_TRUE )
            {
                gExecuteCommand->Startup(gCommand->GetCommandStr(),
                                         STARTUP_COM);
            }
            else
            {
                idlOS::sprintf(gSpool->m_Buf,
                        "insufficient privileges. You have to connect as sysdba\n");
                gSpool->Print();
            };
            break;
        case STARTUP_PROCESS_COM :
            if ( gProgOption.IsSysdba() == ID_TRUE )
            {
                gExecuteCommand->Startup(gCommand->GetCommandStr(),
                                         STARTUP_PROCESS_COM);
            }
            else
            {
                idlOS::sprintf(gSpool->m_Buf,
                        "insufficient privileges. You have to connect as sysdba\n");
                gSpool->Print();
            }
            break;
        case STARTUP_CONTROL_COM :
            if ( gProgOption.IsSysdba() == ID_TRUE )
            {
                gExecuteCommand->Startup(gCommand->GetCommandStr(),
                                         STARTUP_CONTROL_COM);
            }
            else
            {
                idlOS::sprintf(gSpool->m_Buf,
                        "insufficient privileges. You have to connect as sysdba\n");
                gSpool->Print();
            }
            break;
        case STARTUP_META_COM :
            if ( gProgOption.IsSysdba() == ID_TRUE )
            {
                gExecuteCommand->Startup(gCommand->GetCommandStr(),
                                         STARTUP_META_COM);
            }
            else
            {
                idlOS::sprintf(gSpool->m_Buf,
                        "insufficient privileges. You have to connect as sysdba\n");
                gSpool->Print();
            }
            break;
        case STARTUP_SERVICE_COM :
            if ( gProgOption.IsSysdba() == ID_TRUE )
            {
                gExecuteCommand->Startup(gCommand->GetCommandStr(),
                                         STARTUP_SERVICE_COM);
            }
            else
            {
                idlOS::sprintf(gSpool->m_Buf,
                        "insufficient privileges. You have to connect as sysdba\n");
                gSpool->Print();
            }
            break;

        case SHUTDOWN_NORMAL_COM :
            if ( gProgOption.IsSysdba() == ID_TRUE )
            {
                gExecuteCommand->Shutdown(gCommand->GetCommandStr(),
                                          CMD_SHUTDOWN_NORMAL);
            }
            else
            {
                idlOS::sprintf(gSpool->m_Buf,
                        "insufficient privileges. You have to connect as sysdba\n");
                gSpool->Print();
            };
            break;
        case SHUTDOWN_IMMEDIATE_COM :
            if ( gProgOption.IsSysdba() == ID_TRUE )
            {
                gExecuteCommand->Shutdown(gCommand->GetCommandStr(),
                                          CMD_SHUTDOWN_IMMEDIATE);
            }
            else
            {
                idlOS::sprintf(gSpool->m_Buf,
                        "insufficient privileges. You have to connect as sysdba\n");
                gSpool->Print();
            };
            break;
        case SHUTDOWN_ABORT_COM :
            if ( gProgOption.IsSysdba() == ID_TRUE )
            {
                gExecuteCommand->Shutdown(gCommand->GetCommandStr(),
                                          CMD_SHUTDOWN_ABORT);
            }
            else
            {
                idlOS::sprintf(gSpool->m_Buf,
                        "insufficient privileges. You have to connect as sysdba\n");
                gSpool->Print();
            };
            break;
        case SHUTDOWN_EXIT_COM :
            if ( gProgOption.IsSysdba() == ID_TRUE )
            {
                gExecuteCommand->Shutdown(gCommand->GetCommandStr(),
                                          CMD_SHUTDOWN_EXIT);
            }
            else
            {
                idlOS::sprintf(gSpool->m_Buf,
                        "insufficient privileges. You have to connect as sysdba\n");
                gSpool->Print();
            };
            break;

        // end admin
        
        default :
            break;
        }

    }

    if ( gTmpBuf != NULL )
    {
        idlOS::free(gTmpBuf);
        gTmpBuf = NULL;
    }

    return IDE_SUCCESS;

    IDE_EXCEPTION(sysdba_error);
    {
        idlOS::sprintf(gSpool->m_Buf, "\nTo connect to the Altibase, "
                       "you must a priveleged user who has installed it.\n");
        gSpool->Print();
    }
    IDE_EXCEPTION(buffer_size_error);
    {
        idlOS::sprintf(gSpool->m_Buf, "ISQL_BUFFER_SIZE must be greater than 64k.\n");
        gSpool->Print();
    }
    IDE_EXCEPTION(exit_pos);
    {
        disconnectCommand(ID_FALSE);
    }
    IDE_EXCEPTION_END;

    if ( gTmpBuf != NULL )
    {
        idlOS::free(gTmpBuf);
        gTmpBuf = NULL;
    }

    return IDE_FAILURE;
}

void 
ShowCopyRight()
{
    idlOS::fprintf(gProgOption.m_OutFile, "-----------------------------------------------------------------\n");
    idlOS::fprintf(gProgOption.m_OutFile, "     Altibase Client Query utility.\n");
    idlOS::fprintf(gProgOption.m_OutFile, "     Release Version %s\n", iduVersionString);    
    idlOS::fprintf(gProgOption.m_OutFile, "     Copyright 2000, ALTIBASE Corporation or its subsidiaries.\n");
    idlOS::fprintf(gProgOption.m_OutFile, "     All Rights Reserved.\n");
    idlOS::fprintf(gProgOption.m_OutFile, "-----------------------------------------------------------------\n");
    idlOS::fflush(gProgOption.m_OutFile);
}

IDE_RC 
gExecuteGlogin()
{
    SChar tmp[WORD_LEN];

    if ( idlOS::getenv("ALTIBASE_HOME") != NULL )
    {
        idlOS::sprintf(tmp, "%s%cconf%cglogin.sql", idlOS::getenv("ALTIBASE_HOME"),
                       IDL_FILE_SEPARATOR, IDL_FILE_SEPARATOR);
        IDE_TEST(gSQLCompiler->SetScriptFile(tmp, ISQL_PATH_CWD) != IDE_SUCCESS);
    }

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC 
gExecuteLogin()
{
    IDE_TEST(gSQLCompiler->SetScriptFile((SChar*)"login.sql",
                ISQL_PATH_CWD) != IDE_SUCCESS);

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

SInt 
LoadFileData( const SChar *  file, 
                    UChar ** buf )
{
    SInt len;
    struct stat st;
    FILE *fp;

    if ( 0 != idlOS::stat(file, &st) ) return 0;
    len = st.st_size;

    if ( (fp = isql_fopen(file, "r")) == NULL ) return 0;

    *buf = (UChar *)idlOS::malloc(len + 2);
    memset(*buf, 0, len + 2);
    len = idlOS::fread(*buf, 1, len, fp);
    if ( (*buf)[len - 1] == '\n') (*buf)[len - 1] = '\0';
    if ( (*buf)[len - 2] != ';') (*buf)[len - 1] = ';';
    (*buf)[len] = '\n';
    
    if (len <= 0) 
    {
        idlOS::fclose(fp);
        return 0;
    }
    idlOS::fclose(fp);

    return len;
}

SInt 
SaveFileData( const SChar * file, 
                    UChar * buf )
{
    SInt len;
    FILE *fp;

    if ( (fp = isql_fopen(file, "w")) == NULL ) return 0;

    len = idlOS::fwrite(buf, 1, idlOS::strlen((SChar *)buf), fp);
    idlOS::fprintf(fp, "\n");
    
    idlOS::fclose(fp);

    return len;
}

void
QueryLogging( const SChar *aQuery )
{
    FILE *fp;
    time_t timet;
    struct tm  now;

    if ( gProperty.GetQueryLogging() != ID_TRUE )
    {
        return;
    }
    if ( (fp = isql_fopen(QUERY_LOGFILE, "a")) == NULL )
    {
    //    idlOS::fprintf(stderr, "logfile open error[%s]\n", QUERY_LOGFILE);
    //    perror("open error");
        return;
    }

    idlOS::time(&timet);
    idlOS::localtime_r(&timet, &now);
    idlOS::fprintf(fp,
            "[%4"ID_UINT32_FMT
            "/%02"ID_UINT32_FMT
            "/%02"ID_UINT32_FMT 
            " %02"ID_UINT32_FMT
            ":%02"ID_UINT32_FMT
            ":%02"ID_UINT32_FMT"] ",
            now.tm_year + 1900,
            now.tm_mon + 1,
            now.tm_mday,
            now.tm_hour,
            now.tm_min,
            now.tm_sec);

    idlOS::fprintf(fp, "[%s:%d %s]", gProgOption.GetServerName(),
                       gProgOption.GetPortNum(), gProperty.GetUserName());
    idlOS::fprintf(fp, " %s\n", aQuery);
    idlOS::fflush(fp);
    idlOS::fclose(fp);
}

void InitQueryLogFile()
{
    SChar *tmp = NULL;
    tmp = getenv("ALTIBASE_HOME");

    if (tmp != NULL)
    {
        idlOS::sprintf(QUERY_LOGFILE, "%s%ctrc%cisql_query.log",
                       tmp,
                       IDL_FILE_SEPARATOR, IDL_FILE_SEPARATOR);
    }
    else
    {
        QUERY_LOGFILE[0] = 0;
    }
}
