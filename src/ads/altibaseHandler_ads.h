/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id$
 **********************************************************************/

#ifndef _O_ALTIBASE_HANDLER_H_ 
#define _O_ALTIBASE_HANDLER_H_ 1

#include "common_ads.h"
#include "serviceManager_ads.h"
#include "serviceThread_ads.h"

#define MSG_LEN 2048

class AdsServicer;

class DBHandler
{
public:
    DBHandler( AdsServicer  *aServicer );
    ~DBHandler() {};

    IDE_RC      initialize();

    IDE_RC      destroy();

    IDE_RC      logon( SChar       *aDsn,
                       SChar       *aUser,
                       SChar       *aPasswd,
                       SChar       *aNls,
                       SInt         aPort,
                       SChar       *aConntype );

    IDE_RC      logout();

    IDE_RC      execute( SChar       *aBuffer, 
                         CommandKind  aCommandKind ); 

    IDE_RC      connectDB( SChar *aHost, 
                           SChar *aUserID,
                           SChar *aPasswd, 
                           SChar *aNLS,
                           SInt   aPort,
                           SInt   aConntype );

    void        disconnectDB();

    IDE_RC      executeDMLStmt( SChar        *aDDLStmt,
                                CommandKind   aCommandKind );

    IDE_RC      parsingExecProc( SChar  *aBuf,
                                 idBool  aIsFunc,
                                 SInt    aBufSize );

    IDE_RC      executePSMStmt( SChar *aPSMStmt,
                                SChar *aUserName,
                                SChar *aProcName,
                                idBool aIsFunc );

    idBool      executeSelectStmt( SChar *aCommandStr );

    IDE_RC      fetchSelectStmt( idBool aPrepare );

    void        setUser( STAFString aUser );
    void        setLoginUser( STAFString aLoginUser );
    void        setPassword( STAFString aPassWord );
    void        setProcName( STAFString aProcName);

    STAFString  getResult();

private:
    SChar         mErrorBuffer[MSG_LEN];
    SChar         mStringBuffer[BUFFER_SIZE];

    SFloat        mFloatVar;
    SDouble       mDoubleVar;

    SChar         mUserName[MSG_LEN];
    SChar         mLoginUserName[MSG_LEN];
    SChar         mPassWord[MSG_LEN];
    SChar         mProcName[MSG_LEN];

    SChar         mRealQuery[BUFFER_SIZE*4];
    SChar         mConnEnv[BUFFER_SIZE];

    STAFString    mQueryString;
    STAFString    mResultString;

    AdsServicer     *mServicer;

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
