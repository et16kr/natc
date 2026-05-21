/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: serviceThread.cpp 1337 2007-08-02 01:42:54Z upinel9 $
 **********************************************************************/

#include "serviceThread.h"
#include "serviceManager.h"
#include "laborerThread.h"
#include "pslx.h"
#include "psl.h"
#include "common.h"
#include <stdlib.h>

std::map<STAFString, ServerMap> gServerCache;

/* PRJ-1552
   복구지점목록에 대한 STL map 자료구조 */
std::map<STAFString, recPointCache> gRecPointCache;


extern int psparse( void *param );
void       addNode( pslx      *aPslx, 
                    nodeType   aType, 
                    STAFString aProcess );
void       addElement ( pslx       *aPslx, 
                        elementType aType, 
                        KeyMap      aKeyMap );

Servicer::Servicer()
#if defined(STAF_OS_NAME_HPUX) || defined(STAF_OS_NAME_AIX) || defined(STAF_OS_NAME_WIN32) || defined(STAF_OS_NAME_SOLARIS) || defined(STAF_OS_NAME_DEC) || defined(STAF_OS_NAME_LINUX)
: atsBaseThread( 10 * 1024 * 1024 )
#endif
{
}

IDE_RC          
Servicer::initialize( STAFServiceRequestLevel30 *aService,
                      ServiceData               *aServiceData )
{
    mTdxTime       = 0;
    mEnd           = ID_FALSE;
    mDEBUG         = 0;
    mEVENT_TIMEOUT = 30000;
    mMEMORY_TEST   = 0;
    mIgnore        = ID_FALSE;
    mIsFatal       = ID_FALSE;

    // PRJ-1552
    mIsHit         = ID_FALSE;
    mIsArtRestart  = ID_FALSE;
    mIsCrash       = ID_FALSE;

    mService       = aService;
    mServiceData   = aServiceData;

    memset( &mMutex, 0, ID_SIZEOF(mMutex) );
    IDE_TEST( pthread_mutex_init( &mMutex,
                                        NULL ) != 0 );

    IDE_TEST( getEnv() != IDE_SUCCESS );
    
    IDE_TEST( mkdirLog() != IDE_SUCCESS );

    IDE_TEST( mLogger.initialize( mEnvRESULT ) != IDE_SUCCESS );
                            
    mServerAlias["DEFAULT"] = "DEFAULT";
    mDefaultServer["P0"] = "DEFAULT";

    (void)mMemory.init();

    if ( getAtsTestKind() != ATS_TEST_NORMAL )
    {
        // PRJ-1552 복구테스트시 복구지점관리자 초기화
        IDE_TEST( mRecPointer.initialize(mEnvHOME) != IDE_SUCCESS );
    }
    
    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    debug( "initialize error" );

    return IDE_FAILURE;
}

IDE_RC          
Servicer::destroy()
{
    if ( getAtsTestKind() != ATS_TEST_NORMAL )
    {
        // PRJ-1552 복구테스트시 복구지점관리자 해제
        IDE_TEST( mRecPointer.destroy() != IDE_SUCCESS );
    }
    
    IDE_TEST( mLogger.destroy() != IDE_SUCCESS );
        
    IDE_TEST( mServer.destroy() != IDE_SUCCESS );

    (void)mMemory.freeAll();
    
    IDE_TEST( pthread_mutex_destroy( &mMutex ) != 0 );

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;
    
	debug( "destroy error" );

    return IDE_FAILURE;
}

IDE_RC          
Servicer::load()
{
    SChar               sData1[1024];
    STAFString          sData2;
    ServerParam         sServer1;
    ServerParam        *sServer2;
    ServerParam         sServer3;
    ServerParamIterator sIterator;
    ParamIterator       sIterator3;
    UInt                sLevel = 0;
    STAFString          sAgentConf;
    FILE               *sIn = NULL;
    SChar               sLine[1024];
    rsystemData         sRsystem; 
    UInt                a = 0;
  
    IDE_TEST( mServer.initialize() != IDE_SUCCESS );
    
    // server.conf 파일을 로드한다.
    copyData( sData1, 
              mIn.buffer(),
              mIn.length() );

    sData2 = mEnvCASE + FILE_SEPARATORS + "conf" + FILE_SEPARATORS + SERVER_FILE;

    IDE_TEST( ServiceManager::lock() != 0 );
    sLevel = 1;

    if( (gServerCache.find( sData2 ) == gServerCache.end()) ||
        (mBEGIN.asUInt() == 1) )
    {
        copyData( sData1,
                  sData2.buffer(),
                  sData2.length() );

        IDE_TEST( mServer.load( sData1 ) != IDE_SUCCESS );

        mServerMap = (*mServer.getList());

        gServerCache[sData2] = mServerMap;

        debug( "load server.conf" );
    }
    else
    {
        mServerMap = gServerCache[sData2];
    }

    /* PRJ-1552 복구테스트 중
       Regression TEST 와 Sequential TEST의 경우 복구지점목록에
       대한 STL map을 필요로 함 */
    
    if ( ( getAtsTestKind() == ATS_TEST_REGRESSIVE ) ||
         ( getAtsTestKind() == ATS_TEST_SEQUENTIAL ) )
    {
        // recovery.dat 파일을 로드한다.
        copyData( sData1, mRECDATAFILE.buffer(), mRECDATAFILE.length() );

       /* PRJ-1552 복구지점목록의 STL map을 로딩하는 함수
          최초에는 복구지점파일을 판독해서 로딩하고,
          그 이후에는 최초 로딩된 STL map을 사용하게 됨 */        
        if( (gRecPointCache.find( sData1 ) == gRecPointCache.end()) ||
            (mBEGIN.asUInt() == 1) )
        {
            IDE_TEST( mRecPointer.load( sData1 ) != IDE_SUCCESS );
            
            mRecPointCache.recpointMap  = (*mRecPointer.getMap());
            
            gRecPointCache[sData1] = mRecPointCache;
        }
        else
        {
            mRecPointCache = gRecPointCache[sData1];
        }
    }
    else
    {
        // ats normal test
        // ats full static point test
    }
    
    sLevel = 0;
    IDE_TEST( ServiceManager::unlock() != 0 );

    // 각 서버는 DEFAULT 서버의 환경을 상속받는다.
    (mServerMap)["DEFAULT"]["ALTIBASE_HOME"] = mEnvHOME;
    (mServerMap)["DEFAULT"]["PATH"] = mEnvPATH;
    (mServerMap)["DEFAULT"]["LANG"] = mEnvLANG;
    (mServerMap)["DEFAULT"]["ATAF_TEST_RESULT"] = mEnvRESULT;
    (mServerMap)["DEFAULT"]["ATC_HOME"] = mEnvCASE;
    (mServerMap)["DEFAULT"]["ATC_WORK"] = mEnvRESULT;
  
    // a=b b=c c=d 
    for( a = 0; a < mEnvAll.numWords(); a++ )
    {
        // a=b -> a b
        STAFString sEnv = mEnvAll.subWord( a, 1 ).replace( "=", " " );
    
        (mServerMap)["DEFAULT"][sEnv.subWord( 0, 1 )] = sEnv.subWord( 1, 1 );
    }

    sServer1 = (mServerMap)["DEFAULT"];

    for( sIterator = mServerMap.begin();
         sIterator != mServerMap.end();
         sIterator++ )
    {
        if( sIterator->first != "DEFAULT" )
        {
            sServer2 = &(sIterator->second);
            sServer3 = sIterator->second;

            for( sIterator3 = sServer1.begin();
                 sIterator3 != sServer1.end();
                 sIterator3++ )
            {
                if( sServer3[sIterator3->first].length() == 0 )
                {
                    (*sServer2)[sIterator3->first] = sIterator3->second; 
                }
            }
        }
    }

    sAgentConf = mEnvCASE + FILE_SEPARATORS + "conf" + FILE_SEPARATORS + "tagent.conf";

    copyData( sData1, 
              sAgentConf.buffer(), 
              sAgentConf.length() );
   
    sIn = fopen( sData1, "r" );

    if( sIn != NULL )
    {
        while( 1 )
        {
            if( fgets( sLine, ID_SIZEOF(sLine), sIn ) != NULL )
            {
                sData2 = STAFString( sLine ).strip();
                if( sData2.length() == 0 )
                {
                    continue;
                }
                if( sData2.buffer()[0] == '#' )
                {
                    continue;
                }

                sData2 = sData2.replace( "@", " " ).replace( ":", " " );

                copyData( sRsystem.ip,
                          sData2.subWord( 1, 1 ).buffer(),
                          sData2.subWord( 1, 1 ).length() );

                sRsystem.port = sData2.subWord( 2, 1 ).asUInt();

                mRsystemMap[sData2.subWord( 0, 1 )] = sRsystem ;
            }
            else
            {
                break;
            }
        }

        fclose( sIn );
    }
 
    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    if( sLevel != 0 )
    {
        (void)ServiceManager::unlock();
    }
	
	debug( "load error" );

    return IDE_FAILURE;
}

IDE_RC 
Servicer::endLaborer()
{
    UInt            sLevel = 0;
    Laborer        *sLaborer = NULL;
    LaborerIterator sIterator;

    IDE_TEST( lock() != IDE_SUCCESS );
    sLevel = 1;

    for( sIterator  = mLaborer.begin();
         sIterator != mLaborer.end();
         sIterator++ )
    {
        sLaborer = sIterator->second;

        IDE_TEST( sLaborer->destroy() != IDE_SUCCESS );

        delete sLaborer;

        sLaborer = NULL;
    }

    mLaborer.clear();

    sLevel = 0;
    IDE_TEST( unlock() != IDE_SUCCESS );

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    if( sLevel != 0 )
    {
        (void)unlock();
    }
	
	debug( "endLaborer error" );

    return IDE_FAILURE;
}

IDE_RC
Servicer::syncLaborer()
{
    Laborer        *sLaborer = NULL;
    LaborerIterator sIterator;

    sync();

    for( sIterator  = mLaborer.begin();
         sIterator != mLaborer.end();
         sIterator++ )
    {
        sLaborer = sIterator->second;

        IDE_TEST( sLaborer->end() != IDE_SUCCESS );

        IDE_TEST( pthread_join( sLaborer->getTid(),
                                NULL ) != IDE_SUCCESS );
    }
    
    return IDE_SUCCESS;

    IDE_EXCEPTION_END;
	
	debug( "syncLaborer error" );

    return IDE_FAILURE;
}

IDE_RC
Servicer::runLaborer( STAFString aProcess )
{
    logonData sLogonData;
    Laborer  *sLaborer = NULL;
    QueryList sQuery;
    UInt      sLevel = 0;

    (void)getLogonData( &sLogonData, 
                        aProcess ); 

    sLaborer = new Laborer;

    IDE_TEST( sLaborer == NULL );

    IDE_TEST( sLaborer->initialize( this,
                                    aProcess, 
                                    sLogonData ) != IDE_SUCCESS );

    IDE_TEST( sLaborer->start() != IDE_SUCCESS );

    IDE_TEST( sLaborer->waitToStart() != IDE_SUCCESS );

    IDE_TEST( lock() != IDE_SUCCESS );
    sLevel = 1;

    mLaborer[aProcess] = sLaborer;
    mQuery[aProcess] = sQuery;
    
    sLevel = 0;
    IDE_TEST( unlock() != IDE_SUCCESS );

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    if( sLevel != 0 )
    {
        (void)unlock();
    }

    debug( "runLaborer error" );

    return IDE_FAILURE;
}

IDE_RC
Servicer::parseOption()
{
    // 사용자가 지정한 옵션을 얻어온다.
    // staf local ats run a.sql ts a.ts comment test logname orc hostname v880
    STAFResultPtr             sResult;
    STAFCommandParseResultPtr sParsedResult;

    sParsedResult = mServiceData->runParser->parse( mService->request );

    IDE_TEST( sParsedResult->rc != kSTAFOk )

    sResult = ServiceManager::resolveOption( mService,
                                             mServiceData,
                                             sParsedResult,
                                             "RUN");
    IDE_TEST( sResult->rc != 0 );
    mIn = sResult->result;

    sResult = ServiceManager::resolveOption( mService,
                                             mServiceData,
                                             sParsedResult,
                                             "TS");
    IDE_TEST( sResult->rc != 0 );
    copyData( mSuite,
              sResult->result.strip().buffer(),
              sResult->result.strip().length() );

    sResult = ServiceManager::resolveOption( mService,
                                             mServiceData,
                                             sParsedResult,
                                             "FULLTS");
    IDE_TEST( sResult->rc != 0 );
    copyData( mFullSuite,
              sResult->result.strip().buffer(),
              sResult->result.strip().length() );

    sResult = ServiceManager::resolveOption( mService,
                                             mServiceData,
                                             sParsedResult,
                                             "COMMENT");
    IDE_TEST( sResult->rc != 0 );
    copyData( mComment,
              sResult->result.strip().toCurrentCodePage()->buffer(),
              sResult->result.strip().toCurrentCodePage()->length() );

    sResult = ServiceManager::resolveOption( mService,
                                             mServiceData,
                                             sParsedResult,
                                             "LOGNAME");
    IDE_TEST( sResult->rc != 0 );
    copyData( mLogname,
              sResult->result.strip().toCurrentCodePage()->buffer(),
              sResult->result.strip().toCurrentCodePage()->length() );

    sResult = ServiceManager::resolveOption( mService,
                                             mServiceData,
                                             sParsedResult,
                                             "HOSTNAME");
    IDE_TEST( sResult->rc != 0 );
    copyData( mHostname,
              sResult->result.strip().toCurrentCodePage()->buffer(),
              sResult->result.strip().toCurrentCodePage()->length() );

    sResult = ServiceManager::resolveOption( mService,
                                             mServiceData,
                                             sParsedResult,
                                             "LINK");
    IDE_TEST( sResult->rc != 0 );
    mLink = sResult->result;

    sResult = ServiceManager::resolveOption( mService,
                                             mServiceData,
                                             sParsedResult,
                                             "UNLINK");
    IDE_TEST( sResult->rc != 0 );

    mUnlink = sResult->result.replace( mEnvCASE, mEnvRESULT );

    sResult = ServiceManager::resolveOption( mService,
                                             mServiceData,
                                             sParsedResult,
                                             "UNLINK2");
    IDE_TEST( sResult->rc != 0 );
    mUnlink2 = sResult->result.replace( mEnvCASE, mEnvRESULT );

    sResult = ServiceManager::resolveOption( mService,
                                             mServiceData,
                                             sParsedResult,
                                             "BEGIN");
    IDE_TEST( sResult->rc != 0 );
    mBEGIN = sResult->result;

    sResult = ServiceManager::resolveOption( mService,
                                             mServiceData,
                                             sParsedResult,
                                             "PROGRESS");
    IDE_TEST( sResult->rc != 0 );
    mPROGRESS = sResult->result;

    /* PRJ-1552 복구테스트 관련 추가된 옵션
       RECDATAFILE : 복구지점목록파일경로
       TESTTYPE    : 테스트타입
       RECPOINTID  : 복구지점ID */
    sResult = ServiceManager::resolveOption( mService,
                                             mServiceData,
                                             sParsedResult,
                                             "RECDATAFILE");
    IDE_TEST( sResult->rc != 0 );
    mRECDATAFILE = sResult->result;

    sResult = ServiceManager::resolveOption( mService,
                                             mServiceData,
                                             sParsedResult,
                                             "TESTTYPE");
    IDE_TEST( sResult->rc != 0 );
    mTESTTYPE = sResult->result;

    sResult = ServiceManager::resolveOption( mService,
                                             mServiceData,
                                             sParsedResult,
                                             "RECPOINTID");
    IDE_TEST( sResult->rc != 0 );

    /* 복구지점ID의 경우는 string 규약으로
       인해서 약간의 변환이 필요하다 */
    mRECPOINTID = sResult->result.replace("^", ":");

    return IDE_SUCCESS;

    IDE_EXCEPTION_END ;
    
    debug( "parseOption error" );

    return IDE_FAILURE;
}

void            
Servicer::run()
{
    IDE_TEST( parseOption() != IDE_SUCCESS ); 

    IDE_TEST( load() != IDE_SUCCESS ); 

    IDE_TEST( runReal( mIn ) != IDE_SUCCESS );

    IDE_TEST( endLaborer() != IDE_SUCCESS );

    return;

    IDE_EXCEPTION_END;
	
	debug( "run error" );
    
    return;
}

SInt
Servicer::lock()
{
    return pthread_mutex_lock( &mMutex );
}

SInt
Servicer::unlock()
{
    return pthread_mutex_unlock( &mMutex );
}

IDE_RC
Servicer::runReal( STAFString  aIn )
{
    FILE          *sIn = NULL;
    SChar          sLine[65536];
    pslx           sInput;
    psNode         sNode;
    psElement      sElement;
    psLexer       *sLexer = NULL;
    UInt           sSector = 0;
    UInt           sSize = 0;
    SChar         *sData = NULL;
    STAFString     sData1;
    STAFString     sData2;
    STAFString     sError;
    struct timeval sSval;
    struct timeval sEval;
    STAFString     sPass;
    STAFString     sLs;

    if( mDEBUG == 1 )
    {
        debug( STAFString("run: ") + aIn );
    }
    
    gettimeofday( &sSval, NULL );

    if( (aIn.find( mEnvCASE )      == STAFString::kNPos) &&
        (aIn.find( mEnvCASE_USER ) == STAFString::kNPos) )
    {
        mRe = aIn.replace( ".sql", 
                            mEnvSUFFIX_RE + ".out" ); 

        mTdx = aIn.replace( ".sql", 
                            mEnvSUFFIX_RE + ".tdx" ); 

        /* 복구테스트 CRASH가 발생한 경우 $ALTIBASE_HOME에 대한
           압축할 파일 경로 */
        mTgz = aIn.replace( ".sql", 
                            mEnvSUFFIX_RE + ".tgz" ); 

        mLs = aIn.replace( ".sql", 
                            STAFString("_A4_64") + ".lst" );

        for( UInt a = 0; a < mEnvSUFFIX_OR.numWords(); a++ )
        {
            sLs = aIn.replace( ".sql", 
                               mEnvSUFFIX_OR.subWord(a,1).strip() + ".lst" );

            if( exist( sLs ) == ID_TRUE )
            {
                mLs = sLs;
                //fix BUG-14326
                //break;
            }
        }
    }
    else
    {
        if( (aIn.find( mEnvCASE ) == STAFString::kNPos) )
        {
            mRe = aIn.replace( mEnvCASE_USER, "" );
            mTdx = aIn.replace( mEnvCASE_USER, "" );
            mTgz = aIn.replace( mEnvCASE_USER, "" );
        }
        else
        {
            mRe = aIn.replace( mEnvCASE, "" );
            mTdx = aIn.replace( mEnvCASE, "" );
            mTgz = aIn.replace( mEnvCASE, "" );
        }

        //mRe = mEnvRESULT + FILE_SEPARATORS + mRe; 
        mRe = mEnvRESULT + mRe; 
        mRe = mRe.replace( ".sql", 
                             mEnvSUFFIX_RE + ".out" ); 

        mTdx = mEnvRESULT + mTdx; 
        mTdx = mTdx.replace( ".sql", 
                            mEnvSUFFIX_RE + ".tdx" ); 

        /* 복구테스트 CRASH가 발생한 경우 $ALTIBASE_HOME에 대한
           압축할 파일 경로 */
        mTgz = mEnvRESULT + mTgz; 
        mTgz = mTgz.replace( ".sql", 
                            mEnvSUFFIX_RE + ".tgz" ); 

        mLs = aIn.replace( ".sql", 
                             STAFString("_A4_64") + ".lst" );

        for( UInt a = 0; a < mEnvSUFFIX_OR.numWords(); a++ )
        {
            sLs = aIn.replace( ".sql", 
                               mEnvSUFFIX_OR.subWord(a,1).strip() + ".lst" );

            if( exist( sLs ) == ID_TRUE )
            {
                mLs = sLs;
                //fix BUG-14326
                //break;
            }
        }

        unlink();
        mkdir( mRe );
        link();
    }

    //cout << "In:" << mIn << endl;
    //cout << "Re:" << mRe << endl;
    //cout << "Ls:" << mLs << endl << endl;

    copyData( sLine, 
              aIn.buffer(),  
              aIn.length() );

    // 테스트 케이스를 로드한다.
    // LOAD_SQL 처리를 위해서 재귀적으로 호출된다.
    IDE_TEST_RAISE( loadCASE( basename(sLine), 
                              mInData ) != IDE_SUCCESS, error_load_sql );
 
    // 테스트 오라클을 로드한다. 
    IDE_TEST_RAISE( loadORACLE( mLs, 
                                mLsData ) != IDE_SUCCESS, error_load_oracle );

    sSize = mInData.toCurrentCodePage()->length();
    sData = (char *)mMemory.alloc( sSize + 1 );
    copyData( sData,
              mInData.toCurrentCodePage()->buffer(),
              sSize );

    sLexer = new psLexer( sData, 
                          sSize );
  
    sInput.lexer = sLexer;
    sInput.parseTable = NULL;

    sInput.parseTable = new psTable;

    sInput.parseTable->memory = &mMemory; 
    sInput.parseTable->nodeCursor = -1;
    sInput.parseTable->text = sData;

    /* PRJ-1552에서 복구지점목록의 STL map을 Parse Table에서
       접근할 수 있도록 설정함.
       구문파싱시 복구지점 ID를 해당 filename과 linenum으로
       매핑시켜주기 위함 */
    sInput.parseTable->recpointCache = &mRecPointCache; 

    (void)addNode( &sInput, 
                   TYPE_NORMAL, 
                   "P0" );

    IDE_TEST_RAISE( psparse( &sInput ) != IDE_SUCCESS, error_parse );

    IDE_TEST_RAISE( runParseTable( sInput.parseTable, 
                                   aIn,
                                   &sPass ) != IDE_SUCCESS, error_run );

    // fix for memory leak !!
    delete sLexer;
    delete sInput.parseTable;

    gettimeofday( &sEval, NULL );

    saveREPORT( sSval, 
                sEval, 
                sPass, 
                aIn );

    if( mUnlink2.strip().length() != 0 )
    {
        mUnlink = mUnlink2;
        unlink();
    }

    return IDE_SUCCESS;

    IDE_EXCEPTION( error_load_sql );
    {
        sError = "load sql error: ";
        sError += aIn;
        sError += " ";
        sError += errno;
        debug( sError );
        
        mReData = sError;
    }
    IDE_EXCEPTION( error_load_oracle );
    {
        sError = "load oracle error: ";
        sError += mLs;
        sError += " ";
        sError += errno;
        debug( sError );
        
        mReData = sError;
    }
    IDE_EXCEPTION( error_memory );
    {
        sError = "memory error: ";
        sError += errno;
        debug( sError );
        
        mReData = sError;
    }
    IDE_EXCEPTION( error_parse );
    {
        sError = "parse error: ";
        sError += sInput.parseTable->error.subString(0, 1024);
        debug( sError );
        
        mReData = sInput.parseTable->error;
    }
    IDE_EXCEPTION( error_run );
    {
        sError = "run error: ";
        sError += aIn;
        debug( sError );
        
        mReData = sError;
    }
    IDE_EXCEPTION_END;
    
    gettimeofday( &sEval, NULL );

    sPass = "ERROR";
    
    saveREPORT( sSval, 
                sEval, 
                sPass, 
                aIn );

    saveRESULT();
    enqueueData( aIn, 
                 "ERROR" );

    if( mUnlink2.strip().length() != 0 )
    {
        mUnlink = mUnlink2;
        unlink();
    }    
	
	debug( "runReal error" );
    
    return IDE_SUCCESS;
}

void 
addNode( pslx      *aPslx, 
         nodeType   aType, 
         STAFString aProcess )
{
    psNode sNode;

    sNode.type = aType;
    sNode.process = aProcess;

    aPslx->parseTable->nodeList.push_back( sNode ); 
    aPslx->parseTable->nodeCursor++;
}

void 
addElement( pslx       *aPslx, 
            elementType aType, 
            KeyMap      aKeyMap )
{
    psNode   *sNode;
    psElement sElement;

    sElement.type = aType;
    sElement.keyMap = aKeyMap;

    sNode = &(aPslx->parseTable->nodeList[aPslx->parseTable->nodeCursor]);
    sNode->elementList.push_back( sElement );
}

IDE_RC 
Servicer::runParseTable( psTable    *aPsTable, 
                         STAFString  aIn,
                         STAFString *aPass )  
{
    Laborer        *sLaborer = NULL;
    queryData       sData;
    NodeIterator    sNIterator;
    ElementIterator sEIterator;
    psNode          sNode;
    psElement       sElement;
    UInt            sCycle1 = 0; 
    UInt            sCycle2 = 0; 
    STAFString      sEnv; 
    STAFString      sEnv1; 
    STAFString      sEnv2; 
    STAFString      sEnv3; 
    idBool          sPass = ID_FALSE;
    SChar           sFatalData[65536];
    STAFString      sFatalData2;
    idBool          sIsEnableRecPtr = ID_FALSE;

    if( mMEMORY_TEST == 1 )
    {
        (void)logValgrind( aIn, "DEFAULT" );
    }

    for( sNIterator  = aPsTable->nodeList.begin();
         sNIterator != aPsTable->nodeList.end();
         sNIterator++ )
    {
        sNode = *sNIterator;

        if( sNode.type == TYPE_NORMAL )
        {
            if( mLaborer.find(sNode.process) == mLaborer.end() )
            {
                IDE_TEST( runLaborer( sNode.process ) != IDE_SUCCESS );
            }
            sLaborer = mLaborer[sNode.process];

            /* PRJ-1552
               ART 복구테스트 중에
               1) Sequential Test
               2) Full Test
               에서는 아래와 같이 강제로 복구지점(들)을 활성화시킬수
               있게 Command를 추가해주어야 함 */
            
            if ( sIsEnableRecPtr == ID_FALSE )
            {  
                if ( getAtsTestKind() == ATS_TEST_SEQUENTIAL )
                { 
                if ( ((aPsTable->recpointCache)->recpointMap).find(mRECPOINTID)
                    != ((aPsTable->recpointCache)->recpointMap).end() )
                    {
                        sData.type  = RECPOINT_COM;
                        sData.query = ((aPsTable->recpointCache)->recpointMap)[mRECPOINTID].queryString;
                        sData.table      = "enable_recptr";
                        sData.user       = "";
                        sData.realQuery  = "--+TEST_RECPTR ENABLE";
                        sData.realQuery += " '" + mRECPOINTID + "',";
                        sData.realQuery += " 'KILL', 0, 0, 0;\n";

                        push_back( sNode.process, sLaborer, sData );

                        sIsEnableRecPtr = ID_TRUE;
                    }
                    else
                    {
                       // nothing to do
                    }
                }
                else if ( getAtsTestKind() == ATS_TEST_FULL ) 
                {
                    sData.type  = RECPOINT_COM;
                    sData.query = "execute enableall_recptrs()";
                    sData.table      = "enableall_recptrs";
                    sData.user       = "";
                    sData.realQuery  = "--+TEST_RECPTR ENABLEALL;\n";

                    push_back( sNode.process, sLaborer, sData );
                    sIsEnableRecPtr = ID_TRUE;
                }
            }

            for( sEIterator  = sNode.elementList.begin(); 
                 sEIterator != sNode.elementList.end();
                 sEIterator++ )
            {
                sElement = *sEIterator;
                sData.loc = sElement.keyMap["loc"].asUInt();

                switch( sElement.type )
                {
                    case TYPE_CONNECT:
                    {
                        sData.type     = CONNECT_COM;
                        sData.query    = sElement.keyMap["key1"];
                        sData.user     = sElement.keyMap["key2"];
                        sData.password = sElement.keyMap["key3"];
                        sData.sysdba   = sElement.keyMap["key4"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_DISCONNECT:
                    {
                        sData.type  = DISCONNECT_COM;
                        sData.query = sElement.keyMap["key1"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_AUTOCOMMIT:
                    {
                        sData.type  = AUTOCOMMIT_COM;
                        sData.query = sElement.keyMap["key1"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_SPOOL:
                    {
                        break;
                    }
                    case TYPE_START:
                    {
                        if( sElement.keyMap["key2"] == "type1" )
                        {
                            sData.type  = START1_COM;
                            sData.sysdba = sElement.keyMap["key3"];
                        }
                        else
                        {
                            sData.type  = START2_COM;
                        }
                        sData.query = sElement.keyMap["key1"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_SET:
                    {
                        sEnv = sElement.keyMap["key1"];
                        sEnv = sEnv.upperCase().strip();

                        if( sEnv.subWord( 1, 1 ) == "TIMING" )
                        {
                            sData.type  = TIMING_COM;
                            sData.query = sElement.keyMap["key1"];
                            push_back( sNode.process, 
                                       sLaborer, 
                                       sData );
                        }
                        else if( sEnv.subWord( 1, 1 ) == "FOREIGNKEYS" )
                        {
                            sData.type  = FOREIGNKEYS_COM;
                            sData.query = sElement.keyMap["key1"];
                            push_back( sNode.process, 
                                       sLaborer, 
                                       sData );
                        }
                        else if( sEnv.subWord( 1, 1 ) == "TRANSACTION" )
                        {
                            sData.type  = SET_TRANSACTION_COM;
                            sData.query = sElement.keyMap["key1"];
                            push_back( sNode.process, 
                                       sLaborer, 
                                       sData );
                        }
                        else if( sEnv.subWord( 0, 1 ) == "SET_RESTART" )
                        {
                            sData.type  = RESTART_COM;
                            sData.query = "--+"; 
                            sData.query += sEnv; 
                            push_back( sNode.process,  
                                       sLaborer, 
                                       sData );
                        }
                        else if( sEnv.subWord( 1, 1 ) == "HEADING" )
                        {
                            sData.type  = HEADING_COM;
                            sData.query = sElement.keyMap["key1"];
                            push_back( sNode.process, 
                                       sLaborer, 
                                       sData );
                        }
                        else if( sEnv.subWord( 1, 1 ).find( "AGER" ) 
                                                    != STAFString::kNPos )
                        {
                            sData.type  = SET_AGER_COM;
                            sData.query = sElement.keyMap["key1"];
                            push_back( sNode.process, 
                                       sLaborer, 
                                       sData );
                        }
                        else if( sEnv.subWord( 1, 1 ).find( "VERTICAL" ) 
                                                    != STAFString::kNPos )
                        {
                            sData.type  = SET_VERTICAL_COM;
                            sData.query = sElement.keyMap["key1"];
                            push_back( sNode.process, 
                                       sLaborer, 
                                       sData );
                        }
                        else
                        {
                            sData.type  = STRING_COM;
                            sData.query = STAFString("$") + sNode.process + "> "; 
                            sData.query += sElement.keyMap["key1"] + ";";
                            push_back( sNode.process, 
                                       sLaborer, 
                                       sData );
                        }
                        break;
                    }
                    case TYPE_VARIABLE:
                    {
                        sData.type             = SYMBOL_COM;
                        sData.query            = sElement.keyMap["key1"];
                        sData.symbol.name      = sElement.keyMap["key2"];
                        sData.symbol.type      = sElement.keyMap["key3"];
                        sData.symbol.precision = sElement.keyMap["key4"];
                        sData.symbol.scale     = sElement.keyMap["key5"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_EXECUTE:
                    {
                        sData.type   = EXECUTE_COM;
                        sData.query  = sElement.keyMap["key1"];
                        sData.user   = sElement.keyMap["key2"];
                        sData.sysdba = sElement.keyMap["key3"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_EXECUTE_FUNCTION:
                    {
                        sData.type  = EXEC_FUNC_COM;
                        sData.query = sElement.keyMap["key1"];
                        sData.table = sElement.keyMap["key2"];
                        sData.user  = sElement.keyMap["key3"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_EXECUTE_PROCEDURE:
                    {
                        sData.type  = EXEC_PROC_COM;
                        sData.query = sElement.keyMap["key1"];
                        sData.table = sElement.keyMap["key2"];
                        sData.user  = sElement.keyMap["key3"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_TEST_RECPTR:
                    {
                        /* PRJ-1552 ART 복구테스트 기능에서
                           복구지점 관련하여  다음과 같이
                           QueryData 생성후 Laborer에 전달 */
                        
                        sData.type      = RECPOINT_COM;
                        sData.query     = sElement.keyMap["key1"];
                        sData.table     = sElement.keyMap["key2"];
                        sData.user      = sElement.keyMap["key3"];
                        sData.realQuery = sElement.keyMap["key4"];

                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );

                        break;
                    }
                    case TYPE_PRINT:
                    {
                        sData.type  = PRINT_COM;
                        sData.query = sElement.keyMap["key1"];
                        sData.sysdba = sElement.keyMap["key2"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_SHELL:
                    {
                        sData.type  = SHELL_COM;
                        sData.query = sElement.keyMap["key1"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_DECLARE:
                    {
                        sData.type  = STRING_COM;
                        if( sElement.keyMap["key1"].upperCase() == "SERVER" )
                        {
                            sData.query = "--+DECLARE ";
                            sData.query += sElement.keyMap["key1"];
                            sData.query += " ";
                            sData.query += sElement.keyMap["key2"];
                            sData.query += " ";
                            sData.query += sElement.keyMap["key3"];
                            sData.query += ";  ";

                            mServerAlias[sElement.keyMap["key3"]] = sElement.keyMap["key2"];
                            if( mMEMORY_TEST == 1 )
                            {
                                (void)logValgrind( aIn, sElement.keyMap["key2"] );
                            }
                        }
                        else
                        {
                            sData.query = "--+DECLARE ";
                            sData.query += sElement.keyMap["key1"];
                            sData.query += " ";
                            sData.query += sElement.keyMap["key2"];
                            sData.query += " ";
                            sData.query += sElement.keyMap["key3"];
                            sData.query += "(";
                            sData.query += sElement.keyMap["key4"];
                            sData.query += "=";
                            sData.query += sElement.keyMap["key5"];
                            sData.query += ");  ";
                          
                            if( sElement.keyMap["key4"] != "ISQL_CONNECTION" )
                            { 
                                mDefaultServer[sElement.keyMap["key3"]] = sElement.keyMap["key5"];
                            }
                            else
                            {
                                mDefaultType[sElement.keyMap["key3"]] = sElement.keyMap["key5"];
                            }
                        }
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_APPEND_LST:
                    {
                        sData.type  = APPEND_COM;
                        sData.query = sElement.keyMap["key1"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_LOAD_SQL:
                    {
                        //sData.type  = START2_COM;
                        //sData.query = sElement.keyMap["key1"];
                        //push_back( sNode.process, 
                        //sLaborer, 
                        //sData );
                        break;
                    }
                    case TYPE_SYSTEM:
                    {
                        sData.type  = SYSTEM_COM;
                        sData.query = sElement.keyMap["key1"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_RSYSTEM:
                    {
                        sData.type  = RSYSTEM_COM;
                        sData.query = sElement.keyMap["key1"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_SET_ENV:
                    {
                        sData.type  = STRING_COM;
                        sData.query = "--+SET_ENV ";
                        sData.query += sElement.keyMap["key1"];
                        sData.query += ";";
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        
                        sData.type  = ENV_COM;
                        sData.query = sElement.keyMap["key1"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_COMMENT:
                    {
                        sData.type  = STRING_COM;
                        sData.query = sElement.keyMap["key1"] + "\n";
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_SECTOR:
                    {
                        sCycle2++;

                        sData.type  = STRING_COM;
                        sData.query = "--+";
                        sData.query += STAFString( sElement.keyMap["key2"] ).upperCase();
                        sData.query += " ";
                        sData.query += STAFString( sCycle2 );
                        sData.query += ";";
                        sData.query += STAFString( sElement.keyMap["key1"] );
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_SKIP:
                    {
                        sData.type  = SKIP_COM;
                        sData.query = sElement.keyMap["key1"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_IGNORE:
                    {
                        mIgnore = ID_TRUE;
                        break;
                    }
                    case TYPE_POST:
                    {
                        sData.type  = POST_COM;
                        sData.query = sElement.keyMap["key1"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_WAIT:
                    {
                        sData.type  = WAIT_COM;
                        sData.query = sElement.keyMap["key1"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_TABLES:
                    {
                        sData.type  = TABLES_COM;
                        sData.query = sElement.keyMap["key1"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_XTABLES:
                    {
                        sData.type  = XTABLES_COM;
                        sData.query = sElement.keyMap["key1"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_DTABLES:
                    {
                        sData.type  = DTABLES_COM;
                        sData.query = sElement.keyMap["key1"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_VTABLES:
                    {
                        sData.type  = VTABLES_COM;
                        sData.query = sElement.keyMap["key1"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_SEQUENCE:
                    {
                        sData.type  = SEQUENCE_COM;
                        sData.query = sElement.keyMap["key1"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_INSERT:
                    {
                        sData.type  = INSERT_COM;
                        sData.query = sElement.keyMap["key1"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_CREATE:
                    {
                        sData.type  = CREATE_OBJ_COM;
                        sData.query = sElement.keyMap["key1"];
                        sData.realQuery = replace(sElement.keyMap["key1"]);
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_CREATE_OBJECT:
                    {
                        sData.type      = CREATE_PROC_COM;
                        sData.query     = sElement.keyMap["key1"];
                        sData.realQuery = sElement.keyMap["key2"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_MOVE:
                    {
                        sData.type  = MOVE_COM;
                        sData.query = sElement.keyMap["key1"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_COMMIT:
                    {
                        sData.type  = COMMIT_COM;
                        sData.query = sElement.keyMap["key1"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_ABORT:
                    {
                        sData.type  = ROLLBACK_COM;
                        sData.query = sElement.keyMap["key1"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_SAVEPOINT:
                    {
                        sData.type  = SAVEPOINT_COM;
                        sData.query = sElement.keyMap["key1"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_DROP:
                    {
                        sData.type  = DROP_COM;
                        sData.query = sElement.keyMap["key1"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_GRANT:
                    {
                        sData.type  = GRANT_COM;
                        sData.query = sElement.keyMap["key1"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_REVOKE:
                    {
                        sData.type  = REVOKE_COM;
                        sData.query = sElement.keyMap["key1"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_ENQUEUE:
                    {
                        sData.type  = ENQUEUE_COM;
                        sData.query = sElement.keyMap["key1"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_DEQUEUE:
                    {
                        sData.type  = DEQUEUE_COM;
                        sData.query = sElement.keyMap["key1"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_ALTER:
                    {
                        sData.type  = ALTER_COM;
                        sData.query = sElement.keyMap["key1"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_RENAME:
                    {
                        sData.type = RENAME_COM;
                        sData.query = sElement.keyMap["key1"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_TRUNCATE:
                    {
                        sData.type  = TRUNCATE_COM;
                        sData.query = sElement.keyMap["key1"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_LOCK:
                    {
                        sData.type  = LOCK_COM;
                        sData.query = sElement.keyMap["key1"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_PREPARE:
                    {
                        sData.query = sElement.keyMap["key1"];
                        sData.realQuery = sElement.keyMap["key2"];
                        if( sData.query.subWord(1,1) == "INSERT" ||
                            sData.query.subWord(1,1) == "insert" )
                        {
                            sData.type  = PREP_INSERT_COM;
                        }  
                        else if( sData.query.subWord(1,1) == "SELECT" ||
                                 sData.query.subWord(1,1) == "select" )
                        {
                            sData.type  = PREP_SELECT_COM;
                        }  
                        else if( sData.query.subWord(1,1) == "UPDATE" ||
                                 sData.query.subWord(1,1) == "update" )
                        {
                            sData.type  = PREP_UPDATE_COM;
                        }  
                        else if( sData.query.subWord(1,1) == "DELETE" ||
                                 sData.query.subWord(1,1) == "delete" )
                        {
                            sData.type  = PREP_DELETE_COM;
                        }  
                        else if( sData.query.subWord(1,1) == "MOVE" ||
                                 sData.query.subWord(1,1) == "move" )
                        {
                            sData.type  = PREP_MOVE_COM;
                        }  
                        else if( sData.query.subWord(1,1) == "ENQUEUE" ||
                                 sData.query.subWord(1,1) == "enqueue" )
                        {
                            sData.type  = PREP_ENQUEUE_COM;
                        }  
                        else if( sData.query.subWord(1,1) == "DEQUEUE" ||
                                 sData.query.subWord(1,1) == "dequeue" )
                        {
                            sData.type  = PREP_DEQUEUE_COM;
                        }  
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_COMMENT_SQL:
                    {
                        sData.type  = COMMENT_SQL_COM;
                        sData.query = sElement.keyMap["key1"];
                        push_back( sNode.process,
                                   sLaborer,
                                   sData );
                        break;
                    }
                    case TYPE_SELECT:
                    {
                        sData.type  = SELECT_COM;
                        sData.query = sElement.keyMap["key1"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_DESC:
                    {
                        sData.type  = DESC_COM;
                        sData.query = sElement.keyMap["key1"];
                        sData.table = sElement.keyMap["key2"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_XDESC:
                    {
                        sData.type  = DESC_DOLLAR_COM;
                        sData.query = sElement.keyMap["key1"];
                        sData.table = sElement.keyMap["key2"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_DDESC:
                    {
                        sData.type  = DESC_DOLLAR_COM;
                        sData.query = sElement.keyMap["key1"];
                        sData.table = sElement.keyMap["key2"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_VDESC:
                    {
                        sData.type  = DESC_DOLLAR_COM;
                        sData.query = sElement.keyMap["key1"];
                        sData.table = sElement.keyMap["key2"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_UPDATE:
                    {
                        sData.type  = UPDATE_COM;
                        sData.query = sElement.keyMap["key1"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_DELETE:
                    {
                        sData.type  = DELETE_COM;
                        sData.query = sElement.keyMap["key1"];
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_EMPTY:
                    {
                        sCycle1++;

                        sData.type  = STRING_COM;
                        sData.query = "\n";
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    case TYPE_SYNTAX_ERROR:
                    {
                        sData.type  = STRING_COM;
                        sData.query = STAFString("$");
                        sData.query += sNode.process;
                        sData.query += "> ";
                        sData.query += sElement.keyMap["key1"];
                        sData.query += ";\n";
                        sData.query += "[ERR-91010 : Syntax Error.]";
                        push_back( sNode.process, 
                                   sLaborer, 
                                   sData );
                        break;
                    }
                    default:
                    {
                        break;
                    }
                }

                if( sElement.type != TYPE_EMPTY )
                {
                    sCycle1 = 0;
                }
            }
        }
        else 
        {
            if( sNode.type == TYPE_PWAIT )
            {
                syncP0();

                if( sNode.process == "all" )
                {
                    sync();

                    sData.type  = STRING_COM;
                    sData.query = STAFString("$P0> --+PWAIT") + " ;";
                    push_back( "P0", 
                               mLaborer["P0"], 
                               sData );
                }
                else if( sNode.process.isDigits() == true )
                {
                    async();

                    sData.type  = STRING_COM;
                    sData.query = STAFString("$P0> --+PWAIT ") + sNode.process + " ;";
                    push_back( "P0", 
                               mLaborer["P0"], 
                               sData );

                    sleep( sNode.process.asUInt() );
                }
                else
                {
                    sync( sNode.process );

                    sData.type  = STRING_COM;
                    sData.query = STAFString("$P0> --+PWAIT ") + sNode.process + " ;";
                    push_back( "P0", 
                               mLaborer["P0"], 
                               sData );
                }
            }
        }
    }

    syncLaborer();

    if( mIgnore == ID_TRUE )
    {
        /* PRJ-1552
           테스트케이스가 IGNR이면
           1) NORMAL 테스트과 regression test의 경우 -> PASS
           2) 그밖에 경우 -> IGNR */
        if ( ( getAtsTestKind() == ATS_TEST_SEQUENTIAL ) || 
             ( getAtsTestKind() == ATS_TEST_FULL ) )
        {
            *aPass = "IGNR";
            enqueueData(  aIn, "IGNR" );
        }
        else
        {
            *aPass = "PASS";
            enqueueData(  aIn, "PASS" );
        }
    }
    else
    {
        /* PRJ-1552
           
           테스트실행결과 구분
           
           1) NORMAL 테스트과 regression test는 거의 동일
              - PASS
              - FAIL
              - FATAL
              - CRASH (regression test의 경우)
              
           2) 그밖에 경우
              - HIT
              - MISS
              - FATA
              - CRASH
        */
        
        if ( ( getAtsTestKind() == ATS_TEST_NORMAL ) ||
             ( getAtsTestKind() == ATS_TEST_REGRESSIVE ) )
        {
            // FAIL 또는 ERROR의 경우에만 out 파일에 기록한다.
            saveRESULT( &sPass );

            if( sPass == ID_TRUE )
            {
                *aPass = "PASS";
            }
            else
            {
                // fix BUG-14311
                if( getFatal() == ID_TRUE )
                {
                    *aPass = "FATAL";

                    sFatalData2 = "FATAL TEST CASE: " + mIn + "\n";
                    sFatalData2 += status();
    
                    sFatalData2 += "\n==================================================\n";
                    sFatalData2 += "               !!! FAILURE !!!\n";
                    sFatalData2 += "          ATC TEST ABNORMALLY FAIL\n";
                    sFatalData2 += "==================================================\n";
                    copyData( sFatalData,
                              sFatalData2.buffer(),
                              sFatalData2.length() );
                
                    mLogger.log( LOG_ERROR,
                                 sFatalData );
                }
                else
                {
                    *aPass = "FAIL";
                }
            }

            if ( getAtsTestKind() == ATS_TEST_REGRESSIVE )
            {
                if ( getCrash() == ID_TRUE )
                {
                    *aPass = "CRASH";
                }
            }
        }
        else 
        {
            saveArtRESULT();

            if ( getCrash() == ID_TRUE )
            {
                *aPass = "CRASH";
            }
            else if( getHit() == ID_TRUE )
            {
                *aPass = "HIT";
            }
            else
            {
                if ( getFatal() == ID_TRUE )
                {
                    *aPass = "FATAL";
                }
                else
                {
                    *aPass = "MISS";
                }
            }
        }

        enqueueData(  aIn, *aPass );
    }

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;
	
	debug( "runParseTable error" );

    return IDE_FAILURE;
}

STAFString 
Servicer::parseInnerSC(  const SChar *aData, 
                         UInt         aFence )
{
    SInt  sSize;
    SInt  sCursor;
    SChar sData[BUFFER_SIZE];

    copyData( sData,
              aData,
              aFence );

    copyData( sData,
              STAFString(sData).strip().toCurrentCodePage()->buffer(),
              STAFString(sData).strip().toCurrentCodePage()->length() ); 

    sSize = strlen(sData);

    if( sData[sSize - 1] == ';' )
    {
        sCursor = STAFString(aData).findLastOf( ";" );
       
        return STAFString(aData).subString(0, sCursor).replace( ";", INNER_SEMICOLON ) + STAFString(aData).subString( sCursor );
    }
    else
    {
        return STAFString(aData).replace( ";", INNER_SEMICOLON );
    }
}

IDE_RC                 
Servicer::syncP0()
{
    Laborer *sLaborer;

    if( mLaborer.find( "P0" ) != mLaborer.end() )
    {
        sLaborer = mLaborer["P0"];

        sLaborer->sync();
    }

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;
	
	debug( "syncP0 error" );

    return IDE_FAILURE;
}


IDE_RC                 
Servicer::sync( STAFString aProcess )
{
    Laborer        *sLaborer;
    LaborerIterator sIterator;
    QueryList      *sQuery;

    for( sIterator  = mLaborer.begin();
         sIterator != mLaborer.end();
         sIterator++ )
    {
        sLaborer = sIterator->second;

        sQuery = &(mQuery[sLaborer->process()]);
        sLaborer->push_back( sQuery );
    }

    if( mLaborer.find( aProcess ) != mLaborer.end() )
    {
        sLaborer = mLaborer[aProcess];

        sLaborer->sync();
    }

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;
	
	debug( "sync error" );

    return IDE_FAILURE;
}

IDE_RC                     
Servicer::sync()
{
    Laborer        *sLaborer;
    LaborerIterator sIterator;
    QueryList      *sQuery;

    for( sIterator  = mLaborer.begin();
         sIterator != mLaborer.end();
         sIterator++ )
    {
        sLaborer = sIterator->second;

        sQuery = &(mQuery[sLaborer->process()]);
        sLaborer->push_back( sQuery ); 
    }
    
    for( sIterator  = mLaborer.begin();
         sIterator != mLaborer.end();
         sIterator++ )
    {
        sLaborer = sIterator->second;

        sLaborer->sync();
    }

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;
	
	debug( "sync error 2" );

    return IDE_FAILURE;
}

IDE_RC                     
Servicer::async()
{
    Laborer        *sLaborer;
    LaborerIterator sIterator;
    QueryList      *sQuery;

    for( sIterator  = mLaborer.begin();
         sIterator != mLaborer.end();
         sIterator++ )
    {
        sLaborer = sIterator->second;

        sQuery = &(mQuery[sLaborer->process()]);
        sLaborer->push_back( sQuery ); 
    }
    
    return IDE_SUCCESS;

    IDE_EXCEPTION_END;
	
	debug( "async error" );

    return IDE_FAILURE;
}

void
Servicer::push_back( STAFString aProcess, 
                     Laborer   *aLaborer, 
                     queryData  aQuery )
{
    QueryList *sQuery = NULL;

    if( aProcess == "P0" )
    {
        aLaborer->push_back( aQuery );
    }
    else
    {
        sQuery = &(mQuery[aProcess]);
        sQuery->push_back( aQuery );
    }
}

IDE_RC
Servicer::saveArtRESULT()
{
    SChar          *sData;
    FILE           *sRe;
    Laborer        *sLaborer = NULL;
    LaborerIterator sIterator;
    UInt            sSize;
 
    if( mReData.length() == 0 )
    {
        mReData = " \n";
        mReData += "+----------------------------------------------------------------------+\n";
        mReData += "--+SECTOR 0; BY ATC\n";
        mReData += "+----------------------------------------------------------------------+\n \n";
        mReData += "$P0> --+PROCESS P0;\n";
    }

    for( sIterator  = mLaborer.begin();
         sIterator != mLaborer.end();
         sIterator++ )
    {
        sLaborer = sIterator->second;

        mReData += sLaborer->getResult();
    }

    mReData += "\n";

    if( (getHit() == ID_TRUE) || (getFatal() == ID_TRUE) )
    {
        // process가 2개 이상이고, 
        // test 결과가 FAIL일 경우에만 tdx 파일을 생성한다.
        if( mLaborer.size() > 1 )
        {
            saveTDX();
        }

        sData = (char *)mMemory.alloc( mRe.length() + 1 );
        copyData( sData,
                  mRe.buffer(),
                  mRe.length() );
    
        sRe = fopen( sData, "w" );
        IDE_TEST( sRe == NULL );

        sSize = mReData.toCurrentCodePage()->length();
        sData = (char *)mMemory.alloc( sSize + 1 );
        copyData( sData,
                  mReData.toCurrentCodePage()->buffer(),
                  sSize );

        fprintf( sRe, "%s", sData );

        IDE_TEST( fclose( sRe ) != 0 );
    }

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;
	
	debug( "saveArtResult error" );

    return IDE_FAILURE;
}

IDE_RC
Servicer::saveRESULT( idBool *aPass )
{
    SChar          *sData;
    FILE           *sRe;
    Laborer        *sLaborer = NULL;
    LaborerIterator sIterator;
    UInt            sSize;
 
    if( mReData.length() == 0 )
    {
        mReData = " \n";
        mReData += "+----------------------------------------------------------------------+\n";
        mReData += "--+SECTOR 0; BY ATC\n";
        mReData += "+----------------------------------------------------------------------+\n \n";
        mReData += "$P0> --+PROCESS P0;\n";
    }

    for( sIterator  = mLaborer.begin();
         sIterator != mLaborer.end();
         sIterator++ )
    {
        sLaborer = sIterator->second;

        mReData += sLaborer->getResult();
    }

    mReData += "\n";

    if( mReData == mLsData )
    {
        if( aPass != NULL )
        {
            *aPass = ID_TRUE;
        } 
    }
    else
    {
        if( aPass != NULL )
        {
            *aPass = ID_FALSE;
        }
        
        // process가 2개 이상이고, 
        // test 결과가 FAIL일 경우에만 tdx 파일을 생성한다.
        if( mLaborer.size() > 1 )
        {
            saveTDX();
        }

        sData = (char *)mMemory.alloc( mRe.length() + 1 );
        copyData( sData,
                  mRe.buffer(),
                  mRe.length() );
    
        sRe = fopen( sData, "w" );
        IDE_TEST( sRe == NULL );

        sSize = mReData.toCurrentCodePage()->length();
        sData = (char *)mMemory.alloc( sSize + 1 );
        copyData( sData,
                  mReData.toCurrentCodePage()->buffer(),
                  sSize );

        fprintf( sRe, "%s", sData );

        IDE_TEST( fclose( sRe ) != 0 );
    }

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;
	
	debug( "saveResult error" );

    return IDE_FAILURE;
}

IDE_RC
Servicer::saveTDX()
{
    SChar          *sData;
    FILE           *sTdx;
    Laborer        *sLaborer = NULL;
    LaborerIterator sIterator;
    UInt            sSize;

    mTdxData = "";

    for( sIterator  = mLaborer.begin();
         sIterator != mLaborer.end();
         sIterator++ )
    {
        sLaborer = sIterator->second;

        mTdxData += sLaborer->getTdxResult();
    }

    sData = (char *)mMemory.alloc( mTdx.length() + 1 );
    copyData( sData,
              mTdx.buffer(),
              mTdx.length() );

    sTdx = fopen( sData, "w" );
    IDE_TEST( sTdx == NULL );

    sSize = mTdxData.toCurrentCodePage()->length();
    sData = (char *)mMemory.alloc( sSize + 1 );
    copyData( sData,
              mTdxData.toCurrentCodePage()->buffer(),
              sSize );

    fprintf( sTdx, "%s", sData );

    // 파일의 끝에 start mark를 붙여줘야 함.
    fprintf( sTdx, "\n<@!START!@>" );

    IDE_TEST( fclose( sTdx ) != 0 );

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;
	
	debug( "saveTDX error" );

    return IDE_FAILURE;
}

void
Servicer::debug( STAFString aIn )
{
    SChar sDebug[65536];

    copyData( sDebug,
              aIn.buffer(),
              aIn.length() );

    (void)mLogger.log( LOG_DEBUG, 
                       sDebug );
}

IDE_RC
Servicer::getEnv()
{
    STAFResultPtr sResult;
    STAFString    sRequest;

    sRequest = "get handle ";
    sRequest += STAFString(mService->handle);
    sRequest += " var ";

    sResult = mServiceData->handlePtr->submit( "local",
                                               "var",
                                               sRequest + "ALTIBASE_PORT_NO" );
    IDE_TEST( sResult->rc != 0 );
    mEnvPORT = sResult->result.strip();

#if defined(STAF_OS_NAME_WIN32)
    sResult = mServiceData->handlePtr->submit( "local",
                                               "var",
                                               sRequest + "ALTIBASE_IPC_PORT_NO" );

    IDE_TEST( sResult->rc != 0 );
    mEnvIPC_PORT = sResult->result.strip();
#endif

    sResult = mServiceData->handlePtr->submit( "local",
                                               "var",
                                               sRequest + "ALTIBASE_HOME" );
    IDE_TEST( sResult->rc != 0 );
    mEnvHOME = sResult->result;


    sResult = mServiceData->handlePtr->submit( "local",
                                               "var",
                                               sRequest + "ALTIBASE_NLS_USE" );
    IDE_TEST( sResult->rc != 0 );
    mEnvNLS = sResult->result;


    sResult = mServiceData->handlePtr->submit( "local",
                                               "var",
                                               sRequest + "ATAF_TEST_CASE" );
    IDE_TEST( sResult->rc != 0 );
    mEnvCASE = sResult->result;

    sResult = mServiceData->handlePtr->submit( "local",
                                               "var",
                                               sRequest + "ATAF_USER_TEST_CASE" );
    IDE_TEST( sResult->rc != 0 );
    mEnvCASE_USER = sResult->result;

    sResult = mServiceData->handlePtr->submit( "local",
                                               "var",
                                               sRequest + "ATAF_TEST_RESULT" );
    IDE_TEST( sResult->rc != 0 );
    mEnvRESULT = sResult->result;

    sResult = mServiceData->handlePtr->submit( "local",
                                               "var",
                                               sRequest + "ATAF_RESULT_SUFFIX" );
    IDE_TEST( sResult->rc != 0 );
    mEnvSUFFIX_RE = sResult->result;

    sResult = mServiceData->handlePtr->submit( "local",
                                               "var",
                                               sRequest + "ATAF_ORACLE_SUFFIX" );
    IDE_TEST( sResult->rc != 0 );
    mEnvSUFFIX_OR = sResult->result.replace( ",", " " );

    sResult = mServiceData->handlePtr->submit( "local",
                                               "var",
                                               sRequest + "PATH" )
;
    IDE_TEST( sResult->rc != 0 );
    mEnvPATH = sResult->result.replace( "^", ":" );

    sResult = mServiceData->handlePtr->submit( "local",
                                               "var",
                                               sRequest + "LANG" )
;
    IDE_TEST( sResult->rc != 0 );
    mEnvLANG = sResult->result;

    sResult = mServiceData->handlePtr->submit( "local",
                                               "var",
                                               sRequest + "ENV_PROPERTIES" )
;
    IDE_TEST( sResult->rc != 0 );
    // a=b;b=c;c=d -> a=b b=c c=d
    mEnvAll = sResult->result.replace( ";", " ");

    //STAF.cfg
    sResult = mServiceData->handlePtr->submit( "local",
                                               "VAR",
                                               "RESOLVE STRING {ATAF_DEBUG}" );
    mDEBUG = sResult->result.asUInt();
    sResult = mServiceData->handlePtr->submit( "local",
                                               "VAR",
                                               "RESOLVE STRING {ATAF_EVENT_TIMEOUT}" );
    mEVENT_TIMEOUT = sResult->result.asUInt();

    sResult = mServiceData->handlePtr->submit( "local",
                                               "VAR",
                                               "RESOLVE STRING {ATAF_MEMORY_TEST}" );
    mMEMORY_TEST = sResult->result.asUInt();

    sResult = mServiceData->handlePtr->submit( "local",
                                               "VAR",
                                               "RESOLVE STRING {ATAF_ISQL_READ_TIMEOUT}" );
    if ( sResult->rc == 13 )
    {
        mISQL_READ_TIMEOUT = ISQL_READ_TIMEOUT;
    }
    else
    {
        mISQL_READ_TIMEOUT = sResult->result.asUInt();
    }

    if( getenv( "ATAF_DEBUG" ) != NULL )
    {
        mDEBUG = atoi( getenv( "ATAF_DEBUG" ) );
    }

    if( getenv( "ATAF_EVENT_TIMEOUT" ) != NULL )
    {
        mEVENT_TIMEOUT = atoi( getenv( "ATAF_EVENT_TIMEOUT" ) );
    }

    if( getenv( "ATAF_MEMORY_TEST" ) != NULL )
    {
        mMEMORY_TEST = atoi( getenv( "ATAF_MEMORY_TEST" ) );
    }

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;
	
	debug( "getEnv error" );

    return IDE_FAILURE;
}

void 
Servicer::getLogonData( logonData *aLogonData,
                        STAFString aProcess )
{
    SChar       sData[65536];
    SChar       sEnv[65536];
    ServerParam sServer;

    memset( aLogonData,
                   0,
                   ID_SIZEOF(logonData) );

    sprintf( aLogonData->user, 
                    "%s", 
                    "SYS" );
    sprintf( aLogonData->password, 
                    "%s", 
                    "MANAGER" );

    if( mDefaultType[aProcess] == "TCP" )
    {
        aLogonData->conn_type = 1;
    }
    else if( mDefaultType[aProcess] == "UNIX" )
    {
        aLogonData->conn_type = 2;
    }
    else if( mDefaultType[aProcess] == "IPC" )
    {
        aLogonData->conn_type = 3;
    }
    else
    {
        aLogonData->conn_type = 1;
    }

    if( aProcess == "P0" )
    {
        sServer = (mServerMap)["DEFAULT"];
    }
    else
    {
        if( mDefaultServer.find( aProcess ) == mDefaultServer.end() )
        {
            sServer = (mServerMap)["DEFAULT"];
        }
        else
        {
            sServer = (mServerMap)[mServerAlias[mDefaultServer[aProcess]]];
        }
    }

    memcpy( aLogonData->host,
                   sServer["HOST_IP"].strip().buffer(),
                   sServer["HOST_IP"].strip().length() );

    memcpy( aLogonData->nls,
                   sServer["ALTIBASE_NLS_USE"].strip().buffer(),
                   sServer["ALTIBASE_NLS_USE"].strip().length() );

#if defined(STAF_OS_NAME_WIN32)
    if (aLogonData->conn_type == 3)
    {
        aLogonData->port = mEnvIPC_PORT.asUInt();
    }
    else
    {
        aLogonData->port = getPort( sServer["ALTIBASE_PORT_NO"] ).asUInt();
    }
#else
    aLogonData->port = getPort( sServer["ALTIBASE_PORT_NO"] ).asUInt();
#endif

    copyData( sEnv, 
              sServer["ALTIBASE_HOME"].buffer(), 
              sServer["ALTIBASE_HOME"].length() );

    sprintf( aLogonData->env,
                    "%s=%s",
                    "ALTIBASE_HOME",
                    sEnv );

    sprintf( aLogonData->home,
                    "%s",
                    getenv("ALTIBASE_HOME") );
}

IDE_RC
Servicer::enqueueData( STAFString aIn,
                       STAFString aPass )
{
    SChar         sData[1024];
    SChar         sDebug[1024];
    SChar         sPass[1024];
    STAFString    sLstOutPath;
    SChar         sID[1024];

    copyData( sData,
              aIn.buffer(),
              aIn.length() );

    copyData( sPass, 
              aPass.buffer(),
              aPass.length() );

    mComment[30] = '\0';

    sprintf( sDebug, 
#if defined(STAF_USE_COLOR)
                    "\033[0;%sm%5s\033[0m %s %-30s",
                    (aPass == "PASS") ? "32" : "31;1",
#else
                    "%5s %s %-30s",
#endif
                    sPass, 
                    "#",
                    mComment ); 

    mMessage = sDebug;

    
    
    if(  aPass != "PASS" )
    {
        copyData( sData,
                  aIn.buffer(),
                  aIn.length() );

        sprintf( sDebug,
                        "%s # %s # %s", 
                        sData, 
                        mComment, 
                        mSuite );

        // PROJ-1570
        // full path of lst file and out file
        sLstOutPath = mLs + STAFString( " " ) + mRe;

        copyData( sData,
                  sLstOutPath.buffer(),
                  sLstOutPath.length() );

        mLogger.log( LOG_LSTOUT,
                     sData );

        switch ( getAtsTestKind() )
        {
            case ATS_TEST_NORMAL:    // PASS, FAIL
            {
                mLogger.log( LOG_FAIL, sDebug ); 
            }
            break;
        
            case ATS_TEST_REGRESSIVE: // PASS, FAIL, CRASH
            {
                if ( aPass == "CRASH" )
                {
                    mLogger.log( LOG_CRASH, sDebug ); 
                }
                else
                {
                    mLogger.log( LOG_FAIL, sDebug ); 
                }
            }
            break;
            
            case ATS_TEST_SEQUENTIAL: // HIT, MISS, CRASH
            case ATS_TEST_FULL:
            {
                if ( aPass == "HIT" )
                { 
                    mLogger.log( LOG_FAIL, sDebug ); 
                }
                else if ( aPass == "CRASH" )
                { 
                    mLogger.log( LOG_FAIL,  sDebug ); 
                    mLogger.log( LOG_CRASH, sDebug ); 
                }
                else
                {
                    // nothing to do..
                }
            }
            break;

            default:
            break;
        }
    }

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;    
	
	debug( "enqueueData error" );
    
    return IDE_FAILURE;
}

IDE_RC
Servicer::mkdir( STAFString aIn )
{
    SChar         sIn[65536];
    STAFString    sRequest;
    STAFResultPtr sResult;

    copyData( sIn,
              aIn.buffer(),
              aIn.length() );

    if( exist( sIn ) != ID_TRUE )
    {
        sRequest = "create directory ";

        sResult = mServiceData->handlePtr->submit( "local",
                                                   "fs",
                                                   sRequest + dirname(sIn) + " FULLPATH" );
        //IDE_TEST( sResult->rc != 0 );
    }

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;    
	
	debug( "mkdir error" );
    
    return IDE_FAILURE;
}

IDE_RC
Servicer::mkdirLog()
{
    STAFString    sRequest;
    STAFResultPtr sResult;

    sRequest = "create directory ";

    sResult = mServiceData->handlePtr->submit( "local",
                                               "fs",
                                               sRequest + mEnvRESULT + FILE_SEPARATORS + "work" + FILE_SEPARATORS + "log" + " FULLPATH" );
    IDE_TEST( sResult->rc != 0 );

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;    

	debug( "mkdirLog error" );
    debug( sResult->result );

    return IDE_FAILURE;
}

char *
Servicer::basename( const char *name )
{
  const char *base = name;

  while (*name)
    {
      if (*name == FILE_SEPARATOR)
	base = name + 1;
      ++name;
    }
  return (char *) base;
}

char *
Servicer::dirname( char *path )
{
  char *newpath;
  char *slash;
  int length;			/* Length of result, not including NUL.  */

  slash = strrchr (path, FILE_SEPARATOR);
  if (slash == 0)
    {
      /* File is in the current directory.  */
      path = ".";
      length = 1;
    }
  else
    {
      /* Remove any trailing slashes from the result.  */
      while (slash > path && *slash == FILE_SEPARATOR)
	--slash;

      length = slash - path + 1;
    }
  newpath = (char *) mMemory.alloc(length + 1);
  if (newpath == 0)
    return 0;
  strncpy (newpath, path, length);
  newpath[length] = 0;
  return newpath;
}

STAFString
Servicer::getPath()
{
    SChar sPath[65536];

    copyData( sPath,
              mRe.buffer(),
              mRe.length() );

    return dirname( sPath );
}

STAFString
Servicer::getEnv4System( STAFString aAlias )
{
    STAFString    sData;
    SChar         sPath[65536];

    ServerParam   sServer;
    ParamIterator sIterator;
    STAFString    sKey;
    STAFString    sPort;
    SInt          sCursor;

    sServer = (mServerMap)[mServerAlias[aAlias]];

    copyData( sPath,
              mRe.buffer(),
              mRe.length() );

    sData += "cd \"";
    sData += dirname( sPath );
    sData += "\";";

    for( sIterator = sServer.begin();
         sIterator != sServer.end();
         sIterator++ )
    {
        sKey = sIterator->first;

        if( sKey.strip().length() != 0 )
        {
#if defined(STAF_OS_NAME_WIN32)
            if( sKey == "PATH" )
            {
                continue;
            }
#endif
            if( (sKey == "PATH") &&
                (server( aAlias ) != "local" ) )
            {
                continue;
            }

            sData += "export ";
            sData += sKey;
            sData += "=\"";

            if( sKey == "ALTIBASE_PORT_NO" )
            {
                sData += getPort( sIterator->second );

            }
#if defined(STAF_OS_NAME_WIN32)
            else if( sKey == "ALTIBASE_IPC_PORT_NO" )
            {
                sData += mEnvIPC_PORT;

            }
#endif
            else if( sKey == "ALTIBASE_LINKER_PORT_NO" )
            {
                sData += getPort( sIterator->second );

            }
            else if( sKey == "ALTIBASE_REPLICATION_PORT_NO" )
            {
                sData += getReplicationPort( sIterator->second );

            }
            else if( sKey == "ALTIBASE_HOME" )
            {
#if defined(STAF_OS_NAME_WIN32)
                sData += sIterator->second.strip().replace("$ATC_HOME",
                                                           mEnvRESULT ).replace( "\\", "/" );
#else
                sData += sIterator->second.strip().replace("$ATC_HOME",
                                                           mEnvRESULT );
#endif
            }
            else if( sKey.find("AUDIT_DB") != STAFString::kNPos )
            {
                sPort = "%PORT_NO";

                sCursor = sIterator->second.find( sPort );
                if( sCursor != STAFString::kNPos )
                {
                    sPort += sIterator->second.subString( sCursor + 8, 1);
                    sData += sIterator->second.replace( sPort, 
                                                        getPort(sPort)).strip();
                }
                else
                {
                    sData += sIterator->second.strip();
                }
            }
            else
            {
#if defined(STAF_OS_NAME_WIN32)
                sData += sIterator->second.strip().replace( "\\", "/" );
#else
                sData += sIterator->second.strip();
#endif
            }
            sData += "\";";
        }
    }

    return sData.strip();
}

STAFString
Servicer::getEnv4Rsystem( STAFString aAlias )
{
    STAFString    sData;
    SChar         sPath[65536];

    ServerParam   sServer;
    ParamIterator sIterator;
    STAFString    sKey;
    STAFString    sPort;
    SInt          sCursor;

    sServer = (mServerMap)[mServerAlias[aAlias]];

    copyData( sPath,
              mRe.buffer(),
              mRe.length() );

    sData += "envs ";

    for( sIterator = sServer.begin();
         sIterator != sServer.end();
         sIterator++ )
    {
        sKey = sIterator->first;

        if( sKey.strip().length() != 0 )
        {
//#if defined(STAF_OS_NAME_WIN32)
            if( sKey == "PATH" )
            {
                continue;
            }
//#endif
            if( (sKey == "PATH") &&
                (server( aAlias ) != "local" ) )
            {
                continue;
            }

            sData += sKey;
            sData += "=";

            if( sKey == "ALTIBASE_PORT_NO" )
            {
                sData += getPort( sIterator->second );

            }
#if defined(STAF_OS_NAME_WIN32)
            else if( sKey == "ALTIBASE_IPC_PORT_NO" )
            {
               sData += mEnvIPC_PORT;

            }
#endif
            else if( sKey == "ALTIBASE_LINKER_PORT_NO" )
            {
                sData += getPort( sIterator->second );

            }
            else if( sKey == "ALTIBASE_REPLICATION_PORT_NO" )
            {
                sData += getReplicationPort( sIterator->second );

            }
            else if( sKey == "ALTIBASE_HOME" )
            {
#if defined(STAF_OS_NAME_WIN32)
                sData += sIterator->second.strip().replace("$ATC_HOME",
                                                           mEnvRESULT ).replace( "\\", "/" );
#else
                sData += sIterator->second.strip().replace("$ATC_HOME",
                                                           mEnvRESULT );
#endif
            }
            else if( sKey.find("AUDIT_DB") != STAFString::kNPos )
            {
                sPort = "%PORT_NO";

                sCursor = sIterator->second.find( sPort );
                if( sCursor != STAFString::kNPos )
                {
                    sPort += sIterator->second.subString( sCursor + 8, 1);
                    sData += sIterator->second.replace( sPort, 
                                                        getPort(sPort)).strip();
                }
                else
                {
                    sData += sIterator->second.strip();
                }
            }
            else
            {
#if defined(STAF_OS_NAME_WIN32)
                sData += sIterator->second.strip().replace( "\\", "/" );
#else
                sData += sIterator->second.strip();
#endif
            }
            sData += " ";
        }
    }

    return sData.strip();
}


STAFString
Servicer::server( STAFString aAlias )
{
    STAFString  sData;
    ServerParam sServer;

    sServer = (mServerMap)[mServerAlias[aAlias]];

    if( sServer["HOST_IP"] == "127.0.0.1" )
    {
        sData = "local";
    }
    else
    {
        sData = sServer["HOST_IP"];

        if( sServer.find( "ATAF_PORT_NO" ) != sServer.end() )
        {
            sData += "@";
            sData += sServer["ATAF_PORT_NO"];
        }
    }

    return sData;
}

//fix BUG-14285
void
Servicer::rmEnv( STAFString aKey,
                 STAFString aAlias )
{
    ServerParam  *sServer;

    sServer = &((mServerMap)[aAlias]);

    if( sServer->find( aKey ) != sServer->end() )
    {
        sServer->erase( aKey );
    }
}

void
Servicer::addEnv( STAFString aKey,
                  STAFString aEnv,
                  STAFString aAlias )
{
    STAFString    sEnv;
    ServerParam  *sServer;
    ParamIterator sIterator;
    SChar         sSpace[65536];

    //BUGBUG 
    memset( sSpace, 
                   ' ', 
                   65536 );
    sSpace[65536 - 1] = '\0';
                   
    sEnv = aEnv + sSpace;

    sServer = &((mServerMap)[aAlias]);

    if( sEnv.find("%SHM_DB_KEY") != STAFString::kNPos )
    {
        sEnv = getPort( (*sServer)["ALTIBASE_PORT_NO"] );
    }

    if( sEnv.find("$ATC_HOME") != STAFString::kNPos )
    {
        sEnv = sEnv.replace( "$ATC_HOME", 
                             mEnvCASE );
    }
  
    if( sEnv.find("$ALTIBASE_HOME") != STAFString::kNPos )
    {
        sEnv = sEnv.replace( "$ALTIBASE_HOME", 
                             mEnvHOME );
    }

    for( sIterator = sServer->begin();
         sIterator != sServer->end();
         sIterator++ )
    {
        sEnv = sEnv.replace( STAFString("$") + sIterator->first,
                             sIterator->second );
    }

    (*sServer)[aKey] = sEnv.strip();
}

STAFString
Servicer::replace( STAFString aIn )
{
    STAFString    sIn;
    STAFString    sAlias;
    STAFString    sData1;
    STAFString    sData2;
    STAFString    sData3;
    STAFString    sData4;

    ServerParam   sServer;

    ParamIterator sIterator;
    ParamIterator sIterator3;

    sIn = aIn;

    for( sIterator3 = mServerAlias.begin();
         sIterator3 != mServerAlias.end();
         sIterator3++ )
    {
        sAlias = sIterator3->first;
        sServer = (mServerMap)[mServerAlias[sAlias]];

        sData1 = getReplicationPort(sServer["ALTIBASE_REPLICATION_PORT_NO"]);

        sData2 = sServer["HOST_IP"].strip();

        sData3 = STAFString("${HOST_IP@") + sAlias + "}";
        sData4 = STAFString("${ALTIBASE_REPLICATION_PORT_NO@") + sAlias + "}";

        sIn = sIn.replace( sData3, sData2 );
        sIn = sIn.replace( sData4, sData1 );
    }

    return sIn;   
}

STAFString
Servicer::replaceServicePort( STAFString aIn )
{
    STAFString    sIn;
    STAFString    sAlias;
    STAFString    sData1;
    STAFString    sData2;

    ServerParam   sServer;

    ParamIterator sIterator;
    ParamIterator sIterator2;

    sIn = aIn;

    for( sIterator2 = mServerAlias.begin();
         sIterator2 != mServerAlias.end();
         sIterator2++ )
    {
        sAlias = sIterator2->first;
        sServer = (mServerMap)[mServerAlias[sAlias]];

        sData1 = getPort(sServer["ALTIBASE_PORT_NO"]);

        sData2 = STAFString("${ALTIBASE_PORT_NO@") + sAlias + "}";

        sIn = sIn.replace( sData2, sData1 );
    }

    return sIn;   
}

IDE_RC
Servicer::loadCASE( STAFString aIn, STAFString &aData )
{
    STAFString sData1;
    STAFString sData2;
    FILE      *sIn = NULL;
    SChar      sLine[65536];
    SChar      sData3[65536];
    SChar      sData4[65536];

    copyData( sData3,
              mIn.buffer(),
              mIn.length() );
    copyData( sData4,
              aIn.buffer(),
              aIn.length() );

    sprintf( sLine, "%s%s%s",
                           dirname(sData3),
                           FILE_SEPARATORS,
                           sData4 );

    sIn = fopen( sLine, "r" );

    IDE_TEST( sIn == NULL );

    while( 1 )
    {
        if( fgets(sLine, ID_SIZEOF(sLine), sIn) != NULL )
        {
            if( strncasecmp( sLine, 
                                    "--+LOAD_SQL",
                                    strlen("--+LOAD_SQL") ) == 0 )
            {
                aData += "# ==> [";
                aData += STAFString(&sLine[12]).strip().replace(";", "");
                aData += "] BEGIN <=\n";
                loadCASE( STAFString(&sLine[12]).strip().replace(";", ""), 
                          aData );
                aData += "# ==> [";
                aData += STAFString(&sLine[12]).strip().replace(";", "");
                aData += "] END <=\n";
                continue;
            }

            if( (STAFString(sLine).strip().subString(0, 1) == "#") ||
                (STAFString(sLine).strip().subString(0, 2) == "--") || 
                (STAFString(sLine).strip().subString(0, 2) == "//") || 
                (STAFString(sLine).strip().subString(0, 3) == "--+") )
            {
                aData += STAFString( sLine );
            }
            else
            {     
                sData1 = parseInnerSC( sLine, strlen(sLine) );
                sData2 = sData1;
                sData2 = sData2.strip();

                if( (sData2.find( "/" ) != STAFString::kNPos) &&
                    (sData2.length() != 1 ) )
                {
                    sData1= sData1.replace( "/", INNER_SLASH );
                } 

                aData += sData1;
            }
        }
        else
        {
            break;
        }
    }
    IDE_TEST( fclose( sIn ) != 0 );

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;
	
	debug( "loadCASE error" );

    return IDE_FAILURE;
}

IDE_RC
Servicer::loadORACLE( STAFString aIn, 
                      STAFString &aData )
{
    STAFString sData1;
    STAFString sData2;
    FILE      *sIn = NULL;
    SChar      sLine[65536];
    UInt       sLength;

    copyData( sLine, 
              aIn.buffer(), 
              aIn.length() );

    sIn = fopen( sLine, "r" );
    
    if( sIn != NULL )
    {
        while( 1 )
        {
            // BUG-28665
            sLength = fread(sLine, 1, ID_SIZEOF(sLine), sIn);

            if( sLength > 0 )
            {
                aData += STAFString( sLine, sLength );
            }
            else
            {
                break;
            }
        }
        IDE_TEST( fclose( sIn ) != 0 );
    }

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;
	
	debug( "loadORACLE error" );

    return IDE_FAILURE;
}

void
Servicer::system( STAFString aIn )
{
    SChar sDebug[65536];

    copyData( sDebug,
              aIn.replace("%", "%%").buffer(),
              aIn.replace("%", "%%").length() );

    (void)mLogger.log( LOG_SYSTEM, sDebug );
}

STAFString                 
Servicer::getPort( STAFString aPort )
{
    STAFString sPort;

    sPort = aPort.strip();

    if( sPort.find( "%PORT_NO" ) != STAFString::kNPos )
    {
        sPort = sPort.replace( "%PORT_NO", 
                              "" ).asUInt() * 1000 + mEnvPORT.asUInt();
    }

    return sPort;
}

STAFString                 
Servicer::getReplicationPort( STAFString aPort )
{
    STAFString sPort;

    sPort = aPort.strip();

    if( sPort.find( "%REPLICATION_PORT_NO" ) != STAFString::kNPos )
    {
        sPort = sPort.replace( "%REPLICATION_PORT_NO", 
                               "" ).asUInt() * 1000 + mEnvPORT.asUInt() + 5000; 
    }

    return sPort;
}

IDE_RC
Servicer::saveREPORT( struct timeval aSval,
                      struct timeval aEval,
                      STAFString     aPass,
                      STAFString     aIn )
{
    SChar         sData[65536];
    SChar         sPass[1024];
    SChar         sIn[1024];
    SInt          sElapsed;

    sElapsed = getElapsed( &aSval,
                           &aEval );

    copyData( sPass,
              aPass.buffer(),
              aPass.length() ); 
    copyData( sIn,
              aIn.buffer(),
              aIn.length() ); 

    sprintf( sData,
                    "|%s|%s|%d|%s|%s|%s\n",
                    sPass,
                    sIn,
                    sElapsed,
                    mLogname,
                    mHostname,
                    mFullSuite );

    mLogger.log( LOG_REPORT, 
                 sData );

    return IDE_SUCCESS;
}

SInt 
Servicer::getElapsed( struct timeval *aSval,
                      struct timeval *aEval )
{
    struct timeval sSval;
    SInt           sElapsed;

    sSval.tv_sec = (*aEval).tv_sec - (*aSval).tv_sec; 
    sSval.tv_usec = (*aEval).tv_usec - (*aSval).tv_usec; 
    //sSval = (*aEval) - (*aSval); 

    sElapsed = sSval.tv_sec * 1000000 + sSval.tv_usec;

    return sElapsed;
}

idBool                    
Servicer::exist( STAFString aIn )
{
    SChar sIn[65536];

    copyData( sIn,
              aIn.buffer(),
              aIn.length() );

    if( access( sIn, 
                       F_OK ) == 0 )
    {
        return ID_TRUE;
    }
    else
    {
        return ID_FALSE;
    }
}

#if defined(STAF_OS_NAME_WIN32)
IDE_RC
Servicer::link()
{

    SChar         sRe[65536];
    SChar         sIn[65536];

    STAFResultPtr sResult;
    STAFString    sRequest;

    copyData( sRe,
              mRe.buffer(),
              mRe.length() );
    copyData( sIn,
              mIn.buffer(),
              mIn.length() );

    if( STAFString(dirname(sRe)) ==  STAFString(dirname(sIn)) ) 
    {
        goto end;
    }

    if( mLink.strip().length() == 0 )
    {
        goto end;
    }

    //cout << "link: " << mLink << endl;
    sRequest += "start shell command ";
    sRequest += STAFHandle::wrapData( STAFString("cd ") + STAFString(dirname(sRe)) + STAFString(";ln -s ") + mLink + FILE_SEPARATORS + STAFString("* . &> /dev/null") ) + " WAIT";

    if( mDEBUG == 1 )
    {
        system( sRequest );
    }

    sResult = mServiceData->handlePtr->submit( "local",
                                               "process",
                                               sRequest );

    IDE_TEST( sResult->rc != 0 );
end:

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    debug( "link error" );

    return IDE_FAILURE;
}

IDE_RC
Servicer::unlink()
{
    SChar         sRe[65536];
    SChar         sIn[65536];

    STAFResultPtr sResult;
    STAFString    sRequest;

    copyData( sRe,
              mRe.buffer(),
              mRe.length() );
    copyData( sIn,
              mIn.buffer(),
              mIn.length() );

    if( STAFString(dirname(sRe)) ==  STAFString(dirname(sIn)) ) 
    {
        goto end;
    }

    if( mUnlink.strip().length() == 0 )
    {
        goto end;
    }

    //cout << "Unlink: " << mUnlink << endl;
    sRequest += "start shell command ";
    sRequest += STAFHandle::wrapData( STAFString("cd ") + mUnlink + STAFString(";ls -aF | grep @ | grep -v \"\\.sh\" | sed -e 's/@//g' | xargs rm &> /dev/null") ) + " WAIT";

    if( mDEBUG == 1 )
    {
        system( sRequest );
    }

    sResult = mServiceData->handlePtr->submit( "local",
                                               "process",
                                               sRequest );

    IDE_TEST( sResult->rc != 0 );
end:

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    debug( "unlink error" );

    return IDE_FAILURE;
}
#else

IDE_RC
Servicer::link()
{

    SChar         sRe[65536];
    SChar         sIn[65536];
    SChar         sData[BUFFER_SIZE];
    STAFResultPtr sResult;
    STAFString    sRequest;
    pid_t          sPid;

    copyData( sRe,
              mRe.buffer(),
              mRe.length() );
    copyData( sIn,
              mIn.buffer(),
              mIn.length() );

    if( STAFString(dirname(sRe)) ==  STAFString(dirname(sIn)) ) 
    {
        goto end;
    }

    if( mLink.strip().length() == 0 )
    {
        goto end;
    }

    sRequest += STAFString("cd ") + STAFString(dirname(sRe)) + STAFString(";ln -s ") + mLink + FILE_SEPARATORS + STAFString("* . &> /dev/null");

    if( mDEBUG == 1 )
    {
        system( sRequest );
    }

    copyData( sData,
              sRequest.buffer(),
              sRequest.length());

    sPid = fork();
    IDE_TEST(sPid < 0);

    if(sPid == 0)
    {
        execl("/usr/local/bin/bash", "/usr/local/bin/bash", "-c", sData, NULL);

        exit(0);
    }
    else
    {
        waitpid(sPid, NULL, 0);
    }

end:

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    debug( "link error" );

    return IDE_FAILURE;
}

IDE_RC
Servicer::unlink()
{
    SChar         sRe[65536];
    SChar         sIn[65536];
    SChar         sData[BUFFER_SIZE];
    STAFResultPtr sResult;
    STAFString    sRequest;
    pid_t          sPid;

    copyData( sRe,
              mRe.buffer(),
              mRe.length() );
    copyData( sIn,
              mIn.buffer(),
              mIn.length() );

    if( STAFString(dirname(sRe)) ==  STAFString(dirname(sIn)) ) 
    {
        goto end;
    }

    if( mUnlink.strip().length() == 0 )
    {
        goto end;
    }

    // fix for BUG-31650
#if defined(STAF_OS_NAME_HPUX)
    sRequest += STAFString("cd ") + mUnlink + STAFString(";ls -al | grep ^l | awk '{print $9}' | grep -v \"\\.sh\" | xargs rm &> /dev/null");
#else
    sRequest += STAFString("cd ") + mUnlink + STAFString(";ls -aF | grep @ | grep -v \"\\.sh\" | sed -e 's/@//g' | xargs rm &> /dev/null");
#endif

    if( mDEBUG == 1 )
    {
        system( sRequest );
    }

    copyData( sData,
              sRequest.buffer(),
              sRequest.length());

    sPid = fork();
    IDE_TEST(sPid < 0);

    if(sPid == 0)
    {
        execl("/usr/local/bin/bash", "/usr/local/bin/bash", "-c", sData, NULL);

        exit(0);
    }
    else
    {
        waitpid(sPid, NULL, 0);
    }

end:

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    debug( "unlink error" );

    return IDE_FAILURE;
}
#endif

STAFString
Servicer::status()
{
    UInt           sLevel = 0;
    STAFString     sData;
    Laborer        *sLaborer = NULL;
    LaborerIterator sIterator;

    IDE_TEST( lock() != IDE_SUCCESS );
    sLevel = 1;

    sData += "(";
    sData += mPROGRESS;
    sData += ") ";
    sData += mIn;
    sData += "\n";

    if( mLaborer.size() != 0 )
    {
        for( sIterator  = mLaborer.begin();
             sIterator != mLaborer.end();
             sIterator++ )
        {
            sLaborer = sIterator->second;

            if( sLaborer->status().length() != 0 )
            {
                sData += sLaborer->status();
                sData += "\n";
            }
        }
    }
    else
    {
        sData += "+ Initialize...\n";
    }
    
    sLevel = 0;
    IDE_TEST( unlock() != IDE_SUCCESS );

    return sData;

    IDE_EXCEPTION_END;

    if( sLevel != 0 )
    {
        (void)unlock();
    }
    
    return sData;
}

/* PRJ-1552 ART 복구테스트 타입 반환 */

ATSTestKind
Servicer::getAtsTestKind()
{
    ATSTestKind sTestKind;

    if ( mTESTTYPE.find("normal") != STAFString::kNPos )
    {
        sTestKind = ATS_TEST_NORMAL;
    }
    else if ( mTESTTYPE.find("regressive") != STAFString::kNPos )
    {
        sTestKind = ATS_TEST_REGRESSIVE;
    }
    else if ( mTESTTYPE.find("sequential") != STAFString::kNPos )
    {
        sTestKind = ATS_TEST_SEQUENTIAL;
    }
    else if ( mTESTTYPE.find("full") != STAFString::kNPos )
    {
        sTestKind = ATS_TEST_FULL;
    }
    else
    {
        sTestKind = ATS_TEST_NULL; 
    }

    return sTestKind;
}
        
IDE_RC 
Servicer::logValgrind( STAFString aIn, 
                       STAFString aServer )
{
    ServerParam sServer;
    SChar       sData1[BUFFER_SIZE];
    SChar       sData2[BUFFER_SIZE];

    sServer = mServerMap[aServer];

    copyData( sData1,
              sServer["ALTIBASE_HOME"].replace("$ATC_HOME", mEnvRESULT).buffer(),
              sServer["ALTIBASE_HOME"].replace("$ATC_HOME", mEnvRESULT).length());
    copyData( sData2,
              aIn.buffer(),
              aIn.length() );

    IDE_TEST( mLogger.logValgrind( sData2, sData1 ) != IDE_SUCCESS );

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;
        
    debug( "logValgrind error" );

    return IDE_FAILURE;
}

IDE_RC
Servicer::getAgentData( STAFString   aID,
                        SChar      * aIP,
                        SInt       * aPort ) 
{
    rsystemData sRsystem;

    if( mRsystemMap.find( aID ) == mRsystemMap.end() )
    {
        return IDE_FAILURE;
    }

    sRsystem = mRsystemMap[aID];

    sprintf( aIP, "%s", sRsystem.ip );

    *aPort = sRsystem.port;

    return IDE_SUCCESS;
}

