/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: ilo.h 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/
 
#ifndef _O_ILO__H
#define _O_ILO__H

#include <idl.h>
#include <idp.h>
#include <iduVersion.h>
#include <ideErrorMgr.h>
//#include <smDef.h>
//#include <smcDef.h>
#include <sqlcli.h>
#include <iloDef.h>
#include <iloTableInfo.h>
#include <iloSQLApi.h>
#include <iloProgOption.h>
#include <iloCommandCompiler.h>
#include <iloFormCompiler.h>
#include <iloBadFile.h>
#include <iloDataFile.h>
#include <iloLogFile.h>
#include <iloFormDown.h>
#include <iloLoad.h>
#include <iloDownLoad.h>
#include <uttMemory.h>
#include <uttTime.h>

#ifdef VC_WIN32 
inline void changeSeparator(const char *aFileName, char *aNewFileName)
{
    SInt i = 0;

    for (i=0; aFileName[i]; i++)
    {
        if ( aFileName[i] == '/' )
        {
            aNewFileName[i] = IDL_FILE_SEPARATOR;
        }
        else
        {
            aNewFileName[i] = aFileName[i];
        }
    }
    aNewFileName[i] = 0;
}
#endif

inline FILE *ilo_fopen(const char *aFileName, const char *aMode)
{
#ifdef VC_WIN32
    SChar aNewFileName[256];
    
    changeSeparator(aFileName, aNewFileName);

    return idlOS::fopen(aNewFileName, aMode);
#else
    return idlOS::fopen(aFileName, aMode);
#endif
}

#endif /* _O_ILO__H */
