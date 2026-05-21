/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iloProgOption.h 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/
 
#ifndef _O_ILO_PROGOPTION_H
#define _O_ILO_PROGOPTION_H

class iloProgOption
{
public:
    iloProgOption();

    void InitOption();

    SChar *MakeCommandLine(SInt argc, SChar **argv);

    isql_bool ParsingCommandLine(SInt argc, SChar **argv); 

    isql_bool ReadProgOptionInteractive(SInt *aConnType );

    isql_bool ReadEnvironment();

    isql_bool IsValidOption();

    SInt  TestCommandLineOption();

    isql_bool ValidTermString();

    void ResetError(void);

    isql_bool ExistError()   { return m_bErrorExist; }

    SChar* GetErrorMsg()     { return m_ErrorMsg; }

    SChar* GetServerName()   { return m_ServerName; }

    SChar* GetDBName()       { return m_DBName; }

    SChar* GetLoginID()      { return m_LoginID; }

    SChar* GetPassword()     { return m_Password; }

    SChar* GetNLS()          { return m_NLS; }

    SInt   GetPortNum()      { return m_PortNum; }

    SInt   GetShmId()        { return m_ShmId; }

    SInt   GetSemId()        { return m_SemId; }

public:
    isql_bool    m_bErrorExist;
    SChar        m_ErrorMsg[MAX_WORD_LEN];

    ECommandType m_CommandType;
    ECommandType m_HelpArgument;

    SChar        m_DBName[MAX_WORD_LEN];
    SChar        m_NLS[MAX_WORD_LEN];
    SInt         m_ShmId;
    SInt         m_SemId;

    isql_bool    m_bExist_b; // bad input checker

    isql_bool    m_bExist_U;
    SChar        m_LoginID[MAX_WORD_LEN*2];

    isql_bool    m_bExist_P;
    SChar        m_Password[MAX_WORD_LEN];

    isql_bool    m_bExist_S;
    SChar        m_ServerName[MAX_WORD_LEN];

    isql_bool    m_bExist_PORT;
    SInt         m_PortNum;

    isql_bool    m_bExist_Silent;
    isql_bool    m_bExist_NST;    // not show elapsed time

    isql_bool    m_bExist_T;
    SInt         m_nTableCount;
    SChar        m_TableName[50][MAX_TABLENAME_LEN];
    isql_bool    m_bExist_TabOwner;
    SChar        m_TableOwner[50][MAX_TABLENAME_LEN];

    isql_bool    m_bExist_d;
    SChar        m_DataFile[MAX_FILEPATH_LEN];

    isql_bool    m_bExist_f;
    SChar        m_FormFile[MAX_FILEPATH_LEN];

    isql_bool    m_bExist_F;
    SInt         m_FirstRow;

    isql_bool    m_bExist_L;
    SInt         m_LastRow;

    isql_bool    m_bExist_t;
    SChar        m_DefaultFieldTerm[11];
    SChar        m_FieldTerm[11];

    isql_bool    m_bExist_r;
    SChar        m_DefaultRowTerm[11];
    SChar        m_RowTerm[11];

    isql_bool    m_bExist_e;
    SChar        m_EnclosingChar[11];

    isql_bool    m_bExist_mode;
    ELoadMode    m_LoadMode;

    isql_bool    m_bExist_array;
    SInt         m_ArrayCount;

    isql_bool    m_bExist_commit;
    SInt         m_CommitUnit;

    isql_bool    m_bExist_errors;
    SInt         m_ErrorCount;

    isql_bool    m_bExist_log;
    SChar        m_LogFile[MAX_FILEPATH_LEN];

    isql_bool    m_bExist_bad;
    SChar        m_BadFile[MAX_FILEPATH_LEN];

    isql_bool    mReplication;

    isql_bool    m_bExist_split;
    SInt         m_SplitRowCount;

    isql_bool    m_bExist_informix;
    isql_bool    mInformix;

    isql_bool    m_bExist_noexp; 
    isql_bool    mNoExp; 

    isql_bool    mInvalidOption; 
};

#endif /* _O_ILO_PROGOPTION_H */

