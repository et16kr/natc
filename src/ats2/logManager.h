/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: logManager.h 853 2006-08-31 01:24:14Z orc $
 **********************************************************************/

#ifndef _O_LOG_MANAGER_H_ 
#define _O_LOG_MANAGER_H_ 1

#include "common.h"

class Logger
{
public:
    IDE_RC     initialize( STAFString aEnvRESULT );
    IDE_RC     destroy();

    IDE_RC     log( LogType aType, SChar *aData );

    IDE_RC     logERROR( SChar *aData );
    IDE_RC     logEXCEPTION( SChar *aData );
    IDE_RC     logREPORT( SChar *aData );
    IDE_RC     logDEBUG( SChar *aData );
    IDE_RC     logFAIL( SChar *aData );
    IDE_RC     logSYSTEM( SChar *aData );
    IDE_RC     logLSTOUT( SChar *aData );
    IDE_RC     logCRASH( SChar *aData );
    IDE_RC     logValgrind( SChar *aData, SChar *aIn );
    IDE_RC     logTimestamp( FILE *aTarget );

private:
    FILE      *mERROR;
    FILE      *mEXCEPTION;
    FILE      *mREPORT;
    FILE      *mDEBUG;
    FILE      *mFAIL;
    FILE      *mLSTOUT;
    FILE      *mCRASH;

    STAFString mEnvRESULT;
};

#endif
