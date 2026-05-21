/***********************************************************************
 * Copyright 1999-2000, RTBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: uttString.h 20175 2007-01-29 01:53:09Z orc $
 **********************************************************************/

/***********************************************************************
 *
 * NAME
 *   uttString.h
 * 
 * DESCRIPTION
 *   Dynamic memory allocator.
 * 
 * PUBLIC FUNCTION(S)
 * NOTES
 * 
 * MODIFIED    (MM/DD/YYYY)
 *    hjmin     01/17/2001 - Created
 * 
 **********************************************************************/

#ifndef _O_UTTSTRING_H_
# define _O_UTTSTRING_H_  1

#include <idFake.h>

class uttString
{
    /*
    SChar* str;
    int    length;
    */
    
public:
    /*
    uttString();
    uttString(int size);
    uttString(uttString s);
    ~uttString();
    */
    
    /* strdup */
    static SChar* utt_strdup(const SChar* s);
    static SChar* utt_strcpy(SChar *s1, const SChar* s2, int n = -1);
    
    /* compare if two strings are the same */
    /* return 0 : same, o/w : not same     */
    static SInt   streq(SChar* s1, const SChar* s2);
    static SInt   strneq(SChar* s1, const SChar* s2, int n);
    static SInt   strcaseeq(SChar* s1, const SChar* s2);
    static SInt   strncaseeq(SChar* s1, const SChar* s2, int n);
    
    static void   strfree(SChar* s);
    
    /*
    static SInt   strcmp(SChar* s1, SChar* s2);
    static SInt   strcasecmp(SChar* s1, SChar* s2);
    static SInt   strncmp(SChar* s1, SChar* s2, int n);
    */
    
    //SInt strdup(uttString s);
    
    /* strcpy */
    /*
    SInt strcpy(SChar* s);
    SInt strdup(uttString s);
    
    SInt   getLength() { return length; };
    SChar* getString() { return str; };
    */
};

#endif //_O_UTTSTRING_H_
