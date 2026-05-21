/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iloFormDown.cpp 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/
 
#include <ilo.h>

iloFormDown::iloFormDown()                                            
{ 
    m_pProgOption = NULL; 
    m_pISPApi = NULL;
    m_fpForm = NULL; 
}

isql_bool iloFormDown::FormDown()
{
    IDE_TEST_RAISE( m_pISPApi->Columns(m_pProgOption->m_TableName[0], 
                                       m_pProgOption->m_TableOwner[0])
                    == isql_false, err_col );
    
    IDE_TEST( OpenFormFile() == isql_false );
        
    IDE_TEST_RAISE( WriteColumns() == isql_false, err_col );

    CloseFormFile();

    return isql_true;

    IDE_EXCEPTION( err_col );
    {
        idlOS::printf("%s", m_pISPApi->GetErrorMsg());
        CloseFormFile();
    }
    IDE_EXCEPTION_END;

    return isql_false;
}

isql_bool iloFormDown::FormDownAsStruct()
{
    IDE_TEST_RAISE( m_pISPApi->Columns(m_pProgOption->m_TableName[0],
                                       m_pProgOption->m_TableOwner[0])
                    == isql_false, err_col );
    
    IDE_TEST( OpenFormFile() == isql_false );
        
    IDE_TEST_RAISE( WriteColumnsAsStruct() == isql_false, err_col );

    CloseFormFile();

    return isql_true;

    IDE_EXCEPTION( err_col );
    {
        idlOS::printf("%s", m_pISPApi->GetErrorMsg());
        CloseFormFile();
    }
    IDE_EXCEPTION_END;

    return isql_false;
}

isql_bool iloFormDown::OpenFormFile()
{
    m_fpForm = ilo_fopen(m_pProgOption->m_FormFile, "wt");
    IDE_TEST( m_fpForm == NULL );

    return isql_true;

    IDE_EXCEPTION_END;

    return isql_false;
}

isql_bool iloFormDown::WriteColumns()
{
    SChar *pName;
    SInt   i;
    SInt   sDateFlag = 0;

    if ( m_pProgOption->m_bExist_TabOwner == isql_false )
    {
        idlOS::fprintf(m_fpForm, "table %s\n", m_pProgOption->m_TableName[0]);
    }
    else
    {
        idlOS::fprintf(m_fpForm, "table %s.%s\n", 
                       m_pProgOption->m_TableOwner[0],
                       m_pProgOption->m_TableName[0]);
    }
    idlOS::fprintf(m_fpForm, "{\n");
    for (i=0; i < m_pISPApi->m_Column.GetSize(); i++)
    {
        pName = (SChar *)m_pISPApi->m_Column.GetName(i);
        idlOS::fprintf(m_fpForm, "%s ", pName);

        switch (m_pISPApi->m_Column.GetType(i))
        {
        case SQL_DOUBLE :
            idlOS::fprintf(m_fpForm, "double;\n");
            break;
        case SQL_NUMERIC :
            if (m_pISPApi->m_Column.GetScale(i) != 0)
            {
                idlOS::fprintf(m_fpForm, "numeric (%d, %d);\n", 
                               m_pISPApi->m_Column.GetPrecision(i),
                               m_pISPApi->m_Column.GetScale(i));
            }
            else if (m_pISPApi->m_Column.GetPrecision(i) == 38)
            {
                idlOS::fprintf(m_fpForm, "numeric;\n");
            }
            else
            {
                idlOS::fprintf(m_fpForm, "numeric (%d);\n",
                               m_pISPApi->m_Column.GetPrecision(i));
            }
            break;
        case SQL_DECIMAL :
            if (m_pISPApi->m_Column.GetScale(i) != 0)
            {
                idlOS::fprintf(m_fpForm, "decimal (%d, %d);\n", 
                               m_pISPApi->m_Column.GetPrecision(i),
                               m_pISPApi->m_Column.GetScale(i));
            }
            else if (m_pISPApi->m_Column.GetPrecision(i) == 38)
            {
                idlOS::fprintf(m_fpForm, "decimal;\n");
            }
            else
            {
                idlOS::fprintf(m_fpForm, "decimal (%d);\n",
                               m_pISPApi->m_Column.GetPrecision(i));
            }
            break;
        case SQL_FLOAT :
            if (m_pISPApi->m_Column.GetPrecision(i) == 38)
            {
                idlOS::fprintf(m_fpForm, "float;\n");
            }
            else
            {
                idlOS::fprintf(m_fpForm, "float (%d);\n",
                               m_pISPApi->m_Column.GetPrecision(i));
            }
            break;
        case SQL_VARCHAR :
            idlOS::fprintf(m_fpForm, "varchar (%d);\n",
                           m_pISPApi->m_Column.GetPrecision(i));
            break;
        case SQL_SMALLINT :
            idlOS::fprintf(m_fpForm, "smallint;\n");
            break;
        case SQL_BIGINT :
            idlOS::fprintf(m_fpForm, "bigint;\n");
            break;
        case SQL_REAL :
            idlOS::fprintf(m_fpForm, "real;\n");
            break;
        case SQL_INTEGER :
            idlOS::fprintf(m_fpForm, "integer;\n");
            break;
        case SQL_NIBBLE :
            idlOS::fprintf(m_fpForm, "nibble (%d);\n",
                           m_pISPApi->m_Column.GetPrecision(i));
            break;            
        case SQL_CHAR :
            idlOS::fprintf(m_fpForm, "char (%d);\n",
                           m_pISPApi->m_Column.GetPrecision(i));
            break;
        case SQL_BYTES :
            idlOS::fprintf(m_fpForm, "bytes (%d);\n",
                           m_pISPApi->m_Column.GetPrecision(i));
            break;
        case SQL_BINARY :
            idlOS::fprintf(m_fpForm, "blob (%d);\n",
                           m_pISPApi->m_Column.GetPrecision(i));
            break;
        case SQL_DATE :
            idlOS::fprintf(m_fpForm, "date;\n");
            sDateFlag = 1;
            break;
        case SQL_NATIVE_TIMESTAMP :
            idlOS::fprintf(m_fpForm, "timestamp;\n");
            sDateFlag = 1;
            break;
        default :
            idlOS::printf("%s [Unknown Attribute Type]\n", pName);
            return isql_false;
        }
    }
    idlOS::fprintf(m_fpForm, "}\n");
    if ( sDateFlag == 1)
    {
        idlOS::fprintf( m_fpForm, "DATEFORM YYYY/MM/DD HH:MI:SS\n" );
    }

    return isql_true;
}

isql_bool iloFormDown::WriteColumnsAsStruct()
{
    SChar *pName;
    SInt   i;

    idlOS::fprintf(m_fpForm, "typedef struct %s_STRUCT\n",
                   m_pProgOption->m_TableName[0]);
    idlOS::fprintf(m_fpForm, "{\n");
    for (i=0; i < m_pISPApi->m_Column.GetSize(); i++)
    {
        pName = (SChar *)m_pISPApi->m_Column.GetName(i);

        switch (m_pISPApi->m_Column.GetType(i))
        {
        case SQL_DOUBLE :
        case SQL_FLOAT :
            idlOS::fprintf(m_fpForm, "double %s;\n", pName);
            break;
        case SQL_NUMERIC :
        case SQL_DECIMAL :
            idlOS::fprintf(m_fpForm, "double %s;\n", pName);
            break;
        case SQL_VARCHAR :
        case SQL_CHAR :
            idlOS::fprintf(m_fpForm, "char %s[%d+1];\n",
                           pName,
                           m_pISPApi->m_Column.GetPrecision(i));
            break;
        case SQL_SMALLINT :
            idlOS::fprintf(m_fpForm, "SQLSMALLINT %s;\n", pName);
            break;
        case SQL_BIGINT :
            idlOS::fprintf(m_fpForm, "SQLBIGINT %s;\n", pName);
            break;
        case SQL_REAL :
            idlOS::fprintf(m_fpForm, "float %s;\n", pName);
            break;
        case SQL_INTEGER :
            idlOS::fprintf(m_fpForm, "SQLINTEGER %s;\n", pName);
            break;
        case SQL_NIBBLE :
            idlOS::fprintf(m_fpForm, "unsigned char %s[%d]; "
                           "/* use SES_NIBBLE %s[%d] for SESC */\n",
                           pName,
                           m_pISPApi->m_Column.GetPrecision(i),
                           pName,
                           m_pISPApi->m_Column.GetPrecision(i));
            break;            
        case SQL_BYTES :
            idlOS::fprintf(m_fpForm, "unsigned char %s[%d]; "
                           "/* use SES_BYTES %s[%d] for SESC */\n",
                           pName,
                           m_pISPApi->m_Column.GetPrecision(i),
                           pName,
                           m_pISPApi->m_Column.GetPrecision(i));
            break;
        case SQL_BINARY :
            idlOS::fprintf(m_fpForm, "unsigned char %s[%d]; "
                           "/* use SES_BINARY %s[%d] for SESC */\n",
                           pName,
                           m_pISPApi->m_Column.GetPrecision(i),
                           pName,
                           m_pISPApi->m_Column.GetPrecision(i));
            break;
        case SQL_DATE :
            idlOS::fprintf(m_fpForm, "SQL_TIMESTAMP_STRUCT %s;\n",
                           pName);
            break;
        default :
            idlOS::printf("%s [Unknown Attribute Type]\n", pName);
            return isql_false;
        }
    }
    idlOS::fprintf(m_fpForm, "} %s_STRUCT;\n",
                   m_pProgOption->m_TableName[0]);

    return isql_true;
}
