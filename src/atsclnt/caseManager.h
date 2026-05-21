/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: caseManager.h 1020 2006-12-11 00:59:54Z ataf $
 **********************************************************************/
#ifndef _O_CASE_MANAGER
#define _O_CASE_MANAGER 1

#include "common.h"

#define LINE_BUFFER 1024
#define ITEM_SIZE   1024

class CaseManager
{
public:
    IDE_RC    initialize();
    IDE_RC    destroy();

    IDE_RC    load(SChar *aStr, SInt aFlag, SInt aMark, std::map<STAFString, STAFString> *aMap ); //aFlag, aMark should be always 0 
    IDE_RC    loadcase(SChar *aSharedCase, SChar *aMyCase, SInt aCurDepth, std::map<STAFString, STAFString> *aMap );
    SInt      getcasetype(SChar *aFileName); 
    IDE_RC    status();
    IDE_RC    mergeCase();

    CaseList* getList() { return &mCaseList; };
    
private:
    CaseList    mCaseList;
    CaseList    mLocalCaseList;
    SChar       mPlatformName[ITEM_SIZE];
    UInt        mIsSetPlatformInfo;
    SInt        mFindLevel;
    idBool      mIsNeedMerge;
};

class CaseCompare
{
public:
    CaseCompare(STAFString aCaseName){ mCaseName = aCaseName; }

    bool operator()(const caseInfo&caseinfo)
    {
         return caseinfo.caseName == mCaseName;
    }

private:
    STAFString   mCaseName;
};

#endif
