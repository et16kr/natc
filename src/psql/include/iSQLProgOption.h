/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iSQLProgOption.h 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/

#ifndef _O_ISQLPROGOPTION_H_
#define _O_ISQLPROGOPTION_H_ 1

#include <utISPApi.h>
#include <iSQL.h>

class iSQLProgOption
{
public:
    iSQLProgOption();

    IDE_RC ParsingCommandLine(SInt argc, SChar ** argv);
    IDE_RC ReadProgOptionInteractive();
    IDE_RC ReadEnvironment();

    SChar * GetServerName() { return m_ServerName; }
    SChar * GetLoginID()    { return m_LoginID; }
    SChar * GetPassword()   { return m_Password; }
    SChar * GetNLS()        { return m_NLS; }
    SInt    GetPortNum()    { return m_PortNum; }
    SInt    GetConntype()   { return m_Conntype; }
    SChar * GetInFileName() { return m_InFileName; }

    idBool  IsPortNum()     { return m_bExist_PORT; }
    idBool  IsInFile()      { return m_bExist_F; }
    idBool  IsOutFile()     { return m_bExist_O; }
    idBool  IsSilent()      { return m_bExist_SILENT; }
    idBool  IsVerbose()     { return m_bExist_V; }
    idBool  IsSysdba()      { return m_bExist_SYSDBA; }
    idBool  IsATC()         { return m_bExist_ATC; }

    void    setSysdba(idBool aMode) { m_bExist_SYSDBA = aMode; }

public:
    FILE   * m_OutFile;

private:
    SChar    m_ErrorMsg[MSG_LEN];
    idBool   m_bExist_S;
    SChar    m_ServerName[WORD_LEN];
    idBool   m_bExist_U;
    SChar    m_LoginID[WORD_LEN];
    idBool   m_bExist_P;
    SChar    m_Password[WORD_LEN];
    idBool   m_bExist_F;
    SChar    m_InFileName[WORD_LEN];
    idBool   m_bExist_PORT;
    SInt     m_PortNum;
    SInt     m_Conntype;
    idBool   m_bExist_O;
    idBool   m_bExist_V;         /* verbose mode */
    idBool   m_bExist_SILENT;    /* silent mode */
    idBool   m_bExist_ATC;       /* for atc */
    idBool   m_bExist_SYSDBA;    /* connect to db as sysdba */

    SChar    m_NLS[WORD_LEN];
};

#endif // _O_ISQLPROGOPTION_H_

