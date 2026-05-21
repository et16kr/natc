/*********************************************************************** 
* Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: caseManager.cpp 1596 2008-03-21 06:15:59Z orc $
 **********************************************************************/

#include "common.h"
#include "caseManager.h"
#include <algorithm>

#if !defined(STAF_OS_NAME_HPUX)
using namespace std;
#endif

IDE_RC
CaseManager::initialize()
{
    // 자료구조를 초기화 한다.
    return IDE_SUCCESS;
}

IDE_RC
CaseManager::destroy()
{
    // 객체 자신을 해제한다.
    return IDE_SUCCESS;
}

IDE_RC
CaseManager::loadcase( SChar                            *aSharedCase, 
                       SChar                            *aMyCase, 
                       SInt                              aFlag, 
                       std::map<STAFString, STAFString> *aSkipMap )
{

    mIsNeedMerge = ID_FALSE;
    mIsSetPlatformInfo = 0;
    mFindLevel = 0;

    IDE_TEST( load( aSharedCase, 0, 0, aSkipMap ) != IDE_SUCCESS );

    if( aFlag == 2 )
    {
	mIsNeedMerge = ID_TRUE;

	if( load( aMyCase, 0, RUNABLE, aSkipMap ) != IDE_SUCCESS )
        {
            IDE_RAISE(err_pass);
        }
        else if( mergeCase() != IDE_SUCCESS )
        {
            IDE_RAISE(err_pass);
        }
    }

    return IDE_SUCCESS;

    IDE_EXCEPTION( err_pass );

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC
CaseManager::load( SChar *aFileName, SInt aCurDepth, SInt aMark, std::map<STAFString, STAFString> *aSkipMap )
{
    FILE* sFp;
    SChar sBuffer[LINE_BUFFER];
    SChar sLine[LINE_BUFFER];
    SChar sTmp[LINE_BUFFER];
    SChar sPath[LINE_BUFFER];
    SChar sPlatformName[ITEM_SIZE];
    SChar sCaseComment[ITEM_SIZE];
    UInt   sCaseType=0;
    UInt   sFlag = 0;
    UInt   sFlagDepth=0;
    UInt   sBufIndex1;
    UInt   sBufIndex2;
    //UInt   sBufIndex3;
    UInt   sLen;

    struct caseInfo mCaseInfo;

    STAFString sEnvCASE      = getenv( "ATAF_TEST_CASE" );
    STAFString sEnvCASE_USER = getenv( "ATAF_USER_TEST_CASE" );
    idBool     sSkip         = ID_FALSE;
    STAFString sSkipData;

    memset( sPath,
                   0x00,
                   sizeof(sPath));

    memset( sTmp,
                   0x00,
                   sizeof(sTmp));

    strncpy( sTmp,
                    aFileName,
                    strlen(aFileName)); 

    sBufIndex1 = 0;
    sLen = strlen(sTmp);

    // sPath은 파일 이름을 제외하고 path만 갖고 있다파일 이름만 갖고 있음.
    for( sBufIndex1 = sLen; sBufIndex1 > 0 ; sBufIndex1-- )
    {
        if( sTmp[sBufIndex1] == FILE_SEPARATOR )
        {
            strncpy( sPath, sTmp, ++sBufIndex1 );
            break;
        }
    }

    memset( sPlatformName,
                   0x00,
                   sizeof(sPlatformName));

    memset( sCaseComment,
                   0x00,
                   sizeof(sCaseComment));
   
    mCaseInfo.caseMark = aMark;

    if( aCurDepth == 0 )
    {
        memset( mPlatformName,
                       0x00,
                       sizeof(mPlatformName));

        memset( sPlatformName, 
                       0x00,
                       sizeof(sPlatformName));

        memset( sCaseComment,
                       0x00,
                       sizeof(sCaseComment));

        sCaseType = getcasetype(aFileName);
        mIsSetPlatformInfo = 0;

        if( sCaseType == 0 )   
        {
            return IDE_SUCCESS;
        }

        //mCaseInfo.caseMark = RUNABLE;
        mCaseInfo.caseFlag = 1;
        mCaseInfo.casePlatformName = sPlatformName;
        mCaseInfo.caseName = aFileName;
        mCaseInfo.caseComment = sCaseComment;
        mCaseInfo.tsName = aFileName;
        mCaseInfo.caseType = sCaseType;

        sSkipData = mCaseInfo.caseName;
        sSkipData = sSkipData.replace(sEnvCASE, "").replace( sEnvCASE_USER, "");

        if( sSkipData.subString( 0, 1 ) == FILE_SEPARATOR2 )
        {
            sSkipData = sSkipData.subString( 1 );
        }
        //cout << "[a] [" << sSkipData << "]" << endl;
        if( aSkipMap->find( sSkipData ) == aSkipMap->end() )
        {
            sSkip = ID_FALSE;
        }
        else
        {
            //cout << "[s] [" << sSkipData << "]" << endl;
            sSkip = ID_TRUE;
            mCaseInfo.caseMark = RUNSKIP;
        }

        if( mIsNeedMerge == ID_FALSE ) 
        {
            mCaseList.push_back(mCaseInfo);
        }
        else
        {
            mLocalCaseList.push_back(mCaseInfo);
        }
    }

    if(( sCaseType == SQL )||( sCaseType == XML ))   
    {
        return IDE_SUCCESS;
    }

    sFp = NULL;
    sFp = fopen( aFileName, "r" );

    if(sFp == NULL)
    {
        // 파일이 없는 경우, 
        // 여기서는 계속 진행하고, ats 서버에서 에러체크를 한다.
        return IDE_SUCCESS; 
    }

    sFlag = PLAT_OFF;
    while(!feof(sFp))
    {
        memset( sCaseComment,
                       0x00,
                       sizeof(sCaseComment));

        memset( sBuffer,
                       0x00,
                       sizeof(sBuffer));

        mCaseInfo.caseMark = aMark;

       	if(fgets( sBuffer,
                  sizeof(sBuffer),
                  sFp ) == NULL )
       	{
            break;
       	}

    	sLen = strlen(sBuffer);
    	if( sLen <= 0 )
    	{
            return  IDE_SUCCESS;
    	}

        memset( sLine,
                0x00,
                sizeof(sLine));

    	sBufIndex2 = 0;
        sBufIndex1 = 0;

    	for ( sBufIndex1 = 0; 
              sBufIndex1 < sLen && sBuffer[sBufIndex1] != '\0'; 
              sBufIndex1++ )
    	{
            if(( sBuffer[sBufIndex1] == '#' ) && ( sBufIndex1 == 0 ))
	    { 
                mCaseInfo.caseMark = NOTRUNABLE;
		sBufIndex1++;
            }

            if( sBuffer[sBufIndex1] == ' ' ||
                sBuffer[sBufIndex1] == '!' ||
                sBuffer[sBufIndex1] == '\t' )
            {
                continue;
            }

            if( ( sBuffer[sBufIndex1]=='[' ) )
            { 
                memset( sPlatformName,
                               0x00,
                               sizeof(sPlatformName) );
                sBufIndex2 = 0;

                if( sBuffer[++sBufIndex1] == '^' )
                {
                    sFlag = PLAT_ON;
                }
                else
                {
                    sFlag = PLAT_OFF;
                    sPlatformName[sBufIndex2++] = sBuffer[sBufIndex1];
                }

                sBufIndex1++;
                //for( sBufIndex1 > 0; 
                for( ; 
                     sBufIndex1 < sLen && sBuffer[sBufIndex1] != '\0'; 
                     sBufIndex1++ )
                {
                    if( sBuffer[sBufIndex1] == ']' )
                    {
                        break;
                    }

                    sPlatformName[sBufIndex2++] = sBuffer[sBufIndex1];
                }
                sBufIndex2 = 0;
                sBufIndex1++;
            }

            if( ( sBuffer[sBufIndex1] == '#' ) )
            { 
                memset( sCaseComment,
                               0x00,
                               sizeof(sCaseComment) );

                sBufIndex2 = 0;
                //for( sBufIndex1 > 0; 
                for( ; 
                     sBufIndex1 < sLen && sBuffer[sBufIndex1] != '\0'; 
                     sBufIndex1++ )
                {
                    if( sBuffer[sBufIndex1] == '\n' )
                    {
                        break;
                    }

                    sCaseComment[sBufIndex2++] = sBuffer[sBufIndex1];
                    
                }
                sBufIndex2 = sBufIndex1;
                break;
            }

            if( ( sBuffer[sBufIndex1] == '-' && sBufIndex1 == 0 ) || 
                ( sBuffer[sBufIndex1] == '\n') )
            {
                break;
            }

            if ( sBuffer[sBufIndex1] == '\n' )
            {
                break;
            }

            if ( sBuffer[sBufIndex1] == '/')
            {
                #if defined(STAF_OS_NAME_WIN32)
                    sBuffer[sBufIndex1] = FILE_SEPARATOR;
                #endif
            }

            sLine[sBufIndex2++] = sBuffer[sBufIndex1];
        }

        sLen = 0;
        sLen = strlen( sLine );

        if( sLen > 0 )
        {
            memset( sTmp,
                           0x00,
                           sizeof(sTmp) );

            sprintf( sTmp, "%s", sPath );

            if( strlen(sTmp) < LINE_BUFFER - 1 )
            {
                sTmp[strlen(sTmp)+1] = '\0';
            } 

            strcat( sTmp, sLine ); 

            if( strlen(sTmp) < LINE_BUFFER - 1 )
            {
                sTmp[strlen(sTmp)+1]='\0';
            }
        }
        else
        {
            continue;
        }

        if( strstr( sLine,"TestSuiteDescription" ) != NULL )
        {
             // nothing to do
        }
        else
        {
            if( strstr(sLine, ".") != NULL )
            {
                sLen=0;
                sLen = strlen( sPlatformName );

                if( (sLen > 0) && (mPlatformName[0] == '\0'))
                {
                    mCaseInfo.casePlatformName = sPlatformName;
                    mCaseInfo.caseFlag = sFlag;
                    sprintf( mPlatformName ,"%s", sPlatformName );

                    if( strlen(mPlatformName) < ITEM_SIZE - 1 )
                    {
                        mPlatformName[strlen(mPlatformName)+1] = '\0';
                    }

                    mIsSetPlatformInfo = sFlag;
		    mFindLevel = aCurDepth;
                }

                if( (aCurDepth > mFindLevel) && (mPlatformName[0] != '\0'))
                {
                    mCaseInfo.casePlatformName = mPlatformName;
                    mCaseInfo.caseFlag = mIsSetPlatformInfo;
                 }

                if( (aCurDepth <= mFindLevel) && (sLen == 0) )
                {
        	    memset( mPlatformName, 0x00, sizeof(mPlatformName) );
                    mIsSetPlatformInfo = PLAT_OFF;
                    mCaseInfo.casePlatformName = mPlatformName;
                    mCaseInfo.caseFlag = mIsSetPlatformInfo;
                }

                if( (aCurDepth <= mFindLevel) && (sLen > 0) )
                {
                    mCaseInfo.casePlatformName = sPlatformName;
                    mCaseInfo.caseFlag = sFlag;
                    sprintf( mPlatformName , "%s", sPlatformName);

                    if( strlen(mPlatformName) < ITEM_SIZE - 1 )
                    {
                        mPlatformName[strlen(mPlatformName)+1] = '\0';
                    }

                    mIsSetPlatformInfo = sFlag;
		    mFindLevel = aCurDepth;
                }

                sCaseType = getcasetype( sTmp );

                // Unknown File Type
                if ( sCaseType == 0 )   
                {
		    continue;
                }

                memset( sPlatformName,
                               0x00,
                               sizeof(sPlatformName) );

                mCaseInfo.caseName = sTmp;
                mCaseInfo.caseComment = sCaseComment;
                mCaseInfo.tsName = aFileName;
                mCaseInfo.caseType = sCaseType;

                sSkipData = mCaseInfo.caseName;
                sSkipData = sSkipData.replace(sEnvCASE, "").replace( sEnvCASE_USER, "");
                if( sSkipData.subString( 0, 1 ) == FILE_SEPARATOR2 )
                {
                    sSkipData = sSkipData.subString( 1 );
                }

                //cout << "[b] [" << sSkipData << "]" << endl;
                if( aSkipMap->find( sSkipData ) == aSkipMap->end() )
                {
                    sSkip = ID_FALSE;
                }
                else
                {
                    //cout << "[s] [" << sSkipData << "]" << endl;
                    sSkip = ID_TRUE;
                    mCaseInfo.caseMark = RUNSKIP;
                }
		if( mIsNeedMerge == ID_FALSE )
                {
                    mCaseList.push_back(mCaseInfo);
                }
		else
                {
                    mLocalCaseList.push_back(mCaseInfo);
                }
            } 
            sBufIndex1 = aCurDepth + 1;

            if( ( strstr(sLine, ".ts") != NULL ) ||
                ( strstr(sLine, ".tl") != NULL ) )
            {
                CaseManager::load( sTmp,
                                   sBufIndex1,
                                   mCaseInfo.caseMark,
                                   aSkipMap );
            } 
            memset( sPlatformName,
                           0x00,
                           sizeof(sPlatformName) );
        } 
    }//end of while	
    
    fclose( sFp );

    return IDE_SUCCESS;
}

IDE_RC 
CaseManager::status()
{
    CaseIterator sIterator;
    SChar sCName[LINE_BUFFER];
    SChar sPName[LINE_BUFFER];
	
    FILE* sFp;
    sFp  = fopen( "caselist.out", "w" );

    for( sIterator = mCaseList.begin();
         sIterator!= mCaseList.end(); 
         sIterator++) 
    {
        memset( sCName,
                0x00,
                sizeof(sCName) );

        copyData( sCName,
                  (*sIterator).caseName.buffer(),
                  (*sIterator).caseName.length() );

        memset( sPName,
                0x00,
                sizeof(sPName));

        copyData( sPName,
                  (*sIterator).casePlatformName.buffer(), 
                  (*sIterator).casePlatformName.length());

        fprintf( sFp, 
                 " %s %s %d \n",
                 sCName,
                 sPName,
                 (*sIterator).caseFlag );
    }

    for( sIterator = mLocalCaseList.begin();
         sIterator!= mLocalCaseList.end();
         sIterator++) 
    {
       memset(sCName, 0x00, sizeof(sCName));
       copyData( sCName,
                 (*sIterator).caseName.buffer(),
                 (*sIterator).caseName.length() );
       fprintf(sFp, "local: %s \n", sCName);
    }

    fclose( sFp );

    return IDE_SUCCESS;
}

SInt
CaseManager::getcasetype( SChar *aCaseName )
{
    SChar *sPos = NULL;
    UInt  sCaseType;

    sCaseType = 0;

    if ( ( (sPos = strstr( aCaseName, ".ts" )) != NULL ) &&
         ( strlen(aCaseName) - ( sPos - aCaseName ) == 3 ) )
    {
        sCaseType = TS; 
    }
    else if ( ( (sPos = strstr( aCaseName, ".tl" ) ) != NULL ) &&
         ( strlen(aCaseName) - ( sPos - aCaseName ) == 3 ) )
    {
        sCaseType = TL; 
    }
    else if ( ( (sPos = strstr( aCaseName, ".sql" ) ) != NULL ) &&
         ( strlen(aCaseName) - ( sPos - aCaseName ) == 4 ) )
    {
        sCaseType = SQL; 
    }
    else if ( ( (sPos = strstr( aCaseName, ".xml" ) ) != NULL ) &&
         ( strlen(aCaseName) - ( sPos - aCaseName ) == 4 ) )
    {
        sCaseType = XML; 
    }
    else
    {
        // nothing to do
    }

    return sCaseType;
}
    
IDE_RC
CaseManager::mergeCase()
{
    CaseIterator sIterator;
    CaseIterator sIteratorTmp;
    CaseIterator sIteratorKeep;

    STAFString sUserCasePath;
    STAFString sSharedCasePath;
    STAFString sUserCaseName;
    STAFString sCompareName;

    SInt sFullLen;
    SInt sCaseLen;

    sUserCasePath = getenv( "ATAF_USER_TEST_CASE" );
    sSharedCasePath = getenv( "ATAF_TEST_CASE" );

    for( sIterator = mLocalCaseList.begin(); 
         sIterator!= mLocalCaseList.end(); 
         sIterator++ ) 
    {
	sFullLen = (*sIterator).caseName.length();
	sCaseLen = sUserCasePath.length();
	sUserCaseName = (*sIterator).caseName.subString( sCaseLen,
                                                         sFullLen - sCaseLen);
        sCompareName = sSharedCasePath + sUserCaseName;

	sIteratorTmp = find_if( mCaseList.begin(),
			        mCaseList.end(), 
                                CaseCompare(sCompareName));
	
        // 사용자 케이스가 공유 케이스에도 존재할 경우,
        // 사용자 케이스로 공유 케이스를 update
	if( sIteratorTmp != mCaseList.end() )
	{
	    (*sIteratorTmp).caseName = (*sIterator).caseName;
	    (*sIteratorTmp).caseType = (*sIterator).caseType;
	    (*sIteratorTmp).caseComment = (*sIterator).caseComment;
	    (*sIteratorTmp).caseFlag = (*sIterator).caseFlag;
	    (*sIteratorTmp).caseMark = (*sIterator).caseMark;
	    
	    sIteratorKeep = ++sIteratorTmp; 
		
	}
        // 공유 케이스에 없고, 최초의 사용자 케이스 일 경우,
        // 맨 앞에 insert
        else if( sIterator == mLocalCaseList.begin())
	{
	    mCaseList.insert(sIteratorTmp, (*sIterator));
	    sIteratorKeep = sIteratorTmp; 
	}
        // 사용자 케이스가 공유 케이스에 없을 경우, insert. 
        // insert 하는 위치는 이전에 업데이트한 케이스가 있을 경우에는
        // 그 케이스 바로 뒤(sIteratorKeep)에 insert하고,
        // 업데이트한 케이스가 없을 경우에는, 공유 케이스 리스트의 맨 뒤에
        // insert 된다.
        // sIteratorKeep에 ++가 없는 이유는 insert 메소드가 sIteratorKeep이
        // 가르키고 있는 위치의 바로 뒤에 insert 하기 때문임.
        else
	{
	    mCaseList.insert(sIteratorKeep, (*sIterator));
        }
    }
    return IDE_SUCCESS;
}
