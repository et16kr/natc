/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: laborerThread.cpp 1116 2007-01-22 08:35:53Z shsuh $
 **********************************************************************/

#include "laborerThread.h"
#include "altibaseHandler.h"
#include "serviceManager.h"
#include "serviceThread.h"

#include "host.h"

#if !defined(STAF_OS_NAME_WIN32)
#include <stdlib.h>
#include <fcntl.h>
#endif

#define SLEEP_TIMEOUT 10000

Laborer::Laborer()
    : atsBaseThread( 1024 * 1024 )
{
}

IDE_RC                
Laborer::initialize( Servicer * aServicer,
                     STAFString aProcess,
                     logonData  aLogonData )
{
    queryData sData;
    SChar    *sEnv = NULL;
    STAFRC_t  sEcode = kSTAFUnknownError;

    mEnd     = ID_FALSE;
    mSbegin  = ID_FALSE;
    mRetry   = ID_TRUE;
    mLogon   = ID_FALSE;

    mProcess = aProcess;
    mServicer = aServicer;

    IDE_TEST( ServiceManager::registerHandle( mHandle ) != IDE_SUCCESS );

    memset( &mMutex, 0, ID_SIZEOF(mMutex) );
    IDE_TEST( pthread_mutex_init( &mMutex,
                                        NULL ) != 0 );

    mLogonData = aLogonData;

    //mMessage = new SChar[BUFFER_SIZE];
    //IDE_TEST( mMessage == NULL );

    mRunner = new AltibaseHandler( mServicer );

    IDE_TEST( mRunner->initialize( &mLogonData,
                                   mProcess,
                                   NULL,
                                   NULL ) != IDE_SUCCESS );

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;
    
    return IDE_FAILURE;
}

IDE_RC                
Laborer::destroy()
{
    int sRsysFd = 0;
    std::map<STAFString, int>::iterator sIterator; 

    for( sIterator = mRsysFds.begin(); 
         sIterator != mRsysFds.end(); 
         sIterator++ )
    {
        sRsysFd = sIterator->second;

        (void)logoutRsystem( &sRsysFd );
    }

    if( mRunner != NULL )
    {
        mRunner->destroy();
        delete mRunner;
        mRunner = NULL;
    }

/*
    if( mMessage != NULL )
    {
        delete []mMessage;
        mMessage = NULL;
    }
*/

    IDE_TEST( pthread_mutex_destroy( &mMutex ) != 0 );

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

void                  
Laborer::run()
{
    UInt sLevel = 0;

    while( 1 )
    {
        IDE_TEST( lock() != 0 );
        sLevel = 1;

        if( mEnd != ID_TRUE )
        {
            if( mQuery.size() == 0 )
            { 
                sLevel = 0;
                IDE_TEST( unlock() != 0 );

                usleep( SLEEP_TIMEOUT );
                continue;
            }
            else
            {
                sLevel = 0;
                IDE_TEST( unlock() != 0 );

                IDE_TEST( runReal() != IDE_SUCCESS );
            }
        }
        else
        {
            if( mQuery.size() != 0 )
            {
                sLevel = 0;
                IDE_TEST( unlock() != 0 );

                IDE_TEST( runReal() != IDE_SUCCESS );
            }
            else
            {
                break;
            }
        }
    }

    if( sLevel != 0 )
    {
        sLevel = 0;
        (void)unlock();
    }

    return;

    IDE_EXCEPTION_END;

    if( sLevel != 0 )
    {
        sLevel = 0;
        (void)unlock();
    }   

    return; 
}

IDE_RC 
Laborer::runReal()
{
    queryData     sData;
    queryData     sQueryRecPtr;
    SChar         sBuffer[BUFFER_SIZE*4];
    SChar         sData1[128];
    SChar         sData2[128];
    SInt          sSize;
    logonData     sLogonData;
    UInt          sLevel = 0;
    STAFString    sResult;
    STAFString    sEnv;
    STAFString    sEnv1;
    STAFString    sEnv2;
    STAFString    sEnv3;
    STAFString    sResultOnly;
    STAFString    sTemp;
    STAFString    sTdxQueryTemp;
    STAFString    sTdxResultTemp;
    STAFString    sResult2;
    // altibase handler로 execute 하지 않는 종류의 문장
    idBool        sIsNormalString;

    while( 1 )
    {
        sIsNormalString = ID_FALSE;

        IDE_TEST( lock() != 0 );
        sLevel = 1;

        makeTdxPrefix();
        mTdxStringResult = "";

        mStatus = ""; 

        if( mQuery.size() == 0 )
        {
            break;
        }

        sData = *(mQuery.begin());
        mQuery.pop_front();
        
        sSize = sData.query.toCurrentCodePage()->length(); 
        copyData( sBuffer, 
                  sData.query.toCurrentCodePage()->buffer(), 
                  sSize ); 
 
        if( sData.loc != 0 )
        {
            mStatus = "+ $";
            mStatus += mProcess;
            mStatus += "> (";
            mStatus += sData.loc;
            mStatus += ") ";
            mStatus += STAFString(sBuffer).strip();

            mSystemStatus = "$";
            mSystemStatus += mProcess;
            mSystemStatus += "> (";
            mSystemStatus += sData.loc;
            mSystemStatus += ") ";
        }

        sLevel = 0;
        IDE_TEST( unlock() != 0 );

        switch( sData.type )
        {
            case STRING_COM:
            {
                sIsNormalString = ID_TRUE;
                mResult += sData.query;

                mTdxStringResult = mTdxPrefix + sData.query;
                break;
            }
            case RESTART_COM:
            {
                sIsNormalString = ID_TRUE;
                mResult += sData.query;
                mTdxStringResult = mTdxPrefix + sData.query;

                if( sData.query.subWord( 1, 1 ).upperCase() == "ON" )
                {
                    mRetry = ID_TRUE;
                }
                else
                {
                    mRetry = ID_FALSE;
                }
                break;
            }
            case APPEND_COM:
            {
                sIsNormalString = ID_TRUE;
                sTemp =  "--+APPEND_LST";
                sTemp += " ";
                sTemp += sData.query;
                sTemp += ";\n";

                mResult += sTemp;
                mTdxStringResult = mTdxPrefix + sTemp;

                runLoad( sData.query.strip() );

                break;
            }
            case ENV_COM:
            {
                sIsNormalString = ID_TRUE;
                sEnv = sData.query;
                sEnv = sEnv.replace("=", " ");

                sEnv1 = sEnv.subWord(0, 1);
                sEnv2 = sEnv.subWord(1, 1);
                sEnv3 = sEnv.subWord(2, 1);

                // @DB1 a test 001
                // sEnv1 => "@DB1" sEnv2 => "a"
                // sEnv3 => "test"
                // sEnv.subWord(2) => "test 001"
                if( sEnv1.subString(0,1) == "@" )
                {
                    if( sEnv.subWord(2).strip().length() != 0 )
                    {
                        mServicer->addEnv( sEnv2, 
                                           sEnv.subWord(2), 
                                           mServicer->mServerAlias[sEnv1.subString(1)] );
                    }
                    else
                    {
                        //fix BUG-14285
                        mServicer->rmEnv( sEnv2, 
                                          mServicer->mServerAlias[sEnv1.subString(1)] );
                    }
                }
                else
                {
                    if( sEnv.subWord(1).strip().length() != 0 )
                    {
                        mServicer->addEnv( sEnv1, 
                                           sEnv.subWord(1), 
                                           "DEFAULT" );
                    }
                    else
                    {
                        //fix BUG-14285 
                        mServicer->rmEnv( sEnv1, 
                                          "DEFAULT" );
                    }
                }
                break;
            }
            case SYSTEM_COM:
            {
                sIsNormalString = ID_TRUE;
                sTemp = "--+SYSTEM ";
                sTemp += sData.query;
                sTemp += ";";

                mResult += sTemp;
                mTdxStringResult = mTdxPrefix + sTemp;

                if( sData.query.subWord( 0, 1 ).subString( 0, 1 ) == "@" )
                {
                    runSystem( mServicer->replaceServicePort(sData.query.subWord(1)), 
                               sData.query.subWord( 0, 1 ).subString(1) );
                }
                else
                {
                    runSystem( mServicer->replaceServicePort(sData.query), 
                               "DEFAULT" );
                }
                break;
            }
            case RSYSTEM_COM:
            {
                sIsNormalString = ID_TRUE;
                sTemp = "--+RSYSTEM ";
                sTemp += sData.query;
                sTemp += ";";

                mResult += sTemp;
                mTdxStringResult = mTdxPrefix + sTemp;

                if( sData.query.subWord( 1, 1 ).subString( 0, 1 ) == "@" )
                {
                    runRsystem( sData.query.subWord( 2 ), 
                                sData.query.subWord( 1, 1 ).subString(1),
                                sData.query.subWord( 0, 1 ) );
                }
                else
                {
                    runRsystem( sData.query.subWord( 1 ), 
                               "DEFAULT",
                               sData.query.subWord( 0, 1 ) );
                }
                break;
            }
            case START1_COM:
            {
                sIsNormalString = ID_TRUE;
                sTemp = "$";
                sTemp += mProcess;
                sTemp += "> ";
                sTemp += sData.sysdba + " ";
                sTemp += sData.query;
                sTemp += ";\n";

                mResult += sTemp;
                mTdxStringResult = mTdxPrefix + sTemp;

                runSystem2( STAFString("is -silent -f ") + sData.query );
                break;
            }
            case START2_COM:
            {
                sIsNormalString = ID_TRUE;
                sTemp = "$";
                sTemp += mProcess;
                sTemp += "> ";
                sTemp += "@";
                sTemp += sData.query;
                sTemp += ";\n";

                mResult += sTemp;
                mTdxStringResult = mTdxPrefix + sTemp;

                runSystem2( STAFString("is -silent -f ") + sData.query );
                break;
            }
            case POST_COM:
            {
                sIsNormalString = ID_TRUE;
                sTemp = "$";
                sTemp += mProcess;
                sTemp += "> ";
                sTemp += "--+POST ";
                sTemp += sData.query;
                sTemp += "; ";

                mResult += sTemp;
                mTdxStringResult = mTdxPrefix + sTemp;

                runPost( sData.query );

                break;
            }
            case WAIT_COM:
            {
                sIsNormalString = ID_TRUE;
                sTemp = "$";
                sTemp += mProcess;
                sTemp += "> ";
                sTemp += "--+WAIT ";
                sTemp += sData.query;
                sTemp += "; ";

                mResult += sTemp;
                mTdxStringResult = mTdxPrefix + sTemp;

                runWait( sData.query );

                break;
            }
            case SKIP_COM:
            {
                sIsNormalString = ID_TRUE;

                if( sData.query == "begin" )
                {
                    mResult += "--+SKIP BEGIN; ";
                    mTdxStringResult = mTdxPrefix + "--+SKIP BEGIN; ";
                    mSbegin = ID_TRUE;
                }
                else
                {
                    mResult += "--+SKIP END; ";
                    mTdxStringResult = mTdxPrefix + "--+SKIP END; ";
                    mSbegin = ID_FALSE;
                }
                break;
            }
            case DESC_COM:
            case DESC_DOLLAR_COM:
            {
                sData.table = sData.table.replace(".", " ");
             
/* 
                if( sData.table.numWords() == 1 )
                { 
                    mRunner->setTable( sData.table );
                }
                else
                {
                    mRunner->setUser( sData.table.subWord(0,1) );
                    mRunner->setTable( sData.table.subWord(1,1) );
                }
*/ 
               break;
            }
            case CONNECT_COM:
            {
/*
                mRunner->setUser( sData.user );
                mRunner->setLoginUser( sData.user );
                mRunner->setPassword( sData.password );
                mRunner->setSysdba( sData.sysdba == "sysdba" ? ID_TRUE : ID_FALSE );
*/
                break;
            }
            case AUTOCOMMIT_COM:
            {
/*
                if( sData.query.upperCase().find( "ON" ) 
                                                  != STAFString::kNPos )
                {
                    mRunner->setAutocommit( ID_TRUE );
                }
                else
                {
                    mRunner->setAutocommit( ID_FALSE );
                }
*/
                break;
            }
            case TIMING_COM:
            {
/*
                sIsNormalString = ID_TRUE;
                sTemp = "$";
                sTemp += mProcess;
                sTemp += "> ";
                sTemp += sData.query;
                sTemp += ";";

                mResult += sTemp;
                mTdxStringResult = mTdxPrefix + sTemp;

                if( sData.query.upperCase().find( "ON" ) 
                                                  != STAFString::kNPos )
                {
                    mRunner->setTiming( ID_TRUE );
                }
                else
                {
                    mRunner->setTiming( ID_FALSE );
                }
*/
                break;
            }
            case HEADING_COM:
            {
/*
                sIsNormalString = ID_TRUE;
                sTemp = "$";
                sTemp += mProcess;
                sTemp += "> ";
                sTemp += sData.query;
                sTemp += ";";

                mResult += sTemp;
                mTdxStringResult = mTdxPrefix + sTemp;

                if( sData.query.upperCase().find( "ON" )
                                                  != STAFString::kNPos )
                {
                    mRunner->setHeading( ID_TRUE );
                }
                else
                {
                    mRunner->setHeading( ID_FALSE );
                }
*/
                break;
            }
            case FOREIGNKEYS_COM:
            {
/*
                sIsNormalString = ID_TRUE;
                sTemp = "$";
                sTemp += mProcess;
                sTemp += "> ";
                sTemp += sData.query;
                sTemp += ";";

                mResult += sTemp;
                mTdxStringResult = mTdxPrefix + sTemp;

                if( sData.query.upperCase().find( "ON" ) 
                                                  != STAFString::kNPos )
                {
                    mRunner->setForeignkeys( ID_TRUE );
                }
                else
                {
                    mRunner->setForeignkeys( ID_FALSE );
                }
*/
                break;
            }
            case SYMBOL_COM:
            {
/*
                sIsNormalString = ID_TRUE;
                sTemp = "$";
                sTemp += mProcess;
                sTemp += "> ";
                sTemp += sData.query;

                mResult += sTemp;
                mTdxStringResult = mTdxPrefix + sTemp;

                copyData( sData1, 
                          sData.symbol.name.buffer(), 
                          sData.symbol.name.length() );
                copyData( sData2, 
                          sData.symbol.scale.buffer(), 
                          sData.symbol.scale.length() );

                //mSymbol.add( sData1,
                //            (iSQLVarType)sData.symbol.type.asUInt(),
                //            sData.symbol.precision.asUInt(),
                //            sData2 );

                //sResult = mSymbol.getResult().strip();
                if( sResult.length() != 0 )
                {
                    mResult += "\n";
                    mTdxStringResult += "\n";
                }
                mResult += sResult;
                mTdxStringResult += sResult;
*/
                break;
            }
            case PRINT_COM:
            {
/*
                sIsNormalString = ID_TRUE;
                sTemp = "$";
                sTemp += mProcess;
                sTemp += "> ";
                sTemp += sData.query;
                sTemp += "\n";

                mResult += sTemp;
                mTdxStringResult = mTdxPrefix + sTemp;

                copyData( sData1,
                          sData.sysdba.buffer(),
                          sData.sysdba.length() );

                // print var 또는 print varirable 을 
                // 수행했을 경우
                if( sData.sysdba == "all" )
                {
                    //mSymbol.print();
                }
                else
                {
                    //mSymbol.showVar( sData1 );
                }
                //mResult += mSymbol.getResult();
                //mTdxStringResult += mSymbol.getResult() + "\n";
*/ 
               break;
            }
            case EXECUTE_COM:
            {
/*
                sIsNormalString = ID_TRUE;
                sTemp = "$";
                sTemp += mProcess;
                sTemp += "> ";
                sTemp += sData.query;
                sTemp += ";";
                sTemp += "\n";

                mResult += sTemp;
                mTdxStringResult = mTdxPrefix + sTemp;

                copyData( sData1, 
                          sData.user.buffer(), 
                          sData.user.length() );
                copyData( sData2, 
                          sData.sysdba.buffer(), 
                          sData.sysdba.length() );

                // exec :a := NULL 일 경우
                if( strlen( sData2 ) == 0 )
                {
                    //mSymbol.setValue( sData1 );
                }
                else
                {
                    //mSymbol.setValue( sData1, sData2 );
                }
                //mResult += mSymbol.getResult();
                //mTdxStringResult += mSymbol.getResult() + "\n";
*/
                break;
            }
            case EXEC_FUNC_COM:
            {
                //mRunner->setUser( sData.user );
                //mRunner->setProcedure( sData.table );
                break;
            }
            case EXEC_PROC_COM:
            {
                //mRunner->setUser( sData.user );
                //mRunner->setProcedure( sData.table );
                break;
            }
            case RECPOINT_COM:
            {
                //mRunner->setUser( sData.user );
                //mRunner->setProcedure( sData.table );
                sQueryRecPtr = sData;

                sTemp = "$";
                sTemp += mProcess;
                sTemp += "> ";
                sTemp += "--+";
                sTemp += sData.realQuery;
                sTemp += "; ";

                mResult += sTemp;
                mTdxStringResult = mTdxPrefix + sTemp;

                break;
            }
            case SHELL_COM:
            {
                sIsNormalString = ID_TRUE;
                sTemp = "$";
                sTemp += mProcess;
                sTemp += "> ";
                sTemp += "!";
                sTemp += sData.query;
                sTemp += ";\n";

                mResult += sTemp;
                mTdxStringResult = mTdxPrefix + sTemp;
                
                runSystem2( sData.query );
                break;
            }
            case ALTER_COM:
            {
/*
                sEnv = sData.query;
                sEnv = sEnv.upperCase();
                sEnv = sEnv.replace(" ","").replace("\t","").replace("=", " " );
                if( sEnv.find( "ALTER""SESSION""SET""EXPLAIN""PLAN" ) != STAFString::kNPos )
                {
                    SInt sExplainPlanMode;

                    sData.type = EXPLAIN_PLAN_COM;

                    if( sEnv.subWord(1) == "ONLY" )
                    {
                        sExplainPlanMode = EXPLAIN_PLAN_ONLY;
                    }
                    else if( sEnv.subWord(1) == "OFF" )
                    {
                        sExplainPlanMode = EXPLAIN_PLAN_OFF;
                    }
                    else if( sEnv.subWord(1) ==  "ON" )
                    {
                        sExplainPlanMode = EXPLAIN_PLAN_ON;
                    }
                    else
                    {
                        sData.type = ALTER_COM;
                    }

                    //if (sData.type == EXPLAIN_PLAN_COM)
                    //{
                    //    mRunner->setSessionKind(sExplainPlanMode);
                    //}
                }
                else if( sEnv.find( "ALTER""SESSION""SET""AUTOCOMMIT" ) != STAFString::kNPos)
                {
                    idBool sAutocommit;

                    sData.type = AUTOCOMMIT_COM;

                    if( sEnv.subWord(1) == "TRUE" )
                    {
                        sAutocommit = ID_TRUE;
                    }
                    else if( sEnv.subWord(1) == "FALSE" )
                    {
                        sAutocommit = ID_FALSE;
                    }
                    else
                    {
                        sData.type = ALTER_COM;
                    }

                    //if (sData.type == AUTOCOMMIT_COM)
                    //{
                    //    mRunner->setAutocommit( sAutocommit );
                    //}
                }
                else if ( (sEnv.find( "ALTER""SESSION""SET""DATE_FORMAT" ) != STAFString::kNPos) ||
                          (sEnv.find( "ALTER""SESSION""SET""DEFAULT_DATE_FORMAT" ) != STAFString::kNPos) )
                {
                    unsigned int sFrom;
                    unsigned int sTo;

                    sEnv1 = sData.query;
                    sFrom = sEnv1.find("'");
                    sTo   = sEnv1.findLastOf("'");

                    if ((sFrom != STAFString::kNPos) &&
                        (sTo   != STAFString::kNPos) &&
                        (sFrom <  sTo))
                    {
                        mRunner->setDateFormat( sEnv1.subString(sFrom + 1, sTo - sFrom - 1) );

                        sData.type = DATEFORMAT_COM;
                    }
                }
*/
            }
            case CREATE_OBJ_COM:
            case CREATE_PROC_COM:
            case PREP_INSERT_COM:
            case PREP_SELECT_COM:
            case PREP_UPDATE_COM:
            case PREP_DELETE_COM:
            case PREP_MOVE_COM:
            case PREP_ENQUEUE_COM:
            case PREP_DEQUEUE_COM:
            {
                mRunner->setRealQuery( sData.realQuery );
                break;
            }
            default:
            {
                break;
            }
          
        }

        // sIsNormalString:
        // SYMBOL_COM PRINT_COM   SHELL_COM       STRING_COM SKIP_COM
        // POST_COM   WAIT_COM    SYSTEM_COM      APPEND_COM LOAD_SQL_COM
        // TIMING_COM HEADING_COM FOREIGNKEYS_COM ENV_COM    RESTART_COM
        // START1_COM START2_COM  EXECUTE_COM
        
        if ( sIsNormalString == ID_FALSE )
     	{
            if ( mServicer->getAtsTestKind() == ATS_TEST_NORMAL )
            {
                IDE_TEST( logon() != IDE_SUCCESS );
                
                // tdx 파일에 들어가는 내용
                // execute 전에, query만 write
                makeTdxPrefix();
                sTdxQueryTemp = mTdxPrefix + "$" + mProcess + "> " + sBuffer + "\n";
                
                IDE_TEST( mRunner->execute( sBuffer, 
                                            sData.type ) != IDE_SUCCESS );
                
                // tdx 파일에 들어가는 내용
                // execute 후에, result만 write
                makeTdxPrefix();
                sResultOnly = mRunner->getResultOnly();
                sTdxResultTemp = mTdxPrefix + sResultOnly;
                
                // out 파일에 들어가는 내용
                sResult = mRunner->getResult( ID_TRUE );
                
                if( (sResult.find( "ERR-91015" ) !=  STAFString::kNPos) ||
                    (sResult.find( "ERR-91020" ) !=  STAFString::kNPos) ||
                    (sResult.find( "ERR-51036" ) !=  STAFString::kNPos) )
                {
                    if( mRetry == ID_TRUE )
                    {
                        mRunner->clear();
                        
                        mServicer->getLogonData( &sLogonData,
                                                 mProcess );

                        //fix BUG-15963
                        //if( sData.type != EXPLAIN_PLAN_COM )
                        //{
                        //    mRunner->setSessionKindOnly(EXPLAIN_PLAN_OFF);
                        //} 
                        IDE_TEST( mRunner->logon( &sLogonData ) != IDE_SUCCESS );
                        
                        // tdx 파일에 들어가는 내용
                        // execute 전에, query만 write
                        makeTdxPrefix();
                        sTdxQueryTemp = mTdxPrefix + "$" + mProcess + "> " + sBuffer + "\n";
                        
                        IDE_TEST( mRunner->execute( sBuffer, 
                                                    sData.type ) != IDE_SUCCESS );
                        // tdx 파일에 들어가는 내용
                        // execute 후에, result만 write
                        makeTdxPrefix();
                        sResultOnly = mRunner->getResultOnly();
                        sTdxResultTemp = mTdxPrefix + sResultOnly;
                    }
                }
                
                if( mSbegin != ID_TRUE )
                {
                    mResult += mRunner->getResult();
                }
                else
                {
                    mRunner->clear();
                    
                    mResult += "$"; 
                    mResult += mProcess; 
                    mResult += "> "; 
                    mResult += sData.query;
                    if( sData.query.buffer()[sData.query.length() - 1] != ';' )
                    {
                        mResult += ";"; 
                    } 
                    
                    if ( sTdxQueryTemp.subString( sTdxQueryTemp.length() - 1, 1 ) == "\n" )
                    {
                        sTdxQueryTemp = sTdxQueryTemp.subString( 0, sTdxQueryTemp.length() - 1 );
                    }
                    sTdxResultTemp = "";
                }
                
                mTdxResult += sTdxQueryTemp + sTdxResultTemp;
            }
            else
            {
                // PRJ-1552 Art 테스트 기능 수행
                IDE_TEST( executeArtTest( sBuffer,        // 실제 실행 Query 문자열
                                          &sData,         // 현재 query data
                                          &sQueryRecPtr ) // recptr관련 query data
                          != IDE_SUCCESS );
            }
 	}  
        
        // SQL이 아닌 경우 따로 mTdxResult에 추가해준다.
        if ( mTdxStringResult != "" )
        {
            mTdxResult += mTdxStringResult;
        }

        if( (sData.type == START1_COM) ||
            (sData.type == START2_COM) ||
            (sData.type == SHELL_COM) )
        {
            mResult = mResult.strip();
        }
    } // end of while

    if( sLevel != 0 )
    {
        sLevel = 0;
        (void)unlock();
    }   
 
    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    mEnd = ID_TRUE;

    // FATAL 일 경우,
    // 해당 라인 print하고, 연결 에러 메시지 print
    mResult += mStatus;
    mResult += "\n";
    mResult += mRunner->getResult();

    makeTdxPrefix();
    mTdxResult += mTdxPrefix + mRunner->getResult() + "\n";

    if( sLevel != 0 )
    {
        sLevel = 0;
        (void)unlock();
    }

    return IDE_FAILURE;
}

SInt
Laborer::lock()
{
    return pthread_mutex_lock( &mMutex );
}

SInt
Laborer::unlock()
{
    return pthread_mutex_unlock( &mMutex );
}

IDE_RC
Laborer::end()
{
    mEnd = ID_TRUE;

    return IDE_SUCCESS;
}

IDE_RC
Laborer::push_back( queryData aQuery )
{
    UInt sLevel = 0;

    IDE_TEST( lock() != 0 );
    sLevel = 1;
   
    mQuery.push_back( aQuery );
 
    sLevel = 0;
    IDE_TEST( unlock() != 0 );

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    if( sLevel != 0 )
    {
        (void)unlock();
    }

    return IDE_FAILURE;
}

IDE_RC
Laborer::push_back( QueryList *aQuery )
{
    QueryIterator sIterator;
    UInt sLevel = 0;

    IDE_TEST( lock() != 0 );
    sLevel = 1;
  
    for( sIterator = aQuery->begin();
         sIterator != aQuery->end();
         sIterator++ )
    { 
        mQuery.push_back( *sIterator );
    }

    aQuery->clear();

    sLevel = 0;
    IDE_TEST( unlock() != 0 );

    return IDE_SUCCESS;

    if( sLevel != 0 )
    {
        (void)unlock();
    }

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}


IDE_RC
Laborer::sync()
{
    UInt sLevel = 0;

    while( 1 )
    {
        if( mEnd == ID_TRUE )
        {
            break;
        }

        IDE_TEST( lock() != 0 );
        sLevel = 1;

        if( mQuery.size() == 0 )
        {
            break;
        }
        else
        {
            sLevel = 0;
            IDE_TEST( unlock() != 0 );

            usleep( SLEEP_TIMEOUT );

            continue;
        }
    }
    
    if( sLevel != 0 )
    {    
        IDE_TEST( unlock() != 0 );
    }

    return IDE_SUCCESS;

    if( sLevel != 0 )
    {
        (void)unlock();
    }

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

STAFString
Laborer::getResult()
{
    STAFString sResult;

    sResult = mResult;

    mResult = "";

    return sResult;
}

STAFString   
Laborer::getTdxResult()
{   
    STAFString sResult;

    sResult = mTdxResult;
    
    mTdxResult = "";
    
    return sResult;
}   

IDE_RC                
Laborer::runPost( STAFString aIn )
{
    STAFResultPtr sResult;
    STAFString    sRequest;

    //PULSE allows you to post and then reset an event semaphore as a single atomic action. 
    sRequest += "pulse event ";
    sRequest += aIn;

    sResult = mHandle->submit( "local",
                               "sem",
                               sRequest );    

    IDE_TEST( sResult->rc != 0 );

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC                
Laborer::runWait( STAFString aIn )
{
    STAFResultPtr sResult;
    STAFString    sRequest;

    sRequest += "wait event ";
    sRequest += aIn;
    sRequest += STAFString(" timeout ") + STAFString(mServicer->mEVENT_TIMEOUT);

    sResult = mHandle->submit( "local",
                               "sem",
                               sRequest );    

    IDE_TEST( sResult->rc != 0 );

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

// runSystem 함수는 특정 DB 환경에서 사용되는 system 명령을 위한 것임.
#if defined(STAF_OS_NAME_WIN32)
IDE_RC                
Laborer::runSystem( STAFString aIn, STAFString aAlias )
{
    SChar         sData[BUFFER_SIZE];
    STAFResultPtr sResult;
    STAFString    sRequest;

    sRequest += "start shell command ";
    sRequest += STAFHandle::wrapData( mServicer->getEnv4System( aAlias ) + aIn.replace("{","").replace("}","").replace("$ATC_HOME", mServicer->mEnvCASE).replace("$ALTIBASE_HOME", mServicer->mEnvHOME).replace("\\", "/").replace("^", "^^"));

    if( mServicer->server( aAlias ) == "local" )
    {
        sRequest += " SAMECONSOLE WAIT STDERRTOSTDOUT STDOUTAPPEND ";
        sRequest += mServicer->mEnvRESULT + FILE_SEPARATORS + "work" + FILE_SEPARATORS + "log" + FILE_SEPARATORS + SYSTEM_LOG;
    }
    else
    {
        sRequest += " SAMECONSOLE WAIT STDERRTOSTDOUT STDOUTAPPEND rsystem.log";
    }

    if( mServicer->mDEBUG == 1 )
    {
        mServicer->system( mServicer->mIn + ":\n" + mSystemStatus + sRequest );
    }
    else
    {
        mServicer->system( mServicer->mIn + ": " + mSystemStatus + aIn );
    }

    copyData( sData, 
              sRequest.toCurrentCodePage()->buffer(),
              sRequest.toCurrentCodePage()->length() );

    sResult = mHandle->submit( mServicer->server( aAlias ),
                               "process",
                               sData );    

    IDE_TEST( sResult->rc != 0 );
    
    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}
#else
IDE_RC Laborer::runSystem( STAFString aIn, STAFString aAlias )
{
    SChar          sData[BUFFER_SIZE];
    STAFResultPtr  sResult;
    STAFString     sRequest;
    STAFString     sFileName;
    SInt           sFid;
    SInt           sStdout;
    SInt           sStderr;
    pid_t          sPid;

    if( mServicer->server( aAlias ) == "local" )
    {
        sRequest += mServicer->getEnv4System( aAlias ) + aIn.replace("{","").replace("}","").replace("$ATC_HOME", mServicer->mEnvCASE);

        sFileName += mServicer->mEnvRESULT + FILE_SEPARATORS + "work" + FILE_SEPARATORS + "log" + FILE_SEPARATORS + SYSTEM_LOG;

        copyData( sData,
                      sFileName.toCurrentCodePage()->buffer(),
                      sFileName.toCurrentCodePage()->length() );

        sFid = open(sData, O_WRONLY | O_CREAT | O_APPEND, 0644);
        IDE_TEST(sFid < 0);
    }
    else
    {
        sRequest += "start shell command ";
        sRequest += STAFHandle::wrapData( mServicer->getEnv4System( aAlias ) + aIn.replace("{","").replace("}","").replace("^", "^^").replace("$ATC_HOME", mServicer->mEnvCASE) );
        sRequest += " SAMECONSOLE WAIT STDERRTOSTDOUT STDOUTAPPEND rsystem.log";
    }

    if( mServicer->mDEBUG == 1 )
    {
        mServicer->system( mServicer->mIn + ":\n" + mSystemStatus + sRequest );
    }
    else
    {
        mServicer->system( mServicer->mIn + ": " + mSystemStatus + aIn );
    }

    copyData( sData, 
              sRequest.toCurrentCodePage()->buffer(),
              sRequest.toCurrentCodePage()->length() );

    if( mServicer->server( aAlias ) == "local" )
    {
        sPid = fork();
        IDE_TEST(sPid < 0);

        if(sPid == 0)
        {
            sStdout = dup(STDOUT_FILENO);
            sStderr = dup(STDERR_FILENO);

            dup2(sFid, STDOUT_FILENO);
            dup2(sFid, STDERR_FILENO);

            execl("/usr/local/bin/bash", "/usr/local/bin/bash", "-c", sData, NULL);

            dup2(sStdout, STDOUT_FILENO);
            dup2(sStderr, STDERR_FILENO);

            close(sStdout);
            close(sStderr);
            exit(0);
        }
        else
        {
            waitpid(sPid, NULL, 0);
        }

        close(sFid);
    }
    else
    {
        sResult = mHandle->submit( mServicer->server( aAlias ),
                                               "process",
                                               sData );

        IDE_TEST( sResult->rc != 0 );
    }

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}
#endif

// runSystem2 함수는 default 환경에서 수행되는 함수
IDE_RC                
Laborer::runSystem2( STAFString aIn )
{
    FILE         *sIn = NULL;
    SChar         sData[BUFFER_SIZE];
    SChar         sLine[BUFFER_SIZE];

    STAFResultPtr sResult;
    STAFString    sRequest;

    sRequest += "start shell command ";
#if defined(STAF_OS_NAME_WIN32)
    sRequest += STAFHandle::wrapData( mServicer->getEnv4System( "DEFAULT" ) + aIn.replace("$ATC_HOME", mServicer->mEnvCASE).replace("$ALTIBASE_HOME", mServicer->mEnvHOME).replace("\\", "/") );
#else
    sRequest += STAFHandle::wrapData( mServicer->getEnv4System( "DEFAULT" ) + aIn.replace("$ATC_HOME", mServicer->mEnvCASE) );
#endif
    sRequest += " SAMECONSOLE WAIT STDERRTOSTDOUT STDOUT ";
    sRequest += mServicer->mEnvRESULT + FILE_SEPARATORS + "work" + FILE_SEPARATORS + "log" + FILE_SEPARATORS + "__$.log";

    sResult = mHandle->submit( "local",
                               "process",
                               sRequest );    

    IDE_TEST( sResult->rc != 0 );

    copyData( sData, 
              STAFString(mServicer->mEnvRESULT + FILE_SEPARATORS + "work" + FILE_SEPARATORS + "log" + FILE_SEPARATORS + "__$.log").buffer(),
              STAFString(mServicer->mEnvRESULT + FILE_SEPARATORS + "work" + FILE_SEPARATORS + "log" + FILE_SEPARATORS + "__$.log").length() );
                  
    if( mSbegin != ID_TRUE )
    {  
        sIn = fopen( sData, "r" );

        IDE_TEST( sIn == NULL );

        while( 1 )
        {
            if( fgets(sLine, ID_SIZEOF(sLine), sIn) != NULL )
            {
                if( strncmp( sLine, "$$EOF$$", 7 ) == 0 )
                {
                    continue;
                }
                else
                {
                    mResult += STAFString( sLine );
                }
            }
            else
            {
                break;
            }
        }

        IDE_TEST( fclose( sIn ) != 0 )
    }

    sRequest = "delete entry ";
    sRequest += mServicer->mEnvRESULT + FILE_SEPARATORS + "work" + FILE_SEPARATORS + "log" + FILE_SEPARATORS + "__$.log" + " confirm";

    sResult = mHandle->submit( "local",
                               "fs",
                               sRequest );
    IDE_TEST( sResult->rc != 0 );


    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC
Laborer::runLoad( STAFString aIn )
{
    FILE      *sIn = NULL;
    SChar      sData[1024];
    SChar      sLine[65536];
    UInt       sLength;
    STAFString sPath;

    sPath = mServicer->getPath() + FILE_SEPARATORS + aIn;

    copyData( sData,
              sPath.toCurrentCodePage()->buffer(),
              sPath.toCurrentCodePage()->length() );

    sIn = fopen( sData, "r" );

    if( sIn != NULL )
    {
        mResult += ">>> [";
        mResult += aIn;
        mResult += "] BEGIN <<<\n";  

        while( 1 )
        {
            // BUG-28665
            sLength = fread(sLine, 1, ID_SIZEOF(sLine), sIn);

            if( sLength > 0 )
            {
#if defined(STAF_OS_NAME_WIN32)
                mResult += STAFString( sLine, sLength ).replace("\r","");
#else
                mResult += STAFString( sLine, sLength );
#endif
            }
            else
            {
                break;
            }
        }
        IDE_TEST( fclose( sIn ) != 0 )
    
        mResult += ">>> [";
        mResult += aIn;
        mResult += "] END <<<";
    }
    else
    {
        mResult += ">>> [";
        mResult += aIn;
        mResult += "] NOT FOUND <<<";
    }

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC
Laborer::logon()
{
    if( mLogon == ID_FALSE )
    {
        mLogon = ID_TRUE;

        mServicer->getLogonData( &mLogonData,
                                 mProcess );

        return mRunner->logon( &mLogonData );
    }
    else
    {
        return IDE_SUCCESS;
    }
}

void
Laborer::makeTdxPrefix()
{
    STAFString sBuffer;
    SChar      sTimeStr[10];

    mServicer->incrTdxTime();

    sprintf( sTimeStr, "%d", mServicer->getTdxTime() );

    mTdxPrefix = "&^<@!START!@>";
    mTdxPrefix += "&^";
    mTdxPrefix += STAFString( sTimeStr );
    mTdxPrefix += "&^";
    mTdxPrefix += mProcess;
    mTdxPrefix += "&^";
}

STAFString  
Laborer::status() 
{
    STAFString sStatus;

    IDE_TEST( lock() != IDE_SUCCESS );

    sStatus = mStatus;
    
    IDE_TEST( unlock() != IDE_SUCCESS );

    return sStatus; 

    IDE_EXCEPTION_END;

    assert( 0 );
}

idBool
Laborer::checkServer() 
{
    STAFString    sData;
    idBool        sIsRECKILL;
    
    sData = mServicer->mRecPointer.getLastLineFromBootLog();
    
    if ( sData.find("IDU_REC_POINT_KILL") != STAFString::kNPos)
    {
        // REC KILL
        mServicer->setHit(ID_TRUE);
        
        runSystem( "server start;", "DEFAULT" );
        
        sIsRECKILL = ID_TRUE;
    }
    else
    {
        // BUG KILL
        sIsRECKILL = ID_FALSE;
    }

    return sIsRECKILL;
}

IDE_RC
Laborer::cleanServer() 
{
    STAFString      sData;
    SChar           sCommand[1024];

    sData = "sh artComp " + mServicer->getTGZpath() + ";";

    copyData( sCommand,
              sData.buffer(),
              sData.length());

    runSystem( sCommand,  "DEFAULT" );
    runSystem( "clean;",  "DEFAULT" );
    runSystem( "server start;", "DEFAULT" );
    
    mServicer->setCrash(ID_TRUE);

    return IDE_SUCCESS;
}

IDE_RC
Laborer::executeArtTest( SChar*       aBuffer,
                         queryData*   aQuery,
                         queryData*   aQueryRecPtr )
{
    logonData     sLogonData;
    STAFString    sResult;
    STAFString    sResult2;
    STAFString    sResultOnly;
    STAFString    sTdxQueryTemp;
    STAFString    sTdxResultTemp;
    idBool        sIsCheckServer;
    idBool        sIsBUGKILL;
    
    sIsCheckServer = ID_FALSE;
    sIsBUGKILL     = ID_FALSE;

    assert( mServicer->getAtsTestKind() != ATS_TEST_NORMAL );

    if ( mServicer->getArtRestart() == ID_TRUE ) 
    {
        /*************************************************
         * 가. HIT 이후 : ats가 서버를 다시 재구동한 경우
         *     ( restart 플래그가 TRUE인경우 )
         *************************************************/
        
        if ( logon() != IDE_SUCCESS )
        {
            /*************************************************
             * 1. 재구동이후에도 logon이 실패한 경우
             *    : PROCESS[0]가 처리함.
             *    : cleanServer를 수행하고, logon 수행
             *************************************************/            

            if ( mProcess == "P0" )
            {
                // cleanServer : tar/clean/server start를 수행한다.
                mRunner->clear();
                cleanServer(); 
                mLogon = ID_FALSE;
            }
            
            //cout << "[step0-2] : logon " << endl; 
            IDE_TEST( logon() != IDE_SUCCESS );
        }
        else
        {
            /*************************************************
             * 2. 재구동이후에도 logon 성공
             *************************************************/            
            //cout << "[step0-1] : logon success" << endl; 
            //cout << " STARTUP SUCCESS ::  " << endl;
        }

        /*************************************************
         * 3. HIT이후에 Restart 플래그를 ID_FALSE로 설정
         *    : PROCESS[0]가 처리함.
         *************************************************/            
        if ( mProcess == "P0" )
        {
            mServicer->setArtRestart( ID_FALSE );
        }
    }
    else 
    {
        /*************************************************
         * 나. 일반적인 경우 ( restart 플래그가 FALSE 인경우 )
         *************************************************/
        
        if ( logon() != IDE_SUCCESS )
        {
            /*************************************************
             * 1. logon 실패
             *************************************************/
            
            /*
               서버가 운영중이지 않은경우에 복구지점 관련 명령이 테스트케이스
               상에 존재하는 경우 실패하게 되는데 이때에는 logon이 실패하므로
               중단하지 않고 수행하도록 처리
               
               --+TEST_RECPTR CLEAR; // 실행될리 없다. 실패지만 계속진행한다.
               --+clean;
               --+server start;

               하지만, 그 외의 명령을 수행하다 logon이 실패하면 중단..
            */
            
            IDE_TEST( aQuery->type != RECPOINT_COM );
        }
        else
        {
            /*************************************************
             * 2. logon이 성공
             *************************************************/
        }
    }

    /*************************************************
     * 다. Query 실행 
     *************************************************/
    
    makeTdxPrefix();
    sTdxQueryTemp = mTdxPrefix + "$" + mProcess + "> " + aBuffer + "\n";

    IDE_TEST( mRunner->execute( aBuffer,
                                aQuery->type ) != IDE_SUCCESS );

    makeTdxPrefix();
    sResultOnly = mRunner->getResultOnly();
    sTdxResultTemp = mTdxPrefix + sResultOnly;

    // out 파일에 들어가는 내용
    sResult = mRunner->getResult( ID_TRUE );

    /*************************************************
     * 라. Query 결과 확인 
     *************************************************/
    if( (sResult.find( "ERR-91015" ) !=  STAFString::kNPos) ||
        (sResult.find( "ERR-91020" ) !=  STAFString::kNPos) ||
        (sResult.find( "ERR-51036" ) !=  STAFString::kNPos) )
    {
        assert ( mServicer->getArtRestart() == ID_FALSE );

        mServicer->getLogonData( &sLogonData, mProcess );
        sResult2 = mRunner->getResult();
        mRunner->clear(); 
        /*************************************************
        * 1. 서버/클라이언트 접속관련 실행 에러 발생시
        *    기본적으로 query 재수행
        *************************************************/
        IDE_TEST( retryExecution4ART( aBuffer,
                                      aQuery,
                                      aQueryRecPtr,
                                      &sLogonData,
                                      &sIsCheckServer,
                                      &sIsBUGKILL )
                  != IDE_SUCCESS );
    }
    
    if( mSbegin != ID_TRUE )
    {
        /* SKIP_BEGIN이 아닌 경우 query와 result를 출력함 */
        
        if ( aQuery->type != RECPOINT_COM )
        {
            if ( (sIsCheckServer == ID_TRUE) && 
                 (sIsBUGKILL == ID_FALSE) )
            {
                /* 복구지점에 의해 죽은 경우 
                   첫번째 error를 저장하였다가 출력함 */
                mRunner->clear();
                mResult += sResult2;
            }
            else
            {
                mResult += mRunner->getResult();
            }
        }
        else
        {
            /* 복구지점 명령 수행후 재구동(checkserver)이
               된이후에 fatal 처리가 되면 이후에 clean
               서버를 하기때문에 여기서 fatal 플래그를
               clear한다. 이는 테스트를 계속 수행하기 위함 */
            
            mRunner->clear();

            if ( mServicer->getFatal() == ID_TRUE )
            {
                mServicer->clearFatal();
            }
        }
    }
    else
    {
        /* SKIP_BEGIN 인 경우 query만 출력함 */
        mRunner->clear();

        mResult += "$"; 
        mResult += mProcess; 
        mResult += "> "; 
        mResult += aQuery->query;
        mResult += ";"; 

        if ( sTdxQueryTemp.subString( sTdxQueryTemp.length() - 1, 1 ) == "\n" )
        {
            sTdxQueryTemp = sTdxQueryTemp.subString( 0, sTdxQueryTemp.length() - 1 );
        }
        sTdxResultTemp = "";
    }

    mTdxResult += sTdxQueryTemp + sTdxResultTemp;

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

/*************************************************
 * Decription : query 재수행
 *
 * 만약, query 재수행이 실패하면 서버비정상종료
 * 원인 확인하여 재구동하던지 FATAL 처리시킴
 *************************************************/
IDE_RC
Laborer::retryExecution4ART( SChar*       aBuffer,
                             queryData*   aQuery,
                             queryData*   aQueryRecPtr,
                             logonData*   aLogonData,
                             idBool*      aIsCheckServer,
                             idBool*      aIsBugKILL )
{
    STAFString sTdxQueryTemp;
    STAFString sTdxResultTemp;
    STAFString sResultOnly;

    if ( mRunner->logon( aLogonData ) == IDE_SUCCESS )
    {
        /*************************************************
         * 1) 재수행시 logon 성공
         *     다시 Query 수행 성공하면 계속 진행
         *     수행 실패하면 서버가 죽은 원인 확인해야함
         *************************************************/
        makeTdxPrefix();
        sTdxQueryTemp = mTdxPrefix + "$" + mProcess + "> " + aBuffer + "\n";
        
        if ( mRunner->execute( aBuffer, aQuery->type ) 
             == IDE_SUCCESS )
        {
            *aIsCheckServer = ID_FALSE;
            
            // tdx 파일에 들어가는 내용
            // execute 후에, result만 write
            makeTdxPrefix();
            sResultOnly = mRunner->getResultOnly();
            sTdxResultTemp = mTdxPrefix + sResultOnly;
        }
        else
        {
            *aIsCheckServer = ID_TRUE;
        }
    }
    else
    {
        /*************************************************
         * 2) 재수행시 logon 실패
         *    서버가 죽은 원인 확인 필요함.
         *************************************************/
        *aIsCheckServer = ID_TRUE;
    }

    /*************************************************
     * 3) 서버 비정상 종료 원인 확인 후 서버 재구동
     *************************************************/
    if ( *aIsCheckServer == ID_TRUE )
    {
        IDE_TEST( doCheckServer4ART( aQuery,
                                     aQueryRecPtr,
                                     aLogonData,
                                     aIsBugKILL )
                  != IDE_SUCCESS );
    }
        
    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

/*************************************************
 * Decription : 서버의 비정상종료 원인 확인
 *
 * 1. 복구지점에 의해 비정상종료했는지 확인
 *    -> 서버 재구동
 * 2. 버그에 의해 죽은 경우 FATAL 처리
 *************************************************/
IDE_RC
Laborer::doCheckServer4ART( queryData*    aQuery,
                            queryData*    aQueryRecPtr,
                            logonData*    aLogonData,
                            idBool*       aIsBugKILL )
{
    while (1)
    {
        if ( checkServer() == ID_TRUE )
        {
             *aIsBugKILL = ID_FALSE;
            /*************************************************
             * A. 복구지점에 의해 서버 비정상종료
             *    : 다시 서버 재구동시킴
             *************************************************/
            mServicer->setArtRestart( ID_TRUE );
            mLogon = ID_FALSE;

            if ( mServicer->getAtsTestKind() == ATS_TEST_FULL )
            {
                // full test케이스인 경우 복구지점을 서버가
                // 계속 비정상종료되기 때문에 서버가 재구동된
                // 이후에 계속 활성화 시켜야 하기때문에
                // query를 계속 강제로 추가함.
                mQuery.push_front( *aQueryRecPtr );
            }
        }
        else
        {
            *aIsBugKILL = ID_TRUE;
            /*************************************************
             * B. 일반적인 버그로 인한 서버 비정상종료
             *************************************************/
            if ( aQuery->type != RECPOINT_COM ) 
            {
                mRunner->clear();
                            
                IDE_TEST( mRunner->logon( aLogonData ) 
                          != IDE_SUCCESS );
            }
            else
            {
                // nothing to do..
            }
        }

        break;
    } 

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC
Laborer::logonRsystem( char *aIP, int aPort, int *aRsystemFd )
{
#if defined(STAF_OS_NAME_WIN32)
    WORD sVersion = MAKEWORD(1, 1);
    WSADATA sWsaData = { 0 };

    (void)WSAStartup(sVersion, &sWsaData);
#endif

    *aRsystemFd = connectServer( aIP, aPort );

    if( *aRsystemFd <= 0 )
    {
        IDE_RAISE( error );
    }

    return IDE_SUCCESS;

    IDE_EXCEPTION( error );
    IDE_EXCEPTION_END;

    return IDE_FAILURE;    
}

IDE_RC
Laborer::logoutRsystem( int *aRsystemFd )
{
    (void)disconnectServer( *aRsystemFd, NULL );

    return IDE_SUCCESS;
}

IDE_RC                
Laborer::runRsystem( STAFString aIn, STAFString aAlias, STAFString aID )
{
    SChar      sIP[1024];
    SInt       sPort;
    STAFString sRs; 
    SChar      sCommand[65535];
    SChar      sEnvs[65535];
    STAFString sData;
    SChar      sPath[1024];
    int        sRc;
    rsysBuf    sRsysBuf;
    int        sRsysFd = 0;

    // 현재 디렉토리의 경로를 얻어온다.
    sData = mServicer->getPath() + FILE_SEPARATORS;
    copyData( sPath,
              sData.buffer(),
              sData.length() );

    //cout << aIn << endl;
    //cout << aAlias << endl;
    //cout << aID << endl << endl;

    IDE_TEST( mServicer->getAgentData( aID, 
                                       sIP, 
                                       &sPort ) != IDE_SUCCESS );

    if( mRsysFds.find( aID ) == mRsysFds.end() )
    {
        IDE_TEST( logonRsystem( sIP, 
                                sPort, 
                                &sRsysFd ) != IDE_SUCCESS );

        mRsysFds[aID] = sRsysFd;
    } 
    else
    {
        sRsysFd = mRsysFds[aID];
    }

    mResult += "\n>>> [";
    mResult += aID;
    mResult += "] BEGIN <<<\n";  
 
    sRs = mServicer->getEnv4Rsystem( aAlias );

    copyData( sCommand, 
              aIn.buffer(), 
              aIn.length() );

    copyData( sEnvs, 
              sRs.buffer(), 
              sRs.length() );

    //cout << sEnvs << endl;

    sRc = execute( sRsysFd, 
                   sCommand, 
                   sEnvs, 
                   &sRsysBuf,
                   sPath );   
					   
    mResult += sRsysBuf.buffer;

    mResult += ">>> [";
    mResult += aID;
    mResult += "] END <<<";

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;
    
    mResult += "\nRSYSTEM error\n";

    return IDE_FAILURE;
}
