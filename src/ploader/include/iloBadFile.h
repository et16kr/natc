/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iloBadFile.h 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/
 
#ifndef _O_ILO_BADFILE_H
#define _O_ILO_BADFILE_H

class iloBadFile
{
public:
    iloBadFile();

    void SetTerminator( SChar *szFiledTerm, SChar *szRowTerm );

    isql_bool OpenFile( SChar *szFileName );

    isql_bool CloseFile();

    isql_bool PrintOneRecord( iloTableInfo *pTableInfo, SInt aArrayCount );

private:
    FILE      *m_BadFp; 
    isql_bool  m_UseBadFile;
    SChar      m_FieldTerm[11];
    SChar      m_RowTerm[11];
};

#endif /* _O_ILO_BADFILE_H */
