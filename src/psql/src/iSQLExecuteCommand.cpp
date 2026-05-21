/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iSQLExecuteCommand.cpp 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/

#include <ideErrorMgr.h>
#include <utString.h>
#include <iSQLProperty.h>
#include <iSQLProgOption.h>
#include <iSQLHostVarMgr.h>
#include <iSQLHelp.h>
#include <iSQLExecuteCommand.h>
#include <iSQLCommand.h>
#include <iSQLCommandQueue.h>

extern utString                gString;
extern iSQLCommand            *gCommand;
extern iSQLCommandQueue       *gCommandQueue;
extern iSQLProperty            gProperty;
extern iSQLProgOption          gProgOption;
extern iSQLHostVarMgr          gHostVarMgr;
extern iSQLSessionKind         gSessionKind;
extern MESSAGE_CALLBACK_STRUCT gMessageCallbackStruct;

extern int SaveFileData(const char *file, UChar *data);

iSQLExecuteCommand::iSQLExecuteCommand( SInt a_bufSize )
{ 
    m_ISPApi = new utISPApi(a_bufSize);
}

iSQLExecuteCommand::~iSQLExecuteCommand()
{ 
    delete m_ISPApi;
}

IDE_RC 
iSQLExecuteCommand::ConnectDB( SChar * a_Host, 
                               SChar * a_UserID, 
                               SChar * a_Passwd, 
                               SChar * a_NLS, 
                               SInt    a_Port, 
                               SInt    a_Conntype )
{
    SQLRETURN rc;
    IDE_TEST_RAISE((rc = m_ISPApi->Open(a_Host, a_UserID, a_Passwd,
                                  a_NLS, a_Port,
                                  a_Conntype, &gMessageCallbackStruct))
                  != IDE_SUCCESS, error);

    return IDE_SUCCESS;

    IDE_EXCEPTION(error); 
    {
        idlOS::sprintf(m_Spool.m_Buf, m_ISPApi->GetErrorMsg());
        m_Spool.Print();
        if ( a_Conntype == 5 && rc != SQL_SUCCESS )
        {
            if ( idlOS::strcmp(m_ISPApi->GetErrorState(), "CIDLE") == 0 )
            {
                return IDE_SUCCESS;
            }
        }
        else if ( rc == SQL_ERROR )
        {
            idlOS::sprintf(m_Spool.m_Buf, "Fail connect to server.\n");
            m_Spool.Print();
        }
        else
        {
            return IDE_SUCCESS;
        }
    }
    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

void 
iSQLExecuteCommand::DisconnectDB()
{
    if ( m_Spool.IsSpoolOn() == ID_TRUE )
    {
        m_Spool.SpoolOff();
    }

    if ( gProgOption.IsOutFile() == ID_TRUE )
    {
       idlOS::fflush(gProgOption.m_OutFile);
       idlOS::fclose(gProgOption.m_OutFile);
    }

    m_ISPApi->Close();
    
    exit(0);
}

IDE_RC 
iSQLExecuteCommand::DisplayTableList( SChar * a_CommandStr )
{
    SInt   i;
    idBool is_sysuser;
    SChar  tmp[WORD_LEN];
    SInt   sAutocommit;

    idlOS::sprintf(m_Spool.m_Buf, "%s", a_CommandStr);  
    m_Spool.PrintCommand();

    if ( idlOS::strcasecmp(gProperty.GetUserName(), (SChar*)"sys") == 0 ||
         idlOS::strcasecmp(gProperty.GetUserName(), (SChar*)"system_") == 0 )
    {
        is_sysuser = ID_TRUE;
    }
    else
    {
        is_sysuser = ID_FALSE;
    }

    IDE_TEST( m_ISPApi->GetConnectAttr(SQL_ATTR_AUTOCOMMIT, &sAutocommit)
              != IDE_SUCCESS );

    if ( gSessionKind != EXPLAIN_PLAN_OFF )
    {
        if ( sAutocommit == SQL_AUTOCOMMIT_OFF &&
             gProperty.GetPlanCommit() == ID_TRUE )
        {
            m_ISPApi->EndTran(ID_TRUE);
        }
        IDE_TEST(m_ISPApi->ExplainPlanExecute(0) != IDE_SUCCESS);
    }

    IDE_TEST_RAISE(m_ISPApi->Tables(gProperty.GetUserName(), is_sysuser)
                   != IDE_SUCCESS, error);

    if (m_ISPApi->m_Column.GetSize() == 0)
    {
        idlOS::sprintf(m_Spool.m_Buf, "Table does not exist.\n");
        m_Spool.Print();
    }
    else
    {
        if ( is_sysuser == ID_TRUE )
        {
            idlOS::sprintf(m_Spool.m_Buf, "USER NAME                                TABLE NAME                               TYPE\n");
            m_Spool.Print();
            idlOS::sprintf(m_Spool.m_Buf, "--------------------------------------------------------------------------------------\n");
            m_Spool.Print();
        }
        else
        {
            idlOS::sprintf(m_Spool.m_Buf, "TABLE NAME                               TYPE\n");
            m_Spool.Print();
            idlOS::sprintf(m_Spool.m_Buf, "---------------------------------------------\n");
            m_Spool.Print();
        }

        for (i=0; i<m_ISPApi->m_Column.GetSize(); i++)
        {
            SChar sTableType[20];
            if ( m_ISPApi->m_Column.GetType(i) == TYPE_SYSTEM_TABLE )
            {
                idlOS::strcpy( sTableType, "SYSTEM TABLE" );
            }
            else if ( m_ISPApi->m_Column.GetType(i) == TYPE_TABLE )
            {
                idlOS::strcpy( sTableType, "TABLE" );
            }
            else if ( m_ISPApi->m_Column.GetType(i) == TYPE_VIEW )
            {
                idlOS::strcpy( sTableType, "VIEW" );
            }
            else
            {
                idlOS::strcpy( sTableType, "" );
            }
            if ( is_sysuser == ID_TRUE )
            {
                idlOS::sprintf(m_Spool.m_Buf, "%-40s %-40s %s\n",
                               m_ISPApi->m_Column.GetUserName(i),
                               m_ISPApi->m_Column.GetName(i),
                               sTableType);
                m_Spool.Print();
            }
            else
            {
                idlOS::sprintf(m_Spool.m_Buf, "%-40s %s\n",
                               m_ISPApi->m_Column.GetName(i),
                               sTableType);
                m_Spool.Print();
            }
        }

        if (i == 1)
        {
            idlOS::strcpy(tmp, (SChar*)"1 row");
        }
        else 
        {
            idlOS::sprintf(tmp, (SChar*)"%d rows", i);
        }
        idlOS::sprintf(m_Spool.m_Buf, "%s selected.\n", tmp);
        m_Spool.Print();
    }
    
    if ( gSessionKind == EXPLAIN_PLAN_ON )
    {
        if ( sAutocommit == SQL_AUTOCOMMIT_OFF &&
             gProperty.GetPlanCommit() == ID_TRUE )
        {
            m_ISPApi->EndTran(ID_TRUE);
        }
        IDE_TEST(m_ISPApi->ExplainPlanExecute(1) != IDE_SUCCESS);
    }
    else if ( gSessionKind == EXPLAIN_PLAN_ONLY )
    {
        if ( sAutocommit == SQL_AUTOCOMMIT_OFF &&
             gProperty.GetPlanCommit() == ID_TRUE )
        {
            m_ISPApi->EndTran(ID_TRUE);
        }
        IDE_TEST(m_ISPApi->ExplainPlanExecute(2) != IDE_SUCCESS);
    }

    m_ISPApi->m_Column.freeMem();

    return IDE_SUCCESS;

    IDE_EXCEPTION(error);
    {
        m_ISPApi->m_Column.freeMem();

        idlOS::sprintf(m_Spool.m_Buf, "%s", m_ISPApi->GetErrorMsg());
        m_Spool.Print();

        if ( idlOS::strcmp(m_ISPApi->GetErrorState(), "08S01") == 0 )
        {
            DisconnectDB();
        }
        else if ( gSessionKind == EXPLAIN_PLAN_ON )
        {
            if ( sAutocommit == SQL_AUTOCOMMIT_OFF &&
                 gProperty.GetPlanCommit() == ID_TRUE )
            {
                m_ISPApi->EndTran(ID_TRUE);
            }
            m_ISPApi->ExplainPlanExecute(1);
        }
        else if ( gSessionKind == EXPLAIN_PLAN_ONLY )
        {
            if ( sAutocommit == SQL_AUTOCOMMIT_OFF &&
                 gProperty.GetPlanCommit() == ID_TRUE )
            {
                m_ISPApi->EndTran(ID_TRUE);
            }
            m_ISPApi->ExplainPlanExecute(2);
        }
        return IDE_FAILURE;
    }
    IDE_EXCEPTION_END;

    m_ISPApi->m_Column.freeMem();

    idlOS::sprintf(m_Spool.m_Buf, "%s", m_ISPApi->GetErrorMsg());
    m_Spool.Print();

    if ( idlOS::strcmp(m_ISPApi->GetErrorState(), "08S01") == 0 )
    {
        DisconnectDB();
    }

    return IDE_FAILURE;
}

IDE_RC 
iSQLExecuteCommand::DisplayFixedTableList( SChar * a_CommandStr,
                                           SChar * a_PrefixName,
                                           SChar * a_TableType )
{
    SInt   i;
    idBool is_sysuser;
    SChar  tmp[WORD_LEN];
    SInt   sAutocommit;
    SInt   sTableCnt;

    idlOS::sprintf(m_Spool.m_Buf, "%s", a_CommandStr);  
    m_Spool.PrintCommand();

    if ( idlOS::strcasecmp(gProperty.GetUserName(), (SChar*)"sys") == 0 ||
         idlOS::strcasecmp(gProperty.GetUserName(), (SChar*)"system_") == 0 )
    {
        is_sysuser = ID_TRUE;
    }
    else
    {
        is_sysuser = ID_FALSE;
    }

    IDE_TEST( m_ISPApi->GetConnectAttr(SQL_ATTR_AUTOCOMMIT, &sAutocommit)
              != IDE_SUCCESS );

    if ( gSessionKind != EXPLAIN_PLAN_OFF )
    {
        if ( sAutocommit == SQL_AUTOCOMMIT_OFF &&
             gProperty.GetPlanCommit() == ID_TRUE )
        {
            m_ISPApi->EndTran(ID_TRUE);
        }
        IDE_TEST(m_ISPApi->ExplainPlanExecute(0) != IDE_SUCCESS);
    }

    IDE_TEST_RAISE(m_ISPApi->FixedTables(gProperty.GetUserName(), is_sysuser)
                   != IDE_SUCCESS, error);

    if (m_ISPApi->m_Column.GetSize() == 0)
    {
        idlOS::sprintf(m_Spool.m_Buf, "Table does not exist.\n");
        m_Spool.Print();
    }
    else
    {
        idlOS::sprintf(m_Spool.m_Buf, "TABLE NAME                               TYPE\n");
        m_Spool.Print();
        idlOS::sprintf(m_Spool.m_Buf, "---------------------------------------------\n");
        m_Spool.Print();

        sTableCnt = 0;
        for (i=0; i<m_ISPApi->m_Column.GetSize(); i++)
        {
            if( strncmp( m_ISPApi->m_Column.GetName(i), a_PrefixName, 2 ) != 0 )
            {
                continue;
            }
            
            idlOS::sprintf(m_Spool.m_Buf, "%-40s %s\n",
                           m_ISPApi->m_Column.GetName(i),
                           a_TableType);
            m_Spool.Print();
            sTableCnt++;
        }

        if (sTableCnt == 1)
        {
            idlOS::strcpy(tmp, (SChar*)"1 row");
        }
        else 
        {
            idlOS::sprintf(tmp, (SChar*)"%d rows", sTableCnt);
        }
        idlOS::sprintf(m_Spool.m_Buf, "%s selected.\n", tmp);
        m_Spool.Print();
    }
    
    if ( gSessionKind == EXPLAIN_PLAN_ON )
    {
        if ( sAutocommit == SQL_AUTOCOMMIT_OFF &&
             gProperty.GetPlanCommit() == ID_TRUE )
        {
            m_ISPApi->EndTran(ID_TRUE);
        }
        IDE_TEST(m_ISPApi->ExplainPlanExecute(1) != IDE_SUCCESS);
    }
    else if ( gSessionKind == EXPLAIN_PLAN_ONLY )
    {
        if ( sAutocommit == SQL_AUTOCOMMIT_OFF &&
             gProperty.GetPlanCommit() == ID_TRUE )
        {
            m_ISPApi->EndTran(ID_TRUE);
        }
        IDE_TEST(m_ISPApi->ExplainPlanExecute(2) != IDE_SUCCESS);
    }

    m_ISPApi->m_Column.freeMem();

    return IDE_SUCCESS;

    IDE_EXCEPTION(error);
    {
        m_ISPApi->m_Column.freeMem();

        idlOS::sprintf(m_Spool.m_Buf, "%s", m_ISPApi->GetErrorMsg());
        m_Spool.Print();

        if ( idlOS::strcmp(m_ISPApi->GetErrorState(), "08S01") == 0 )
        {
            DisconnectDB();
        }
        else if ( gSessionKind == EXPLAIN_PLAN_ON )
        {
            if ( sAutocommit == SQL_AUTOCOMMIT_OFF &&
                 gProperty.GetPlanCommit() == ID_TRUE )
            {
                m_ISPApi->EndTran(ID_TRUE);
            }
            m_ISPApi->ExplainPlanExecute(1);
        }
        else if ( gSessionKind == EXPLAIN_PLAN_ONLY )
        {
            if ( sAutocommit == SQL_AUTOCOMMIT_OFF &&
                 gProperty.GetPlanCommit() == ID_TRUE )
            {
                m_ISPApi->EndTran(ID_TRUE);
            }
            m_ISPApi->ExplainPlanExecute(2);
        }
        return IDE_FAILURE;
    }
    IDE_EXCEPTION_END;

    m_ISPApi->m_Column.freeMem();

    idlOS::sprintf(m_Spool.m_Buf, "%s", m_ISPApi->GetErrorMsg());
    m_Spool.Print();

    if ( idlOS::strcmp(m_ISPApi->GetErrorState(), "08S01") == 0 )
    {
        DisconnectDB();
    }

    return IDE_FAILURE;
}


IDE_RC 
iSQLExecuteCommand::DisplaySequenceList( SChar * a_CommandStr )
{
    SInt      i;
    SInt      m = 0;
    idBool    is_sysuser;
    SChar     tmp[WORD_LEN];
    SInt     *nDisplayPos = NULL;
    SInt     *ColSize     = NULL;
    SInt     *Header_row  = NULL;
    SInt     *space       = NULL;
    int       nLen, j, k, p, q;
    int       curr;
    idBool    bRowPrintComplete;
    SInt      sAutocommit;
    SQLRETURN nResult;

    idlOS::sprintf(m_Spool.m_Buf, "%s", a_CommandStr);  
    m_Spool.PrintCommand();

    if ( idlOS::strcasecmp(gProperty.GetUserName(), (SChar*)"sys") == 0 ||
         idlOS::strcasecmp(gProperty.GetUserName(), (SChar*)"system_") == 0 )
    {
        is_sysuser = ID_TRUE;
    }
    else
    {
        is_sysuser = ID_FALSE;
    }

    IDE_TEST( m_ISPApi->GetConnectAttr(SQL_ATTR_AUTOCOMMIT, &sAutocommit)
              != IDE_SUCCESS );

    if ( gSessionKind != EXPLAIN_PLAN_OFF )
    {
        if ( sAutocommit == SQL_AUTOCOMMIT_OFF &&
             gProperty.GetPlanCommit() == ID_TRUE )
        {
            m_ISPApi->EndTran(ID_TRUE);
        }
        IDE_TEST_RAISE( m_ISPApi->ExplainPlanExecute(0) != IDE_SUCCESS,
                        ret_pos );
    }

    IDE_TEST_RAISE(m_ISPApi->Sequence(gProperty.GetUserName(), is_sysuser)
                   != IDE_SUCCESS, exec_error);

    nDisplayPos = new SInt [m_ISPApi->m_Column.GetSize()];
    ColSize     = new SInt [m_ISPApi->m_Column.GetSize()];
    Header_row  = new SInt [m_ISPApi->m_Column.GetSize()];
    space       = new SInt [m_ISPApi->m_Column.GetSize()];

    for (i=0; i < m_ISPApi->m_Column.GetSize(); i++)
    {
        switch (m_ISPApi->m_Column.GetType(i))
        {
        case SQL_CHAR :
        case SQL_VARCHAR :
            ColSize[i] = m_ISPApi->m_Column.GetPrecision(i);
            break;
        case SQL_SMALLINT :
        case SQL_INTEGER :
            ColSize[i] = 11;
            break;
        case SQL_BIGINT :
        case SQL_INTERVAL :
            ColSize[i] = 20;
            break;
        default :
            ColSize[i] = 0;
            break;
        }
    }
    
    for (k = 0; (nResult = m_ISPApi->FetchNext())//Sequence())
                != SQL_NO_DATA_FOUND; k++)
    {    
        if ( ( k == 0 ) || 
             ( gProperty.GetPageSize() != 0 && m % gProperty.GetPageSize() == 0 ) )
        {
            PrintHeader(ColSize, Header_row, space);
        }
        m++;
        
        if (nResult != SQL_SUCCESS)
        {
            IDE_TEST_RAISE( idlOS::strncmp(m_ISPApi->GetErrorState(),
                                           "08S01", 5) == 0, network_error );
            IDE_RAISE( exec_error );
        }
        
        bRowPrintComplete = ID_FALSE;
        for (i=0; i < m_ISPApi->m_Column.GetSize(); i++)
        {
            nDisplayPos[i] = 0;
        }
        
        while (bRowPrintComplete == ID_FALSE)
        {
            bRowPrintComplete = ID_TRUE;
            p = 0, q = 0;
            for (i=0; i < m_ISPApi->m_Column.GetSize(); i++)
            {
                if (nDisplayPos[i] == -1)
                {
                    for (j = 0; j <= ColSize[i]; j++)
                    {
                        m_Spool.m_Buf[j] = ' ';
                    }
                    m_Spool.m_Buf[j] = '\0';
                    m_Spool.Print();
                    continue;
                }
                if (Header_row[q] > p++)
                {
                    switch (m_ISPApi->m_Column.GetType(i))
                    {
                    case SQL_CHAR :
                        if (nDisplayPos[i] == 0)
                        {
                            gString.removeLastSpace(m_ISPApi->m_Column.m_CValue[i]);
                        }
                    case SQL_VARCHAR :
                        nLen = idlOS::strlen(m_ISPApi->m_Column.m_CValue[i]);
                        for (j = 0; j <= ColSize[i]; j++)
                        {
                            if (nDisplayPos[i] < nLen)
                            {
                                if ((j == ColSize[i]) &&
                                    ((m_Spool.m_Buf[j-1] & 0x80) == 0))
                                {
                                    m_Spool.m_Buf[j] = ' ';
                                }
                                else
                                {
                                    m_Spool.m_Buf[j] = m_ISPApi->m_Column.m_CValue[i][nDisplayPos[i]++];
                                }
                            }
                            else
                            {
                                m_Spool.m_Buf[j] = ' ';
                            }
                        }
                        m_Spool.m_Buf[j++] = ' ';
                        m_Spool.m_Buf[j] = '\0';
                        m_Spool.Print();
                        if (nDisplayPos[i] < nLen)
                        {
                            bRowPrintComplete = ID_FALSE;
                        }
                        else
                        {
                            nDisplayPos[i] = -1;
                        }
                        break;
                    case SQL_BIGINT :
                        nLen = idlOS::strlen(m_ISPApi->m_Column.m_CValue[i]);
                        curr = j;
                        for (j = curr; j < curr+ColSize[i]; j++)
                        {
                            if (nDisplayPos[i] < nLen)
                            {
                                m_Spool.m_Buf[j] = m_ISPApi->m_Column.m_CValue[i][nDisplayPos[i]++];
                            }
                            else
                            {
                                m_Spool.m_Buf[j] = ' ';
                            }
                        }
                        m_Spool.m_Buf[j++] = ' ';
                        nDisplayPos[i] = -1;
                        break;
                    default :
                        break;
                    }
                }
                else
                {
                    idlOS::sprintf(m_Spool.m_Buf, "\n");    
                    m_Spool.Print();
                    i--; q++; p=0;
                }
            }    /* for loop */
            idlOS::sprintf(m_Spool.m_Buf, "\n");    
            m_Spool.Print();
        }    /* while loop */
    }    /* for loop */

    IDE_TEST_RAISE( k == 0, no_seq );

    if (k == 1)
    {
        idlOS::strcpy(tmp, (SChar*)"1 row");
    }
    else 
    {
        idlOS::sprintf(tmp, (SChar*)"%d rows", k);
    }
    idlOS::sprintf(m_Spool.m_Buf, "%s selected.\n", tmp);
    m_Spool.Print();

    m_ISPApi->StmtClose();
    delete [] ColSize;
    delete [] nDisplayPos;
    delete [] Header_row;
    delete [] space;
    m_ISPApi->m_Column.freeMem();

    if ( gSessionKind == EXPLAIN_PLAN_ON )
    {
        if ( sAutocommit == SQL_AUTOCOMMIT_OFF &&
             gProperty.GetPlanCommit() == ID_TRUE )
        {
            m_ISPApi->EndTran(ID_TRUE);
        }
        IDE_TEST(m_ISPApi->ExplainPlanExecute(1) != IDE_SUCCESS);
    }
    else if ( gSessionKind == EXPLAIN_PLAN_ONLY )
    {
        if ( sAutocommit == SQL_AUTOCOMMIT_OFF &&
             gProperty.GetPlanCommit() == ID_TRUE )
        {
            m_ISPApi->EndTran(ID_TRUE);
        }
        IDE_TEST(m_ISPApi->ExplainPlanExecute(2) != IDE_SUCCESS);
    }

    return IDE_SUCCESS;

    IDE_EXCEPTION( network_error );
    {
        idlOS::sprintf(m_Spool.m_Buf,
                       "%s",
                       (char*)"Communication failure.\nConnection closed.\n");  
        m_Spool.Print();
        DisconnectDB();
        exit(0);
    }
    IDE_EXCEPTION( exec_error );
    {
        idlOS::sprintf(m_Spool.m_Buf, "%s", m_ISPApi->GetErrorMsg());
        m_Spool.Print();

        if ( idlOS::strcmp(m_ISPApi->GetErrorState(), "08S01") == 0 )
        {
            DisconnectDB();
            return IDE_FAILURE;
        }
    }
    IDE_EXCEPTION( no_seq );
    {
        idlOS::sprintf(m_Spool.m_Buf, "Sequence does not exist.\n");
        m_Spool.Print();
    }
    IDE_EXCEPTION( ret_pos );
    {
        return IDE_FAILURE;
    }
    IDE_EXCEPTION_END;

    m_ISPApi->StmtClose();
    if ( ColSize != NULL )
    {
        delete [] ColSize;
    }
    if ( nDisplayPos != NULL )
    {
        delete [] nDisplayPos;
    }
    if ( Header_row != NULL )
    {
        delete [] Header_row;
    }
    if ( space != NULL )
    {
        delete [] space;
    }
    m_ISPApi->m_Column.freeMem();

    if ( gSessionKind == EXPLAIN_PLAN_ON )
    {
        if ( sAutocommit == SQL_AUTOCOMMIT_OFF &&
             gProperty.GetPlanCommit() == ID_TRUE )
        {
            m_ISPApi->EndTran(ID_TRUE);
        }
        m_ISPApi->ExplainPlanExecute(1);
    }
    else if ( gSessionKind == EXPLAIN_PLAN_ONLY )
    {
        if ( sAutocommit == SQL_AUTOCOMMIT_OFF &&
             gProperty.GetPlanCommit() == ID_TRUE )
        {
            m_ISPApi->EndTran(ID_TRUE);
        }
        m_ISPApi->ExplainPlanExecute(2);
    }

    return IDE_FAILURE;
}

IDE_RC 
iSQLExecuteCommand::DisplayAttributeList( SChar * a_CommandStr, 
                                          SChar * a_UserName, 
                                          SChar * a_TableName )
{
    SInt      sAutocommit;

    idlOS::sprintf(m_Spool.m_Buf, "%s", a_CommandStr);  
    m_Spool.PrintCommand();

    IDE_TEST( m_ISPApi->GetConnectAttr(SQL_ATTR_AUTOCOMMIT, &sAutocommit)
              != IDE_SUCCESS );

    // BUG-9714,7540
    if ( gSessionKind != EXPLAIN_PLAN_OFF )
    {
        if ( sAutocommit == SQL_AUTOCOMMIT_OFF &&
             gProperty.GetPlanCommit() == ID_TRUE )
        {
            m_ISPApi->EndTran(ID_TRUE);
        }
        IDE_TEST_RAISE(m_ISPApi->ExplainPlanExecute(0) != IDE_SUCCESS, error);
    }

    if ( idlOS::strlen(a_UserName) == 0 )
    {
        idlOS::strcpy(a_UserName, gProperty.GetUserName());
    }

    if ( ShowColumns(a_UserName, a_TableName) == IDE_SUCCESS )
    {
        if ( ShowIndexInfo(a_UserName, a_TableName) == IDE_SUCCESS )
        {
            ShowPrimaryKeys(a_UserName, a_TableName);
        }

        if ( gProperty.GetForeignKeys() == ID_TRUE )
        {
            ShowForeignKeys(a_UserName, a_TableName);
        }
    }

    if ( gSessionKind == EXPLAIN_PLAN_ON )
    {
        if ( sAutocommit == SQL_AUTOCOMMIT_OFF &&
             gProperty.GetPlanCommit() == ID_TRUE )
        {
            m_ISPApi->EndTran(ID_TRUE);
        }
        IDE_TEST_RAISE(m_ISPApi->ExplainPlanExecute(1) != IDE_SUCCESS, error);
    }
    else if ( gSessionKind == EXPLAIN_PLAN_ONLY )
    {
        if ( sAutocommit == SQL_AUTOCOMMIT_OFF &&
             gProperty.GetPlanCommit() == ID_TRUE )
        {
            m_ISPApi->EndTran(ID_TRUE);
        }
        IDE_TEST_RAISE(m_ISPApi->ExplainPlanExecute(2) != IDE_SUCCESS, error);
    }

    return IDE_SUCCESS;

    IDE_EXCEPTION(error);
    {
        idlOS::sprintf(m_Spool.m_Buf, "%s", m_ISPApi->GetErrorMsg());
        m_Spool.Print();

        if ( idlOS::strcmp(m_ISPApi->GetErrorState(), "08S01") == 0 )
        {
            DisconnectDB();
        }
    }
    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC 
iSQLExecuteCommand::DisplayAttributeList4FTnPV( SChar * a_CommandStr, 
                                                SChar * a_UserName, 
                                                SChar * a_TableName )
{
    SInt      sAutocommit;

    idlOS::sprintf(m_Spool.m_Buf, "%s", a_CommandStr);  
    m_Spool.PrintCommand();

    IDE_TEST( m_ISPApi->GetConnectAttr(SQL_ATTR_AUTOCOMMIT, &sAutocommit)
              != IDE_SUCCESS );

    if ( gSessionKind != EXPLAIN_PLAN_OFF )
    {
        if ( sAutocommit == SQL_AUTOCOMMIT_OFF &&
             gProperty.GetPlanCommit() == ID_TRUE )
        {
            m_ISPApi->EndTran(ID_TRUE);
        }
        IDE_TEST_RAISE(m_ISPApi->ExplainPlanExecute(0) != IDE_SUCCESS, error);
    }

    if ( idlOS::strlen(a_UserName) == 0 )
    {
        idlOS::strcpy(a_UserName, gProperty.GetUserName());
    }

    if ( ShowColumns4FTnPV(a_UserName, a_TableName) == IDE_SUCCESS )
    {
/*        
        if ( ShowIndexInfo(a_UserName, a_TableName) == IDE_SUCCESS )
        {
            ShowPrimaryKeys(a_UserName, a_TableName);
        }

        if ( gProperty.GetForeignKeys() == ID_TRUE )
        {
            ShowForeignKeys(a_UserName, a_TableName);
        }
*/        
    }

    if ( gSessionKind == EXPLAIN_PLAN_ON )
    {
        if ( sAutocommit == SQL_AUTOCOMMIT_OFF &&
             gProperty.GetPlanCommit() == ID_TRUE )
        {
            m_ISPApi->EndTran(ID_TRUE);
        }
        IDE_TEST_RAISE(m_ISPApi->ExplainPlanExecute(1) != IDE_SUCCESS, error);
    }
    else if ( gSessionKind == EXPLAIN_PLAN_ONLY )
    {
        if ( sAutocommit == SQL_AUTOCOMMIT_OFF &&
             gProperty.GetPlanCommit() == ID_TRUE )
        {
            m_ISPApi->EndTran(ID_TRUE);
        }
        IDE_TEST_RAISE(m_ISPApi->ExplainPlanExecute(2) != IDE_SUCCESS, error);
    }

    return IDE_SUCCESS;

    IDE_EXCEPTION(error);
    {
        idlOS::sprintf(m_Spool.m_Buf, "%s", m_ISPApi->GetErrorMsg());
        m_Spool.Print();

        if ( idlOS::strcmp(m_ISPApi->GetErrorState(), "08S01") == 0 )
        {
            DisconnectDB();
        }
    }
    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC 
iSQLExecuteCommand::ShowColumns( SChar * a_UserName, 
                                 SChar * a_TableName )
{
    SInt  i;
    SChar tmp[MSG_LEN];
    SChar col_name[WORD_LEN];
    SChar sTBSName[QP_MAX_NAME_LEN+1];
    SChar variable[10];

    IDE_TEST_RAISE(m_ISPApi->getTBSName(a_UserName, a_TableName,
                                        sTBSName) != IDE_SUCCESS,
                   error);
    idlOS::sprintf(m_Spool.m_Buf, "[ TABLESPACE : %s ]\n", sTBSName);
    m_Spool.Print();

    IDE_TEST_RAISE(m_ISPApi->Columns(a_UserName, a_TableName) != IDE_SUCCESS,
                   error);

    idlOS::sprintf(m_Spool.m_Buf, "[ ATTRIBUTE ]                                                         \n");
    m_Spool.Print();
    idlOS::sprintf(m_Spool.m_Buf, "------------------------------------------------------------------------------\n");
    m_Spool.Print();
    idlOS::sprintf(m_Spool.m_Buf, "NAME                                     TYPE                        IS NULL \n");
    m_Spool.Print();
    idlOS::sprintf(m_Spool.m_Buf, "------------------------------------------------------------------------------\n");
    m_Spool.Print();
    
    for (i=0; i<m_ISPApi->m_Column.GetSize(); i++)
    {
        idlOS::strcpy(tmp, m_ISPApi->m_Column.GetName(i));  // column name
        if ( idlOS::strlen(tmp) > 40 )
        {
            idlOS::strncpy(col_name, tmp, 40);
            col_name[40] = 0;
        }
        else
        {
            idlOS::strcpy(col_name, tmp);
        }
        idlOS::sprintf(m_Spool.m_Buf, "%-41s", col_name);    
        m_Spool.Print();

        if ( idlOS::strcmp(m_ISPApi->m_Column.GetIsVaring(i), "F") == 0 )
        {
            idlOS::strcpy(variable, "FIXED");    
        }
        else
        {
            idlOS::strcpy(variable, "VARIABLE");    
        }

        switch (m_ISPApi->m_Column.GetType(i))
        {
        case SQL_CHAR :
            idlOS::sprintf(tmp, "CHAR(%d)",
                           m_ISPApi->m_Column.GetPrecision(i));    
            break;
        case SQL_VARCHAR :
            idlOS::sprintf(tmp, "VARCHAR(%d)",
                           m_ISPApi->m_Column.GetPrecision(i));    
            break;
        case SQL_SMALLINT :
            idlOS::strcpy(tmp, "SMALLINT");    
            break;
        case SQL_INTEGER :
            idlOS::strcpy(tmp, "INTEGER");    
            break;
        case SQL_BIGINT :
            idlOS::strcpy(tmp, "BIGINT");    
            break;
        case SQL_NUMERIC :
        case SQL_DECIMAL :  // BUGBUG
            if (m_ISPApi->m_Column.GetScale(i) != 0)
            {
                idlOS::sprintf(tmp, "NUMERIC(%d, %d)",
                               m_ISPApi->m_Column.GetPrecision(i),
                               m_ISPApi->m_Column.GetScale(i));    
            }
            else if (m_ISPApi->m_Column.GetPrecision(i) != 38)
            {
                idlOS::sprintf(tmp, "NUMERIC(%d)",
                               m_ISPApi->m_Column.GetPrecision(i));    
            }
            else
            {
                idlOS::sprintf(tmp, "NUMERIC");    
            }
            break;
        case SQL_FLOAT : // NUMBER
            if (m_ISPApi->m_Column.GetPrecision(i) != 38)
            {
                idlOS::sprintf(tmp, "FLOAT(%d)",
                               m_ISPApi->m_Column.GetPrecision(i));    
            }
            else
            {
                idlOS::sprintf(tmp, "FLOAT");    
            }
            break;
        case SQL_REAL : // 실제 FLOAT
            idlOS::strcpy(tmp, "REAL");    
            break;
        case SQL_DOUBLE :
            idlOS::strcpy(tmp, "DOUBLE");    
            break;
        case SQL_TYPE_DATE :
        case SQL_DATE      :
            idlOS::strcpy(tmp, "DATE");    
            break;
        case SQL_BINARY :
            idlOS::sprintf(tmp, "BLOB(%d)",
                           m_ISPApi->m_Column.GetPrecision(i));    
            break;
        case SQL_BYTES :
            idlOS::sprintf(tmp, "BYTE(%d)",
                           m_ISPApi->m_Column.GetPrecision(i));    
            break;
        case SQL_NIBBLE :
            idlOS::sprintf(tmp, "NIBBLE(%d)",
                           m_ISPApi->m_Column.GetPrecision(i));    
            break;
        case SQL_GEOMETRY :
            idlOS::strcpy(tmp, "GEOMETRY");    
            break;
        case SQL_NATIVE_TIMESTAMP :
            idlOS::strcpy(tmp, "TIMESTAMP");    
            break;
        default :
            idlOS::sprintf(tmp, "UNKNOWN TYPE");    
            break;
        }
        idlOS::sprintf(m_Spool.m_Buf, "%-15s %-12s", tmp, variable);
        m_Spool.Print();

        if (m_ISPApi->m_Column.GetNull(i) == 0)
        {
            idlOS::sprintf(m_Spool.m_Buf, "NOT NULL\n");
            m_Spool.Print();
        }
        else 
        {
            idlOS::sprintf(m_Spool.m_Buf, "\n");
            m_Spool.Print();
        }
    }

    m_ISPApi->m_Column.freeMem();

    return IDE_SUCCESS;

    IDE_EXCEPTION(error);
    {
        m_ISPApi->m_Column.freeMem();

        idlOS::sprintf(m_Spool.m_Buf, "%s", m_ISPApi->GetErrorMsg());
        m_Spool.Print();

        if ( idlOS::strcmp(m_ISPApi->GetErrorState(), "08S01") == 0 )
        {
            DisconnectDB();
        }
    }
    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC 
iSQLExecuteCommand::ShowColumns4FTnPV( SChar * a_UserName, 
                                       SChar * a_TableName )
{
    SInt  i;
    SChar tmp[MSG_LEN];
    SChar col_name[WORD_LEN];

    IDE_TEST_RAISE(m_ISPApi->Columns4FTnPV(a_UserName, a_TableName) != IDE_SUCCESS,
                   error);

    idlOS::sprintf(m_Spool.m_Buf, "[ ATTRIBUTE ]                                                         \n");
    m_Spool.Print();
    idlOS::sprintf(m_Spool.m_Buf, "------------------------------------------------------------------------------\n");
    m_Spool.Print();
    idlOS::sprintf(m_Spool.m_Buf, "NAME                                     TYPE                         \n");
    m_Spool.Print();
    idlOS::sprintf(m_Spool.m_Buf, "------------------------------------------------------------------------------\n");
    m_Spool.Print();
    
    for (i=0; i<m_ISPApi->m_Column.GetSize(); i++)
    {
        idlOS::strcpy(tmp, m_ISPApi->m_Column.GetName(i));  // column name
        if ( idlOS::strlen(tmp) > 40 )
        {
            idlOS::strncpy(col_name, tmp, 40);
            col_name[40] = 0;
        }
        else
        {
            idlOS::strcpy(col_name, tmp);
        }
        idlOS::sprintf(m_Spool.m_Buf, "%-41s", col_name);    
        m_Spool.Print();

        switch ( (m_ISPApi->m_Column.GetType(i)) & IDU_FT_TYPE_MASK )
        {
        case IDU_FT_TYPE_CHAR :
            idlOS::sprintf(tmp, "CHAR(%d)",
                           m_ISPApi->m_Column.GetPrecision(i));    
            break;
        case IDU_FT_TYPE_USMALLINT :
        case IDU_FT_TYPE_SMALLINT :
            idlOS::strcpy(tmp, "SMALLINT");    
            break;
        case IDU_FT_TYPE_UINTEGER :
        case IDU_FT_TYPE_INTEGER :
            idlOS::strcpy(tmp, "INTEGER");    
            break;
        case IDU_FT_TYPE_UBIGINT :
        case IDU_FT_TYPE_BIGINT :
            idlOS::strcpy(tmp, "BIGINT");    
            break;
        case IDU_FT_TYPE_DOUBLE :
            idlOS::strcpy(tmp, "DOUBLE");    
            break;
        default :
            idlOS::sprintf(tmp, "UNKNOWN TYPE");    
            break;
        }
        idlOS::sprintf(m_Spool.m_Buf, "%-15s", tmp);
        m_Spool.Print();
        
        idlOS::sprintf(m_Spool.m_Buf, "\n");
        m_Spool.Print();
    }

    m_ISPApi->m_Column.freeMem();

    return IDE_SUCCESS;

    IDE_EXCEPTION(error);
    {
        m_ISPApi->m_Column.freeMem();

        idlOS::sprintf(m_Spool.m_Buf, "%s", m_ISPApi->GetErrorMsg());
        m_Spool.Print();

        if ( idlOS::strcmp(m_ISPApi->GetErrorState(), "08S01") == 0 )
        {
            DisconnectDB();
        }
    }
    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC 
iSQLExecuteCommand::ShowIndexInfo( SChar * a_UserName, 
                                   SChar * a_TableName )
{
    SInt  i;
    SChar      tmp[MSG_LEN];
    SChar      index_name[WORD_LEN];
    SInt       nIndexCount;
    IndexInfo *pIndexInfo = NULL;

    IDE_TEST_RAISE(m_ISPApi->Statistics(a_UserName, a_TableName, &nIndexCount, &pIndexInfo)
                   != IDE_SUCCESS, error);

    idlOS::sprintf(m_Spool.m_Buf, "\n");
    m_Spool.Print();
    idlOS::sprintf(m_Spool.m_Buf, "[ INDEX ]                                                       \n");
    m_Spool.Print();
    idlOS::sprintf(m_Spool.m_Buf, "------------------------------------------------------------------------------\n");
    m_Spool.Print();
    idlOS::sprintf(m_Spool.m_Buf, "NAME                                     TYPE     IS UNIQUE     COLUMN\n");
    m_Spool.Print();
    idlOS::sprintf(m_Spool.m_Buf, "------------------------------------------------------------------------------\n");
    m_Spool.Print();

    for (i=0; i<nIndexCount; i++)
    {
        idlOS::strcpy(tmp, pIndexInfo[i].IndexName);  
        idlOS::strcpy(index_name, tmp);

        if (pIndexInfo[i].OrdinalPos == 1)
        {
            if (i!=0)
            {
                idlOS::sprintf(m_Spool.m_Buf, "\n");
                m_Spool.Print();
            }

            idlOS::sprintf(m_Spool.m_Buf, "%-40s ", index_name);
            m_Spool.Print();

            idlOS::sprintf(m_Spool.m_Buf, "%-8s ", pIndexInfo[i].IndexType);
            m_Spool.Print();

            if ( pIndexInfo[i].NonUnique == ID_TRUE )
            {
                idlOS::strcpy(tmp, "");
            }
            else
            {
                idlOS::strcpy(tmp, "UNIQUE");
            }
            idlOS::sprintf(m_Spool.m_Buf, "%-13s ", tmp);
            m_Spool.Print();
            
            idlOS::sprintf(m_Spool.m_Buf, "%s ", pIndexInfo[i].ColumnName);
            m_Spool.Print();
            
            if ( pIndexInfo[i].SortAsc == ID_TRUE )
            {
                idlOS::sprintf(m_Spool.m_Buf, "ASC");
                m_Spool.Print();
            }
            else
            {
                idlOS::sprintf(m_Spool.m_Buf, "DESC");
                m_Spool.Print();
            }
        }
        else //if (pIndexInfo[i].m_OrdinalPos > 1)
        {
            idlOS::sprintf(m_Spool.m_Buf, ",\n");
            m_Spool.Print();
            idlOS::sprintf(m_Spool.m_Buf, "                                                                %s ", pIndexInfo[i].ColumnName);
            m_Spool.Print();

            if ( pIndexInfo[i].SortAsc == ID_TRUE )
            {
                idlOS::sprintf(m_Spool.m_Buf, "ASC");
                m_Spool.Print();
            }
            else
            {
                idlOS::sprintf(m_Spool.m_Buf, "DESC");
                m_Spool.Print();
            }
        }
    }

    idlOS::sprintf(m_Spool.m_Buf, "\n");
    m_Spool.Print();

    return IDE_SUCCESS;

    IDE_EXCEPTION(error);
    {
        idlOS::sprintf(m_Spool.m_Buf, "%s", m_ISPApi->GetErrorMsg());
        m_Spool.Print();

        if ( idlOS::strcmp(m_ISPApi->GetErrorState(), "08S01") == 0 )
        {
            DisconnectDB();
        }
    }
    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC 
iSQLExecuteCommand::ShowPrimaryKeys( SChar * a_UserName, 
                                     SChar * a_TableName )
{
    SInt  i;
    SInt  pk_col_cnt;
    SChar tmp[MSG_LEN];
    SChar pk[QC_MAX_KEY_COLUMN_COUNT][QP_MAX_NAME_LEN+1];

    IDE_TEST_RAISE(m_ISPApi->PrimaryKeys(a_UserName, a_TableName, pk, &pk_col_cnt)
                   != IDE_SUCCESS, error);

    idlOS::sprintf(m_Spool.m_Buf, "\n");
    m_Spool.Print();
    idlOS::sprintf(m_Spool.m_Buf, "[ PRIMARY KEY ]                                                 \n");
    m_Spool.Print();
    idlOS::sprintf(m_Spool.m_Buf, "------------------------------------------------------------------------------\n");
    m_Spool.Print();

    for (i=0; i<pk_col_cnt; i++)
    {
        if (i == 0)
        {
            idlOS::strcpy(tmp, pk[i]);
        }
        else 
        {
            idlOS::strcat(tmp, ", ");    
            idlOS::strcat(tmp, pk[i]);
        }
    }
    
    idlOS::sprintf(m_Spool.m_Buf, "%s\n", tmp);
    m_Spool.Print();

    return IDE_SUCCESS;

    IDE_EXCEPTION(error);
    {
        idlOS::sprintf(m_Spool.m_Buf, "%s", m_ISPApi->GetErrorMsg());
        m_Spool.Print();

        if ( idlOS::strcmp(m_ISPApi->GetErrorState(), "08S01") == 0 )
        {
            DisconnectDB();
        }
    }
    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC 
iSQLExecuteCommand::ShowForeignKeys( SChar * a_UserName, 
                                     SChar * a_TableName )
{
    SChar     sPKStr[256];
    SChar     sFKStr[256];
    SChar     sPKSchema[QP_MAX_NAME_LEN+1];
    SChar     sPKTableName[QP_MAX_NAME_LEN+1];
    SChar     sPKColumnName[QP_MAX_NAME_LEN+1];
    SChar     sPKName[QP_MAX_NAME_LEN+1];
    SChar     sFKSchema[QP_MAX_NAME_LEN+1];
    SChar     sFKTableName[QP_MAX_NAME_LEN+1];
    SChar     sFKColumnName[QP_MAX_NAME_LEN+1];
    SChar     sFKName[QP_MAX_NAME_LEN+1];
    SShort    sKeySeq;
    SQLRETURN rc;
    SInt      sFirst = 1;

    idlOS::sprintf(m_Spool.m_Buf, "\n");
    m_Spool.Print();
    idlOS::sprintf(m_Spool.m_Buf, "[ FOREIGN KEYS ]                                                 \n");
    m_Spool.Print();
    idlOS::sprintf(m_Spool.m_Buf, "------------------------------------------------------------------------------\n");
    m_Spool.Print();

    IDE_TEST_RAISE( m_ISPApi->ForeignKeys(a_UserName, a_TableName,
                                          FOREIGNKEY_PK,
                                          sPKSchema,
                                          sPKTableName,
                                          sPKColumnName,
                                          sPKName,
                                          sFKSchema,
                                          sFKTableName,
                                          sFKColumnName,
                                          sFKName,
                                          &sKeySeq)
                    != IDE_SUCCESS, error );

    sFirst = 1;
    while ( ( rc = m_ISPApi->FetchNext() ) == SQL_SUCCESS )
    {
        if ( sKeySeq == 1 )
        {
            if ( sFirst != 1 )
            {
                sFirst = 1;
                idlOS::strcat( sPKStr, " )" );
                idlOS::strcat( sFKStr, " )" );
                idlOS::sprintf(m_Spool.m_Buf, "%-34s", sPKStr);
                m_Spool.Print();
                idlOS::sprintf(m_Spool.m_Buf, "<---  ");
                m_Spool.Print();
                idlOS::sprintf(m_Spool.m_Buf, "%-35s\n", sFKStr);
                m_Spool.Print();
            }
            idlOS::sprintf(m_Spool.m_Buf, "* %-32s      * %-33s\n", sPKName, sFKName);
            m_Spool.Print();
            idlOS::sprintf( sPKStr, "( %s", sPKColumnName );
            idlOS::sprintf( sFKStr, "%s.%s ( %s",
                            sFKSchema, sFKTableName, sFKColumnName );
        }
        else
        {
            idlOS::strcat( sPKStr, ", " );
            idlOS::strcat( sPKStr, sPKColumnName );
            idlOS::strcat( sFKStr, ", " );
            idlOS::strcat( sFKStr, sFKColumnName );
        }
        sFirst = 0;
    }
    if ( sFirst != 1 )
    {
        idlOS::strcat( sPKStr, " )" );
        idlOS::sprintf(m_Spool.m_Buf, "%-34s", sPKStr);
        m_Spool.Print();
        idlOS::sprintf(m_Spool.m_Buf, "<---  ");
        m_Spool.Print();

        idlOS::strcat( sFKStr, " )" );
        idlOS::sprintf(m_Spool.m_Buf, "%-35s\n", sFKStr);
        m_Spool.Print();
    }

    IDE_TEST_RAISE( m_ISPApi->ForeignKeys(a_UserName, a_TableName,
                                          FOREIGNKEY_FK,
                                          sPKSchema,
                                          sPKTableName,
                                          sPKColumnName,
                                          sPKName,
                                          sFKSchema,
                                          sFKTableName,
                                          sFKColumnName,
                                          sFKName,
                                          &sKeySeq)
                    != IDE_SUCCESS, error );

    sFirst = 1;
    while ( ( rc = m_ISPApi->FetchNext() ) == SQL_SUCCESS )
    {
        if ( sKeySeq == 1 )
        {
            if ( sFirst != 1 )
            {
                sFirst = 1;
                idlOS::strcat( sPKStr, " )" );
                idlOS::strcat( sFKStr, " )" );
                idlOS::sprintf(m_Spool.m_Buf, "%-34s", sFKStr);
                m_Spool.Print();
                idlOS::sprintf(m_Spool.m_Buf, "--->  ");
                m_Spool.Print();
                idlOS::sprintf(m_Spool.m_Buf, "%-35s\n", sPKStr);
                m_Spool.Print();
            }
            idlOS::sprintf(m_Spool.m_Buf, "* %-32s      * %-33s\n", sFKName, sPKName);
            m_Spool.Print();
            idlOS::sprintf( sFKStr, "( %s", sFKColumnName );
            idlOS::sprintf( sPKStr, "%s.%s ( %s",
                            sPKSchema, sPKTableName, sPKColumnName );
        }
        else
        {
            idlOS::strcat( sFKStr, ", " );
            idlOS::strcat( sFKStr, sFKColumnName );
            idlOS::strcat( sPKStr, ", " );
            idlOS::strcat( sPKStr, sPKColumnName );
        }
        sFirst = 0;
    }
    if ( sFirst != 1 )
    {
        idlOS::strcat( sFKStr, " )" );
        idlOS::sprintf(m_Spool.m_Buf, "%-34s", sFKStr);
        m_Spool.Print();
        idlOS::sprintf(m_Spool.m_Buf, "--->  ");
        m_Spool.Print();
        idlOS::strcat( sPKStr, " )" );
        idlOS::sprintf(m_Spool.m_Buf, "%-35s\n", sPKStr);
        m_Spool.Print();
    }

    m_ISPApi->StmtClose();

    return IDE_SUCCESS;

    IDE_EXCEPTION( error );
    {
        idlOS::sprintf(m_Spool.m_Buf, "%s", m_ISPApi->GetErrorMsg());
        m_Spool.Print();

        if ( idlOS::strcmp(m_ISPApi->GetErrorState(), "08S01") == 0 )
        {
            DisconnectDB();
        }
    }
    IDE_EXCEPTION_END;

    m_ISPApi->StmtClose();

    return IDE_FAILURE;
}

IDE_RC 
iSQLExecuteCommand::ExecuteDDLStmt( SChar           * a_CommandStr, 
                                    SChar           * a_DDLStmt, 
                                    iSQLCommandKind   a_CommandKind )
{
    idlOS::sprintf(m_Spool.m_Buf, "%s", a_CommandStr);  
    m_Spool.PrintCommand();

    m_ISPApi->SetQuery(a_DDLStmt);

    if ( gProperty.GetTiming() == ID_TRUE )
    {    
        m_uttTime.reset();
        m_uttTime.start();
    }
    
    IDE_TEST_RAISE(m_ISPApi->DirectExecute() != IDE_SUCCESS, error);

    if ( gProperty.GetTiming() == ID_TRUE )
    {    
        m_uttTime.finish();    
    }
    
    switch (a_CommandKind)
    {
    case CRT_OBJ_COM  :
    case CRT_PROC_COM :
        idlOS::sprintf(m_Spool.m_Buf, "Create success.\n");
        break;
    case ALTER_COM :
        idlOS::sprintf(m_Spool.m_Buf, "Alter success.\n");
        break;
    case DROP_COM :
        idlOS::sprintf(m_Spool.m_Buf, "Drop success.\n");
        break;
    case GRANT_COM :
        idlOS::sprintf(m_Spool.m_Buf, "Grant success.\n");
        break;
    case LOCK_COM :
        idlOS::sprintf(m_Spool.m_Buf, "Lock success.\n");
        break;
    case RENAME_COM :
        idlOS::sprintf(m_Spool.m_Buf, "Rename success.\n");
        break;
    case REVOKE_COM :
        idlOS::sprintf(m_Spool.m_Buf, "Revoke success.\n");
        break;
    case TRUNCATE_COM :
        idlOS::sprintf(m_Spool.m_Buf, "Truncate success.\n");
        break;
    case SAVEPOINT_COM :
        idlOS::sprintf(m_Spool.m_Buf, "Savepoint success.\n");
        break;
    case COMMIT_COM :
        idlOS::sprintf(m_Spool.m_Buf, "Commit success.\n");
        break;
    case ROLLBACK_COM :
        idlOS::sprintf(m_Spool.m_Buf, "Rollback success.\n");
        break;
    default :
        break;
    }
    m_Spool.Print();
    
    if ( gProperty.GetTiming() == ID_TRUE )
    {    
        ShowElapsedTime();
    }

    m_ISPApi->StmtClose();

    return IDE_SUCCESS;

    IDE_EXCEPTION(error);
    {
        idlOS::sprintf(m_Spool.m_Buf, "%s", m_ISPApi->GetErrorMsg());
        m_Spool.Print();

        if ( idlOS::strcmp(m_ISPApi->GetErrorState(), "08S01") == 0 )
        {
            DisconnectDB();
        }
    }
    IDE_EXCEPTION_END;

    m_ISPApi->StmtClose();

    return IDE_FAILURE;
}

IDE_RC 
iSQLExecuteCommand::ExecuteDMLStmt( SChar           * a_CommandStr, 
                                    SChar           * a_DMLStmt, 
                                    iSQLCommandKind   a_CommandKind )
{
    SChar tmp1[WORD_LEN], tmp2[WORD_LEN];
    SInt  cnt;

    idlOS::sprintf(m_Spool.m_Buf, "%s", a_CommandStr);  
    m_Spool.PrintCommand();

    m_ISPApi->SetQuery(a_DMLStmt);

    if ( gProperty.GetTiming() == ID_TRUE )
    {    
        m_uttTime.reset();
        m_uttTime.start();
    }
    
    IDE_TEST_RAISE(m_ISPApi->DirectExecute() != IDE_SUCCESS, error);

    if ( gProperty.GetTiming() == ID_TRUE )
    {    
        m_uttTime.finish();    
    }
    
    IDE_TEST_RAISE(m_ISPApi->GetRowCount(&cnt) != IDE_SUCCESS, error);
    
    if (cnt == 0)
    {
        idlOS::strcpy(tmp1, (SChar*)"No rows");
    }
    else if (cnt == 1)
    {
        idlOS::strcpy(tmp1, (SChar*)"1 row");
    }
    else 
    {
        idlOS::sprintf(tmp1, (SChar*)"%d rows", cnt);
    }
    
    switch (a_CommandKind)
    {
    case INSERT_COM :
        idlOS::strcpy(tmp2, (SChar*)"inserted");
        break;
    case UPDATE_COM :
        idlOS::strcpy(tmp2, (SChar*)"updated");
        break;
    case DELETE_COM :
        idlOS::strcpy(tmp2, (SChar*)"deleted");
        break;
    case MOVE_COM :
        idlOS::strcpy(tmp2, (SChar*)"moved");
    default :
        break;
    }

    idlOS::sprintf(m_Spool.m_Buf, "%s %s.\n", tmp1, tmp2);
       m_Spool.Print();

    if ( gProperty.GetTiming() == ID_TRUE )
    {    
        ShowElapsedTime();
    }

    m_ISPApi->StmtClose();

    return IDE_SUCCESS;

    IDE_EXCEPTION(error);
    {
        idlOS::sprintf(m_Spool.m_Buf, "%s", m_ISPApi->GetErrorMsg());
        m_Spool.Print();

        if ( idlOS::strcmp(m_ISPApi->GetErrorState(), "08S01") == 0 )
        {
            DisconnectDB();
        }
    }
    IDE_EXCEPTION_END;

    m_ISPApi->StmtClose();

    return IDE_FAILURE;
}

idBool 
iSQLExecuteCommand::ExecuteSelectStmt( SChar * a_CommandStr, 
                                       SChar * szSelectStmt )
{
    m_ISPApi->SetQuery(szSelectStmt);
    idlOS::sprintf(m_Spool.m_Buf, "%s", a_CommandStr);  
    m_Spool.PrintCommand();

    if ( gProperty.GetTiming() == ID_TRUE )
    {    
        m_uttTime.reset();
        m_uttTime.start();
    }

    IDE_TEST_RAISE(m_ISPApi->SelectExecute() != 0, error);

    IDE_TEST( FetchSelectStmt(ID_FALSE) != IDE_SUCCESS );

    m_ISPApi->StmtClose(ID_FALSE);

    return ID_TRUE;

    IDE_EXCEPTION(error);
    {
        if (idlOS::strncmp(m_ISPApi->GetErrorState(), "08S01", 5) == 0)
        {
            idlOS::sprintf(m_Spool.m_Buf,
                           "%s",
                           (char*)"Communication failure.\nConnection closed.\n");  
            m_Spool.Print();
            DisconnectDB();
            exit(0);
        }
        idlOS::sprintf(m_Spool.m_Buf, "%s", m_ISPApi->GetErrorMsg());  
        m_Spool.Print();
        
    }
    IDE_EXCEPTION_END;

    m_ISPApi->StmtClose(ID_FALSE);

    return ID_FALSE;
}

IDE_RC 
iSQLExecuteCommand::FetchSelectStmt(idBool aPrepare)
{
    int *nDisplayPos;
    int *ColSize;
    int *Header_row;
    int *space;
    int  nLen, i, j, k, p, q;
    int  curr;
    idBool bRowPrintComplete;
    int    nResult;
    SChar  tmp[WORD_LEN];
    char  *sPlanTree;
    SInt   sColSize;

    sColSize    = gProperty.GetColSize();
    nDisplayPos = new int [m_ISPApi->m_Column.GetSize()];
    ColSize     = new int [m_ISPApi->m_Column.GetSize()];
    Header_row  = new int [m_ISPApi->m_Column.GetSize()];
    space       = new int [m_ISPApi->m_Column.GetSize()];

    for (i=0; i < m_ISPApi->m_Column.GetSize(); i++)
    {
        switch (m_ISPApi->m_Column.GetType(i))
        {
        case SQL_CHAR :
        case SQL_VARCHAR :
            ColSize[i] = m_ISPApi->m_Column.GetPrecision(i);
            if ( sColSize > 0 && ColSize[i] > sColSize )
            {
                ColSize[i] = sColSize;
            }
            break;
        case SQL_SMALLINT :
        case SQL_INTEGER :
        case SQL_NUMERIC :
        case SQL_DECIMAL :
        case SQL_FLOAT :
            ColSize[i] = 11;
            break;
        case SQL_DOUBLE :
            ColSize[i] = 22;
            break;
        case SQL_REAL :
            ColSize[i] = 13;
            break;
        case SQL_BIGINT :
        case SQL_INTERVAL :
            ColSize[i] = 20;
            break;
        case SQL_TYPE_DATE :
        case SQL_DATE :
            ColSize[i] = 20;
            break;
        case SQL_NATIVE_TIMESTAMP :
            ColSize[i] = 30;
            break;
        case SQL_BYTES :
        case SQL_NIBBLE :
            ColSize[i] = m_ISPApi->m_Column.GetPrecision(i)*2;
            break;
        default :
            ColSize[i] = 0;
            break;
        }
    }
    
    if (gProperty.GetPageSize() == 0)
    {
        PrintHeader(ColSize, Header_row, space);
    }
        
    int m = 0;
    for (k = 0; (nResult = m_ISPApi->Fetch(aPrepare)) != SQL_NO_DATA_FOUND; k++)
    {    
        if((gProperty.GetPageSize() != 0) && ((m % gProperty.GetPageSize()) == 0)) 
        {
            PrintHeader(ColSize, Header_row, space);
        }
        m++;
        
        if (nResult != 0)
        {
            if (idlOS::strncmp(m_ISPApi->GetErrorState(), "08S01", 5) == 0)
            {
                idlOS::sprintf(m_Spool.m_Buf,
                               "%s",
                               (char*)"Communication failure.\nConnection closed.\n");  
                m_Spool.Print();
                DisconnectDB();
                exit(0);
            }
            idlOS::sprintf(m_Spool.m_Buf, "%s", m_ISPApi->GetErrorMsg());
            m_Spool.Print();
            break;
        }
        
        bRowPrintComplete = ID_FALSE;
        for (i=0; i < m_ISPApi->m_Column.GetSize(); i++)
        {
            nDisplayPos[i] = 0;
        }
        j = 0;
        
        while (bRowPrintComplete == ID_FALSE)
        {
            bRowPrintComplete = ID_TRUE;
            p = 0, q = 0;
            for (i=0; i < m_ISPApi->m_Column.GetSize(); i++)
            {
                if (nDisplayPos[i] == -1)
                {
                    curr = j;
                    int sEmptyColSize = curr+ColSize[i];
                    switch (m_ISPApi->m_Column.GetType(i))
                    {
                    case SQL_NUMERIC :
                    case SQL_DECIMAL :
                    case SQL_SMALLINT :
                    case SQL_INTEGER :
                    case SQL_BIGINT :
                    case SQL_FLOAT :
                    case SQL_TYPE_DATE :
                    case SQL_DATE :
                    case SQL_NATIVE_TIMESTAMP :
                    case SQL_INTERVAL :
                        --sEmptyColSize;
                        break;
                    default :
                        break;
                    }
                    for (j = curr; j <= sEmptyColSize; j++)
                    {
                        m_Spool.m_Buf[j] = ' ';
                    }
                    m_Spool.m_Buf[j++] = ' ';
                    //m_Spool.m_Buf[j] = '\0';
                    //m_Spool.Print();
                    continue;
                }
                if (Header_row[q] > p++)
                {
                    switch (m_ISPApi->m_Column.GetType(i))
                    {
                    case SQL_CHAR :
                        if (nDisplayPos[i] == 0)
                        {
                            gString.removeLastSpace(m_ISPApi->m_Column.m_CValue[i]);
                        }
                    case SQL_BYTES :
                    case SQL_NIBBLE :
                    case SQL_VARCHAR :
                        nLen = idlOS::strlen(m_ISPApi->m_Column.m_CValue[i]);
                        curr = j;
                        for (j = curr; j <= curr+ColSize[i]; j++)
                        {
                            if (nDisplayPos[i] < nLen)
                            {
                                if ((j-curr == ColSize[i]) &&
                                    ((m_Spool.m_Buf[j-1] & 0x80) == 0))
                                {
                                    m_Spool.m_Buf[j] = ' ';
                                }
                                else
                                {
                                    m_Spool.m_Buf[j] = m_ISPApi->m_Column.m_CValue[i][nDisplayPos[i]++];
                                }
                            }
                            else
                            {
                                m_Spool.m_Buf[j] = ' ';
                            }
                        }
                        m_Spool.m_Buf[j++] = ' ';
                        //m_Spool.m_Buf[j] = '\0';
                        //m_Spool.Print();
                        if (nDisplayPos[i] < nLen)
                        {
                            bRowPrintComplete = ID_FALSE;
                        }
                        else
                        {
                            nDisplayPos[i] = -1;
                        }
                        break;
                    case SQL_DOUBLE :
                        if ( m_ISPApi->m_Column.m_Len[i] != SQL_NULL_DATA )
                        {
                            m_Spool.m_DoubleBuf = m_ISPApi->m_Column.m_Value[i].DValue;
                            m_Spool.PrintWithDouble(&j);
                            if ( ColSize[i] > 22 )
                            {
                                curr = j;
                                for (j=curr; j<=curr+ColSize[i]-(22); j++)
                                {
                                    m_Spool.m_Buf[j] = ' ';
                                }
                                //m_Spool.m_Buf[j] = '\0';
                                //m_Spool.Print();
                            }
                            else
                            {
                                m_Spool.m_Buf[j++] = ' ';
                                //m_Spool.m_Buf[1] = '\0';
                                //m_Spool.Print();
                            }
                        }
                        else
                        {
                            curr = j;
                            for (j=curr; j<=curr+ColSize[i]; j++)
                            {
                                m_Spool.m_Buf[j] = ' ';
                            }
                            //m_Spool.m_Buf[j] = '\0';
                            //m_Spool.Print();
                        }
                        nDisplayPos[i] = -1;
                        break;
                    case SQL_REAL :
                        if ( m_ISPApi->m_Column.m_Len[i] != SQL_NULL_DATA )
                        {
                            m_Spool.m_FloatBuf = m_ISPApi->m_Column.m_Value[i].FValue;
                            m_Spool.PrintWithFloat(&j);
                            if ( ColSize[i] > 13 )
                            {
                                curr = j;
                                for (j=curr; j<=curr+ColSize[i]-(13); j++)
                                {
                                    m_Spool.m_Buf[j] = ' ';
                                }
                                //m_Spool.m_Buf[j] = '\0';
                                //m_Spool.Print();
                            }
                            else
                            {
                                m_Spool.m_Buf[j++] = ' ';
                                //m_Spool.m_Buf[1] = '\0';
                                //m_Spool.Print();
                            }
                        }
                        else
                        {
                            curr = j;
                            for (j=curr; j<=curr+ColSize[i]; j++)
                            {
                                m_Spool.m_Buf[j] = ' ';
                            }
                            //m_Spool.m_Buf[j] = '\0';
                            //m_Spool.Print();
                        }
                        nDisplayPos[i] = -1;
                        break;
                    case SQL_NUMERIC :
                    case SQL_DECIMAL :
                    case SQL_SMALLINT :
                    case SQL_INTEGER :
                    case SQL_BIGINT :
                    case SQL_FLOAT :
                    case SQL_TYPE_DATE :
                    case SQL_DATE :
                    case SQL_NATIVE_TIMESTAMP :
                    case SQL_INTERVAL :
                        nLen = idlOS::strlen(m_ISPApi->m_Column.m_CValue[i]);
                        curr = j;
                        for (j = curr; j < curr+ColSize[i]; j++)
                        {
                            if (nDisplayPos[i] < nLen)
                            {
                                m_Spool.m_Buf[j] = m_ISPApi->m_Column.m_CValue[i][nDisplayPos[i]++];
                            }
                            else
                            {
                                m_Spool.m_Buf[j] = ' ';
                            }
                        }
                        m_Spool.m_Buf[j++] = ' ';
                        //m_Spool.m_Buf[j] = '\0';
                        //m_Spool.Print();
                        nDisplayPos[i] = -1;
                        break;
                    case SQL_NULL :
                        m_Spool.m_Buf[j++] = ' ';
                        //m_Spool.m_Buf[1] = '\0';
                        //m_Spool.Print();
                        nDisplayPos[i] = -1;
                        break;
                    default :
                        idlOS::sprintf(m_Spool.m_Buf, "unknown type\n");
                        //m_Spool.Print();
                        nDisplayPos[i] = -1;
                        break;
                    }
                }
                else
                {
                    //idlOS::sprintf(m_Spool.m_Buf, "\n");    
                    m_Spool.m_Buf[j++] = '\n';
                    m_Spool.m_Buf[j] = '\0';
                    m_Spool.Print();
                    j = 0;
                    i--; q++; p=0;
                }
            }    /* for loop */
            //idlOS::sprintf(m_Spool.m_Buf, "\n");    
            m_Spool.m_Buf[j++] = '\n';
            m_Spool.m_Buf[j] = '\0';
            m_Spool.Print();
            j = 0;
        }    /* while loop */
    }    /* for loop */

    if ( gProperty.GetTiming() == ID_TRUE )
    {    
        m_uttTime.finish();    
    }
    
    if (k == 0)
    {
        idlOS::strcpy(tmp, (SChar*)"No rows");
    }
    else if (k == 1)
    {
        idlOS::strcpy(tmp, (SChar*)"1 row");
    }
    else 
    {
        idlOS::sprintf(tmp, (SChar*)"%d rows", k);
    }
    idlOS::sprintf(m_Spool.m_Buf, "%s selected.\n", tmp);
    m_Spool.Print();

    if ( m_ISPApi->GetPlanTree( & sPlanTree, aPrepare ) == IDE_SUCCESS )
    {
        if ( sPlanTree != NULL )
        {
            idlOS::sprintf( m_Spool.m_Buf, "%s\n", sPlanTree );
            m_Spool.Print();
        }
        else
        {
            // no plan tree
        }
    }
    
    if ( gProperty.GetTiming() == ID_TRUE )
    {    
        m_ElapsedTime = m_uttTime.getMilliSeconds(UTT_WALL_TIME)/1000;
        idlOS::sprintf(m_Spool.m_Buf, "elapsed time : %.2f\n", m_ElapsedTime);
        m_Spool.Print();
    }
        
    delete [] ColSize;
    delete [] nDisplayPos;
    delete [] Header_row;
    delete [] space;
    m_ISPApi->m_Column.freeMem();

    return IDE_SUCCESS;
}

IDE_RC 
iSQLExecuteCommand::ExecutePSMStmt( SChar * a_CommandStr, 
                                    SChar * a_PSMStmt, 
                                    SChar * a_UserName, 
                                    SChar * a_ProcName, 
                                    idBool  a_IsFunc )
{
    SShort inout_type;
    SShort data_type;
    SShort para_order;
    SInt   inout_type_len;
    SInt   data_type_len;
    SInt   para_order_len;
    
    SShort  c_type;
    SInt    precision = 0;
    SInt    max_value = 0;
    SInt   *len = NULL;
    
    HostVarNode *t_node, *s_node, *r_node;
    SQLRETURN    nResult;
    SInt         i, j=0;
    SInt         bind_cnt;
    idlOS::sprintf(m_Spool.m_Buf, "%s", a_CommandStr);  
    m_Spool.PrintCommand();

    m_ISPApi->SetQuery(a_PSMStmt);

    if ( idlOS::strlen(a_UserName) == 0 )
    {
        idlOS::strcpy(a_UserName, gProperty.GetUserName());
    }

    r_node = gHostVarMgr.getBindList();
    t_node = r_node;
        
    bind_cnt = gHostVarMgr.getBindListCnt();
    if (bind_cnt != 0)
    {
        IDE_TEST_RAISE( (len = (SInt*) idlOS::malloc(sizeof(SInt)*bind_cnt))
                        == NULL, mem_alloc_error );
        memset( len, 0x00, sizeof(SInt)*bind_cnt );
    }

    if ( gProperty.GetTiming() == ID_TRUE )
    {    
        m_uttTime.reset();
        m_uttTime.start();
    }

    IDE_TEST_RAISE(m_ISPApi->Prepare() != IDE_SUCCESS, error);

    if (t_node == NULL)
    {
        goto no_bind_para;
    }


    IDE_TEST_RAISE(m_ISPApi->GetProcInfo(a_UserName, a_ProcName, &inout_type, 
                                        &inout_type_len, &data_type, 
                                        &data_type_len, &para_order, 
                                        &para_order_len) != IDE_SUCCESS, error);

    for (i=1; ; )
    {
        if (i==1 && a_IsFunc)
        {
            IDE_TEST_RAISE(m_ISPApi->GetReturnType(a_UserName, a_ProcName, 
                                                   &data_type, &data_type_len)
                           != SQL_SUCCESS, error);
            inout_type = SQL_PARAM_OUTPUT;
            para_order = 1;
        }
        else
        {
            nResult = m_ISPApi->FetchProcInfo();
            if (nResult == SQL_NO_DATA) break;
            IDE_TEST_RAISE(nResult != SQL_SUCCESS, error);
        }

        if (t_node == NULL)
        {
            break;
        }

        // para_order는 함수나 프로시저의 create 시 파라미터 순서
        // order는 bindpara 시 순서
        if (t_node->element.para_order == para_order)   // exec proc1(:a, :b, :c), exec proc1(:a, 'a', :b)
        {
            if (t_node->element.assigned)
            {
                len[j] = SQL_NTS;
            }
            else
            {
                len[j] = SQL_NULL_DATA;
            }

            if ( (inout_type == SQL_PARAM_OUTPUT) ||
                 (inout_type == SQL_PARAM_INPUT_OUTPUT && !t_node->element.assigned) )
            {
                t_node->element.assigned = ID_TRUE;
            }

            switch (t_node->element.type)
            {
            case iSQL_DOUBLE :
                c_type = SQL_C_DOUBLE;
                max_value = sizeof(t_node->element.d_value);
                IDE_TEST_RAISE(m_ISPApi->ProcBindPara(i++, inout_type,
                                                      c_type, data_type, 0, 
                                                      &(t_node->element.d_value),
                                                      max_value, &(len[j++]))
                               != IDE_SUCCESS, error);
                break;
            case iSQL_REAL :
                c_type = SQL_C_FLOAT;
                max_value = sizeof(t_node->element.f_value);
                IDE_TEST_RAISE(m_ISPApi->ProcBindPara(i++, inout_type,
                                                      c_type, data_type, 0, 
                                                      &(t_node->element.f_value),
                                                      max_value, &(len[j++]))
                              != IDE_SUCCESS, error);
                break;
            case iSQL_BLOB :
                c_type = SQL_C_BINARY;
                max_value = t_node->element.precision+1;
                if (t_node->element.precision<0)
                {
                    precision = 1;
                }
                else
                {
                    precision = t_node->element.precision;
                }
                IDE_TEST_RAISE(m_ISPApi->ProcBindPara(i++, inout_type,
                                                      c_type, data_type, precision, 
                                                      t_node->element.c_value,
                                                      max_value, &(len[j++]))
                               != IDE_SUCCESS, error);
                break;
            default :
                c_type = SQL_C_CHAR;
                if ( t_node->element.type == iSQL_CHAR       || 
                     t_node->element.type == iSQL_VARCHAR    || 
                     t_node->element.type == iSQL_NIBBLE || 
                     t_node->element.type == iSQL_BLOB ) 
                {
                    max_value = t_node->element.precision+1;
                }
                else if ( t_node->element.type == iSQL_BYTE )
                {
                    max_value = t_node->element.size + 1;
                }
                else
                {
                    max_value = 21+1;//BIGINT_SIZE+1;
                    t_node->element.precision = 21;
                }
                
                if (t_node->element.precision<0)
                {
                    precision = 1;
                }
                else
                {
                    precision = t_node->element.precision;
                }

                IDE_TEST_RAISE(m_ISPApi->ProcBindPara(i++, inout_type,
                                                      c_type, data_type, precision, 
                                                      t_node->element.c_value,
                                                      max_value, &(len[j++]))
                               != IDE_SUCCESS, error);
                break;
            }
            s_node = t_node;
            t_node = s_node->host_var_next;
        }
    }

no_bind_para:
    IDE_TEST_RAISE(m_ISPApi->Execute() != IDE_SUCCESS, error);

    if ( gProperty.GetTiming() == ID_TRUE )
    {    
        m_uttTime.finish();    
    }
    
    if (r_node != NULL)
    {
        gHostVarMgr.setHostVar(r_node); // BUGBUG : r_node 는 불필요한 parameter
    }

    idlOS::sprintf(m_Spool.m_Buf, "Execute success.\n");
    m_Spool.Print();
    
    if ( gProperty.GetTiming() == ID_TRUE )
    {    
        ShowElapsedTime();
    }

    if (len != NULL)
    {
        idlOS::free(len);
    }
    
    m_ISPApi->StmtClose(ID_TRUE);

    return IDE_SUCCESS;

    IDE_EXCEPTION(error);
    {
        if (len != NULL)
        free(len);

        idlOS::sprintf(m_Spool.m_Buf, "%s", m_ISPApi->GetErrorMsg());
        m_Spool.Print();

        if ( idlOS::strcmp(m_ISPApi->GetErrorState(), "08S01") == 0 )
        {
            DisconnectDB();
        }
    }

    IDE_EXCEPTION(mem_alloc_error);
    {
        if (len != NULL)
        {
            idlOS::free(len);
        }

        idlOS::fprintf(stderr, "Memory allocation error!!! --- (%d, %s)\n",
                       __LINE__, __FILE__);
        exit(0);
    }

    IDE_EXCEPTION_END;

    m_ISPApi->StmtClose(ID_TRUE);

    return IDE_FAILURE;
}

IDE_RC 
iSQLExecuteCommand::ExecuteConnectStmt( SChar * a_CommandStr, 
                                        SChar * a_Host, 
                                        SChar * a_UserName, 
                                        SChar * a_Passwd, 
                                        SChar * a_NLS, 
                                        SInt    a_Port, 
                                        SInt    a_Conntype )
{
    idlOS::sprintf(m_Spool.m_Buf, "%s", a_CommandStr);  
    m_Spool.PrintCommand();

    m_ISPApi->Close();

    IDE_TEST_RAISE(m_ISPApi->Open(a_Host, a_UserName, a_Passwd,
                                  a_NLS, a_Port,
                                  a_Conntype, &gMessageCallbackStruct)
                  != IDE_SUCCESS, error);

    idlOS::sprintf(m_Spool.m_Buf, "Connect success.\n");
    m_Spool.Print();
    
    gProperty.SetUserName(a_UserName);

    return IDE_SUCCESS;

    IDE_EXCEPTION(error);
    {
        idlOS::sprintf(m_Spool.m_Buf, "%s", m_ISPApi->GetErrorMsg());
        m_Spool.Print();
        gProperty.SetUserName((SChar*)"");
    }

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

void 
iSQLExecuteCommand::ExecuteDisconnectStmt(
        SChar * a_CommandStr, idBool aDisplayMode ) 
{
    idlOS::sprintf(m_Spool.m_Buf, "%s", a_CommandStr);  
    m_Spool.PrintCommand();

    m_ISPApi->Close();

    if ( aDisplayMode == ID_TRUE )
    {
        idlOS::sprintf(m_Spool.m_Buf, "Disconnect success.\n");
        m_Spool.Print();
    }

    gProperty.SetUserName((SChar*)"");
}

IDE_RC 
iSQLExecuteCommand::ExecuteAutoCommitStmt( SChar * a_CommandStr, 
                                           idBool  a_IsAutoCommitOn )
{
    idlOS::sprintf(m_Spool.m_Buf, "%s", a_CommandStr);  
    m_Spool.PrintCommand();

    IDE_TEST_RAISE(m_ISPApi->AutoCommit(a_IsAutoCommitOn) != IDE_SUCCESS, error);

    if ( a_IsAutoCommitOn == ID_TRUE )
    {
        idlOS::sprintf(m_Spool.m_Buf, "Set autocommit on success.\n");
    }
    else
    {
        idlOS::sprintf(m_Spool.m_Buf, "Set autocommit off success.\n");
    }
    m_Spool.Print();

    return IDE_SUCCESS;

    IDE_EXCEPTION(error);
    {
        idlOS::sprintf(m_Spool.m_Buf, "%s", m_ISPApi->GetErrorMsg());
        m_Spool.Print();

        if ( idlOS::strcmp(m_ISPApi->GetErrorState(), "08S01") == 0 )
        {
            DisconnectDB();
        }
    }

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}
void 
iSQLExecuteCommand::ExecuteSpoolStmt( SChar        * a_FileName,
                                      iSQLPathType   a_PathType )
{
    SChar  *sHomePath = NULL;
    SChar   filename[WORD_LEN];

    idlOS::strcpy(filename, "");
    if ( a_PathType == ISQL_PATH_HOME )
    {
        sHomePath = idlOS::getenv("ALTIBASE_HOME");
        IDE_TEST( sHomePath == NULL );
        idlOS::strcpy(filename, sHomePath);
    }

    idlOS::strcat(filename, a_FileName);
    if ( idlOS::strchr(filename, '.') == NULL )
    {
        idlOS::strcat(filename, ".lst");
    }

    m_Spool.SetSpoolFile(filename); 
    return;

    IDE_EXCEPTION_END;

    idlOS::sprintf(m_Spool.m_Buf, "%s", "Set environment ALTIBASE_HOME");
    m_Spool.Print();

    return;
}

void 
iSQLExecuteCommand::ExecuteSpoolOffStmt()
{
    m_Spool.SpoolOff();
}
void 
iSQLExecuteCommand::ExecuteEditStmt(
        SChar        * a_InFileName, 
        iSQLPathType   a_PathType,
        SChar        * a_OutFileName )
{
    SChar  *sHomePath = NULL;
    SChar   editCommand[WORD_LEN];
    SChar   sysCommand[WORD_LEN];

    if (idlOS::getenv("ISQL_EDITOR"))
    {
        idlOS::strcpy(editCommand, idlOS::getenv("ISQL_EDITOR"));
    }
    else
    {
#if !defined(VC_WIN32)
        idlOS::strcpy(editCommand, "/bin/vi");
#else
        idlOS::strcpy(editCommand, "notepad.exe");
#endif /* VC_WIN32 */
    }
    if ( a_PathType == ISQL_PATH_HOME )
    {
        sHomePath = idlOS::getenv("ALTIBASE_HOME");
        IDE_TEST( sHomePath == NULL );
    }

    if ( idlOS::strlen(a_InFileName) == 0 )
    {
        idlOS::sprintf(sysCommand, "%s %s", editCommand, ISQL_BUF);
        idlOS::strcpy(a_OutFileName, ISQL_BUF);
    }
    else
    {
        idlOS::sprintf(sysCommand, "%s ", editCommand);
        if ( a_PathType == ISQL_PATH_HOME )
        {
            idlOS::strcat(sysCommand, sHomePath);
        }
        if ( idlOS::strchr(a_InFileName, '.') != NULL )
        {
            idlOS::strcat(sysCommand, a_InFileName);
        }
        else
        {
            idlOS::strcat(sysCommand, a_InFileName);
            idlOS::strcat(sysCommand, ".sql");
        }
        idlOS::strcpy(a_OutFileName, a_InFileName);
    }

    idlOS::system(sysCommand);

    return;

    IDE_EXCEPTION_END;

    idlOS::sprintf(m_Spool.m_Buf, "%s", "Set environment ALTIBASE_HOME");
    m_Spool.Print();

    return;
}

void 
iSQLExecuteCommand::ExecuteShellStmt( SChar * a_ShellStmt )
{
    if ( (!a_ShellStmt) || (idlOS::strlen(a_ShellStmt) == 0) )
    {
        idlOS::system("/bin/sh");
    }
    else 
    {
        idlOS::system(a_ShellStmt);
    }
}

IDE_RC 
iSQLExecuteCommand::ExecuteOtherCommandStmt( SChar * a_CommandStr, 
                                             SChar * a_OtherCommandStmt )
{
    idlOS::sprintf(m_Spool.m_Buf, "%s", a_CommandStr);  
    m_Spool.PrintCommand();

    m_ISPApi->SetQuery(a_OtherCommandStmt);

    if ( gProperty.GetTiming() == ID_TRUE )
    {    
        m_uttTime.reset();
        m_uttTime.start();
    }
    
    IDE_TEST_RAISE(m_ISPApi->DirectExecute() != IDE_SUCCESS, error);

    if ( gProperty.GetTiming() == ID_TRUE )
    {    
        m_uttTime.finish();    
    }
    
    idlOS::sprintf(m_Spool.m_Buf, "Command execute success.\n");
    m_Spool.Print();
    
    if ( gProperty.GetTiming() == ID_TRUE )
    {    
        ShowElapsedTime();
    }

    m_ISPApi->StmtClose();

    return IDE_SUCCESS;

    IDE_EXCEPTION(error);
    {
        idlOS::sprintf(m_Spool.m_Buf, "%s", m_ISPApi->GetErrorMsg());
        m_Spool.Print();

        if ( idlOS::strcmp(m_ISPApi->GetErrorState(), "08S01") == 0 )
        {
            DisconnectDB();
        }
    }

    IDE_EXCEPTION_END;

    m_ISPApi->StmtClose();

    return IDE_FAILURE;
}

IDE_RC 
iSQLExecuteCommand::PrintHelpString(SChar * /*a_CommandStr*/, 
                                    iSQLCommandKind eHelpArguKind)
{
    iSQLHelp cHelp;

    idlOS::sprintf(m_Spool.m_Buf, cHelp.GetHelpString(eHelpArguKind));
    m_Spool.Print();
    return IDE_SUCCESS;
}

void 
iSQLExecuteCommand::PrintHeader( int * ColSize, 
                                 int * pg, 
                                 int * space )
{
    int i, j, k, a, p, q;
    int nLen, LineSize;
    LineSize = 0;
    p = 0, q = 0;
            
    for (i=0; i < m_ISPApi->m_Column.GetSize(); i++)
    {
        p++;
        space[i] = 0;
        nLen = idlOS::strlen(m_ISPApi->m_Column.GetName(i));
        if (nLen > ColSize[i])
        {
            for (j = 0; j < nLen; j++)
            {
                m_Spool.m_Buf[j] = m_ISPApi->m_Column.m_Name[i][j];
                if (j > ColSize[i])
                {
                    space[i]++;
                }
            }
            LineSize = LineSize + nLen;
        }
        else 
        {
            for (j = 0; j < ColSize[i]; j++)
            {    
                if (j < nLen)
                {
                    m_Spool.m_Buf[j] = m_ISPApi->m_Column.m_Name[i][j];
                }
                else
                {
                    m_Spool.m_Buf[j] = ' ';
                }
            }
            LineSize = LineSize + ColSize[i];
        }
        
        if ((m_ISPApi->m_Column.GetType(i) == SQL_CHAR) ||
            (m_ISPApi->m_Column.GetType(i) == SQL_VARCHAR) ||
            (m_ISPApi->m_Column.GetType(i) == SQL_NIBBLE) ||
            (m_ISPApi->m_Column.GetType(i) == SQL_BYTES))
        {
            m_Spool.m_Buf[j++] = ' ';
            ++LineSize;
        }
        m_Spool.m_Buf[j++] = ' ';
        m_Spool.m_Buf[j] = '\0';
        LineSize = LineSize + 2;
        
        if ( gProperty.GetHeading() == ID_TRUE )
        {
            m_Spool.Print();
        }
        
        if ( ( i < m_ISPApi->m_Column.GetSize() - 1 &&
               gProperty.GetLineSize() < LineSize + ColSize[i+1] ) ||
             ( i+1 == m_ISPApi->m_Column.GetSize() ) )
        {
            idlOS::sprintf(m_Spool.m_Buf, "\n");  
            m_Spool.Print();
                
            for (k=0, a=0; k<=LineSize; k++)
            {
                m_Spool.m_Buf[a++] = '-';
            }
            m_Spool.m_Buf[a++] = '\n';
            m_Spool.m_Buf[a++] = '\0';
            pg[q++] = p;
            LineSize = 0;
            p = 0;
            
            if ( gProperty.GetHeading() == ID_TRUE )
            {
                m_Spool.Print();
            }
        }
    }
}

void 
iSQLExecuteCommand::ShowHostVar( SChar * a_CommandStr )
{
    idlOS::sprintf(m_Spool.m_Buf, "%s", a_CommandStr);  
    m_Spool.PrintCommand();

    gHostVarMgr.print();
}

void 
iSQLExecuteCommand::ShowHostVar( SChar * a_CommandStr, 
                                 SChar * a_HostVarName )
{
    idlOS::sprintf(m_Spool.m_Buf, "%s", a_CommandStr);  
    m_Spool.PrintCommand();

    gHostVarMgr.showVar(a_HostVarName);
}

void 
iSQLExecuteCommand::ShowElapsedTime()
{
    switch (gProperty.GetTimeScale())
    {
    case iSQL_SEC :
        m_ElapsedTime = m_uttTime.getSeconds(UTT_WALL_TIME);
        break;
    case iSQL_MILSEC :
        m_ElapsedTime = m_uttTime.getMilliSeconds(UTT_WALL_TIME);
        break;
    case iSQL_MICSEC :
        m_ElapsedTime = m_uttTime.getMicroSeconds(UTT_WALL_TIME);
        break;
    case iSQL_NANSEC :
        m_ElapsedTime = m_uttTime.getMicroSeconds(UTT_WALL_TIME)*1000;
        break;
    default :
        break;
    }
    idlOS::sprintf(m_Spool.m_Buf, "elapsed time : %.2f\n", m_ElapsedTime);
    m_Spool.Print();
}
