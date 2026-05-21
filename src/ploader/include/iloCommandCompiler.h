/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iloCommandCompiler.h 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/
 
#ifndef _O_ILO_COMMANDCOMPILER_H
#define _O_ILO_COMMANDCOMPILER_H

class iloCommandCompiler
{
private:

public:
    iloCommandCompiler()  {}

    virtual ~iloCommandCompiler();

    void SetInputStr( SChar *s );

    isql_bool IsNullCommand( SChar *szBuf );

    isql_bool GetCommandString();
};

#endif /* _O_ILO_COMMANDCOMPILER_H */
