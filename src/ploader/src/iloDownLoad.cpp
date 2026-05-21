/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iloDownLoad.cpp 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/
 
#include <ilo.h>

extern SChar gDateForm[64];

iloDownLoad::iloDownLoad()
{ 
    m_pProgOption = NULL;
    m_pISPApi = NULL;
}

isql_bool iloDownLoad::GetTableTree()
{
    iloTableNode *pTableRoot = NULL;
    SInt          nRet;
    SChar         szMsg[4096];

    szMsg[0] = '\0';
    gDateForm[0] = 0;

    IDE_TEST_RAISE( m_FormCompiler.SetInputFile(m_pProgOption->m_FormFile)
                    == isql_false, err_open );

    nRet = yyparse(&pTableRoot);
    m_FormCompiler.CloseInputFp();
    IDE_TEST_RAISE( nRet != 0, err_parse );

    m_TableTree.SetTreeRoot(pTableRoot);

    if ( idlOS::getenv("ILO_DATEFORM") != NULL )
    {
        idlOS::strcpy( gDateForm, idlOS::getenv("ILO_DATEFORM") );
    }
    if ( gDateForm[0] != 0 )
    {
        idlOS::printf("DATE FORMAT : %s\n", gDateForm);
    }

#ifdef _ILOADER_DEBUG
    m_TableTree.PrintTree();
#endif

    return isql_true;

    IDE_EXCEPTION( err_open );
    {
        idlOS::sprintf(szMsg, "Error : Cannot Open File [%s]\n",
                       m_pProgOption->m_FormFile);
    }
    IDE_EXCEPTION( err_parse );
    {
        delete pTableRoot;
        idlOS::sprintf(szMsg, "Input Command Parser Error or "
                       "Reserved Keyword Used\n");
    }
    IDE_EXCEPTION_END;

    idlOS::printf(szMsg);

    if ( szMsg[0] != '\0' && m_pProgOption->m_bExist_log )
    {
        if ( m_LogFile.OpenFile(m_pProgOption->m_LogFile) != isql_false )
        {
            m_LogFile.PrintLogMsg(szMsg);
            m_LogFile.CloseFile();
        }
    }

    return isql_false;
}

isql_bool iloDownLoad::GetTableInfo()
{
    IDE_TEST( m_TableInfo.GetTableInfo(m_TableTree.GetTreeRoot())
              != isql_true );
#ifdef _ILOADER_DEBUG
    m_TableInfo.PrintTableInfo();
#endif

    return isql_true;

    IDE_EXCEPTION_END;

    return isql_false;
}

isql_bool iloDownLoad::DownLoad()
{
    SChar szMsg[4096];
    SInt i;
    SInt sDataFileCnt = 0;

    IDE_TEST( GetTableTree() == isql_false );
    IDE_TEST( GetTableInfo() == isql_false );
    IDE_TEST( GetQueryString() == isql_false );
    IDE_TEST( ExecuteQuery() == isql_false );
    IDE_TEST( CompareAttrType() == isql_false );

    m_DataFile.SetTerminator( m_pProgOption->m_FieldTerm,
                              m_pProgOption->m_RowTerm );
    m_DataFile.SetEnclosing( m_pProgOption->m_bExist_e,
                             m_pProgOption->m_EnclosingChar );
    if ( m_pProgOption->m_bExist_split == ID_TRUE )
    {
        IDE_TEST( m_DataFile.OpenFile(m_pProgOption->m_DataFile, sDataFileCnt++, (SChar*)"wt")
                  == isql_false );
    }
    else
    {
        IDE_TEST( m_DataFile.OpenFile(m_pProgOption->m_DataFile, (SChar*)"wt")
                  == isql_false );
    }

    if (m_pProgOption->m_bExist_log)
    {
        IDE_TEST_RAISE( m_LogFile.OpenFile(m_pProgOption->m_LogFile)
                        == isql_false, err_open );

        idlOS::sprintf(szMsg,
                       "<Data DownLoad>\nTableName : %s\n",
                       m_TableInfo.GetTableName());
        m_LogFile.PrintLogMsg(szMsg);
        m_LogFile.PrintTime((SChar*)"Start Time");
        m_LogFile.SetTerminator( m_pProgOption->m_FieldTerm,
                                 m_pProgOption->m_RowTerm );
    }
   
    idlOS::printf("     ");
    for (i = 1; m_pISPApi->Fetch(); i++)
    {
        m_DataFile.PrintOneRecord(&(m_pISPApi->m_Column));
        if (i % 10 == 0)
        {
            idlOS::printf(".");
        }
        if (i % 500 == 0)
        {
            idlOS::printf("\n     ");
        }

        if (i % 5000 == 0)
        {
            idlOS::printf("%d record download\n", i);
            idlOS::printf("\n     ");
        }
        if ( m_pProgOption->m_bExist_split == ID_TRUE &&
             i % m_pProgOption->m_SplitRowCount == 0 )
        {
            m_DataFile.CloseFile();
            IDE_TEST( m_DataFile.OpenFile(m_pProgOption->m_DataFile, sDataFileCnt++, (SChar*)"wt")
                      == isql_false );
        }
    }

    idlOS::printf("\n     Total %d record download\n", i-1);

    m_DataFile.CloseFile();
    if (m_pProgOption->m_bExist_log)
    {
        m_LogFile.PrintTime((SChar*)"End Time");
        idlOS::sprintf(szMsg,
                       "Total Row Count : %d\n"
                       "Load Row Count  : %d\n"
                       "Error Row Count : %d\n",
                       i-1, i-1,  0);
        m_LogFile.PrintLogMsg(szMsg);
        m_LogFile.CloseFile();
    }

    return isql_true;

    IDE_EXCEPTION( err_open );
    {
        idlOS::printf("Log File [%s] open fail\n",
                      m_pProgOption->m_LogFile);
        m_DataFile.CloseFile();
    }
    IDE_EXCEPTION_END;

    return isql_false;
}

isql_bool iloDownLoad::GetQueryString()
{
    SChar *szQuery;
    SChar *szWhere;
    SChar  buffer[72];
    SInt   i;

    idlOS::strcpy(m_QueryStr, "select ");

    for (i=0; i < m_TableInfo.GetAttrCount(); i++)
    {
        if( m_TableInfo.GetAttrType(i) == ISP_ATTR_DATE )
        {
            if ( m_TableInfo.mAttrDateFormat[i] != NULL )
            {
                idlOS::sprintf(buffer, "to_char(%s,'%s')",
                               m_TableInfo.GetAttrName(i),
                               m_TableInfo.mAttrDateFormat[i]);
                idlOS::strcat(m_QueryStr, buffer);
            }
            else if ( idlOS::strlen(gDateForm) >= 1 )
            {
                idlOS::sprintf(buffer, "to_char(%s,'%s')",
                               m_TableInfo.GetAttrName(i), gDateForm);
                idlOS::strcat(m_QueryStr, buffer);
            }
            else
            {
                idlOS::strcat(m_QueryStr, m_TableInfo.GetAttrName(i));
            }
        }
        else
        {
            idlOS::strcat(m_QueryStr, m_TableInfo.GetAttrName(i));
        }
        idlOS::strcat(m_QueryStr, ", ");
    }
    m_QueryStr[idlOS::strlen(m_QueryStr) - 2] = '\0'; // ", " 제거

    idlOS::strcat(m_QueryStr, " from ");
    idlOS::strcat(m_QueryStr, m_TableInfo.GetTableName());

    if (m_TableInfo.ExistDownCond() == isql_true)
    {
        szQuery = m_TableInfo.GetQueryString();
        szWhere = strstr(szQuery, "where");
        if (szWhere == NULL)
        {
            szWhere = strstr(szQuery, "WHERE");
        }
        if (szWhere != NULL)
        {
            strcat(m_QueryStr, " ");
            strcat(m_QueryStr, szWhere);
        }
    }

    m_TableInfo.FreeDateFormat();

#ifdef _ILOADER_DEBUG
    idlOS::printf("DownLoad QueryStr[%s]\n", m_QueryStr);
#endif

    return isql_true;
}

isql_bool iloDownLoad::ExecuteQuery()
{
    m_pISPApi->SetSQLStatement(m_QueryStr);

    IDE_TEST( m_pISPApi->SelectExecute(&m_TableInfo) == isql_false );

    return isql_true;

    IDE_EXCEPTION_END;

    idlOS::printf("%s", m_pISPApi->GetErrorMsg());

    return isql_false;
}

isql_bool iloDownLoad::CompareAttrType()
{
    IDE_TEST( m_TableInfo.GetAttrCount() != m_pISPApi->m_Column.GetSize() );

    /* 이곳에 Form 파일에 기술된 데이터 타입과 사용자가 입력한
     * 데이터 타입을 비교하는 코드를 삽입한다.
     */

    return isql_true;

    IDE_EXCEPTION_END;

    idlOS::printf("Result Attribute Count is wrong\n");

    return isql_false;
}

