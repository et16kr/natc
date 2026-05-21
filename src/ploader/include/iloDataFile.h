/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iloDataFile.h 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/
 
#ifndef _O_ILO_DATAFILE_H
#define _O_ILO_DATAFILE_H

#define MAX_READ_BUFFER_LEN (256*1024+1)
#define MAX_TOKENBUFFER_LEN 8192
#define MAX_TOKEN_VALUE_LEN MAX_VARCHAR_SIZE*2

class iloDataFile
{
public:
    iloDataFile();

    isql_bool OpenFile(SChar *szFileName, SChar *szMode);
    isql_bool OpenFile(SChar *szFileName, SInt sFileCnt, SChar *szMode);

    isql_bool CloseFile();

    void SetTerminator(SChar *szFiledTerm, SChar *szRowTerm);

    void SetEnclosing(isql_bool bSetEnclosing, SChar *szEnclosing);

    isql_bool PrintOneRecord(iloColumns *pCols);

    SInt  ReadOneRecord(iloTableInfo *pTableInfo, SInt aArrayCount);

    EDataToken GetToken();

    SChar *GetTokenValue()        { return (m_TokenValue); }

    SInt  GetChar();

    void rtrim();

    SInt strtonumCheck(SChar *p);

//    void SetAttrExtra( SInt aExtra );

private:
    FILE      *m_DataFp; 
    isql_bool  m_SetEnclosing;
    SChar      m_FieldTerm[11];
    SChar      m_RowTerm[11];
    SChar      m_Enclosing[11];
    SInt       m_nFTLen;
    SInt       m_nRTLen;
    SInt       m_nEnLen;
    SChar      m_TokenValue[MAX_TOKEN_VALUE_LEN];
    isql_bool  m_SetNextToken;

    UChar      m_ReadBuf[MAX_READ_BUFFER_LEN];
    SInt       m_nCurReadPos;
    SInt       m_nReadSize;
};

inline SInt iloDataFile::GetChar()
{
    if (m_nCurReadPos == m_nReadSize)
    {
        m_nReadSize = idlOS::fread(m_ReadBuf,
                             sizeof(SChar), MAX_TOKENBUFFER_LEN, m_DataFp);

        if (m_nReadSize == 0)
        {
            m_nCurReadPos = 0;
            return EOF;
        }
        m_nCurReadPos = 0;
    }

    return (SInt) m_ReadBuf[m_nCurReadPos++];
}


#endif /* _O_ILO_DATAFILE_H */
