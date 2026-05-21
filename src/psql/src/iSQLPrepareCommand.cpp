/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iSQLPrepareCommand.cpp 2 2006-04-13 15:48:39Z copyrei $
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

SInt getSqlType(iSQLVarType     aType)
{                       
    SInt sSqlType;
    switch (aType)
    {  
    case iSQL_BIGINT :
        sSqlType = SQL_BIGINT;
        break;
    case iSQL_BLOB :
        sSqlType = SQL_BINARY;
        break;
    case iSQL_CHAR :
        sSqlType = SQL_CHAR;
        break;
    case iSQL_DATE :
        sSqlType = SQL_DATE;
        break;
    case iSQL_DECIMAL :
        sSqlType = SQL_DECIMAL;
        break;
    case iSQL_DOUBLE :
        sSqlType = SQL_DOUBLE;
        break;
    case iSQL_FLOAT :
        sSqlType = SQL_FLOAT;
        break;
    case iSQL_BYTE :
        sSqlType = SQL_BYTES;
        break;
    case iSQL_NIBBLE :
        sSqlType = SQL_NIBBLE;
        break;
    case iSQL_INTEGER :
        sSqlType = SQL_INTEGER;
        break;
    case iSQL_NUMBER :
        sSqlType = SQL_NUMERIC;
        break;
    case iSQL_NUMERIC :
        sSqlType = SQL_NUMERIC;
        break;
    case iSQL_REAL :
        sSqlType = SQL_REAL;
        break;
    case iSQL_SMALLINT :
        sSqlType = SQL_SMALLINT;
        break;
    case iSQL_VARCHAR :
        sSqlType = SQL_VARCHAR;
        break;
    default:
        sSqlType = SQL_CHAR;
        break;
    }
    return sSqlType;
}

IDE_RC 
iSQLExecuteCommand::BindParam(SInt **aLen)
{
    SShort inout_type;
    SShort data_type;
    SShort para_order;

    SShort  c_type;
    SInt    precision = 0;
    SInt    max_value = 0;
    SInt   *len = NULL;
    
    HostVarNode *t_node, *s_node, *r_node;
    SInt         i, j=0;
    SInt         bind_cnt;

    r_node = gHostVarMgr.getBindList();
    t_node = r_node;
        
    bind_cnt = gHostVarMgr.getBindListCnt();
    if (bind_cnt != 0)
    {   
        IDE_TEST_RAISE( (len = (SInt*) idlOS::malloc(sizeof(SInt)*bind_cnt))
                        == NULL, mem_alloc_error );
        idlOS::memset( len, 0x00, sizeof(SInt)*bind_cnt );
        *aLen = len;
    }

    for (i=1; ; )
    {
        if (t_node == NULL)
        {
            break; 
        }
            
        para_order = t_node->element.para_order;
        if (t_node->element.assigned)
        {
            len[j] = SQL_NTS;
        }
        else
        {
            len[j] = SQL_NULL_DATA;
        }
        inout_type = SQL_PARAM_INPUT;
        data_type = getSqlType(t_node->element.type);

        switch (t_node->element.type)
        {
        case iSQL_DOUBLE :
            c_type = SQL_C_DOUBLE;
            max_value = sizeof(t_node->element.d_value);
            IDE_TEST_RAISE(m_ISPApi->ProcBindPara(para_order, inout_type,
                                                  c_type, data_type, 0,
                                                  &(t_node->element.d_value),
                                                  max_value, &(len[j++]))
                           != IDE_SUCCESS, error);
            break;
        case iSQL_REAL :
            c_type = SQL_C_FLOAT;
            max_value = sizeof(t_node->element.f_value);
            IDE_TEST_RAISE(m_ISPApi->ProcBindPara(para_order, inout_type,
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
            IDE_TEST_RAISE(m_ISPApi->ProcBindPara(para_order, inout_type,
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

            IDE_TEST_RAISE(m_ISPApi->ProcBindPara(para_order, inout_type,
                                                  c_type, data_type, precision,
                                                  t_node->element.c_value,
                                                  max_value, &(len[j++]))
                           != IDE_SUCCESS, error);
            break;
        }
        s_node = t_node;
        t_node = s_node->host_var_next;
    }

    return IDE_SUCCESS;

    IDE_EXCEPTION(mem_alloc_error);
    {
        idlOS::fprintf(stderr, "Memory allocation error!!! --- (%d, %s)\n",
                       __LINE__, __FILE__);
        exit(0);
    }
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
iSQLExecuteCommand::PrepareDMLStmt( SChar           * a_CommandStr, 
                                    SChar           * a_DMLStmt, 
                                    iSQLCommandKind   a_CommandKind )
{
    SChar tmp1[WORD_LEN], tmp2[WORD_LEN];
    SInt  cnt;
    SInt *sLen = NULL;

    idlOS::sprintf(m_Spool.m_Buf, "%s", a_CommandStr);  
    m_Spool.PrintCommand();

    m_ISPApi->SetQuery(a_DMLStmt);

    if ( gProperty.GetTiming() == ID_TRUE )
    {    
        m_uttTime.reset();
        m_uttTime.start();
    }
    
    IDE_TEST_RAISE(m_ISPApi->Prepare() != IDE_SUCCESS, error);

    IDE_TEST( BindParam(&sLen) != IDE_SUCCESS );

    IDE_TEST_RAISE(m_ISPApi->Execute() != IDE_SUCCESS, error);

    if ( gProperty.GetTiming() == ID_TRUE )
    {    
        m_uttTime.finish();    
    }
    
    IDE_TEST_RAISE(m_ISPApi->GetRowCount(&cnt, ID_TRUE) != IDE_SUCCESS, error);
    
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
    case PREP_INSERT_COM :
        idlOS::strcpy(tmp2, (SChar*)"inserted");
        break;
    case PREP_UPDATE_COM :
        idlOS::strcpy(tmp2, (SChar*)"updated");
        break;
    case PREP_DELETE_COM :
        idlOS::strcpy(tmp2, (SChar*)"deleted");
        break;
    default :
        break;
    }

    idlOS::sprintf(m_Spool.m_Buf, "%s %s.\n", tmp1, tmp2);
    m_Spool.Print();

    if ( gProperty.GetTiming() == ID_TRUE )
    {    
        ShowElapsedTime();
    }

    if (sLen != NULL)
    {
        idlOS::free(sLen);
    }
    m_ISPApi->StmtClose(ID_TRUE);

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

    if (sLen != NULL)
    {
        idlOS::free(sLen);
    }
    m_ISPApi->StmtClose(ID_TRUE);

    return IDE_FAILURE;
}

IDE_RC 
iSQLExecuteCommand::PrepareSelectStmt( SChar * a_CommandStr, 
                                       SChar * szSelectStmt )
{
    SInt  *sLen = NULL;
    
    m_ISPApi->SetQuery(szSelectStmt);
    idlOS::sprintf(m_Spool.m_Buf, "%s", a_CommandStr);  
    m_Spool.PrintCommand();

    if ( gProperty.GetTiming() == ID_TRUE )
    {    
        m_uttTime.reset();
        m_uttTime.start();
    }

    IDE_TEST_RAISE(m_ISPApi->Prepare() != IDE_SUCCESS, error);

    IDE_TEST( BindParam(&sLen) != IDE_SUCCESS );

    IDE_TEST_RAISE(m_ISPApi->SelectExecute(ID_TRUE) != IDE_SUCCESS, error);

    IDE_TEST( FetchSelectStmt(ID_TRUE) != IDE_SUCCESS );

    if (sLen != NULL)
    {
        idlOS::free(sLen);
    }
    m_ISPApi->StmtClose(ID_TRUE);

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

    if (sLen != NULL)
    {
        idlOS::free(sLen);
    }
    m_ISPApi->StmtClose(ID_TRUE);

    return IDE_FAILURE;
}

