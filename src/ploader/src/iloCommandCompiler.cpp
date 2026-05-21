/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iloCommandCompiler.cpp 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/
 
#include <ilo.h>

#ifdef USE_READLINE
#include <histedit.h>

extern EditLine *gEdo;
extern History  *gHist;
extern HistEvent gEvent;
#endif


iloCommandCompiler::~iloCommandCompiler()
{
}

void iloCommandCompiler::SetInputStr(SChar *s)
{
    gSetInputStr(s);
}

isql_bool iloCommandCompiler::IsNullCommand(SChar *szBuf)
{
    SChar *p;

    for (p = szBuf; *p != '\0'; p++)
    {
        if ((*p != ' ') && (*p != '\t') && (*p != '\n'))
            return isql_false;
    } 

    return isql_true;
}

isql_bool iloCommandCompiler::GetCommandString()
{
    static SChar szBuf[500];
#ifdef USE_READLINE
    SInt          ch_cnt;
    const char   *in_ch;
#endif

    idlOS::fflush(stdin);
#ifdef USE_READLINE
    in_ch = el_gets(gEdo, &ch_cnt);

    if ((in_ch == NULL) || (ch_cnt == 0))
    {
        idlOS::exit(0);
    }

    if (*in_ch != '\n')
    {
        history(gHist, &gEvent, H_ENTER, in_ch);
    }

    idlOS::strncpy(szBuf, in_ch, ch_cnt);
    szBuf[ch_cnt] = '\0';
#else
    idlOS::printf("\niLoader> ");
    idlOS::fflush(stdout);
    idlOS::gets(szBuf, sizeof(szBuf));
#endif

    IDE_TEST( IsNullCommand(szBuf) == isql_true );

    strcat(szBuf, " ");
    SetInputStr(szBuf);

    return isql_true;

    IDE_EXCEPTION_END;

    return isql_false;
}

