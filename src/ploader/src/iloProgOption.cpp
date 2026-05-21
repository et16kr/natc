/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iloProgOption.cpp 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/

#include <ide.h>
#include <ilo.h>

extern SChar gszCommand[2048];
extern SChar *getpass(const SChar *prompt);

static SChar *gHelpMessage =
(SChar *)
"=====================================================================\n"
"                         ILOADER HELP Screen\n"
"=====================================================================\n"
"  Usage   : iloader [-h]\n"
"                    [-s server_name] [-u user_name] [-p password]\n"
"                    [-port port_no] [-silent] [-nst]\n"
"            -h      : This screen\n"
"            -s      : Specify server name to connect\n"
"            -u      : Specify user name to connect\n"
"            -p      : Specify password of specify user name\n"
"            -port   : Specify port number to communication\n"
"            -silent : No display Copyright\n"
"            -nst    : No display Elapsed Time\n"
"=====================================================================\n"
;

iloProgOption::iloProgOption()
{
    idlOS::strcpy(m_DBName, "database");
    idlOS::strcpy(m_NLS, "US7ASCII");
    m_PortNum = 9999;

    idlOS::strcpy(m_DefaultFieldTerm, "^");
    idlOS::strcpy(m_DefaultRowTerm, "\n");

    InitOption();
}

void iloProgOption::InitOption()
{
    m_CommandType = NON_COM;
    idlOS::strcpy(m_FieldTerm, m_DefaultFieldTerm);
    idlOS::strcpy(m_RowTerm, m_DefaultRowTerm);

    m_bExist_b = isql_false; // bad input checker
    m_bExist_T = isql_false;

    m_bExist_U = isql_false;
    m_bExist_P = isql_false;
    m_bExist_S = isql_false;
    m_bExist_Silent = isql_false;
    m_bExist_PORT = isql_false;
    m_bExist_NST = isql_false;

    m_nTableCount = 0;
    m_bExist_d = isql_false;
    m_bExist_f = isql_false;
    m_bExist_F = isql_false;
    m_bExist_L = isql_false;
    m_bExist_t = isql_false;
    m_bExist_r = isql_false;
    m_bExist_e = isql_false;

    m_bExist_mode = isql_false;
    m_LoadMode = APPEND;

    m_bExist_commit = isql_false;
    m_CommitUnit = 0;

    m_bExist_array = isql_false;
    m_ArrayCount = 0;

    m_bExist_errors = isql_false;
    m_ErrorCount = 1;

    m_bExist_log = isql_false;
    m_bExist_bad = isql_false;
    mReplication = isql_true;

    m_bExist_split = isql_false;
    m_SplitRowCount = 0;

    m_bExist_informix = isql_false;
    mInformix = isql_false;

    m_bExist_noexp = isql_false;
    mNoExp = isql_false;

    mInvalidOption = isql_false;
}

SChar *iloProgOption::MakeCommandLine(SInt argc, SChar **argv)
{
    static SChar szCommand[2048];
    SInt         i;

    szCommand[0] = '\0';
    for (i=1; i<argc; i++)
    {
    idlOS::strcat(szCommand, argv[i]);
    idlOS::strcat(szCommand, " ");
    }

    return szCommand;
}

isql_bool iloProgOption::ParsingCommandLine(SInt argc, SChar **argv)
{
    SInt len = 0;
    UChar unit;
    SInt i = 1;
    SInt j;
     
    while (i<argc)
    {
        IDE_TEST_RAISE( idlOS::strcasecmp(argv[i], "-h") == 0,
                        print_help_screen );

        if (idlOS::strcmp(argv[i], "-U") == 0 || idlOS::strcmp(argv[i], "-u") == 0)
        {
            IDE_TEST_RAISE( m_bExist_U == isql_true, err_user );
            IDE_TEST_RAISE( i+1 >= argc, err_nouser );
 
            m_bExist_U = isql_true;  
            if (argv[i+1][0] == '-')
            {
                idlOS::strcpy(m_LoginID, "");
            }
            else
            {
                strcpy(m_LoginID, argv[i+1]);
            }
                
            len = idlOS::strlen(m_LoginID);
            for (j=0; j<len; j++)
            {
                unit = ((UChar*)m_LoginID)[j];
                if (unit >= 97 && unit <=122)
                {
                    m_LoginID[j] = unit - 32;
                }
            }
            i += 2;
        }
        
        else if (idlOS::strcmp(argv[i], "-P") == 0 || idlOS::strcmp(argv[i], "-p") == 0)
        {
            IDE_TEST_RAISE( m_bExist_P == isql_true, err_passwd );
            IDE_TEST_RAISE( i+1 >= argc, err_nopasswd );

            m_bExist_P = isql_true;
            if (argv[i+1][0] == '-')
            {
                idlOS::strcpy(m_Password, "");
            }
            else         
            {
                idlOS::strcpy(m_Password, argv[i+1]);
            }
                
            /*
            len = idlOS::strlen(m_Password);
            for (j=0; j<len; j++)
            {
                unit = ((UChar*)m_Password)[j];
                if (unit >= 97 && unit <=122) m_Password[j] = unit - 32;
            }
            */
            i += 2;
        }

        else if (idlOS::strcmp(argv[i], "-S") == 0 || idlOS::strcmp(argv[i], "-s") == 0)
        {
            IDE_TEST_RAISE( m_bExist_S == isql_true, err_server );
            IDE_TEST_RAISE( i+1 >= argc, err_noserver ); 

            m_bExist_S = isql_true;
            if (argv[i+1][0] == '-')
            {
                idlOS::strcpy(m_ServerName, "");
            }
            else         
            {
                idlOS::strcpy(m_ServerName, argv[i+1]);
            }
            i += 2;
        }
        else if (idlOS::strcmp(argv[i], "-port") == 0 || idlOS::strcmp(argv[i], "-PORT") == 0)
        {
            IDE_TEST_RAISE( m_bExist_PORT == isql_true, err_port );
            IDE_TEST_RAISE( i+1 >= argc, err_noserver ); 

            m_bExist_PORT = isql_true;
            m_PortNum     = idlOS::atoi(argv[i+1]);
            i += 2;
        }
        else if (idlOS::strcmp(argv[i], "-nst") == 0 || idlOS::strcmp(argv[i], "-NST") == 0)
        {
            IDE_TEST_RAISE( m_bExist_NST == isql_true, err_nst );
            m_bExist_NST = isql_true;
            i++;
        }
        else if (idlOS::strcmp(argv[i], "-silent") == 0 || idlOS::strcmp(argv[i], "-SILENT") == 0)
        {
            IDE_TEST_RAISE( m_bExist_Silent == isql_true, err_silent );
            m_bExist_Silent = isql_true;
            i++;
        }
        else
        {
            idlOS::strcat(gszCommand, argv[i]);
            idlOS::strcat(gszCommand, " ");
            i ++;
        }
    }
    return isql_true;

    IDE_EXCEPTION( err_user );
    {
        m_bErrorExist = isql_true;
        idlOS::printf("-U 아규먼트가 중복해서 사용되었습니다.");
    }
    IDE_EXCEPTION( err_nouser );
    {
        m_bErrorExist = isql_true;
        idlOS::printf("이용자 ID가 입력되지 않았습니다.");
    }
    IDE_EXCEPTION( err_passwd );
    {
        m_bErrorExist = isql_true;
        idlOS::printf("-P 아규먼트가 중복해서 사용되었습니다.");
    }
    IDE_EXCEPTION( err_nopasswd );
    {
        m_bErrorExist = isql_true;
        idlOS::printf("이용자 비밀번호가 입력되지 않았습니다.");
    }
    IDE_EXCEPTION( err_noserver );
    {
        m_bErrorExist = isql_true;
        idlOS::printf("서버이름이 입력되지 않았습니다.");
    }
    IDE_EXCEPTION( err_server );
    {
        m_bErrorExist = isql_true;
        idlOS::printf("-S 아규먼트가 중복해서 사용되었습니다.");
    }
    IDE_EXCEPTION( err_port );
    {
        m_bErrorExist = isql_true;
        idlOS::printf("-port 아규먼트가 중복해서 사용되었습니다.");
    }
    IDE_EXCEPTION( err_nst );
    {
        m_bErrorExist = isql_true;
        idlOS::printf("-nst 아규먼트가 중복해서 사용되었습니다.");
    }
    IDE_EXCEPTION( err_silent );
    {
        m_bErrorExist = isql_true;
        idlOS::printf("-silent 아규먼트가 중복해서 사용되었습니다.");
    }
    IDE_EXCEPTION( print_help_screen );
    {
        m_bErrorExist = isql_true;
        idlOS::printf(gHelpMessage);
    }
    IDE_EXCEPTION_END;

    return isql_false;
}

isql_bool iloProgOption::ReadProgOptionInteractive( SInt *aConnType )
{
    SChar szInStr[100];
    SInt  len = 0;
    SInt  j;
    SInt  sConnType;
    UChar unit;
    SChar *sConnTypeStr = NULL;

    if (m_bExist_S == isql_false)
    {
        idlOS::printf("Write Server Name (enter:127.0.0.1) : ");
        idlOS::fflush(stdout);
        idlOS::gets(szInStr, sizeof(szInStr));
           
        m_bExist_S = isql_true;
        if (strlen(szInStr) == 0) 
        {
            idlOS::strcpy(m_ServerName, "127.0.0.1");
        }
        else
        {
            idlOS::strcpy(m_ServerName, szInStr);
        }
    }
    
    if (m_bExist_U == isql_false)
    {
        idlOS::printf("Write UserID : ");
        idlOS::fflush(stdout);
        idlOS::gets(szInStr, sizeof(szInStr));

        m_bExist_U = isql_true; 
        idlOS::strcpy(m_LoginID, szInStr);
        
        len = idlOS::strlen(m_LoginID);
        for (j=0; j<len; j++)
        {
            unit = ((UChar*)m_LoginID)[j];
            if (unit >= 97 && unit <=122)
            {
                m_LoginID[j] = unit - 32;
            }
        }
    }  

    if (m_bExist_P == isql_false)
    {        
        idlOS::strcpy(m_Password, getpass("Write Password : "));
          
        len = idlOS::strlen(m_Password);
        for (j=0; j<len; j++)
        {
            unit = ((UChar*)m_Password)[j];
            if (unit >= 97 && unit <=122)
            {
                m_Password[j] = unit - 32;
            }
        }
    }
    
    if ( idlOS::strcmp(m_ServerName, "127.0.0.1") != 0 &&
         idlOS::strcmp(m_ServerName, "localhost") != 0 )
    {
        sConnType = 1;

        if ( m_bExist_PORT == isql_false )
        {
            idlOS::printf("Write PortNo : ");
            idlOS::fflush(stdout);
            idlOS::gets(szInStr, sizeof(szInStr));

            m_bExist_PORT = isql_true;
            m_PortNum     = idlOS::atoi( szInStr );
        }
    }

    sConnTypeStr = idlOS::getenv("ISQL_CONNECTION");
    sConnType = 1;
    if ( sConnTypeStr != NULL )
    {
        if (idlOS::strncmp(sConnTypeStr, "TCP", 3) == 0)
        {
            sConnType = 1;
        }
        else if (idlOS::strncmp(sConnTypeStr, "UNIX", 4) == 0)
        {
#if !defined(VC_WIN32) && !defined(NTO_QNX)
            sConnType = 2;
#else
            sConnType = 1;
#endif
        }
        else if (idlOS::strncmp(sConnTypeStr, "IPC", 3) == 0)
        {
            sConnType = 3;
        }
    }

    *aConnType = sConnType;

    return isql_true;

}

isql_bool iloProgOption::ReadEnvironment() 
{
    UInt   sIntData;
    SChar *sCharData;

    IDE_TEST_RAISE( idp::initialize() != IDE_SUCCESS,
                    err_noprop );

    if ( m_bExist_PORT == isql_false )
    {
        IDE_TEST_RAISE( idp::read("PORT_NO", (void*)&sIntData, 0)
                != IDE_SUCCESS, not_found_port_no );
        m_PortNum = sIntData;
        m_bExist_PORT = isql_true;
    }
    IDE_TEST_RAISE( idp::readPtr("DB_NAME", (void**)&sCharData, 0)
            != IDE_SUCCESS, not_found_db_name );
    idlOS::strcpy(m_DBName, sCharData);

    IDE_TEST_RAISE( idp::readPtr("NLS_USE", (void**)&sCharData, 0)
            != IDE_SUCCESS, not_found_nls_use );
    idlOS::strcpy(m_NLS   , sCharData);

    return isql_true;

    IDE_EXCEPTION( err_noprop );
    {
        printf("[ Can't read altibase.properties file ]\n");
    }
    IDE_EXCEPTION(not_found_port_no);
    {
        printf("Property PORT_NO not found.\n");
    }
    IDE_EXCEPTION(not_found_db_name);
    {
        printf("Property DB_NAME not found.\n");
    }
    IDE_EXCEPTION(not_found_nls_use);
    {
        printf("Property NLS_USE not found.\n");
    }
    IDE_EXCEPTION_END;

    return isql_false;
}

isql_bool iloProgOption::IsValidOption()
{
    IDE_TEST_RAISE( mInvalidOption == isql_true, err_option );

    switch (m_CommandType)
    {
    case NON_COM :
        return isql_false;
    case EXIT_COM :
    case HELP_COM :
        break;
    case DATA_IN :
        IDE_TEST_RAISE( m_bExist_f == isql_false, err_form );
        IDE_TEST_RAISE( m_bExist_d == isql_false, err_data );
        IDE_TEST_RAISE( ValidTermString() == isql_false, err_term );
        IDE_TEST_RAISE( m_bExist_array == isql_true && m_ArrayCount <= 0, err_array );
        IDE_TEST_RAISE( m_bExist_split == isql_true , err_split );
        break;
    case DATA_OUT :
        IDE_TEST_RAISE( m_bExist_f == isql_false, err_form );
        IDE_TEST_RAISE( m_bExist_d == isql_false, err_data );
        IDE_TEST_RAISE( ValidTermString() == isql_false, err_term );
        break;
    case FORM_OUT :
        IDE_TEST_RAISE( m_bExist_f == isql_false, err_form );
        IDE_TEST_RAISE( m_bExist_T == isql_false, err_table );
        break;
    case STRUCT_OUT :
        IDE_TEST_RAISE( m_bExist_f == isql_false, err_form );
        IDE_TEST_RAISE( m_bExist_T == isql_false, err_table );
        break;
    default :
        break;
    }

    return isql_true;

    IDE_EXCEPTION( err_data );
    {
        m_bErrorExist = isql_true;
        idlOS::strcpy(m_ErrorMsg, "-d option(data file name) is not used "
                      "or precedence option is not correct");
    }
    IDE_EXCEPTION( err_term );
    {
        m_bErrorExist = isql_true;
        idlOS::strcpy(m_ErrorMsg, "Field Terminator, Row terminator and "
                      "Enclosingchar must be different.\n");
    }
    IDE_EXCEPTION( err_form );
    {
        m_bErrorExist = isql_true;
        idlOS::strcpy(m_ErrorMsg, "-f option(form file name) is not used "
                      "or precedence option is not correct");
    }
    IDE_EXCEPTION( err_table );
    {
        m_bErrorExist = isql_true;
        idlOS::strcpy(m_ErrorMsg, "-T option(Table name) is not used or "
                      "precedence option is not correct");
    }
    IDE_EXCEPTION( err_array );
    {
        m_bErrorExist = isql_true;
        idlOS::strcpy(m_ErrorMsg, "-array option(ArrayCount) is Invalid or "
                      "precedence option is not correct");
    }
    IDE_EXCEPTION( err_split );
    {
        m_bErrorExist = isql_true;
        idlOS::strcpy(m_ErrorMsg, "-split option(SplitRowCount) cannot be "
                      "used on IN command");
    }
    IDE_EXCEPTION( err_option );
    {
        m_bErrorExist = isql_true;
    }
    IDE_EXCEPTION_END;

    return isql_false;
}

// Return Value - invalid (-1)
//              - prompt (0)
//              - valid (1)
SInt iloProgOption::TestCommandLineOption()
{
    IDE_TEST_RAISE( mInvalidOption == isql_true, err_option );

    switch (m_CommandType)
    {
    case NON_COM :
        return 0;
    case EXIT_COM :
        return -1;
    case HELP_COM :
        return 2;
    case DATA_IN :
        IDE_TEST_RAISE( m_bExist_f == isql_false, err_form );
        IDE_TEST_RAISE( m_bExist_d == isql_false, err_data );
        IDE_TEST_RAISE( ValidTermString() == isql_false, err_term );
        IDE_TEST_RAISE( m_bExist_array == isql_true && m_ArrayCount <= 0, err_array );
        IDE_TEST_RAISE( m_bExist_split == isql_true , err_split );
        break;
    case DATA_OUT :
        IDE_TEST_RAISE( m_bExist_f == isql_false, err_form );
        IDE_TEST_RAISE( m_bExist_d == isql_false, err_data );
        IDE_TEST_RAISE( ValidTermString() == isql_false, err_term );
        break;
    case FORM_OUT :
        IDE_TEST_RAISE( m_bExist_f == isql_false, err_form );
        IDE_TEST_RAISE( m_bExist_T == isql_false, err_table );
        break;
    case STRUCT_OUT :
        IDE_TEST_RAISE( m_bExist_f == isql_false, err_form );
        IDE_TEST_RAISE( m_bExist_T == isql_false, err_table );
        break;
    default :
        break;
    }

    return 1;

    IDE_EXCEPTION( err_data );
    {
        m_bErrorExist = isql_true;
        idlOS::strcpy(m_ErrorMsg, "-d option(data file name) is not used "
                      "or precedence option is not correct");
    }
    IDE_EXCEPTION( err_term );
    {
        m_bErrorExist = isql_true;
        idlOS::strcpy(m_ErrorMsg, "Field Terminator, Row terminator and "
                      "Enclosingchar must be different.\n");
    }
    IDE_EXCEPTION( err_form );
    {
        m_bErrorExist = isql_true;
        idlOS::strcpy(m_ErrorMsg, "-f option(form file name) is not used "
                      "or precedence option is not correct");
    }
    IDE_EXCEPTION( err_table );
    {
        m_bErrorExist = isql_true;
        idlOS::strcpy(m_ErrorMsg, "-T option(Table name) is not used or "
                      "precedence option is not correct");
    }
    IDE_EXCEPTION( err_array );
    {
        m_bErrorExist = isql_true;
        idlOS::strcpy(m_ErrorMsg, "-array option(ArrayCount) is Invalid or "
                      "precedence option is not correct");
    }
    IDE_EXCEPTION( err_split );
    {
        m_bErrorExist = isql_true;
        idlOS::strcpy(m_ErrorMsg, "-split option(SplitRowCount) cannot be "
                      "used on IN command");
    }
    IDE_EXCEPTION( err_option );
    {
        m_bErrorExist = isql_true;
    }
    IDE_EXCEPTION_END;

    return -1;
}

isql_bool iloProgOption::ValidTermString()
{
    IDE_TEST( idlOS::strcmp(m_FieldTerm, m_RowTerm) == 0 );

    if (m_bExist_e)
    {
        IDE_TEST( idlOS::strcmp(m_FieldTerm, m_EnclosingChar) == 0 );
        IDE_TEST( idlOS::strcmp(m_RowTerm, m_EnclosingChar) == 0 );
    }

    return isql_true;

    IDE_EXCEPTION_END;

    return isql_false;
}

void iloProgOption::ResetError(void)
{
    m_bErrorExist = isql_false;
    m_ErrorMsg[0] = '\0';
}

