/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iloTableInfo.h 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/
 
#ifndef _O_ILO_TABLEINFO_H
#define _O_ILO_TABLEINFO_H

#define UT_MAX_SEQ_ARRAY_CNT (8)
#define UT_MAX_SEQ_NAME_LEN  (50)
#define UT_MAX_SEQ_COL_LEN   (50)
#define UT_MAX_SEQ_VAL_LEN   (8)

class iloTableNode
{
public:
    iloTableNode();

    iloTableNode(ETableNodeType eNodeType,
                 SChar         *szNodeValue,
                 iloTableNode  *pSon,
                 iloTableNode  *pBrother);

    ~iloTableNode();
        
    ETableNodeType GetNodeType()             { return m_NodeType; }

    SChar *GetNodeValue()                    { return m_NodeValue; }

    iloTableNode *GetSon()                   { return m_pSon; }

    iloTableNode *GetBrother()               { return m_pBrother; }

    void SetSon(iloTableNode *pSon)          { m_pSon = pSon; }

    void SetBrother(iloTableNode *pBrother)  { m_pBrother = pBrother; }

    void setSkipFlag( SInt aSkipFlag );
    void setNoExpFlag( SInt aNoExpFlag );
    void setPrecision( SInt aPrecision, SInt aScale );

    isql_bool PrintNode(SInt nDepth);
    
    
private:
    ETableNodeType  m_NodeType;
    SChar          *m_NodeValue; 
    iloTableNode   *m_pSon;
    iloTableNode   *m_pBrother;   

public:
    SChar           mSkipFlag;
    SInt            mPrecision;
    SInt            mScale;
    SChar           mNoExpFlag;
};

class iloTableTree
{
public:
    iloTableTree()                     { m_Root = NULL; }

    iloTableTree(iloTableNode *pRoot)  { m_Root = pRoot; }

    ~iloTableTree()                    { delete m_Root; }
    
    isql_bool SetTreeRoot(iloTableNode *pRoot);

    iloTableNode *GetTreeRoot()        { return m_Root; }

    isql_bool PrintTree();

private:
    iloTableNode *m_Root;
};

class iloTableInfo
{
public:
    iloTableInfo()                     { m_AttrValue = NULL; }

    struct SeqInfo
    {
        SChar seqName[UT_MAX_SEQ_NAME_LEN];
        SChar seqCol[UT_MAX_SEQ_COL_LEN];
        SChar seqVal[UT_MAX_SEQ_VAL_LEN];
    } localSeqArray[UT_MAX_SEQ_ARRAY_CNT];

    isql_bool GetTableInfo(iloTableNode *pTableNameNode);
    // TABLE_NODE에 대한 포인터를 입력으로 받아 테이블에 대한 정보를 얻는다.
    // 이때 형제 테이블 노드가 있는지는 검색하지 않는다.
    isql_bool ExistDownCond()            { return m_bDownCond; }

    SChar *GetQueryString()              { return m_QueryString; }

    SChar *GetTableName()                { return m_TableName; }

    SInt  GetAttrCount()                 { return m_AttrCount; }

    SInt  GetReadCount(SInt aIdx)        { return m_ReadCount[aIdx]; }

    void SetReadCount(SInt nReadCount, SInt aIdx)
                                         { m_ReadCount[aIdx] = nReadCount; }
    
    void CopyStruct();

    SChar *GetAttrName(SInt nAttr);

    EispAttrType GetAttrType(SInt nAttr);

    union ColumnValue *GetAttrValue(SInt nAttr, SInt aArrayCnt = 0);

    isql_bool SetAttrValue(SInt nAttr, SLong lAttrValue);

    isql_bool SetAttrValue(SInt nAttr, SInt lAttrValue);

    isql_bool SetAttrValue(SInt nAttr, SDouble dAttrValue);

    isql_bool SetAttrValue(SInt nAttr, SChar *szAttrValue, SInt aArrayCount);

    isql_bool SetAttrLen(SInt nAttr, SInt len, SInt aArrayCount);

    isql_bool PrintTableInfo();

    SInt seqEqualChk(SInt index);

    isql_bool seqColChk();

    isql_bool seqDupChk();
    
    SInt seqCount ();

    isql_bool AllocTableAttr(SInt sArrayCount);
    isql_bool FreeTableAttr();
    void      FreeDateFormat();

private:
    SChar             m_TableName[MAX_TABLENAME_LEN];

    isql_bool         m_bDownCond;
    SChar             m_QueryString[MAX_WORD_LEN*3];

    SInt              m_AttrCount;
    SInt             *m_ReadCount;
    SChar             m_AttrName[MAX_ATTR_COUNT][MAX_WORD_LEN];
    EispAttrType      m_AttrType[MAX_ATTR_COUNT];
public:
    //union ColumnValue m_AttrValue[MAX_ATTR_COUNT];
    union ColumnValue **m_AttrValue;
    //SInt              m_AttrLen[MAX_ATTR_COUNT];    
    SInt              **m_AttrLen;    
    SQLUSMALLINT       *mStatusPtr;
    SChar               mSkipFlag[MAX_ATTR_COUNT];
    SChar               mNoExpFlag[MAX_ATTR_COUNT];
    SInt                mPrecision[MAX_ATTR_COUNT];
    SInt                mScale[MAX_ATTR_COUNT];
    SChar              *mAttrDateFormat[MAX_ATTR_COUNT];
};

inline isql_bool iloTableInfo::SetAttrLen(SInt nAttr, SInt len, SInt aArrayCount )
{
    if ((nAttr >= 0) && (nAttr <m_AttrCount))
    {
        m_AttrLen[nAttr][aArrayCount] = len;
        return isql_true;
    }
    else
        return isql_false;
}

inline isql_bool iloTableInfo::SetAttrValue(SInt nAttr, SChar *szAttrValue, SInt aArrayCount ) 
{
    if ((nAttr >= 0) && (nAttr <m_AttrCount))
    {
        if ( m_AttrType[nAttr] == ISP_ATTR_NIBBLE ||
             m_AttrType[nAttr] == ISP_ATTR_BYTES ||
             m_AttrType[nAttr] == ISP_ATTR_TIMESTAMP ||
             m_AttrType[nAttr] == ISP_ATTR_BLOB )
        {
            idlOS::strcpy((SChar*)(m_AttrValue[nAttr][0].B_Col[aArrayCount].B_Val),
                          szAttrValue);
        }
        else
        {
            idlOS::strcpy(m_AttrValue[nAttr][aArrayCount].C_Col, szAttrValue);
        }
        return isql_true;
    }
    else
        return isql_false;
}

#endif /* _O_ILO_TABLEINFO_H */
