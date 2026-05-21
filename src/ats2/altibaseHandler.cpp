/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: altibaseHandler.cpp 1140 2007-02-08 06:21:13Z leekmo $
 **********************************************************************/

#include "altibaseHandler.h"
#include "serviceManager.h"
#include "serviceThread.h"
#include <stdlib.h>

//fix BUG-20120
#if defined(STAF_OS_NAME_WIN32)
int errno;
#endif

AltibaseHandler::AltibaseHandler( Servicer  *aServicer )
{
    mServicer = aServicer;
}

IDE_RC
AltibaseHandler::initialize( logonData *aLogonData,
                             STAFString aProcess,
                             void      *aSymbol,
                             SChar     *aMessage )
{
    pid = 0;
    isql_i = NULL;
    isql_o = NULL;
    isql_i_fd = 0;

    // query, result 버퍼 초기화
    mQueryString = "";
    mResultString = "";

    // 기본값이 TRUE 이다.
    mSetHeading = ID_TRUE;

    mMessage = aMessage;
    //mSymbol  = aSymbol;
    mProcess = aProcess;

    memcpy( mProcessNum,
                   mProcess.buffer(),
                   mProcess.length() );
    mProcessNum[mProcess.length()] = '\0';

    // DESC 명령에서 외래키를 보여줄지를 결정
    mShowForeignKeys = ID_FALSE;

    // autocommit on, off 인지 설정.
    mAutoCommit = ID_TRUE;

    // explanin plan on, off 인지 설정.
    mSessionKind = EXPLAIN_PLAN_OFF;

    // set timing on, off인지 설정.
    mSetTiming = ID_FALSE;

    // 디폴트로 SYS/MANAGER로 연결된다.
    sprintf( mUserName, "%s", (SChar*) "SYS" );
    sprintf( mLoginUserName, "%s", (SChar*) "SYS" );
    sprintf( mPassWord, "%s", (SChar*) "MANAGER" );

    mIsRealQuery = ID_TRUE;

    // sysdba 모드인지 설정
    mIsSysdba = ID_FALSE;

    mLogonData = *aLogonData;

    mIsqlReadTimeout = mServicer->getIsqlReadTimeout();

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC
AltibaseHandler::destroy()
{
    (void)logout();

    return IDE_SUCCESS;
}

IDE_RC
AltibaseHandler::logon()
{
    return logon( &mLogonData );
}

IDE_RC
AltibaseHandler::logon( logonData *aLogonData )
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
             aLogonData->home,
             aLogonData->user,
             aLogonData->password,
             aLogonData->port,
             aLogonData->host,
             aLogonData->nls );

    (void)ServiceManager::lock();

    switch( aLogonData->conn_type )
    {
       case 1:
           putenv( "ISQL_CONNECTION=TCP" );
           break;
       case 2:
           putenv( "ISQL_CONNECTION=UNIX" );
           break;
       case 3:
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

    (void)ServiceManager::unlock();

    if( sRs == 0 )
    {
        fprintf( stderr, "execl error: %d\n", GetLastError() );
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

        sprintf( sPath, 
                        "%s/bin/isql", 
                        aLogonData->home );

        sprintf( sPort,
                        "%d", aLogonData->port );
        char * sArgs[14];

        sArgs[0] = sPath;
        sArgs[1] = "-silent";
        sArgs[2] = "-u";
        sArgs[3] = aLogonData->user;
        sArgs[4] = "-p";
        sArgs[5] = aLogonData->password;
        sArgs[6] = "-port";
        sArgs[7] = sPort;
        sArgs[8] = "-s";
        sArgs[9] = aLogonData->host;
        sArgs[10] = "-nls_use";
        sArgs[11] = aLogonData->nls;
        sArgs[12] = "-ataf";
        sArgs[13] = 0;

        putenv( aLogonData->env ); 

        switch( aLogonData->conn_type )
        {
           case 1:
               putenv( "ISQL_CONNECTION=TCP" );
               break;
           case 2:
               putenv( "ISQL_CONNECTION=UNIX" );
               break;
           case 3:
               putenv( "ISQL_CONNECTION=IPC" );
               break;
        }

         int sRs = execv( sPath, 
                         sArgs );

         if( sRs < 0 )
         {
            fprintf( stderr, "execl error: %d\n", errno );
            exit(-1);
         }
    } 
#endif

    IDE_TEST_RAISE( ping() != 1, error );  

    return IDE_SUCCESS;

    IDE_EXCEPTION( error );
    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC
AltibaseHandler::logout()
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
#endif

    return IDE_SUCCESS;
}

IDE_RC
AltibaseHandler::execute( SChar* aBuffer, CommandKind aCommandKind )
{
#if defined(STAF_OS_NAME_WIN32)
    SChar sBuffer[65536 * 2];
    SInt sSize;
    SInt sRs;

    sSize = strlen( aBuffer );

    switch( aCommandKind )
    {
        case CREATE_OBJ_COM:
            if( aBuffer[sSize-1] !=  ';' )
            {
                sprintf( sBuffer, "%s;\n", aBuffer );
            }
            else
            {
                sprintf( sBuffer, "%s\n", aBuffer );
            } 
            mQueryString = STAFString("$") + mProcessNum + "> " + sBuffer;
            sprintf( sBuffer, "%s;\n", mRealQuery );
            break;
        case CREATE_PROC_COM:
        case PRINT_COM:
        case SYMBOL_COM:
            sprintf( sBuffer, "%s\n", aBuffer );
            mQueryString = STAFString("$") + mProcessNum + "> " + sBuffer;
            break;
        default:
            if( aBuffer[sSize-1] !=  ';' )
            {
                sprintf( sBuffer, "%s;\n", aBuffer );
            }
            else
            {
                sprintf( sBuffer, "%s\n", aBuffer );
            } 
            mQueryString = STAFString("$") + mProcessNum + "> " + sBuffer;
            break;
    }

    mResultString = "";

    //cout << mQueryString;

    DWORD sByte = strlen(sBuffer);
    if( WriteFile( isql_o, 
                   sBuffer, 
                   sByte, 
                   &sByte, 
                   NULL ) == FALSE )
    {
        errno = GetLastError();
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

        sRs = WaitForSingleObject( isql_i, mIsqlReadTimeout * 1000L );

        if( sRs == WAIT_FAILED )
        {
            //error
        }
        else if( sRs == WAIT_TIMEOUT )
        {
            //timeout
        }
        else if( sRs == WAIT_OBJECT_0 )
        {
            while( 1 )
            {
                if( _fgets( sBuffer, sizeof(sBuffer), &isql_i ) <= 0 )
                {
                    errno = GetLastError();
                    // Broken pipe, fix BUG-20120
                    if( (errno == ERROR_NO_DATA) || (errno == ERROR_BROKEN_PIPE) )
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
                        mResultString += sBuffer;

                        if( strstr( sBuffer, "ERR-91015" ) != NULL )
                        {
                            break;
                        }
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

    FD_ZERO( &sRset );
    FD_SET( isql_i_fd, &sRset );

    sTimeout.tv_sec = mIsqlReadTimeout;
    sTimeout.tv_usec = 0;

    sSize = strlen( aBuffer );

    switch( aCommandKind )
    {
        case CREATE_OBJ_COM:
            if( aBuffer[sSize-1] !=  ';' )
            {
                sprintf( sBuffer, "%s;\n", aBuffer );
            }
            else
            {
                sprintf( sBuffer, "%s\n", aBuffer );
            } 
            mQueryString = STAFString("$") + mProcessNum + "> " + sBuffer;
            sprintf( sBuffer, "%s;\n", mRealQuery );
            break;
        case CREATE_PROC_COM:
        case PRINT_COM:
        case SYMBOL_COM:
            sprintf( sBuffer, "%s\n", aBuffer );
            mQueryString = STAFString("$") + mProcessNum + "> " + sBuffer;
            break;
        default:
            if( aBuffer[sSize-1] !=  ';' )
            {
                sprintf( sBuffer, "%s;\n", aBuffer );
            }
            else
            {
                sprintf( sBuffer, "%s\n", aBuffer );
            } 
            mQueryString = STAFString("$") + mProcessNum + "> " + sBuffer;
            break;
    }

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

        if ( mIsqlReadTimeout == 0 )
        {
            sRs = select( isql_i_fd + 1, &sRset, NULL, NULL, NULL);//For valgrind
        }
        else
        {
            sRs = select( isql_i_fd + 1, &sRset, NULL, NULL, &sTimeout );
        }

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
                if( fgets( sBuffer, sizeof(sBuffer), isql_i ) <= 0 )
                {
                    //fprintf( stderr, "fgets error: %d\n", errno );
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
                        mResultString += sBuffer;

                        if( strstr( sBuffer, "ERR-91015" ) != NULL )
                        {
                            break;
                        }
                    } 
                }
            }
        }
    }
#endif
  
    mResultString = mResultString.subString( 0, mResultString.length() - 1 );

    //cout << mResultString << endl; 

    return IDE_SUCCESS;
}

void
AltibaseHandler::setRealQuery( STAFString aQuery )
{
    memcpy( mRealQuery,
                   aQuery.toCurrentCodePage()->buffer(),
                   aQuery.toCurrentCodePage()->length() );
    mRealQuery[aQuery.toCurrentCodePage()->length()] = '\0';
}

STAFString
AltibaseHandler::getResult( idBool aPeek )
{
    STAFString sResult;

    sResult = mQueryString;

    if ( ( mResultString.length() == 0 ) &&
         ( sResult.subString( sResult.length() - 1, 1 ) == "\n" ) )
    {
        sResult = sResult.subString( 0, sResult.length() - 1 );
    }

    if( mResultString.subString( mResultString.length() - 1, 1 ) == "\n" )
    {
        sResult += mResultString.subString(0, mResultString.length() - 1);
    }
    else
    {
        sResult += mResultString;
    }

    if( aPeek != ID_TRUE )
    {
        clear();
    }

    // fix BUG-14311 + P0 서버가 아닐 경우에도 FATAL 처리해야 함
    if( sResult.find( "ERR-50032" ) != STAFString::kNPos )
//        strcmp( mProcessNum, "P0" ) == 0 )
    {
        mServicer->setFatal();
    }

    return sResult;
}

STAFString
AltibaseHandler::getQueryOnly()
{
    return mQueryString;
}

STAFString
AltibaseHandler::getResultOnly()
{
    return mResultString;
}

SInt 
AltibaseHandler::ping()
{
    SChar sBuffer[65536];

    sprintf( sBuffer, "%s;\n", "ping" );

#if defined(STAF_OS_NAME_WIN32)
    DWORD sByte = strlen(sBuffer);
    if( WriteFile( isql_o, sBuffer, sByte, &sByte, NULL ) == FALSE )
    {
        // fix BUG-20120
        printf( "ping fwrite error: %d\n", GetLastError() );

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

    // Syntax Error
    if( mResultString.find( "ERR-91010" ) !=  STAFString::kNPos )
    {
        return 1; 
    }
    else
    {
        return 0; 
    }   
}

#if defined(STAF_OS_NAME_WIN32)
int AltibaseHandler::_fgets( SChar *aBuffer, int aSize, HANDLE *isql_i )
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
