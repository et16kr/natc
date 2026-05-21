/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iloTableInfo.cpp 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/
 
#include <ilo.h>

SInt    gSeqIndex ;
seqInfo gSeqArray[UT_MAX_SEQ_ARRAY_CNT];

void InsertSeq(SChar *sName, SChar *cName, SChar *val)
{
    //구조체에 넣어준다.
    if (gSeqIndex > UT_MAX_SEQ_ARRAY_CNT)
    {
        idlOS::printf("Too Many Sequence !! LIMIT %d\n", UT_MAX_SEQ_ARRAY_CNT);
        gSeqIndex = 0;
    }
    idlOS::strcpy(gSeqArray[gSeqIndex].seqName, sName);
    idlOS::strcpy(gSeqArray[gSeqIndex].seqCol, cName);
    idlOS::strcpy(gSeqArray[gSeqIndex].seqVal, val);
    
    gSeqIndex++;
}

iloTableNode::iloTableNode()
{
    m_NodeValue = NULL;
    m_pSon = NULL;
    m_pSon = NULL;
    mSkipFlag = 0;
    mNoExpFlag = 0;
    mPrecision = 0;
    mScale = 0;
}

iloTableNode::iloTableNode(ETableNodeType eNodeType, SChar *szNodeValue, iloTableNode *pSon, iloTableNode *pBrother)
{
    m_NodeType = eNodeType;
    if (szNodeValue == NULL)
    {
        m_NodeValue = NULL;
    }
    else
    {
        m_NodeValue = new SChar [idlOS::strlen(szNodeValue) + 1];
        idlOS::strcpy(m_NodeValue, szNodeValue);
    }
    m_pSon = pSon;
    m_pBrother = pBrother;
    mSkipFlag = 0;
    mNoExpFlag = 0;
}

iloTableNode::~iloTableNode()
{
    if (this != NULL)
    {
        if ( m_pSon != NULL )
        {
            delete m_pSon;
            m_pSon = NULL;
        }
        if ( m_pBrother != NULL )
        {
               delete m_pBrother;
            m_pBrother = NULL;
        }
        if ( m_NodeValue != NULL )
        {
            delete [] m_NodeValue;
            m_NodeValue = NULL;
        }
    }
}

void iloTableNode::setSkipFlag( SInt aSkipFlag )
{
    mSkipFlag = (SChar) aSkipFlag;
}

void iloTableNode::setNoExpFlag( SInt aNoExpFlag ) 
{ 
    if ( aNoExpFlag == 0 ) 
    { 
        mNoExpFlag = (SChar) 0; 
    } 
    else 
    { 
        mNoExpFlag = (SChar) 1; 
    } 
} 

void iloTableNode::setPrecision( SInt aPrecision, SInt aScale )
{
    mPrecision = aPrecision;
    mScale = aScale;
}

/* Called with nDepth = 0 in First */
isql_bool iloTableNode::PrintNode(SInt nDepth)
{
    SInt i;

    if (nDepth > 0)
    {
        for (i=nDepth ; i > 0; i--)
            idlOS::printf("     ");
        idlOS::printf("|--");
    }

    switch (m_NodeType)
    {
    case TABLE_NODE :
        idlOS::printf("TABLE\n");
        break;
    case DOWN_NODE :
        idlOS::printf("Download condition [%s]\n", m_NodeValue);
        break;
    case TABLENAME_NODE :
        idlOS::printf("Table Name [%s]\n", m_NodeValue);
        break;
    case ATTR_NODE :
        idlOS::printf("Attribute\n");
        break;
    case SEQ_NODE :
        idlOS::printf("Attr Name [%s]\n", m_NodeValue);
        break;
    case ATTRNAME_NODE :
        idlOS::printf("Attr Name [%s]\n", m_NodeValue);
        break;
    case ATTRTYPE_NODE :
        idlOS::printf("Attr Type [%s]\n", m_NodeValue);
        break;
    }

    if (m_pSon != NULL)
    {
        m_pSon->PrintNode(nDepth + 1);
    }
    if (m_pBrother != NULL)
    {
        m_pBrother->PrintNode(nDepth);
    }
    
    return isql_true;
}

isql_bool iloTableTree::SetTreeRoot(iloTableNode *pRoot)
{
    if (m_Root != NULL)
    {
        delete m_Root;
    }
    m_Root = pRoot;

    return isql_true;
}

isql_bool iloTableTree::PrintTree()
{
    if (m_Root == NULL)
    {
        return isql_true;
    }
    else
    {
        return m_Root->PrintNode(0);
    }
}

isql_bool iloTableInfo::GetTableInfo(iloTableNode *pTableNameNode)
{
    iloTableNode *pNode;
    SChar         szTmp[100];
    SChar        *sDateFormat;
    SInt          sLength;

    pNode = pTableNameNode->GetSon();

    // 최상위 pTableNameNode의 Son 은 TABLE_DEF, DOWN_COND_DEF 의 조합
    if (pNode->GetNodeType() == DOWN_NODE)
    {
        m_bDownCond = isql_true;
        idlOS::strcpy(m_QueryString, pNode->GetNodeValue());
        pNode = pNode->GetBrother();
    }
    else
    {
        m_bDownCond = isql_false;
    }

    // pNode->GetNodeValue() 는 TABLE_DEF
    idlOS::strcpy(m_TableName, pNode->GetNodeValue());

    pNode = pNode->GetSon();

    for (m_AttrCount = 0; pNode != NULL; m_AttrCount++)
    {
        if (m_AttrCount >= MAX_ATTR_COUNT)
        {
            idlOS::printf("This Program can process to %d attribute\n", MAX_ATTR_COUNT);
            return isql_false;
        }

        idlOS::strcpy(m_AttrName[m_AttrCount], pNode->GetSon()->GetNodeValue());
        mSkipFlag[m_AttrCount] = pNode->mSkipFlag;
        mNoExpFlag[m_AttrCount] = pNode->mNoExpFlag;
        mPrecision[m_AttrCount] = pNode->mPrecision;
        mScale[m_AttrCount] = pNode->mScale;
        if ( (sDateFormat = pNode->GetNodeValue()) != NULL )
        {
            sLength = idlOS::strlen(sDateFormat);
            mAttrDateFormat[m_AttrCount] = (SChar*) idlOS::malloc(sLength + 1);
            idlOS::strncpy( mAttrDateFormat[m_AttrCount], sDateFormat, sLength );
            mAttrDateFormat[m_AttrCount][sLength] = '\0';
        }
        else
        {
            mAttrDateFormat[m_AttrCount] = NULL;
        }
        
        idlOS::strcpy(szTmp, pNode->GetSon()->GetBrother()->GetNodeValue());
        if (strcmp(szTmp, "char") == 0)
        {
            m_AttrType[m_AttrCount] = ISP_ATTR_CHAR;
        }
        else if (strcmp(szTmp, "varchar") == 0)
        {
            m_AttrType[m_AttrCount] = ISP_ATTR_VARCHAR;
        }
        else if (strcmp(szTmp, "integer") == 0)
        {
            m_AttrType[m_AttrCount] = ISP_ATTR_INTEGER;
        }
        else if (strcmp(szTmp, "double") == 0 )
        {
            m_AttrType[m_AttrCount] = ISP_ATTR_DOUBLE;
        }
        else if (strcmp(szTmp, "smallint") == 0 )
        {
            m_AttrType[m_AttrCount] = ISP_ATTR_SMALLINT; 
        }
        else if (strcmp(szTmp, "bigint") == 0 )
        {
            m_AttrType[m_AttrCount] = ISP_ATTR_BIGINT;
        }
        else if (strcmp(szTmp, "decimal") == 0 )
        {
            m_AttrType[m_AttrCount] = ISP_ATTR_DECIMAL;
        }
        else if (strcmp(szTmp, "float") == 0 )
        {
            m_AttrType[m_AttrCount] = ISP_ATTR_FLOAT;
        }
        else if (strcmp(szTmp, "real") == 0 )
        {
            m_AttrType[m_AttrCount] = ISP_ATTR_REAL;
        }
        else if (strcmp(szTmp, "inteval") == 0 )
        {
            m_AttrType[m_AttrCount] = ISP_ATTR_INTEVAL;
        }
        else if (strcmp(szTmp, "boolean") == 0 )
        {
            m_AttrType[m_AttrCount] = ISP_ATTR_BOOLEAN;
        }
        else if (strcmp(szTmp, "blob") == 0 )
        {
            m_AttrType[m_AttrCount] = ISP_ATTR_BLOB;
        }
        else if (strcmp(szTmp, "nibble") == 0)
        {
            m_AttrType[m_AttrCount] = ISP_ATTR_NIBBLE;
        }
        else if (strcmp(szTmp, "bytes") == 0)
        {
            m_AttrType[m_AttrCount] = ISP_ATTR_BYTES;        
        }
        else if (strcmp(szTmp, "timestamp") == 0)
        {
            m_AttrType[m_AttrCount] = ISP_ATTR_TIMESTAMP;        
        }
        else if (strcmp(szTmp, "bit") == 0)
        {
            m_AttrType[m_AttrCount] = ISP_ATTR_BIT;
        }
        else if (strcmp(szTmp, "numeric_long") == 0)
        {
            m_AttrType[m_AttrCount] = ISP_ATTR_NUMERIC_LONG;
        }
        else if (strcmp(szTmp, "numeric_double") == 0)
        {
            m_AttrType[m_AttrCount] = ISP_ATTR_NUMERIC_DOUBLE;
        }
        else if (strcmp(szTmp, "date") == 0)
        {
            m_AttrType[m_AttrCount] = ISP_ATTR_DATE;
        }
        else if (strcmp(szTmp, "nextval") == 0)
        {
            m_AttrType[m_AttrCount] = ISP_ATTR_DATE;
        }
        else if (strcmp(szTmp, "currval") == 0)
        {
            m_AttrType[m_AttrCount] = ISP_ATTR_DATE;
        }
        else
        {
            idlOS::printf("This [%s] is not used in ALTIBASE\n", szTmp);
            return isql_false;
        }

        pNode = pNode->GetBrother();
    }

    return isql_true;
}

isql_bool iloTableInfo::AllocTableAttr(SInt sArrayCount)
{
    SInt i;

    m_ReadCount = ( SInt* ) idlOS::malloc( 
                  sizeof(SInt) * sArrayCount);
    IDE_TEST_RAISE( m_ReadCount == NULL, malloc_error );

    mStatusPtr = ( SQLUSMALLINT* ) idlOS::malloc( 
                  sizeof(SQLUSMALLINT) * sArrayCount);
    IDE_TEST_RAISE( mStatusPtr == NULL, malloc_error );

    m_AttrValue = ( union ColumnValue** ) idlOS::malloc( 
                  sizeof(union ColumnValue*) * m_AttrCount);
    IDE_TEST_RAISE( m_AttrValue == NULL, malloc_error );

    m_AttrLen = (SQLINTEGER**)idlOS::malloc( sizeof(SQLINTEGER*) * m_AttrCount);
    IDE_TEST_RAISE( m_AttrLen == NULL, malloc_error );

    for( i = 0; i < m_AttrCount ; i++ )
    {
        m_AttrValue[i] = ( union ColumnValue* ) idlOS::malloc(
                         sizeof(union ColumnValue) * sArrayCount); 
        IDE_TEST_RAISE( m_AttrValue[i] == NULL, malloc_error );

        if ( m_AttrType[i] == ISP_ATTR_NIBBLE ||
             m_AttrType[i] == ISP_ATTR_BYTES ||
             m_AttrType[i] == ISP_ATTR_TIMESTAMP ||
             m_AttrType[i] == ISP_ATTR_BLOB )
        {
            m_AttrValue[i][0].B_Col = ( union BinaryValue* ) idlOS::malloc(
                              sizeof(union BinaryValue) * sArrayCount);
            IDE_TEST_RAISE( m_AttrValue[i][0].B_Col == NULL, malloc_error );
        }

        m_AttrLen[i] = (SQLINTEGER*)idlOS::malloc(sizeof(SQLINTEGER) * sArrayCount);
        IDE_TEST_RAISE( m_AttrLen[i] == NULL, malloc_error );
    }

    return isql_true;

    IDE_EXCEPTION( malloc_error );
    {
        idlOS::printf("memory malloc error, sArrayCount=%d\n", sArrayCount);
    }
    IDE_EXCEPTION_END;

    return isql_false;
}

SChar *iloTableInfo::GetAttrName(SInt nAttr)
{
    if ((nAttr >= 0) && (nAttr <m_AttrCount))
    {
        return m_AttrName[nAttr];
    }
    else
    {
        return NULL;
    }
}

void iloTableInfo::CopyStruct()
{
    SInt i;
    
    for(i = 0; i < gSeqIndex; i++)
    {
        idlOS::strcpy(localSeqArray[i].seqName, gSeqArray[i].seqName);
        idlOS::strcpy(localSeqArray[i].seqCol, gSeqArray[i].seqCol);
        idlOS::strcpy(localSeqArray[i].seqVal, gSeqArray[i].seqVal);
     }
}

EispAttrType iloTableInfo::GetAttrType(SInt nAttr)
{
    if ((nAttr >= 0) && (nAttr <m_AttrCount))
    {
        return m_AttrType[nAttr];
    }
    else
    {
        return ISP_ATTR_NONE;
    }
}

union ColumnValue *iloTableInfo::GetAttrValue(SInt nAttr, SInt aArrayCnt)
{
    if ((nAttr >= 0) && (nAttr < m_AttrCount))
    {
        return &(m_AttrValue[nAttr][aArrayCnt]);
    }
    else
    {
        return NULL;
    }
}

isql_bool iloTableInfo::PrintTableInfo()
{
    SInt i;

    idlOS::printf("Table [%s]\n", m_TableName);

    if (m_bDownCond)
    {
        idlOS::printf("Download Condition [%s]\n", m_QueryString);
    }

    for (i = 0; i < m_AttrCount; i++)
    {
        idlOS::printf("%s ", m_AttrName[i]);
        switch (m_AttrType[i])
        {
        case ISP_ATTR_INTEGER :
            idlOS::printf("(integer) ");
            break;
        case ISP_ATTR_NIBBLE :
            idlOS::printf("(nibble) ");
            break;
        case ISP_ATTR_BYTES :
            idlOS::printf("(bytes) ");
            break;
        case ISP_ATTR_TIMESTAMP :
            idlOS::printf("(timestamp) ");
            break;
        case ISP_ATTR_CHAR :
            idlOS::printf("(char) ");
            break;
        case ISP_ATTR_VARCHAR :
            idlOS::printf("(varchar) ");
            break;
        case ISP_ATTR_BIT :
            idlOS::printf("(bit) ");
            break;
        case ISP_ATTR_NUMERIC_LONG :
            idlOS::printf("(numeric long) ");
            break;
        case ISP_ATTR_NUMERIC_DOUBLE :
            idlOS::printf("(numeric double) ");
            break;
        case ISP_ATTR_DATE :
            idlOS::printf("(date) ");
            break;
        default :
            idlOS::printf("(none) ");
            break;
        }
        idlOS::printf("[%s]\n", (SChar *)m_AttrValue);
    }
    return isql_true;
}

SInt iloTableInfo::seqEqualChk(SInt index)
{
    SInt j;
    for (j = 0;j < seqCount(); j++)
    {
        if (idlOS::strcasecmp(GetAttrName(index), localSeqArray[j].seqCol) == 0)
        {
            return j;
        }
    }
    return -1;
}


isql_bool iloTableInfo::seqColChk()
{
    SInt i;
    SInt j;
    SInt exist = 0;;

    for (j = 0;j < seqCount(); j++)
    {
        exist = 0;
        
        for(i = 0; i < GetAttrCount(); i++)
        {
            if (idlOS::strcasecmp(GetAttrName(i), localSeqArray[j].seqCol) == 0)
                exist = 1;
        }
        if (exist == 0)
        {
            idlOS::printf("\n%s :: Not Exist Column Linked Sequence !! \nChack Your Form File!!\n"
                ,localSeqArray[j].seqCol);
            return isql_false;
        }
    }
    return isql_true;
}

isql_bool iloTableInfo::seqDupChk()
{
    SInt i;
    SInt j;
    SInt exist = 0;;

    for (j = 0; j < seqCount(); j++)
    {
        exist = 0;
        
        for(i = 0; i < seqCount(); i++)
        {
            if (idlOS::strcasecmp(localSeqArray[i].seqCol, localSeqArray[j].seqCol) == 0)
                exist++;
        }
        if (exist > 1)
        {
            idlOS::printf("\n%s :: One Column Linked %d Sequence !! \nChack Your Form File!!\n"
                ,localSeqArray[j].seqCol, exist);
            return isql_false;
        }
    }
    return isql_true;
}

SInt iloTableInfo::seqCount()
{
    SInt i;
    for(i = 0; i < gSeqIndex; i++)
    {
        if ( idlOS::strcasecmp(localSeqArray[i].seqName,"") == 0 )
            return i;
    }
    return i;
}

isql_bool iloTableInfo::FreeTableAttr()
{
    SInt i;

    for( i = 0; i < m_AttrCount ; i++ )
    {
        if ( m_AttrType[i] == ISP_ATTR_NIBBLE ||
             m_AttrType[i] == ISP_ATTR_BYTES ||
             m_AttrType[i] == ISP_ATTR_TIMESTAMP ||
             m_AttrType[i] == ISP_ATTR_BLOB )
        {
            idlOS::free( m_AttrValue[i][0].B_Col );
        }
        idlOS::free( m_AttrValue[i] );
        idlOS::free( m_AttrLen[i] );
    }

    idlOS::free ( m_AttrValue );
    idlOS::free ( m_AttrLen );
    idlOS::free ( mStatusPtr );
    idlOS::free ( m_ReadCount );

    return isql_true;
}

void iloTableInfo::FreeDateFormat()
{
    SInt i;

    for( i = 0; i < m_AttrCount ; i++ )
    {
        if ( m_AttrType[i] == ISP_ATTR_DATE &&
             mAttrDateFormat[i] != NULL )
        {
            idlOS::free( mAttrDateFormat[i] );
        }
    }
}
