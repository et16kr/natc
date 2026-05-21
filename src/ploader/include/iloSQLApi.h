/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iloSQLApi.h 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/
 
#ifndef _O_ILO_SQLAPI_H
#define _O_ILO_SQLAPI_H

class iloColumns
{
public:
    iloColumns();

    ~iloColumns();

    SInt  GetSize()                     { return m_nCol; }

    void SetColumnCount(SInt nColCount) { m_nCol = nColCount; }

    isql_bool SetSize(SInt nColCount);
    isql_bool resize(SInt nColCount);

    SChar *GetName(SInt nCol) 
    { return (nCol >= m_nCol) ? NULL : m_Name[nCol]; }

    isql_bool SetName(SInt nCol, SChar *szName);

    SInt GetType(SInt nCol)
    { return (nCol >= m_nCol) ? 0 : m_Type[nCol]; }

    isql_bool SetType(SInt nCol, SInt nType);

    SInt GetPrecision(SInt nCol)
    { return (nCol >= m_nCol) ? 0 : m_Precision[nCol]; }

    isql_bool SetPrecision(SInt nCol, SInt nPrecision);

    SInt GetScale(SInt nCol) 
    { return (nCol >= m_nCol) ? 0 : m_Scale[nCol]; }
    
    isql_bool SetScale(SInt nCol, SInt nScale);

    isql_bool SetValue(SInt nCol, SChar *szValue);

public:
    SChar                (*m_Name)[256];  
    SInt                 *m_Precision;
    SInt                 *m_Scale;  
    union ColumnValue    *m_Value;
    SQLINTEGER           *m_Len;
    SInt                 *m_DisplayPos; // 인쇄할 위치, 인쇄가 완료되면 -1

private: 
    SInt            m_nCol;
    SInt            *m_Type;
};


class iloSQLApi    
{
public:
    iloColumns m_Column;

private:
    SQLHENV     m_IEnv;
    SQLHDBC     m_ICon;
    SQLHSTMT    m_IStmt ;
    SChar       m_SQLStatement[4096];
    SChar       m_ErrorMsg[4096];

public:
    SQLINTEGER  mErrorCode;

public:
    iloSQLApi();

    virtual ~iloSQLApi(); 

    void SetSQLStatement(SChar *szStr);

    SQLHSTMT getStmt();

    SChar *GetErrorMsg()              { return m_ErrorMsg; }

    void SetErrorMsg(SChar *szError)  { strcpy(m_ErrorMsg, szError); }

    isql_bool  OpenforUtil(SChar *szHost, 
                           SChar *szUser, 
                           SChar *szPassword);

    isql_bool  Open(SChar *szHost,
                    SChar *szDB,
                    SChar *szUser,
                    SChar *szPassword,
                    SChar *szNLS,
                    SInt   nPort);
    
    isql_bool  OpenWithUD(SChar *szHost,
                          SChar *szDB,
                          SChar *szUser,
                          SChar *szPassword,
                          SChar *szNLS);

    isql_bool OpenWithIPC(SChar *szHost,
                          SChar *szDB,
                          SChar *szUser,
                          SChar *szPassword,
                          SChar *szNLS,
                          SInt nPort);

    isql_bool  OpenWithIPC(SChar *szHost, 
                           SChar *szDB, 
                           SChar *szUser, 
                           SChar *szPassword,
                           SChar *szNLS,
                           SInt  nShmId,
                           SInt  nSemId);

    isql_bool Tables();

    isql_bool Columns(SChar *inTableName, SChar *inTableOwner);

    isql_bool Statistics(SChar *inTableName,
                         SInt &nIndexCount,
                         SIndexInfo **pIndexInfo);

    isql_bool ExecuteDirect();
    
    isql_bool Execute();

    isql_bool Prepare(SChar *szSQLStmt, SInt nAttrCount);

    isql_bool FreeStmtParams();

    isql_bool SelectExecute(iloTableInfo  *aTableInfo);

    isql_bool Fetch();

    isql_bool AutoCommit(isql_bool bIsCommitOn);

    isql_bool EndTran(isql_bool bIsCommit);

    isql_bool setQueryTimeOut( SInt aTime );

    isql_bool alterReplication( isql_bool aBool );

    isql_bool StmtClose();

    isql_bool Close();
};

#endif  /* _O_ILO_SQLAPI_H */

