/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iloCommandLexer.l 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/
 
%option 8bit
%option prefix="iloCommandLexer"
%option noyywrap
%option noyymore

%{
/* This is Lex Source for lexical Analysis of iLoader Command */
#define _ILOADER_DEBUG
#undef _ILOADER_DEBUG

#include <ilo.h>

#if defined(BISON_POSTFIX_HPP)
#include "iloCommandParser.hpp"
#else /* BISON_POSTFIX_CPP_H */
#include "iloCommandParser.cpp.h"
#endif

#undef YY_INPUT
#define YY_INPUT(b, r, m)       (r = iloCommandParser_yyinput((char *)b, m))

extern uttMemory *g_memmgr;
extern iloProgOption gProgOption;
iloProgOption *qProgOption = &gProgOption;
YYSTYPE  *lval;

void gSetInputStr(char *s);
int  string_yyinput(char *buf, int max_size);
void SeparatorCopy(char *szTar, char *szSrc);
char    *input_strptr;
vSLong   length_input_str;

int  iloCommandParser_yyinput(char*, int);
void iloCommandParsererror(char *s);

%}

%start WAIT_NUM WAIT_IDENT WAIT_FILE WAIT_SEPARATOR WAIT_ENCLOSING_SEPARATOR WAIT_BOOL WAIT_MODE

%%

"in "|"IN "           { 
#ifdef _ILOADER_DEBUG
                          idlOS::printf("Get Token [in]\n");
#endif
                          if (qProgOption->m_bExist_b) ;
                          else return T_IN;
                      }
"out "|"OUT "         {
#ifdef _ILOADER_DEBUG
                          idlOS::printf("Get Token [out]\n");
#endif
                          if (qProgOption->m_bExist_b) ;
                          else return T_OUT;
                      }
"formout "|"FORMOUT " {
#ifdef _ILOADER_DEBUG
                          idlOS::printf("Get Token [formout]\n");
#endif
                          if (qProgOption->m_bExist_b) ;
                          else return T_FORMOUT;
                      }
"structout "|"STRUCTOUT " {
#ifdef _ILOADER_DEBUG
                          idlOS::printf("Get Token [structout]\n");
#endif
                          if (qProgOption->m_bExist_b) ;
                          else return T_STRUCTOUT;
                      }
"quit"|"QUIT"|"exit"|"EXIT" {
#ifdef _ILOADER_DEBUG
                          idlOS::printf("Get Token [exit]\n");
#endif
                          if (qProgOption->m_bExist_b) ;
                          else return T_EXIT;
                      }
"help"|"HELP"         {
#ifdef _ILOADER_DEBUG
                          idlOS::printf("Get Token [help]\n");
#endif
                          if (qProgOption->m_bExist_b) ;
                          else return T_HELP;
                      }
"."                   {   return T_PERIOD;   }
"-T"                  {
                          BEGIN WAIT_IDENT;
#ifdef _ILOADER_DEBUG
                          idlOS::printf("Get Token [-T]\n");
#endif
                          if (qProgOption->m_bExist_b) ;
                          else return T_TABLENAME_OPT;
                      }
"-d"                  {
                          BEGIN WAIT_FILE;
#ifdef _ILOADER_DEBUG
                          idlOS::printf("Get Token [-d]\n");
#endif
                          if (qProgOption->m_bExist_b) ;
                          else return T_DATAFILE_OPT;
                      }
"-f"                  {
                          BEGIN WAIT_FILE;
#ifdef _ILOADER_DEBUG
                          idlOS::printf("Get Token [-f]\n");
#endif
                          if (qProgOption->m_bExist_b) ;
                          else return T_FORMATFILE_OPT;
                      }

"-ft"                 {
#ifdef _ILOADER_DEBUG
                          idlOS::printf("Get Token [-ft]\n");
#endif
                          if (qProgOption->m_bExist_b) ;
                          else return T_FORMOUTTARGET_OPT;
                      }

"-F"                  {
                          BEGIN WAIT_NUM;
#ifdef _ILOADER_DEBUG
                          idlOS::printf("Get Token [-F]\n");
#endif
                          if (qProgOption->m_bExist_b) ;
                          else return T_FIRSTROW_OPT;
                      }

"-L"                  {
                          BEGIN WAIT_NUM;
#ifdef _ILOADER_DEBUG
                          if (qProgOption->m_bExist_b) ;
                          else idlOS::printf("Get Token [-L]\n");
#endif
                          return T_LASTROW_OPT;
                      }

"-t "                  {
                          BEGIN WAIT_SEPARATOR;
#ifdef _ILOADER_DEBUG
                          idlOS::printf("Get Token [-t]\n");
#endif
                          if (qProgOption->m_bExist_b) ;
                          else return T_FIELDTERM_OPT;
                      }
"-r "                  {
                          BEGIN WAIT_SEPARATOR;
#ifdef _ILOADER_DEBUG
                          idlOS::printf("Get Token [-r]\n");
#endif
                          if (qProgOption->m_bExist_b) ;
                          else return T_ROWTERM_OPT;
                      }
"-mode"               {
                          BEGIN WAIT_MODE;
#ifdef _ILOADER_DEBUG
                          idlOS::printf("Get Token [-mode]\n");
#endif
                          if (qProgOption->m_bExist_b) ;
                          else return T_MODETYPE_OPT;
                      }
"-array"              {
                          BEGIN WAIT_NUM;
#ifdef _ILOADER_DEBUG
                          idlOS::printf("Get Token [-array]\n");
#endif
                          if (qProgOption->m_bExist_b) ;
                          else return T_ARRAYCOUNT_OPT;
                      }
"-commit"             {
                          BEGIN WAIT_NUM;
#ifdef _ILOADER_DEBUG
                          idlOS::printf("Get Token [-commit]\n");
#endif
                          if (qProgOption->m_bExist_b) ;
                          else return T_COMMITUNIT_OPT;
                      }
"-errors"             {
                          BEGIN WAIT_NUM;
#ifdef _ILOADER_DEBUG
                          idlOS::printf("Get Token [-errors]\n");
#endif
                          if (qProgOption->m_bExist_b) ;
                          else return T_ERRORCOUNT_OPT;
                      }
"-log"                {
                          BEGIN WAIT_FILE;
#ifdef _ILOADER_DEBUG
                          idlOS::printf("Get Token [-log]\n");
#endif
                          if (qProgOption->m_bExist_b) ;
                          else return T_LOGFILE_OPT;
                      }
"-bad"                {
                          BEGIN WAIT_FILE;
#ifdef _ILOADER_DEBUG
                          idlOS::printf("Get Token [-bad]\n");
#endif
                          if (qProgOption->m_bExist_b) ;
                          else return T_BADFILE_OPT;
                      }
"-e"                  {
                          BEGIN WAIT_ENCLOSING_SEPARATOR;
#ifdef _ILOADER_DEBUG
                          idlOS::printf("Get Token [-e]\n");
#endif
                          if (qProgOption->m_bExist_b) ;
                          else return T_ENCLOSING_OPT;
                      }
"-replication"        {
                          BEGIN WAIT_BOOL;
#ifdef _ILOADER_DEBUG
                          idlOS::printf("Get Token [-replication]\n");
#endif
                          if (qProgOption->m_bExist_b) ;
                          else return T_REPLICATION_OPT;
                      }
"-split"        {
                          BEGIN WAIT_NUM;
#ifdef _ILOADER_DEBUG
                          idlOS::printf("Get Token [-split]\n");
#endif
                          if (qProgOption->m_bExist_b) ;
                          else return T_SPLIT_OPT;
                      }
"-informix"        {
#ifdef _ILOADER_DEBUG
                          idlOS::printf("Get Token [-informix]\n");
#endif
                          if (qProgOption->m_bExist_b) ;
                          else return T_INFORMIX_OPT;
                      }
"-noexp"        {
#ifdef _ILOADER_DEBUG
                          idlOS::printf("Get Token [-noexp]\n");
#endif
                          if (qProgOption->m_bExist_b) ;
                          else return T_NOEXP_OPT;
                      }

<WAIT_MODE>"append"|"APPEND"     {
#ifdef _ILOADER_DEBUG
                          idlOS::printf("Get Token [append]\n");
#endif
                          if (qProgOption->m_bExist_b) ;
                          else return T_APPEND;
                      }

<WAIT_MODE>"replace"|"REPLACE"   {
#ifdef _ILOADER_DEBUG
                          idlOS::printf("Get Token [replace]\n");
#endif
                          if (qProgOption->m_bExist_b) ;
                          else return T_REPLACE;
                      }
<WAIT_BOOL>"true"|"TRUE"         {
#ifdef _ILOADER_DEBUG
                          idlOS::printf("Get Token [true]\n");
#endif
                          if (qProgOption->m_bExist_b) ;
                          else return T_TRUE;
                      }
<WAIT_BOOL>"false"|"FALSE"       {
#ifdef _ILOADER_DEBUG
                          idlOS::printf("Get Token [false]\n");
#endif
                          if (qProgOption->m_bExist_b) ;
                          else return T_FALSE;
                      }

<WAIT_NUM>[-]{0,1}[0-9]+      {
#ifdef _ILOADER_DEBUG
                          idlOS::printf("Get Token [T_NUMBER,%s]\n", yytext);
#endif
                          lval->num = idlOS::atoi((char *)yytext);
                          if (qProgOption->m_bExist_b) ;
                          else return T_NUMBER;
                      }

<WAIT_IDENT>[a-zA-Z\200-\377][a-zA-Z\200-\3770-9_$#]*  {
#ifdef _ILOADER_DEBUG
                          idlOS::printf("Get Token [T_IDENTIFIER,%s]\n", yytext);
#endif
//                          idlOS::strcpy(lval->str, (char *)yytext);
                          if (qProgOption->m_bExist_b) ;
                          else return T_IDENTIFIER;
                      }

<WAIT_FILE>[./_a-zA-Z\200-\377][^ ,*?"<>|\t\n\\]*    {
#ifdef _ILOADER_DEBUG
                          idlOS::printf("Get Token [T_FILENAME,%s]\n", yytext);
#endif
//                          idlOS::strcpy(lval->str, (char *)yytext);
                          BEGIN INITIAL;
                          if (qProgOption->m_bExist_b) ;
                          else return T_FILENAME;
                      }

<WAIT_SEPARATOR>[^ \t\n"]{1,20}  {
#ifdef _ILOADER_DEBUG
                          idlOS::printf("Get Token [T_SEPARATOR,%s]\n", yytext);
#endif
                          //strcpy(lval->str, (char *)(yytext+1));
                          //param->str[strlen(lval->str)-1] = '\0';
                          SeparatorCopy(lval->str, (char *)yytext);
                          idlOS::strcpy(yytext, lval->str);
                          BEGIN INITIAL;
                          if (qProgOption->m_bExist_b) ;
                          else return T_SEPARATOR;
                      }


<WAIT_ENCLOSING_SEPARATOR>[^ \t\n]{1,20}      {
#ifdef _ILOADER_DEBUG
                          idlOS::printf("Get Token [T_ENCLOSING_SEPARATOR,%s]\n", yytext);
#endif
                          SeparatorCopy(lval->str, (char *)yytext);
                          idlOS::strcpy(yytext, lval->str);
                          BEGIN INITIAL;
                          if (qProgOption->m_bExist_b) ;
                          else return T_ENCLOSING_SEPARATOR;
                      }

<<EOF>>               {
                          yyterminate();
                      }
[ \t\n]+              {}

.|\n                  {
                          while(yylex() != 0) ;
                          qProgOption->m_bExist_b = isql_true;
                      }

-[a-zA-Z_]*           {
#ifdef _ILOADER_DEBUG
                          idlOS::printf("Get Token [INVALID_OPTION,%s]\n", yytext);
#endif
                          qProgOption->mInvalidOption = isql_true;
                          idlOS::sprintf(qProgOption->m_ErrorMsg, "%s Option is invalid", yytext);
                          BEGIN INITIAL;
                          iloCommandParsererror("Unkown Option");
                          return T_INVALID_OPT;
                      }

%%

void
iloCommandParsererror(char * /*s*/)
{
   //printf("Error:: %s \n", CommandLLexertext);
   iloCommandLexer_flush_buffer( yy_current_buffer );
}

void gSetInputStr(char *s)
{
    length_input_str = idlOS::strlen(s) + (vSLong)s; 
    input_strptr = s; 
}

int iloCommandParser_yyinput(char *buf, int max_size)
{
        int     n;

        if (max_size < length_input_str - (vSLong)input_strptr -1) 
        {
            n = max_size;
        }
        else 
        {
            n = length_input_str - (vSLong)input_strptr;
        }

        if(n > 0) 
        {
                idlOS::memcpy(buf,input_strptr,n);
                input_strptr += n;
                buf[n] = 0;
        }
        return n;
}

void SeparatorCopy(char *szTar, char *szSrc)
{
    int i, j,  nLen;

    nLen = idlOS::strlen(szSrc);
    for (i = 0, j = 0; i < nLen; i++)
    {
        if (szSrc[i] == '\"')
        {
//            szTar[j++] ='\"';
            continue;
        }
        else if (szSrc[i] == '%')
        {

            if (szSrc[i+1] == 'n')
            {
                szTar[j++] = '\n';
                i++;
                continue;
            }
            else if (szSrc[i+1] == 't')
            {
                szTar[j++] = '\t';
                i++;
                continue;
            }
        }

        szTar[j++] = szSrc[i];
    }

    szTar[j] = '\0';
}

int iloCommandParserlex(
YYSTYPE * lvalp,
void    * /*param*/ )
{
  SInt        rc;
  SInt        t_len;

  rc = yylex();
  t_len = idlOS::strlen(yytext);
  lvalp->str=(SChar*)(g_memmgr->alloc(t_len+1));
  idlOS::memcpy(lvalp->str, yytext, t_len);
  (lvalp->str)[t_len] = '\0';
//  printf("===>parserlex ::: %s\n", yytext);
  lval = lvalp;
  return rc;
}
