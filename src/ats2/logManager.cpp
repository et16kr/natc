/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: logManager.cpp 853 2006-08-31 01:24:14Z orc $
 **********************************************************************/

#include "logManager.h"
#include "pslx.h"

IDE_RC 
Logger::initialize( STAFString aEnvRESULT )
{
    SChar      sData1[1024];
    STAFString sData2;
    idBool     sExist = ID_FALSE;

    mEnvRESULT = aEnvRESULT;

    mERROR      = NULL;
    mEXCEPTION  = NULL;
    mREPORT     = NULL;
    mDEBUG      = NULL;
    mFAIL       = NULL;
    mLSTOUT     = NULL;
    mCRASH     = NULL;

    sData2 = aEnvRESULT + FILE_SEPARATORS + "work" + FILE_SEPARATORS + "log" + FILE_SEPARATORS + ERROR_LOG;
    copyData( sData1,
              sData2.buffer(),
              sData2.length() );
    IDE_TEST( (mERROR     = fopen( sData1, "a" )) == NULL );

    sData2 = aEnvRESULT + FILE_SEPARATORS + "work" + FILE_SEPARATORS + "log" + FILE_SEPARATORS + EXCEPTION_LOG;
    copyData( sData1,
              sData2.buffer(),
              sData2.length() );
    IDE_TEST( (mEXCEPTION = fopen( sData1, "a" )) == NULL );

    sData2 = aEnvRESULT + FILE_SEPARATORS + "work" + FILE_SEPARATORS + "log" + FILE_SEPARATORS + REPORT_LOG;
    copyData( sData1,
              sData2.buffer(),
              sData2.length() );
    IDE_TEST( (mREPORT = fopen( sData1, "a" )) == NULL );

    sData2 = aEnvRESULT + FILE_SEPARATORS + "work" + FILE_SEPARATORS + "log" + FILE_SEPARATORS + DEBUG_LOG;
    copyData( sData1,
              sData2.buffer(),
              sData2.length() );
    IDE_TEST( (mDEBUG = fopen( sData1, "a" )) == NULL );

    sData2 = aEnvRESULT + FILE_SEPARATORS + "work" + FILE_SEPARATORS + FAIL_LOG;
    copyData( sData1,
              sData2.buffer(),
              sData2.length() );

    if( access( sData1, F_OK ) == 0 )
    {
        sExist = ID_TRUE;
    }

    IDE_TEST( (mFAIL = fopen( sData1, "a" )) == NULL );

    if( sExist != ID_TRUE )
    {
        log( LOG_FAIL, "" );
        log( LOG_FAIL, "TestSuiteDescription     =   Test for Test Case where have got FAIL test" );
        log( LOG_FAIL, "#########################################################################" );
    }

    sData2 = aEnvRESULT + FILE_SEPARATORS + "work" + FILE_SEPARATORS + "log" + FILE_SEPARATORS + LSTOUT_LOG;
    copyData( sData1,
              sData2.buffer(),
              sData2.length() );
    IDE_TEST( (mLSTOUT = fopen( sData1, "a" )) == NULL );

    sData2 = aEnvRESULT + FILE_SEPARATORS + "work" + FILE_SEPARATORS + CRASH_LOG;
    copyData( sData1,
              sData2.buffer(),
              sData2.length() );

    if( access( sData1, F_OK ) == 0 )
    {
        sExist = ID_TRUE;
    }

    IDE_TEST( (mCRASH = fopen( sData1, "a" )) == NULL );

    if( sExist != ID_TRUE )
    {
        log( LOG_CRASH, "" );
        log( LOG_CRASH, "TestSuiteDescription     =   Test for Test Case where have got CRASH test" );
        log( LOG_CRASH, "#########################################################################" );
    }
    
    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC 
Logger::destroy()
{
    IDE_TEST( fclose( mERROR ) != 0 );
    IDE_TEST( fclose( mEXCEPTION ) != 0 );
    IDE_TEST( fclose( mREPORT ) != 0 );
    IDE_TEST( fclose( mDEBUG ) != 0 );
    IDE_TEST( fclose( mLSTOUT ) != 0 );
    IDE_TEST( fclose( mFAIL ) != 0 );
    IDE_TEST( fclose( mCRASH ) != 0 );

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;
 
    return IDE_FAILURE;
}

IDE_RC 
Logger::log( LogType aType, SChar *aData )
{
    switch ( aType )
    {
         case LOG_ERROR:
         {
             logERROR( aData );
             break;
         }
         case LOG_REPORT:
         {
             logREPORT( aData );
             break;
         }
         case LOG_EXCEPTION:
         {
             logEXCEPTION( aData );
             break;
         }
         case LOG_DEBUG:
         {
             logDEBUG( aData );
             break;
         }
         case LOG_FAIL:
         {
             logFAIL( aData );
             break;
         }
         case LOG_SYSTEM:
         {
             logSYSTEM( aData );
             break;
         }
         case LOG_LSTOUT:
         {
             logLSTOUT( aData );
             break;
         }
         case LOG_CRASH:
         {
             logCRASH( aData );
             break;
         }
         default:
         {
             break;
         }
    }

    return IDE_SUCCESS;
}

IDE_RC 
Logger::logERROR( SChar *aData )
{
    fprintf( mERROR, 
                    aData );
    
    //fflush( mERROR );

    return IDE_SUCCESS;
}

IDE_RC 
Logger::logEXCEPTION( SChar *aData )
{
    fprintf( mEXCEPTION, 
                    aData );
    
    //fflush( mEXCEPTION );

    return IDE_SUCCESS;
}

IDE_RC 
Logger::logREPORT( SChar *aData )
{
    logTimestamp( mREPORT );

    fprintf( mREPORT, 
                    aData );
    
    //fflush( mREPORT );

    return IDE_SUCCESS;
}

IDE_RC
Logger::logDEBUG( SChar *aData )
{
    logTimestamp( mDEBUG );

    fprintf( mDEBUG, 
                    aData );
    
    fprintf( mDEBUG, 
                    "\n" );

    //fflush( mDEBUG );

    return IDE_SUCCESS;
}

IDE_RC
Logger::logFAIL( SChar *aData )
{
    fprintf( mFAIL, 
                    aData );
    
    fprintf( mFAIL, 
                    "\n" );

    //fflush( mFAIL );

    return IDE_SUCCESS;
}

IDE_RC
Logger::logCRASH( SChar *aData )
{
    fprintf( mCRASH, 
                    aData );
    
    fprintf( mCRASH, 
                    "\n" );

    return IDE_SUCCESS;
}

IDE_RC 
Logger::logTimestamp( FILE *aTarget )
{
    time_t timet;
    struct tm  now;

    time(&timet);
    localtime_r(&timet, &now);

    return fprintf( aTarget,
                           "[%4"ID_UINT32_FMT
                           "/%02"ID_UINT32_FMT
                           "/%02"ID_UINT32_FMT
                           " %02"ID_UINT32_FMT
                           ":%02"ID_UINT32_FMT
                           ":%02"ID_UINT32_FMT"] ",
                           now.tm_year + 1900,
                           now.tm_mon + 1,
                           now.tm_mday,
                           now.tm_hour,
                           now.tm_min,
                           now.tm_sec) >= 0 ? IDE_SUCCESS : IDE_FAILURE;
}

IDE_RC
Logger::logSYSTEM( SChar *aData )
{
    SChar      sData1[BUFFER_SIZE];
    STAFString sData2;
    FILE      *sSystem ;

    sData2 = mEnvRESULT + FILE_SEPARATORS + "work" + FILE_SEPARATORS + "log" + FILE_SEPARATORS + SYSTEM_LOG;
    copyData( sData1,
              sData2.buffer(),
              sData2.length() );
    IDE_TEST( (sSystem = fopen( sData1, "a" )) == NULL );

    logTimestamp( sSystem );

    fprintf( sSystem, 
                    aData );

    fprintf( sSystem, 
                    "\n" );

    //fflush( sSystem );

    fclose( sSystem );

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC
Logger::logLSTOUT( SChar *aData )
{
    fprintf( mLSTOUT,
                    aData );

    fprintf( mLSTOUT,
                    "\n" );

    //fflush( mFAIL );

    return IDE_SUCCESS;
}

IDE_RC
Logger::logValgrind( SChar *aData, 
                     SChar *aIn )
{
    SChar  sIn[BUFFER_SIZE];
    FILE  *sValgrind;

    sprintf( sIn,
                    "%s%s%s%s%s",
                    aIn,
                    FILE_SEPARATORS,
                    "trc",
                    FILE_SEPARATORS,
                    VALGRIND_LOG ); 

    IDE_TEST( (sValgrind = fopen( sIn, "a" )) == NULL );

    logTimestamp( sValgrind );

    fprintf( sValgrind, 
                    aData );

    fprintf( sValgrind, 
                    "\n" );

    fflush( sValgrind );

    fclose( sValgrind );

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}
