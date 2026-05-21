/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: serverManager.cpp 725 2006-06-29 08:34:05Z copyrei $
 **********************************************************************/

#include "common.h"
#include "serverManager.h"
#include <algorithm>

#define LINE_BUFFER 1024
#define ITEM_SIZE   1024

#if !defined(STAF_OS_NAME_HPUX)
using namespace std;
#endif

IDE_RC 
ServerManager::initialize()
{
    return IDE_SUCCESS;
}

IDE_RC 
ServerManager::destroy()
{
    return IDE_SUCCESS;
}

IDE_RC
ServerManager::load( SChar *aFileName)
{
    STAFString sError;
    FILE       *sFp;
    SChar      sBuffer[LINE_BUFFER];
    SChar      sServer[ITEM_SIZE];
    SChar      sName[ITEM_SIZE];
    SChar      sValue[ITEM_SIZE];
    UInt       sBufIndex = 0;
    UInt       sBufIndex2 = 0;
    UInt       sNameLen = 0;
    UInt       sServerLen = 0;
    idBool     sIsValue = ID_FALSE;

    sFp = fopen( aFileName, "r" );

    // 파일이 없으면 바로 종료
    IDE_TEST( sFp == NULL );

    memset( sServer,
                   0x00,
                   ID_SIZEOF( sServer ) );

    while( !feof(sFp) )
    {
        memset( sBuffer,
                       0x00,
                       ID_SIZEOF(sBuffer) );
        memset( sName,
                       0x00,
                       ID_SIZEOF(sName) );
        memset( sValue,
                       0x00,
                       ID_SIZEOF(sValue) );

        if( fgets( sBuffer,
                          ID_SIZEOF(sBuffer),
                          sFp ) == NULL ) break;

        sNameLen = strlen(sBuffer);

        if( sNameLen <= 0 )
        {
             return IDE_SUCCESS;
        }

        sBufIndex2 = 0;
        sIsValue = ID_FALSE;

        for( sBufIndex = 0; 
             sBufIndex < sNameLen && sBuffer[sBufIndex] != '\0';
             sBufIndex++ )
        {
            if( ( sBuffer[sBufIndex] == ' '  ) ||
                ( sBuffer[sBufIndex] == '\n' ) ||
                ( sBuffer[sBufIndex] == '\t' ) )
            {
                continue;
            }

            if( sBuffer[sBufIndex] == '#'  )
            {
                break;
            } 
    
            if( sBuffer[sBufIndex]=='[' )
            {
                memset( sServer,
                               0x00,
                               ID_SIZEOF(sServer) );

                for( sBufIndex2 = 1; sBufIndex2 < sNameLen; sBufIndex2++  )
                {
                    if( sBuffer[sBufIndex2] == ']' )
                    {
                        // 서버 이름이 끝나면 map에 넣고, clear 해준다.
			mSrvParam.clear();
                        break;
                    }
                    else
                    {
                        sServer[sBufIndex2 - 1] = sBuffer[sBufIndex2];
                    }
                }
                break;
            }
            
            if( ( sBuffer[sBufIndex] == '=' ) && ( sValue[0] == '\0' ) )
            {
                sIsValue = ID_TRUE;
                sBufIndex2 = 0;
                continue;
            }

            if( sIsValue == ID_FALSE )
            {
                sName[sBufIndex2++] = sBuffer[sBufIndex];
            }
            else
            {
                sValue[sBufIndex2++] = sBuffer[sBufIndex];
            }
        } // end of for loop

        sNameLen = strlen(sName);
        sServerLen = strlen(sServer);

        if ( sNameLen > 0 && sServerLen > 0 )
        {
            mSrvParam[sName] = sValue;
            mSrvMap[sServer] = mSrvParam;
        }
    } // end of while loop

    fclose(sFp);
    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}
