/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iloFormDown.h 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/
 
#ifndef _O_ILO_FORMDOWN_H
#define _O_ILO_FORMDOWN_H

class iloFormDown
{
public:
    iloFormDown();

    void SetProgOption(iloProgOption *pProgOption)
    { m_pProgOption = pProgOption; }

    void SetSQLApi(iloSQLApi *pISPApi) { m_pISPApi = pISPApi; }

    isql_bool OpenFormFile();

    void CloseFormFile() { if (m_fpForm != NULL) fclose(m_fpForm); }

    isql_bool FormDown();
    isql_bool FormDownAsStruct();

    isql_bool WriteColumns();
    isql_bool WriteColumnsAsStruct();

private:
    iloProgOption     *m_pProgOption;
    iloSQLApi         *m_pISPApi;
    FILE              *m_fpForm;
};

#endif /* _O_ILO_FORMDOWN_H */
