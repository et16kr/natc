/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iloLogFile.cpp 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/
 
#include <ilo.h>

extern idBool     gAddFlag;

iloLogFile::iloLogFile()
{
    m_LogFp = NULL;
    m_UseLogFile = isql_false;
    idlOS::strcpy(m_FieldTerm, "^");
    idlOS::strcpy(m_RowTerm, "\n");
}

void iloLogFile::SetTerminator(SChar *szFiledTerm, SChar *szRowTerm)
{
    idlOS::strcpy(m_FieldTerm, szFiledTerm);
    idlOS::strcpy(m_RowTerm, szRowTerm);
}

isql_bool iloLogFile::OpenFile(SChar *szFileName)
{
    m_LogFp = ilo_fopen(szFileName, "wt");
    IDE_TEST( m_LogFp == NULL );

    m_UseLogFile = isql_true;
    return isql_true;

    IDE_EXCEPTION_END;

    m_UseLogFile = isql_false;
    return isql_false;
}

isql_bool iloLogFile::CloseFile()
{
    IDE_TEST_RAISE( m_UseLogFile == isql_false, err_ignore );

    IDE_TEST( idlOS::fclose(m_LogFp) != 0 );

    m_UseLogFile = isql_false;
    return isql_true;

    IDE_EXCEPTION( err_ignore );
    {
        return isql_true;
    }
    IDE_EXCEPTION_END;

    return isql_false;
}

void iloLogFile::PrintLogMsg(SChar *szMsg)
{
    IDE_TEST(m_UseLogFile == isql_false);

    idlOS::fprintf(m_LogFp, "%s", szMsg);

    IDE_EXCEPTION_END;

    return;
}

void iloLogFile::PrintTime(SChar *szPrnStr)
{
    time_t lTime;
    SChar  *szTime;

    IDE_TEST(m_UseLogFile == isql_false);

    time(&lTime);
    szTime = ctime(&lTime);

    idlOS::fprintf(m_LogFp, "%s : %s\n", szPrnStr, szTime);

    IDE_EXCEPTION_END;

    return;
}

isql_bool iloLogFile::PrintOneRecord(iloTableInfo *pTableInfo, SInt aArrayCount)
{
    SInt i;

    IDE_TEST(m_UseLogFile == isql_false);

    for (i=0; i < pTableInfo->GetReadCount(aArrayCount); i++)
    {
        if ( pTableInfo->GetAttrType(i) == ISP_ATTR_TIMESTAMP &&
             gAddFlag == ID_TRUE )
        {           
            i++;                    
        } 
        switch (pTableInfo->GetAttrType(i))
        {
        case ISP_ATTR_INTEGER :
        case ISP_ATTR_DOUBLE :
        case ISP_ATTR_SMALLINT:
        case ISP_ATTR_BIGINT:
        case ISP_ATTR_DECIMAL:
        case ISP_ATTR_FLOAT:
        case ISP_ATTR_REAL:
        case ISP_ATTR_NIBBLE :
        case ISP_ATTR_BYTES :
        case ISP_ATTR_CHAR :
        case ISP_ATTR_VARCHAR :
        case ISP_ATTR_NUMERIC_LONG :
        case ISP_ATTR_NUMERIC_DOUBLE :
        case ISP_ATTR_DATE :
        case ISP_ATTR_TIMESTAMP :
            idlOS::fprintf(m_LogFp, "%s",
                           pTableInfo->GetAttrValue(i,aArrayCount)->C_Col);
            break;
        case ISP_ATTR_BIT :
            idlOS::fprintf(m_LogFp, "[BIT]");
            break;
        default :
            idlOS::fprintf(m_LogFp, "unknown type");
            break;
        }
        idlOS::fprintf(m_LogFp, "%s",
            (i == pTableInfo->GetAttrCount()-1) ? m_RowTerm : m_FieldTerm);
    }

    return isql_true;

    IDE_EXCEPTION_END;

    return isql_true;
}

