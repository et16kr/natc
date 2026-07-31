/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: idFake.h 2570 2006-12-04 07:10:09Z  $
 **********************************************************************/

#ifndef _O_IDFAKE_H_ 
#define  _O_IDFAKE_H_  1

#include <errno.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <ctype.h>
#include <unistd.h>
#include <stdarg.h>
#include <sys/time.h>
#include <stdio.h>
#include <time.h>
#include <signal.h>
#include <errno.h>
#include <pthread.h>
#include <fcntl.h>
#include <sys/sem.h>
#include <sys/msg.h>
#include <sys/shm.h>
#include <sys/ipc.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <ctype.h>
#include <sys/wait.h>
#include <sys/utsname.h>
#include <idTypes.h>

#define IDE_CLEAR() 
#define IDE_RAISE( b ) goto b;
#define IDE_TEST_RAISE( a, b )   \
    if( a )                      \
    {                            \
        goto b;                  \
    }                            \

#define IDE_TEST( a )            \
    if( a )                      \
    {                            \
        goto IDE_EXCEPTION_END_LABEL; \
    }                                 \

#define IDE_EXCEPTION( a ) goto IDE_EXCEPTION_END_LABEL; a:
#define IDE_EXCEPTION_CONT(a) a:
#define IDE_EXCEPTION_END       IDE_EXCEPTION_END_LABEL:;
#define IDE_SET( a )

#define SChar char
#define SInt  int
#define SLong long long
#define SFloat float 
#define SDouble double 

#define SQL_ERROR_EXIT( a, b, c) \
    if (a != 0) \
    {                                 \
        log("Error : [%d] %s\n\n", b, c); \
        exit(-1); \
    }             \

#define SQL_ERROR_NO_EXIT( a, b, c) \
    if (a != 0) \
    {                                 \
        log("Error : [%d] %s\n\n", b, c); \
    }             \

#define SYS_ERROR_EXIT( a, b ) \
    { \
        log("Error: %s : %s (%d)\n\n", a, b, errno); \
        exit(-1); \
    }             \

#define SYS_ERROR_NO_EXIT( a, b ) \
    { \
        log("Error: %s : %s (%d)\n\n", a, b, errno); \
    }             \

#endif /*_O_IDFAKE_H_ */
