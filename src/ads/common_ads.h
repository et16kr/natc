/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: common.h 725 2006-06-29 08:34:05Z copyrei $
 **********************************************************************/

#ifndef _O_COMMON_H_
#define _O_COMMON_H_ 1

#include "STAF.h"
#include <deque>
#include <map>
#include <list>
#include "STAFMutexSem.h"
#include "STAFCommandParser.h"
#include "STAFServiceInterface.h"
#include "STAFUtil.h"

#if !defined(STAF_OS_NAME_WIN32)
#include <sys/wait.h>
#else
#include "win32.h" 
#endif

#include <sys/types.h>
#include <signal.h>
#include <assert.h>

#include "idFake.h"
#include "atsBaseThread.h"

struct ServiceDataADS
{
    UInt                 debugMode;
    STAFString           shortName;
    STAFString           name;
    STAFHandlePtr        handlePtr;
    STAFString           localMachineName;
    STAFCommandParserPtr helpParser;
    STAFCommandParserPtr versionParser;
    STAFCommandParserPtr runParser;
    STAFCommandParserPtr statusParser;
};

#ifdef __cplusplus
extern "C"
{
#endif

typedef enum STAFServiceError_e
{
    // add service-specific return codes here
    kServiceInvalidOption = 4002
} STAFServiceError_t;

#ifdef __cplusplus
}
#endif

enum CommandKind
{
    QUERY_INSERT,
    QUERY_UPDATE,
    QUERY_SELECT,
    QUERY_DELETE,
    QUERY_EXECUTE
};

#define BUFFER_SIZE   (65536)
#define SMALL_BUFFER  (1024)

#define copyData( a, b, c ) { memcpy( a, b, c ); a[c] = '\0'; }


#endif
