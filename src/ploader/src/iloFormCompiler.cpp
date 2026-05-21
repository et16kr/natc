/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iloFormCompiler.cpp 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/
 
#include <ilo.h>

isql_bool iloFormCompiler::SetInputFile(SChar *szFileName)
{
    FILE *fp; 

    fp = ilo_fopen(szFileName, "rt");
    IDE_TEST( fp == NULL );

    yyin = fp;
    return isql_true;

    IDE_EXCEPTION_END;

    return isql_false;
}

