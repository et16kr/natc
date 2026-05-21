/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: serviceThread.cpp 721 2006-06-29 06:19:26Z orc $
 **********************************************************************/

#include "serviceThread_ads.h"
#include "serviceManager_ads.h"
#include "altibaseHandler_ads.h"
#include "common_ads.h"
#include <stdlib.h>

AdsServicer::AdsServicer()
#if defined(STAF_OS_NAME_HPUX) || defined(STAF_OS_NAME_AIX) || defined(STAF_OS_NAME_WIN32) || defined(STAF_OS_NAME_SOLARIS) || defined(STAF_OS_NAME_DEC)
: atsBaseThread( 10 * 1024 * 1024 )
#endif
{
}

IDE_RC          
AdsServicer::initialize( STAFServiceRequestLevel30 *aService,
                      ServiceDataADS               *aServiceData )
{
    mEnd           = ID_FALSE;

    mService       = aService;
    mServiceData   = aServiceData;

    mErrorCode     = kSTAFOk;

    memset( &mMutex, 0, ID_SIZEOF(mMutex) );
    IDE_TEST( pthread_mutex_init( &mMutex,
                                        NULL ) != 0 );

    mRunner = new DBHandler( this );

    IDE_TEST( mRunner->initialize( ) != IDE_SUCCESS );

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC          
AdsServicer::destroy()
{
    IDE_TEST( pthread_mutex_destroy( &mMutex ) != 0 );

    if( mRunner != NULL )
    {
        mRunner->destroy();
        delete mRunner;
        mRunner = NULL;
    }

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

void
AdsServicer::run()
{
    IDE_TEST( parseOption() != IDE_SUCCESS );

    IDE_TEST( runReal() != IDE_SUCCESS );
    
    return;

    IDE_EXCEPTION_END;
    
    return;
}

IDE_RC
AdsServicer::parseOption()
{
    // 사용자가 지정한 옵션을 얻어온다.
    // staf local ads run "QUERY" dsn "DSN" user "USER" passwd "PASSWORD" nls "NLS_USE" port "PORT" conntype "CONNTYPE"

    STAFResultPtr             sResult;
    STAFCommandParseResultPtr sParsedResult;

    sParsedResult = mServiceData->runParser->parse( mService->request );

    IDE_TEST( sParsedResult->rc != kSTAFOk )

    sResult = AdsServiceManager::resolveOption( mService,
                                                mServiceData,
                                                sParsedResult,
                                                "RUN");
    IDE_TEST( sResult->rc != 0 );
    mQuery = sResult->result;

    sResult = AdsServiceManager::resolveOption( mService,
                                                mServiceData,
                                                sParsedResult,
                                                "DSN");
    IDE_TEST( sResult->rc != 0 );

    copyData( mDsn,
              sResult->result.strip().toCurrentCodePage()->buffer(),
              sResult->result.strip().toCurrentCodePage()->length() );

    sResult = AdsServiceManager::resolveOption( mService,
                                                mServiceData,
                                                sParsedResult,
                                                "USER");
    IDE_TEST( sResult->rc != 0 );
    copyData( mUser,
              sResult->result.strip().toCurrentCodePage()->buffer(),
              sResult->result.strip().toCurrentCodePage()->length() );

    sResult = AdsServiceManager::resolveOption( mService,
                                                mServiceData,
                                                sParsedResult,
                                                "PASSWD");
    IDE_TEST( sResult->rc != 0 );
    copyData( mPasswd,
              sResult->result.strip().toCurrentCodePage()->buffer(),
              sResult->result.strip().toCurrentCodePage()->length() );

    sResult = AdsServiceManager::resolveOption( mService,
                                                mServiceData,
                                                sParsedResult,
                                                "NLS_USE");
    IDE_TEST( sResult->rc != 0 );
    copyData( mNls,
              sResult->result.strip().upperCase().toCurrentCodePage()->buffer(),
              sResult->result.strip().upperCase().toCurrentCodePage()->length() );

    sResult = AdsServiceManager::resolveOption( mService,
                                                mServiceData,
                                                sParsedResult,
                                                "PORT");
    IDE_TEST( sResult->rc != 0 );
    copyData( mPort,
              sResult->result.strip().toCurrentCodePage()->buffer(),
              sResult->result.strip().toCurrentCodePage()->length() );

    sResult = AdsServiceManager::resolveOption( mService,
                                                mServiceData,
                                                sParsedResult,
                                                "CONNTYPE");
    IDE_TEST( sResult->rc != 0 );
    copyData( mConntype,
              sResult->result.strip().upperCase().toCurrentCodePage()->buffer(),
              sResult->result.strip().upperCase().toCurrentCodePage()->length() );

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC
AdsServicer::runReal()
{
    CommandKind sCommandKind;
    idBool      sIsUserProcName = ID_FALSE;

    if( mQuery.strip().subWord( 0, 1 ).upperCase() == "INSERT" )
    {
        sCommandKind = QUERY_INSERT;
    }
    else if( mQuery.strip().subWord( 0, 1 ).upperCase() == "UPDATE" )
    {
        sCommandKind = QUERY_UPDATE;
    }
    else if( mQuery.strip().subWord( 0, 1 ).upperCase() == "SELECT" )
    {
        sCommandKind = QUERY_SELECT;
    }
    else if( mQuery.strip().subWord( 0, 1 ).upperCase() == "DELETE" )
    {
        sCommandKind = QUERY_DELETE;
    }
    else if( ( mQuery.strip().subWord( 0, 1 ).upperCase() == "EXECUTE" ) ||
             ( mQuery.strip().subWord( 0, 1 ).upperCase() == "EXEC" ) )
    {
        sCommandKind = QUERY_EXECUTE;
        mRunner->setProcName( mQuery.strip().subWord( 1, 1 ) );

        if ( mQuery.strip().subWord( 1, 1 ).find(".") != STAFString::kNPos )
        {
            sIsUserProcName = ID_TRUE;
        }
    }
    else
    {
    }

    // 환경 세팅
    if( sIsUserProcName == ID_TRUE )
    {
        mRunner->setUser( mQuery.strip().subWord( 1, 1 ).replace( ".", " " ).subWord( 0, 1 ) );
        mRunner->setProcName( mQuery.strip().subWord( 1, 1 ).replace( ".", " " ).subWord( 1, 1 ) );
    }
    else
    {
        mRunner->setUser( mUser );
    }
    mRunner->setLoginUser( mUser );
    mRunner->setPassword( mPasswd );

    // 실제 수행 부분 
    IDE_TEST( mRunner->logon( mDsn,
                              mUser,
                              mPasswd,
                              mNls,
                              atoi( mPort ),
                              mConntype ) 
              != IDE_SUCCESS );

    copyData( mQueryBuffer,
              mQuery.buffer(),
              mQuery.length() );

    IDE_TEST( mRunner->execute( mQueryBuffer, sCommandKind ) != IDE_SUCCESS );

    mResult = mRunner->getResult();

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

SInt
AdsServicer::lock()
{
    return pthread_mutex_lock( &mMutex );
}

SInt
AdsServicer::unlock()
{
    return pthread_mutex_unlock( &mMutex );
}

STAFString
AdsServicer::status()
{
    return IDE_SUCCESS;
}

void
AdsServicer::setResponseMsg( STAFString aMsg )
{
    mMessage = aMsg;
}

void
AdsServicer::setErrorCode( STAFError_t aErrCode )
{
    mErrorCode = aErrCode;
}
