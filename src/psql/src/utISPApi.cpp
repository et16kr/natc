/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: utISPApi.cpp 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/

#include <idl.h> 
#include <ideErrorMgr.h>
#include <utISPApi.h>
#include <ulAmi.h>

//#define _ISPAPI_DEBUG

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

SLong Strtoll(const char *nptr, char **endptr, int base)
{
    const char *s = nptr;
    ULong acc;
    int c;
    ULong cutoff;
    int neg = 0, any, cutlim;

    /*
     * Skip white space and pick up leading +/- sign if any.
     * If base is 0, allow 0x for hex and 0 for octal, else
     * assume decimal; if base is already 16, allow 0x.
     */
    do {
            c = *s++;
    } while (c == ' ' || c == '\t');
    if (c == '-') {
            neg = 1;
            c = *s++;
    } else if (c == '+')
            c = *s++;
    if ((base == 0 || base == 16) &&
        c == '0' && (*s == 'x' || *s == 'X')) {
            c = s[1];
            s += 2;
            base = 16;
    }
    if (base == 0)
            base = c == '0' ? 8 : 10;

    /*
     * Compute the cutoff value between legal numbers and illegal
     * numbers.  That is the largest legal value, divided by the
     * base.  An input number that is greater than this value, if
     * followed by a legal input character, is too big.  One that
     * is equal to this value may be valid or not; the limit
     * between valid and invalid numbers is then based on the last
     * digit.  For instance, if the range for long longs is
     * [-2147483648..2147483647] and the input base is 10,
     * cutoff will be set to 214748364 and cutlim to either
     * 7 (neg==0) or 8 (neg==1), meaning that if we have accumulated
     * a value > 214748364, or equal but the next digit is > 7 (or 8),
     * the number is too big, and we will return a range error.
     *
     * Set any if any `digits' consumed; make it negative to indicate
     * overflow.
     */
    cutoff = neg ? -(ULong)LONG_LONG_MIN : LONG_LONG_MAX;
    cutlim = cutoff % (ULong)base;
    cutoff /= (ULong)base;

    for (acc = 0, any = 0;; c = *s++) {
            if (isdigit(c))
                    c -= '0';
            else
                    break;
            if (c >= base)
                    break;
            if (any < 0 || acc > cutoff || acc == cutoff && c > cutlim)
                    any = -1;
            else {
                    any = 1;
                    acc *= base;
                    acc += c;
            }
    }
    if (any < 0) {
            acc = neg ? LONG_LONG_MIN : LONG_LONG_MAX;
            errno = ERANGE;
    } else if (neg)
            acc = -acc;
    if (endptr != 0)
            *endptr = (char *) (any ? s - 1 : nptr);
    return (acc);
}

utColumns::utColumns()
{
    m_Name       = NULL;
    m_UserName   = NULL;
    m_Value      = NULL;
    m_Type       = NULL;
    m_Precision  = NULL;
    m_Scale      = NULL;
    m_Null       = NULL;
    m_Len        = NULL;
    m_Col        = 0;
    m_IsChar     = NULL;
    m_IsVaring   = NULL;
    m_CValue   = NULL;
}

utColumns::~utColumns()
{
    if (m_Name       != NULL) delete [] m_Name;
    if (m_UserName   != NULL) delete [] m_UserName;
    if (m_Value      != NULL) delete [] m_Value;
    if (m_Type       != NULL) delete [] m_Type;
    if (m_Precision  != NULL) delete [] m_Precision;
    if (m_Scale      != NULL) delete [] m_Scale;
    if (m_Null       != NULL) delete [] m_Null;
    if (m_Len        != NULL) delete [] m_Len;
    if (m_IsChar     != NULL) delete [] m_IsChar;
    if (m_IsVaring   != NULL) delete [] m_IsVaring;
}

void utColumns::freeMem()
{
    int i;

    if (m_Name != NULL) 
    {
        delete [] m_Name;
        m_Name = NULL;
    }

    if (m_UserName != NULL) 
    {
        delete [] m_UserName;
        m_UserName = NULL;
    }

    if (m_Type != NULL) 
    {
        delete [] m_Type;
        m_Type = NULL;
    }

    if (m_Precision != NULL) 
    {
        delete [] m_Precision;
        m_Precision = NULL;
    }

    if (m_Scale != NULL) 
    {
        delete [] m_Scale;
        m_Scale = NULL;
    }

    if (m_Null != NULL) 
    {
        delete [] m_Null;
        m_Null = NULL;
    }

    if (m_Len != NULL) 
    {
        delete [] m_Len;
        m_Len = NULL;
    }

    if (m_Value != NULL) 
    {
        delete [] m_Value;
        m_Value = NULL;
    }

    if (m_CValue != NULL) 
    {
        for (i=0; i<m_Col; i++)
        {
            if (m_CValue[i] != NULL)
            {
                idlOS::free(m_CValue[i]);
                m_CValue[i] = NULL;
            }
        }

        idlOS::free(m_CValue);
        m_CValue = NULL;
    }

    if (m_IsChar != NULL) 
    {
        delete [] m_IsChar;
        m_IsChar = NULL;
    }

    if (m_IsVaring != NULL) 
    {
        delete [] m_IsVaring;
        m_IsVaring = NULL;
    }

    m_Col = 0;
}

IDE_RC utColumns::SetSize(SInt a_ColCount)
{
    int i;

    m_Name = new SChar [a_ColCount][QP_MAX_NAME_LEN+1];
    IDE_TEST(m_Name == NULL);

    m_UserName = new SChar [a_ColCount][QP_MAX_NAME_LEN+1];
    IDE_TEST(m_UserName == NULL);

    m_Value = new union ColumnValue [a_ColCount];
    IDE_TEST(m_Value == NULL);

    m_IsChar = new idBool [a_ColCount];
    IDE_TEST(m_IsChar == NULL);
    for (i=0; i<a_ColCount; i++)
    {
        m_IsChar[i] = ID_FALSE;
    }

    m_CValue = (SChar**)idlOS::calloc( a_ColCount, sizeof(SChar*) );
    IDE_TEST(m_CValue == NULL);
    
    m_Type = new SInt [a_ColCount];
    IDE_TEST(m_Type == NULL);

    m_Precision = new SInt [a_ColCount];
    IDE_TEST(m_Precision == NULL);

    m_Scale = new SInt [a_ColCount];
    IDE_TEST(m_Scale == NULL);

    m_Null = new SInt [a_ColCount];
    IDE_TEST(m_Null == NULL);

    m_Len = new SInt [a_ColCount];
    IDE_TEST(m_Len == NULL);

    m_IsVaring = new SChar [a_ColCount][QP_MAX_NAME_LEN+1];
    IDE_TEST(m_IsVaring == NULL);

    m_Col = a_ColCount;

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC utColumns::SetValueSize(SInt a_Col, SInt a_Size)
{
    m_CValue[a_Col] = (SChar*)idlOS::malloc(a_Size);
    IDE_TEST(m_CValue[a_Col] == NULL);

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC utColumns::SetName(SInt a_Col, SChar *a_Name)
{
    IDE_TEST(a_Col >= m_Col);

    idlOS::strcpy(m_Name[a_Col], a_Name);

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC utColumns::SetUserName(SInt a_Col, SChar *a_UserName)
{
    IDE_TEST(a_Col >= m_Col);

    idlOS::strcpy(m_UserName[a_Col], a_UserName);

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC utColumns::SetType(SInt a_Col, SInt a_Type)
{
    IDE_TEST(a_Col >= m_Col);

    m_Type[a_Col] = a_Type;

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC utColumns::SetPrecision(SInt a_Col, SInt a_Precision)
{
    IDE_TEST(a_Col >= m_Col);

    m_Precision[a_Col] = a_Precision;

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC utColumns::SetScale(SInt a_Col, SInt a_Scale)
{
    IDE_TEST(a_Col >= m_Col);

    m_Scale[a_Col] = a_Scale;

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC utColumns::SetNull(SInt a_Col, SInt a_Nullable)
{
    IDE_TEST(a_Col >= m_Col);

    m_Null[a_Col] = a_Nullable;

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC utColumns::SetIsVaring(SInt a_Col, SChar *a_IsVaring)
{
    IDE_TEST(a_Col >= m_Col);

    idlOS::strcpy(m_IsVaring[a_Col], a_IsVaring);

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

utISPApi::utISPApi(SInt a_bufSize)
{
    m_IEnv          = SQL_NULL_HENV;
    m_ICon          = SQL_NULL_HDBC;
    m_IStmt         = SQL_NULL_HSTMT;
    m_TmpStmt       = SQL_NULL_HSTMT;    
    m_TmpStmt2      = SQL_NULL_HSTMT;    
    m_TmpStmt3      = SQL_NULL_HSTMT;    
    m_Query[0]      = '\0';
    m_ErrorMsg[0]   = '\0';
    m_ErrorState[0] = '\0';

    if ( (m_Buf = (SChar*)idlOS::malloc(a_bufSize)) == NULL )
    {
        idlOS::fprintf(stderr, "Memory allocation error!!! --- (%d, %s)\n", __LINE__, __FILE__);
        exit(0);
    }
    idlOS::memset(m_Buf, 0x00, a_bufSize);
}

utISPApi::~utISPApi()
{
    idlOS::free(m_Buf);
}

IDE_RC utISPApi::SetQuery(SChar *a_query)
{
    IDE_TEST(a_query == NULL);

    idlOS::strcpy(m_Query, a_query);

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC utISPApi::SetErrorMsgWithDBC(SQLHDBC a_con)
{
    SInt   errNo;
    SShort msgLength;
    SChar  errMsg[IDCCLI_ERROR_MSG_LEN];

    IDE_TEST_RAISE( m_IEnv == SQL_NULL_HENV || a_con == SQL_NULL_HDBC, 
            not_connected );

    IDE_TEST(SQLError(m_IEnv, a_con, NULL, m_ErrorState, &errNo, errMsg, 
                      IDCCLI_ERROR_MSG_LEN, &msgLength) != IDE_SUCCESS);

    if ( idlOS::strcmp(m_ErrorState, "08S01") == 0 )
    {
        idlOS::strcpy(m_ErrorMsg, 
                      (SChar*)"Communication failure.\nConnection closed.\n");  
    }
    else if ( idlOS::strcmp(m_ErrorState, "CIDLE") == 0 )
    {
		idlOS::sprintf(m_ErrorMsg, "[%s]\n", errMsg);
    }
    else
    {
        idlOS::sprintf(m_ErrorMsg, "[ERR-%05X : %s]\n", errNo, errMsg);
    }

    return IDE_SUCCESS;

    IDE_EXCEPTION(not_connected);
    {
        idlOS::sprintf(m_ErrorMsg, "Not connected.\n");
    }

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC utISPApi::SetErrorMsgWithStmt(SQLHSTMT a_stmt)
{
    SInt   errNo;
    SShort msgLength;
    SChar  errMsg[IDCCLI_ERROR_MSG_LEN];

    IDE_TEST_RAISE( m_IEnv == SQL_NULL_HENV || m_ICon == SQL_NULL_HDBC || a_stmt == SQL_NULL_HSTMT, not_connected);

    IDE_TEST_RAISE(SQLError(m_IEnv, m_ICon, a_stmt, m_ErrorState, &errNo, errMsg, 
                            IDCCLI_ERROR_MSG_LEN, &msgLength) != IDE_SUCCESS, error);

    if ( idlOS::strcmp(m_ErrorState, "08S01") == 0 )
    {
        idlOS::strcpy(m_ErrorMsg, (SChar*)"Communication failure.\nConnection closed.\n");  
    }
    else
    {
        idlOS::sprintf(m_ErrorMsg, "[ERR-%05X : %s]\n", errNo, errMsg);
        StmtClose(a_stmt);
    }

    return IDE_SUCCESS;

    IDE_EXCEPTION(error);
    {
        StmtClose(a_stmt);
    }

    IDE_EXCEPTION(not_connected);
    {
        idlOS::sprintf(m_ErrorMsg, "Not connected.\n");
    }

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC utISPApi::SetErrorMsg()
{
    SInt   errNo;
    SShort msgLength;
    SChar  errMsg[IDCCLI_ERROR_MSG_LEN];

    IDE_TEST_RAISE(m_IEnv == SQL_NULL_HENV || m_ICon == SQL_NULL_HDBC, not_connected);

    IDE_TEST(SQLError(m_IEnv, m_ICon, NULL, m_ErrorState, &errNo, errMsg, IDCCLI_ERROR_MSG_LEN, &msgLength) != IDE_SUCCESS);

    if ( idlOS::strcmp(m_ErrorState, "08S01") == 0 )
    {
        idlOS::strcpy(m_ErrorMsg, (SChar*)"Communication failure.\nConnection closed.\n");  
    }
    else if ( idlOS::strcmp(m_ErrorState, "CIDLE") == 0 )
    {
		idlOS::sprintf(m_ErrorMsg, "[%s]\n", errMsg);
    }
    else
    {
        idlOS::sprintf(m_ErrorMsg, "[ERR-%05X : %s]\n", errNo, errMsg);
    }

    return IDE_SUCCESS;

    IDE_EXCEPTION(not_connected);
    {
        idlOS::sprintf(m_ErrorMsg, "Not connected.\n");
    }

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

void utISPApi::SetErrorMsg(SChar *a_errMsg)
{
   idlOS::sprintf(m_ErrorMsg, "[ERR-00000 : %s]\n", a_errMsg);
}

void utISPApi::SetMsg(SChar *a_msg)
{
   idlOS::sprintf(m_ErrorMsg, "%s\n", a_msg);
}

SQLRETURN utISPApi::Open(SChar *a_Host,
                         SChar *a_User,
                         SChar *a_Passwd,
                         SChar *a_NLS,
                         SInt   a_Port,
                         SInt   a_Conntype,
                         MESSAGE_CALLBACK_STRUCT *a_MessageCallbackStruct)
{
    SQLRETURN rc;
    SChar connStr[1024];

    IDE_TEST_RAISE(SQLAllocEnv(&m_IEnv) != IDE_SUCCESS, alloc_env_error);

    IDE_TEST_RAISE(SQLAllocConnect(m_IEnv,&m_ICon) != IDE_SUCCESS, alloc_con_error);

    /*
    IDE_TEST_RAISE(SQLSetConnectAttr(m_ICon, SQL_ATTR_MESSAGE_CALLBACK, (void*)a_MessageCallbackStruct, 0) != IDE_SUCCESS, 
                        set_con_attr_error);
    */
#if !defined (VC_WIN32) && !defined (NTO_QNX)
    if (a_Conntype == 1)
#else
    if (a_Conntype == 1 || a_Conntype == 2)
#endif
    {
        sprintf(connStr, "DSN=%s;UID=%s;PWD=%s;CONNTYPE=%d;NLS_USE=%s;PORT_NO=%d",
                    a_Host, a_User, a_Passwd, a_Conntype, a_NLS, a_Port);
    }
    else if ( a_Conntype == 5 )
    {
        sprintf(connStr, 
#if !defined (VC_WIN32) && !defined (NTO_QNX)
                    "DSN=%s;UID=%s;PWD=%s;CONNTYPE=%d;NLS_USE=%s", 
                    a_Host, a_User, a_Passwd, a_Conntype, a_NLS);
#else
                    "DSN=%s;UID=%s;PWD=%s;CONNTYPE=%d;NLS_USE=%s;PORT_NO=%d",
                    a_Host, a_User, a_Passwd, a_Conntype, a_NLS, a_Port);
#endif
    }
    else
    {
        sprintf(connStr, "DSN=%s;UID=%s;PWD=%s;CONNTYPE=%d;NLS_USE=%s", 
                    a_Host, a_User, a_Passwd, a_Conntype, a_NLS);
    }

    /*
    rc = SQLDriverConnect(m_ICon, NULL,
                    connStr, SQL_NTS,
                    NULL, 0, NULL, SQL_DRIVER_NOPROMPT);
    */
    sprintf ((char *)connStr, "%s:%d", a_Host, a_Port);
    rc = SQLConnect(m_ICon, (SQLCHAR*)(connStr), SQL_NTS, a_User, SQL_NTS, a_Passwd, SQL_NTS);
    if ( a_Conntype == 5 && rc != SQL_SUCCESS )
    {
        IDE_RAISE(admin_connect_error);
    }
    else if ( rc == SQL_ERROR )
    {
        IDE_RAISE(alloc_driverCon_error);
    }

    IDE_TEST_RAISE(SQLAllocStmt(m_ICon,&m_IStmt) != IDE_SUCCESS, alloc_stmt_error);
    IDE_TEST_RAISE(SQLAllocStmt(m_ICon,&m_TmpStmt) != IDE_SUCCESS, alloc_stmt_error);
    IDE_TEST_RAISE(SQLAllocStmt(m_ICon,&m_TmpStmt2) != IDE_SUCCESS, alloc_stmt_error);
    IDE_TEST_RAISE(SQLAllocStmt(m_ICon,&m_TmpStmt3) != IDE_SUCCESS, alloc_stmt_error);

    return rc;

    IDE_EXCEPTION(alloc_env_error);
    {
        SetErrorMsg((SChar*)"SQLAllocEnv Error");
    }

    IDE_EXCEPTION(alloc_con_error);
    {
        SetErrorMsg((SChar*)"SQLAllocConnect Error");
    }

    IDE_EXCEPTION(set_con_attr_error);
    {
        SetErrorMsgWithDBC(m_ICon);
    }

    IDE_EXCEPTION(alloc_driverCon_error);
    {
        SetErrorMsgWithDBC(m_ICon);

        SQLFreeConnect(m_ICon);
        SQLFreeEnv(m_IEnv);

        m_IEnv = SQL_NULL_HENV;
        m_ICon = SQL_NULL_HDBC;
    }

    IDE_EXCEPTION(alloc_stmt_error);
    {
        SetErrorMsgWithDBC(m_ICon);
    }
    IDE_EXCEPTION(admin_connect_error);
    {
        SetErrorMsgWithDBC(m_ICon);
    }

    IDE_EXCEPTION_END;

    return SQL_ERROR;
}

IDE_RC utISPApi::StmtClose(SQLHSTMT a_stmt)
{
    if (a_stmt != NULL)
    {
        SQLFreeStmt(a_stmt, SQL_CLOSE);
    }
    return IDE_SUCCESS;
}

IDE_RC utISPApi::StmtClose(idBool aPrepare)
{
    SQLHSTMT sStmt;

    if ( aPrepare == ID_TRUE )
    {
        sStmt = m_TmpStmt3;
    }
    else
    {
        sStmt = m_IStmt;
    }
    if ( sStmt != SQL_NULL_HSTMT )
    {
        return StmtClose(sStmt);
    }
    return IDE_SUCCESS;
}

IDE_RC utISPApi::Close()
{
    IDE_TEST(StmtClose(m_IStmt)    != IDE_SUCCESS);
    IDE_TEST(StmtClose(m_TmpStmt)  != IDE_SUCCESS);
    IDE_TEST(StmtClose(m_TmpStmt2) != IDE_SUCCESS);
    IDE_TEST(StmtClose(m_TmpStmt3) != IDE_SUCCESS);
    if ( m_ICon != NULL )
    {
        IDE_TEST_RAISE(SQLDisconnect(m_ICon)  != IDE_SUCCESS, disCon_error);
        IDE_TEST_RAISE(SQLFreeConnect(m_ICon) != IDE_SUCCESS, free_con_error);
    }
    if ( m_IEnv != NULL )
    {
        IDE_TEST_RAISE(SQLFreeEnv(m_IEnv)     != IDE_SUCCESS, free_env_error);
    }

    m_IEnv          = SQL_NULL_HENV;
    m_ICon          = SQL_NULL_HDBC; 
    m_IStmt         = SQL_NULL_HSTMT;
    m_TmpStmt       = SQL_NULL_HSTMT;    
    m_TmpStmt2      = SQL_NULL_HSTMT;
    m_TmpStmt3      = SQL_NULL_HSTMT;    
    m_Query[0]      = '\0';
    m_ErrorMsg[0]   = '\0';
    m_ErrorState[0] = '\0';

    return IDE_SUCCESS;

    IDE_EXCEPTION(disCon_error);
    {
        SetErrorMsg((SChar*)"SQLDisconnect Error");
    }

    IDE_EXCEPTION(free_con_error);
    {
        SetErrorMsg((SChar*)"SQLFreeConnect Error");
    }

    IDE_EXCEPTION(free_env_error);
    {
        SetErrorMsg((SChar*)"SQLFreeEnv Error");
    }

    IDE_EXCEPTION_END;

    m_IEnv          = SQL_NULL_HENV;
    m_ICon          = SQL_NULL_HDBC; 
    m_IStmt         = SQL_NULL_HSTMT;
    m_TmpStmt       = SQL_NULL_HSTMT;    
    m_TmpStmt2      = SQL_NULL_HSTMT;
    m_TmpStmt3      = SQL_NULL_HSTMT;    
    m_Query[0]      = '\0';
    m_ErrorMsg[0]   = '\0';
    m_ErrorState[0] = '\0';

    return IDE_FAILURE;
}

IDE_RC utISPApi::Tables(SChar *a_UserName, idBool a_IsSysUser)  
{
// Declare buffers for result set data 
    SChar TableName[QP_MAX_NAME_LEN+1];
    SChar UserName[QP_MAX_NAME_LEN+1];
    SChar TableType[20];

// Declare buffers for bytes available to return 
    SInt cbTableName;
    SInt cbUserName;
    SInt cbTableType;

    SChar  user[QP_MAX_NAME_LEN+1];
    SInt   cnt;
    SInt   len;
    SInt   i;

    if (a_IsSysUser)
    {
        user[0] = '\0';   // all user ==> get all table list
    } 
    else
    {
        idlOS::strcpy(user, a_UserName);
    }

    // Get table count 
    idlOS::sprintf( m_Buf,
                    "select count(*) from all_tables where owner = \'%s\'", user );
    /*
    if (a_IsSysUser)
    {
        idlOS::sprintf( m_Buf,
                        "select count(*) from system_.sys_tables_ "
                        "where table_type in ('T','V')" );
    }
    else
    {
        idlOS::sprintf( m_Buf,
                        "select count(*) from system_.sys_tables_ "
                        "where table_type in ('T','V') " 
                        "and user_id = "
                        "( select user_id from system_.sys_users_ "
                        "where user_name = \'%s\' )", user);
    }
    */

    IDE_TEST_RAISE(SQLExecDirect(m_TmpStmt, m_Buf, SQL_NTS)
                   != IDE_SUCCESS, tmp_error);    

    SQLBindCol(m_TmpStmt, 1, SQL_C_SLONG, &cnt, 0, 0);

    IDE_TEST_RAISE(SQLFetch(m_TmpStmt) != IDE_SUCCESS, tmp_error);    
    StmtClose(m_TmpStmt);
    
    // SQLTables execute 
    // SQLTables( stmt, catalog, catalog_len, schema, schema_len,
    //            table_name, table_name_len, table_type, table_type_len);
    IDE_TEST_RAISE( SQLTables( m_IStmt, NULL, 0, user, SQL_NTS,
                               NULL, 0, (SChar*)"TABLE,VIEW", 10 )
                    != IDE_SUCCESS, i_error);    

    // Bind columns in result set to buffers 
    SQLBindCol( m_IStmt, 2, SQL_C_CHAR,
                UserName, sizeof(UserName), &cbUserName);
    SQLBindCol( m_IStmt, 3, SQL_C_CHAR,
                TableName, sizeof(TableName), &cbTableName);
    SQLBindCol( m_IStmt, 4, SQL_C_CHAR,
                TableType, sizeof(TableType), &cbTableType);

    // Get column name 
    m_Column.SetSize(cnt);
    for (i=0; i<m_Column.GetSize(); i++)
    {
        IDE_TEST_RAISE(SQLFetch(m_IStmt) != IDE_SUCCESS, i_error);    

        m_Column.SetName(i, TableName);    
        m_Column.SetUserName(i, UserName);    
        if ( cbTableType != NULL )
        {
            if ( idlOS::strcmp( TableType, "SYSTEM TABLE" ) == 0 )
            {
                m_Column.SetType(i, TYPE_SYSTEM_TABLE);
            }
            else if ( idlOS::strcmp( TableType, "TABLE" ) == 0 )
            {
                m_Column.SetType(i, TYPE_TABLE);
            }
            else if ( idlOS::strcmp( TableType, "VIEW" ) == 0 )
            {
                m_Column.SetType(i, TYPE_VIEW);
            }
            else if ( idlOS::strcmp( TableType, "VIEW" ) == 0 )
            {
                m_Column.SetType(i, TYPE_UNKNOWN);
            }
        }
        else
        {
            m_Column.SetType(i, TYPE_UNKNOWN);
        }
    }

    m_Column.SetColumnCount(i);

    StmtClose(m_IStmt);

    return IDE_SUCCESS;

    IDE_EXCEPTION(i_error);
    {
        SetErrorMsgWithStmt(m_IStmt);
        StmtClose(m_TmpStmt);
        // m_IStmt will be closed by caller
    }

    IDE_EXCEPTION(tmp_error);
    {
        SetErrorMsgWithStmt(m_TmpStmt);
        StmtClose(m_IStmt);
        // m_TmpStmt will be closed by caller
    }

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC utISPApi::FixedTables(SChar *a_UserName, idBool a_IsSysUser)  
{
    /*
// Declare buffers for result set data 
    SChar TableName[QP_MAX_NAME_LEN+1];
    SChar UserName[QP_MAX_NAME_LEN+1];
    SChar TableType[20];

// Declare buffers for bytes available to return 
    SInt cbTableName;
    SInt cbUserName;
    SInt cbTableType;

    SChar  user[QP_MAX_NAME_LEN+1];
    SInt   cnt;
    SInt   len;
    SInt   i;

    if (a_IsSysUser)
    {
        user[0] = '\0';   // all user ==> get all table list
    } 
    else
    {
        idlOS::strcpy(user, a_UserName);
    }

    // Get table count 
    // Get table count 
    if (a_IsSysUser)
    {
        idlOS::sprintf( m_Buf,
                        "select count(*) from x$table" );
    }
    else
    {
        idlOS::sprintf( m_Buf,
                        "select count(*) from x$table" );
    }

    IDE_TEST_RAISE(SQLExecDirect(m_TmpStmt, m_Buf, SQL_NTS)
                   != IDE_SUCCESS, tmp_error);    

    SQLBindCol(m_TmpStmt, 1, SQL_C_SLONG, &cnt, sizeof(cnt), &len);

    IDE_TEST_RAISE(SQLFetch(m_TmpStmt) != IDE_SUCCESS, tmp_error);    
    StmtClose(m_TmpStmt);
    
    // SQLTables execute 
    // SQLTables( stmt, catalog, catalog_len, schema, schema_len,
    //            table_name, table_name_len, table_type, table_type_len);
    IDE_TEST_RAISE( SQLFixedTables( m_IStmt, NULL, 0, user, SQL_NTS,
                               NULL, 0, (SChar*)"TABLE,VIEW", 10 )
                    != IDE_SUCCESS, i_error);    

    // Bind columns in result set to buffers 
    SQLBindCol( m_IStmt, 2, SQL_C_CHAR,
                UserName, sizeof(UserName), &cbUserName);
    SQLBindCol( m_IStmt, 3, SQL_C_CHAR,
                TableName, sizeof(TableName), &cbTableName);
    SQLBindCol( m_IStmt, 4, SQL_C_CHAR,
                TableType, sizeof(TableType), &cbTableType);

    // Get column name 
    m_Column.SetSize(cnt);
    for (i=0; i<m_Column.GetSize(); i++)
    {
        IDE_TEST_RAISE(SQLFetch(m_IStmt) != IDE_SUCCESS, i_error);    

        m_Column.SetName(i, TableName);    
        m_Column.SetUserName(i, UserName);    
        m_Column.SetType(i, TYPE_SYSTEM_TABLE);
    }

    m_Column.SetColumnCount(i);

    StmtClose(m_IStmt);

    return IDE_SUCCESS;

    IDE_EXCEPTION(i_error);
    {
        SetErrorMsgWithStmt(m_IStmt);
        StmtClose(m_TmpStmt);
        // m_IStmt will be closed by caller
    }

    IDE_EXCEPTION(tmp_error);
    {
        SetErrorMsgWithStmt(m_TmpStmt);
        StmtClose(m_IStmt);
        // m_TmpStmt will be closed by caller
    }

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
    */
    return IDE_SUCCESS;
}


IDE_RC utISPApi::Sequence(SChar *a_UserName, idBool a_IsSysUser)  
{
    SChar  user[QP_MAX_NAME_LEN+1];
    SShort Col;
    SShort Type;
    SShort Scale;
    SShort Null;
    SInt   Precision;
    SInt   Size;
    SShort cnt;
    SInt   i;
    SInt   k;
    SInt   pos = 0;

    if (a_IsSysUser)
    {
        user[0] = '\0';   // all user ==> get all table list
    } 
    else
    {
        idlOS::strcpy(user, a_UserName);
    }

    pos = idlOS::sprintf( m_Buf,
                    "select ");
    if ( a_IsSysUser == ID_TRUE )
    {
        pos += idlOS::sprintf( m_Buf + pos,
                    "a.user_name USER_NAME,");
    }
    pos += idlOS::sprintf( m_Buf + pos,
                        "b.table_name SEQUENCE_NAME,"
                        "c.current_seq CURRENT_VALUE,"
                        "c.increment_seq INCREMENT_BY,"
                        "c.min_seq MIN_VALUE,"
                        "c.max_seq MAX_VALUE,"
                        "decode(c.flag,0,'NO',16,'YES','') CYCLE_,"
                        "c.sync_interval CACHE_SIZE "
                    "from system_.sys_users_ a,system_.sys_tables_ b,"
                          "x$seq c "
                    "where a.user_id=b.user_id and "
                    "b.table_oid=c.seq_oid and "
                    "a.user_name<>'SYSTEM_' and "
                    "b.table_type='S'" );
    if ( a_IsSysUser != ID_TRUE )
    {
        idlOS::sprintf( m_Buf + pos,
                        "and a.user_name='%s'", user );
    }
    idlOS::strcat( m_Buf, " order by 1,2" );

    IDE_TEST_RAISE( SQLExecDirect(m_IStmt, m_Buf, SQL_NTS)
                    != IDE_SUCCESS, i_error);    

    // Bind columns in result set to buffers 
    SQLNumResultCols(m_IStmt, &cnt);
    m_Column.SetSize(cnt);
    k = 0;
    for (i=0; i<cnt; i++)
    {
        SQLDescribeCol(m_IStmt, i+1, m_Column.m_Name[k],
                       QP_MAX_NAME_LEN, &Col, &Type, &Precision, &Scale, &Null);
    
        if ( strcmp(m_Column.m_Name[k], "CYCLE_") == 0 )
        {
            m_Column.SetName(k, (SChar*)"CYCLE");
        }
        if ( Type == SQL_BIGINT )
        {
            m_Column.SetType(i, SQL_VARCHAR);
            m_Column.SetScale(i, 0);
            m_Column.SetPrecision(i, 21);
            m_Column.SetValueSize(i, 22);
        }
        else
        {
            m_Column.SetType(k, Type);
            m_Column.SetScale(k, Scale);
            m_Column.SetPrecision(k, Precision);
            Size = Precision+1;
            m_Column.SetValueSize(k, Size);
        }
        m_Column.SetNull(k, Null);
        SQLBindCol(m_IStmt, i+1, SQL_C_CHAR,
                   m_Column.m_CValue[k], Size, &m_Column.m_Len[k]);
        k++;
    }
    /*
    for (i=cnt; i<cnt+6; i++)
    {
        m_Column.SetType(i, SQL_VARCHAR);
        m_Column.SetScale(i, 0);
        m_Column.SetNull(i, SQL_NULLABLE);
        if ( i == cnt + 2 || i == cnt + 3 )
        {
            m_Column.SetPrecision(i, 21);
            m_Column.SetValueSize(i, 22);
        }
        else
        {
            m_Column.SetPrecision(i, 14);
            m_Column.SetValueSize(i, 15);
        }
    }
    */

    return IDE_SUCCESS;

    IDE_EXCEPTION(i_error);
    {
        SetErrorMsgWithStmt(m_IStmt);
        StmtClose();
        // m_IStmt will be closed by caller
    }
    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

SQLRETURN utISPApi::FetchSequence()
{
    SQLRETURN rc;
    SInt      sCnt = 0;
    SChar    *sUser = NULL;
    SChar    *sSeq  = NULL;
    SChar    *tmp = NULL;
    SChar    *tmp2 = NULL;
    SInt      errNo;
    SShort    msgLength;
    SChar     errMsg[IDCCLI_ERROR_MSG_LEN];

    rc = SQLFetch(m_IStmt);
    
    if ( rc == SQL_ERROR || rc == SQL_SUCCESS_WITH_INFO )
    {
        SetErrorMsgWithStmt(m_IStmt);
        return rc;
    }
    if ( m_Column.GetSize() == 8 ) // SYS
    {
        sCnt = 2;
        sUser = m_Column.m_CValue[0];
        sSeq = m_Column.m_CValue[1];
        idlOS::sprintf(m_Buf, "check sequence %s.%s", sUser, sSeq);
    }
    else
    {
        sCnt = 1;
        sSeq = m_Column.m_CValue[0];
        idlOS::sprintf(m_Buf, "check sequence %s", sSeq);
    }

    IDE_TEST( SQLExecDirect(m_TmpStmt, m_Buf, SQL_NTS) != SQL_ERROR );

    SQLError(m_IEnv, m_ICon, m_TmpStmt, m_ErrorState, &errNo, errMsg, 
             IDCCLI_ERROR_MSG_LEN, &msgLength);

    tmp = idlOS::strtok(errMsg, "\n");
    while ( tmp != NULL )
    {
        if ( idlOS::strncmp(tmp, "CURRENT_VALUE", 13) == 0 )
        {
            tmp2 = idlOS::strchr(tmp, '\t');
            if ( tmp2 != NULL )
            {
                idlOS::strcpy( m_Column.m_CValue[sCnt], tmp2+1 );
                m_Column.m_Len[sCnt] = idlOS::strlen( m_Column.m_CValue[sCnt] );
            }
            else
            {
                idlOS::strcpy( m_Column.m_CValue[sCnt], "" );
                m_Column.m_Len[sCnt] = 0;
            }
        }
        else if ( idlOS::strncmp(tmp, "INCREMENT_VALUE", 15) == 0 )
        {
            tmp2 = idlOS::strchr(tmp, '\t');
            if ( tmp2 != NULL )
            {
                idlOS::strcpy( m_Column.m_CValue[sCnt+1], tmp2+1 );
                m_Column.m_Len[sCnt+1] = 
                         idlOS::strlen( m_Column.m_CValue[sCnt+1] );
            }
            else
            {
                idlOS::strcpy( m_Column.m_CValue[sCnt+1], "" );
                m_Column.m_Len[sCnt+1] = 0;
            }
        }
        else if ( idlOS::strncmp(tmp, "MIN_VALUE", 9) == 0 )
        {
            tmp2 = idlOS::strchr(tmp, '\t');
            if ( tmp2 != NULL )
            {
                idlOS::strcpy( m_Column.m_CValue[sCnt+2], tmp2+1 );
                m_Column.m_Len[sCnt+2] =
                         idlOS::strlen( m_Column.m_CValue[sCnt+2] );
            }
            else
            {
                idlOS::strcpy( m_Column.m_CValue[sCnt+2], "" );
                m_Column.m_Len[sCnt+2] = 0;
            }
        }
        else if ( idlOS::strncmp(tmp, "MAX_VALUE", 9) == 0 )
        {
            tmp2 = idlOS::strchr(tmp, '\t');
            if ( tmp2 != NULL )
            {
                idlOS::strcpy( m_Column.m_CValue[sCnt+3], tmp2+1 );
                m_Column.m_Len[sCnt+3] =
                         idlOS::strlen( m_Column.m_CValue[sCnt+3] );
            }
            else
            {
                idlOS::strcpy( m_Column.m_CValue[sCnt+3], "" );
                m_Column.m_Len[sCnt+3] = 0;
            }
        }
        else if ( idlOS::strncmp(tmp, "CACHE_VALUE", 11) == 0 )
        {
            tmp2 = idlOS::strchr(tmp, '\t');
            if ( tmp2 != NULL )
            {
                idlOS::strcpy( m_Column.m_CValue[sCnt+5], tmp2+1 );
                m_Column.m_Len[sCnt+5] =
                         idlOS::strlen( m_Column.m_CValue[sCnt+5] );
            }
            else
            {
                idlOS::strcpy( m_Column.m_CValue[sCnt+5], "" );
                m_Column.m_Len[sCnt+5] = 0;
            }
        }
        else if ( idlOS::strncmp(tmp, "CYCLE", 5) == 0 )
        {
            tmp2 = idlOS::strchr(tmp, '\t');
            if ( tmp2 != NULL )
            {
                idlOS::strcpy( m_Column.m_CValue[sCnt+4], tmp2+1 );
                m_Column.m_Len[sCnt+4] =
                         idlOS::strlen( m_Column.m_CValue[sCnt+4] );
            }
            else
            {
                idlOS::strcpy( m_Column.m_CValue[sCnt+4], "" );
                m_Column.m_Len[sCnt+4] = 0;
            }
        }
        tmp = idlOS::strtok(NULL, "\n");
    }

    return rc;

    IDE_EXCEPTION_END;

    return SQL_ERROR;
}

IDE_RC utISPApi::getTBSName(SChar *a_UserName,
                            SChar *a_TableName,
                            SChar *aTBSName)
{
    SInt      len;
    SQLRETURN rc;

    // BUGBUG-10990
    // Performance View 완료 후 Table Space를 얻어야 함.
    
    // get tablespace
    idlOS::sprintf(m_Buf, 
        "select a.name "
          "from x$tablespaces a,"
               "system_.sys_tables_ b,"
               "system_.sys_users_ c "
          "where a.id=b.tbs_id and "
               "b.user_id=c.user_id and "
               "c.user_name='%s' and "
               "b.table_name='%s'",
          a_UserName, a_TableName);
    
    IDE_TEST_RAISE(SQLExecDirect(m_TmpStmt, m_Buf, SQL_NTS)
                   != IDE_SUCCESS, tmp_error);    

    SQLBindCol(m_TmpStmt, 1, SQL_C_CHAR, aTBSName, QP_MAX_NAME_LEN + 1, &len);

    rc = SQLFetch(m_TmpStmt);

    IDE_TEST_RAISE(rc == SQL_NO_DATA, no_table);
    IDE_TEST_RAISE(rc != IDE_SUCCESS, tmp_error);    

    StmtClose(m_TmpStmt);

    return IDE_SUCCESS;

    IDE_EXCEPTION(tmp_error);
    {
        SetErrorMsgWithStmt(m_TmpStmt);
    }
    IDE_EXCEPTION(no_table);
    {
        idlOS::sprintf(m_Buf, "%s does not exist\n", a_TableName);
        SetErrorMsg(m_Buf);
        StmtClose(m_TmpStmt);
    }
    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC utISPApi::Columns(SChar *a_UserName, SChar *a_TableName)
{
// Declare buffers for result set data 
    SChar ColumnName[QP_MAX_NAME_LEN+1];
    SInt  DataType;
    SInt  ColumnSize;
    SInt  DecimalDigits;
    SInt  Nullable;
    SChar IsVaring[QP_MAX_NAME_LEN+1];
    
// Declare buffers for bytes available to return 
    SInt cbColumnName;
    SInt cbDataType;
    SInt cbColumnSize;
    SInt cbDecimalDigits;
    SInt cbNullable;
    SInt cbIsVaring;

    SInt  cnt = -1;
    SInt  len;
    SInt  i;

    // Get column count 
    idlOS::sprintf(m_Buf, 
        "select count(*) \
           from system_.sys_columns_ SYSC, \
                system_.sys_tables_  SYST, \
                system_.sys_users_   SYSU  \
          where SYSC.table_id = SYST.table_id \
            and SYST.user_id = SYSU.user_id \
            and SYST.table_name = \'%s\' \
            and SYSU.user_name = \'%s\'", 
                    a_TableName, a_UserName);

    IDE_TEST_RAISE(SQLExecDirect(m_TmpStmt, m_Buf, SQL_NTS)
                   != IDE_SUCCESS, tmp_error);    

    SQLBindCol(m_TmpStmt, 1, SQL_C_SLONG, &cnt, sizeof(cnt), &len);

    IDE_TEST_RAISE(SQLFetch(m_TmpStmt) != IDE_SUCCESS, tmp_error);    
    StmtClose(m_TmpStmt);
    IDE_TEST_RAISE(cnt == 0, no_table);    
    
// SQLColumns execute 
// SQLColumns(stmt, catalog, catalog_len, schema, schema_len, table_name, table_name_len, column_name, column_name_len);
    IDE_TEST_RAISE(SQLColumns(m_IStmt, NULL, 0,    a_UserName, SQL_NTS, a_TableName, SQL_NTS, NULL, 0) != IDE_SUCCESS, i_error);    

// Bind columns in result set to buffers 
    SQLBindCol(m_IStmt, 4,  SQL_C_CHAR,   ColumnName,    QP_MAX_NAME_LEN+1, &cbColumnName);
    SQLBindCol(m_IStmt, 5,  SQL_C_SLONG, &DataType,      0,               &cbDataType);
    SQLBindCol(m_IStmt, 7,  SQL_C_SLONG, &ColumnSize,    0,               &cbColumnSize);
    SQLBindCol(m_IStmt, 9,  SQL_C_SLONG, &DecimalDigits, 0,               &cbDecimalDigits);
    SQLBindCol(m_IStmt, 11, SQL_C_SLONG, &Nullable,      0,               &cbNullable);
    SQLBindCol(m_IStmt, 19, SQL_C_CHAR,   IsVaring,      QP_MAX_NAME_LEN, &cbIsVaring);

    // Get column name and type ... 
    m_Column.SetSize(cnt);
    for (i=0; i<m_Column.GetSize(); i++)
    {
        IDE_TEST_RAISE(SQLFetch(m_IStmt) != IDE_SUCCESS, i_error);    

        m_Column.SetName(i, ColumnName);
        m_Column.SetType(i, DataType);
        m_Column.SetPrecision(i, ColumnSize);
        m_Column.SetScale(i, DecimalDigits);
        m_Column.SetNull(i, Nullable);
        m_Column.SetIsVaring(i, IsVaring);
    }

    m_Column.SetColumnCount(i);
    IDE_TEST_RAISE(i == 0, no_table);    

    StmtClose(m_IStmt);

    return IDE_SUCCESS;

    IDE_EXCEPTION(i_error);
    {
        SetErrorMsgWithStmt(m_IStmt);
        StmtClose(m_TmpStmt);
        // m_IStmt will be close by caller
    }

    IDE_EXCEPTION(tmp_error);
    {
        SetErrorMsgWithStmt(m_TmpStmt);
        StmtClose(m_IStmt);
        // m_TmpStmt will be close by caller
    }

    IDE_EXCEPTION(no_table);
    {
        idlOS::sprintf(m_Buf, "%s does not exist\n", a_TableName);
        SetErrorMsg(m_Buf);
        StmtClose(m_IStmt);
    }

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC utISPApi::Columns4FTnPV(SChar *a_UserName, SChar *a_TableName)
{
    /*
// Declare buffers for result set data 
    SChar ColumnName[QP_MAX_NAME_LEN+1];
    SInt  DataType;
    SInt  ColumnSize;
    
// Declare buffers for bytes available to return 
    SInt cbColumnName;
    SInt cbDataType;
    SInt cbColumnSize;

    SInt  cnt = -1;
    SInt  len;
    SInt  i;

    // Get column count 
    idlOS::sprintf(m_Buf, 
                   "select count(*) "
                   "from x$column C, "
                   "x$table T "
                   "where C.tablename = T.name "
                   "and T.name = \'%s\'", 
                   a_TableName );

    IDE_TEST_RAISE(SQLExecDirect(m_TmpStmt, m_Buf, SQL_NTS)
                   != IDE_SUCCESS, tmp_error);    

    SQLBindCol(m_TmpStmt, 1, SQL_C_SLONG, &cnt, sizeof(cnt), &len);

    IDE_TEST_RAISE(SQLFetch(m_TmpStmt) != IDE_SUCCESS, tmp_error);    
    StmtClose(m_TmpStmt);
    IDE_TEST_RAISE(cnt == 0, no_table);    
    
// SQLColumns execute 
// SQLColumns(stmt, catalog, catalog_len, schema, schema_len, table_name, table_name_len, column_name, column_name_len);
    IDE_TEST_RAISE(SQLColumns4FTnPV(m_IStmt, NULL, 0,    a_UserName, SQL_NTS, a_TableName, SQL_NTS, NULL, 0) != IDE_SUCCESS, i_error);    

// Bind columns in result set to buffers 
    SQLBindCol(m_IStmt, 1,  SQL_C_CHAR,   ColumnName,    QP_MAX_NAME_LEN+1, &cbColumnName);
    SQLBindCol(m_IStmt, 2,  SQL_C_SLONG, &DataType,      0,               &cbDataType);
    SQLBindCol(m_IStmt, 3,  SQL_C_SLONG, &ColumnSize,    0,               &cbColumnSize);

    // Get column name and type ... 
    m_Column.SetSize(cnt);
    for (i=0; i<m_Column.GetSize(); i++)
    {
        IDE_TEST_RAISE(SQLFetch(m_IStmt) != IDE_SUCCESS, i_error);    

        m_Column.SetName(i, ColumnName);
        m_Column.SetType(i, DataType);
        m_Column.SetPrecision(i, ColumnSize);
    }

    m_Column.SetColumnCount(i);
    IDE_TEST_RAISE(i == 0, no_table);    

    StmtClose(m_IStmt);

    return IDE_SUCCESS;

    IDE_EXCEPTION(i_error);
    {
        SetErrorMsgWithStmt(m_IStmt);
        StmtClose(m_TmpStmt);
        // m_IStmt will be close by caller
    }

    IDE_EXCEPTION(tmp_error);
    {
        SetErrorMsgWithStmt(m_TmpStmt);
        StmtClose(m_IStmt);
        // m_TmpStmt will be close by caller
    }

    IDE_EXCEPTION(no_table);
    {
        idlOS::sprintf(m_Buf, "%s does not exist\n", a_TableName);
        SetErrorMsg(m_Buf);
        StmtClose(m_IStmt);
    }

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
    */
    return IDE_SUCCESS;
}

IDE_RC utISPApi::Statistics(SChar *a_UserName, SChar *a_TableName, SInt *a_IndexCount, IndexInfo **a_IndexInfo)
{
// Declare buffers for result set data 
    SChar IndexName[QP_MAX_NAME_LEN+1];
    SChar ColumnName[QP_MAX_NAME_LEN+1];
    SChar SortSeq[QP_MAX_NAME_LEN+1];
    SInt  NonUnique;
    SInt  OrdinalPos;
    SInt  IndexType;

// Declare buffers for bytes available to return 
    SInt cbNonUnique;
    SInt cbIndexName;
    SInt cbOrdinalPos;
    SInt cbColumnName;
    SInt cbSortSeq;
    SInt cbIndexType;

    static IndexInfo t_index_info[SMC_INDEX_MAX_COUNT];
    SInt   nIndex = 0;
    SInt   nResult;
    SChar  buf[MSG_LEN];
    SChar  tmp[MSG_LEN];

// SQLStatistics execute 
// SQLStatistics(stmt, catalog, catalog_len, schema, schema_len, table_name, table_name_len, unique, reserved);
    IDE_TEST_RAISE(SQLStatistics(m_IStmt, NULL, 0,    a_UserName, SQL_NTS, a_TableName, SQL_NTS, SQL_INDEX_ALL, 0) != IDE_SUCCESS, 
                    i_error);    

// Bind columns in result set to buffers 
    SQLBindCol(m_IStmt, 4,  SQL_C_SLONG, &NonUnique,  0,               &cbNonUnique);
    SQLBindCol(m_IStmt, 6,  SQL_C_CHAR,   IndexName,  QP_MAX_NAME_LEN, &cbIndexName);
    SQLBindCol(m_IStmt, 8,  SQL_C_SLONG, &OrdinalPos, 0,               &cbOrdinalPos);
    SQLBindCol(m_IStmt, 9,  SQL_C_CHAR,   ColumnName, QP_MAX_NAME_LEN, &cbColumnName);
    SQLBindCol(m_IStmt, 10, SQL_C_CHAR,   SortSeq,    QP_MAX_NAME_LEN, &cbSortSeq);
    SQLBindCol(m_IStmt, 14, SQL_C_SLONG, &IndexType,  0,               &cbIndexType);

// Get index infomation 
    for (nIndex=0; nIndex<SMC_INDEX_MAX_COUNT; nIndex++)
    {
        nResult = SQLFetch(m_IStmt);

        if ( nResult == SQL_NO_DATA ) break;

        IDE_TEST_RAISE(nResult != IDE_SUCCESS, i_error);    

        idlOS::strcpy(t_index_info[nIndex].IndexName, IndexName);
        idlOS::strcpy(t_index_info[nIndex].ColumnName, ColumnName);
        t_index_info[nIndex].SortAsc    = (idlOS::strcmp(SortSeq, "A") == 0) ? ID_TRUE : ID_FALSE;
        t_index_info[nIndex].NonUnique  = (NonUnique == ID_TRUE) ? ID_TRUE : ID_FALSE;
        t_index_info[nIndex].OrdinalPos = OrdinalPos;

        switch(IndexType)
        {
            case 1 : idlOS::strcpy(t_index_info[nIndex].IndexType, "BTREE"); break;
            case 2 : idlOS::strcpy(t_index_info[nIndex].IndexType, "RTREE"); break;
            case 3 : idlOS::strcpy(t_index_info[nIndex].IndexType, "HASH"); break;
        }
    }

    *a_IndexCount = nIndex;
    IDE_TEST_RAISE(nIndex == 0, no_index);    

    (*a_IndexInfo) = t_index_info;
    
    StmtClose(m_IStmt);

    return IDE_SUCCESS;

    IDE_EXCEPTION(i_error);
    {
        SetErrorMsgWithStmt(m_IStmt);
    }

    IDE_EXCEPTION(no_index);
    {
        idlOS::sprintf(buf, "%s have no index\n", a_TableName);
        idlOS::sprintf(tmp, "%s have no primary key", a_TableName);
        idlOS::strcat(buf, tmp);
        SetMsg(buf);
        StmtClose(m_IStmt);
    }

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC utISPApi::PrimaryKeys(SChar *a_UserName, SChar *a_TableName, SChar a_pk[QC_MAX_KEY_COLUMN_COUNT][QP_MAX_NAME_LEN+1], SInt *a_pk_col_cnt)
{
// Declare buffers for result set data 
    SChar ColumnName[QP_MAX_NAME_LEN+1];
    SInt  OrdinalPos;       
                                
// Declare buffers for bytes available to return 
    SInt cbColumnName;
    SInt cbOrdinalPos;       
    
    SInt  i;
    SInt  nResult;
    SChar buf[MSG_LEN];

// SQLPrimaryKeys execute 
// SQLPrimaryKeys(stmt, catalog, catalog_len, schema, schema_len, table_name, table_name_len);
    IDE_TEST_RAISE(SQLPrimaryKeys(m_IStmt, NULL, 0,    a_UserName, SQL_NTS, a_TableName, SQL_NTS) != IDE_SUCCESS, 
                    i_error);    

// Bind columns in result set to buffers 
    SQLBindCol(m_IStmt, 4, SQL_C_CHAR,   ColumnName, QP_MAX_NAME_LEN, &cbColumnName);
    SQLBindCol(m_IStmt, 5, SQL_C_SLONG, &OrdinalPos, 0,               &cbOrdinalPos);

// Get primarykeys infomation 
    for (i=0; i<QC_MAX_KEY_COLUMN_COUNT; i++)
    {
        nResult = SQLFetch(m_IStmt);

        if ( nResult == SQL_NO_DATA ) break;

        IDE_TEST_RAISE(nResult != IDE_SUCCESS, i_error);    

        idlOS::strcpy(a_pk[OrdinalPos-1], ColumnName);
    }
    
    *a_pk_col_cnt = i;

    IDE_TEST_RAISE(i == 0, no_pk);    

    StmtClose(m_IStmt);

    return IDE_SUCCESS;

    IDE_EXCEPTION(i_error);
    {
        SetErrorMsgWithStmt(m_IStmt);
    }

    IDE_EXCEPTION(no_pk);
    {
        idlOS::sprintf(buf, "\n%s have no primary key", a_TableName);
        SetMsg(buf);
        StmtClose(m_IStmt);
    }

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC utISPApi::ForeignKeys( SChar              *a_UserName,
                              SChar              *a_TableName,
                              iSQLForeignKeyKind  a_Type,
                              SChar              *aPKSchema,
                              SChar              *aPKTableName,
                              SChar              *aPKColumnName,
                              SChar              *aPKName,
                              SChar              *aFKSchema,
                              SChar              *aFKTableName,
                              SChar              *aFKColumnName,
                              SChar              *aFKName,
                              SShort             *aKeySeq )
{
    if ( a_Type == FOREIGNKEY_PK )
    {
        IDE_TEST_RAISE( SQLForeignKeys(m_IStmt,
                                   NULL, 0,
                                   a_UserName, SQL_NTS,
                                   a_TableName, SQL_NTS,
                                   NULL, 0,
                                   NULL, 0,
                                   NULL, 0) != SQL_SUCCESS, 
                        i_error);    
    }
    else
    {
        IDE_TEST_RAISE( SQLForeignKeys(m_IStmt,
                                   NULL, 0,
                                   NULL, 0,
                                   NULL, 0,
                                   NULL, 0,
                                   a_UserName, SQL_NTS,
                                   a_TableName, SQL_NTS) != SQL_SUCCESS, 
                        i_error);    
    }

    SQLBindCol(m_IStmt, 2, SQL_C_CHAR, aPKSchema, QP_MAX_NAME_LEN+1, NULL);
    SQLBindCol(m_IStmt, 3, SQL_C_CHAR, aPKTableName, QP_MAX_NAME_LEN+1, NULL);
    SQLBindCol(m_IStmt, 4, SQL_C_CHAR, aPKColumnName, QP_MAX_NAME_LEN+1, NULL);
    SQLBindCol(m_IStmt, 6, SQL_C_CHAR, aFKSchema, QP_MAX_NAME_LEN+1, NULL);
    SQLBindCol(m_IStmt, 7, SQL_C_CHAR, aFKTableName, QP_MAX_NAME_LEN+1, NULL);
    SQLBindCol(m_IStmt, 8, SQL_C_CHAR, aFKColumnName, QP_MAX_NAME_LEN+1, NULL);
    SQLBindCol(m_IStmt, 9, SQL_C_SSHORT, aKeySeq, 0, NULL);
    SQLBindCol(m_IStmt, 12, SQL_C_CHAR, aFKName, QP_MAX_NAME_LEN+1, NULL);
    SQLBindCol(m_IStmt, 13, SQL_C_CHAR, aPKName, QP_MAX_NAME_LEN+1, NULL);

    return IDE_SUCCESS;

    IDE_EXCEPTION(i_error);
    {
        SetErrorMsgWithStmt(m_IStmt);
        StmtClose(m_IStmt);
    }
    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

SQLRETURN utISPApi::FetchNext()
{
    SQLRETURN rc;

    rc = SQLFetch(m_IStmt);
    
    if ( rc == SQL_ERROR || rc == SQL_SUCCESS_WITH_INFO )
    {
        SetErrorMsgWithStmt(m_IStmt);
    }

    return rc;
}

IDE_RC utISPApi::GetRowCount(SInt *a_rowcnt, idBool aPrepare)
{
    SInt cnt = 0;
    SQLHSTMT sStmt;

    if ( aPrepare == ID_TRUE )
    {
        sStmt = m_TmpStmt3;
    }
    else
    {
        sStmt = m_IStmt;
    }

    IDE_TEST_RAISE(SQLRowCount(sStmt, &cnt) != IDE_SUCCESS, i_error);    

    *a_rowcnt = cnt;

    return IDE_SUCCESS;

    IDE_EXCEPTION(i_error);
    {
        SetErrorMsgWithStmt(m_IStmt);
    }

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC utISPApi::ExplainPlanExecute(SInt a_type)
{
    // a_type : 0=off, 1=on, 2=only

    if ( a_type == 0 )
    {
        strcpy(m_Buf, "alter session set explain plan = off");
    }
    else if ( a_type == 1 )
    {
        strcpy(m_Buf, "alter session set explain plan = on");
    }
    else if ( a_type == 2 )
    {
        strcpy(m_Buf, "alter session set explain plan = only");
    }

    IDE_TEST_RAISE(SQLExecDirect(m_IStmt, m_Buf, SQL_NTS) != IDE_SUCCESS, i_error);    
    
    return IDE_SUCCESS;

    IDE_EXCEPTION(i_error);
    {
        SetErrorMsgWithStmt(m_IStmt);
    }

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC utISPApi::DirectExecute()
{
    SQLRETURN rc;
#ifdef _ISPAPI_DEBUG
    idlOS::fprintf(stderr, "%s:%d:ExecuteDirect ===> %s\n", __FILE__, __LINE__, m_Query);
#endif

    rc = SQLExecDirect(m_IStmt, m_Query, SQL_NTS);
    IDE_TEST_RAISE(rc != SQL_SUCCESS && rc != SQL_NO_DATA, i_error);
    
    return IDE_SUCCESS;

    IDE_EXCEPTION(i_error);
    {
        SetErrorMsgWithStmt(m_IStmt);
    }

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC utISPApi::SelectExecute(idBool aPrepare)
{
    SShort ulCols;      
    SShort Col;
    SShort Type;
    SShort Scale;
    SShort Null;
    SInt   Precision;
    SInt   Size;
    SInt   i;
    SQLHSTMT sStmt;

#ifdef _ISPAPI_DEBUG
    idlOS::fprintf(stderr, "%s:%d:SelectExecute ===> %s\n", __FILE__, __LINE__, m_Query);
#endif

    if ( aPrepare == ID_TRUE )
    {
        sStmt = m_TmpStmt3;
        IDE_TEST_RAISE(SQLExecute(sStmt) != IDE_SUCCESS, i_error);    
    }
    else
    {
        sStmt = m_IStmt;
        IDE_TEST_RAISE(SQLExecDirect(sStmt,
                    m_Query, SQL_NTS) != IDE_SUCCESS, i_error);    
    }
    IDE_TEST_RAISE(SQLNumResultCols(sStmt, &ulCols) != IDE_SUCCESS, i_error);    
    m_Column.SetSize(ulCols);
    for (i=0; i<m_Column.GetSize(); i++)
    {
        SQLDescribeCol(sStmt, i+1, m_Column.m_Name[i], QP_MAX_NAME_LEN, &Col, &Type, &Precision, &Scale, &Null);
    
        m_Column.SetType(i, Type);
        m_Column.SetScale(i, Scale);
        m_Column.SetNull(i, Null);
        m_Column.SetPrecision(i, Precision);

        switch (Type)
        {
        case SQL_REAL :
            SQLBindCol(sStmt, i+1, SQL_C_FLOAT, &(m_Column.m_Value[i].FValue), sizeof(SFloat), &m_Column.m_Len[i]);
            break;
        case SQL_DOUBLE :
            SQLBindCol(sStmt, i+1, SQL_C_DOUBLE, &(m_Column.m_Value[i].DValue), sizeof(SDouble), &m_Column.m_Len[i]);
            break;
        case SQL_CHAR    : 
        case SQL_VARCHAR :
            Size = Precision+1;
            m_Column.SetValueSize(i, Size);
            SQLBindCol(sStmt, i+1, SQL_C_CHAR, m_Column.m_CValue[i], Size, &m_Column.m_Len[i]);
            break;
        case SQL_NULL     :
        case SQL_SMALLINT :
            Size = SMALLINT_SIZE+1;
            m_Column.SetValueSize(i, Size);
            SQLBindCol(sStmt, i+1, SQL_C_CHAR, m_Column.m_CValue[i], Size, &m_Column.m_Len[i]);
            break;
        case SQL_INTEGER :
            Size = INTEGER_SIZE+1;
            m_Column.SetValueSize(i, Size);
            SQLBindCol(sStmt, i+1, SQL_C_CHAR, m_Column.m_CValue[i], Size, &m_Column.m_Len[i]);
            break;
        case SQL_BIGINT   :
        case SQL_INTERVAL :
            Size = BIGINT_SIZE+1;
            m_Column.SetValueSize(i, Size);
            SQLBindCol(sStmt, i+1, SQL_C_CHAR, m_Column.m_CValue[i], Size, &m_Column.m_Len[i]);
            break;
        case SQL_FLOAT   :
        case SQL_DECIMAL :
        case SQL_NUMERIC :
            Size = NUMBER_SIZE+1;
            m_Column.SetValueSize(i, Size);
            SQLBindCol(sStmt, i+1, SQL_C_CHAR, m_Column.m_CValue[i], Size, &m_Column.m_Len[i]);
            break;
        case SQL_DATE      :
        case SQL_TYPE_DATE :
            Size = DATE_SIZE+1;
            m_Column.SetValueSize(i, Size);
            SQLBindCol(sStmt, i+1, SQL_C_CHAR, m_Column.m_CValue[i], Size, &m_Column.m_Len[i]);
            break;
        case SQL_BYTES  :
        case SQL_NIBBLE :
            Size = Precision*2+1;
            m_Column.SetValueSize(i, Precision*2+1);
            SQLBindCol(sStmt, i+1, SQL_C_CHAR, m_Column.m_CValue[i], Size, &m_Column.m_Len[i]);
            break;
        case SQL_BINARY : // BUGBUG : IDE_RAISE(binary_type);
            IDE_RAISE(binary_datatype);
        case SQL_GEOMETRY : // BUGBUG : IDE_RAISE(binary_type);
            IDE_RAISE(geometry_datatype);
        default :
            IDE_RAISE(wrong_datatype);
        }
    }

    return IDE_SUCCESS;

    IDE_EXCEPTION(i_error);
    {
        SetErrorMsgWithStmt(sStmt);
    }

    IDE_EXCEPTION(wrong_datatype);
    {
        SetErrorMsg((SChar*)"Unknown datatype");
        StmtClose(sStmt);
    }

    IDE_EXCEPTION(binary_datatype);
    {
        SetErrorMsg((SChar*)"BLOB type can't display");
        StmtClose(sStmt);
    }

    IDE_EXCEPTION(geometry_datatype);
    {
        SetErrorMsg((SChar*)"GEOMETRY type can't display");
        StmtClose(sStmt);
    }

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

SQLRETURN utISPApi::Fetch(idBool aPrepare)
{
    SQLRETURN nResult;
    SQLHSTMT  sStmt;
    if ( aPrepare == ID_TRUE )
    {
        sStmt = m_TmpStmt3;
    }
    else
    {
        sStmt = m_IStmt;
    }

    SQLSetStmtAttr(sStmt, SQL_ATTR_MAX_ROWS, (void*)FETCH_CNT, 0);
    
    nResult = SQLFetch(sStmt);
    
    if ( nResult == SQL_ERROR || nResult == SQL_SUCCESS_WITH_INFO )
    {
        SetErrorMsgWithStmt(sStmt);
    }

    return nResult;
}

IDE_RC utISPApi::AutoCommit(idBool a_IsCommitOn)
{
    if (a_IsCommitOn) 
    {
        IDE_TEST_RAISE(SQLSetConnectAttr(m_ICon, SQL_ATTR_AUTOCOMMIT, (void*)SQL_AUTOCOMMIT_ON, 0) != IDE_SUCCESS,
                        error);
    }
    else 
    {
        IDE_TEST_RAISE(SQLSetConnectAttr(m_ICon, SQL_ATTR_AUTOCOMMIT, (void*)SQL_AUTOCOMMIT_OFF, 0) != IDE_SUCCESS,
                        error);
    }
    
    return IDE_SUCCESS;

    IDE_EXCEPTION(error);
    {
        SetErrorMsgWithDBC(m_ICon);
    }

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC utISPApi::EndTran(idBool a_IsCommit)
{
    if (a_IsCommit) 
    {
        IDE_TEST_RAISE(SQLEndTran(SQL_HANDLE_DBC, m_ICon, SQL_COMMIT) != IDE_SUCCESS, error);
    }
    else 
    {
        IDE_TEST_RAISE(SQLEndTran(SQL_HANDLE_DBC, m_ICon, SQL_ROLLBACK) != IDE_SUCCESS, error);
    }
    
    return IDE_SUCCESS;

    IDE_EXCEPTION(error);
    {
        SetErrorMsg();
    }

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC utISPApi::GetPlanTree(SChar **a_PlanString, idBool aPrepare)
{
    /*
    SQLHSTMT sStmt;

    if ( aPrepare == ID_TRUE )
    {
        sStmt = m_TmpStmt3;
    }
    else
    {
        sStmt = m_IStmt;
    }
    IDE_TEST_RAISE(SQLGetPlan(sStmt, a_PlanString) != IDE_SUCCESS, error);
    
    return IDE_SUCCESS;

    IDE_EXCEPTION(error);
    {
        SetErrorMsgWithStmt(sStmt);
    }

    IDE_EXCEPTION_END;
    
    return IDE_FAILURE;
    */
    return IDE_FAILURE;
}

IDE_RC utISPApi::GetProcInfo(SChar *a_UserName, SChar *a_ProcName, SShort *a_InOutType, SInt *a_InOutTypeLen, 
                                SShort *a_DataType, SInt *a_DataTypeLen, SShort *a_ParaOrder, SInt *a_ParaOrderLen)
{
// SQLProcedureColumns execute 
// SQLProcedureColumns(stmt, catalog, catalog_len, schema, schema_len, proc_name, proc_name_len, column_name, column_name_len);
//    IDE_TEST_RAISE(SQLProcedureColumns(m_TmpStmt, NULL, 0, a_UserName, SQL_NTS, a_ProcName, SQL_NTS, NULL, 0) != IDE_SUCCESS, tmp_error);    

    idlOS::sprintf(m_Buf, "select decode(inout_type,0,1,2,2,1,4,0), data_type,"
                                  "para_order from system_.sys_proc_paras_ "
                          "where proc_oid = ( select proc_oid "
                                              "from system_.sys_procedures_ "
                                              "where proc_name = \'%s\' "
                                                "and user_id=(select user_id "
                                                  "from system_.sys_users_ "
                                                  "where user_name = \'%s\') ) "
                          "order by para_order",
                   a_ProcName, a_UserName, a_UserName);
    
    IDE_TEST_RAISE(SQLExecDirect(m_TmpStmt, m_Buf, SQL_NTS) != IDE_SUCCESS, tmp_error);    

    SQLBindCol(m_TmpStmt, 1, SQL_C_SSHORT, a_InOutType, 0, a_InOutTypeLen);
    SQLBindCol(m_TmpStmt, 2, SQL_C_SSHORT, a_DataType, 0, a_DataTypeLen);
    SQLBindCol(m_TmpStmt, 3, SQL_C_SSHORT, a_ParaOrder, 0, a_ParaOrderLen);

// Bind columns in result set to buffers 
/*    res = SQLBindCol(m_TmpStmt, 5, SQL_C_SSHORT, a_InOutType, 0, a_InOutTypeLen);
    if (res != SQL_SUCCESS)
    {
        printf("%s:%d:procedure error..\n", __FILE__, __LINE__);

    }
    res = SQLBindCol(m_TmpStmt, 6, SQL_C_SSHORT, a_DataType,  0, a_DataTypeLen);
    if (res != SQL_SUCCESS)
    {
        printf("%s:%d:procedure error..\n", __FILE__, __LINE__);

    }
*/
    return IDE_SUCCESS;

    IDE_EXCEPTION(tmp_error);
    {
        SetErrorMsgWithStmt(m_TmpStmt);
    }

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

SQLRETURN utISPApi::FetchProcInfo()
{
    SQLRETURN nResult;

    nResult = SQLFetch(m_TmpStmt);    
    
    if (nResult == SQL_ERROR)
    {
        SetErrorMsgWithStmt(m_TmpStmt);
        StmtClose(m_TmpStmt);
    }
    else if (nResult == SQL_NO_DATA)
    {
        StmtClose(m_TmpStmt);
    }

    return nResult;
}

SQLRETURN utISPApi::GetReturnType(SChar *a_UserName, SChar *a_ProcName, SShort *a_ReturnDataType, SInt *a_ReturnDataTypeLen)
{
    SQLRETURN nResult;
    SChar msg[MSG_LEN];

    idlOS::sprintf(m_Buf, "select return_data_type from system_.sys_procedures_ where proc_name = \'%s\' \
                              and user_id = ( select user_id from system_.sys_users_ where user_name = \'%s\' )",
                              a_ProcName, a_UserName);

    IDE_TEST_RAISE(SQLExecDirect(m_TmpStmt2, m_Buf, SQL_NTS) != IDE_SUCCESS, error);    
    
    SQLBindCol(m_TmpStmt2, 1, SQL_C_SSHORT, a_ReturnDataType, 0, a_ReturnDataTypeLen);

    nResult = SQLFetch(m_TmpStmt2);    
    
    if (nResult == SQL_ERROR)
    {
        SetErrorMsgWithStmt(m_TmpStmt2);
        StmtClose(m_TmpStmt2);
    }
    else if (nResult == SQL_NO_DATA)
    {
        idlOS::sprintf(msg, "%s not found", a_ProcName);
        SetMsg(msg);
        StmtClose(m_TmpStmt2);
    }

    return nResult;

    IDE_EXCEPTION(error);
    {
        SetErrorMsgWithStmt(m_TmpStmt2);
        StmtClose(m_TmpStmt2);
        return SQL_ERROR;
    }

    IDE_EXCEPTION_END;

    return SQL_ERROR;
}

IDE_RC utISPApi::ProcBindPara(SShort a_Order, SShort a_InOutType, SShort a_CType, SShort a_SqlType, 
                                SInt a_Precision, void *a_HostVar, SInt a_MaxValue, SInt *a_Len)
{
/*
    printf("a_InOutType=%d\n", a_InOutType);
    printf("a_CType=%d\n",     a_CType);
    printf("a_SqlType=%d\n",   a_SqlType);
    printf("a_Precision=%d\n", a_Precision);
    printf("a_MaxValue=%d\n",  a_MaxValue);
    printf("a_Len=%d\n",      *a_Len);
    printf("a_Order=%d\n",     a_Order);
*/
    IDE_TEST_RAISE(SQLBindParameter(m_TmpStmt3, a_Order, a_InOutType, a_CType, a_SqlType, a_Precision, 0, 
                                    a_HostVar, a_MaxValue, a_Len) != IDE_SUCCESS, i_error);

    return IDE_SUCCESS;

    IDE_EXCEPTION(i_error);
    {
        SetErrorMsgWithStmt(m_TmpStmt3);
    }

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC utISPApi::Prepare()
{
    IDE_TEST_RAISE(SQLPrepare(m_TmpStmt3, m_Query, SQL_NTS) != IDE_SUCCESS, i_error);

    return IDE_SUCCESS;

    IDE_EXCEPTION(i_error);
    {
        SetErrorMsgWithStmt(m_TmpStmt3);
    }

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC utISPApi::Execute()
{
    SQLRETURN rc;

    rc = SQLExecute(m_TmpStmt3);
    IDE_TEST_RAISE(rc != SQL_SUCCESS && rc != SQL_NO_DATA, i_error);

    StmtClose(m_TmpStmt3);
    return IDE_SUCCESS;

    IDE_EXCEPTION(i_error);
    {
        SetErrorMsgWithStmt(m_TmpStmt3);
        StmtClose(m_TmpStmt3);
    }

    IDE_EXCEPTION_END;
    StmtClose(m_TmpStmt3);

    return IDE_FAILURE;
}

IDE_RC utISPApi::GetConnectAttr(SInt aAttr, SInt *aValue)
{
    IDE_TEST(SQLGetConnectAttr(m_ICon,
                aAttr,
                aValue,
                0,
                NULL) != SQL_SUCCESS);
    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    SetErrorMsgWithDBC(m_ICon);
    return IDE_FAILURE;
}

IDE_RC utISPApi::Startup()
{
    /*
    IDE_TEST(ADMStartup(m_ICon) != SQL_SUCCESS);

    if ( m_IStmt == SQL_NULL_HSTMT )
    {
        IDE_TEST_RAISE(SQLAllocStmt(m_ICon,&m_IStmt) != IDE_SUCCESS, alloc_stmt_error);
        IDE_TEST_RAISE(SQLAllocStmt(m_ICon,&m_TmpStmt) != IDE_SUCCESS, alloc_stmt_error);
        IDE_TEST_RAISE(SQLAllocStmt(m_ICon,&m_TmpStmt2) != IDE_SUCCESS, alloc_stmt_error);
        IDE_TEST_RAISE(SQLAllocStmt(m_ICon,&m_TmpStmt3) != IDE_SUCCESS, alloc_stmt_error);
    }

    return IDE_SUCCESS;

    IDE_EXCEPTION(alloc_stmt_error);
    {
        SetErrorMsgWithDBC(m_ICon);
    }
    IDE_EXCEPTION_END;

    return IDE_FAILURE;
    */
    return IDE_SUCCESS;
}

IDE_RC utISPApi::Shutdown(SInt aMode)
{
    /*
    IDE_TEST(ADMShutdown(m_ICon, aMode) != SQL_SUCCESS);
    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    SetErrorMsgWithDBC(m_ICon);
    return IDE_FAILURE;
    */
    return IDE_SUCCESS;
}

// BUG-11767 : don't used now
IDE_RC utISPApi::Status(SInt aStatID, SChar *aArg)
{
    /*
    IDE_TEST(ADMStatus(m_ICon, aStatID, aArg) != SQL_SUCCESS);
    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    SetErrorMsgWithDBC(m_ICon);
    return IDE_FAILURE;
    */
    return IDE_SUCCESS;
}

// BUG-11767 : don't used now
IDE_RC utISPApi::Terminate(SChar *aNumber)
{
    /*
    IDE_TEST(ADMTerminate(m_ICon, aNumber) != SQL_SUCCESS);
    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    SetErrorMsgWithDBC(m_ICon);
    return IDE_FAILURE;
    */
    return IDE_SUCCESS;
}
