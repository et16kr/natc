/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: altibaseHandler.h 1098 2007-01-15 03:03:19Z shsuh $
 **********************************************************************/

#ifndef _O_ALTIBASE_HANDLER_H_
#define _O_ALTIBASE_HANDLER_H_ 1

#include "common.h"

#define MSG_LEN 2048

class Servicer;

class AltibaseHandler
{
public:
    AltibaseHandler( Servicer  *aServicer );
    ~AltibaseHandler() {};

    IDE_RC      initialize( logonData   *aLogondata,
                            STAFString   aProcess,
                            void        *aSymbol,
                            SChar       *aMessage );
    IDE_RC      destroy();

    IDE_RC      logon( logonData    *aLogonData );
    IDE_RC      logon();
    IDE_RC      logout();
    IDE_RC      execute( SChar       *aBuffer,
                         CommandKind  aCommandKind );

    void        setRealQuery( STAFString aQuery );
    void        clear() { mQueryString = ""; mResultString = ""; };
    STAFString  getResult( idBool aPeek = ID_FALSE );

    // for tdx file
    STAFString  getQueryOnly();
    STAFString  getResultOnly();

private:
    //SQL_MESSAGE_CALLBACK_STRUCT mMessageCallbackStruct;

    STAFString    mProcess;
    STAFString    mQueryString;
    STAFString    mResultString;

    SChar         mProcessNum[128];

    //utISPApi      mISPApi;
    //utString      mString;
    //uttTime       mUttTime;

    SChar         mErrorBuffer[MSG_LEN];
    SChar         mStringBuffer[BUFFER_SIZE];

    SFloat        mFloatBuf;
    SDouble       mDoubleBuf;

    SChar         mUserName[MSG_LEN];
    SChar         mLoginUserName[MSG_LEN];
    SChar         mPassWord[MSG_LEN];

    idBool        mSetTiming;
    idBool        mSetHeading;
    idBool        mAutoCommit;
    idBool        mShowForeignKeys;
    SInt          mSessionKind;
    SInt          mIsqlReadTimeout;
    SDouble       mElapsedTime;

    idBool        mIsRealQuery;
    idBool        mIsSysdba;

    SChar         mTableName[MSG_LEN];
    SChar         mProcName[MSG_LEN];

    SChar         mDateFormat[MSG_LEN];

    SChar         mRealQuery[BUFFER_SIZE*4];
    SChar         mEnv[BUFFER_SIZE];

    //Symbol       *mSymbol;

    logonData     mLogonData;
    //uteErrorMgr   mErrorMgr;

    Servicer     *mServicer;
    SChar        *mMessage;
    STAFString    mTdxResult;

#if defined(STAF_OS_NAME_WIN32)
    HANDLE isql_i;
    HANDLE isql_o;
    SInt  isql_i_fd;
    HANDLE pid;
    int _fgets( SChar *aBuffer, int aSize, HANDLE *isql_i );
#else 
    FILE *isql_i;
    FILE *isql_o;
    SInt  isql_i_fd;
    pid_t pid;
#endif

    SInt ping();
};

#endif
