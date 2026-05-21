/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iSQLHelp.h 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/

#ifndef _O_ISQLHELP_H_
#define _O_ISQLHELP_H_ 1

#include <idTypes.h>
#include <iSQL.h>

class iSQLHelp
{
public:
    SChar * GetHelpString(iSQLCommandKind a_HelpOption);
};

#endif // _O_ISQLHELP_H_

