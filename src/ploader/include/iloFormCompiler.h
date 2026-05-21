/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iloFormCompiler.h 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/
 
#ifndef _O_ILO_FORMCOMPILER_H
#define _O_ILO_FORMCOMPILER_H

extern FILE *yyin;

class iloFormCompiler
{
private:
public:
    iloFormCompiler()  {};

    isql_bool SetInputFile(SChar *szFileName);

    void SetInputFp(FILE *infp)     { yyin = infp; }

    void CloseInputFp()             { fclose(yyin); }

    FILE *GetInputFp()              { return yyin; }
};

#endif /* _O_ILO_FORMCOMPILER_H */
