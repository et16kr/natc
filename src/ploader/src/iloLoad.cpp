/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iloLoad.cpp 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/
 
#include <ilo.h>
#include <ilo.h>

extern uttMemory *g_memmgr;
extern SChar      gDateForm[64];
extern SChar      gTimestampVal[20];
extern TimestampType gTimestampType;
extern idBool     gAddFlag;

iloLoad::iloLoad()
{
    m_pProgOption = NULL;
    m_pISPApi = NULL;
}

isql_bool iloLoad::GetTableTree()
{
    iloTableNode *pTableRoot = NULL;
    SInt  nRet;

    gDateForm[0] = 0;

    IDE_TEST_RAISE( m_FormCompiler.SetInputFile(m_pProgOption->m_FormFile)
                    == isql_false, err_open );

    /* -f *.dat -d *.fmt 에서 에러 발생하면 해제 못하는 부분. */
    nRet = yyparse(&pTableRoot);
    g_memmgr->freeAll();
    
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
        idlOS::printf("Error : Cannot Open File [%s]\n",
                      m_pProgOption->m_FormFile);
    }
    IDE_EXCEPTION( err_parse );
    {
        delete pTableRoot;
        idlOS::printf("Input Form Parser Error\n");
    }
    IDE_EXCEPTION_END;

    return isql_false;
}

isql_bool iloLoad::GetTableInfo()
{
    if( m_pProgOption->m_bExist_array != isql_true )
    {
        m_pProgOption->m_ArrayCount = 1;
    }

    IDE_TEST( m_TableInfo.GetTableInfo(m_TableTree.GetTreeRoot())
              != isql_true );
    IDE_TEST( m_TableInfo.AllocTableAttr(m_pProgOption->m_ArrayCount)
              != isql_true );

#ifdef _ILOADER_DEBUG
    m_TableInfo.PrintTableInfo();
#endif

    return isql_true;

    IDE_EXCEPTION_END;

    return isql_false;
}

isql_bool iloLoad::LoadwithPrepare()
{
    isql_bool     ret;
    SInt          i;
    SInt          nErrCount = 0;
    SInt          nRet;
    SInt          ix;
    SInt          nLoad;
    SInt          nTotal = 0;
    SChar         szMsg[4096];
    SInt          sRealCount = 0;
    SInt          sArrayCount = 0;
    SQLUSMALLINT *sStatusPtr = NULL;

    uttTime g_qcuTimeCheck;

    IDE_TEST( GetTableTree() == isql_false );  // 에러해제 못하는 부분.

    IDE_TEST( GetTableInfo() == isql_false );

    m_DataFile.SetTerminator( m_pProgOption->m_FieldTerm,
                              m_pProgOption->m_RowTerm );

    m_DataFile.SetEnclosing( m_pProgOption->m_bExist_e,
                             m_pProgOption->m_EnclosingChar );

    IDE_TEST_RAISE( m_DataFile.OpenFile(m_pProgOption->m_DataFile, (SChar *)"rt")
                    == isql_false, err_open_data );

    if (m_pProgOption->m_bExist_log)
    {
        IDE_TEST_RAISE( m_LogFile.OpenFile(m_pProgOption->m_LogFile)
                        == isql_false, err_open_log );

        idlOS::sprintf(szMsg, "<DataLoad>\nTableName : %s\n",
                       m_TableInfo.GetTableName());
        m_LogFile.PrintLogMsg(szMsg);
        m_LogFile.PrintTime((SChar *)"Start Time");
        m_LogFile.SetTerminator( m_pProgOption->m_FieldTerm,
                                 m_pProgOption->m_RowTerm);
    }

    if (m_pProgOption->m_bExist_bad)
    {
        IDE_TEST_RAISE( m_BadFile.OpenFile(m_pProgOption->m_BadFile)
                        == isql_false, err_open_bad );
        m_BadFile.SetTerminator( m_pProgOption->m_FieldTerm,
                                 m_pProgOption->m_RowTerm );
    }

    IDE_TEST_RAISE( (m_pProgOption->m_LoadMode == REPLACE) &&
                    (ExecuteDeleteStmt() == isql_false),
                    err_delete );

    MakePrepareSQLStatement();
    m_pISPApi->Prepare(m_SQLStatement, m_TableInfo.GetAttrCount());
    BindParameter();
    
    idlOS::printf("     ");

    g_qcuTimeCheck.setName("UPLOAD");
    g_qcuTimeCheck.start();

    sArrayCount = m_pProgOption->m_ArrayCount;
    for( ix = 1, nRet = 1, nTotal = 0, nLoad = 1, nErrCount = 0;
         (nRet != 2) /*&& (nErrCount < m_pProgOption->m_ErrorCount) nRet == 1*/;
         ix ++)
    {
        if (sRealCount == sArrayCount)
        {
            sRealCount = 0;
        }
        nRet = m_DataFile.ReadOneRecord(&m_TableInfo, sRealCount);

        if ( nRet == 2 && sRealCount == 0 )
        {
            continue;
        }

        if (m_pProgOption->m_bExist_F && (ix < m_pProgOption->m_FirstRow))
        {
            sRealCount = 0;
            continue;
        }
        if (m_pProgOption->m_bExist_L && (ix > m_pProgOption->m_LastRow))
        {
            break;
        }

        if (nRet != 2) 
            nTotal++;
        if (nRet == 0)
        {
            nErrCount ++;
            m_LogFile.PrintOneRecord(&m_TableInfo, sRealCount);
            m_BadFile.PrintOneRecord(&m_TableInfo, sRealCount);
            idlOS::sprintf(szMsg, " -> line[%d] Data Parsing Error\n",
                           nTotal);
            m_LogFile.PrintLogMsg(szMsg);
            continue;
        }

        sRealCount++;

        if ( sRealCount == sArrayCount || nRet == 2 ||
             m_pProgOption->m_bExist_L && (ix == m_pProgOption->m_LastRow) )
        {
            if ( nRet == 2 )   // readOneRecord 에서 (EOF) 만 읽어왔을경우
            {
                SQLSetStmtAttr( m_pISPApi->getStmt(),
                    SQL_ATTR_PARAMSET_SIZE,
                    (void *)(sRealCount-1),
                    0); 
            }
            else if ( m_pProgOption->m_bExist_L && (ix == m_pProgOption->m_LastRow) )
            {
                SQLSetStmtAttr( m_pISPApi->getStmt(),
                    SQL_ATTR_PARAMSET_SIZE,
                    (void *)sRealCount,
                    0); 
            }

            ret = m_pISPApi->Execute();
            if ( ret == isql_false && sArrayCount == 1 )
            {
                nErrCount ++;
                if ( m_pISPApi->mErrorCode == 0x3b032 ||
                     m_pISPApi->mErrorCode == 0x5003b || // buffer full
                     m_pISPApi->mErrorCode == 0x51043 ) // 통신 장애
                {
                    idlOS::fprintf(stdout, "Insert Error : %s\n",
                                   m_pISPApi->GetErrorMsg());
                    idlOS::sprintf(szMsg, "Insert Error : %s\n",
                                   m_pISPApi->GetErrorMsg());
                    m_LogFile.PrintLogMsg(szMsg);
                    break;
                }
                m_LogFile.PrintOneRecord(&m_TableInfo, sRealCount-1);
                m_BadFile.PrintOneRecord(&m_TableInfo, sRealCount-1);
                idlOS::sprintf(szMsg, "Insert Error : %s\n",
                               m_pISPApi->GetErrorMsg());
                m_LogFile.PrintLogMsg(szMsg);
                continue; 
            }
            else if ( ret == isql_false && sArrayCount > 1 )
            {
                if ( m_pISPApi->mErrorCode == 0x3b032 ||
                     m_pISPApi->mErrorCode == 0x5003b || // buffer full
                     m_pISPApi->mErrorCode == 0x51043 ) // 통신 장애
                {
                    idlOS::fprintf(stdout, "Insert Error : %s\n",
                                   m_pISPApi->GetErrorMsg());
                    idlOS::sprintf(szMsg, "Insert Error : %s\n",
                                   m_pISPApi->GetErrorMsg());
                    m_LogFile.PrintLogMsg(szMsg);
                    break;
                }
                sStatusPtr = m_TableInfo.mStatusPtr;
                for ( i=0; ( nRet == 2 && i < sRealCount - 1 )
                           || ( nRet != 2 && i < sArrayCount ) ; i++ )
                {
                    if ( sStatusPtr[i] != SQL_PARAM_SUCCESS )
                    {
                        nErrCount ++;
                        m_LogFile.PrintOneRecord(&m_TableInfo, i);
                        m_BadFile.PrintOneRecord(&m_TableInfo, i);
                        if ( sStatusPtr[i] == SQL_PARAM_ERROR )
                        {
                            idlOS::sprintf(szMsg, "Insert Error : %s\n",
                                           m_pISPApi->GetErrorMsg());
                        }
                        else if ( sStatusPtr[i] == SQL_PARAM_UNUSED )
                        {
                            idlOS::sprintf(szMsg, "Insert Error : unused\n");
                        }
                        m_LogFile.PrintLogMsg(szMsg);
                        continue; 
                    }
                }
            }

            if ( nRet == 2 )
                continue;

        }

        if ( (m_pProgOption->m_CommitUnit > 0) &&
             (nLoad % m_pProgOption->m_CommitUnit == 0) )
        {
            if (m_pISPApi->EndTran(isql_true) == isql_false)
            {
                m_pISPApi->EndTran(isql_false);
                nErrCount += m_pProgOption->m_CommitUnit;

                if (m_pProgOption->m_CommitUnit == 1)
                {
                    m_LogFile.PrintOneRecord(&m_TableInfo, sRealCount-1);
                    m_BadFile.PrintOneRecord(&m_TableInfo, sRealCount-1);
                }
                idlOS::sprintf(szMsg, "Insert Commit Error : %s\n",
                               m_pISPApi->GetErrorMsg());
                m_LogFile.PrintLogMsg(szMsg);
                continue; 
            }
        }

        if (nLoad % 100 == 0)
        {
            putchar('.');
        }

        if (nLoad % 5000 == 0)
        {
            idlOS::printf("\n%d record load\n", nLoad);
            idlOS::printf("\n     ");
        }

        nLoad++;
    } /* for... */

    g_qcuTimeCheck.finish();

    m_TableInfo.FreeTableAttr();

    if (!m_pProgOption->m_bExist_NST)
    {
        g_qcuTimeCheck.show();
    }

    if ( (m_pProgOption->m_CommitUnit > 0) && 
                ((nLoad - 1) % m_pProgOption->m_CommitUnit != 0) ) 
    {
        if (m_pISPApi->EndTran(isql_true) == isql_false)
        {
            m_pISPApi->EndTran(isql_false);
            nErrCount += (nLoad - 1) % m_pProgOption->m_CommitUnit;
        }
    }

    idlOS::printf("\n     Load Count  : %d", nTotal - nErrCount);
    if (nErrCount > 0)
    {
        idlOS::printf("\n     Error Count : %d\n", nErrCount);
    }
    idlOS::printf("\n");

    m_DataFile.CloseFile();
    if (m_pProgOption->m_bExist_log)
    {
        m_LogFile.PrintTime((SChar *)"End Time");
        idlOS::sprintf(szMsg,
                       "Total Row Count : %d\n"
                       "Load Row Count  : %d\n"
                       "Error Row Count : %d\n",
                       nTotal, nTotal - nErrCount,  nErrCount);
        m_LogFile.PrintLogMsg(szMsg);
        m_LogFile.CloseFile();
    }
    m_BadFile.CloseFile();

    return isql_true;

    IDE_EXCEPTION( err_open_data );
    {
        idlOS::printf("Data File [%s] open fail\n",
                      m_pProgOption->m_DataFile);
    }
    IDE_EXCEPTION( err_open_log );
    {
        idlOS::printf("Log File [%s] open fail\n",
                      m_pProgOption->m_LogFile);
        m_DataFile.CloseFile();
    }
    IDE_EXCEPTION( err_open_bad );
    {
        idlOS::printf("Bad File [%s] open fail\n",
                      m_pProgOption->m_BadFile);
        m_DataFile.CloseFile();
    }
    IDE_EXCEPTION( err_delete );
    {
        idlOS::printf("Delete Record from Table(%s) Fail\n",
                      m_TableInfo.GetTableName());
        m_DataFile.CloseFile();
        m_LogFile.PrintLogMsg((SChar *)"Delete Record from Table Fail\n");
        m_LogFile.CloseFile();
        m_BadFile.CloseFile();
    }
    IDE_EXCEPTION_END;

    return isql_false;
}

isql_bool iloLoad::MakePrepareSQLStatement()
{
    SInt  i = 0;
    SInt  index ;
    SChar tmpBuffer[128];

    UInt  secVal;
    
    m_TableInfo.CopyStruct();
    IDE_TEST( m_TableInfo.seqColChk() == isql_false ||
              m_TableInfo.seqDupChk() == isql_false );

    idlOS::sprintf(m_SQLStatement, "INSERT INTO %s ",
                   m_TableInfo.GetTableName());

    idlOS::strcat(m_SQLStatement, "(");
    for ( i=0; i<m_TableInfo.GetAttrCount(); i++)
    {
        if( m_TableInfo.mSkipFlag[i] == 1 &&
            m_TableInfo.GetAttrType(i) != ISP_ATTR_TIMESTAMP )
        {
            continue;
        }
        if ( m_TableInfo.GetAttrType(i) == ISP_ATTR_TIMESTAMP &&
             gTimestampType == ILO_TIMESTAMP_DEFAULT )
        {
            continue;
        }
        idlOS::strcat(m_SQLStatement, m_TableInfo.GetAttrName(i));
        idlOS::strcat(m_SQLStatement, ",");
    }
    m_SQLStatement[ idlOS::strlen(m_SQLStatement) - 1 ] = ')';

    idlOS::strcat(m_SQLStatement, " VALUES (");
    for ( i=0; i<m_TableInfo.GetAttrCount(); i++)
    {
        if ( m_TableInfo.GetAttrType(i) == ISP_ATTR_TIMESTAMP )
        {
            if ( gTimestampType == ILO_TIMESTAMP_DEFAULT )
            {
                continue;
            }
            else if ( gTimestampType == ILO_TIMESTAMP_NULL )
            {
                idlOS::sprintf(tmpBuffer, "NULL,");
                idlOS::strcat(m_SQLStatement, tmpBuffer);
            }
            else if ( gTimestampType == ILO_TIMESTAMP_VALUE )
            {
                struct tm tval;
                SChar  tmp[5];
                idlOS::memset( &tval, 0, sizeof(struct tm));
                idlOS::strncpy(tmp, gTimestampVal, 4);
                tmp[4] = 0;
                tval.tm_year = idlOS::atoi(tmp) - 1900;
                // add length(YYYY, 4)
                idlOS::strncpy(tmp, gTimestampVal+4, 2);
                tmp[2] = 0;
                tval.tm_mon = idlOS::atoi(tmp) - 1;
                // add length(YYYY:MM, 6)
                idlOS::strncpy(tmp, gTimestampVal+6, 2);
                tmp[2] = 0;
                tval.tm_mday = idlOS::atoi(tmp);
                if ( idlOS::strlen(gTimestampVal) > 8 )
                {
                    // add length(YYYY:MM:DD, 8)
                    idlOS::strncpy(tmp, gTimestampVal+8, 2);
                    tmp[2] = 0;
                    tval.tm_hour = idlOS::atoi(tmp);
                    // add length(YYYY:MM:DD:HH, 10)
                    idlOS::strncpy(tmp, gTimestampVal+10, 2);
                    tmp[2] = 0;
                    tval.tm_min = idlOS::atoi(tmp);
                    // add length(YYYY:MM:DD:HH:MI, 12)
                    idlOS::strncpy(tmp, gTimestampVal+12, 2);
                    tmp[2] = 0;
                    tval.tm_sec = idlOS::atoi(tmp);
                }
                secVal = (UInt)idlOS::mktime(&tval);

                idlOS::sprintf(tmpBuffer,
                        "BYTE\'%08"ID_XINT32_FMT"\',", secVal);
                idlOS::strcat(m_SQLStatement, tmpBuffer);
            }
            else if ( gTimestampType == ILO_TIMESTAMP_DAT )
            {     
                if( m_TableInfo.mSkipFlag[i] != 1 )
                {
                    idlOS::strcat(m_SQLStatement, "?,");
                }
            }
            continue;
        }
        if( m_TableInfo.mSkipFlag[i] == 1 )
        {
            continue;
        }
        if ((index = m_TableInfo.seqEqualChk(i)) >= 0)
        { 
            idlOS::strcat(m_SQLStatement,
                          m_TableInfo.localSeqArray[index].seqName);
            idlOS::strcat(m_SQLStatement, ".");
            idlOS::strcat(m_SQLStatement,
                          m_TableInfo.localSeqArray[index].seqVal);
            idlOS::strcat(m_SQLStatement, ",");
            continue;
        }
        else if( m_TableInfo.GetAttrType(i) == ISP_ATTR_DATE )
        {
            if( m_TableInfo.mAttrDateFormat[i] != NULL )
            {
                idlOS::sprintf(tmpBuffer, "to_date(?,'%s'),",
                               m_TableInfo.mAttrDateFormat[i]);
                idlOS::strcat(m_SQLStatement, tmpBuffer);
            }
            else if( idlOS::strlen(gDateForm) >= 1 )
            {
                idlOS::sprintf(tmpBuffer, "to_date(?,'%s'),", gDateForm);
                idlOS::strcat(m_SQLStatement, tmpBuffer);
            }
            else
            {
                idlOS::strcat(m_SQLStatement, "?,");
            }
        }
        else
        { 
            idlOS::strcat(m_SQLStatement, "?,");
        }
    }
    m_SQLStatement[ idlOS::strlen(m_SQLStatement) - 1 ] = ')';
    
    m_pISPApi->SetSQLStatement(m_SQLStatement);
    m_TableInfo.FreeDateFormat();

    return isql_true;

    IDE_EXCEPTION_END;

    return isql_false;
}

isql_bool iloLoad::ExecuteDeleteStmt()
{
    idlOS::sprintf(m_SQLStatement, "DELETE FROM %s ",
                   m_TableInfo.GetTableName());
    m_pISPApi->SetSQLStatement(m_SQLStatement);

    IDE_TEST( m_pISPApi->ExecuteDirect() == isql_false );

    return isql_true;

    IDE_EXCEPTION_END;

    return isql_false;
}

isql_bool iloLoad::BindParameter()
{
    SInt nResult;
    SInt i;
    SInt j = 0;
    SQLSMALLINT sSQLType;
    SQLINTEGER  sPrec;
    SQLINTEGER  sValueMax;
    void       *sValuePtr = NULL;

    mArrayCount = m_pProgOption->m_ArrayCount;

    if ( mArrayCount > 1 )
    {
    SQLSetStmtAttr( m_pISPApi->getStmt(), 
                    SQL_ATTR_PARAM_BIND_TYPE,
                    SQL_PARAM_BIND_BY_COLUMN,
                    0);

    SQLSetStmtAttr( m_pISPApi->getStmt(),
                    SQL_ATTR_PARAMSET_SIZE,
                    (void *)mArrayCount,
                    0); 

    SQLSetStmtAttr( m_pISPApi->getStmt(),
                    SQL_ATTR_PARAM_STATUS_PTR,
                    m_TableInfo.mStatusPtr,
                    0);

    SQLSetStmtAttr( m_pISPApi->getStmt(),
                    SQL_ATTR_PARAMS_PROCESSED_PTR,
                    NULL,
                    0);
    }

    m_ulLen = SQL_NTS;
    
    m_TableInfo.CopyStruct();
    
    for (i=0; i <  m_TableInfo.GetAttrCount(); i++)
    {
       
        if ( m_TableInfo.seqEqualChk(i) >= 0 || 
             m_TableInfo.mSkipFlag[i] == 1 )
        {   
            continue;
        }   
        if ( m_TableInfo.GetAttrType(i) == ISP_ATTR_TIMESTAMP &&
             gAddFlag == ID_TRUE )
        {
            continue;
        }
        
        j++;
        switch (m_TableInfo.GetAttrType(i))
        {
        case ISP_ATTR_NIBBLE :
            sSQLType = SQL_NIBBLE;
            sPrec    = m_TableInfo.mPrecision[i];
//            sPrec    = MAX_VARCHAR_SIZE; // precision: ColumnValue.C_Col 
            sValuePtr = m_TableInfo.GetAttrValue(i)->B_Col;
            sValueMax = sizeof(union BinaryValue);//MAX_VARCHAR_SIZE * 2 + 1;
            break;
        case ISP_ATTR_VARCHAR :
            sSQLType = SQL_VARCHAR;
            sPrec    = MAX_VARCHAR_SIZE; /* precision: ColumnValue.C_Col */
            sValuePtr = m_TableInfo.GetAttrValue(i)->C_Col;
            sValueMax = MAX_VARCHAR_SIZE;
            break;
        case ISP_ATTR_INTEGER :
            sSQLType = SQL_INTEGER;
            sPrec    = sizeof(SInt);
            sValuePtr = m_TableInfo.GetAttrValue(i)->C_Col;
            sValueMax = MAX_VARCHAR_SIZE;
            break;                       
        case ISP_ATTR_BYTES :
        case ISP_ATTR_TIMESTAMP :
            sSQLType = SQL_BYTES;
            sPrec    = m_TableInfo.mPrecision[i];
            //sPrec    = MAX_VARCHAR_SIZE;
            sValuePtr = m_TableInfo.GetAttrValue(i)->B_Col;
            sValueMax = sizeof(union BinaryValue);//MAX_VARCHAR_SIZE * 2 + 1;
            break;
        case ISP_ATTR_DOUBLE :
            sSQLType = SQL_DOUBLE;
            sPrec    = MAX_VARCHAR_SIZE;
            sValuePtr = m_TableInfo.GetAttrValue(i)->C_Col;
            sValueMax = MAX_VARCHAR_SIZE;
            break;
        case ISP_ATTR_REAL:
            sSQLType = SQL_REAL;
            sPrec    = MAX_VARCHAR_SIZE;
            sValuePtr = m_TableInfo.GetAttrValue(i)->C_Col;
            sValueMax = MAX_VARCHAR_SIZE;
            break;
        case ISP_ATTR_BIGINT:
            sSQLType = SQL_BIGINT;
            sPrec    = MAX_VARCHAR_SIZE;
            sValuePtr = m_TableInfo.GetAttrValue(i)->C_Col;
            sValueMax = MAX_VARCHAR_SIZE;
            break;
        case ISP_ATTR_SMALLINT:
            sSQLType = SQL_SMALLINT;
            sPrec    = MAX_VARCHAR_SIZE;
            sValuePtr = m_TableInfo.GetAttrValue(i)->C_Col;
            sValueMax = MAX_VARCHAR_SIZE;
            break;
        case ISP_ATTR_BLOB:
            sSQLType = SQL_BINARY;
            sPrec    = MAX_VARCHAR_SIZE;
            sValuePtr = m_TableInfo.GetAttrValue(i)->B_Col;
            sValueMax = sizeof(union BinaryValue);//MAX_VARCHAR_SIZE * 2 + 1;
            break;
        default :
            sSQLType = SQL_CHAR;
            sPrec    = MAX_VARCHAR_SIZE;
            sValuePtr = m_TableInfo.GetAttrValue(i)->C_Col;
            sValueMax = MAX_VARCHAR_SIZE;
            break;
        }
                                   
        nResult = SQLBindParameter(m_pISPApi->getStmt(),
                                   j,
                                   SQL_PARAM_INPUT,
                                   SQL_C_CHAR,
                                   sSQLType,
                                   sPrec,
                                   0,
                                   sValuePtr,
                                   sValueMax,
                                   &(m_TableInfo.m_AttrLen[i][0]) );
        IDE_TEST( nResult != SQL_SUCCESS );
    }

    return isql_true;

    IDE_EXCEPTION_END;

    return isql_false;
}
