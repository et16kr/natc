/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: serviceManager.cpp 729 2006-06-30 04:36:32Z copyrei $
 **********************************************************************/

#include "serviceManager_ads.h"
#include "serviceThread_ads.h"

extern STAFString       gLineSep;
extern const STAFString gAdsVersionInfo("3.0.1_test");
// ATAF 버전을 지정한다.
// 사용자는 아래 명령어를 통해서 버전을 확인할 수 있다.
// staf local ats version
// 각 수자가 의미하는 내용은 아래와 같다.
// 3: STAF 버전
// 0: 서비스가 추가되는 경우 ++
// 1: 버그가 fix되는 경우 ++
extern const STAFString gLocal("local");
extern const STAFString gHelp("help");
extern const STAFString gVar("var");
extern const STAFString gResStrResolve("RESOLVE REQUEST ");
extern const STAFString gString(" STRING ");
extern const STAFString gLeftCurlyBrace(kUTF8_LCURLY);

ServicerList              AdsServiceManager::mServicerList;
pthread_mutex_t        AdsServiceManager::mMutex;

IDE_RC          
AdsServiceManager::initialize()
{
    memset( &mMutex, 0, ID_SIZEOF(mMutex) );
    IDE_TEST( pthread_mutex_init( &mMutex,
                                        NULL ) != 0 );

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC          
AdsServiceManager::destroy()
{
    IDE_TEST( pthread_mutex_destroy( &mMutex ) != 0 );

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

SInt
AdsServiceManager::lock()
{
    return pthread_mutex_lock( &mMutex );
}

SInt
AdsServiceManager::unlock()
{
    return pthread_mutex_unlock( &mMutex );
}

IDE_RC          
AdsServiceManager::addService( AdsServicer*aServicer )
{
    IDE_ASSERT( aServicer != NULL );

    IDE_TEST( lock() != 0 );

    (void)mServicerList.push_back( aServicer );
   
    IDE_TEST( unlock() != 0 );

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC          
AdsServiceManager::rmService( AdsServicer *aServicer )
{
    ServicerList::iterator sIterator;

    IDE_ASSERT( aServicer != NULL );

    IDE_TEST( lock() != 0 );

    for( sIterator  = mServicerList.begin(); 
         sIterator != mServicerList.end(); 
         sIterator++ )
    {
        if( *sIterator == aServicer )
        {
            mServicerList.erase( sIterator );

            break;
        }
    }
    
    IDE_TEST( unlock() != 0 );

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

STAFResultPtr
AdsServiceManager::handleHelp( STAFServiceRequestLevel30 *aInfo,
                            ServiceDataADS               *aServiceData )
{
    STAFString sHelp("ADS Service Help" + gLineSep + gLineSep);

    sHelp += "RUN <SQL> DSN <IP> USER <ID> PASSWD <PW> NLS_USE <NLS> PORT <PORT> CONNTYPE <CONN>" + gLineSep;
    sHelp += "VERSION" + gLineSep;
    sHelp += "HELP" + gLineSep;

    return STAFResultPtr( new STAFResult(kSTAFOk, sHelp), STAFResultPtr::INIT );
}


STAFResultPtr
AdsServiceManager::handleVersion( STAFServiceRequestLevel30 *aInfo,
                               ServiceDataADS               *aServiceData )
{
    return STAFResultPtr( new STAFResult(kSTAFOk, gAdsVersionInfo), STAFResultPtr::INIT );
}

STAFResultPtr
AdsServiceManager::handleStatus( STAFServiceRequestLevel30 *aInfo,
                              ServiceDataADS               *aServiceData )
{
    return STAFResultPtr( new STAFResult(kSTAFOk, "status" ),
                          STAFResultPtr::INIT );
}

STAFResultPtr
AdsServiceManager::handleRun( STAFServiceRequestLevel30 *aInfo,
                              ServiceDataADS               *aServiceData )
{
    STAFString          sMessage;
    STAFError_t         sErrCode = kSTAFOk;
    AdsServicer        *sServicer = NULL;

    sServicer = new AdsServicer;

    IDE_TEST( sServicer == NULL );

    IDE_TEST( sServicer->initialize( aInfo,
                                     aServiceData ) != IDE_SUCCESS );

    IDE_TEST( addService( sServicer ) != IDE_SUCCESS );

    IDE_TEST( sServicer->start() != IDE_SUCCESS );

    IDE_TEST( pthread_join( sServicer->getTid(),
                               NULL ) != IDE_SUCCESS );

    sMessage = sServicer->message();
    sErrCode = sServicer->errorCode();

    IDE_TEST( sErrCode != kSTAFOk );

    IDE_TEST( rmService( sServicer ) != IDE_SUCCESS );

    IDE_TEST( sServicer->destroy() != IDE_SUCCESS );

    if( sServicer != NULL )
    {
        delete sServicer;
    }

    return STAFResultPtr(new STAFResult(sErrCode, sMessage ),
                         STAFResultPtr::INIT);

    IDE_EXCEPTION_END;

    IDE_TEST( rmService( sServicer ) != IDE_SUCCESS );

    IDE_TEST( sServicer->destroy() != IDE_SUCCESS );

    if( sServicer != NULL )
    {
        delete sServicer;
    }

    return STAFResultPtr(new STAFResult( sErrCode, sMessage ),
                         STAFResultPtr::INIT);
}

STAFResultPtr
AdsServiceManager::resolveOption( STAFServiceRequestLevel30 *aInfo,
                               ServiceDataADS               *aServiceData,
                               STAFCommandParseResultPtr &aParsedResult,
                               const STAFString          &aOption,
                               UInt                       aOptionIndex )
{
    STAFString sOptionValue = aParsedResult->optionValue(aOption, aOptionIndex);

    if( sOptionValue.find(gLeftCurlyBrace) == STAFString::kNPos )
    {
        return STAFResultPtr( new STAFResult(kSTAFOk, sOptionValue), STAFResultPtr::INIT );
    }

    return resolveString( aInfo, aServiceData, sOptionValue );
}

STAFResultPtr
AdsServiceManager::resolveString( STAFServiceRequestLevel30 *aInfo,
                               ServiceDataADS               *aServiceData,
                               const STAFString          &aTheString)
{
    return aServiceData->handlePtr->submit( gLocal, gVar, gResStrResolve +
                                     STAFString(aInfo->requestNumber) +
                                     gString +
                                     aServiceData->handlePtr->wrapData(aTheString) );
}

void
AdsServiceManager::registerHelpData( ServiceDataADS      *aServiceData,
                                  UInt              aErrorCode,
                                 const STAFString &aShortInfo,
                                 const STAFString &aLongInfo )
{
    static STAFString sRegString( "REGISTER SERVICE %C ERROR %d INFO %C "
                                 "DESCRIPTION %C");

    aServiceData->handlePtr->submit( gLocal,
                              gHelp,
                              STAFHandle::formatString(
                              sRegString.getImpl(), aServiceData->shortName.getImpl(), aErrorCode,
                              aShortInfo.getImpl(), aLongInfo.getImpl()) );
}

void
AdsServiceManager::unregisterHelpData( ServiceDataADS *aServiceData,
                                    UInt         aErrorCode )
{
    static STAFString sRegString("UNREGISTER SERVICE %C ERROR %d");

    aServiceData->handlePtr->submit( gLocal,
                                     gHelp,
                                     STAFHandle::formatString(
                                     sRegString.getImpl(), 
                                     aServiceData->shortName.getImpl(), 
                                     aErrorCode));
}
