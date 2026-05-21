/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iloFormParser.y 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/
 
%pure_parser
%{
/* This is YACC Source for syntax Analysis of iLoader Form file */

//#define _ILOADER_DEBUG
//#undefine _ILOADER_DEBUG

#include <ilo.h>
%}

%union{
SInt  num;
SChar *str;
iloTableNode *pNode;
}

%{

#if defined(VC_WIN32)
# include <malloc.h>
#endif

#define LEX_BODY 0
#define ERROR_BODY 0

#define SKIP_MASK  1 
#define NOEXP_MASK 2 

SInt  yylex(YYSTYPE * lvalp, void * param);
void yyerror(SChar *s);
SChar *ltrim(SChar *s);
SChar *rtrim(SChar *s);

SChar gDateForm[64];
SChar gTimestampVal[16];
TimestampType gTimestampType;
idBool gAddFlag;
SChar  gTmpBuf[256];

#define YYPARSE_PARAM param
#define YYLEX_PARAM   param

%}

%token T_SEMICOLON T_COMMA T_LBRACE T_RBRACE T_LBRACKET T_RBRACKET T_PERIOD
%token T_DOWNLOAD T_SEQUENCE T_TABLE
%token T_NUMERIC T_CHAR T_VARCHAR T_BIT T_DATE T_INTEGER T_BYTES T_NIBBLE T_NEXTVAL T_CURRVAL T_DOUBLE T_SMALLINT T_BIGINT T_DECIMAL T_FLOAT T_REAL T_BOOLEAN T_BLOB
%token T_ZERO T_DATEFORMAT_CMD T_SKIP T_ADD T_TIMESTAMP_DEFAULT T_TIMESTAMP_NULL T_NOEXP
%token <str> T_TIMESTAMP_VALUE T_CONDITION
%token <str> T_IDENTIFIER T_STRING T_TIMEFORMAT T_DATEFORMAT T_NOTERM_DATEFORMAT T_OPTIONAL_DATEFORMAT
%token <num> T_NUMBER

%type <str> user_object_name
%type <str> column_name
%type <pNode> ILOADER_FORM DOWN_COND_DEF SEQ_DEF TABLE_DEF ATTRIBUTE_DEF_LIST SEQ_DEF_LIST
%type <pNode> ATTRIBUTE_DEF DATEFORMAT_DEF
%type <num> SKIP_DEF SKIPNOEXP_DEF

%start ILOADER_FORM

%%

ILOADER_FORM 
    : DOWN_COND_DEF TABLE_DEF
      { 
          $1->SetBrother($2);
        
          $$ = new iloTableNode(TABLE_NODE, NULL, $1, NULL);
          //gTableTree.SetTreeRoot($$);
          *((iloTableNode **) param) = $$;
#ifdef _ILOADER_DEBUG
          idlOS::printf("Address of $$ [%x]\n", $$);
          idlOS::printf("Rule Accept\n"); 
#endif
          YYACCEPT;
      }
    | TABLE_DEF DOWN_COND_DEF
      {
          $2->SetBrother($1);
    
          $$ = new iloTableNode(TABLE_NODE, NULL, $2, NULL);
          //gTableTree.SetTreeRoot($$);
          *((iloTableNode **) param) = $$;
#ifdef _ILOADER_DEBUG
          idlOS::printf("Address of $$ [%x]\n", $$);
          idlOS::printf("Rule Accept\n");
#endif
          YYACCEPT;
      }
    | SEQ_DEF_LIST TABLE_DEF DOWN_COND_DEF
      {
          $3->SetBrother($2);
    
          $$ = new iloTableNode(TABLE_NODE, NULL, $3, NULL);
          //gTableTree.SetTreeRoot($$);
          *((iloTableNode **) param) = $$;
#ifdef _ILOADER_DEBUG
          idlOS::printf("Address of $$ [%x]\n", $$);
          idlOS::printf("Rule Accept\n");
#endif
          YYACCEPT;
      }
    | TABLE_DEF
      {
          $$ = new iloTableNode(TABLE_NODE, NULL, $1, NULL);
          //gTableTree.SetTreeRoot($$);
          *((iloTableNode **) param) = $$;
#ifdef _ILOADER_DEBUG
          idlOS::printf("Rule Accept\n");
#endif
          YYACCEPT;
      }
    | SEQ_DEF_LIST TABLE_DEF
      { 
          //$1->SetBrother($2);

          $$ = new iloTableNode(TABLE_NODE, (SChar *)"seq", $2, NULL);
          //gTableTree.SetTreeRoot($$);
          *((iloTableNode **) param) = $$;
          //idlOS::printf("## HERE SEQUENCE SEQ_DEF PARSING ##");
#ifdef _ILOADER_DEBUG
          idlOS::printf("Address of $$ [%x]\n", $$);
          idlOS::printf("Rule Accept\n"); 
#endif
          YYACCEPT;
      }
    | TABLE_DEF DATEFORMAT_DEF
      { 
          //$1->SetBrother($2);

          $$ = new iloTableNode(TABLE_NODE, (SChar *)"dateform", $1, NULL);
          //gTableTree.SetTreeRoot($$);
          *((iloTableNode **) param) = $$;
          //idlOS::printf("## HERE SEQUENCE DATEFORMAT_DEF PARSING ##");
#ifdef _ILOADER_DEBUG
          idlOS::printf("Address of $$ [%x]\n", $$);
          idlOS::printf("Rule Accept\n"); 
#endif
          YYACCEPT;
      }
    | SEQ_DEF_LIST TABLE_DEF DATEFORMAT_DEF
      { 
          $$ = new iloTableNode(TABLE_NODE, (SChar *)"dateform", $2, NULL);
          *((iloTableNode **) param) = $$;
#ifdef _ILOADER_DEBUG
          idlOS::printf("Address of $$ [%x]\n", $$);
          idlOS::printf("Rule Accept\n"); 
#endif
          YYACCEPT;
      }
    | TABLE_DEF DATEFORMAT_DEF DOWN_COND_DEF
      {
          $3->SetBrother($1);

          $$ = new iloTableNode(TABLE_NODE, (SChar *)"dateform", $3, NULL);
          //gTableTree.SetTreeRoot($$);
          *((iloTableNode **) param) = $$;
#ifdef _ILOADER_DEBUG
          idlOS::printf("Address of $$ [%x]\n", $$);
          idlOS::printf("Rule Accept\n");
#endif
          YYACCEPT;
      }
    | SEQ_DEF_LIST TABLE_DEF DATEFORMAT_DEF DOWN_COND_DEF
      {
          $4->SetBrother($2);

          $$ = new iloTableNode(TABLE_NODE, (SChar *)"dateform", $4, NULL);
          //gTableTree.SetTreeRoot($$);
          *((iloTableNode **) param) = $$;
#ifdef _ILOADER_DEBUG
          idlOS::printf("Address of $$ [%x]\n", $$);
          idlOS::printf("Rule Accept\n");
#endif
          YYACCEPT;
      }
    | TABLE_DEF DOWN_COND_DEF DATEFORMAT_DEF
      {
          $2->SetBrother($1);

          $$ = new iloTableNode(TABLE_NODE, (SChar *)"dateform", $2, NULL);
          //gTableTree.SetTreeRoot($$);
          *((iloTableNode **) param) = $$;
#ifdef _ILOADER_DEBUG
          idlOS::printf("Address of $$ [%x]\n", $$);
          idlOS::printf("Rule Accept\n");
#endif
          YYACCEPT;
      }
    | SEQ_DEF_LIST TABLE_DEF DOWN_COND_DEF DATEFORMAT_DEF
      {
          $3->SetBrother($2);

          $$ = new iloTableNode(TABLE_NODE, (SChar *)"dateform", $3, NULL);
          //gTableTree.SetTreeRoot($$);
          *((iloTableNode **) param) = $$;
#ifdef _ILOADER_DEBUG
          idlOS::printf("Address of $$ [%x]\n", $$);
          idlOS::printf("Rule Accept\n");
#endif
          YYACCEPT;
      }
    ;

DOWN_COND_DEF
    : T_DOWNLOAD T_CONDITION T_STRING
      {
        $$ = new iloTableNode(DOWN_NODE, $3, NULL, NULL);
      }
    ;

SEQ_DEF_LIST
    : SEQ_DEF | SEQ_DEF_LIST SEQ_DEF 
    ;

SEQ_DEF
    : T_SEQUENCE user_object_name user_object_name
      {
          InsertSeq($2, $3, (SChar *)"nextval");
          //idlOS::printf("## HERE SEQUENCE");
      }                                               
    | T_SEQUENCE user_object_name user_object_name T_NEXTVAL
      {
          InsertSeq($2, $3, (SChar *)"nextval");
      }   
    | T_SEQUENCE user_object_name user_object_name T_CURRVAL
      {
          InsertSeq($2, $3, (SChar *)"currval");
                                    
      }
    ;
    
DATEFORMAT_DEF
    : T_DATEFORMAT_CMD T_DATEFORMAT
      {
          idlOS::strcpy(gDateForm, $2);
      }
    | T_DATEFORMAT_CMD T_NOTERM_DATEFORMAT
      {
          idlOS::strcpy(gDateForm, $2);
      }
    | T_DATEFORMAT_CMD T_TIMEFORMAT
      {
          idlOS::strcpy(gDateForm, $2);
      }
    | T_DATEFORMAT_CMD T_DATEFORMAT T_TIMEFORMAT
      {
          idlOS::strcpy(gDateForm, $2);
          idlOS::strcat(gDateForm, " ");
          idlOS::strcat(gDateForm, $3);
      }
    | T_DATEFORMAT_CMD T_OPTIONAL_DATEFORMAT
      {
          SInt len  = 0;
          idlOS::strcpy(gDateForm, $2);
          len = idlOS::strlen($2);
          gDateForm[0] = ' ';
          gDateForm[len-1] = ' ';
          strcpy(gDateForm, ltrim(gDateForm));
          strcpy(gDateForm, rtrim(gDateForm));
      }
    ;
    
TABLE_DEF
    : T_TABLE user_object_name T_LBRACE ATTRIBUTE_DEF_LIST T_RBRACE
      {
          $$ = new iloTableNode(TABLENAME_NODE, $2, $4, NULL);
      }
    ;

ATTRIBUTE_DEF_LIST
    : ATTRIBUTE_DEF_LIST ATTRIBUTE_DEF
      {
          iloTableNode *pAttr;
    
          pAttr = $1;
          while (pAttr->GetBrother() != NULL)
              pAttr = pAttr->GetBrother();
          pAttr->SetBrother($2);
          $$ = $1;
      }
    | ATTRIBUTE_DEF
      {
          $$ = $1;
      }
    ;

ATTRIBUTE_DEF
    : column_name T_IDENTIFIER T_LBRACKET T_NUMBER T_RBRACKET SKIPNOEXP_DEF T_SEMICOLON
      {
          iloTableNode *pAttrName, *pAttrType;
        
          if ( idlOS::strcasecmp($2, "CHAR") == 0 )
          {
              pAttrType = new iloTableNode(ATTRTYPE_NODE, (SChar *)"char", NULL, NULL);
              pAttrName = new iloTableNode(ATTRNAME_NODE, $1, NULL, pAttrType);
              $$ = new iloTableNode(ATTR_NODE, NULL, pAttrName, NULL);
              $$->setSkipFlag($6 & SKIP_MASK);
              $$->setPrecision($4, 0);
#ifdef _ILOADER_DEBUG
              idlOS::printf("xx char(n)\n");
#endif
          }
          else if ( idlOS::strcasecmp($2, "NIBBLE") == 0 )
          {
              pAttrType = new iloTableNode(ATTRTYPE_NODE, (SChar *)"nibble", NULL, NULL);
              pAttrName = new iloTableNode(ATTRNAME_NODE, $1, NULL, pAttrType);
              $$ = new iloTableNode(ATTR_NODE, NULL, pAttrName, NULL);
              $$->setSkipFlag($6 & SKIP_MASK);
              $$->setPrecision($4, 0);
#ifdef _ILOADER_DEBUG
              idlOS::printf("xx nibble(n)\n");
#endif
          }
          else if ( idlOS::strcasecmp($2, "BYTES") == 0 )
          {
              pAttrType = new iloTableNode(ATTRTYPE_NODE, (SChar *)"bytes", NULL, NULL);
              pAttrName = new iloTableNode(ATTRNAME_NODE, $1, NULL, pAttrType);
              $$ = new iloTableNode(ATTR_NODE, NULL, pAttrName, NULL);
              $$->setSkipFlag($6 & SKIP_MASK);
              $$->setPrecision($4, 0);
#ifdef _ILOADER_DEBUG
              idlOS::printf("xx bytes(n)\n");
#endif
          }
          else if ( idlOS::strcasecmp($2, "VARCHAR") == 0 )
          {
              pAttrType = new iloTableNode(ATTRTYPE_NODE, (SChar *)"varchar", NULL, NULL);
              pAttrName = new iloTableNode(ATTRNAME_NODE, $1, NULL, pAttrType);
              $$ = new iloTableNode(ATTR_NODE, NULL, pAttrName, NULL);
              $$->setSkipFlag($6 & SKIP_MASK);
#ifdef _ILOADER_DEBUG
              printf("xx varchar(n)\n");
#endif
          }
          else if ( idlOS::strcasecmp($2, "BIT") == 0 )
          {
              pAttrType = new iloTableNode(ATTRTYPE_NODE, (SChar *)"bit", NULL, NULL);
              pAttrName = new iloTableNode(ATTRNAME_NODE, $1, NULL, pAttrType);
              $$ = new iloTableNode(ATTR_NODE, NULL, pAttrName, NULL);
              $$->setSkipFlag($6 & SKIP_MASK);
              $$->setPrecision($4, 0);
#ifdef _ILOADER_DEBUG
              idlOS::printf("xx bit(n)\n");
#endif
          }
          else if ( idlOS::strcasecmp($2, "DOUBLE") == 0 )
          {
              pAttrType = new iloTableNode(ATTRTYPE_NODE, (SChar *)"double", NULL, NULL);
              pAttrName = new iloTableNode(ATTRNAME_NODE, $1, NULL, pAttrType);
              $$ = new iloTableNode(ATTR_NODE, NULL, pAttrName, NULL);
              $$->setSkipFlag($6 & SKIP_MASK);
#ifdef _ILOADER_DEBUG
              printf("xx double(n)\n");
#endif
          }
          else if ( idlOS::strcasecmp($2, "BLOB") == 0 )
          {
              pAttrType = new iloTableNode(ATTRTYPE_NODE, (SChar *)"blob", NULL, NULL);
              pAttrName = new iloTableNode(ATTRNAME_NODE, $1, NULL, pAttrType);
              $$ = new iloTableNode(ATTR_NODE, NULL, pAttrName, NULL);
              $$->setSkipFlag($6 & SKIP_MASK);
              $$->setPrecision($4, 0);
#ifdef _ILOADER_DEBUG
              printf("xx blob(n)\n");
#endif
          }
          else if ( idlOS::strcasecmp($2, "NUMERIC") == 0 ||
                    idlOS::strcasecmp($2, "NUMBER") == 0 ||
                    idlOS::strcasecmp($2, "DECIMAL") == 0 )
          {
              pAttrType = new iloTableNode(ATTRTYPE_NODE, (SChar *)"numeric_long", NULL, NULL);
              pAttrName = new iloTableNode(ATTRNAME_NODE, $1, NULL, pAttrType);
              $$ = new iloTableNode(ATTR_NODE, NULL, pAttrName, NULL);
              $$->setSkipFlag($6 & SKIP_MASK);
              $$->setNoExpFlag($6 & NOEXP_MASK);
#ifdef _ILOADER_DEBUG
              printf("xx numeric(n)\n");
#endif
          }
          else
          {
              idlOS::printf("Type [%s(n)] is not supported.\n", $2);
              YYABORT;
          }
      }

    // BUG-8679  column DATE FORMAT
    | column_name T_IDENTIFIER T_STRING SKIP_DEF T_SEMICOLON
      {
          iloTableNode *pAttrName, *pAttrType;

          if ( idlOS::strcasecmp($2, "DATE") == 0 )
          {
              gDateForm[0] = '\0';
              pAttrType = new iloTableNode(ATTRTYPE_NODE, (SChar *)"date", NULL, NULL);
              pAttrName = new iloTableNode(ATTRNAME_NODE, $1, NULL, pAttrType);
              // nodeValue 를 dateFormat 저장장소로 사용
              $$ = new iloTableNode(ATTR_NODE, $3, pAttrName, NULL);
              $$->setSkipFlag($4);
#ifdef _ILOADER_DEBUG
              idlOS::printf("xx date\n");
#endif
          }
          else
          {
              idlOS::printf("Type [%s] is not supported.\n", $2);
              YYABORT;
          }
      }

// added by leekmo
    | column_name T_IDENTIFIER SKIPNOEXP_DEF T_SEMICOLON
      {
              
          iloTableNode *pAttrName, *pAttrType;

          if ( idlOS::strcasecmp($2, "DOUBLE") == 0 )
          {
              pAttrType = new iloTableNode(ATTRTYPE_NODE, (SChar *)"double", NULL, NULL);
              pAttrName = new iloTableNode(ATTRNAME_NODE, $1, NULL, pAttrType);
              $$ = new iloTableNode(ATTR_NODE, NULL, pAttrName, NULL);
              $$->setSkipFlag($3 & SKIP_MASK);
#ifdef _ILOADER_DEBUG
              idlOS::printf("xx double\n");
#endif
          }
          else if ( idlOS::strcasecmp($2, "SMALLINT") == 0 )
          {
              pAttrType = new iloTableNode(ATTRTYPE_NODE, (SChar *)"smallint", NULL, NULL);
              pAttrName = new iloTableNode(ATTRNAME_NODE, $1, NULL, pAttrType);
              $$ = new iloTableNode(ATTR_NODE, NULL, pAttrName, NULL);
              $$->setSkipFlag($3 & SKIP_MASK);
#ifdef _ILOADER_DEBUG
              idlOS::printf("xx smallint\n");
#endif
          }
          else if ( idlOS::strcasecmp($2, "BIGINT") == 0 )
          {
              pAttrType = new iloTableNode(ATTRTYPE_NODE, (SChar *)"bigint", NULL, NULL);
              pAttrName = new iloTableNode(ATTRNAME_NODE, $1, NULL, pAttrType);
              $$ = new iloTableNode(ATTR_NODE, NULL, pAttrName, NULL);
              $$->setSkipFlag($3 & SKIP_MASK);
#ifdef _ILOADER_DEBUG
              idlOS::printf("xx bigint\n");
#endif
          }
          else if ( idlOS::strcasecmp($2, "INTEGER") == 0 )
          {
              pAttrType = new iloTableNode(ATTRTYPE_NODE, (SChar *)"integer", NULL, NULL);
              pAttrName = new iloTableNode(ATTRNAME_NODE, $1, NULL, pAttrType);
              $$ = new iloTableNode(ATTR_NODE, NULL, pAttrName, NULL);
              $$->setSkipFlag($3 & SKIP_MASK);
#ifdef _ILOADER_DEBUG
              idlOS::printf("xx integer\n");
#endif
          }
          else if ( idlOS::strcasecmp($2, "BOOLEAN") == 0 )
          {
              pAttrType = new iloTableNode(ATTRTYPE_NODE, (SChar *)"boolean", NULL, NULL);
              pAttrName = new iloTableNode(ATTRNAME_NODE, $1, NULL, pAttrType);
              $$ = new iloTableNode(ATTR_NODE, NULL, pAttrName, NULL);
              $$->setSkipFlag($3 & SKIP_MASK);
#ifdef _ILOADER_DEBUG
              idlOS::printf("xx boolean\n");
#endif
          }
          else if ( idlOS::strcasecmp($2, "BLOB") == 0 )
          {
              pAttrType = new iloTableNode(ATTRTYPE_NODE, (SChar *)"blob", NULL, NULL);
              pAttrName = new iloTableNode(ATTRNAME_NODE, $1, NULL, pAttrType);
              $$ = new iloTableNode(ATTR_NODE, NULL, pAttrName, NULL);
              $$->setSkipFlag($3 & SKIP_MASK);
#ifdef _ILOADER_DEBUG
              idlOS::printf("xx blob\n");
#endif
          }
          else if ( idlOS::strcasecmp($2, "REAL") == 0 )
          {
              pAttrType = new iloTableNode(ATTRTYPE_NODE, (SChar *)"real", NULL, NULL);
              pAttrName = new iloTableNode(ATTRNAME_NODE, $1, NULL, pAttrType);
              $$ = new iloTableNode(ATTR_NODE, NULL, pAttrName, NULL);
              $$->setSkipFlag($3 & SKIP_MASK);
#ifdef _ILOADER_DEBUG
              idlOS::printf("xx real\n");
#endif
          }
          else if ( idlOS::strcasecmp($2, "FLOAT") == 0 )
          {
              pAttrType = new iloTableNode(ATTRTYPE_NODE, (SChar *)"float", NULL, NULL);
              pAttrName = new iloTableNode(ATTRNAME_NODE, $1, NULL, pAttrType);
              $$ = new iloTableNode(ATTR_NODE, NULL, pAttrName, NULL);
              $$->setSkipFlag($3 & SKIP_MASK);
              $$->setNoExpFlag($3 & NOEXP_MASK);
#ifdef _ILOADER_DEBUG
              idlOS::printf("xx float\n");
#endif
          }
          else if ( idlOS::strcasecmp($2, "NUMERIC") == 0 ||
                    idlOS::strcasecmp($2, "NUMBER") == 0 ||
                    idlOS::strcasecmp($2, "DECIMAL") == 0 )
          {
              pAttrType = new iloTableNode(ATTRTYPE_NODE, (SChar *)"numeric_long", NULL, NULL);
              pAttrName = new iloTableNode(ATTRNAME_NODE, $1, NULL, pAttrType);
              $$ = new iloTableNode(ATTR_NODE, NULL, pAttrName, NULL);
              $$->setSkipFlag($3 & SKIP_MASK);
              $$->setNoExpFlag($3 & NOEXP_MASK);
#ifdef _ILOADER_DEBUG
              idlOS::printf("xx numeric\n");
#endif
          }
          else if ( idlOS::strcasecmp($2, "DATE") == 0 )
          {
              gDateForm[0] = '\0';
              pAttrType = new iloTableNode(ATTRTYPE_NODE, (SChar *)"date", NULL, NULL);
              pAttrName = new iloTableNode(ATTRNAME_NODE, $1, NULL, pAttrType);
              $$ = new iloTableNode(ATTR_NODE, NULL, pAttrName, NULL);
              $$->setSkipFlag($3 & SKIP_MASK);
#ifdef _ILOADER_DEBUG
              idlOS::printf("xx date\n");
#endif
          }
          else if ( idlOS::strcasecmp($2, "TIMESTAMP") == 0 )
          {
              pAttrType = new iloTableNode(ATTRTYPE_NODE, (SChar *)"timestamp", NULL, NULL);
              pAttrName = new iloTableNode(ATTRNAME_NODE, $1, NULL, pAttrType);
              $$ = new iloTableNode(ATTR_NODE, NULL, pAttrName, NULL);
              $$->setSkipFlag($3 & SKIP_MASK);
              $$->setPrecision(8, 0);
              gTimestampType = ILO_TIMESTAMP_DAT;
              gAddFlag = ID_FALSE;
#ifdef _ILOADER_DEBUG
              idlOS::printf("xx timestamp 1\n");
#endif
          }
          else
          {
              idlOS::printf("Type [%s] is not supported.\n", $2);
              YYABORT;
          }
      }                  

    | column_name T_IDENTIFIER T_SKIP T_TIMESTAMP_DEFAULT T_SEMICOLON
      {
          if ( idlOS::strcasecmp($2, "TIMESTAMP") == 0 )
          {
              iloTableNode *pAttrName, *pAttrType;

              pAttrType = new iloTableNode(ATTRTYPE_NODE, (SChar *)"timestamp", NULL, NULL);
              pAttrName = new iloTableNode(ATTRNAME_NODE, $1, NULL, pAttrType);
              $$ = new iloTableNode(ATTR_NODE, NULL, pAttrName, NULL);
              $$->setSkipFlag(1);
              $$->setPrecision(8, 0);
              gTimestampType = ILO_TIMESTAMP_DEFAULT;
              gAddFlag = ID_FALSE;
#ifdef _ILOADER_DEBUG
              idlOS::printf("xx timestamp 2\n");
#endif
          }
          else
          {
              idlOS::printf("Type [%s] SKIP DEFAULT is not supported.\n", $2);
              YYABORT;
          }
      }                  
    | column_name T_IDENTIFIER T_SKIP T_TIMESTAMP_NULL T_SEMICOLON
      {
          if ( idlOS::strcasecmp($2, "TIMESTAMP") == 0 )
          {
              iloTableNode *pAttrName, *pAttrType;

              pAttrType = new iloTableNode(ATTRTYPE_NODE, (SChar *)"timestamp", NULL, NULL);
              pAttrName = new iloTableNode(ATTRNAME_NODE, $1, NULL, pAttrType);
              $$ = new iloTableNode(ATTR_NODE, NULL, pAttrName, NULL);
              $$->setSkipFlag(1);
              $$->setPrecision(8, 0);
              gTimestampType = ILO_TIMESTAMP_NULL;
              gAddFlag = ID_FALSE;
#ifdef _ILOADER_DEBUG
              idlOS::printf("xx timestamp 3\n");
#endif
          }
          else
          {
              idlOS::printf("Type [%s] SKIP NULL is not supported.\n", $2);
              YYABORT;
          }
      }                  
    | column_name T_IDENTIFIER T_SKIP T_TIMESTAMP_VALUE T_SEMICOLON
      {
          if ( idlOS::strcasecmp($2, "TIMESTAMP") == 0 )
          {
              iloTableNode *pAttrName, *pAttrType;

              pAttrType = new iloTableNode(ATTRTYPE_NODE, (SChar *)"timestamp", NULL, NULL);
              pAttrName = new iloTableNode(ATTRNAME_NODE, $1, NULL, pAttrType);
              $$ = new iloTableNode(ATTR_NODE, NULL, pAttrName, NULL);
              $$->setSkipFlag(1);
              $$->setPrecision(8, 0);
              gTimestampType = ILO_TIMESTAMP_VALUE;
              idlOS::strcpy(gTimestampVal, $4);
              gAddFlag = ID_FALSE;
#ifdef _ILOADER_DEBUG
              idlOS::printf("xx timestamp 4\n");
#endif
          }
          else
          {
              idlOS::printf("Type [%s] SKIP %s is not supported.\n", $2, $4);
              YYABORT;
          }
      }                  
    | column_name T_IDENTIFIER T_ADD T_TIMESTAMP_DEFAULT T_SEMICOLON
      {
          if ( idlOS::strcasecmp($2, "TIMESTAMP") == 0 )
          {
              iloTableNode *pAttrName, *pAttrType;

              pAttrType = new iloTableNode(ATTRTYPE_NODE, (SChar *)"timestamp", NULL, NULL);
              pAttrName = new iloTableNode(ATTRNAME_NODE, $1, NULL, pAttrType);
              $$ = new iloTableNode(ATTR_NODE, NULL, pAttrName, NULL);
              $$->setPrecision(8, 0);
              gTimestampType = ILO_TIMESTAMP_DEFAULT;
              gAddFlag = ID_TRUE;
#ifdef _ILOADER_DEBUG
              idlOS::printf("xx timestamp 2\n");
#endif
          }
          else
          {
              idlOS::printf("Type [%s] ADD DEFAULT is not supported.\n", $2);
              YYABORT;
          }
      }                  
    | column_name T_IDENTIFIER T_ADD T_TIMESTAMP_NULL T_SEMICOLON
      {
          if ( idlOS::strcasecmp($2, "TIMESTAMP") == 0 )
          {
              iloTableNode *pAttrName, *pAttrType;

              pAttrType = new iloTableNode(ATTRTYPE_NODE, (SChar *)"timestamp", NULL, NULL);
              pAttrName = new iloTableNode(ATTRNAME_NODE, $1, NULL, pAttrType);
              $$ = new iloTableNode(ATTR_NODE, NULL, pAttrName, NULL);
              $$->setPrecision(8, 0);
              gTimestampType = ILO_TIMESTAMP_NULL;
              gAddFlag = ID_TRUE;
#ifdef _ILOADER_DEBUG
              idlOS::printf("xx timestamp 3\n");
#endif
          }
          else
          {
              idlOS::printf("Type [%s] ADD NULL is not supported.\n", $2);
              YYABORT;
          }
      }                  
    | column_name T_IDENTIFIER T_ADD T_TIMESTAMP_VALUE T_SEMICOLON
      {
          if ( idlOS::strcasecmp($2, "TIMESTAMP") == 0 )
          {
              iloTableNode *pAttrName, *pAttrType;

              pAttrType = new iloTableNode(ATTRTYPE_NODE, (SChar *)"timestamp", NULL, NULL);
              pAttrName = new iloTableNode(ATTRNAME_NODE, $1, NULL, pAttrType);
              $$ = new iloTableNode(ATTR_NODE, NULL, pAttrName, NULL);
              $$->setPrecision(8, 0);
              gTimestampType = ILO_TIMESTAMP_VALUE;
              idlOS::strcpy(gTimestampVal, $4);
              gAddFlag = ID_TRUE;
#ifdef _ILOADER_DEBUG
              idlOS::printf("xx timestamp 4\n");
#endif
          }
          else
          {
              idlOS::printf("Type [%s] ADD %s is not supported.\n", $2, $4);
              YYABORT;
          }
      }                  

    | column_name T_IDENTIFIER T_LBRACKET T_NUMBER T_COMMA T_ZERO T_RBRACKET SKIPNOEXP_DEF T_SEMICOLON
      {
          if ( idlOS::strcasecmp($2, "NUMERIC") == 0 ||
               idlOS::strcasecmp($2, "NUMBER") == 0 )
          {
              iloTableNode *pAttrName, *pAttrType;

              pAttrType = new iloTableNode(ATTRTYPE_NODE, (SChar *)"numeric_long", NULL, NULL);
              pAttrName = new iloTableNode(ATTRNAME_NODE, $1, NULL, pAttrType);
              $$ = new iloTableNode(ATTR_NODE, NULL, pAttrName, NULL);
              $$->setSkipFlag($8 & SKIP_MASK);
              $$->setNoExpFlag($8 & NOEXP_MASK);
#ifdef _ILOADER_DEBUG
              idlOS::printf("xx numeric(n, 0)\n");
#endif
          }
          else
          {
              idlOS::printf("Type [%s(n, 0)] is not supported.\n", $2);
              YYABORT;
          }
      }

    | column_name T_IDENTIFIER T_LBRACKET T_NUMBER T_COMMA T_NUMBER T_RBRACKET SKIPNOEXP_DEF T_SEMICOLON
      {
          iloTableNode *pAttrName, *pAttrType;

          if ( idlOS::strcasecmp($2, "NUMERIC") == 0 ||
               idlOS::strcasecmp($2, "NUMBER") == 0 )
          {
              pAttrType = new iloTableNode(ATTRTYPE_NODE, (SChar *)"numeric_double", NULL, NULL);
              pAttrName = new iloTableNode(ATTRNAME_NODE, $1, NULL, pAttrType);
              $$ = new iloTableNode(ATTR_NODE, NULL, pAttrName, NULL);
              $$->setSkipFlag($8 & SKIP_MASK);
              $$->setNoExpFlag($8 & NOEXP_MASK);
#ifdef _ILOADER_DEBUG
              idlOS::printf("xx numeric(n, m)\n");
#endif
          }
          else
          {
              idlOS::printf("Type [%s(n, m)] is not supported.\n", $2);
              YYABORT;
          }
      }
    ;

user_object_name
    : T_IDENTIFIER
      {
          $$ = $1;
      }
    | T_IDENTIFIER T_PERIOD T_IDENTIFIER
      {
          idlOS::sprintf(gTmpBuf, "%s.%s", $1, $3);    
//printf("TableOwnerName [%s]\n",gTmpBuf);
          $$ = gTmpBuf;
      }
    ;

column_name
    : T_IDENTIFIER
      {
          $$ = $1;
      }
    /* BUG-12091 */
    | T_CONDITION
      {
          $$ = $1;
      }
    ;

SKIP_DEF
    : /* empty */
      {
          $$ = 0;
      }
    | T_SKIP
      {
          $$ = 1;
      }
    ;

SKIPNOEXP_DEF
    : /* empty */
      {
          $$ = 0;
      }
    | T_SKIP
      {
          $$ = SKIP_MASK;
      }
    | T_NOEXP
      {
          $$ = NOEXP_MASK;
      }
    | T_SKIP T_NOEXP
      {
          $$ = SKIP_MASK | NOEXP_MASK;
      }
    | T_NOEXP T_SKIP
      {
          $$ = SKIP_MASK | NOEXP_MASK;
      }
    ;

%%

