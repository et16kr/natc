/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iloFormLexer.l 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/
 
%option 8bit
%option caseless
%option noyywrap
%option noyymore

%{
/* This is Lex Source for lexical Analysis of iLoader Form file */
//#define _ILOADER_DEBUG
//#undef _ILOADER_DEBUG

#include <ilo.h>

#if defined(BISON_POSTFIX_HPP)
#include "iloFormParser.hpp"
#else /* BISON_POSTFIX_CPP_H */
#include "iloFormParser.cpp.h"
#endif

extern uttMemory *g_memmgr;

YYSTYPE *f_lval;

void yyerror(char *s);
%}


%start COMMENT DATE_FORM

%%

"#".*                          ;
"/*"                           BEGIN COMMENT;
<COMMENT>"*/"                  BEGIN INITIAL;
<COMMENT>.|\n                  ;
"{"                            {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token '{'\n");
#endif
                                   return T_LBRACE;
                               }
"}"                            {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token '}'\n");
#endif
                                   return T_RBRACE;
                               }
"("                            {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token '('\n");
#endif
                                   return T_LBRACKET;
                               }
")"                            {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token ')'\n");
#endif
                                   return T_RBRACKET;
                               }
","                            {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token ','\n");
#endif
                                   return T_COMMA;
                               }
";"                            {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token ';'\n");
#endif
                                   return T_SEMICOLON;
                               }
"."                            {   
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token '.'\n");
#endif
                                   return T_PERIOD;
                               }
("download")|("DOWNLOAD")      {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token 'download'\n");
#endif
                                   return T_DOWNLOAD;
                               }
("condition")|("CONDITION")    {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token 'condition'\n");
#endif
                                   int t_len = idlOS::strlen(yytext);

                                   f_lval->str=(SChar*)(g_memmgr->alloc(t_len+1));
                                   idlOS::memcpy(f_lval->str, yytext, t_len);
                                   (f_lval->str)[t_len] = '\0';

                                   return T_CONDITION;
                               }
("sequence")|("SEQUENCE")    {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token 'sequence'\n");
#endif
                                   return T_SEQUENCE;
                               }                               
("table")|("TABLE")            {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token 'table'\n");
#endif
                                   return T_TABLE;
                               }
							   /*
("char")|("CHAR")               {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token 'char'\n");
#endif
                                   return T_CHAR;
                               }
("nibble")|("NIBBLE")           {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token 'nibble'\n");
#endif
                                   return T_NIBBLE;
                               }                               
("bytes")|("BYTES")                               {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token 'bytes'\n");
#endif
                                   return T_BYTES;
                               }                               
("varchar")|("VARCHAR")        {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token 'varchar'\n");
#endif
                                   return T_VARCHAR;
                               }
("bit")|("BIT")                {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token 'bit'\n");
#endif
                                   return T_BIT;
                               }
("integer")|("INTEGER")        {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token 'integer'\n");
#endif
                                   return T_INTEGER;
                               }                   
("smallint")|("SMALLINT")        {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token 'smallint'\n");
#endif
                                   return T_SMALLINT;
                               }                   
("bigint")|("BIGINT")        {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token 'bigint'\n");
#endif
                                   return T_BIGINT;
                               }                   
("numeric")|("NUMERIC")           {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token 'numeric'\n");
#endif
                                   return T_NUMERIC;
                               }
("decimal")|("DECIMAL")           {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token 'decimal'\n");
#endif
                                   return T_NUMERIC;
                               }
("float")|("FLOAT")           {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token 'float'\n");
#endif
                                   return T_FLOAT;
                               }
("real")|("REAL")           {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token 'real'\n");
#endif
                                   return T_REAL;
                               }
("double")|("DOUBLE")           {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token 'double'\n");
#endif
                                   return T_DOUBLE;
                               }
("number")|("NUMBER")          {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token 'number'\n");
#endif
                                   return T_NUMERIC;
                               }                               
("date")|("DATE")              {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token 'date'\n");
#endif
                                   return T_DATE;
                               }
("boolean")|("BOOLEAN")        {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token 'boolean'\n");
#endif
                                   return T_BOOLEAN;
                               }                   
("blob")|("BLOB")        {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token 'blob'\n");
#endif
                                   return T_BLOB;
                               }                   
							   */
("noexp")|("NOEXP")             {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token 'noexp'\n");
#endif
                                   return T_NOEXP;
                               }                   
("skip")|("SKIP")             {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token 'skip'\n");
#endif
                                   return T_SKIP;
                               }                   
("default")|("DEFAULT")        {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token 'default'\n");
#endif
                                   return T_TIMESTAMP_DEFAULT;
                               }                   
("null")|("NULL")              {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token 'null'\n");
#endif
                                   return T_TIMESTAMP_NULL;
                               }                   
("add")|("ADD")                {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token 'add'\n");
#endif
                                   return T_ADD;
                               }                   
("nextval")|("NEXTVAL")        {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token 'nextval'\n");
#endif
                                   return T_NEXTVAL;
                               }
("currval")|("CURRVAL")        {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token 'currval'\n");
#endif
                                   return T_CURRVAL;
                               }                                                         
("dateform")|("DATEFORM")      {
                                   BEGIN DATE_FORM;
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token 'dateform'\n");
#endif
                                   return T_DATEFORMAT_CMD;
                               }
<DATE_FORM>"Y"{2,4}[/-]?"MM"[/-]?"DD"     |
"DD"[/-]?"MM"[/-]?"Y"{2,4}     |
"MM"[/-]?"DD"[/-]?"Y"{2,4}     |
"DD"[/-]?"MON"[/-]?"Y"{2,4}    {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token Identifier [%s]\n", yytext);
#endif
                                   int t_len = idlOS::strlen(yytext);

                                   f_lval->str=(SChar*)(g_memmgr->alloc(t_len+1));
                                   idlOS::memcpy(f_lval->str, yytext, t_len);
                                   (f_lval->str)[t_len] = '\0';

                                   return T_DATEFORMAT;
                               }
<DATE_FORM>"'"[^"'"]*"'"                  {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token Identifier [%s]\n", yytext);
#endif
                                   int t_len = idlOS::strlen(yytext);

                                   f_lval->str=(SChar*)(g_memmgr->alloc(t_len+1));
                                   idlOS::memcpy(f_lval->str, yytext, t_len);
                                   (f_lval->str)[t_len] = '\0';

                                   return T_OPTIONAL_DATEFORMAT;
                               }
<DATE_FORM>"HH"{0,1}[:/]?"MI"{0,1}[:/]?"SS"{0,1}[:/]?"SSSSSS"{0,1}   {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token Identifier [%s]\n", yytext);
#endif
                                   int t_len = idlOS::strlen(yytext);

                                   f_lval->str=(SChar*)(g_memmgr->alloc(t_len+1));
                                   idlOS::memcpy(f_lval->str, yytext, t_len);
                                   (f_lval->str)[t_len] = '\0';

                                   return T_TIMEFORMAT;
                               }
<DATE_FORM>("Y"{2,4}){0,1}"MMDDHH"{0,1}"MI"{0,1}"SS"{0,1}"SSSSSS"{0,1}     {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token Identifier [%s]\n", yytext);
#endif
                                   int t_len = idlOS::strlen(yytext);

                                   f_lval->str=(SChar*)(g_memmgr->alloc(t_len+1));
                                   idlOS::memcpy(f_lval->str, yytext, t_len);
                                   (f_lval->str)[t_len] = '\0';

                                   return T_NOTERM_DATEFORMAT;
                               }
[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]([0-9][0-9][0-9][0-9][0-9][0-9]){0,1} {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token T_TIMESTAMP_VALUE [%s]\n", yytext);
#endif
                                   int t_len = idlOS::strlen(yytext);

                                   f_lval->str=(SChar*)(g_memmgr->alloc(t_len+1));
                                   idlOS::memcpy(f_lval->str, yytext, t_len);
                                   (f_lval->str)[t_len] = '\0';

                                   return T_TIMESTAMP_VALUE;
                               }
[1-9][0-9]*                    {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token Identifier [%s]\n", yytext);
#endif
                                   f_lval->num = atoi((char *)yytext);
                                   return T_NUMBER;
                               }
"0"                            {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token Identifier [%s]\n", yytext);
#endif
                                   return T_ZERO;
                               }
[_a-zA-Z\200-\377][a-zA-Z\200-\3770-9_$#]*         {
#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token Identifier [%s]\n", yytext);
#endif
                                   int t_len = idlOS::strlen(yytext);

                                   f_lval->str=(SChar*)(g_memmgr->alloc(t_len+1));
                                   idlOS::memcpy(f_lval->str, yytext, t_len);
                                   (f_lval->str)[t_len] = '\0';

                                   return T_IDENTIFIER;
                               }
 
["][^"]*["]                    {
                                   int t_len = idlOS::strlen(yytext);

                                   f_lval->str=(SChar*)(g_memmgr->alloc(t_len));
                                   idlOS::memcpy(f_lval->str, yytext+1, t_len-2);
                                   (f_lval->str)[t_len-2] = '\0';

#ifdef _ILOADER_DEBUG
                                   idlOS::printf("Token STRING [%s]\n", f_lval->str);
#endif
                                   return T_STRING;
                               }

<<EOF>>                        {
                                   yyterminate();
                               }

[ \t\n]+                  ;

.|\n                      return yytext[0];

%%

void
yyerror(char * /*s*/)
{
   //printf("Error:: %s \n", yytext);
   yy_flush_buffer( yy_current_buffer );
}

int yylex(YYSTYPE* lvalp, void* /*parm*/)
{
   f_lval = lvalp;
   return yylex();
}

char *
ltrim(char *s)
{
   char *p = s;
   
   while (*p == ' ' && idlOS::strlen(p) > 0)
      p++;
   
   idlOS::memcpy(s, p, strlen(s));

   return s;
}

char *
rtrim(char *s)
{
   char *str;

   str = s + idlOS::strlen(s)-1;
   for (; s<str; str--)
   {
      if (*str == ' ')
         *str = (char) 0;
      else
         break;
   }

   return s;
}

