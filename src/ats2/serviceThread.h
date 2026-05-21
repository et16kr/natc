/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: serviceThread.h 1021 2006-12-11 03:42:03Z ataf $
 **********************************************************************/

#ifndef _O_SERVICER_H_
#define _O_SERVICER_H_ 1

#include "common.h"
#include "serverManager.h"
#include "logManager.h"
#include "recpointManager.h"
#include "uttMemory.h"

#define ISQL_READ_TIMEOUT 600

class  Laborer;
struct ServiceData;
struct psTable;
struct queryData;

class Servicer : public atsBaseThread
{
    friend class Laborer; 

public:
    Servicer();
    ~Servicer() {};

    IDE_RC                     initialize( STAFServiceRequestLevel30 *aInfo,
                                           ServiceData               *aServiceData );
    IDE_RC                     destroy();

    IDE_RC                     load();
    void                       run();
    IDE_RC                     runReal( STAFString  aIn );
    IDE_RC                     runLaborer( STAFString aProcess );
    IDE_RC                     endLaborer();
    IDE_RC                     syncLaborer();
    IDE_RC                     runParseTable( psTable    *aPsTable, 
                                              STAFString  aIn, 
                                              STAFString *aPass );
    IDE_RC                     parseOption();

    IDE_RC                     sync( STAFString aProcess );
    IDE_RC                     sync();
    IDE_RC                     async();
    IDE_RC                     syncP0();
 
    IDE_RC                     saveRESULT( idBool *aPass = NULL );   
    IDE_RC                     saveTDX();
    IDE_RC                     saveREPORT( struct timeval aSval,
                                           struct timeval aEval,
                                           STAFString     aPass,
                                           STAFString     aIn);   

    SInt                       getElapsed( struct timeval *aSval,
                                           struct timeval *aEval );

    SInt                       lock();
    SInt                       unlock();

    void                       push_back( STAFString aProcess, 
                                          Laborer   *aLaborer, 
                                          queryData  aQuery );

    void                       debug( STAFString aIn );
    void                       system( STAFString aIn );

    IDE_RC                     getEnv();
    void                       getLogonData( logonData *aLogonData,
                                             STAFString aProcess );

    IDE_RC                     enqueueData( STAFString aIn, 
                                            STAFString aPass );

    IDE_RC                     mkdirLog();
    IDE_RC                     mkdir( STAFString aIn );
    IDE_RC                     link();
    IDE_RC                     unlink();
    STAFString                 getEnv4System( STAFString aAlias );
    STAFString                 getEnv4Rsystem( STAFString aAlias );
    STAFString                 getPath();
    IDE_RC                     getAgentData( STAFString   aID, 
                                             SChar      * aIP, 
                                             SInt       * aPort ); 

    void                       addEnv( STAFString aKey,
                                       STAFString aValue,
                                       STAFString aAlias );
    void                       rmEnv( STAFString aKey,
                                      STAFString aAlias );

    STAFString                 parseInnerSC( const SChar *aData, 
                                             UInt aFence );

    char                      *basename( const char *name );
    char                      *dirname( char *path );
    idBool                     exist( STAFString aIn );

    STAFString                 replace( STAFString aIn );
    STAFString                 replaceServicePort( STAFString aIn );

    IDE_RC                     loadCASE( STAFString aIn, 
                                         STAFString &aData );
    IDE_RC                     loadORACLE( STAFString aIn, 
                                           STAFString &aData );

    STAFString                 getPort( STAFString aPort );
    STAFString                 getReplicationPort( STAFString aPort );

    STAFString                 status(); 

    STAFString                 message() { return mMessage; };
    void                       clearFatal() { mIsFatal = ID_FALSE; };
    void                       setFatal() { mIsFatal = ID_TRUE; };
    idBool                     getFatal() { return mIsFatal; };
    void                       incrTdxTime( void ) { mTdxTime++; };
    UInt                       getTdxTime( void ) { return mTdxTime; };

    IDE_RC                     logValgrind( STAFString aIn,
                                            STAFString aServer );
    
    STAFString                 server( STAFString aAlias );
    
    /*  PRJ-1552  ART 복구테스트기능 관련 함수 */

    IDE_RC                     saveArtRESULT();      // ART 복구테스트결과 저장 : out, tdx
    ATSTestKind                getAtsTestKind();     // 복구테스트 타입 반환

    // HIT 여부 설정 및 반환
    void                       setHit( idBool aHit ) { mIsHit = aHit; };
    idBool                     getHit() { return mIsHit; };

     // CRASH 여부 설정 및 반환
    void                       setCrash( idBool aCrash ) { mIsCrash = aCrash; };
    idBool                     getCrash() { return mIsCrash; };

     // 서버재구동 여부 설정 및 반환
    void                       setArtRestart( idBool aRestart ) { mIsArtRestart = aRestart; };
    idBool                     getArtRestart() { return mIsArtRestart; };

    // 복구테스트 CRASH 발생시 $ALTIBASE_HOME에 대한 압축파일 경로
    STAFString                 getTGZpath() { return mTgz; };

    // ISQL_READ_TIMEOUT for valgrind
    UInt                       getIsqlReadTimeout() { return mISQL_READ_TIMEOUT; };

private:
    pthread_mutex_t         mMutex;

    LaborerList                mLaborer;
    LaborerQueryList           mQuery;

    idBool                     mEnd;

    STAFServiceRequestLevel30 *mService;
    ServiceData               *mServiceData;

    STAFString                 mIn;
    STAFString                 mRe;
    STAFString                 mTdx;
    STAFString                 mTgz;
    STAFString                 mLs;

    STAFString                 mInData;
    STAFString                 mReData;
    STAFString                 mTdxData;
    STAFString                 mLsData;

    SChar                      mSuite[1024];
    SChar                      mFullSuite[1024];
    SChar                      mComment[1024];
    SChar                      mLogname[1024];
    SChar                      mHostname[1024];

    ServerManager              mServer;
    ServerMap                  mServerMap;
    RsystemMap                 mRsystemMap;
 
    Logger                     mLogger;             

    STAFString                 mEnvPATH;
    STAFString                 mEnvLANG;
    STAFString                 mEnvHOME;
    STAFString                 mEnvPORT;
    STAFString                 mEnvIPC_PORT;
    STAFString                 mEnvNLS;
    STAFString                 mEnvCASE;
    STAFString                 mEnvCASE_USER;
    STAFString                 mEnvRESULT;
    STAFString                 mEnvSUFFIX_RE;
    STAFString                 mEnvSUFFIX_OR;
    STAFString                 mEnvAll;

    ServerAlias                mServerAlias;
    DefaultServer              mDefaultServer;
    DefaultType                mDefaultType;

    uttMemory                  mMemory;

    idBool                     mIgnore;
    STAFString                 mLink;
    STAFString                 mUnlink;
    STAFString                 mUnlink2;

    UInt                       mDEBUG;
    UInt                       mEVENT_TIMEOUT;
    UInt                       mMEMORY_TEST;
    UInt                       mISQL_READ_TIMEOUT;
    
    STAFString                 mBEGIN;
    STAFString                 mPROGRESS;

    STAFString                 mMessage;
    idBool                     mIsFatal;
    UInt                       mTdxTime;

    /*  PRJ-1552  ART 복구테스트기능 관련 멤버변수 */

    RecPointer                 mRecPointer;     // 복구지점관리자 
    recPointCache              mRecPointCache;  // 복구지점목록 STL map 저장

    STAFString                 mRECDATAFILE;    // 복구테스트 옵션중 복구지점파일경로
    STAFString                 mTESTTYPE;       // ATS 테스트타입
    
    /* Sequential Test에서 테스트할 복구지점 ID */    
    STAFString                 mRECPOINTID;    

    idBool                     mIsHit;          // 복구지점 비정상종료여부
    idBool                     mIsCrash;        // 재구동이후 복구실패여부

    /* 복구지점 비정상종료이후 재구동수행여부 */
    idBool                     mIsArtRestart;   
    
};

#endif
