/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iloSQLApi.cpp 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/
 
#include <ilo.h>
#include <ulCli.h>

extern iloProgOption gProgOption;

SQLRETURN   SQLFreeEnv(SQLHENV EnvironmentHandle)
{
    return SQLFreeHandle(SQL_HANDLE_ENV, EnvironmentHandle);
}

SQLRETURN   SQLFreeConnect(SQLHDBC ConnectionHandle)
{
    return SQLFreeHandle(SQL_HANDLE_DBC, ConnectionHandle);
}

SQLRETURN   SQLAllocStmt(SQLHDBC ConnectionHandle,
           SQLHSTMT *StatementHandle)
{
    return SQLAllocHandle(SQL_HANDLE_STMT, ConnectionHandle, StatementHandle);
}

SQLRETURN   SQLAllocEnv(SQLHENV *EnvironmentHandle)
{
    return SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, EnvironmentHandle);
}

SQLRETURN   SQLAllocConnect(SQLHENV EnvironmentHandle,
           SQLHDBC *ConnectionHandle)
{
    return SQLAllocHandle(SQL_HANDLE_DBC, EnvironmentHandle, ConnectionHandle);
}

char* SQLErrorStr(char* buf, SQLSMALLINT handleType, SQLHANDLE handle)
{
    SQLCHAR sqlState[6];
    SQLCHAR errMsg[128];
    SQLINTEGER errCode;
    SQLSMALLINT bufptr;

    int res = SQLGetDiagRec(handleType, handle, 1, sqlState, &errCode, errMsg, 128, &bufptr);

    if (! SQL_SUCCEEDED(res))
    {
        sprintf(buf, "Failed to get diag record.");
        return buf;
    }

    sprintf(buf, "ODBC_ERR: (VendorCode=%d, SQLState=%s) %s", errCode, sqlState,
                        errMsg);
    return buf;
}

SQLRETURN   SQLError(SQLHENV EnvironmentHandle,
           SQLHDBC ConnectionHandle, SQLHSTMT StatementHandle,
           SQLCHAR *Sqlstate, SQLINTEGER *NativeError,
           SQLCHAR *MessageText, SQLSMALLINT BufferLength,
           SQLSMALLINT *TextLength)
{
    *NativeError = 0;
    SQLErrorStr((char *)MessageText, SQL_HANDLE_STMT, StatementHandle);
    *TextLength = strlen((char *)MessageText) + 1;

    return SQL_SUCCESS;
}

iloColumns::iloColumns()
{
    m_Name = NULL;
    m_Type = NULL;
    m_Precision = NULL;
    m_Scale = NULL;
    m_Value = NULL;
    m_Len = NULL;
    m_DisplayPos = NULL;
    m_nCol = 0;
}

iloColumns::~iloColumns()
{
    if (m_Name != NULL)
    {
        idlOS::free( m_Name );
    }
    if (m_Type != NULL)
    {
        idlOS::free( m_Type );
    }
    if (m_Precision != NULL)
    {
        idlOS::free( m_Precision );
    }
    if (m_Scale != NULL)
    {
        idlOS::free( m_Scale );
    }
    if (m_Value != NULL)
    {
        idlOS::free( m_Value );
    }
    if (m_Len != NULL)
    {
        idlOS::free( m_Len );
    }
    if (m_DisplayPos != NULL)
    {
        idlOS::free( m_DisplayPos );
    }
}

isql_bool iloColumns::SetSize(SInt nColCount)
{
    if (m_Name != NULL)
    {
        idlOS::free( m_Name );
        m_Name = NULL;
    }
    m_Name = ( SChar (*)[256] ) idlOS::malloc( nColCount * sizeof(*m_Name) );
    IDE_TEST(m_Name == NULL);

    if (m_Type != NULL)
    {
        idlOS::free( m_Type );
        m_Type = NULL;
    }
    m_Type = (SInt*) idlOS::malloc( nColCount * sizeof(SInt) );
    IDE_TEST(m_Type == NULL);

    if (m_Precision != NULL)
    {
        idlOS::free( m_Precision );
        m_Precision = NULL;
    }
    m_Precision = (SInt*) idlOS::malloc( nColCount * sizeof(SInt) );
    IDE_TEST(m_Precision == NULL);

    if (m_Scale != NULL)
    {
        idlOS::free( m_Scale );
        m_Scale = NULL;
    }
    m_Scale = (SInt*) idlOS::malloc( nColCount * sizeof(SInt) );
    IDE_TEST(m_Scale == NULL);

    if (m_Value != NULL)
    {
        idlOS::free( m_Value );
        m_Value = NULL;
    }
    m_Value = (union ColumnValue *)
              idlOS::malloc( nColCount * sizeof(union ColumnValue) );
    IDE_TEST(m_Value == NULL);

    if (m_Len != NULL)
    {
        idlOS::free( m_Len );
        m_Len = NULL;
    }
    m_Len = (SQLINTEGER*) idlOS::malloc( nColCount * sizeof(SQLINTEGER) );
    IDE_TEST(m_Len == NULL);

    if (m_DisplayPos != NULL)
    {
        idlOS::free( m_DisplayPos );
        m_DisplayPos = NULL;
    }
    m_DisplayPos = (SInt*) idlOS::malloc( nColCount * sizeof(SInt) );
    IDE_TEST(m_DisplayPos == NULL);

    m_nCol = nColCount;
    return isql_true;

    IDE_EXCEPTION_END;

    return isql_false;
}

isql_bool iloColumns::resize(SInt nColCount)
{
    m_Name = ( SChar (*)[256] ) idlOS::realloc( m_Name,
                                nColCount * sizeof(*m_Name) );
    IDE_TEST(m_Name == NULL);

    m_Type = (SInt*) idlOS::realloc( m_Type,
                                nColCount * sizeof(SInt) );
    IDE_TEST(m_Type == NULL);

    m_Precision = (SInt*) idlOS::realloc( m_Precision,
                                nColCount * sizeof(SInt) );
    IDE_TEST(m_Precision == NULL);

    m_Scale = (SInt*) idlOS::realloc( m_Scale,
                                nColCount * sizeof(SInt) );
    IDE_TEST(m_Scale == NULL);

    m_Value = (union ColumnValue *) idlOS::realloc( m_Value,
                                nColCount * sizeof(union ColumnValue) );
    IDE_TEST(m_Value == NULL);

    m_Len = (SQLINTEGER*) idlOS::realloc( m_Len,
                                nColCount * sizeof(SQLINTEGER) );
    IDE_TEST(m_Len == NULL);

    m_DisplayPos = (SInt*) idlOS::realloc( m_DisplayPos,
                                nColCount * sizeof(SInt) );
    IDE_TEST(m_DisplayPos == NULL);

    m_nCol = nColCount;
    return isql_true;

    IDE_EXCEPTION_END;

    return isql_false;
}

isql_bool iloColumns::SetName(SInt nCol, SChar *szName)
{
    IDE_TEST( nCol >= m_nCol );
    idlOS::strcpy((SChar *)m_Name[nCol], (SChar *)szName);

    return isql_true;

    IDE_EXCEPTION_END;

    return isql_false;
}

isql_bool iloColumns::SetType(SInt nCol, SInt nType)
{
    IDE_TEST( nCol >= m_nCol );
    m_Type[nCol] = nType;

    return isql_true;

    IDE_EXCEPTION_END;

    return isql_false;
}

isql_bool iloColumns::SetPrecision(SInt nCol, SInt nPrecision)
{
    IDE_TEST( nCol >= m_nCol );
    m_Precision[nCol] = nPrecision;

    return isql_true;

    IDE_EXCEPTION_END;

    return isql_false;
}

isql_bool iloColumns::SetScale(SInt nCol, SInt nScale)
{
    IDE_TEST( nCol >= m_nCol );
    m_Scale[nCol] = nScale;

    return isql_true;

    IDE_EXCEPTION_END;

    return isql_false;
}

isql_bool iloColumns::SetValue(SInt nCol, SChar *szValue)
{
    IDE_TEST( nCol >= m_nCol );
    idlOS::strcpy(m_Value[nCol].C_Col, szValue);

    return isql_true;

    IDE_EXCEPTION_END;

    return isql_false;
}

iloSQLApi::iloSQLApi()
{
    m_IEnv = NULL ;
    m_ICon = NULL ;
    m_IStmt = NULL ;
    m_SQLStatement[0] = '\0';
    m_ErrorMsg[0] = '\0';
}

iloSQLApi::~iloSQLApi()
{
}


void iloSQLApi::SetSQLStatement(SChar *szStr)
{
    if (szStr != NULL)
    {
        strcpy(m_SQLStatement, szStr);
    }
}

isql_bool iloSQLApi::OpenforUtil(SChar *szHost,
                                 SChar *szUser,
                                 SChar *szPassword)
{
    SInt        rc ;
    SChar       sConStr[1024];
    SInt        sConType = 2;    //  1:TCP/IP 2:U/D
    SChar       sEnvConType[10];
    SQLINTEGER  sErrCode;
    SQLSMALLINT sErrMsgLen;
    SChar       sErrMsg[MSG_LEN];
    
    // ODBC Connection
    rc = SQLAllocEnv(&m_IEnv) ;
    IDE_TEST_RAISE( rc != SQL_SUCCESS, err_env );

    rc = SQLAllocConnect(m_IEnv,&m_ICon) ;
    IDE_TEST_RAISE( rc != SQL_SUCCESS, err_alloc_con );

/* TCP, UNIX 분류 */    
    if ( idlOS::getenv("ISQL_CONNECTION") != NULL )
    {
        idlOS::strcpy(sEnvConType, idlOS::getenv("ISQL_CONNECTION"));
        if (idlOS::strncmp(sEnvConType, "TCP", 3) == 0)
        {
            sConType = 1;
        }
        else if (idlOS::strncmp(sEnvConType, "UNIX", 4) == 0) 
        {
#if !defined(VC_WIN32) && !defined(NTO_QNX)
            sConType = 2;
#else
            sConType = 1;
#endif
        }
    }
    
    if ((sConType == 3 || sConType == 2) && szHost != NULL)
    {
        sConType = 1; //unix, ipc일 때 hostname있으면 TCP로 바꿈
    }
    
    idlOS::sprintf(sConStr, "DSN=%s;UID=%s;PWD=%s;CONNTYPE=%d", 
                szHost, szUser, szPassword, sConType);
    rc = SQLDriverConnect( m_ICon, NULL,
                                sConStr, SQL_NTS,
                                NULL, 0,
                                NULL, SQL_DRIVER_NOPROMPT ); //add bluetheme
    IDE_TEST_RAISE( rc != SQL_SUCCESS, err_connect );

    rc = SQLAllocStmt(m_ICon,&m_IStmt) ;
    IDE_TEST_RAISE( rc != SQL_SUCCESS, err_stmt );

    return isql_true;

    IDE_EXCEPTION( err_env );
    {
        idlOS::printf("SQLAllocEnv Error !!!\n") ;
        return isql_false;
    }
    IDE_EXCEPTION( err_alloc_con );
    {
        idlOS::sprintf(m_ErrorMsg, "SQLAllocConnect Error !!!\n") ;
    }
    IDE_EXCEPTION( err_connect );
    {
        idlOS::sprintf(m_ErrorMsg, "Connect Error !!!\n");
    }
    IDE_EXCEPTION( err_stmt );
    {
        idlOS::sprintf(m_ErrorMsg, "SQLAllocStmt Error !!!\n") ;
    }
    IDE_EXCEPTION_END;

    SQLError ( m_IEnv, m_ICon, m_IStmt, NULL, &sErrCode,
               sErrMsg, MSG_LEN, &sErrMsgLen );
    idlOS::printf(" rCM_-%d : %s\n", sErrCode, sErrMsg);
    mErrorCode = sErrCode;

    return isql_false;
}

isql_bool iloSQLApi::Open(SChar *szHost,
                          SChar * /*szDB*/,
                          SChar *szUser,
                          SChar *szPassword,
                          SChar *szNLS,
                          SInt  nPort)
{
    SInt        rc;
    SChar       sConStr[1024];  
    SQLINTEGER  sErrCode;
    SQLSMALLINT sErrMsgLen;
    SChar       sErrMsg[MSG_LEN];
    
    // ODBC Connection
    rc = SQLAllocEnv(&m_IEnv) ;
    IDE_TEST_RAISE( rc != SQL_SUCCESS, err_env );

    rc = SQLAllocConnect(m_IEnv,&m_ICon) ;
    IDE_TEST_RAISE( rc != SQL_SUCCESS, err_alloc_con );

    idlOS::sprintf(sConStr, "DSN=%s;UID=%s;PWD=%s;CONNTYPE=1;NLS_USE=%s;PORT_NO=%d", 
                   szHost, szUser, szPassword, szNLS, nPort);
   
    /* 
    rc = SQLDriverConnect( m_ICon, NULL,
                           sConStr, SQL_NTS,
                           NULL, 0,
                           NULL, SQL_DRIVER_NOPROMPT );  
    */ 
    sprintf ((char *)sConStr, "%s:%d", szHost, nPort);
    rc = SQLConnect(m_ICon, (SQLCHAR*)(sConStr), SQL_NTS, szUser, SQL_NTS, szPassword, SQL_NTS);
    IDE_TEST_RAISE( rc != SQL_SUCCESS, err_connect );

    rc = SQLAllocStmt(m_ICon,&m_IStmt) ;
    IDE_TEST_RAISE( rc != SQL_SUCCESS, err_stmt );
    
    return isql_true;

    IDE_EXCEPTION( err_env );
    {
        idlOS::printf("SQLAllocEnv Error !!!\n") ;
        return isql_false;
    }
    IDE_EXCEPTION( err_alloc_con );
    {
        idlOS::sprintf(m_ErrorMsg, "SQLAllocConnect Error !!!\n") ;
    }
    IDE_EXCEPTION( err_connect );
    {
        idlOS::sprintf(m_ErrorMsg, "Connect Error !!!\n");
    }
    IDE_EXCEPTION( err_stmt );
    {
        idlOS::sprintf(m_ErrorMsg, "SQLAllocStmt Error !!!\n") ;
    }
    IDE_EXCEPTION_END;

    SQLError ( m_IEnv, m_ICon, m_IStmt, NULL, &sErrCode,
               sErrMsg, MSG_LEN, &sErrMsgLen );
    idlOS::printf(" rCM_-%d : %s\n", sErrCode, sErrMsg);
    mErrorCode = sErrCode;

    return isql_false;
}


isql_bool iloSQLApi::OpenWithUD(SChar *szHost,
                   SChar * /*szDB*/,
                   SChar *szUser,
                   SChar *szPassword,
                   SChar *szNLS)
{
    SInt        rc;
    SChar       sConStr[1024];  
    SQLINTEGER  sErrCode;
    SQLSMALLINT sErrMsgLen;
    SChar       sErrMsg[MSG_LEN];
    
    // ODBC Connection
    rc = SQLAllocEnv(&m_IEnv) ;
    IDE_TEST_RAISE( rc != SQL_SUCCESS, err_env );

    rc = SQLAllocConnect(m_IEnv,&m_ICon) ;
    IDE_TEST_RAISE( rc != SQL_SUCCESS, err_alloc_con );

    idlOS::sprintf(sConStr, "DSN=%s;UID=%s;PWD=%s;CONNTYPE=2;NLS_USE=%s", 
                   szHost, szUser, szPassword, szNLS);
    
    rc = SQLDriverConnect( m_ICon, NULL,
                           sConStr, SQL_NTS,
                           NULL, 0,
                           NULL, SQL_DRIVER_NOPROMPT );  
    IDE_TEST_RAISE( rc != SQL_SUCCESS, err_connect );

    rc = SQLAllocStmt(m_ICon,&m_IStmt) ;
    IDE_TEST_RAISE( rc != SQL_SUCCESS, err_stmt );

    return isql_true;

    IDE_EXCEPTION( err_env );
    {
        idlOS::printf("SQLAllocEnv Error !!!\n") ;
        return isql_false;
    }
    IDE_EXCEPTION( err_alloc_con );
    {
        idlOS::sprintf(m_ErrorMsg, "SQLAllocConnect Error !!!\n") ;
    }
    IDE_EXCEPTION( err_connect );
    {
        idlOS::sprintf(m_ErrorMsg, "Connect Error !!!\n");
    }
    IDE_EXCEPTION( err_stmt );
    {
        idlOS::sprintf(m_ErrorMsg, "SQLAllocStmt Error !!!\n") ;
    }
    IDE_EXCEPTION_END;

    SQLError ( m_IEnv, m_ICon, m_IStmt, NULL, &sErrCode,
               sErrMsg, MSG_LEN, &sErrMsgLen );
    idlOS::printf(" rCM_-%d : %s\n", sErrCode, sErrMsg);
    mErrorCode = sErrCode;

    return isql_false;
}

isql_bool iloSQLApi::OpenWithIPC(SChar *szHost,
                                 SChar * /*szDB*/,
                                 SChar *szUser,
                                 SChar *szPassword,
                                 SChar *szNLS,
                                 SInt  nPort)
{
    SInt        rc;
    SChar       sConStr[1024];  
    SQLINTEGER  sErrCode;
    SQLSMALLINT sErrMsgLen;
    SChar       sErrMsg[MSG_LEN];
    
    // ODBC Connection
    rc = SQLAllocEnv(&m_IEnv) ;
    IDE_TEST_RAISE( rc != SQL_SUCCESS, err_env );

    rc = SQLAllocConnect(m_IEnv,&m_ICon) ;
    IDE_TEST_RAISE( rc != SQL_SUCCESS, err_alloc_con );
     
    idlOS::sprintf(sConStr, "DSN=%s;UID=%s;PWD=%s;CONNTYPE=3;NLS_USE=%s;PORT_NO=%d", 
                   szHost, szUser, szPassword, szNLS, nPort);
    
    rc = SQLDriverConnect( m_ICon, NULL,
                           sConStr, SQL_NTS,
                           NULL, 0,
                           NULL, SQL_DRIVER_NOPROMPT );  
    IDE_TEST_RAISE( rc != SQL_SUCCESS, err_connect );

    rc = SQLAllocStmt(m_ICon,&m_IStmt) ;
    IDE_TEST_RAISE( rc != SQL_SUCCESS, err_stmt );

    return isql_true;

    IDE_EXCEPTION( err_env );
    {
        idlOS::printf("SQLAllocEnv Error !!!\n") ;
        return isql_false;
    }
    IDE_EXCEPTION( err_alloc_con );
    {
        idlOS::sprintf(m_ErrorMsg, "SQLAllocConnect Error !!!\n") ;
    }
    IDE_EXCEPTION( err_connect );
    {
        idlOS::sprintf(m_ErrorMsg, "Connect Error !!!\n");
    }
    IDE_EXCEPTION( err_stmt );
    {
        idlOS::sprintf(m_ErrorMsg, "SQLAllocStmt Error !!!\n") ;
    }
    IDE_EXCEPTION_END;

    SQLError ( m_IEnv, m_ICon, m_IStmt, NULL, &sErrCode,
               sErrMsg, MSG_LEN, &sErrMsgLen );
    idlOS::printf(" rCM_-%d : %s\n", sErrCode, sErrMsg);
    mErrorCode = sErrCode;

    return isql_false;
 }
 
SQLHSTMT iloSQLApi::getStmt()
{
    return m_IStmt;
}

isql_bool iloSQLApi::Tables()
{
    /* Declare buffers for result set data */
    SChar   szCatalog[STR_LEN], szSchema[STR_LEN];
    SChar   szTableName[STR_LEN], szTableType[STR_LEN];
    SChar   szRemarks[REM_LEN];

    /* Declare buffers for bytes available to return */
    SQLINTEGER cbCatalog, cbSchema, cbTableName;
    SQLINTEGER cbTableType, cbRemarks;

    SInt        nResult;
    SInt        i;
    SQLINTEGER  sErrCode;
    SQLSMALLINT sErrMsgLen;
    SChar       sErrMsg[MSG_LEN];

    /* SQLTables Execute */
    nResult = SQLTables(m_IStmt,
                        NULL, 0,      /* All catalogs */
                        NULL, 0,      /* All schemas  */
                        NULL, 0,      /* All tables   */
                        (SChar *)"TABLE", 5);     /* All columns  */
    IDE_TEST( nResult != SQL_SUCCESS );

    /* Bind columns in result set to buffers */
    SQLBindCol(m_IStmt, 1, ISP_C_STRING, szCatalog, STR_LEN,&cbCatalog);
    SQLBindCol(m_IStmt, 2, ISP_C_STRING, szSchema, STR_LEN, &cbSchema);
    SQLBindCol(m_IStmt, 3, ISP_C_STRING, szTableName, STR_LEN,&cbTableName);
    SQLBindCol(m_IStmt, 4, ISP_C_STRING, szTableType, STR_LEN, &cbTableType);
    SQLBindCol(m_IStmt, 5, ISP_C_STRING, szRemarks, STR_LEN, &cbRemarks);

    /* Get Column Name and Type */
    m_Column.SetSize(200);
    for (i=0; i<m_Column.GetSize(); )
    {
        nResult = SQLFetch(m_IStmt);
        if (nResult == SQL_SUCCESS)
        {
            if (idlOS::strcmp((SChar *)szTableType, "TABLE") == 0)
                m_Column.SetName(i++, szTableName);
        }
        else
            break;
    }

    m_Column.SetColumnCount(i);
    return isql_true;

    IDE_EXCEPTION_END;

    SQLError ( m_IEnv, m_ICon, m_IStmt, NULL, &sErrCode,
               sErrMsg, MSG_LEN, &sErrMsgLen );
    idlOS::sprintf(m_ErrorMsg, "Get Table List Error [%s]\n", sErrMsg);
    mErrorCode = sErrCode;

    return isql_false;
}

isql_bool iloSQLApi::Columns(SChar *inTableName, SChar *inTableOwner)
{
    /* Declare buffers for result set data */
    SChar   szCatalog[STR_LEN], szSchema[STR_LEN];
    SChar   szTableName[STR_LEN], szColumnName[STR_LEN];
    SChar   szTypeName[STR_LEN], szRemarks[REM_LEN];
    SChar   szColumnDefault[STR_LEN], szIsNullable[STR_LEN];
    ULong   ColumnSize, BufferLength, CharOctetLength, OrdinalPosition;
    short   DataType, DecimalDigits, NumPrecRadix, Nullable;
    short   SQLDataType, DatetimeSubtypeCode;
    SInt    retcode;
    SChar   szErrState[6];
    SChar   szErrText[MSG_LEN];
    SQLSMALLINT ulErrMsgLen;
    SQLINTEGER dwErrCode;
    SInt    sCount;
    SInt    sAllocCount;

    /* Declare buffers for bytes available to return */
    SQLINTEGER cbCatalog, cbSchema, cbTableName, cbColumnName;
    SQLINTEGER cbDataType, cbTypeName, cbColumnSize, cbBufferLength;
    SQLINTEGER cbDecimalDigits, cbNumPrecRadix, cbNullable, cbRemarks;
    SQLINTEGER cbColumnDefault, cbSQLDataType, cbDatetimeSubtypeCode, cbCharOctetLength;
    SQLINTEGER cbOrdinalPosition, cbIsNullable;

    if ( gProgOption.m_bExist_TabOwner == isql_false )
    {
        /* SQLColumns Execute */
        retcode = SQLColumns(m_IStmt,
                             NULL, 0,      /* All catalogs */
                             NULL, 0,      /* CUSTOMERS schemas */
                             inTableName,  idlOS::strlen(inTableName),  /* CUSTOMERS table */
                             NULL, 0);     /* All columns  */
    }
    else
    {
        /* SQLColumns Execute */
        retcode = SQLColumns(m_IStmt,
                             NULL, 0,      /* All catalogs */
                             inTableOwner, idlOS::strlen(inTableOwner), /* CUSTOMERS schemas */
                             inTableName,  idlOS::strlen(inTableName),  /* CUSTOMERS table */
                             NULL, 0);     /* All columns  */
    }
    IDE_TEST (retcode != SQL_SUCCESS);

    /* Bind columns in result set to buffers */
    SQLBindCol(m_IStmt, 1, ISP_C_STRING, szCatalog, STR_LEN,&cbCatalog);
    SQLBindCol(m_IStmt, 2, ISP_C_STRING, szSchema, STR_LEN, &cbSchema);
    SQLBindCol(m_IStmt, 3, ISP_C_STRING, szTableName, STR_LEN,&cbTableName);
    SQLBindCol(m_IStmt, 4, ISP_C_STRING, szColumnName, STR_LEN, &cbColumnName);
    SQLBindCol(m_IStmt, 5, ISP_C_SSHORT, &DataType, 0, &cbDataType);
    SQLBindCol(m_IStmt, 6, ISP_C_STRING, szTypeName, STR_LEN, &cbTypeName);
    SQLBindCol(m_IStmt, 7, ISP_C_SLONG, &ColumnSize, 0, &cbColumnSize);
    SQLBindCol(m_IStmt, 8, ISP_C_SLONG, &BufferLength, 0, &cbBufferLength);
    SQLBindCol(m_IStmt, 9, ISP_C_SSHORT, &DecimalDigits, 0, &cbDecimalDigits);
    SQLBindCol(m_IStmt, 10, ISP_C_SSHORT, &NumPrecRadix, 0, &cbNumPrecRadix);
    SQLBindCol(m_IStmt, 11, ISP_C_SSHORT, &Nullable, 0, &cbNullable);
    SQLBindCol(m_IStmt, 12, ISP_C_STRING, szRemarks, REM_LEN, &cbRemarks);
    SQLBindCol(m_IStmt, 13, ISP_C_STRING, szColumnDefault, STR_LEN, &cbColumnDefault);
    SQLBindCol(m_IStmt, 14, ISP_C_SSHORT, &SQLDataType, 0, &cbSQLDataType);
    SQLBindCol(m_IStmt, 15, ISP_C_SSHORT, &DatetimeSubtypeCode, 0, &cbDatetimeSubtypeCode);
    SQLBindCol(m_IStmt, 16, ISP_C_SLONG, &CharOctetLength, 0, &cbCharOctetLength);
    SQLBindCol(m_IStmt, 17, ISP_C_SLONG, &OrdinalPosition, 0, &cbOrdinalPosition);
    SQLBindCol(m_IStmt, 18, ISP_C_STRING, szIsNullable, STR_LEN, &cbIsNullable);

    /* Get Column Name and Type */
    sAllocCount = 1;
    IDE_TEST_RAISE( m_Column.SetSize(200) != isql_true, alloc_error );
    sCount = 0;
    retcode = SQLFetch(m_IStmt);
    while ( retcode != SQL_NO_DATA && retcode == SQL_SUCCESS )
    {
        sCount++;
        if ( sCount > sAllocCount * 200 )
        {
            IDE_TEST_RAISE( m_Column.resize( (sAllocCount + 1) * 200 )
                            != isql_true, alloc_error );
            sAllocCount++;
        }   

        m_Column.SetName(sCount-1, szColumnName);
        m_Column.SetType(sCount-1, DataType);
        m_Column.SetPrecision(sCount-1, ColumnSize);
        m_Column.SetScale(sCount-1, DecimalDigits);

        retcode = SQLFetch(m_IStmt);
    }

    if (sCount == 0)
    {
        idlOS::sprintf(m_ErrorMsg, "%s is not exist\n", inTableName);
        return isql_false;
    }

    m_Column.SetColumnCount(sCount);

    return isql_true;

    IDE_EXCEPTION( alloc_error );
    {
        idlOS::sprintf(m_ErrorMsg, "memory relloc error\n");
        return isql_false;
    }
    IDE_EXCEPTION_END;

    SQLError( m_IEnv, m_ICon, m_IStmt,
              szErrState, &dwErrCode,
              szErrText, MSG_LEN, &ulErrMsgLen);
    idlOS::sprintf( m_ErrorMsg, "SQLColumns (%s) is Failed [%s]\n",
                    inTableName, szErrText );
    mErrorCode = dwErrCode;

    return isql_false;
}

isql_bool iloSQLApi::Statistics(SChar *inTableName, SInt &nIndexCount, SIndexInfo **pIndexInfo)
{
    static SIndexInfo IndexInfo[MAX_INDEX_COUNT];
    SInt    nIndex = 0;

    /* Declare buffers for result set data */
    SChar   szCatalog[STR_LEN], szSchema[STR_LEN];              // unsigned char
    SChar   szTableName[STR_LEN], szIndexQualifier[STR_LEN];
    SChar   szIndexName[STR_LEN], szColumnName[STR_LEN];
    SChar   szSortSeq[STR_LEN], szsmiFilterCond[STR_LEN];
    ULong  lCardinality, lPages;   // long
    short sNonUnique, sType, sOrdinalPos;   // short

    SInt retcode;                            // short
    SChar szErrState[6];   // unsigned char
    SChar szErrText[MSG_LEN];
    SQLSMALLINT ulErrMsgLen;      // short int
    SQLINTEGER dwErrCode;        // long int

    /* Declare buffers for bytes available to return */
    SQLINTEGER cbCatalog, cbSchema, cbTableName, cbNonUnique;
    SQLINTEGER cbIndexQualifier, cbIndexName, cbType, cbOrdinalPos;
    SQLINTEGER cbColumnName, cbSortSeq, cbCardinality, cbPages;
    SQLINTEGER cbsmiFilterCond;

    /* SQLColumns Execute */
    retcode = SQLStatistics(m_IStmt,
                            NULL, 0,      /* All catalogs */
                            NULL, 0,      /* All schemas   */
                            inTableName, idlOS::strlen(inTableName), /* CUSTOMERS table */
                            SQL_INDEX_ALL, 0);     /* All columns  */

    if (retcode != SQL_SUCCESS)
    {
        SQLError(m_IEnv, m_ICon, m_IStmt, szErrState, &dwErrCode, szErrText, MSG_LEN, &ulErrMsgLen);
        idlOS::sprintf(m_ErrorMsg, "SQLColumns (%s) is Failed [%s]\n", inTableName, szErrText) ;
        mErrorCode = dwErrCode;
        return isql_false;
    }

    /* Bind columns in result set to buffers */
    SQLBindCol(m_IStmt, 1, ISP_C_STRING, szCatalog, STR_LEN,&cbCatalog);
    SQLBindCol(m_IStmt, 2, ISP_C_STRING, szSchema, STR_LEN, &cbSchema);
    SQLBindCol(m_IStmt, 3, ISP_C_STRING, szTableName, STR_LEN,&cbTableName);
    SQLBindCol(m_IStmt, 4, ISP_C_SSHORT, &sNonUnique, 0, &cbNonUnique);
    SQLBindCol(m_IStmt, 5, ISP_C_STRING, szIndexQualifier, STR_LEN, &cbIndexQualifier);
    SQLBindCol(m_IStmt, 6, ISP_C_STRING, szIndexName, STR_LEN, &cbIndexName);
    SQLBindCol(m_IStmt, 7, ISP_C_SSHORT, &sType, 0, &cbType);
    SQLBindCol(m_IStmt, 8, ISP_C_SSHORT, &sOrdinalPos, 0, &cbOrdinalPos);
    SQLBindCol(m_IStmt, 9, ISP_C_STRING, szColumnName, STR_LEN, &cbColumnName);
    SQLBindCol(m_IStmt, 10, ISP_C_STRING, szSortSeq, STR_LEN, &cbSortSeq);
    SQLBindCol(m_IStmt, 11, ISP_C_SLONG, &lCardinality, 0, &cbCardinality);
    SQLBindCol(m_IStmt, 12, ISP_C_SLONG, &lPages, 0, &cbPages);
    SQLBindCol(m_IStmt, 13, ISP_C_STRING, szsmiFilterCond, STR_LEN, &cbsmiFilterCond);

    /* Get Index Infomation */
    for (nIndex=0; nIndex<MAX_INDEX_COUNT; )
    {
        retcode = SQLFetch(m_IStmt);

        if (retcode == SQL_SUCCESS)
        {
            if (idlOS::strlen((SChar *)szColumnName) == 0)
                continue;

            idlOS::strcpy(IndexInfo[nIndex].m_IndexName, (SChar *)szIndexName);
            idlOS::strcpy(IndexInfo[nIndex].m_ColumnName, (SChar *)szColumnName);
            IndexInfo[nIndex].m_bSortAsc = (idlOS::strcmp((SChar *)szSortSeq, "A") == 0) ? isql_true : isql_false;
            IndexInfo[nIndex].m_OrdinalPos = sOrdinalPos;
            IndexInfo[nIndex].m_bNonUnique = (sNonUnique == 1) ? isql_true : isql_false;
            nIndex++;
        }
        else
        {
            break;
        }
    }

    if (nIndex == 0)
    {
        idlOS::sprintf(m_ErrorMsg, "%s is not have index\n", inTableName);
        return isql_false;
    }

    nIndexCount = nIndex;
    (*pIndexInfo) = IndexInfo;
    return isql_true;
}

isql_bool iloSQLApi::ExecuteDirect()
{
    SInt nResult;
    SChar szErrState[6];
    SChar szErrText[MSG_LEN];
    SQLSMALLINT ulErrMsgLen;     
    SQLINTEGER dwErrCode;        

    SQLFreeStmt(m_IStmt, SQL_RESET_PARAMS);
    nResult = SQLExecDirect(m_IStmt, m_SQLStatement, idlOS::strlen(m_SQLStatement));
    if (nResult != SQL_SUCCESS && nResult != SQL_NO_DATA)
    {
        SQLError(m_IEnv, m_ICon, m_IStmt, szErrState, &dwErrCode, szErrText, MSG_LEN, &ulErrMsgLen);
        idlOS::sprintf(m_ErrorMsg, "Execute Error (%s) [%s]\n", m_SQLStatement, szErrText) ;
        mErrorCode = dwErrCode;
        return isql_false;
    }

    return isql_true;
}

isql_bool iloSQLApi::Execute()
{
    SInt nResult;
    SChar szErrState[6];
    SChar szErrText[MSG_LEN];
    SQLSMALLINT ulErrMsgLen;    
    SQLINTEGER dwErrCode;       

    nResult = SQLExecute(m_IStmt);
    if (nResult != SQL_SUCCESS && nResult != SQL_NO_DATA)
    {
        SQLError(m_IEnv, m_ICon, m_IStmt, szErrState, &dwErrCode, szErrText, MSG_LEN, &ulErrMsgLen);
        idlOS::sprintf(m_ErrorMsg, "Execute Error (%s) [%s]\n", m_SQLStatement, szErrText) ;
        mErrorCode = dwErrCode;
        return isql_false;
    }

    return isql_true;
}

isql_bool iloSQLApi::Prepare(SChar * /*szSQLStmt*/, SInt /*nAttrCount*/)
{
    SInt nResult;
    SChar szErrState[6];
    SChar szErrText[MSG_LEN];
    SQLSMALLINT ulErrMsgLen;     
    SQLINTEGER dwErrCode;        

    nResult = SQLPrepare(m_IStmt, m_SQLStatement, SQL_NTS);
    if (nResult != SQL_SUCCESS)
    {
        SQLError(m_IEnv, m_ICon, m_IStmt, szErrState, &dwErrCode, szErrText, MSG_LEN, &ulErrMsgLen);
        idlOS::sprintf(m_ErrorMsg, "Execute Error (%s) [%s]\n", m_SQLStatement, szErrText) ;
        idlOS::fprintf(stderr, "Execute Error (%s) [%s]\n", m_SQLStatement, szErrText) ;
        mErrorCode = dwErrCode;
        return isql_false;
    }

    return isql_true;
}

isql_bool iloSQLApi::SelectExecute(iloTableInfo  *aTableInfo)
{
    SInt nResult;
    SChar szErrState[6];
    SChar szErrText[MSG_LEN];
    SQLSMALLINT ulErrMsgLen;  
    SQLINTEGER dwErrCode;     
    SInt i;
    SQLSMALLINT ulCols;

    SQLSMALLINT  swCol, swType, swScale, swNull;
    SQLINTEGER     usPricision;

    SQLFreeStmt(m_IStmt, SQL_RESET_PARAMS);
    nResult = SQLExecDirect(m_IStmt, m_SQLStatement, idlOS::strlen(m_SQLStatement)) ;
    if (nResult != SQL_SUCCESS)
    {
        SQLError(m_IEnv, m_ICon, m_IStmt, szErrState, &dwErrCode, szErrText, MSG_LEN, &ulErrMsgLen);
        idlOS::sprintf(m_ErrorMsg, "Query Error (%s) [%s]\n", m_SQLStatement, szErrText) ;
        mErrorCode = dwErrCode;
        return isql_false;
    }

    nResult = SQLNumResultCols(m_IStmt, &ulCols) ;
    if (nResult != SQL_SUCCESS)
    {
        SQLError(m_IEnv, m_ICon, m_IStmt, szErrState, &dwErrCode, szErrText, MSG_LEN, &ulErrMsgLen);
        idlOS::sprintf(m_ErrorMsg, "Get Column Count Fail [%s]\n", szErrText);
        return isql_false;
    }
    m_Column.SetSize(ulCols);
    for (i=0; i<m_Column.GetSize(); i++)
    {
        SQLDescribeCol(m_IStmt, i+1, m_Column.m_Name[i], 256, &swCol, &swType, &usPricision, &swScale, &swNull);
        m_Column.SetType(i, swType);
        m_Column.SetPrecision(i, usPricision);
        m_Column.SetScale(i, swScale);

        switch (swType)
        {
        case ISP_CHAR :
            SQLBindCol(m_IStmt, i+1, ISP_C_STRING, &m_Column.m_Value[i], MAX_VARCHAR_SIZE-1, &m_Column.m_Len[i]);
            break;
        case ISP_VARCHAR :
            SQLBindCol(m_IStmt, i+1, ISP_C_STRING, &m_Column.m_Value[i], MAX_VARCHAR_SIZE-1, &m_Column.m_Len[i]);
            break;
        case ISP_BIT :
            SQLBindCol(m_IStmt, i+1, SQL_C_CHAR, &m_Column.m_Value[i], MAX_VARCHAR_SIZE-1, &m_Column.m_Len[i]);
            break;
//            idlOS::sprintf(m_ErrorMsg, "Query Error (%s) [BIT 은 표시할 수 없습니다.]\n", m_SQLStatement);
//            return isql_false;
        case ISP_TNUMERIC :
        case ISP_NUMERIC :
        case SQL_DECIMAL :
        case SQL_FLOAT     :
            if ( gProgOption.mNoExp == isql_true )
            {
                SQLBindCol(m_IStmt,
                           i+1,
                           SQL_C_CHAR,
                           &m_Column.m_Value[i],
                           MAX_VARCHAR_SIZE-1,
                           &m_Column.m_Len[i]);
            }
            else
            {
                if ( aTableInfo->mNoExpFlag[i] == 1 )
                {
                    SQLBindCol(m_IStmt,
                               i+1,
                               SQL_C_CHAR,
                               &m_Column.m_Value[i],
                               MAX_VARCHAR_SIZE-1,
                               &m_Column.m_Len[i]);
                }
                else
                {
                    SQLBindCol(m_IStmt,
                               i+1,
                               ILO_C_CHAR,
                               &m_Column.m_Value[i],
                               MAX_VARCHAR_SIZE-1,
                               &m_Column.m_Len[i]);
                }
            }
            break;
        case SQL_DOUBLE :
        case SQL_REAL     :
            SQLBindCol(m_IStmt, i+1, ISP_C_STRING, &m_Column.m_Value[i], MAX_VARCHAR_SIZE-1, &m_Column.m_Len[i]);
            break;
        case ISP_DATE :
        case SQL_DATE :
            SQLBindCol(m_IStmt, i+1, ISP_C_STRING, &m_Column.m_Value[i], MAX_VARCHAR_SIZE-1, &m_Column.m_Len[i]);
            break;
        case ISP_BYTES :
            SQLBindCol(m_IStmt, i+1, ISP_C_STRING, &m_Column.m_Value[i], MAX_VARCHAR_SIZE-1, &m_Column.m_Len[i]);
            break;
        case ISP_NIBBLE :
            SQLBindCol(m_IStmt, i+1, ISP_C_STRING, &m_Column.m_Value[i], MAX_VARCHAR_SIZE-1, &m_Column.m_Len[i]);
            break;
        case ISP_INTEGER :
        case SQL_BIGINT  :
        case SQL_SMALLINT:
            SQLBindCol(m_IStmt, i+1, ISP_C_STRING, &m_Column.m_Value[i], MAX_VARCHAR_SIZE-1, &m_Column.m_Len[i]);
            break;
        
        default :
            idlOS::sprintf(m_ErrorMsg, "Query Error (%s) [알려지지 않은 타입이 사용되었습니다.]\n", m_SQLStatement);
            return isql_false;
        }

    }

    return isql_true;
}

isql_bool iloSQLApi::Fetch()
{
    SInt        rc;
    SChar       sErrState[6];
    SChar       sErrMsg[MSG_LEN];
    SQLSMALLINT sErrMsgLen;     
    SQLINTEGER  sErrCode;        

    if (m_Column.GetSize() == 0)
    {
        idlOS::sprintf(m_ErrorMsg, "Fetch Error (Wrong Column Count) !!!\n") ;
        return isql_false;
    }

    UInt size = 1000;
    SQLSetStmtAttr(m_IStmt, SQL_ATTR_MAX_ROWS, (void*)size, 0);
    rc = SQLFetch(m_IStmt);
    if (rc == SQL_ERROR)
    {
        SQLError(m_IEnv, m_ICon, m_IStmt,
                 sErrState, &sErrCode, sErrMsg, MSG_LEN, &sErrMsgLen);
        idlOS::sprintf(m_ErrorMsg, "SQLFetch Error[%s] !!!\n", sErrMsg) ;
        idlOS::fprintf(stdout, "[ERR-%05X : %s]\n", sErrCode, sErrMsg);
        mErrorCode = sErrCode;
        return isql_false;
    }
    else if (rc == SQL_NO_DATA)
        return isql_false;
    else
        return isql_true;
}

isql_bool iloSQLApi::AutoCommit(isql_bool bIsCommitOn)
{
    SInt nResult;
    SChar szErrState[6];
    SChar szErrText[MSG_LEN];
    SQLSMALLINT ulErrMsgLen;     
    SQLINTEGER dwErrCode;        
    if (bIsCommitOn)
    {
        nResult = SQLSetConnectAttr(m_ICon, SQL_ATTR_AUTOCOMMIT, (void*)SQL_AUTOCOMMIT_ON, 0);
    }
    else
    {
        nResult = SQLSetConnectAttr(m_ICon, SQL_ATTR_AUTOCOMMIT, (void*)SQL_AUTOCOMMIT_OFF, 0);
    }
    if (nResult == SQL_ERROR)
    {
        SQLError(m_IEnv, m_ICon, m_IStmt, szErrState, &dwErrCode, szErrText, MSG_LEN, &ulErrMsgLen);
        if (bIsCommitOn)
            idlOS::sprintf(m_ErrorMsg, "Set AutoCommit On Fail [%s]\n", szErrText);
        else
            idlOS::sprintf(m_ErrorMsg, "Set AutoCommit Off Fail [%s]\n", szErrText);
        mErrorCode = dwErrCode;
        return isql_false;
    }

    return isql_true;
}

isql_bool iloSQLApi::EndTran(isql_bool bIsCommit)
{
    SInt nResult;
    SChar szErrState[6];
    SChar szErrText[MSG_LEN];
    SQLSMALLINT ulErrMsgLen;   
    SQLINTEGER dwErrCode;    
      
    if (bIsCommit)
        nResult = SQLEndTran(SQL_HANDLE_DBC, m_ICon, SQL_COMMIT);
    else
        nResult = SQLEndTran(SQL_HANDLE_DBC, m_ICon, SQL_ROLLBACK);
    if (nResult != SQL_SUCCESS)
    {
        SQLError(m_IEnv, m_ICon, m_IStmt, szErrState, &dwErrCode, szErrText, MSG_LEN, &ulErrMsgLen);
        idlOS::sprintf(m_ErrorMsg, "Execute Error (%s) [%s]\n", m_SQLStatement, szErrText);
        mErrorCode = dwErrCode;
        return isql_false;
    }

    return isql_true;
}

isql_bool iloSQLApi::setQueryTimeOut( SInt aTime )
{
    SQLRETURN   rc;
    SQLSMALLINT sErrMsgLen;     
    SQLINTEGER  sErrCode;        
    SChar       sQuery[50];
    SChar       sErrState[6];
    SChar       sErrMsg[MSG_LEN];
    SQLHSTMT    sStmt = SQL_NULL_HSTMT;

    idlOS::sprintf(sQuery, "alter session set query_timeout=%d", aTime );

    rc = SQLAllocStmt( m_ICon, &sStmt );
    IDE_TEST_RAISE( rc != SQL_SUCCESS, err_alloc );

    rc = SQLExecDirect( sStmt, sQuery, SQL_NTS );
    IDE_TEST_RAISE( rc != SQL_SUCCESS, err_exec );

    SQLFreeStmt( sStmt, SQL_DROP );

    return isql_true;

    IDE_EXCEPTION( err_alloc );
    {
        SQLError( m_IEnv, m_ICon, sStmt,
                  sErrState, &sErrCode,
                  sErrMsg, MSG_LEN,
                  &sErrMsgLen );
        idlOS::sprintf(m_ErrorMsg, "Set Query Timeout On Fail [%s]\n", sErrMsg);
        mErrorCode = sErrCode;
    }
    IDE_EXCEPTION( err_exec );
    {
        SQLError( m_IEnv, m_ICon, sStmt,
                  sErrState, &sErrCode,
                  sErrMsg, MSG_LEN,
                  &sErrMsgLen );
        idlOS::sprintf(m_ErrorMsg, "Set Query Timeout On Fail [%s]\n", sErrMsg);
        mErrorCode = sErrCode;

        SQLFreeStmt( sStmt, SQL_DROP );
    }
    IDE_EXCEPTION_END;

    return isql_false;
}

isql_bool iloSQLApi::alterReplication( isql_bool aBool )
{
    SQLRETURN   rc;
    SQLSMALLINT sErrMsgLen;     
    SQLINTEGER  sErrCode;        
    SChar       sQuery[50];
    SChar       sErrState[6];
    SChar       sErrMsg[MSG_LEN];
    SQLHSTMT    sStmt = SQL_NULL_HSTMT;

    if ( aBool == isql_true )
    {
        idlOS::sprintf(sQuery, "alter session set replication=true");
    }
    else
    {
        idlOS::sprintf(sQuery, "alter session set replication=false");
    }

    rc = SQLAllocStmt( m_ICon, &sStmt );
    IDE_TEST_RAISE( rc != SQL_SUCCESS, err_alloc );

    rc = SQLExecDirect( sStmt, sQuery, SQL_NTS );
    IDE_TEST_RAISE( rc != SQL_SUCCESS, err_exec );

    SQLFreeStmt( sStmt, SQL_DROP );

    return isql_true;

    IDE_EXCEPTION( err_alloc );
    {
        SQLError( m_IEnv, m_ICon, sStmt,
                  sErrState, &sErrCode,
                  sErrMsg, MSG_LEN,
                  &sErrMsgLen );
        idlOS::sprintf(m_ErrorMsg, "Alter Replication [%s]\n", sErrMsg);
        mErrorCode = sErrCode;
    }
    IDE_EXCEPTION( err_exec );
    {
        SQLError( m_IEnv, m_ICon, sStmt,
                  sErrState, &sErrCode,
                  sErrMsg, MSG_LEN,
                  &sErrMsgLen );
        idlOS::sprintf(m_ErrorMsg, "Alter Replication [%s]\n", sErrMsg);
        mErrorCode = sErrCode;

        SQLFreeStmt( sStmt, SQL_DROP );
    }
    IDE_EXCEPTION_END;

    return isql_false;
}
isql_bool iloSQLApi::StmtClose()
{
    SInt nResult = SQLFreeStmt(m_IStmt, SQL_DROP);
    if (nResult == SQL_ERROR)
    {
        idlOS::sprintf(m_ErrorMsg, "SQLFreeStmt Error !!!\n") ;
        return isql_false;
    }

    return isql_true;
}

isql_bool iloSQLApi::Close()
{
    SInt nResult;

    // ODBC DisConnect
    nResult = SQLFreeStmt(m_IStmt, SQL_DROP) ;
    if (nResult == SQL_ERROR)
    {
        idlOS::sprintf(m_ErrorMsg, "SQLFreeStmt Error !!!") ;
        return isql_false;
    }

    nResult = SQLDisconnect(m_ICon) ;
    if (nResult == SQL_ERROR)
    {
        idlOS::sprintf(m_ErrorMsg, "SQLDisconnect Error !!!\n") ;
        return isql_false;
    }

    nResult = SQLFreeConnect(m_ICon) ;
    if (nResult == SQL_ERROR)
    {
        idlOS::sprintf(m_ErrorMsg, "SQLFreeConnect Error !!!\n") ;
        return isql_false;
    }

    nResult = SQLFreeEnv(m_IEnv);
    if (nResult == SQL_ERROR)
    {
        idlOS::sprintf(m_ErrorMsg, "SQLFreeEnv Error !!!\n");
        return isql_false;
    }
    return isql_true;
}

