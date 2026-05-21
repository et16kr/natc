/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: serviceThread.h 704 2006-06-22 06:39:49Z orc $
 **********************************************************************/

#ifndef _O_SERVICER_H_
#define _O_SERVICER_H_ 1

#include "common_ads.h"
#include "altibaseHandler_ads.h"

struct ServiceDataADS;

class DBHandler;

class AdsServicer : public atsBaseThread
{
public:
    AdsServicer();
    ~AdsServicer() {};

    IDE_RC                     initialize( STAFServiceRequestLevel30 *aInfo,
                                           ServiceDataADS               *aServiceData );
    IDE_RC                     destroy();

    void                       run();

    SInt                       lock();
    SInt                       unlock();

    STAFString                 status(); 
    STAFString                 message() { return mMessage; };
    STAFError_t                errorCode() { return mErrorCode; };

    IDE_RC                     parseOption();
    IDE_RC                     runReal();

    void                       setResponseMsg( STAFString aMsg );
    void                       setErrorCode( STAFError_t aErrCode );

private:
    pthread_mutex_t         mMutex;

    DBHandler                 *mRunner;

    idBool                     mEnd;

    STAFServiceRequestLevel30 *mService;
    ServiceDataADS               *mServiceData;

    STAFString                 mQuery;
    SChar                      mQueryBuffer[BUFFER_SIZE];
    SChar                      mDsn[SMALL_BUFFER];
    SChar                      mUser[SMALL_BUFFER];
    SChar                      mPasswd[SMALL_BUFFER];
    SChar                      mNls[SMALL_BUFFER];
    SChar                      mPort[SMALL_BUFFER];
    SChar                      mConntype[SMALL_BUFFER];

    STAFString                 mResult;

    STAFString                 mMessage;
    STAFError_t                mErrorCode;
};

#endif
