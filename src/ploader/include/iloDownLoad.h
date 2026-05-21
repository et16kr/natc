/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iloDownLoad.h 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/
 
#ifndef _O_ILO_DOWNLOAD_H
#define _O_ILO_DOWNLOAD_H

class iloDownLoad
{
public:
    iloDownLoad();

    void SetProgOption(iloProgOption *pProgOption)
    { m_pProgOption = pProgOption; }
    
    void SetSQLApi(iloSQLApi *pISPApi) { m_pISPApi = pISPApi; }

    isql_bool GetTableTree();
    
    isql_bool GetTableInfo();

    isql_bool GetQueryString();

    isql_bool DownLoad();

    isql_bool ExecuteQuery();

    isql_bool CompareAttrType();

private:
    iloProgOption     *m_pProgOption;
    iloFormCompiler    m_FormCompiler;
    iloTableTree       m_TableTree;
    iloTableInfo       m_TableInfo;
    iloSQLApi         *m_pISPApi;
    iloDataFile        m_DataFile;
    iloLogFile         m_LogFile;

    SChar              m_QueryStr[64*1024];
};

#endif /* _O_ILO_DOWNLOAD_H */
