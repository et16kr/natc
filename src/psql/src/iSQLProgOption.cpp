/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iSQLProgOption.cpp 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/

#include <idp.h>
#include <ideErrorMgr.h>
#include <utString.h>
#include <iSQLCommand.h>
#include <iSQLExecuteCommand.h>
#include <iSQLProperty.h>
#include <iSQLProgOption.h>
#include <iSQLCompiler.h>

extern utString           gString;
extern iSQLProperty        gProperty;
extern iSQLCommand        *gCommand;
extern iSQLExecuteCommand *gExecuteCommand;
extern iSQLCompiler       *gSQLCompiler;
extern SChar *getpass(const SChar *prompt);

static SChar *HelpMessage =
(SChar *)
"===================================================================== \n"
"                         ISQL HELP Screen                             \n" 
"===================================================================== \n"
"  Usage   : isql [-h]                                                 \n"
"                 [-s server_name] [-u user_name] [-p password]        \n"
"                 [-port port_no] [-silent] [-v]                       \n"
"                 [-f in_file_name] [-o out_file_name]               \n\n"               
"            -h  : This screen\n"
"            -s  : Specify server name to connect\n"
"            -u  : Specify user name to connect\n"       
"            -p  : Specify password of specify user name\n"
"            -port : Specify port number to communication\n"
"            -f  : Specify script file to process\n"
"            -o  : Specify file to save result\n"       
"            -v  : Print command once more\n"
"            -silent : No display Copyright\n"
"===================================================================== \n"
;

iSQLProgOption::iSQLProgOption()
{
    m_bExist_U        = ID_FALSE;
    m_bExist_P        = ID_FALSE;
    m_bExist_S        = ID_FALSE;
    m_bExist_F        = ID_FALSE;
    m_bExist_O        = ID_FALSE;
    m_bExist_V        = ID_FALSE; /* verbose mode */
    m_bExist_SILENT   = ID_FALSE; /* silent mode */
    m_bExist_PORT     = ID_FALSE;
    m_bExist_ATC      = ID_FALSE;
    m_bExist_SYSDBA   = ID_FALSE;

    m_OutFile = stdout;
}

IDE_RC 
iSQLProgOption::ParsingCommandLine( SInt     argc, 
                                    SChar ** argv )
{
    SInt  i;

    for (i=1; i<argc; i+=2)
    {
        IDE_TEST_RAISE(idlOS::strcasecmp(argv[i], "-h") == 0,
                       print_help_screen);
        
        if (idlOS::strcasecmp(argv[i], "-u") == 0)
        {
            // userid가 없는 경우
            IDE_TEST_RAISE(argc <= i+1, print_help_screen);
            IDE_TEST_RAISE(idlOS::strncmp(argv[i+1], "-", 1) == 0,
                           print_help_screen);

            m_bExist_U = ID_TRUE;
            idlOS::strcpy(m_LoginID, argv[i+1]);

            gString.toUpper(m_LoginID);

            gProperty.SetUserName(m_LoginID);
            gCommand->SetUserName(m_LoginID);
        }
        else if (idlOS::strcasecmp(argv[i], "-p") == 0)
        {
            // passwd가 없는 경우
            IDE_TEST_RAISE(argc <= i+1, print_help_screen);
            IDE_TEST_RAISE(idlOS::strncmp(argv[i+1], "-", 1) == 0,
                           print_help_screen);

            m_bExist_P = ID_TRUE;
            idlOS::strcpy(m_Password, argv[i+1]);

            //gString.toUpper(m_Password);
        }
        else if (idlOS::strcasecmp(argv[i], "-s") == 0)
        {
            // servername이 없는 경우
            IDE_TEST_RAISE(argc <= i+1, print_help_screen);
            IDE_TEST_RAISE(idlOS::strncmp(argv[i+1], "-", 1) == 0,
                           print_help_screen);

            m_bExist_S = ID_TRUE;
            idlOS::strcpy(m_ServerName, argv[i+1]);
        }
        else if (idlOS::strcasecmp(argv[i], "-port") == 0)
        {
            // portno가 없는 경우
            IDE_TEST_RAISE(argc <= i+1, print_help_screen);
            IDE_TEST_RAISE(idlOS::strncmp(argv[i+1], "-", 1) == 0,
                           print_help_screen);

            m_bExist_PORT     = ID_TRUE;
            m_PortNum         =  atoi(argv[i+1]);
        }
        else if (idlOS::strcasecmp(argv[i], "-f") == 0)
        {
            // scriptfile이 없는 경우
            IDE_TEST_RAISE(argc <= i+1, print_help_screen);
            IDE_TEST_RAISE(idlOS::strncmp(argv[i+1], "-", 1) == 0,
                           print_help_screen);

            m_bExist_F = ID_TRUE;
            idlOS::strcpy(m_InFileName, argv[i+1]);
        }
        else if (idlOS::strcasecmp(argv[i], "-o") == 0)
        {
            // outfile이 없는 경우
            IDE_TEST_RAISE(argc <= i+1, print_help_screen);
            IDE_TEST_RAISE(idlOS::strncmp(argv[i+1], "-", 1) == 0,
                           print_help_screen);

            m_OutFile = isql_fopen(argv[i+1], "w");
            IDE_TEST_RAISE(m_OutFile == NULL, fail_open_file);

            m_bExist_O = ID_TRUE;
        }
        else if (idlOS::strcasecmp(argv[i], "-v") == 0)
        {
            m_bExist_V = ID_TRUE;
            i--;
        }
        else if (idlOS::strcasecmp(argv[i], "-silent") == 0)
        {
            m_bExist_SILENT = ID_TRUE;
            i--;
        }
        else if (idlOS::strcasecmp(argv[i], "-atc") == 0)
        {
            gSQLCompiler->SetPrompt(ID_TRUE);
            m_bExist_ATC = ID_TRUE;
            i--;
        }
        else if (idlOS::strcasecmp(argv[i], "-sysdba") == 0)
        {
            m_bExist_SYSDBA = ID_TRUE;
            i--;
        }
        else 
        {
            IDE_RAISE(print_help_screen);
        }
    }

    return IDE_SUCCESS;

    IDE_EXCEPTION(fail_open_file);
    {
        idlOS::fprintf(stderr, "Error : Can not open file. [%s]\n", argv[i+1]);
    }
    IDE_EXCEPTION(print_help_screen);
    {
        idlOS::fprintf(m_OutFile, HelpMessage);
    }
    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC 
iSQLProgOption::ReadProgOptionInteractive()
{
    SChar szInStr[WORD_LEN];

    if (m_bExist_S == ID_FALSE)
    {
        idlOS::printf("Write Server Name (default:127.0.0.1) : ");
        idlOS::fflush(stdout);
        idlOS::gets(szInStr, WORD_LEN);

        m_bExist_S = ID_TRUE;
        if (idlOS::strlen(szInStr) == 0)
        {
          idlOS::strcpy(m_ServerName, "127.0.0.1");
        }
        else
        {
          idlOS::strcpy(m_ServerName, szInStr);
        }
    }

    if (m_bExist_U == ID_FALSE)
    {
        idlOS::printf("Write UserID : ");
        idlOS::fflush(stdout);
        idlOS::gets(szInStr, WORD_LEN);

        m_bExist_U = ID_TRUE;
        idlOS::strcpy(m_LoginID, szInStr);

        gString.toUpper(m_LoginID);

        gProperty.SetUserName(m_LoginID);
        gCommand->SetUserName(m_LoginID);
    }
    
    if (m_bExist_P == ID_FALSE)
    {
        strcpy(m_Password, getpass("Write Password : "));
        m_bExist_P = ID_TRUE;
        
        gString.toUpper(m_Password);
    }

    if (idlOS::strcmp(gProperty.GetConntype(), "TCP") == 0)
    {
        m_Conntype = 1;
    }
    else if (idlOS::strcmp(gProperty.GetConntype(), "UNIX") == 0)
    {
#if !defined(VC_WIN32) && !defined(NTO_QNX)
        m_Conntype = 2;
#else
/*
        idlOS::fprintf(gProgOption.m_OutFile,
        "> QNX6.0/WIN32 cannot support UNIX Domain Socket.\
        \n> Instead of UNIX Domain Socket, Use TCP Socket!\
        \n> Maybe QNX6.2 support UNIX Domain Socket.\
        \n> And then we will support UNIX Domain Socket Method!\
        \n");
*/
        m_Conntype = 1;
#endif
    }
    else if (idlOS::strcmp(gProperty.GetConntype(), "IPC") == 0)
    {
        m_Conntype = 3;
    }
    else
    {
        m_Conntype = 1;
    }

    if ( idlOS::strcmp(m_ServerName, "127.0.0.1") != 0 &&
         idlOS::strcmp(m_ServerName, "localhost") != 0 )
    {
        IDE_TEST_RAISE(m_Conntype == 2 || m_Conntype == 3, error);

        if ( m_bExist_PORT == ID_FALSE )
        {
            idlOS::printf("Write PortNo : ");
            idlOS::fflush(stdout);
            idlOS::gets(szInStr, WORD_LEN);

            m_bExist_PORT = ID_TRUE;
            m_PortNum     = atoi(szInStr);
        }
    }

    return IDE_SUCCESS;

    IDE_EXCEPTION(error);
    {
        idlOS::fprintf(stderr, "Error : ISQL_CONNECTION must be TCP "
                       "when Altibase server is remote.\n");
    }
    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC 
iSQLProgOption::ReadEnvironment()
{
    SChar *sCharData;
    UInt   sIntData;

    IDE_TEST_RAISE(idp::initialize() != IDE_SUCCESS,
                   not_found_property_file);

    IDE_TEST_RAISE( idp::read("PORT_NO", (void*)&sIntData, 0)
            != IDE_SUCCESS, not_found_port_no );

    if (m_bExist_PORT == ID_FALSE)
    {
        m_PortNum     = sIntData;
        m_bExist_PORT = ID_TRUE;
    }

    IDE_TEST_RAISE( idp::readPtr("NLS_USE", (void**)&sCharData, 0)
                != IDE_SUCCESS, not_found_nls_use );

    idlOS::strcpy(m_NLS, sCharData);

    return IDE_SUCCESS;

    IDE_EXCEPTION(not_found_property_file);
    {
        idlOS::fprintf(m_OutFile, idp::getErrorBuf());
    }
    IDE_EXCEPTION(not_found_port_no);
    {
        idlOS::fprintf(m_OutFile, "Property PORT_NO not found.\n");
    }
    IDE_EXCEPTION(not_found_nls_use);
    {
        idlOS::fprintf(m_OutFile, "Property NLS_USE not found.\n");
    }
    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

