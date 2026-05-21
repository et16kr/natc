/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: utString.h 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/

#ifndef _O_UTSTRING_H_
#define _O_UTSTRING_H_ 1

#include <idl.h>

class utString
{
public:
    void eraseWhiteSpace(SChar *a_Str);
    void removeLastSpace(SChar *a_Str);
    void removeLastCR(SChar *a_Str);
    void toUpper(SChar *a_Str);
};

#endif // _O_UTSTRING_H_

