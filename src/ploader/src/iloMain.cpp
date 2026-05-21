/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iloMain.cpp 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/
 
#include <ilo.h>
#ifdef USE_READLINE
#include <histedit.h>
#endif

extern SInt gSeqIndex ;

iloProgOption       gProgOption;
iloSQLApi           gSQLApi;
iloCommandCompiler *gCommandCompiler;
iloDownLoad        *gDownLoad;
iloLoad            *gLoad;
iloFormDown        *gFormDown;
SChar               gszCommand[2048];

uttMemory          *g_memmgr;

#ifdef USE_READLINE
EditLine *gEdo;
History  *gHist;
HistEvent gEvent;
#endif

void ShowCopyRight(void);

void ShowHelpAll(ECommandType cmType);

void ShowHelpCommandOption(void);

isql_bool ConnectDB(iloSQLApi *pISPApi,
                    SChar *szHost,
                    SChar *szDB,
                    SChar *szUserID,
                    SChar *szPasswd,
                    SChar *szNLS,
                    SInt  nPort);

isql_bool ConnectDBwithUD(iloSQLApi *pISPApi,
                          SChar *szHost,
                          SChar *szDB,
                          SChar *szUserID,
                          SChar *szPasswd,
                          SChar *szNLS);

isql_bool ConnectDBforUtil(iloSQLApi *pISPApi,
                           SChar *szHost,
                           SChar *szUserID,
                           SChar *szPasswd);  

isql_bool ConnectDBwithIPC(iloSQLApi *pISPApi,
                           SChar *szHost,
                           SChar *szDB,
                           SChar *szUserID,
                           SChar *szPasswd,
                           SChar *szNLS,
                           SInt  nPort);

isql_bool DisconnectDB(iloSQLApi *pISPApi);

#ifdef USE_READLINE
char * iloprompt(EditLine *el)
{
    return "iLoader> ";
}
#endif

int main(int argc, char **argv)
{
    uttTime g_qcuTimeCheck;
    SInt    nRet;
    SInt    i;
    SInt    conn_type = 1;    // auto  1:TCP/IP 2:U/D
    
    gCommandCompiler = new iloCommandCompiler();
    gDownLoad        = new iloDownLoad();
    gLoad            = new iloLoad();
    gFormDown        = new iloFormDown();
    g_memmgr         = new uttMemory;
    
    g_memmgr->init();
    
    gszCommand[0] = '\0';
    
    IDE_TEST( gProgOption.ParsingCommandLine(argc, argv)
                    == isql_false );

    if ( gProgOption.m_bExist_Silent != isql_true )
    {
        ShowCopyRight();
    }

    if (gCommandCompiler->IsNullCommand(gszCommand) == isql_false)
    {
        gCommandCompiler->SetInputStr(gszCommand);
        IDE_TEST_RAISE( iloCommandParserparse(&gProgOption) == 1,
                        err_command2 );

        IDE_TEST_RAISE( gProgOption.ExistError() == isql_true,
                        err_command3 );
    }

    nRet = gProgOption.TestCommandLineOption();
    IDE_TEST_RAISE( nRet == -1, err_command1 );
    IDE_TEST_RAISE( nRet == 2, err_command4 );
    
    gProgOption.ReadEnvironment();
    
    IDE_TEST_RAISE( gProgOption.ReadProgOptionInteractive( &conn_type )
                    == isql_false, err_command1 );
    
    if (gProgOption.m_bExist_Silent != isql_true)
    {
        if ( conn_type == 1 )
        {
            idlOS::printf("ISQL_CONNECTION : TCP\n");
        }
        else if ( conn_type == 2 )
        {
            idlOS::printf("ISQL_CONNECTION : UNIX\n");
        }
        else if ( conn_type == 3 )
        {
            idlOS::printf("ISQL_CONNECTION : IPC\n");
        }
        idlOS::fflush(stdout);
    }

    if ( (conn_type == 2 || conn_type == 3) &&
         idlOS::strncmp(gProgOption.GetServerName(), "127.0.0.1", 9) != 0)
    {
        conn_type = 1;
    }

#if !defined(VC_WIN32) && !defined(NTO_QNX)
    if (conn_type == 1)
#else
    if (conn_type == 1 || conn_type == 2)
#endif
    {
        IDE_TEST(ConnectDB(&gSQLApi, gProgOption.GetServerName(),
                                gProgOption.GetDBName(),
                                gProgOption.GetLoginID(),
                                gProgOption.GetPassword(),
                                gProgOption.GetNLS(),
                                gProgOption.GetPortNum()) == isql_false);
    }
#if !defined(VC_WIN32) && !defined(NTO_QNX)
    else if (conn_type == 2)
    {
        IDE_TEST(ConnectDBwithUD(&gSQLApi, gProgOption.GetServerName(),
                                  gProgOption.GetDBName(),
                                  gProgOption.GetLoginID(),
                                  gProgOption.GetPassword(),
                                  gProgOption.GetNLS()) == isql_false);
    }
#endif /* !VC_WIN32 && !NTO_QNX */    
    else if (conn_type == 3)
    {
        IDE_TEST(ConnectDBwithIPC(&gSQLApi, gProgOption.GetServerName(),
                                  gProgOption.GetDBName(),
                                  gProgOption.GetLoginID(),
                                  gProgOption.GetPassword(),
                                  gProgOption.GetNLS(),
                                  gProgOption.GetPortNum()) == isql_false);
    }

    gSQLApi.AutoCommit(isql_true);
    //IDE_TEST_RAISE( gSQLApi.setQueryTimeOut( 0 ) != isql_true, err_set_timeout );

    if (nRet == isql_true) /* Command Option */
    {
        switch (gProgOption.m_CommandType)
        {
        case NON_COM :
        case HELP_COM :
        case EXIT_COM : goto exit_pos;
        case FORM_OUT : 
            gFormDown->SetProgOption(&gProgOption);
            gFormDown->SetSQLApi(&gSQLApi);
            gFormDown->FormDown();
            break;
        case STRUCT_OUT : 
            gFormDown->SetProgOption(&gProgOption);
            gFormDown->SetSQLApi(&gSQLApi);
            gFormDown->FormDownAsStruct();
            break;
        case DATA_IN  : 
            gSeqIndex = 0;
            gLoad->SetProgOption(&gProgOption);
            gLoad->SetSQLApi(&gSQLApi);
            
            if(gProgOption.m_CommitUnit == 0 )
            {
                gSQLApi.AutoCommit(isql_true);
            }
            else 
            {
                gSQLApi.AutoCommit(isql_false);
            }
            gSQLApi.alterReplication( gProgOption.mReplication );

            gLoad->LoadwithPrepare();

            if(gProgOption.m_CommitUnit > 0 )
            {
                gSQLApi.AutoCommit(isql_true);
                gProgOption.m_CommitUnit = 0;
            }
            break;
        case DATA_OUT : 
            gDownLoad->SetProgOption(&gProgOption);
            g_qcuTimeCheck.setName("     DOWNLOAD");
            g_qcuTimeCheck.start();
            gDownLoad->SetSQLApi(&gSQLApi);
            gDownLoad->DownLoad();
            g_qcuTimeCheck.finish();

            if (gProgOption.m_bExist_NST != isql_true)
            {
                g_qcuTimeCheck.show();
            }
            break;
        default :
            break;
        }
    }
    else   /* interactive Option */
    {
#ifdef USE_READLINE
        SChar *sEditor;

        sEditor = idlOS::getenv("ALTIBASE_EDITOR");
        if (sEditor == NULL)
        {
            sEditor = "emacs";
        }

        gHist = history_init();

        history(gHist, &gEvent, H_SETSIZE,100);

        gEdo = el_init(*argv, stdin, stdout, stderr);
        el_set(gEdo, EL_PROMPT, iloprompt);
        el_set(gEdo, EL_HIST, history, gHist);
        el_set(gEdo, EL_SIGNAL, 1);
        el_set(gEdo, EL_TERMINAL, NULL);
        el_set(gEdo, EL_EDITOR, sEditor);
#endif
        for (i=0; isql_true; i++)
        {
            g_memmgr->freeAll();
            if (gCommandCompiler->GetCommandString() == isql_false)
            {
                continue;
            }
            gProgOption.InitOption();  
    
            if (iloCommandParserparse(&gProgOption) == 1)
            {
                idlOS::printf("Misspelled Command or Command Option Sequence Error\n");
                idlOS::printf("Use help. iLoader> help\n");
                continue;
            }
            if (gProgOption.ExistError())
            {
                idlOS::printf("%s\n", gProgOption.GetErrorMsg());
                gProgOption.ResetError();    
                continue;
            }
    
            if (gProgOption.IsValidOption() == isql_false)
            {
                idlOS::printf("%s\n", gProgOption.GetErrorMsg());
                gProgOption.ResetError();
                continue;
            }

#ifdef _ILOADER_DEBUG
            idlOS::printf("Input Option is Valid\n");
#endif
   
            switch (gProgOption.m_CommandType)
            {
            case EXIT_COM : goto exit_pos;
            case HELP_COM :
                ShowHelpAll(gProgOption.m_HelpArgument);
                break;
            case FORM_OUT : 
                gFormDown->SetProgOption(&gProgOption);
                gFormDown->SetSQLApi(&gSQLApi);
                gFormDown->FormDown();
                break;
            case STRUCT_OUT : 
                gFormDown->SetProgOption(&gProgOption);
                gFormDown->SetSQLApi(&gSQLApi);
                gFormDown->FormDownAsStruct();
                break;
            case DATA_IN  : 
                gSeqIndex = 0;
                gLoad->SetProgOption(&gProgOption);
                gLoad->SetSQLApi(&gSQLApi);
            
                if(gProgOption.m_CommitUnit == 0 )
                {
                    gSQLApi.AutoCommit(isql_true);
                }
                else 
                {
                    gSQLApi.AutoCommit(isql_false);
                }
                gSQLApi.alterReplication( gProgOption.mReplication );
                
                gLoad->LoadwithPrepare();

                if(gProgOption.m_CommitUnit > 0 )
                {
                    gSQLApi.AutoCommit(isql_true);
                    gProgOption.m_CommitUnit = 0;
                }
                break;
            case DATA_OUT : 
                    gDownLoad->SetProgOption(&gProgOption);
                    g_qcuTimeCheck.setName("     DOWNLOAD");
                    g_qcuTimeCheck.start();
                    gDownLoad->SetSQLApi(&gSQLApi);
                    gDownLoad->DownLoad();
                    g_qcuTimeCheck.finish();
                    g_qcuTimeCheck.show();
                break;
            default :    
                break;
            }
        }
    }

exit_pos:
    DisconnectDB(&gSQLApi);

    return 0;

    IDE_EXCEPTION( err_command1 );
    {
        idlOS::printf("%s\n", gProgOption.GetErrorMsg());
    }
    IDE_EXCEPTION( err_command2 );
    {
        idlOS::printf("Misspelled Command or Command Option "
                      "Sequence Error\n");
        idlOS::printf("Use help. iLoader> help \n");
    }
    IDE_EXCEPTION( err_command3 );
    {
        idlOS::printf("%s\n", gProgOption.GetErrorMsg());
        idlOS::printf("Misspelled Command or Command Option "
                      "Sequence Error\n");
    }
    IDE_EXCEPTION( err_command4 );
    {
        ShowHelpAll(NON_COM); // call default
    }
    IDE_EXCEPTION( err_set_timeout );
    {
        idlOS::printf("Fail on set query time out\n");
    }
    IDE_EXCEPTION_END;

    return -1;
}

void ShowCopyRight(void)
{
    idlOS::printf("-----------------------------------------------------------------\n");
    idlOS::printf("     Altibase Data Load/Download utility. \n");
    idlOS::printf("     Release Version %s        \n",iduVersionString);
    idlOS::printf("     Copyright 2000, ALTIBASE Corporation or its subsidiaries.\n");
    idlOS::printf("     All Rights Reserved.         \n");
    idlOS::printf("-----------------------------------------------------------------\n");
    idlOS::fflush(stdout);
}

void ShowHelpAll(ECommandType cmType)
{
    switch(cmType)
    {
        case DATA_IN:
            idlOS::printf("Ex> in -f $formatfile -d $datafile -bad $badfile -log $logfile -e $enclosing \n");
            break;
        case DATA_OUT:
            idlOS::printf("Ex> out -f $formatfile -d $datafile \n");
            break;
        case FORM_OUT:
            idlOS::printf("Ex> formout -T $table_name -f $formatfile \n");
            break;
        case STRUCT_OUT:
            idlOS::printf("Ex> structout -T $table_name -f $filename \n");
            break;
        case EXIT_COM:
            idlOS::printf("Ex> exit (or quit) \n");
            break;
        case HELP_HELP:
            idlOS::printf("Ex> help \n");
            break;
        case HELP_COM:
            ShowHelpCommandOption();
            break;
        default:
            idlOS::printf("iloader { in | out | formout | structout | help } "
                          "[-T table_name] \n");
            idlOS::printf("        [-d datafile]         [-f formatfile] \n");
            idlOS::printf("        [-F firstrow]         [-L lastrow] \n");
            idlOS::printf("        [-t field_term]       [-r row_term] \n");
            idlOS::printf("        [-U|-u login_id]      [-P|-p password] \n");
            idlOS::printf("        [-S|-s servername]    [-mode mode_type] \n");
            idlOS::printf("        [-commit commit_unit] [-bad badfile] \n");
            idlOS::printf("        [-log logfile]        [-e enclosing] \n");
            idlOS::printf("        [-array count]        [-replication true/false] \n");
            idlOS::fflush(stdout);
    }
}

void ShowHelpCommandOption(void)
{
    idlOS::printf("{ in | out | formout | structout | help } [-T table_name] \n");
    idlOS::printf("  [-d datafile]     [-f formatfile] \n");
    idlOS::printf("  [-F firstrow]     [-L lastrow] \n");
    idlOS::printf("  [-t field_term]   [-r row_term] \n");
    idlOS::printf("  [-mode mode_type] [-commit commit_unit] \n");
    idlOS::printf("  [-bad badfile]    [-log logfile]  [-e enclosing] \n");
    idlOS::printf("  [-array count]    [-replication true/false] \n");
    idlOS::fflush(stdout);
}

isql_bool ConnectDBforUtil(iloSQLApi *pISPApi,
                           SChar *szHost,
                           SChar *szUserID,
                           SChar *szPasswd)
{
    IDE_TEST(pISPApi->OpenforUtil(szHost, szUserID, szPasswd) == isql_false);

    return isql_true;

    IDE_EXCEPTION_END;

    idlOS::printf("Connect To Server Fail\n");
    return isql_false;
}
           
isql_bool ConnectDB(iloSQLApi *pISPApi, 
                    SChar *szHost,
                    SChar *szDB, 
                    SChar *szUserID, 
                    SChar *szPasswd, 
                    SChar *szNLS,
                    SInt  nPort)
{
    IDE_TEST(pISPApi->Open(szHost, szDB, szUserID, szPasswd, szNLS, nPort)
             == isql_false);

    return isql_true;

    IDE_EXCEPTION_END;

    idlOS::printf("Connect To Server Fail\n");
    return isql_false;
}

isql_bool ConnectDBwithUD(iloSQLApi *pISPApi,
                   SChar *szHost,
                   SChar *szDB,
                   SChar *szUserID,
                   SChar *szPasswd,
                   SChar *szNLS)
{
    IDE_TEST(pISPApi->OpenWithUD(szHost, szDB, szUserID, szPasswd, szNLS)
             == isql_false);

    return isql_true;

    IDE_EXCEPTION_END;

    idlOS::printf("Connect To Server Fail\n");
    return isql_false;
}

isql_bool ConnectDBwithIPC(iloSQLApi *pISPApi,
                      SChar *szHost,
                      SChar *szDB,
                      SChar *szUserID,
                      SChar *szPasswd,
                      SChar *szNLS,
                      SInt  nPort)
{
    IDE_TEST(pISPApi->OpenWithIPC(szHost, szDB, szUserID, szPasswd, szNLS, nPort)
             == isql_false);
    return isql_true;

    IDE_EXCEPTION_END;

    idlOS::printf("Connect To Server Fail\n");
    return isql_false;
}

isql_bool DisconnectDB(iloSQLApi *pISPApi)
{
    IDE_TEST(pISPApi->Close() == isql_false);

    return isql_true;

    IDE_EXCEPTION_END;

    return isql_false;
}
