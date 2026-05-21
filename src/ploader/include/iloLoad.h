/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iloLoad.h 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/
 
#ifndef _O_ILO_LOAD_H
#define _O_ILO_LOAD_H

class iloLoad
{
public:
    iloLoad();

    void SetProgOption(iloProgOption *pProgOption)
    { m_pProgOption = pProgOption; }

    void SetSQLApi(iloSQLApi *pISPApi) { m_pISPApi = pISPApi; }

    isql_bool LoadwithPrepare();


private:
    isql_bool GetTableTree();

    isql_bool GetTableInfo();

    isql_bool MakePrepareSQLStatement();

    isql_bool ExecuteDeleteStmt();

    isql_bool BindParameter();

private:
    iloProgOption     *m_pProgOption;
    iloFormCompiler    m_FormCompiler;
    iloTableTree       m_TableTree;
    iloTableInfo       m_TableInfo;
    iloSQLApi         *m_pISPApi;
    iloDataFile        m_DataFile;
    iloLogFile         m_LogFile;
    iloBadFile         m_BadFile;
    SInt               m_ulLen;

    SChar              m_SQLStatement[64*1024];
    SQLUINTEGER        mArrayCount;
};

#endif /* _O_ILO_LOAD_H */
