/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iloLogFile.h 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/
 
#ifndef _O_ILO_LOGFILE_H
#define _O_ILO_LOGFILE_H

class iloLogFile
{
public:
    iloLogFile();

    void SetTerminator(SChar *szFiledTerm, SChar *szRowTerm);
    
    isql_bool OpenFile(SChar *szFileName);

    isql_bool CloseFile();

    void PrintLogMsg(SChar *szMsg);

    void PrintTime(SChar *szPrnStr);

    isql_bool PrintOneRecord(iloTableInfo *pTableInfo, SInt aArrayCount);

private:
    FILE      *m_LogFp; 
    isql_bool  m_UseLogFile;
    SChar      m_FieldTerm[11];
    SChar      m_RowTerm[11];
};

#endif /* _O_ILO_LOGFILE_H */
