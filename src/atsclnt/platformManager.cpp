/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: platformManager.cpp 1596 2008-03-21 06:15:59Z orc $
 **********************************************************************/

#include "common.h"
#include "platformManager.h"
#include <algorithm>

#define LINE_BUFFER 1024
#define ITEM_SIZE   1024

#if !defined(STAF_OS_NAME_HPUX)
using namespace std;
#endif

#if defined(STAF_OS_NAME_WIN32)

#define INET_ADDRSTRLEN 16
const char *inet_ntop (int family, const void *addrptr, char *strptr, size_t len)
{
  const u_char *p =
    reinterpret_cast<const u_char *> (addrptr);

    {
      char temp[INET_ADDRSTRLEN];

      // Stevens uses snprintf() in his implementation but snprintf()
      // doesn't appear to be very portable.  For now, hope that using
      // sprintf() will not cause any string/memory overrun problems.
      sprintf (temp,
                       "%d.%d.%d.%d",
                       p[0], p[1], p[2], p[3]);

      if (strlen (temp) >= len)
        {
          //errno = ENOSPC;
          return 0; // Failure
        }

      strcpy (strptr, temp);
      return strptr;
    }
}
#endif

IDE_RC 
PlatformManager::initialize()
{
    return IDE_SUCCESS;
}

IDE_RC 
PlatformManager::destroy()
{
    return IDE_SUCCESS;
}

IDE_RC 
PlatformManager::load( SChar *aFileName )
{
    FILE *sFp;
    //FILE *sEfp;
    SChar sBuffer[LINE_BUFFER];
    SChar sServer[ITEM_SIZE];
    SChar sIp[ITEM_SIZE];
    SChar sGroup[ITEM_SIZE];
    //SChar sGroupTmp[ITEM_SIZE];
    SChar sTmp[ITEM_SIZE];

    //struct hostent  sHost;
    struct hostent *sHostPtr = NULL;

    //char sTmpBuffer[1024*4];
    
    //SInt   sHostErrno;
    UInt   sBufIndex = 0;
    UInt   sBufIndex2 = 0;
    UInt   sLen = 0;
    UInt   sLine = 0;
    UInt   sValuePos = 0;
//do TASK-2193    
#if defined(STAF_OS_NAME_WIN32)
    WORD sVersion = MAKEWORD(1, 1);
    WSADATA sWsaData = { 0 };

    (void)WSAStartup(sVersion, &sWsaData);
#endif
    
    sLen = 0;
    sFp = fopen( aFileName, "r" );

    IDE_TEST( sFp == NULL );

    memset( sBuffer,
            0x00,
            sizeof(sBuffer) );

    while( !feof(sFp) )
    {
        memset( sBuffer,
                0x00,
                sizeof(sBuffer) );

       	if( fgets( sBuffer,
                   sizeof(sBuffer),
                   sFp ) == NULL ) break;

    	sLen = strlen(sBuffer);

    	if( sLen <= 0 )
        {
            return  IDE_SUCCESS;
        }

    	memset( sServer, 0x00, sizeof(sServer) );
    	memset( sGroup, 0x00, sizeof(sGroup) );
    	memset( sIp, 0x00, sizeof(sIp) );
    
    	sValuePos = 0;
    	sBufIndex2 = 0;

    	for( sBufIndex = 0; 
             sBufIndex < sLen && sBuffer[sBufIndex] != '\0';
             sBufIndex++ )
    	{
            if( sBuffer[sBufIndex] == ' ' )
            {
                continue;
            }

       	    if( sBuffer[sBufIndex] == '\n'||
                sBuffer[sBufIndex] == '#' )
            {
                break;
            }
  
       	    if( sBuffer[sBufIndex] == ':' )
            {
                sValuePos = 1;
                sBufIndex2 = 0;
                continue;
            }

       	    if( sValuePos == 0 )
            {
                sGroup[sBufIndex2++] = sBuffer[sBufIndex];
            } 
            else
            {
    	        memset( sServer, 0x00, sizeof(sServer) );

                sBufIndex2 = 0;
                //for( sBufIndex > 0; 
                for( ; 
                     sBufIndex < sLen && sBuffer[sBufIndex] != '\0';
                     sBufIndex++ )
                {
                    if ( sBuffer[sBufIndex] == '#' ) 
                    {
                        sBufIndex = sLen;
                        sServer[sBufIndex2++] = '\0';
                        break;
                    }
                    else
                    {
                        sServer[sBufIndex2++] = sBuffer[sBufIndex];
                    }
                }
                break;
            }

            if( sValuePos > 0 )
            {
                break;
            }
    	}

        sServer[sBufIndex2++] = '\0';

        mList.clear();
    	sLen = strlen(sServer);
       
    	if( sLen > 0 )
    	{
            sBufIndex = 0;
            sBufIndex2 = 0;
            sValuePos = sLen - 1;

            for ( sBufIndex = 0; sBufIndex < sLen && sServer[sBufIndex]; sBufIndex++ )
            {
                if ( ( sServer[sBufIndex] == ' ' ) || ( sBufIndex == sValuePos ) )
                {
                    if ( strstr(sTmp, ".") == NULL)
                    { 
                        sTmp[sBufIndex] = '\0';
			sHostPtr = gethostbyname( sTmp );
                                                    //       &sHost,
                                                    //       sTmpBuffer,
                                                    //       &sHostErrno );
            		if ( sHostPtr != NULL )
            		{
                	    if( inet_ntop( sHostPtr->h_addrtype,
                                                  *(sHostPtr->h_addr_list),
                                                  sIp,
                                                  50 ) == NULL )
                            {
                                memcpy( sIp, "127.0.0.1", 10 );
                            }
                        }
                        else
                        {
                            // BUGBUG
                        }
    		        mList.push_back(sIp);
                    }
                    else
                    {
                        mList.push_back(sTmp);
                    }

    		    mList.push_back(sIp);
    		    mPlatformList[sGroup]=mList;
                    sBufIndex2 = 0;

                    memset( sTmp, 0x00, sizeof(sTmp) );
                    memset( sIp, 0x00, sizeof(sIp) );
                }
                else
                {
                    sTmp[sBufIndex2++] = sServer[sBufIndex];
                }
            }
        }
    }

    fclose(sFp);

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;
    return IDE_FAILURE;
}

// 서버 그룹에 자신의 아이피가 존재하는지 체크
idBool 
PlatformManager::contains( STAFString aPlatGroup )
{
    SInt       sCnt = 0;
    //SChar      sIP[ITEM_SIZE];
    SChar      sName[ITEM_SIZE]; 
    STAFString sLocalIP;
    UInt       sIpIndex = 0;
    UInt       sBufIndex = 0;
    idBool     sIsValid;

    std::map< STAFString, std::list<STAFString> >::const_iterator sPlatformIterator;
    std::list< STAFString >::const_iterator sPlatformList;

    struct sockaddr_in addr; 
    struct hostent     *pHostInfo;

    if( gethostname (sName, sizeof(sName)) == 0) 
    { 
        if( ( pHostInfo = gethostbyname(sName)) != NULL )
        { 
            for( sIpIndex = 0; 
                 pHostInfo->h_addr_list[sIpIndex] != NULL; 
                 sIpIndex++ )
            {
                memcpy( &(addr.sin_addr),
                        pHostInfo->h_addr_list[sBufIndex],
                        pHostInfo->h_length );
                break;
            }
        } 
    }

    if( mPlatformList.find(aPlatGroup) != mPlatformList.end())
    {
        sPlatformIterator = mPlatformList.find( STAFString(aPlatGroup) );

        sPlatformList = find( (*sPlatformIterator).second.begin(),
                              (*sPlatformIterator).second.end(),
                              STAFString( inet_ntoa(addr.sin_addr) ) );

        if( sPlatformList != (*sPlatformIterator).second.end() )
        {
            sIsValid = ID_TRUE;
        }
        else
        {
            sIsValid = ID_FALSE;
        }
    }
    else
    {
        sIsValid = ID_FALSE;
    }

    return sIsValid;
}

//Printing Map for DEBUG
IDE_RC 
PlatformManager::status()
{
    std::map< STAFString, std::list<STAFString> >::const_iterator sPlatformIterator;
    std::list<STAFString>::const_iterator sPlatformList;

    for( sPlatformIterator = mPlatformList.begin(); 
         sPlatformIterator != mPlatformList.end(); 
         sPlatformIterator++ )
    {
    	cout<< "["<< (*sPlatformIterator).first << "]" << endl;

    	for( sPlatformList = (*sPlatformIterator).second.begin();
             sPlatformList != (*sPlatformIterator).second.end();
             sPlatformList++ )
        {
    	    cout<<" IP: "<<(*sPlatformList)<<endl;
        }
    }
    return IDE_SUCCESS;
}
