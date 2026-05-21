/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: laborerThread.h 853 2006-08-31 01:24:14Z orc $
 **********************************************************************/

#ifndef _O_LABORER_H_
#define _O_LABORER_H_ 1

#include "common.h"

class AltibaseHandler;
class Servicer; 

class Laborer : public atsBaseThread
{
public:
    Laborer();
    ~Laborer() {};

    IDE_RC                initialize( Servicer  *aServicer,  
                                      STAFString aProcess,
                                      logonData  aLogonData );
    IDE_RC                destroy();

    void                  run();
    IDE_RC                sync();
    IDE_RC                runReal();
    IDE_RC                push_back( queryData  aQuery );
    IDE_RC                push_back( QueryList *aQuery );

    SInt                  lock();
    SInt                  unlock();

    IDE_RC                end();
    STAFString            process(){ return mProcess; };
    STAFString            getResult();

    IDE_RC                runPost( STAFString aIn );
    IDE_RC                runWait( STAFString aIn );
    IDE_RC                runSystem( STAFString aIn,
                                     STAFString aProcess );
    IDE_RC                runSystem2( STAFString aIn );
    IDE_RC                runRsystem( STAFString aIn,
                                      STAFString aProcess,
                                      STAFString aID );
    IDE_RC                runLoad( STAFString aIn );
    IDE_RC                logon();
    void                  makeTdxPrefix();
    STAFString            getTdxResult();
    STAFString            status();

    // PRJ-1552
    IDE_RC                executeArtTest( SChar*      aBuffer,
                                          queryData*  aData,       
                                          queryData*  aQueryRecPtr );
     
    IDE_RC                retryExecution4ART( SChar*       aBuffer,
                                              queryData*   aQuery,
                                              queryData*   aQueryRecPtr,
                                              logonData*   aLogonData,
                                              idBool*      aIsCheckServer,
                                              idBool*      aIsBugKILL );
    
    IDE_RC                doCheckServer4ART( queryData*    aQuery,
                                             queryData*    aQueryRecPtr,
                                             logonData*    aLogonData,
                                             idBool*       aIsBugKILL );
    
    idBool                checkServer();
    IDE_RC                cleanServer();

    IDE_RC                logonRsystem( char *aIP, int aPort, int *aRsystemFd );
    IDE_RC                logoutRsystem( int * aRsystemFd );
 
private:
    pthread_mutex_t       mMutex;
    QueryList             mQuery;
    STAFString            mResult;
    AltibaseHandler      *mRunner;
    STAFString            mProcess;
    idBool                mEnd;
    //Symbol                mSymbol;
    idBool                mSbegin;

    STAFHandlePtr         mHandle;
    Servicer             *mServicer;

    idBool                mRetry;
    idBool                mLogon;
    logonData             mLogonData;

    SChar                *mMessage;
    STAFString            mTdxPrefix;
    STAFString            mTdxResult;
    STAFString            mTdxStringResult;
    STAFString            mStatus;
    STAFString            mSystemStatus;

    std::map<STAFString, int>  mRsysFds;
};

#endif
