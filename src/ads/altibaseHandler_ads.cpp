/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: altibaseHandler_ads.cpp 1594 2008-03-21 06:11:41Z orc $
 **********************************************************************/

#include "altibaseHandler_ads.h"
#include <stdlib.h>

#define MAX_SYSDBA_RETRY 3
#define MAX_USER_RETRY   1
#define SLEEP_TIMEOUT    1

//fix BUG-20120
#if defined(STAF_OS_NAME_WIN32)
int errno;
#endif

DBHandler::DBHandler( AdsServicer  *aServicer )
{
    mServicer = aServicer;
}

IDE_RC
DBHandler::initialize()
{
    pid = 0;
    isql_i = NULL;
    isql_o = NULL;
    isql_i_fd = 0;

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC
DBHandler::destroy()
{
    logout();

    return IDE_SUCCESS;
}

IDE_RC
DBHandler::logon( SChar *aDsn,
                        SChar *aUser,
                        SChar *aPasswd,
                        SChar *aNls,
                        SInt   aPort,
                        SChar *aConntype )
{
#if defined(STAF_OS_NAME_WIN32)
    char   sPath[1024];
    HANDLE fds_i[2];
    HANDLE fds_o[2];
    int    sRs;

    (void)logout();

    SECURITY_ATTRIBUTES sa;   
    sa.nLength                  = sizeof( SECURITY_ATTRIBUTES );   
    sa.bInheritHandle           = TRUE;   
    sa.lpSecurityDescriptor     = NULL;  

    PROCESS_INFORMATION piProcInfo; 
    STARTUPINFO siStartInfo;

    memset( &piProcInfo, 0, sizeof(piProcInfo) );
    memset( &siStartInfo, 0, sizeof(siStartInfo) );

    if( ::CreatePipe( &fds_i[0], &fds_i[1], &sa, 0 ) == 0 )
    {
        IDE_RAISE( error );
    }

    if( ::CreatePipe( &fds_o[0], &fds_o[1], &sa, 0 ) == 0 )
    {
        IDE_RAISE( error );
    }
        
    isql_i = fds_i[0];
    isql_o = fds_o[1];

    siStartInfo.cb = sizeof(STARTUPINFO); 
    siStartInfo.hStdError = GetStdHandle(STD_ERROR_HANDLE);
    siStartInfo.hStdOutput = fds_i[1];
    siStartInfo.hStdInput = fds_o[0];
    siStartInfo.dwFlags |= STARTF_USESTDHANDLES;

    sprintf( sPath, 
             "%s/bin/isql.exe -silent -u %s -p %s -port %d -s %s -nls_use %s -ataf", 
             getenv("ALTIBASE_HOME"),
             aUser,
             aPasswd,
             aPort,
             aDsn,
             aNls );

    (void)AdsServiceManager::lock();

	switch( aConntype[0] )
    {
        case 'T':
           putenv( "ISQL_CONNECTION=TCP" );
           break;
        case 'U':
           putenv( "ISQL_CONNECTION=UNIX" );
           break;
        case 'I':
           putenv( "ISQL_CONNECTION=IPC" );
           break;
    }

    sRs = CreateProcess( NULL, 
                         sPath,        // command line 
                         NULL,         // process security attributes 
                         NULL,         // primary thread security attributes 
                         TRUE,         // handles are inherited 
                         0,            // creation flags 
                         NULL,         // use parent's environment 
                         NULL,         // use parent's current directory 
                         &siStartInfo, // STARTUPINFO pointer 
                         &piProcInfo); // receives PROCESS_INFORMATION  

    (void)AdsServiceManager::unlock();

    if( sRs == 0 )
    {
        fprintf( stderr, "execl error: %d\n", errno );
        exit(-1);
    }

    pid = piProcInfo.hProcess;

    CloseHandle( fds_i[1] );
    CloseHandle( fds_o[0] );
#else
    int fds_i[2];
    int fds_o[2];

    (void)logout();

    if( pipe( fds_i ) < 0 )
    {
        IDE_RAISE( error );
    }

    if( pipe( fds_o ) < 0 )
    {
        IDE_RAISE( error );
    }

    pid = fork();

    if( pid < 0 )
    {
        fprintf( stderr, "fork error: %d\n", errno );
        IDE_RAISE( error );
    }

    if( pid > 0 ) // parent
    {
        isql_i = fdopen( fds_i[0], "r" );
        isql_i_fd = fds_i[0];
        close( fds_i[1] );

        if( isql_i == NULL )
        {
            fprintf( stderr, "fdopen error1: %d\n", errno );
            IDE_RAISE( error );
        }

        isql_o = fdopen( fds_o[1], "w" );
        close( fds_o[0] );

        if( isql_o == NULL )
        {
            fprintf( stderr, "fdopen error2: %d\n", errno );
            IDE_RAISE( error );
        }
    }
    else // child
    {
        dup2( fds_i[1], STDOUT_FILENO );
        dup2( fds_o[0], STDIN_FILENO );

        char sPath[1024];
        char sPort[128];

#ifdef VC_WIN32
        sprintf( sPath,
                        "%s/bin/isql.exe",
                        getenv("ALTIBASE_HOME") );
#else
        sprintf( sPath,
                        "%s/bin/isql",
                        getenv("ALTIBASE_HOME") );
#endif

        sprintf( sPort,
                        "%d", aPort );
        char * sArgs[14];

        sArgs[0] = sPath;
        sArgs[1] = "-silent";
        sArgs[2] = "-u";
        sArgs[3] = aUser;
        sArgs[4] = "-p";
        sArgs[5] = aPasswd;
        sArgs[6] = "-port";
        sArgs[7] = sPort;
        sArgs[8] = "-s";
        sArgs[9] = aDsn;
        sArgs[10] = "-nls_use";
        sArgs[11] = aNls;
        sArgs[12] = "-ataf";
        sArgs[13] = 0;

        switch( aConntype[0] )
        {
           case 'T':
               putenv( "ISQL_CONNECTION=TCP" );
               break;
           case 'U':
               putenv( "ISQL_CONNECTION=UNIX" );
               break;
          case 'I':
               putenv( "ISQL_CONNECTION=IPC" );
               break;
        }

         int rs = execv( sPath,
                         sArgs );

         if( rs < 0 )
         {
            fprintf( stderr, "execl error: %d\n", errno );
            exit(-1);
         }
    }
#endif

    IDE_TEST_RAISE( ping() != 1, error );

    mServicer->setResponseMsg( mResultString );
    mServicer->setErrorCode( kSTAFOk  );

    return IDE_SUCCESS;

    IDE_EXCEPTION( error );
    IDE_EXCEPTION_END;

    mServicer->setResponseMsg( mResultString );
    mServicer->setErrorCode( kSTAFUnknownError  );

    return IDE_FAILURE;
/*
    SQLRETURN sError;
    SInt      sConntype = 0;

    if( idlOS::strcmp( aConntype, "TCP" ) == 0 )
    {
        sConntype = 1;
    }
    else if( idlOS::strcmp( aConntype, "UNIX" ) == 0 )
    {
        sConntype = 2;
    }
    else if( idlOS::strcmp( aConntype, "IPC" ) == 0 )
    {
        sConntype = 3;
    }
    else
    {
        // error msg
    }

    sError = connectDB( aDsn,
                        aUser,
                        aPasswd,
                        aNls,
                        aPort,
                        sConntype );

    return (IDE_RC)sError;
*/
}

IDE_RC
DBHandler::logout()
{
    // 데이터베이스 접속 해제
    disconnectDB();

    return IDE_SUCCESS;
}

IDE_RC
DBHandler::execute( SChar* aBuffer, CommandKind aCommandKind )
{
#if defined(STAF_OS_NAME_WIN32)
	SChar sBuffer[65536 * 2];
    SInt sSize;
    SInt  sRs;

    SInt sLine = 0;
    SInt sWords = 0;
    SInt sError = 0;

    sSize = strlen( aBuffer );

    if( aBuffer[sSize-1] !=  ';' )
    {
        sprintf( sBuffer, "%s;\n", aBuffer );
    }
    else
    {
        sprintf( sBuffer, "%s\n", aBuffer );
    }

    mQueryString = sBuffer;

    mResultString = "";

    //cout << mQueryString;

	DWORD sByte = strlen(sBuffer);
	if( WriteFile( isql_o, 
                   sBuffer, 
                   sByte, 
                   &sByte, 
                   NULL ) == FALSE )
    {
        // Broken pipe, fix BUG-20120
        if( (errno == ERROR_NO_DATA) || (errno == ERROR_BROKEN_PIPE) )
        {
            mResultString = "[ERR-91020 : No Connection State]\n";
        }
        else
        {
            fprintf( stderr, "fwrite error: %d\n", errno );
        }
    }
    else
    {
        fflush( NULL );

        sRs = WaitForSingleObject( isql_i, 300 * 1000L );

        if( sRs < 0 )
        {
            //error
        }
        else if( sRs == 0 )
        {
            //timeout
        }
        else
        {
            while( 1 )
            {
                sLine++;   
                if( _fgets( sBuffer, sizeof(sBuffer), &isql_i ) <= 0 )
                {
                    // Broken pipe, fix BUG-20120
                    if( (errno == ERROR_NO_DATA) || (errno == ERROR_BROKEN_PIPE))
                    {
                        mResultString = "[ERR-91020 : No Connection State]\n";
                    }
                    else
                    {
                        fprintf( stderr, "fwrite error2: %d\n", errno );
                    }
                    break;
                }
                else
                {
                    if( strstr( sBuffer, "$$EOF$$" ) != NULL )
                    {
                        break;
                    }
                    else
                    {
                        if( aCommandKind == QUERY_SELECT )
                        {
                            if( sLine == 1 && strstr( sBuffer, "[ERR-" ) != NULL )
                            {
                                sError = 1;
                            }
                            
                            if( sError == 1 )
                            {
                                mResultString += sBuffer;
                            }
                            else
                            { 
                                if( sLine >= 3 )
                                {
                                    if( strstr( sBuffer, "selected" ) != NULL )
                                    {
                                        continue;
                                    }

                                    sWords = STAFString( sBuffer ).numWords();

                                    if( sWords == 0 )
                                    {
                                        continue;
                                    }
                                
                                    for( int i = 0; i < sWords; i++ )
                                    {
                                        mResultString += STAFString( sBuffer ).subWord( i, 1 ) + "|";
                                    } 
                                    mResultString += "\n";
                                }
                            }
                        }
                        else
                        {          
                            mResultString += sBuffer;

                            if( strstr( sBuffer, "ERR-91015" ) != NULL )
                            {
                                break;
                            }
                        }
                        //fprintf( stderr, "%s", sBuffer );
                    }
                }
            }
        }
    }
#else
    SChar sBuffer[65536 * 2];
    SInt sSize;
    fd_set sRset;
    SInt  sRs;
    struct timeval sTimeout;
    SInt sLine = 0;
    SInt sWords = 0;
    SInt sError = 0;

    FD_ZERO( &sRset );
    FD_SET( isql_i_fd, &sRset );

    sTimeout.tv_sec = 300;
    sTimeout.tv_usec = 0;

    sSize = strlen( aBuffer );

    if( aBuffer[sSize-1] !=  ';' )
    {
        sprintf( sBuffer, "%s;\n", aBuffer );
    }
    else
    {
        sprintf( sBuffer, "%s\n", aBuffer );
    }

    mQueryString = sBuffer;

    mResultString = "";

    //cout << mQueryString;

    if( fwrite( sBuffer,
                       strlen(sBuffer),
                       1,
                       isql_o ) < 0 )
    {
        fprintf( stderr, "fwrite error: %d\n", errno );
        // Broken pipe
        if( (errno == 32) || (errno == 29) )
        {
            mResultString = "[ERR-91020 : No Connection State]\n";
        }
    }
    else
    {
        fflush( isql_o );

        sRs = select( isql_i_fd + 1, &sRset, NULL, NULL, &sTimeout );

        if( sRs < 0 )
        {
            //error
        }
       else if( sRs == 0 )
        {
            //timeout
        }
        else
        {
            while( 1 )
            {
                sLine++;   
                if( fgets( sBuffer, sizeof(sBuffer), isql_i ) <= 0 )
                {
                    fprintf( stderr, "fgets error: %d\n", errno );
                    // Broken pipe
                    if( (errno == 32) || (errno == 29) )
                    {
                        mResultString = "[ERR-91020 : No Connection State]\n";
                    }
                    break;
                }
                else
                {
                    if( strstr( sBuffer, "$$EOF$$" ) != NULL )
                    {
                        break;
                    }
                    else
                    {
                        if( aCommandKind == QUERY_SELECT )
                        {
                            if( sLine == 1 && strstr( sBuffer, "[ERR-" ) != NULL )
                            {
                                sError = 1;
                            }
                            
                            if( sError == 1 )
                            {
                                mResultString += sBuffer;
                            }
                            else
                            { 
                                if( sLine >= 3 )
                                {
                                    if( strstr( sBuffer, "selected" ) != NULL )
                                    {
                                        continue;
                                    }

                                    sWords = STAFString( sBuffer ).numWords();

                                    if( sWords == 0 )
                                    {
                                        continue;
                                    }
                                
                                    for( int i = 0; i < sWords; i++ )
                                    {
                                        mResultString += STAFString( sBuffer ).subWord( i, 1 ) + "|";
                                    } 
                                    mResultString += "\n";
                                }
                            }
                        }
                        else
                        {          
                            mResultString += sBuffer;

                            if( strstr( sBuffer, "ERR-91015" ) != NULL )
                            {
                                break;
                            }
                        }
                        //fprintf( stderr, "%s", sBuffer );
                    }
                }
            }
        }
    }
#endif
    mResultString = mResultString.subString( 0, mResultString.length() - 1 );

    //cout << mResultString << endl;

    if( strstr( mResultString.buffer(), "[ERR-" ) == NULL )
    {
        mServicer->setResponseMsg( mResultString );
        mServicer->setErrorCode( kSTAFOk );
    }
    else
    {
        mServicer->setResponseMsg( mResultString );
        mServicer->setErrorCode( kSTAFUnknownError );
    }

    return IDE_SUCCESS;
/*
    switch ( aCommandKind )
    {
        case QUERY_INSERT:
        case QUERY_UPDATE:
        case QUERY_DELETE:
            executeDMLStmt( aBuffer, aCommandKind );
            break;
        case QUERY_EXECUTE:
            if ( parsingExecProc( aBuffer, ID_FALSE, idlOS::strlen( aBuffer ) + 1 ) == IDE_FAILURE )
                break;
            executePSMStmt( aBuffer, mUserName, mProcName, ID_FALSE);
            break;
        case QUERY_SELECT:
            executeSelectStmt( aBuffer );
            break;
    }

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
*/
}

IDE_RC
DBHandler::executeDMLStmt( SChar* aDMLStmt, CommandKind aCommandKind )
{
/*
    SQLLEN sCnt = 0;

    idlOS::sprintf ( mStringBuffer, "ADS> %s\n", aDMLStmt );
    mQueryString = STAFString( mStringBuffer );

    mISPApi.SetQuery( aDMLStmt );

    IDE_TEST_RAISE(mISPApi.DirectExecute() != IDE_SUCCESS, error);

    IDE_TEST_RAISE(mISPApi.GetRowCount(&sCnt, ID_FALSE) != IDE_SUCCESS, error);

    if ( sCnt == 0)
    {
        idlOS::sprintf( mStringBuffer, "No rows " );
    }
    else if ( sCnt == 1)
    {
        idlOS::sprintf( mStringBuffer, "1 row " );
    }
    else
    {
        idlOS::sprintf( mStringBuffer, "%d rows ", (SInt)sCnt );
    }
    mResultString += STAFString( mStringBuffer );

    switch( aCommandKind )
    {
        case QUERY_INSERT:
            idlOS::sprintf ( mStringBuffer, "inserted." );
            break;
        case QUERY_UPDATE:
            idlOS::sprintf ( mStringBuffer, "updated." );
            break;
        case QUERY_DELETE:
            idlOS::sprintf ( mStringBuffer, "deleted." );
            break;
        default:
            break;
    }
    mResultString += STAFString( mStringBuffer );

    // Response
    mServicer->setResponseMsg( STAFString( (SInt)sCnt ) );
    mServicer->setErrorCode( kSTAFOk  );

    mISPApi.StmtClose(ID_FALSE);

    return IDE_SUCCESS;

    IDE_EXCEPTION(error);
    {
        uteSprintfErrorCode(mErrorBuffer, MSG_LEN, &mErrorMgr);
        mResultString += STAFString( mErrorBuffer );

        if ( mResultString.subString( mResultString.length() - 1, 1 ) == "\n" )
        {
            mResultString= mResultString.subString( 0, mResultString.length() - 1 );
        }

        // Response
        mServicer->setResponseMsg( mResultString );
        mServicer->setErrorCode( kSTAFUnknownError );

        // Comm_Failure_Error
        if ( idlOS::strcmp(mISPApi.GetErrorState(), "08S01") == 0 )
        {
            disconnectDB();
        }
    }
    IDE_EXCEPTION_END;

    mISPApi.StmtClose(ID_FALSE);

    return IDE_FAILURE;
*/
    return IDE_SUCCESS;
}

IDE_RC
DBHandler::parsingExecProc( SChar * aBuf,
                                  idBool  aIsFunc,
                                  SInt    aBufSize )
{
/*
    // for execute procedure/function
    SChar *sTempBuf;
    SChar *sPos;
    SChar *sPos1;
    SChar *sPos2;
    SChar *sBeginPos;

    SInt   sLen;
    SInt   sOrder      = 1;
    SInt   sParaOrder = 1;
    SInt   sBraceCnt  = 0;
    idBool sIsIsInString   = ID_FALSE;

    if ( (sTempBuf = (SChar*)idlOS::malloc( aBufSize )) == NULL )
    {
        idlOS::fprintf(stderr, "Memory allocation error!!! --- (%d, %s)\n", __LINE__, __FILE__);
        exit(0);
    }
    idlOS::memset(sTempBuf, 0x00, aBufSize);

    idlOS::strcpy(sTempBuf, aBuf);
    mString.eraseWhiteSpace(sTempBuf);

    mSymbol->initBindList();

    if ( aIsFunc == ID_TRUE )
    {
        sPos1 = idlOS::strchr(sTempBuf, ':');
        assert(sPos1 != NULL);

        sPos2 = idlOS::strchr(sPos1+1, ':');
        assert(sPos2 != NULL);
        *sPos2 = '\0';

        mString.eraseWhiteSpace(sPos1+1);
        mString.removeLastCR(sPos1+1);
        mString.toUpper(sPos1+1);
        IDE_TEST(mSymbol->putBindList(sPos1+1, sOrder++, sParaOrder) != IDE_SUCCESS);

        sPos1 = idlOS::strchr(sPos2+1, '(');
    }
    else
    {
        sPos1 = idlOS::strchr(sTempBuf, '(');
    }

    if (sPos1==NULL)
    {
        IDE_TEST_RAISE(!aIsFunc, have_no_host_var);
        IDE_RAISE(have_no_host_var_with_func);
    }

    sBeginPos = sPos1+1;
    sLen = idlOS::strlen(sBeginPos);

    for (sPos=sBeginPos; sPos<sBeginPos+sLen; sPos++)
    {
        if ( sIsIsInString == ID_TRUE )
        {
            if (*sPos == '\'')
            {
                sIsIsInString = ID_FALSE;
            }
        }
        else if (sBraceCnt > 0)
        {
            if (*sPos == ')')
            {
                sBraceCnt--;
            }
            else if (*sPos == '(')
            {
                sBraceCnt++;
            }
        }
        else
        {
            if (*sPos == '\'')
            {
                sIsIsInString = ID_TRUE;
            }
            else if (*sPos == '(')
            {
                sBraceCnt++;
            }
            else if (*sPos == ':')
            {
                sPos1 = idlOS::strchr(sPos+1, ',');
                if (sPos1 != NULL)
                {
                    *sPos1 = '\0';
                }
                else
                {
                    sPos1 = idlOS::strchr(sPos+1, ')');
                    if (sPos1 != NULL)
                    {
                        *sPos1 = '\0';
                    }
                }

                mString.eraseWhiteSpace(sPos+1);
                mString.removeLastCR(sPos+1);
                mString.toUpper(sPos+1);
                IDE_TEST(mSymbol->putBindList(sPos+1, sOrder++, sParaOrder++) != IDE_SUCCESS);
                sPos = sPos1;
            }
            else if (*sPos == ',')
            {
                sParaOrder++;
            }
        }
    }

    if ( sTempBuf != NULL )
    {
        idlOS::free(sTempBuf);
        sTempBuf = NULL;
    }

    return IDE_SUCCESS;

    IDE_EXCEPTION(have_no_host_var);
    {
        if ( sTempBuf != NULL )
        {
            idlOS::free(sTempBuf);
            sTempBuf = NULL;
        }
        return IDE_SUCCESS;
    }

    IDE_EXCEPTION(have_no_host_var_with_func);
    {
        if ( sTempBuf != NULL )
        {
            idlOS::free(sTempBuf);
            sTempBuf = NULL;
        }
        return IDE_SUCCESS;
    }

    IDE_EXCEPTION_END;

    if ( sTempBuf != NULL )
    {
        idlOS::free(sTempBuf);
        sTempBuf = NULL;
    }

    idlOS::sprintf ( mStringBuffer, "ADS> %s\n", aBuf );
    mResultString += STAFString( mStringBuffer );
    mResultString += mSymbol->getResult();

    return IDE_FAILURE;
*/
    return IDE_SUCCESS;
}

IDE_RC
DBHandler::executePSMStmt( SChar * aPSMStmt,
                                 SChar * aUserName,
                                 SChar * aProcName,
                                 idBool  aIsFunc )
{
/*
    SShort      sInoutType;
    SShort      sDataType;
    SShort      sParaOrder;
    SQLLEN      sInoutTypeLen;
    SQLLEN      sDataTypeLen;
    SQLLEN      sParaOrderLen;

    SShort      sCType;
    SInt        sPrecision = 0;
    SInt        sMaxValue = 0;

    SymbolNode *t_node;
    SymbolNode *s_node;
    SymbolNode *r_node;

    SQLRETURN   sResult;
    SInt        i = 0;
    SInt        j = 0;

    gMessage[0] = 0;

    idlOS::sprintf ( mStringBuffer, "ADS> %s\n", aPSMStmt );
    mQueryString = STAFString( mStringBuffer );

    mISPApi.SetQuery(aPSMStmt);

    if ( idlOS::strlen(aUserName) == 0 )
    {
        idlOS::strcpy(aUserName, mLoginUserName );
    }

    r_node = mSymbol->getBindList();
    t_node = r_node;

    IDE_TEST_RAISE(mISPApi.Prepare() != IDE_SUCCESS, error);

    if (t_node == NULL)
    {
        goto no_bind_para;
    }

    IDE_TEST_RAISE(mISPApi.GetProcInfo(aUserName, aProcName, &sInoutType,
                                        &sInoutTypeLen, &sDataType,
                                        &sDataTypeLen, &sParaOrder,
                                        &sParaOrderLen) != IDE_SUCCESS, error);

    for (i=1; ; )
    {
        if (i==1 && aIsFunc)
        {
            IDE_TEST_RAISE(mISPApi.GetReturnType(aUserName, aProcName,
                                                   &sDataType, &sDataTypeLen)
                           != SQL_SUCCESS, error);
            sInoutType = SQL_PARAM_OUTPUT;
            sParaOrder = 1;
        }
        else
        {
            sResult = mISPApi.FetchProcInfo();
            if (sResult == SQL_NO_DATA) break;
            IDE_TEST_RAISE(sResult != SQL_SUCCESS, error);
        }

        if (t_node == NULL)
        {
            break;
        }

        // sParaOrder는 함수나 프로시저의 create 시 파라미터 순서
        // order는 bindpara 시 순서

        // exec proc1(:a, :b, :c), exec proc1(:a, 'a', :b)
        if (t_node->element.para_order == sParaOrder )
        {
            switch (t_node->element.type)
            {
            case iSQL_DOUBLE :
                sCType = SQL_C_DOUBLE;
                sMaxValue = ID_SIZEOF(t_node->element.d_value);
                IDE_TEST_RAISE(mISPApi.ProcBindPara(i++, sInoutType,
                                                      sCType, sDataType, 0,
                                                      &t_node->element.d_value,
                                                      sMaxValue,
                                                      &t_node->element.mInd)
                               != IDE_SUCCESS, error);
                break;
            case iSQL_REAL :
                sCType = SQL_C_FLOAT;
                sMaxValue = ID_SIZEOF(t_node->element.f_value);
                IDE_TEST_RAISE(mISPApi.ProcBindPara(i++, sInoutType,
                                                      sCType, sDataType, 0,
                                                      &t_node->element.f_value,
                                                      sMaxValue,
                                                      &t_node->element.mInd)
                              != IDE_SUCCESS, error);
                break;
            case iSQL_BLOB :
                sCType = SQL_C_BINARY;
                sMaxValue = t_node->element.precision+1;
                if (t_node->element.precision<0)
                {
                    sPrecision = 1;
                }
                else
                {
                    sPrecision = t_node->element.precision;
                }
                IDE_TEST_RAISE(mISPApi.ProcBindPara(i++, sInoutType,
                                                      sCType, sDataType, sPrecision,
                                                      t_node->element.c_value,
                                                      sMaxValue,
                                                      &t_node->element.mInd)
                               != IDE_SUCCESS, error);
                break;
            default :
                sCType = SQL_C_CHAR;
                if ( t_node->element.type == iSQL_CHAR       ||
                     t_node->element.type == iSQL_VARCHAR    ||
                     t_node->element.type == iSQL_NIBBLE ||
                     t_node->element.type == iSQL_BLOB )
                {
                    sMaxValue = t_node->element.precision+1;
                }
                else if ( t_node->element.type == iSQL_BYTE )
                {
                    sMaxValue = t_node->element.size + 1;
                }
                else
                {
                    sMaxValue = 21+1; //BIGINT_SIZE+1;
                    t_node->element.precision= 21;
                }

                if (t_node->element.precision<0)
                {
                    sPrecision = 1;
                }
                else
                {
                    sPrecision = t_node->element.precision;
                }

                IDE_TEST_RAISE(mISPApi.ProcBindPara(i++, sInoutType,
                                                      sCType, sDataType, sPrecision,
                                                      t_node->element.c_value,
                                                      sMaxValue,
                                                      &t_node->element.mInd)
                               != IDE_SUCCESS, error);
                break;
            }
            s_node = t_node;
            t_node = s_node->host_var_next;
        }
    }

no_bind_para:
    gMessage[0] = 0;

    IDE_TEST_RAISE(mISPApi.Execute() != IDE_SUCCESS, error);

    if (r_node != NULL)
    {
        mSymbol->setSymbol(r_node); // BUGBUG : r_node 는 불필요한 parameter
    }

    idlOS::sprintf( mStringBuffer, gMessage );
    mResultString += STAFString( mStringBuffer );

    // idlOS::sprintf( mStringBuffer, "Execute success.");
    // mResultString += STAFString( mStringBuffer );

    if ( mResultString.subString( mResultString.length() - 1, 1 ) == "\n" )
    {
        mResultString= mResultString.subString( 0, mResultString.length() - 1 );
    }

    // Response
    mServicer->setResponseMsg( mResultString );
    mServicer->setErrorCode( kSTAFOk  );

    mISPApi.StmtClose(ID_TRUE);

    return IDE_SUCCESS;

    IDE_EXCEPTION(error);
    {
        idlOS::sprintf( mStringBuffer, gMessage );
        mResultString += STAFString( mStringBuffer );

        uteSprintfErrorCode( mErrorBuffer, MSG_LEN, &mErrorMgr);
        mResultString += STAFString( mErrorBuffer );

        if ( idlOS::strcmp(mISPApi.GetErrorState(), "08S01") == 0 )
        {
            disconnectDB();
        }

        if ( mResultString.subString( mResultString.length() - 1, 1 ) == "\n" )
        {
            mResultString= mResultString.subString( 0, mResultString.length() - 1 );
        }

        // Response
        mServicer->setResponseMsg( mResultString );
        mServicer->setErrorCode( kSTAFUnknownError );
    }

    IDE_EXCEPTION(mem_alloc_error);
    {
        idlOS::fprintf(stderr, "Memory allocation error!!! --- (%d, %s)\n",
                       __LINE__, __FILE__);

        exit(0);
    }

    IDE_EXCEPTION_END;

    mISPApi.StmtClose(ID_TRUE);

    return IDE_FAILURE;
*/
    return IDE_SUCCESS;
}

idBool
DBHandler::executeSelectStmt( SChar * aCommandStr )
{
/*
    idlOS::sprintf ( mStringBuffer, "ADS> %s\n", aCommandStr );
    mQueryString = STAFString( mStringBuffer );

    mISPApi.SetQuery(aCommandStr);

    IDE_TEST_RAISE(mISPApi.SelectExecute(ID_FALSE, ID_TRUE) != 0, error);
    IDE_TEST( fetchSelectStmt(ID_FALSE) != IDE_SUCCESS );

    mISPApi.StmtClose(ID_FALSE);

    return ID_TRUE;

    IDE_EXCEPTION(error);
    {
        if (idlOS::strncmp(mISPApi.GetErrorState(), "08S01", 5) == 0)
        {
            uteSetErrorCode(&mErrorMgr, utERR_ABORT_Comm_Failure_Error);
            uteSprintfErrorCode(mErrorBuffer, MSG_LEN, &mErrorMgr);
            mResultString += STAFString( mErrorBuffer );

            disconnectDB();
        }
        else
        {
            uteSprintfErrorCode(mErrorBuffer, MSG_LEN, &mErrorMgr);
            mResultString += STAFString( mErrorBuffer );
        }

        if ( mResultString.subString( mResultString.length() - 1, 1 ) == "\n" )
        {
            mResultString= mResultString.subString( 0, mResultString.length() - 1 );
        }

        // Response
        mServicer->setResponseMsg( mResultString );
        mServicer->setErrorCode( kSTAFUnknownError );
    }

    IDE_EXCEPTION_END;

    mISPApi.StmtClose(ID_FALSE);

    return ID_FALSE;
*/
    return ID_TRUE;
}

IDE_RC
DBHandler::fetchSelectStmt(idBool aPrepare)
{
/*
    idBool      sIsRowPrintComplete;
    SInt        sResult;
    SInt        sRowCnt = 0;
    SInt        sColCnt = 0;
    SInt        sColPos = 0;
    SInt        sDisplayPos = 0;
    SInt       *sColSize;
    UInt        sLen = 0;
    SChar       sTemp[BUFFER_SIZE];

    sColSize = new SInt [mISPApi.m_Column.GetSize()];

    idlOS::memset( mStringBuffer, 0x00, ID_SIZEOF( mStringBuffer ) );
    idlOS::memset( sColSize, 0x00, ID_SIZEOF( sColSize ) );
    idlOS::memset( sTemp, 0x00, ID_SIZEOF( sTemp ) );

    for ( sColCnt = 0; sColCnt < mISPApi.m_Column.GetSize(); sColCnt++)
    {
        switch (mISPApi.m_Column.GetType(sColCnt))
        {
        case SQL_CHAR :
        case SQL_VARCHAR :
            sColSize[sColCnt] = mISPApi.m_Column.GetPrecision(sColCnt);
            break;
        case SQL_SMALLINT :
        case SQL_INTEGER :
        case SQL_NUMERIC :
        case SQL_DECIMAL :
        case SQL_FLOAT :
            sColSize[sColCnt] = 11;
            break;
        case SQL_DOUBLE :
            sColSize[sColCnt] = 22;
            break;
        case SQL_REAL :
            sColSize[sColCnt] = 13;
            break;
        case SQL_BIGINT :
        case SQL_INTERVAL :
        case SQL_INTERVAL_YEAR:
        case SQL_INTERVAL_MONTH:
        case SQL_INTERVAL_DAY:
        case SQL_INTERVAL_HOUR:
        case SQL_INTERVAL_MINUTE:
        case SQL_INTERVAL_SECOND:
        case SQL_INTERVAL_YEAR_TO_MONTH:
        case SQL_INTERVAL_DAY_TO_HOUR:
        case SQL_INTERVAL_DAY_TO_MINUTE:
        case SQL_INTERVAL_DAY_TO_SECOND:
        case SQL_INTERVAL_HOUR_TO_MINUTE:
        case SQL_INTERVAL_HOUR_TO_SECOND:
        case SQL_INTERVAL_MINUTE_TO_SECOND:
            sColSize[sColCnt] = 20;
            break;
        case SQL_TYPE_DATE :
        case SQL_DATE :
            sColSize[sColCnt] = 20;
            break;
        //case SQL_NATIVE_TIMESTAMP :
        //    sColSize[sColCnt] = 30;
        //    break;
        case SQL_BYTES :
        case SQL_NIBBLE :
            sColSize[sColCnt] = mISPApi.m_Column.GetPrecision(sColCnt)*2;
            break;
        case SQL_BIT:
        case SQL_VARBIT:
            sColSize[sColCnt] = mISPApi.m_Column.GetPrecision(sColCnt);
            break;
        default :
            sColSize[sColCnt] = 0;
            break;
        }
    }

    mResultString = "";

    for ( sRowCnt = 0;
          (sResult = mISPApi.Fetch(aPrepare)) != SQL_NO_DATA_FOUND;
          sRowCnt++ )
    {
        if (sResult != 0)
        {
            if (idlOS::strncmp(mISPApi.GetErrorState(), "08S01", 5) == 0)
            {
                uteSetErrorCode(&mErrorMgr, utERR_ABORT_Comm_Failure_Error);
                uteSprintfErrorCode(mErrorBuffer, MSG_LEN, &mErrorMgr);
                mResultString += STAFString( mErrorBuffer );

                disconnectDB();
            }
            uteSprintfErrorCode(mErrorBuffer, MSG_LEN, &mErrorMgr);
            mResultString += STAFString( mErrorBuffer );
            break;
        }

        sIsRowPrintComplete = ID_FALSE;

        while (sIsRowPrintComplete == ID_FALSE)
        {
            sIsRowPrintComplete = ID_TRUE;

            for ( sColCnt = 0; sColCnt < mISPApi.m_Column.GetSize(); sColCnt++ )
            {
                switch (mISPApi.m_Column.GetType( sColCnt ) )
                {
                    case SQL_CHAR :
                    case SQL_BYTES :
                    case SQL_NIBBLE :
                    case SQL_VARCHAR :
                    case SQL_BIT:
                    case SQL_VARBIT:
                    {
                        sLen = idlOS::strlen( mISPApi.m_Column.m_CValue[sColCnt] );
                        for ( sColPos = 0; sColPos < sLen; sColPos++ )
                        {
                            mStringBuffer[sDisplayPos] = mISPApi.m_Column.m_CValue[sColCnt][sColPos];
                            sDisplayPos++;
                        }
                        break;
                    }
                    case SQL_DOUBLE :
                    {
                        mDoubleVar = *(SDouble *)mISPApi.m_Column.m_Value[sColCnt];
                        idlOS::sprintf( sTemp, "%"ID_DOUBLE_G_FMT, mDoubleVar );
                        idlOS::sprintf( mStringBuffer + sDisplayPos,
                                        "%s",
                                        sTemp );
                        sDisplayPos += idlOS::strlen( sTemp );
                        break;
                    }
                    case SQL_REAL :
                    {
                        mFloatVar = *(SFloat *)mISPApi.m_Column.m_Value[sColCnt];
                        idlOS::sprintf( sTemp, "%"ID_FLOAT_G_FMT, mFloatVar );
                        idlOS::sprintf( mStringBuffer + sDisplayPos,
                                        "%s",
                                        sTemp );
                        sDisplayPos += idlOS::strlen( sTemp );
                        break;
                    }
                    case SQL_NUMERIC :
                    case SQL_DECIMAL :
                    case SQL_SMALLINT :
                    case SQL_INTEGER :
                    case SQL_BIGINT :
                    case SQL_FLOAT :
                    case SQL_TYPE_DATE :
                    case SQL_DATE :
                    //case SQL_NATIVE_TIMESTAMP :
                    case SQL_INTERVAL :
                    case SQL_INTERVAL_YEAR:
                    case SQL_INTERVAL_MONTH:
                    case SQL_INTERVAL_DAY:
                    case SQL_INTERVAL_HOUR:
                    case SQL_INTERVAL_MINUTE:
                    case SQL_INTERVAL_SECOND:
                    case SQL_INTERVAL_YEAR_TO_MONTH:
                    case SQL_INTERVAL_DAY_TO_HOUR:
                    case SQL_INTERVAL_DAY_TO_MINUTE:
                    case SQL_INTERVAL_DAY_TO_SECOND:
                    case SQL_INTERVAL_HOUR_TO_MINUTE:
                    case SQL_INTERVAL_HOUR_TO_SECOND:
                    case SQL_INTERVAL_MINUTE_TO_SECOND:
                    {
                        sLen = idlOS::strlen( mISPApi.m_Column.m_CValue[sColCnt] );
                        for ( sColPos = 0; sColPos < sLen; sColPos++ )
                        {
                            mStringBuffer[sDisplayPos]= mISPApi.m_Column.m_CValue[sColCnt][sColPos];
                            sDisplayPos++;
                        }
                        break;
                    }
                    //case SQL_NULL :
                    //    break;
                    default :
                        idlOS::sprintf( sTemp, "%s", "unknown type\n" );
                        idlOS::sprintf( mStringBuffer + sDisplayPos,
                                        "%s",
                                        sTemp );
                        sDisplayPos += idlOS::strlen( "unknown type\n" );
                        break;
                }
                // column-separator
                mStringBuffer[sDisplayPos] = '|';
                sDisplayPos++;
            } // column-loop
        }
        // mStringBuffer에는 한줄씩만 쓴다.
        mStringBuffer[sDisplayPos] = '\n';
        sDisplayPos = 0;

        mResultString += STAFString( mStringBuffer );
        idlOS::memset( mStringBuffer, 0x00, ID_SIZEOF( mStringBuffer ) );
    } // row-loop

    if ( mResultString.subString( mResultString.length() - 1, 1 ) == "\n" )
    {
        mResultString= mResultString.subString( 0, mResultString.length() - 1 );
    }

    // Response
    mServicer->setResponseMsg( mResultString );
    mServicer->setErrorCode( kSTAFOk );

    if ( sRowCnt == 0)
    {
        idlOS::sprintf( mStringBuffer, "No rows " );
    }
    else if ( sRowCnt == 1)
    {
        idlOS::sprintf( mStringBuffer, "1 row " );
    }
    else
    {
        idlOS::sprintf( mStringBuffer, "%d rows ", sRowCnt );
    }
    mResultString += STAFString( STAFString("\n") + mStringBuffer );

    idlOS::sprintf( mStringBuffer, "selected.");
    mResultString += STAFString( mStringBuffer );

    delete [] sColSize;
    mISPApi.m_Column.freeMem();

    return IDE_SUCCESS;
*/
    return IDE_SUCCESS;
}

IDE_RC
DBHandler::connectDB( SChar * aHost,
                            SChar * aUserID,
                            SChar * aPasswd,
                            SChar * aNLS,
                            SInt    aPort,
                            SInt    aConntype )
{
/*
    SQLRETURN      sError;
    UInt           sRetry = 0;
    PDL_Time_Value sTimeout;

    sTimeout.set( SLEEP_TIMEOUT, 0 );

retry:
    mISPApi.Close();

    sError = mISPApi.Open( aHost,
                           aUserID,
                           aPasswd,
                           aNLS,
                           aPort,
                           aConntype,
                           &mMessageCallbackStruct );

    if( sError != IDE_SUCCESS )
    {
        if( sRetry < MAX_USER_RETRY )
        {
            sRetry++;
            idlOS::sleep( sTimeout );
            goto retry;
        }
        else
        {
            IDE_RAISE( error );
        }
    }

    return IDE_SUCCESS;

    IDE_EXCEPTION(error);
    {
        if ( aConntype == 5 )
        {
            if ( idlOS::strncmp(mISPApi.GetErrorState(), "CIDLE", 5) == 0 )
            {
                return IDE_SUCCESS;
            }
            else
            {
                uteSprintfErrorCode(mErrorBuffer, MSG_LEN, &mErrorMgr);
                mResultString += STAFString( mErrorBuffer );
            }
        }
        else
        {
            uteSprintfErrorCode(mErrorBuffer, MSG_LEN, &mErrorMgr);
            mResultString += STAFString( mErrorBuffer );
        }
    }

    // Response
    mServicer->setResponseMsg( mResultString );
    mServicer->setErrorCode( kSTAFUnknownError );

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
*/
    return IDE_SUCCESS;
}

void
DBHandler::disconnectDB()
{
#if defined(STAF_OS_NAME_WIN32)
	char sBuffer[128];
    sprintf( sBuffer, "%s\n", "exit" ); 
    DWORD sByte = strlen(sBuffer);
    WriteFile( isql_o, 
               sBuffer, 
               sByte, 
               &sByte, 
               NULL );

    CloseHandle( isql_i );
    CloseHandle( isql_o );
#else
    if( isql_i != NULL )
    {
        fclose( isql_i );
        isql_i = NULL;
    }
    if( isql_o != NULL )
    {
        fclose( isql_o );
        isql_o = NULL;
    }

    if( pid != 0 )
    {
        kill( pid, SIGKILL );
        waitpid( pid, NULL, 0 );
        pid = 0;
    }
    //mISPApi.Close();
#endif
}

STAFString
DBHandler::getResult()
{
    return ( mQueryString + mResultString );
}

void
DBHandler::setUser( STAFString aUser )
{
    copyData( mUserName,
              aUser.buffer(),
              aUser.length() );
}

void
DBHandler::setLoginUser( STAFString aLoginUser )
{
    copyData( mLoginUserName,
              aLoginUser.buffer(),
              aLoginUser.length() );
}

void
DBHandler::setPassword( STAFString aPassWord )
{
    copyData( mPassWord,
              aPassWord.buffer(),
              aPassWord.length() );
}

void
DBHandler::setProcName( STAFString aProcName )
{
    copyData( mProcName,
              aProcName.buffer(),
              aProcName.length() );
}

SInt
DBHandler::ping()
{
    SChar sBuffer[65536];

    sprintf( sBuffer, "%s;\n", "set linesize 32767" );

#if defined(STAF_OS_NAME_WIN32)
    DWORD sByte = strlen(sBuffer);
    if( WriteFile( isql_o, sBuffer, sByte, &sByte, NULL ) == FALSE )
    {
        printf( "ping fwrite error: %d\n", errno );

        return -1; 
    }
    else
    {
        fflush( NULL );

        while( 1 )
        {
            if( _fgets( sBuffer, sizeof(sBuffer), &isql_i ) <= 0 )
            {
                //printf( "ping fgets error: %d\n", errno );

                return -1;
            } 
            else
            {
                if( strstr( sBuffer, "$$EOF$$" ) != NULL )
                {
                    break;
                }
                else
                { 
                    mResultString += sBuffer;
                } 
            }
        }
    }
#else 
    if( fwrite( sBuffer,
                strlen(sBuffer),
                1,
                isql_o ) < 0 )
    {
        //printf( "ping fwrite error: %d\n", errno );

        return -1;
    }
    else
    {
        fflush( isql_o );

        while( 1 )
        {
            if( fgets( sBuffer, sizeof(sBuffer), isql_i ) <= 0 )
            {
                //printf( "ping fgets error: %d\n", errno );

                return -1;
            }
            else
            {
                if( strstr( sBuffer, "$$EOF$$" ) != NULL )
                {
                    break;
                }
                else
                {
                    mResultString += sBuffer;
                }
            }
        }
    }
#endif
    mResultString = mResultString.subString( 0, mResultString.length() - 1 );

    // empty result 
    if( mResultString.length() == 0 )
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

#if defined(STAF_OS_NAME_WIN32)
int DBHandler::_fgets( SChar *aBuffer, int aSize, HANDLE *isql_i )
{
    int sCursor = 0;
    DWORD sByte = 0;

    while( 1 )
    {
        if( ReadFile( *isql_i, &aBuffer[sCursor], 1, &sByte, NULL ) == FALSE )
        {
            return -1;
        }

        if( aBuffer[sCursor] == '\r' )
        {
            continue;
        }

        if( aBuffer[sCursor] == '\n' )
        {
            sCursor++;
            break;
        }
        else
        {
            sCursor++;
        }
    } 

    aBuffer[sCursor] = '\0';

    //cout << "[" << aBuffer << "]" << endl;

    return sCursor;
}
#endif
