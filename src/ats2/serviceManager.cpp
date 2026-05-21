/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: serviceManager.cpp 1152 2007-02-16 02:37:53Z ataf $
 **********************************************************************/

#include "serviceManager.h"
#include "serviceThread.h"

extern STAFString       gLineSep;
extern const STAFString gVersionInfo("3.0.21");
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

ServicerList              ServiceManager::mServicerList;
pthread_mutex_t        ServiceManager::mMutex;

//PDL_thread_key_t          psmKey;

IDE_RC          
ServiceManager::initialize()
{
    memset( &mMutex, 0, ID_SIZEOF(mMutex) );
    IDE_TEST( pthread_mutex_init( &mMutex,
                                        NULL ) != 0 );

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC          
ServiceManager::destroy()
{
    IDE_TEST( pthread_mutex_destroy( &mMutex ) != 0 );

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

SInt
ServiceManager::lock()
{
    return pthread_mutex_lock( &mMutex );
}

SInt
ServiceManager::unlock()
{
    return pthread_mutex_unlock( &mMutex );
}

SInt
ServiceManager::lockLogon()
{
    return 1;
}

SInt
ServiceManager::unlockLogon()
{
    return 1;
}

IDE_RC          
ServiceManager::addService( Servicer *aServicer )
{
    IDE_ASSERT( aServicer != NULL );

    IDE_TEST( lock() != 0 );

    (void)mServicerList.push_back( aServicer );
   
    //printf( "!! a: %d\n", mServicerList.size() );
 
    IDE_TEST( unlock() != 0 );

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC          
ServiceManager::rmService( Servicer *aServicer )
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

            //printf( "!! b: %d\n", mServicerList.size() );
            break;
        }
    }
    
    IDE_TEST( unlock() != 0 );

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

STAFResultPtr
ServiceManager::handleHelp( STAFServiceRequestLevel30 *aInfo,
                            ServiceData               *aServiceData )
{
    STAFString sHelp("ATS Service Help" + gLineSep + gLineSep);

    sHelp += "RUN <TEST CASE>";
    sHelp += gLineSep;
    sHelp += "VERSION" + gLineSep;
    sHelp += "HELP" + gLineSep;

    return STAFResultPtr( new STAFResult(kSTAFOk, sHelp), STAFResultPtr::INIT );
}


STAFResultPtr
ServiceManager::handleVersion( STAFServiceRequestLevel30 *aInfo,
                               ServiceData               *aServiceData )
{
    return STAFResultPtr( new STAFResult(kSTAFOk, gVersionInfo), STAFResultPtr::INIT );
}

STAFResultPtr
ServiceManager::handleKill( STAFServiceRequestLevel30 *aInfo,
                            ServiceData               *aServiceData )
{
    kill( getpid(), SIGTERM );
    return STAFResultPtr( new STAFResult(kSTAFOk, ""), STAFResultPtr::INIT );
}

STAFResultPtr
ServiceManager::handleStatus( STAFServiceRequestLevel30 *aInfo,
                              ServiceData               *aServiceData )
{
    ServicerList::iterator    sIterator;
    STAFResultPtr             sResult;
    STAFString                sData;

    IDE_TEST( lock() != 0 );

    for( sIterator  = mServicerList.begin(); 
         sIterator != mServicerList.end(); 
         sIterator++ )
    {
        sData += (*sIterator)->status();
        sData += "\n";
    }
    
    IDE_TEST( unlock() != 0 );

    return STAFResultPtr( new STAFResult(kSTAFOk, sData), 
                          STAFResultPtr::INIT );

    IDE_EXCEPTION_END;
    
    return STAFResultPtr( new STAFResult(kSTAFOk, sResult->result), 
                          STAFResultPtr::INIT );
}

STAFResultPtr
ServiceManager::handleRun( STAFServiceRequestLevel30 *aInfo,
                           ServiceData               *aServiceData )
{
    STAFString sMessage;
    Servicer  *sServicer = NULL;

    sServicer = new Servicer;

    IDE_TEST_RAISE( sServicer == NULL,
                    ERROR_NULL );

    IDE_TEST_RAISE( sServicer->initialize( aInfo, 
                                           aServiceData ) != IDE_SUCCESS,
                    ERROR_INITIALIZE );

    IDE_TEST_RAISE( addService( sServicer ) != IDE_SUCCESS,
                    ERROR_ADD );

    IDE_TEST_RAISE( sServicer->start() != IDE_SUCCESS,
                    ERROR_START );

    IDE_TEST_RAISE( pthread_join( sServicer->getTid(), 
                                  NULL ) != IDE_SUCCESS,
                    ERROR_JOIN );
   
    sMessage = sServicer->message();
 
    IDE_TEST_RAISE( rmService( sServicer ) != IDE_SUCCESS,
                    ERROR_RM );

    IDE_TEST_RAISE( sServicer->destroy() != IDE_SUCCESS,
                    ERROR_DESTROY );

    if( sServicer != NULL )
    {
        delete sServicer;
    }

    return STAFResultPtr(new STAFResult(kSTAFOk, sMessage),
                         STAFResultPtr::INIT);

    IDE_EXCEPTION( ERROR_NULL );
    {
        sMessage = " IGNR # ATS exception 1: ";
        sMessage += STAFString( errno );
    }
    IDE_EXCEPTION( ERROR_INITIALIZE );
    {
        sMessage = " IGNR # ATS exception 2: ";
        sMessage += STAFString( errno );
    }
    IDE_EXCEPTION( ERROR_ADD );
    {
        (void)sServicer->destroy(); 
        sMessage = " IGNR # ATS exception 3: ";
        sMessage += STAFString( errno );
    }
    IDE_EXCEPTION( ERROR_START );
    {
        (void)sServicer->destroy(); 
        sMessage = " IGNR # ATS exception 4: ";
        sMessage += STAFString( errno );
    }
    IDE_EXCEPTION( ERROR_JOIN );
    {
        (void)sServicer->destroy(); 
        sMessage = " IGNR # ATS exception 5: ";
        sMessage += STAFString( errno );
    }
    IDE_EXCEPTION( ERROR_RM );
    {
        (void)sServicer->destroy(); 
        sMessage = " IGNR # ATS exception 6: ";
        sMessage += STAFString( errno );
    }
    IDE_EXCEPTION( ERROR_DESTROY );
    {
        (void)sServicer->destroy(); 
        sMessage = " IGNR # ATS exception 7: ";
        sMessage += STAFString( errno );
    }
    IDE_EXCEPTION_END;

    if( sServicer != NULL )
    {
        delete sServicer;
    }

    return STAFResultPtr(new STAFResult(kSTAFOk, sMessage),
                         STAFResultPtr::INIT);
}

STAFResultPtr
ServiceManager::resolveOption( STAFServiceRequestLevel30 *aInfo,
                               ServiceData               *aServiceData,
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
ServiceManager::resolveString( STAFServiceRequestLevel30 *aInfo,
                               ServiceData               *aServiceData,
                               const STAFString          &aTheString)
{
    return aServiceData->handlePtr->submit( gLocal, gVar, gResStrResolve +
                                     STAFString(aInfo->requestNumber) +
                                     gString +
                                     aServiceData->handlePtr->wrapData(aTheString) );
}

void
ServiceManager::registerHelpData( ServiceData      *aServiceData,
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
ServiceManager::unregisterHelpData( ServiceData *aServiceData,
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

IDE_RC 
ServiceManager::registerHandle( STAFHandlePtr &aHandle )
{
    static SInt   sCycle = 0;
    STAFRC_t      sEcode = kSTAFUnknownError;
    STAFResultPtr sResult;
    SChar         sName[128];
    UInt          sLevel = 0;

    IDE_TEST( lock() != 0 );
    sLevel = 1;

    sCycle++;
    sprintf( sName, 
                    "%s_%d", 
                    "handle", 
                    sCycle );

    sEcode = STAFHandle::create( sName, aHandle );

    IDE_TEST( sEcode != kSTAFOk );

    sLevel = 0;
    IDE_TEST( unlock() != 0 );

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    if ( sLevel != 0 )
    {
        (void)unlock();
    }

    return IDE_FAILURE;
}
