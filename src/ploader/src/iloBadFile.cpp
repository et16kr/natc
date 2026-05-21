/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iloBadFile.cpp 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/
 
#include <ilo.h>

extern idBool     gAddFlag;

iloBadFile::iloBadFile()
{
    m_BadFp = NULL;
    m_UseBadFile = isql_false;
    idlOS::strcpy(m_FieldTerm, "^");
    idlOS::strcpy(m_RowTerm, "\n");
}

void iloBadFile::SetTerminator(SChar *szFiledTerm, SChar *szRowTerm)
{
    idlOS::strcpy(m_FieldTerm, szFiledTerm);
    idlOS::strcpy(m_RowTerm, szRowTerm);
}

isql_bool iloBadFile::OpenFile(SChar *szFileName)
{
    m_BadFp = ilo_fopen(szFileName, "wt");
    IDE_TEST( m_BadFp == NULL );

    m_UseBadFile = isql_true;
    return isql_true;

    IDE_EXCEPTION_END;

    m_UseBadFile = isql_false;
    return isql_false;
}

isql_bool iloBadFile::CloseFile()
{
    IDE_TEST_RAISE( m_UseBadFile != isql_true, err_ignore );

    IDE_TEST( idlOS::fclose( m_BadFp ) != 0 );

    m_UseBadFile = isql_false;
    return isql_true;

    IDE_EXCEPTION( err_ignore );
    {
        return isql_true;
    }
    IDE_EXCEPTION_END;

    return isql_false;
}

isql_bool iloBadFile::PrintOneRecord(iloTableInfo *pTableInfo, SInt aArrayCount)
{
    SInt i;

    IDE_TEST_RAISE( m_UseBadFile != isql_true, err_ignore );

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
        case ISP_ATTR_DOUBLE:
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
            idlOS::fprintf(m_BadFp, "%s", pTableInfo->GetAttrValue(i,aArrayCount)->C_Col);
            break;
        case ISP_ATTR_BIT :
            //fprintf(m_BadFi, "%s", pTableInfo->GetAttrValue(i)->C_Col);
            idlOS::fprintf(m_BadFp, "[BLOB]");
            break;
        default :
            idlOS::fprintf(m_BadFp, "unknown type");
            break;
        }
        idlOS::fprintf(m_BadFp, "%s",
                (i == pTableInfo->GetAttrCount()-1) ? m_RowTerm : m_FieldTerm);
    }

    return isql_true;

    IDE_EXCEPTION( err_ignore );
    {
        return isql_true;
    }
    IDE_EXCEPTION_END;

    return isql_false;
}

