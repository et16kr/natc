/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: utISPApi.h 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/

#ifndef _O_UTISPAPI_H_
#define _O_UTISPAPI_H_ 1

#include <sqlcli.h>

#define COMMAND_LEN             1024*64
#define MSG_LEN                 2048
#define QP_MAX_NAME_LEN         40
#define QC_MAX_KEY_COLUMN_COUNT 32
#define SMC_INDEX_MAX_COUNT     48
#define NUMBER_SIZE             11
#define SMALLINT_SIZE           6
#define INTEGER_SIZE            11
#define BIGINT_SIZE             20
#define DATE_SIZE               19
#define FETCH_CNT               10

#define TYPE_UNKNOWN              0
#define TYPE_SYSTEM_TABLE         1
#define TYPE_TABLE                2
#define TYPE_VIEW                 3

enum iSQLForeignKeyKind
{
    FOREIGNKEY_PK=0, FOREIGNKEY_FK=1
};

typedef struct IndexInfo
{
    SChar  IndexName[QP_MAX_NAME_LEN+1];
    SChar  ColumnName[QP_MAX_NAME_LEN+1];
    idBool SortAsc;
    SShort OrdinalPos;  // 1, 2, 3, ...
    idBool NonUnique;
    SChar  IndexType[10];

} IndexInfo;

union ColumnValue
{
    SChar   *CValue;
    SFloat   FValue;
    SDouble  DValue;
};

class utColumns
{
public:
    utColumns();
    ~utColumns();

    void    freeMem();
    IDE_RC  SetSize(SInt a_ColCount);
    SInt    GetSize()                                   { return m_Col; }
    IDE_RC  SetName(SInt a_Col, SChar *a_Name);
    SChar  *GetName(SInt a_Col)                         { return (a_Col >= m_Col) ? NULL : m_Name[a_Col]; }
    IDE_RC  SetUserName(SInt a_Col, SChar *a_UserName);
    SChar  *GetUserName(SInt a_Col)                     { return (a_Col >= m_Col) ? NULL : m_UserName[a_Col]; }
    IDE_RC  SetType(SInt a_Col, SInt a_Type);    
    SInt    GetType(SInt a_Col)                         { return (a_Col >= m_Col) ? 0 : m_Type[a_Col]; }
    IDE_RC  SetPrecision(SInt a_Col, SInt a_Precision);
    SInt    GetPrecision(SInt a_Col)                    { return (a_Col >= m_Col) ? 0 : m_Precision[a_Col]; }
    IDE_RC  SetScale(SInt a_Col, SInt a_Scale); 
    SInt    GetScale(SInt a_Col)                        { return (a_Col >= m_Col) ? 0 : m_Scale[a_Col]; }
    IDE_RC  SetNull(SInt a_Col, SInt a_Null);
    SInt    GetNull(SInt a_Col)                         { return (a_Col >= m_Col) ? 0 : m_Null[a_Col]; }
    IDE_RC  SetIsVaring(SInt a_Col, SChar *a_IsVaring);
    SChar  *GetIsVaring(SInt a_Col)                     { return (a_Col >= m_Col) ? NULL : m_IsVaring[a_Col]; }
    IDE_RC  SetValueSize(SInt a_Col, SInt a_Size);
    void    SetColumnCount(SInt a_ColCount)             { m_Col = a_ColCount; }

public:
    union ColumnValue *m_Value;
    SChar **m_CValue;
    SChar (*m_Name)[QP_MAX_NAME_LEN+1];  
    SChar (*m_UserName)[QP_MAX_NAME_LEN+1];  
    SInt   *m_Len;
    idBool *m_IsChar;

private: 
    SInt  *m_Type;
    SInt  *m_Precision;
    SInt  *m_Scale;  
    SInt  *m_Null;
    SInt   m_Col;
    SChar (*m_IsVaring)[QP_MAX_NAME_LEN+1];
};

class utISPApi    
{
public:
    utISPApi(SInt a_bufSize);
    ~utISPApi();

    IDE_RC  SetQuery(SChar *a_query);
    SChar  *GetErrorMsg()           { return m_ErrorMsg; }
    SChar  *GetErrorState()         { return m_ErrorState; }

    SQLRETURN Open(SChar *a_Host, SChar *a_User, SChar *a_Passwd, SChar *a_NLS, 
                SInt a_Port, SInt a_Conntype,
                MESSAGE_CALLBACK_STRUCT *a_MessageCallbackStruct);
    IDE_RC Close();
    IDE_RC StmtClose(idBool aPrepare=ID_FALSE); 
    
    IDE_RC Tables(SChar *a_UserName, idBool a_IsSysUser);   
    IDE_RC FixedTables(SChar *a_UserName, idBool a_IsSysUser);   
    IDE_RC PerformanceViews(SChar *a_UserName, idBool a_IsSysUser);   
    IDE_RC Sequence(SChar *a_UserName, idBool a_IsSysUser);   
    IDE_RC getTBSName(SChar *a_UserName,
                      SChar *a_TableName,
                      SChar *aTBSName);
    IDE_RC Columns(SChar *a_UserName, SChar *a_TableName);  
    IDE_RC Columns4FTnPV(SChar *a_UserName, SChar *a_TableName);  
    IDE_RC Statistics(SChar *a_UserName, SChar *a_TableName, SInt *a_IndexCount, IndexInfo **a_IndexInfo);
    IDE_RC PrimaryKeys(SChar *a_UserName, SChar *a_TableName, 
                       SChar a_pk[QC_MAX_KEY_COLUMN_COUNT][QP_MAX_NAME_LEN+1], SInt *a_pk_col_cnt);
    IDE_RC ForeignKeys( SChar              *a_UserName,
                        SChar              *a_TableName,
                        iSQLForeignKeyKind  a_Tyep,
                        SChar              *aPKSchema,
                        SChar              *aPKTableName,
                        SChar              *aPKColumnName,
                        SChar              *aPKName,
                        SChar              *aFKSchema,
                        SChar              *aFKTableName,
                        SChar              *aFKColumnName,
                        SChar              *aFKName,
                        SShort             *aKeySeq );
    
    IDE_RC    DirectExecute();
    IDE_RC    SelectExecute(idBool aPrepare=ID_FALSE);
    SQLRETURN Fetch(idBool aPrepare=ID_FALSE);
    SQLRETURN FetchNext();
    SQLRETURN FetchSequence();
    IDE_RC    GetRowCount(SInt *a_rowcnt, idBool aPrepare=ID_FALSE);
    IDE_RC    ExplainPlanExecute(SInt a_type);
    
    IDE_RC AutoCommit(idBool a_IsCommitOn);
    IDE_RC EndTran(idBool a_IsCommit);
    IDE_RC GetPlanTree(SChar **a_PlanString, idBool aPrepare=ID_FALSE);

    IDE_RC    GetProcInfo(SChar *a_UserName, SChar *a_ProcName, 
                          SShort *a_InOutType, SInt *a_InOutTypeLen, 
                          SShort *a_DataType, SInt *a_DataTypeLen, 
                          SShort *a_ParaOrder, SInt *a_ParaOrderLen);
    SQLRETURN FetchProcInfo(); 
    IDE_RC    ProcBindPara(SShort a_Order, SShort a_InOutType, 
                           SShort a_CType, SShort a_SqlType, 
                           SInt a_Precision, void *a_HostVar, SInt a_MaxValue, 
                           SInt *a_Len);
    SQLRETURN GetReturnType(SChar *a_UserName, SChar *a_ProcName, 
                            SShort *a_ReturnDataType, SInt *a_ReturnDataTypeLen);

/* BUGBUG-procedure, function directExecute 수행하면 에러 */
    IDE_RC    Prepare();
    IDE_RC    Execute();
    IDE_RC    GetConnectAttr(SInt aAttr, SInt *aValue);

    // for admin
    IDE_RC Startup();
    IDE_RC Shutdown(SInt aMode);
    IDE_RC Status(SInt aStatID, SChar *aArg);
    IDE_RC Terminate(SChar *aNumber);

private:
    void   SetMsg(SChar *a_msg);
    IDE_RC SetErrorMsg();   // for EndTran    
    void   SetErrorMsg(SChar *a_errMsg);
    IDE_RC SetErrorMsgWithDBC(SQLHDBC a_con);    
    IDE_RC SetErrorMsgWithStmt(SQLHSTMT a_stmt);    
    IDE_RC StmtClose(SQLHSTMT a_stmt);

public:
    utColumns m_Column;

private:
    SQLHENV   m_IEnv;
    SQLHDBC   m_ICon;
    SQLHSTMT  m_IStmt;
    SQLHSTMT  m_TmpStmt;    // use Tables, Columns, GetProcInfo, FetchProcInfo
    SQLHSTMT  m_TmpStmt2;   // use GetReturnType
    SQLHSTMT  m_TmpStmt3;   // use Prepare, ProcBindPara, Execute, BUGBUG-stmt prepare 사용 후 directExecute 사용하면 에러
    SChar     m_Query[COMMAND_LEN];
    SChar     m_ErrorMsg[IDCCLI_ERROR_MSG_LEN];
    SChar     m_ErrorState[6];
    SChar    *m_Buf;
};

#endif // _O_UTISPAPI_H_ 
