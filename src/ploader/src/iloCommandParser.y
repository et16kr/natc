/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iloCommandParser.y 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/
 
%pure_parser
%{
/* This is YACC Source for syntax Analysis of iLoader Command */
//#undefine _ILOADER_DEBUG

#include <ilo.h>
%}

%union{
SInt   num;
SChar *str;
}

%{

#if defined(VC_WIN32)
# include <malloc.h>
#endif
    
#define LEX_BODY 0
#define ERROR_BODY 0

SInt iloCommandParser_yyinput(SChar*, SInt);
void iloCommandParsererror(SChar *s);
void iloCommandParserinput(void);
SInt  iloCommandParserlex(YYSTYPE * lvalp, void    * param );

extern iloProgOption gProgOption;
iloProgOption *pProgOption = &gProgOption;

#define YYPARSE_PARAM param
#define YYLEX_PARAM   param

%}

%token T_IN T_OUT T_FORMOUT T_STRUCTOUT T_EXIT T_HELP 
%token T_TABLENAME_OPT T_DATAFILE_OPT T_FORMATFILE_OPT T_FORMOUTTARGET_OPT
%token T_FIRSTROW_OPT T_LASTROW_OPT T_FIELDTERM_OPT T_ROWTERM_OPT
%token T_MODETYPE_OPT T_ARRAYCOUNT_OPT T_COMMITUNIT_OPT T_ERRORCOUNT_OPT T_LOGFILE_OPT
%token T_BADFILE_OPT T_ENCLOSING_OPT T_REPLICATION_OPT T_SPLIT_OPT T_INFORMIX_OPT T_NOEXP_OPT
%token T_ISPEENER T_ORACLE T_SQLSERVER T_APPEND T_REPLACE
%token T_NUMBER T_IDENTIFIER T_FILENAME T_SEPARATOR T_ENCLOSING_SEPARATOR
%token T_TRUE T_FALSE T_INVALID_OPT T_PERIOD

%start ILOADER_COMMANDLINE

%%

ILOADER_COMMANDLINE : ILOADER_COMMAND OPTION_LIST
                        {
#ifdef _ILOADER_DEBUG
                            idlOS::printf("Rule Accept\n");
#endif
                            YYACCEPT;
                        }
                    | ILOADER_COMMAND
                        {
#ifdef _ILOADER_DEBUG
                            idlOS::printf("Rule Accept\n");
#endif
                            YYACCEPT;
                        }
                    ;

ILOADER_COMMAND : T_IN
                    {
                        pProgOption->m_CommandType = DATA_IN;
                    }
                | T_OUT
                    {
                        pProgOption->m_CommandType = DATA_OUT;
                    }
                | T_FORMOUT
                    {
                        pProgOption->m_CommandType = FORM_OUT;
                    }
                | T_STRUCTOUT
                    {
                        pProgOption->m_CommandType = STRUCT_OUT;
                    }
                | T_EXIT
                    {
                        pProgOption->m_CommandType = EXIT_COM;
                    }
                | HELP_COMMAND
                    {
                        pProgOption->m_CommandType = HELP_COM;
                    }
                ;

HELP_COMMAND : T_HELP T_IN
                 {
                     pProgOption->m_HelpArgument = DATA_IN;
                 }
             | T_HELP T_OUT
                 {
                     pProgOption->m_HelpArgument = DATA_OUT;
                 }
             | T_HELP T_FORMOUT
                 {
                     pProgOption->m_HelpArgument = FORM_OUT;
                 }
             | T_HELP T_STRUCTOUT
                 {
                     pProgOption->m_HelpArgument = STRUCT_OUT;
                 }
             | T_HELP T_EXIT
                 {
                     pProgOption->m_HelpArgument = EXIT_COM;
                 }
             | T_HELP T_HELP
                 {
                     pProgOption->m_HelpArgument = HELP_HELP;
                 }
             | T_HELP
                 {
                     pProgOption->m_HelpArgument = HELP_COM;
                 }
             ;

OPTION_LIST : OPTION_LIST OPTION_KIND
            | OPTION_KIND
            ; 

OPTION_KIND : TABLENAME_OPTION
            | DATAFILE_OPTION
            | FORMATFILE_OPTION
            | FIRSTROW_OPTION
            | LASTROW_OPTION
            | FIELDTERM_OPTION
            | ROWTERM_OPTION
            | MODETYPE_OPTION
                {
                    if (pProgOption->m_bExist_mode)
                    {
                        pProgOption->m_bErrorExist = isql_true;
                        idlOS::strcpy(pProgOption->m_ErrorMsg, "-mode Option is used more than One");
                    }
                    else
                        pProgOption->m_bExist_mode = isql_true;
                }
            | ARRAY_OPTION
            | COMMIT_OPTION
            | ERRORCOUNT_OPTION
            | LOGFILE_OPTION
            | BADFILE_OPTION
            | ENCLOSING_OPTION
            | REPLICATION_OPTION
            | SPLIT_OPTION
            | INFORMIX_OPTION
            | NOEXP_OPTION
            ;

TABLENAME_OPTION : T_TABLENAME_OPT TABLE_NAME_LIST
                    {
                        if (pProgOption->m_bExist_T)
                        {
                            pProgOption->m_bErrorExist = isql_true;
                            idlOS::strcpy(pProgOption->m_ErrorMsg, "-T Option is used more than One");
                        }
                        else
                            pProgOption->m_bExist_T = isql_true;
                    }
                 ;

TABLE_NAME_LIST : T_IDENTIFIER
                    {
                        idlOS::strcpy(pProgOption->m_TableName[0], $<str>1);
						pProgOption->m_nTableCount++;
						pProgOption->m_bExist_TabOwner = isql_false;
//printf("TableOwner[%s]\n",pProgOption->m_TableOwner[0]);
                    }
				| T_IDENTIFIER T_PERIOD T_IDENTIFIER
				    {
                        idlOS::strcpy(pProgOption->m_TableOwner[0], $<str>1);
                        idlOS::strcpy(pProgOption->m_TableName[0], $<str>3);
						pProgOption->m_nTableCount++;
						pProgOption->m_bExist_TabOwner = isql_true;
//printf("TableOwner[%s]\n",pProgOption->m_TableOwner[0]);
					}
                ;

DATAFILE_OPTION : T_DATAFILE_OPT T_FILENAME
                    {
                        if (pProgOption->m_bExist_d)
                        {
                            pProgOption->m_bErrorExist = isql_true;
                            idlOS::strcpy(pProgOption->m_ErrorMsg, "-d Option is used more than One");
                        }
                        else
                        {
                            pProgOption->m_bExist_d = isql_true;
                            idlOS::strcpy(pProgOption->m_DataFile, $<str>2);
                        }
#ifdef _ILOADER_DEBUG
                     idlOS::printf("DataFile [%s]\n", $<str>2);
                     idlOS::printf("DATAFILE_OPTION Accept\n");
#endif
                    }
                ;

FORMATFILE_OPTION : T_FORMATFILE_OPT T_FILENAME
                    {
                        if (pProgOption->m_bExist_f)
                        {
                            pProgOption->m_bErrorExist = isql_true;
                            idlOS::strcpy(pProgOption->m_ErrorMsg, "-f Option is used more than One");
                        }
                        else
                        {
                            pProgOption->m_bExist_f = isql_true;
                            idlOS::strcpy(pProgOption->m_FormFile, $<str>2);
                        }
#ifdef _ILOADER_DEBUG
                     idlOS::printf("Form File [%s]\n", $<str>2);
                     idlOS::printf("FORMATFILE_OPTION Accept\n");
#endif
                    }
                ;

FIRSTROW_OPTION : T_FIRSTROW_OPT T_NUMBER
                    {
                        if (pProgOption->m_bExist_F)
                        {
                            pProgOption->m_bErrorExist = isql_true;
                            strcpy(pProgOption->m_ErrorMsg, "-F Option is used more than One");
                        }
                        else
                        {
                            pProgOption->m_bExist_F = isql_true;
                            pProgOption->m_FirstRow = idlOS::atoi($<str>2);
                            if ( pProgOption->m_FirstRow < 0 )
                            {
                                pProgOption->m_bErrorExist = isql_true;
                                strcpy(pProgOption->m_ErrorMsg,
                                       "-F Option must be greater than Zero");
                            }
                        }
                    }
                ;

LASTROW_OPTION : T_LASTROW_OPT T_NUMBER
                    {
                        if (pProgOption->m_bExist_L)
                        {
                            pProgOption->m_bErrorExist = isql_true;
                            idlOS::strcpy(pProgOption->m_ErrorMsg, "-L Option is used more than One");
                        }
                        else
                        {
                            pProgOption->m_bExist_L = isql_true;
                            pProgOption->m_LastRow = idlOS::atoi($<str>2);
                            if ( pProgOption->m_LastRow < 0 )
                            {
                                pProgOption->m_bErrorExist = isql_true;
                                strcpy(pProgOption->m_ErrorMsg,
                                       "-L Option must be greater than Zero");
                            }
                        }
                    }
               ;

FIELDTERM_OPTION : T_FIELDTERM_OPT T_SEPARATOR
                    {
                        if (pProgOption->m_bExist_t)
                        {
                            pProgOption->m_bErrorExist = isql_true;
                            idlOS::strcpy(pProgOption->m_ErrorMsg, "-t Option is used more than One");
                        }
                        else
                        {
                            if ( idlOS::strlen($<str>2) > 10 )
                            {
                                pProgOption->m_bErrorExist = isql_true;
                                idlOS::strcpy(pProgOption->m_ErrorMsg, "-t Option string is longer than 10");
                            }
                            else
                            {
                                pProgOption->m_bExist_t = isql_true;
                                idlOS::strcpy(pProgOption->m_FieldTerm, $<str>2);
                            }
                        }
                    }
                 ;

ROWTERM_OPTION : T_ROWTERM_OPT T_SEPARATOR
                    {
                        if (pProgOption->m_bExist_r)
                        {
                            pProgOption->m_bErrorExist = isql_true;
                            idlOS::strcpy(pProgOption->m_ErrorMsg, "-r Option is used more than One");
                        }
                        else
                        {
                            if ( idlOS::strlen($<str>2) > 10 )
                            {
                                pProgOption->m_bErrorExist = isql_true;
                                idlOS::strcpy(pProgOption->m_ErrorMsg, "-r Option string is longer than 10");
                            }
                            else
                            {
                                pProgOption->m_bExist_r = isql_true;
                                idlOS::strcpy(pProgOption->m_RowTerm, $<str>2);
                            }
                        }
                    }
               ;

MODETYPE_OPTION : T_MODETYPE_OPT T_APPEND
                    {
                        pProgOption->m_LoadMode = APPEND;
                    }
                | T_MODETYPE_OPT T_REPLACE
                    {
                        pProgOption->m_LoadMode = REPLACE;
                    }
                ;

ARRAY_OPTION : T_ARRAYCOUNT_OPT T_NUMBER
                    {
                        if (pProgOption->m_bExist_array)
                        {
                            pProgOption->m_bErrorExist = isql_true;
                            idlOS::strcpy(pProgOption->m_ErrorMsg, "-array Option is used more than One");
                        }
                        else
                        {
                            pProgOption->m_bExist_array = isql_true;
                            pProgOption->m_ArrayCount = idlOS::atoi($<str>2);
                            if ( pProgOption->m_ArrayCount <= 0 )
                            {
                                pProgOption->m_bErrorExist = isql_true;
                                strcpy(pProgOption->m_ErrorMsg,
                                       "-array Option must be greater than Zero");
                            }
                        }
                    }
              ;

COMMIT_OPTION : T_COMMITUNIT_OPT T_NUMBER
                    {
                        if (pProgOption->m_bExist_commit)
                        {
                            pProgOption->m_bErrorExist = isql_true;
                            idlOS::strcpy(pProgOption->m_ErrorMsg, "-commit Option is used more than One");
                        }
                        else
                        {
                            pProgOption->m_bExist_commit = isql_true;
                            pProgOption->m_CommitUnit = idlOS::atoi($<str>2);
                            if ( pProgOption->m_CommitUnit < 0 )
                            {
                                pProgOption->m_bErrorExist = isql_true;
                                strcpy(pProgOption->m_ErrorMsg,
                                       "-commit Option must be greater than Zero");
                            }
                        }
                    }
              ;

ERRORCOUNT_OPTION : T_ERRORCOUNT_OPT T_NUMBER
                    {
                        if (pProgOption->m_bExist_errors)
                        {
                            pProgOption->m_bErrorExist = isql_true;
                            idlOS::strcpy(pProgOption->m_ErrorMsg, "-errors Option is used more than One");
                        }
                        else
                        {
                            pProgOption->m_bExist_errors = isql_true;
                            pProgOption->m_ErrorCount = idlOS::atoi($<str>2);
                            if ( pProgOption->m_ErrorCount < 0 )
                            {
                                pProgOption->m_bErrorExist = isql_true;
                                strcpy(pProgOption->m_ErrorMsg,
                                       "-errors Option must be greater than Zero");
                            }
                        }
                    }
                  ;

LOGFILE_OPTION : T_LOGFILE_OPT T_FILENAME
                    {
                        if (pProgOption->m_bExist_log)
                        {
                            pProgOption->m_bErrorExist = isql_true;
                            idlOS::strcpy(pProgOption->m_ErrorMsg, "-log Option is used more than One");
                        }
                        else
                        {
                            pProgOption->m_bExist_log = isql_true;
                            idlOS::strcpy(pProgOption->m_LogFile, $<str>2);
                        }
                    }
               ;

BADFILE_OPTION : T_BADFILE_OPT T_FILENAME
                    {
                        if (pProgOption->m_bExist_bad)
                        {
                            pProgOption->m_bErrorExist = isql_true;
                            idlOS::strcpy(pProgOption->m_ErrorMsg, "-bad Option is used more than One");
                        }
                        else
                        {
                            pProgOption->m_bExist_bad = isql_true;
                            idlOS::strcpy(pProgOption->m_BadFile, $<str>2);
                        }
                    }
               ;

ENCLOSING_OPTION : T_ENCLOSING_OPT T_ENCLOSING_SEPARATOR
                    {
                        if (pProgOption->m_bExist_e)
                        {
                            pProgOption->m_bErrorExist = isql_true;
                            idlOS::strcpy(pProgOption->m_ErrorMsg, "-e Option is used more than One");
                        }
                        else
                        {
                            if ( idlOS::strlen($<str>2) > 10 )
                            {
                                pProgOption->m_bErrorExist = isql_true;
                                idlOS::strcpy(pProgOption->m_ErrorMsg, "-e Option string is longer than 10");
                            }
                            else
                            {
                                pProgOption->m_bExist_e = isql_true;
                                idlOS::strcpy(pProgOption->m_EnclosingChar, $<str>2);
                            }
                        }
                    }
                 ;

REPLICATION_OPTION : T_REPLICATION_OPT T_TRUE
                    {
                        pProgOption->mReplication = isql_true;
                    }
                   | T_REPLICATION_OPT T_FALSE
                    {
                        pProgOption->mReplication = isql_false;
                    }
                   ;

SPLIT_OPTION : T_SPLIT_OPT T_NUMBER
                    {
                        if (pProgOption->m_bExist_split)
                        {
                            pProgOption->m_bErrorExist = isql_true;
                            idlOS::strcpy(pProgOption->m_ErrorMsg, "-split Option is used more than One");
                        }
                        else
                        {
                            pProgOption->m_bExist_split = isql_true;
                            pProgOption->m_SplitRowCount = idlOS::atoi($<str>2);
                            if ( pProgOption->m_SplitRowCount < 0 )
                            {
                                pProgOption->m_bErrorExist = isql_true;
                                strcpy(pProgOption->m_ErrorMsg,
                                       "-split Option must be greater than Zero");
                            }
                        }
                    }
                  ;

INFORMIX_OPTION
                   : T_INFORMIX_OPT
                    {
                        if (pProgOption->m_bExist_informix)
                        {
                            pProgOption->m_bErrorExist = isql_true;
                            idlOS::strcpy(pProgOption->m_ErrorMsg, "-informix Option is used more than One");
                        }
                        else
                        {
                            pProgOption->mInformix = isql_true;
                        }
                    }
                   ;

NOEXP_OPTION
                   : T_NOEXP_OPT
                    {
                        if (pProgOption->m_bExist_noexp)
                        {
                            pProgOption->m_bErrorExist = isql_true;
                            idlOS::strcpy(pProgOption->m_ErrorMsg, "-noexp Option is used more than One");
                        }
                        else
                        {
                            pProgOption->mNoExp = isql_true;
                        }
                    }
                   ;

