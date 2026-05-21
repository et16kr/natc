/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iloDef.h 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/
 
#ifndef _O_ILO_DEF_H
#define _O_ILO_DEF_H

#define ENVIRON_FILE       "iloader.ini"

#define MAX_TABLENAME_LEN  50
#define MAX_FILEPATH_LEN   150
#define MAX_WORD_LEN       128
#define MAX_ATTR_COUNT     1024
#define MAX_VALUE_LEN      10000

#define INT_NULL           -2147483648
#define MSG_LEN            1024
#define STR_LEN            128+1
#define REM_LEN            256+1

#define MAX_VARCHAR_SIZE   32*1024 // BUGBUG : TODO ..(SMC_PERS_PAGE_BODY_SIZE - sizeof(smcVarPageHeader) - sizeof(smVarColumn))
#define MAX_INDEX_COUNT   100

#define UT_MAX_SEQ_ARRAY_CNT (8)
#define UT_MAX_SEQ_NAME_LEN  (50)
#define UT_MAX_SEQ_COL_LEN   (50)
#define UT_MAX_SEQ_VAL_LEN   (8)

#define MAX_PASS_LEN 40

typedef SInt isql_bool;

#define isql_true 1
#define isql_false 0

enum ETableNodeType
{
    TABLE_NODE,
    DOWN_NODE,
    SEQ_NODE,
    TABLENAME_NODE,
    ATTR_NODE,
    ATTRNAME_NODE,
    ATTRTYPE_NODE
};

enum EispAttrType
{ 
    ISP_ATTR_NONE, 
    ISP_ATTR_INTEGER,
    
    ISP_ATTR_DOUBLE,
    ISP_ATTR_SMALLINT,
    ISP_ATTR_BIGINT,
    ISP_ATTR_DECIMAL,
    ISP_ATTR_FLOAT,
    ISP_ATTR_REAL,
    ISP_ATTR_INTEVAL,
    ISP_ATTR_BOOLEAN,
    ISP_ATTR_BLOB,
    
    ISP_ATTR_NIBBLE,
    ISP_ATTR_BYTES,
    ISP_ATTR_CHAR,
    ISP_ATTR_VARCHAR,
    ISP_ATTR_BIT,
    ISP_ATTR_NUMERIC_LONG,
    ISP_ATTR_NUMERIC_DOUBLE,
    ISP_ATTR_DATE,
    ISP_ATTR_TIMESTAMP
};

enum ECommandType
{
    NON_COM,
    DATA_IN,
    DATA_OUT,
    STRUCT_OUT,
    FORM_OUT,
    EXIT_COM,
    HELP_COM,
    HELP_HELP
};

enum ELoadMode
{
    APPEND,
    REPLACE
};

enum EDataToken
{
    TEOF,
    TFIELD_TERM,
    TROW_TERM,
    TVALUE
};

enum TimestampType
{
    ILO_TIMESTAMP_DAT,
    ILO_TIMESTAMP_DEFAULT,
    ILO_TIMESTAMP_NULL,
    ILO_TIMESTAMP_VALUE
};

struct SIndexInfo
{
    SChar     m_IndexName[50];
    SChar     m_ColumnName[50];
    isql_bool m_bSortAsc;
    SShort    m_OrdinalPos;    // 1, 2, 3, ...
    isql_bool m_bNonUnique;
};
    
union BinaryValue       
{
    SChar     B_Val[MAX_VARCHAR_SIZE*2+1];
};

union ColumnValue       
{
    SChar     C_Col[MAX_VARCHAR_SIZE];
    union BinaryValue    *B_Col;
};

typedef struct seqInfo
{
    char seqName[UT_MAX_SEQ_NAME_LEN];
    char seqCol[UT_MAX_SEQ_COL_LEN];
    char seqVal[UT_MAX_SEQ_VAL_LEN];
} seqInfo;

void gSetInputStr( SChar *s );

SInt yyparse(void*);

void InsertSeq(SChar *sName, SChar *cName, SChar *val);

SInt iloCommandParserparse(void*);

#endif /* _O_ILO_DEF_H */
