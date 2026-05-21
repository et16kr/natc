/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: idFake.h 2570 2006-12-04 07:10:09Z  $
 **********************************************************************/

#ifndef _O_IDFAKE_H_ 
#define  _O_IDFAKE_H_  1

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

#define ID_SIZEOF sizeof
#define IDE_ASSERT assert
#define ID_UINT32_FMT   "u"

typedef enum
{
    ID_FALSE = 0,
    ID_TRUE  = 1
} idBool;

typedef enum
{
    IDE_FAILURE = -1,
    IDE_SUCCESS =  0,
    IDE_CM_STOP =  1
} IDE_RC;

#define SChar char
#define SInt  int
#define UInt  unsigned int
#if defined(STAF_OS_NAME_WIN32)
    #define SLong LONGLONG 
    #define ULong ULONGLONG 
#else
    #define SLong long long
    #define ULong unsigned long long
#endif
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
