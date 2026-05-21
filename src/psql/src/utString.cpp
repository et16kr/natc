/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: utString.cpp 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/

#include <utString.h>

void utString::eraseWhiteSpace(SChar *a_Str)
{
    SInt i, j;
    SInt len;
    
    // 1. 앞에서 부터 검사 시작..

    len = idlOS::strlen(a_Str);
    if( len <= 0 )
    {
        return;
    }

    for (i=0; i<len && a_Str[i]; i++)
    {
        if (a_Str[i]==' ') // 스페이스 임
        {
            for (j=i; a_Str[j]; j++)
            {
                a_Str[j] = a_Str[j+1];
            }
            i--;
        }
        else
        {
            break;
        }
    }
    
    // 2. 끝에서 부터 검사 시작.. : 스페이스 없애기

    len = idlOS::strlen(a_Str);
    if( len <= 0 )
    {
        return;
    }

    for (i=len-1; a_Str[i] && len>=0; i--)
    {
        if (a_Str[i]==' ') // 스페이스 없애기
        {
            a_Str[i] = 0;
        }
        else
        {
            break;
        }
    }
}

void utString::removeLastSpace(SChar *a_Str)
{
    SInt i, len;

    len = idlOS::strlen(a_Str);
    if( len <= 0 )
    {
        return;
    }

    for (i=len-1; a_Str[i] && i>=0; i--)
    {
        if (a_Str[i]==' ') 
        {
            a_Str[i] = 0;
        }
        else
        {
            break;
        }
    }
}

void utString::toUpper(SChar *a_Str)
{
    UChar unit;
    SInt  len, j;

    len = idlOS::strlen(a_Str);
    for (j=0; j<len; j++)
    {
        unit = ((UChar*)a_Str)[j];
        if ( unit >= 97 && unit <=122 ) a_Str[j] = unit - 32;
    }
}

void utString::removeLastCR(SChar *a_Str)
{
    SInt i, len;

    len = idlOS::strlen(a_Str);
    if( len <= 0 )
    {
        return;
    }

    for (i=len-1; a_Str[i] && i>=0; i--)
    {
        if (a_Str[i]=='\n' || a_Str[i] == '\t') 
        {
            a_Str[i] = 0;
        }
        else
        {
            break;
        }
    }
}
