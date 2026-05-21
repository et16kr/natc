/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iSQLCompiler.h 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/

#ifndef _O_ISQLCOMPILER_H_
#define _O_ISQLCOMPILER_H_ 1

#include <iSQLSpool.h>

typedef struct script_file
{
    FILE        * fp;
    SChar         filePath[256];
    script_file * next;
} script_file;

class iSQLCompiler
{
public:
    iSQLCompiler();
    ~iSQLCompiler();
    
    void   SetInputStr(SChar *a_Str);
    void   RegStdin();
    IDE_RC SetScriptFile(SChar *a_File, iSQLPathType a_PathType);     
    IDE_RC ResetInput();
    void   SetFileRead(idBool a_FileRead)    { m_FileRead = a_FileRead; } 
    idBool IsFileRead()                      { return m_FileRead; }

    void   SetPrompt(idBool a_IsATC);
    void   PrintPrompt();
    void   PrintLineNum();
    void   PrintCommand();

    IDE_RC SaveCommandToFile(SChar        *a_Command,
                             SChar        *a_FileName,
                             iSQLPathType  a_PathType);
    IDE_RC SaveCommandToFile2(SChar *a_Command);

    IDE_RC ParsingExecProc(SChar *a_Buf, idBool a_IsFunc, SInt a_bufSize); 
    IDE_RC ParsingPrepareSQL( SChar * a_Buf,
                              SInt    a_bufSize );

public:
    script_file * m_flist;

private:
    iSQLSpool     m_Spool;
    idBool        m_FileRead;        // -f, @, start, load
public:
    SChar         m_Prompt[5];       // after second line 
    SInt          m_LineNum;         // after second line 
};

class iSQLBufMgr
{
public:
    iSQLBufMgr(SInt a_bufSize);
    ~iSQLBufMgr();
    
    void      Reset();     
    IDE_RC    Append(SChar *a_Str);
    SChar   * GetBuf()    { return m_Buf; }

private:
    iSQLSpool    m_Spool;
    SChar      * m_Buf;       
    SChar      * m_BufPtr;       
    SInt         m_MaxBuf;
};

#endif // _O_ISQLCOMPILER_H_

