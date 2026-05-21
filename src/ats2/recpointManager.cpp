/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id$
 **********************************************************************/

#include "recpointManager.h"

IDE_RC 
RecPointer::initialize( STAFString aEnvHOME )
{
    STAFString sData1;
    SChar      sData[BUFFER_SIZE];
    
    mEnvHOME = aEnvHOME;

    mBOOTLOG   = NULL;
    memset( mLastLine, 0x00, 1024);
    memset( mBOOTLOG_PATH, 0x00, 1024);

    sData1 = aEnvHOME + FILE_SEPARATORS + "trc" + FILE_SEPARATORS + BOOT_LOG;
    
    copyData( mBOOTLOG_PATH,
              sData1.buffer(),
              sData1.length() );

    memset( &mCheckMutex, 0, ID_SIZEOF(mCheckMutex) );
    IDE_TEST( pthread_mutex_init( &mCheckMutex, 
                                        NULL ) != 0 );

    
    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}


IDE_RC 
RecPointer::destroy()
{
    IDE_TEST( pthread_mutex_destroy( &mCheckMutex ) != 0 );

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;
 
    return IDE_FAILURE;
}

IDE_RC
RecPointer::lock()
{
    IDE_TEST( pthread_mutex_lock( &mCheckMutex ) != 0 );

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;
 
    return IDE_FAILURE;
}

IDE_RC
RecPointer::unlock()
{
    IDE_TEST( pthread_mutex_unlock( &mCheckMutex ) != 0 );

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;
 
    return IDE_FAILURE;
}

IDE_RC 
RecPointer::load( SChar        * aFileName ) 
{
    recPointData   sData;
    idBool         sExist;
    FILE        *  sRECPOINT;
    SChar          sBuffer[1024];
    SChar          sRecPointID[512];
    SChar          sFileName[512];
    SChar          sTestType[16];
    UInt           sLineNumber;
    UInt           sApplyValue;
    UInt           sSkipFlagAtStartup;
        
    sRECPOINT  = NULL;

    IDE_TEST( access( aFileName, F_OK ) != 0 );

    IDE_TEST( (sRECPOINT = fopen( aFileName, "r" )) == NULL );

    while ( feof(sRECPOINT) == 0 )
    {
        if ( fgets(sBuffer, 1024, sRECPOINT) != NULL )
        {
            sLineNumber        = 0;
            sApplyValue        = 0;
            sSkipFlagAtStartup = 0;

            sscanf( sBuffer, "%s %d %s",
                    sFileName,
                    &sLineNumber,
                    sRecPointID );

            sData.filename   = STAFString( sFileName ).strip();
            
            sData.lineNumber = sLineNumber;
            
            sData.testType  = "KILL"; // default test type

            sData.applyValue = sApplyValue;
            
            sData.skipFlagAtStartup = sSkipFlagAtStartup;
            
            sData.recPointID = STAFString( sRecPointID ).strip();

            // FULL TEST시 수행할 query string 생성
            sData.queryString  = "execute enable_recptr( ";

            // recpoint id
            sData.queryString += "'" + sData.recPointID.strip() + "', ";

            // test type 
            sData.queryString += "'" + sData.testType.strip()   + "', ";

            // apply value 
            sprintf(sBuffer, "%d", sApplyValue); 
            sData.queryString += STAFString( sBuffer ).strip()  + ", ";

            // sleep second
            sData.queryString += "0, "; 

            // skip flag at startup
            sprintf(sBuffer, "%d", sSkipFlagAtStartup); 
            sData.queryString += STAFString( sBuffer ).strip()  + ", ";

            // filename 
            sData.queryString += "'" + sData.filename           + "', ";

            // line number
            sprintf(sBuffer, "%d", sLineNumber); 
            sData.queryString += STAFString( sBuffer ).strip()  + ")";

            if ( mRecPointMap.find( sData.recPointID ) == mRecPointMap.end() )
            {
                mRecPointMap[ sData.recPointID ] = sData;
            }
			/*  
            else
            {
                cout << "[recpointerMgr] Not Unique recovery ID";
                cout << " [ " << sData.recPointID << " ] " << endl;
            }
			*/
        }
    }

    fclose( sRECPOINT );

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

STAFString
RecPointer::getLastLineFromBootLog()
{
    UInt sState = 0;

    lock();
    sState = 1;

    mBOOTLOG = NULL;

    IDE_TEST( (mBOOTLOG = fopen( mBOOTLOG_PATH, "r" )) == NULL );

    while ( 1 )
    {
        if ( fgets(mLastLine, 1024, mBOOTLOG) == NULL )
        {
            break;
        }
    }

    if ( mBOOTLOG != NULL )
    {
        fclose( mBOOTLOG );
    }

    sState = 0;
    unlock();

    return STAFString( mLastLine );

    IDE_EXCEPTION_END;

    if ( sState == 1 )
    {
        unlock();
    }

    return STAFString::kNPos;
}
