/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iSQLAdminCommand.cpp 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/

#include <ideErrorMgr.h>
#include <utString.h>
#include <iSQLProperty.h>
#include <iSQLProgOption.h>
#include <iSQLHostVarMgr.h>
#include <iSQLHelp.h>
#include <iSQLExecuteCommand.h>
#include <iSQLCommand.h>
#include <iSQLCommandQueue.h>

extern utString                gString;
extern iSQLCommand            *gCommand;
extern iSQLCommandQueue       *gCommandQueue;
extern iSQLProperty            gProperty;
extern iSQLProgOption          gProgOption;
extern iSQLHostVarMgr          gHostVarMgr;
extern iSQLSessionKind         gSessionKind;
extern MESSAGE_CALLBACK_STRUCT gMessageCallbackStruct;

extern int SaveFileData(const char *file, UChar *data);

extern "C" void sigfuncSIGPIPE( SInt /* signo */ );

extern "C" void sigfuncSIGPIPE_shutdown( SInt /* signo */ )
{   
    idlOS::signal(SIGPIPE, sigfuncSIGPIPE);
    return;
}   

IDE_RC 
iSQLExecuteCommand::Startup(SChar * a_CommandStr,
                            SInt    aMode)
{
    switch (aMode)
    {
    case STARTUP_COM:
        idlOS::sprintf(m_Spool.m_Buf, "%s", a_CommandStr);  
        m_Spool.PrintCommand();

        IDE_TEST_RAISE(m_ISPApi->Startup() != IDE_SUCCESS, error);

        gCommand->SetQueryStr("alter database mydb service");
        IDE_TEST_RAISE(ExecuteOtherCommandStmt(
                             gCommand->GetCommandStr(),
                             gCommand->GetQuery())
                       != IDE_SUCCESS, error);
        break;

    case STARTUP_PROCESS_COM:
        IDE_TEST_RAISE(m_ISPApi->Startup() != IDE_SUCCESS, error);

        gCommand->SetQueryStr("alter database mydb process");
        IDE_TEST_RAISE(ExecuteOtherCommandStmt(
                             gCommand->GetCommandStr(),
                             gCommand->GetQuery())
                       != IDE_SUCCESS, error);
        break;

    case STARTUP_CONTROL_COM:
        IDE_TEST_RAISE(m_ISPApi->Startup() != IDE_SUCCESS, error);

        gCommand->SetQueryStr("alter database mydb control");
        IDE_TEST_RAISE(ExecuteOtherCommandStmt(
                             gCommand->GetCommandStr(),
                             gCommand->GetQuery())
                       != IDE_SUCCESS, error);
        break;

    case STARTUP_META_COM:
        IDE_TEST_RAISE(m_ISPApi->Startup() != IDE_SUCCESS, error);

        gCommand->SetQueryStr("alter database mydb meta");
        IDE_TEST_RAISE(ExecuteOtherCommandStmt(
                             gCommand->GetCommandStr(),
                             gCommand->GetQuery())
                       != IDE_SUCCESS, error);
        break;

    case STARTUP_SERVICE_COM:
        IDE_TEST_RAISE(m_ISPApi->Startup() != IDE_SUCCESS, error);

        gCommand->SetQueryStr("alter database mydb service");
        IDE_TEST_RAISE(ExecuteOtherCommandStmt(
                             gCommand->GetCommandStr(),
                             gCommand->GetQuery())
                       != IDE_SUCCESS, error);
        break;

    default:
        break;
    }

    return IDE_SUCCESS;

    IDE_EXCEPTION(error); 
    {
        idlOS::sprintf(m_Spool.m_Buf, "%s", m_ISPApi->GetErrorMsg());
        m_Spool.Print();

        if ( idlOS::strcmp(m_ISPApi->GetErrorState(), "08S01") == 0 )
        {
            DisconnectDB();
        }
    }
    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC 
iSQLExecuteCommand::Shutdown(SChar * a_CommandStr,
                             SInt    aMode)
{
    idlOS::signal(SIGPIPE, sigfuncSIGPIPE_shutdown);
    switch (aMode)
    {
    case CMD_SHUTDOWN_NORMAL:
        gCommand->SetQueryStr("alter database mydb shutdown normal");
        IDE_TEST( ExecuteSysdbaCommandStmt(gCommand->GetCommandStr(),
                                 gCommand->GetQuery()) != IDE_SUCCESS );
        break;

    case CMD_SHUTDOWN_IMMEDIATE:
        gCommand->SetQueryStr("alter database mydb shutdown immediate");
        IDE_TEST( ExecuteSysdbaCommandStmt(gCommand->GetCommandStr(),
                                 gCommand->GetQuery()) != IDE_SUCCESS );
        break;

    case CMD_SHUTDOWN_ABORT:
        idlOS::sprintf(m_Spool.m_Buf, "%s", a_CommandStr);  
        m_Spool.PrintCommand();

        IDE_TEST_RAISE(m_ISPApi->Shutdown(aMode) != IDE_SUCCESS, error);
        break;

    case CMD_SHUTDOWN_EXIT:
        gCommand->SetQueryStr("alter database mydb shutdown exit");
        IDE_TEST( ExecuteSysdbaCommandStmt(gCommand->GetCommandStr(),
                                 gCommand->GetQuery()) != IDE_SUCCESS );
        break;

    default:
        break;
    }

    m_ISPApi->Close();
    IDE_TEST( ConnectDB(gProgOption.GetServerName(),
                        gProgOption.GetLoginID(),
                        gProgOption.GetPassword(),
                        gProgOption.GetNLS(),
                        gProgOption.GetPortNum(),
                        5)
              != IDE_SUCCESS );

    idlOS::signal(SIGPIPE, sigfuncSIGPIPE);

    return IDE_SUCCESS;

    IDE_EXCEPTION(error);
    {
    }
    IDE_EXCEPTION_END;

    idlOS::sprintf(m_Spool.m_Buf, "%s", m_ISPApi->GetErrorMsg());
    m_Spool.Print();

    if ( idlOS::strcmp(m_ISPApi->GetErrorState(), "08S01") == 0 )
    {
        m_ISPApi->Close();
        ConnectDB(gProgOption.GetServerName(),
                    gProgOption.GetLoginID(),
                    gProgOption.GetPassword(),
                    gProgOption.GetNLS(),
                    gProgOption.GetPortNum(),
                    5);
    }
    idlOS::signal(SIGPIPE, sigfuncSIGPIPE);
    return IDE_FAILURE;
}

IDE_RC 
iSQLExecuteCommand::ExecuteSysdbaCommandStmt( SChar * a_CommandStr, 
                                              SChar * a_SysdbaCommandStmt )
{
    idBool sReplace = ID_FALSE;

    idlOS::sprintf(m_Spool.m_Buf, "%s", a_CommandStr);  
    m_Spool.PrintCommand();

    m_ISPApi->SetQuery(a_SysdbaCommandStmt);

    if ( gProperty.GetTiming() == ID_TRUE )
    {    
        m_uttTime.reset();
        m_uttTime.start();
    }
    
    IDE_TEST_RAISE(m_ISPApi->DirectExecute() != IDE_SUCCESS, error);

    if ( gProperty.GetTiming() == ID_TRUE )
    {    
        m_uttTime.finish();    
    }
    
    if ( a_CommandStr[idlOS::strlen(a_CommandStr) - 1] == '\n' )
    {
        sReplace = ID_TRUE;
        a_CommandStr[idlOS::strlen(a_CommandStr) - 1] = 0;
    }
    idlOS::sprintf(m_Spool.m_Buf, "%s success.\n", a_CommandStr);
    m_Spool.Print();

    if ( sReplace == ID_TRUE )
    {
        a_CommandStr[idlOS::strlen(a_CommandStr) - 1] = '\n';
    }
    
    if ( gProperty.GetTiming() == ID_TRUE )
    {    
        ShowElapsedTime();
    }

    m_ISPApi->StmtClose();

    return IDE_SUCCESS;

    IDE_EXCEPTION(error);
    {
        /*
        idlOS::sprintf(m_Spool.m_Buf, "%s", m_ISPApi->GetErrorMsg());
        m_Spool.Print();

        if ( idlOS::strcmp(m_ISPApi->GetErrorState(), "08S01") == 0 )
        {
            DisconnectDB();
        }
        */
    }

    IDE_EXCEPTION_END;

    m_ISPApi->StmtClose();

    return IDE_FAILURE;
}
