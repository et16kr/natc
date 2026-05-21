/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iSQLCompiler.cpp 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/

#include <ideMsgLog.h>
#include <ideErrorMgr.h>
#include <utString.h>
#include <iSQLProgOption.h>
#include <iSQLExecuteCommand.h>
#include <iSQLHostVarMgr.h>
#include <iSQLSpool.h>
#include <iSQLCompiler.h>

#ifdef USE_READLINE
#include <histedit.h>

extern EditLine *gEdo;
#endif


extern iSQLCompiler       *gSQLCompiler;
extern utString            gString;
extern iSQLProgOption      gProgOption;
extern iSQLExecuteCommand *gExecuteCommand;
extern iSQLHostVarMgr      gHostVarMgr;
extern iSQLSpool          *gSpool;
extern iSQLBufMgr          *gBufMgr;
extern idBool              g_glogin;
extern idBool              g_login;
extern SChar  * gTmpBuf;

void gSetInputStr(SChar *s);

#ifdef USE_READLINE
extern char * isqlprompt(EditLine *el);

char * isqlprompt2(EditLine *el)
{
    static char tmp[28];
    idlOS::sprintf(tmp, "%s%d ", gSQLCompiler->m_Prompt, gSQLCompiler->m_LineNum-1);
    return tmp;
}
#endif

iSQLCompiler::iSQLCompiler()
{
    m_flist        = NULL;
    m_FileRead     = ID_FALSE;
    m_LineNum      = 2;
    idlOS::strcpy(m_Prompt, "    ");

}

iSQLCompiler::~iSQLCompiler()
{
}

void 
iSQLCompiler::SetInputStr( SChar * a_Str )
{
    gSetInputStr(a_Str); 
}

IDE_RC 
iSQLCompiler::ParsingExecProc( SChar * a_Buf, 
                               idBool  a_IsFunc, 
                               SInt    a_bufSize )
{
    // for execute procedure/function
    SChar *tmpBuf;
    SChar *pos, *pos1, *pos2, *begin_pos;
    SInt   nLen;
    SInt   order      = 1;
    SInt   para_order = 1;
    SInt   brace_cnt  = 0;
    idBool inString   = ID_FALSE;

    if ( (tmpBuf = (SChar*)idlOS::malloc(a_bufSize)) == NULL )
    {
        idlOS::fprintf(stderr, "Memory allocation error!!! --- (%d, %s)\n", __LINE__, __FILE__);
        exit(0);
    }
    idlOS::memset(tmpBuf, 0x00, a_bufSize);

    idlOS::strcpy(tmpBuf, a_Buf);
    gString.eraseWhiteSpace(tmpBuf);

    gHostVarMgr.initBindList();

    if ( a_IsFunc == ID_TRUE )
    {
        pos1 = idlOS::strchr(tmpBuf, ':');
        assert(pos1 != NULL);

        pos2 = idlOS::strchr(pos1+1, ':');
        assert(pos2 != NULL);
        *pos2 = '\0';

        gString.eraseWhiteSpace(pos1+1);
        gString.removeLastCR(pos1+1);
        gString.toUpper(pos1+1);
        IDE_TEST(gHostVarMgr.putBindList(pos1+1, order++, para_order) != IDE_SUCCESS);

        pos1 = idlOS::strchr(pos2+1, '(');
    }
    else
    {
        pos1 = idlOS::strchr(tmpBuf, '(');
    }

    if (pos1==NULL)
    {
        IDE_TEST_RAISE(!a_IsFunc, have_no_host_var);
        IDE_RAISE(have_no_host_var_with_func);
    }
    
    begin_pos = pos1+1;
    nLen = idlOS::strlen(begin_pos);

    for (pos=begin_pos; pos<begin_pos+nLen; pos++)
    {
        if ( inString == ID_TRUE )
        {
            if (*pos == '\'')
            {
                inString = ID_FALSE;
            }
        }
        else if (brace_cnt > 0)
        {
            if (*pos == ')')
            {
                brace_cnt--;
            }
            else if (*pos == '(')
            {
                brace_cnt++;
            }
        }
        else
        {
            if (*pos == '\'')
            {
                inString = ID_TRUE;
            }
            else if (*pos == '(')
            {
                brace_cnt++;
            }
            else if (*pos == ':')
            {
                pos1 = idlOS::strchr(pos+1, ',');
                if (pos1 != NULL)
                {
                    *pos1 = '\0';
                }
                else
                {
                    pos1 = idlOS::strchr(pos+1, ')');
                    if (pos1 != NULL)
                    {
                        *pos1 = '\0';
                    }
                }

                gString.eraseWhiteSpace(pos+1);
                gString.removeLastCR(pos+1);
                gString.toUpper(pos+1);
                IDE_TEST(gHostVarMgr.putBindList(pos+1, order++, para_order++) != IDE_SUCCESS);
                pos = pos1;
            }
            else if (*pos == ',')
            {
                para_order++;
            }
        }
    }
    
    if ( tmpBuf != NULL )
    {
        idlOS::free(tmpBuf);
        tmpBuf = NULL;
    }

    return IDE_SUCCESS;            

    IDE_EXCEPTION(have_no_host_var); 
    {
        if ( tmpBuf != NULL )
        {
            idlOS::free(tmpBuf);
            tmpBuf = NULL;
        }
        return IDE_SUCCESS;           
    }

    IDE_EXCEPTION(have_no_host_var_with_func); 
    {
        if ( tmpBuf != NULL )
        {
            idlOS::free(tmpBuf);
            tmpBuf = NULL;
        }
        return IDE_SUCCESS;           
    }

    IDE_EXCEPTION_END;

    if ( tmpBuf != NULL )
    {
        idlOS::free(tmpBuf);
        tmpBuf = NULL;
    }
    return IDE_FAILURE;
}

IDE_RC 
iSQLCompiler::ParsingPrepareSQL( SChar * a_Buf, 
                                 SInt    a_bufSize )
{
    // for execute procedure/function
    SChar *tmpBuf;
    SChar *pos, *pos1, *begin_pos;
    SInt   nLen;
    SInt   order      = 1;
    SInt   brace_cnt  = 0;
    idBool inString   = ID_FALSE;

    if ( (tmpBuf = (SChar*)idlOS::malloc(a_bufSize)) == NULL )
    {
        idlOS::fprintf(stderr, "Memory allocation error!!! --- (%d, %s)\n",
                       __LINE__, __FILE__);
        exit(0);
    }
    idlOS::memset(tmpBuf, 0x00, a_bufSize);

    idlOS::strcpy(tmpBuf, a_Buf);
    gString.eraseWhiteSpace(tmpBuf);

    gHostVarMgr.initBindList();

    begin_pos = tmpBuf;
    nLen = idlOS::strlen(begin_pos);

    for (pos=begin_pos; pos<begin_pos+nLen; pos++)
    {
        if ( inString == ID_TRUE )
        {
            if (*pos == '\'')
            {
                inString = ID_FALSE;
            }
        }
        else
        {
            if (*pos == '\'')
            {
                inString = ID_TRUE;
            }
            else if (*pos == ':')
            {
                pos1 = pos+1;
                for (pos=pos1; pos<begin_pos+nLen; pos++)
                {
                    if ( *pos == ' ' ||
                         *pos == '\t' ||
                         *pos == '\n' ||
                         *pos == ')' ||
                         *pos == ',' )
                    {
                        *pos = '\0';
                        break;
                    }
                }

                gString.eraseWhiteSpace(pos1);
                gString.removeLastCR(pos1);
                gString.toUpper(pos1);
                IDE_TEST(gHostVarMgr.putBindList(pos1, order, order++)
                         != IDE_SUCCESS);
            }
        }
    }
    
    if ( tmpBuf != NULL )
    {
        idlOS::free(tmpBuf);
        tmpBuf = NULL;
    }

    return IDE_SUCCESS;            

    IDE_EXCEPTION_END;

    if ( tmpBuf != NULL )
    {
        idlOS::free(tmpBuf);
        tmpBuf = NULL;
    }
    return IDE_FAILURE;
}
/* ============================================
 * Register stdin
 * This function is called only one when isql start if not -f option
 * ============================================ */
void 
iSQLCompiler::RegStdin()
{
    script_file * sf;

    sf = (script_file*)idlOS::malloc(sizeof(script_file));
    if (sf == NULL)
    {
        idlOS::fprintf(stderr, 
                "Memory allocation error!!! --- (%d, %s)\n", 
                __LINE__, __FILE__);
        exit(1);
    }
    memset(sf, 0x00, sizeof(script_file));

    sf->fp   = stdin;
    sf->next = m_flist;
    m_flist  = sf;
}

/* ============================================
 * Reset input of isql 
 * 1. When input is at end-of-file 
 * 2. After load
 * ============================================ */
IDE_RC 
iSQLCompiler::ResetInput()
{
    script_file * sf;
    script_file * sf2 = NULL;

    sf  = m_flist;
    if ( sf != NULL )
    {
        sf2 = sf->next;
    }
    idlOS::fclose(sf->fp);
    free(sf);
    m_flist = sf2;

    if ( m_flist == NULL )
    {
        /* ============================================
         * Case of -f option 
         * ============================================ */
        SetFileRead(ID_FALSE);
        return IDE_FAILURE;
    }
    else
    {
        /* ============================================
         * Not -f option
         * Set stdin for input of isql
         * ============================================ */
        if ( gProgOption.IsInFile() == ID_FALSE && m_flist->next == NULL )
        {
            SetFileRead(ID_FALSE);
        }
        return IDE_SUCCESS;
    }
}

IDE_RC 
iSQLCompiler::SetScriptFile( SChar        * a_FileName,
                             iSQLPathType   a_PathType )
{
    // -f, @, start, load
    SChar  full_filename[WORD_LEN];
    SChar  filename[WORD_LEN];
    SChar  filePath[WORD_LEN];
    SChar  tmp[WORD_LEN];
    SChar *pos;
    FILE  *fp;
    script_file *sf; 

    idlOS::strcpy(tmp, a_FileName);
    idlOS::strcpy(filePath, "");
    idlOS::strcpy(full_filename, "");

    if ( a_PathType == ISQL_PATH_CWD )
    {
        if (a_FileName[0] == IDL_FILE_SEPARATOR)
        {
            pos = idlOS::strrchr(tmp, IDL_FILE_SEPARATOR);
            *pos = '\0';
            idlOS::strcpy(filePath, tmp);
            idlOS::strcat(filePath, IDL_FILE_SEPARATORS);
            *pos = IDL_FILE_SEPARATOR;
        }
        else
        {
            pos = idlOS::strrchr(tmp, IDL_FILE_SEPARATOR);
            if ( pos != NULL )
            {
                *pos = '\0';
                idlOS::strcpy(filePath, tmp);
                *pos = IDL_FILE_SEPARATOR;
                idlOS::strcat(filePath, IDL_FILE_SEPARATORS);
            }
        }
    }
    else if ( a_PathType == ISQL_PATH_AT )
    {
        if ( m_flist == NULL )
        {
            idlOS::strcpy(filePath, "");
        }
        else
        {
            idlOS::strcpy(filePath, m_flist->filePath);
        }
    }
    else if ( a_PathType == ISQL_PATH_HOME )
    {
        pos = idlOS::getenv("ALTIBASE_HOME");
        IDE_TEST( pos == NULL );
        idlOS::strcpy(filePath, pos);
        if ( tmp[0] == IDL_FILE_SEPARATOR )
        {
            idlOS::strcat(filePath, IDL_FILE_SEPARATORS);
        }
    }

    pos = idlOS::strrchr(tmp, IDL_FILE_SEPARATOR);
    if ( pos == NULL )  // filename only
    {
        if ( idlOS::strchr(tmp, '.') == NULL )
        {
            idlOS::sprintf(filename, "%s.sql", tmp);
        }
        else
        {
            idlOS::strcpy(filename, tmp);
        }
    }
    else    // path+filename
    {
        if ( idlOS::strchr(pos+1, '.') == NULL )
        {
            idlOS::sprintf(filename, "%s.sql", tmp);
        }
        else
        {
            idlOS::strcpy(filename, tmp);
        }
    }

    if ( a_PathType == ISQL_PATH_AT )
    {
        idlOS::sprintf(full_filename, "%s%s", filePath, filename);
    }
    else if ( a_PathType == ISQL_PATH_HOME )
    {
        idlOS::sprintf(full_filename, "%s%s", filePath, filename);
    }
    else
    {
        idlOS::strcpy(full_filename, filename);
    }

    fp = isql_fopen(full_filename, "r");
    IDE_TEST_RAISE(fp == NULL, fail_open_file); 

    sf = (script_file*)idlOS::malloc(sizeof(script_file));
    if (sf == NULL)
    {
        idlOS::fprintf(stderr, "Memory allocation error!!! --- (%d, %s)\n",
                       __LINE__, __FILE__);
        exit(0);
    }
    memset(sf, 0x00, sizeof(script_file));

    pos = idlOS::strrchr(full_filename, IDL_FILE_SEPARATOR);
    if ( pos != NULL )
    {
        *pos = '\0';
        idlOS::strcpy(filePath, full_filename);
        *pos = IDL_FILE_SEPARATOR;
        idlOS::strcat(filePath, IDL_FILE_SEPARATORS);
    }
    else
    {
        idlOS::strcpy(filePath, "");
    }
    sf->fp = fp;
    idlOS::strcpy(sf->filePath, filePath);
    sf->next = m_flist;
    m_flist = sf;
    SetFileRead(ID_TRUE); 

    return IDE_SUCCESS;

    IDE_EXCEPTION(fail_open_file); 
    {
        if ( !g_glogin && !g_login ) 
        {
            idlOS::sprintf(gSpool->m_Buf, "Can not open file. [%s]\n", full_filename);
            gSpool->Print();
        }
    }

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC 
iSQLCompiler::SaveCommandToFile( SChar        * a_Command, 
                                 SChar        * a_FileName,
                                 iSQLPathType   a_PathType )
{
    SChar  *sHomePath = NULL;
    SChar  filename[WORD_LEN];
    SChar *pos;
    FILE  *fp;

    idlOS::strcpy(filename, "");
    if ( a_PathType == ISQL_PATH_HOME )
    {
        sHomePath = idlOS::getenv("ALTIBASE_HOME");
        IDE_TEST_RAISE( sHomePath == NULL, err_home_path );
        idlOS::strcpy(filename, sHomePath);
    }
    idlOS::strcat(filename, a_FileName);

    pos = idlOS::strrchr(a_FileName, IDL_FILE_SEPARATOR);
    if ( pos == NULL )  // filename only
    {
        if ( idlOS::strchr(a_FileName, '.') == NULL )
        {
            idlOS::strcat(filename, ".sql");
        }
    }
    else    // path+filename
    {
        if ( idlOS::strchr(pos+1, '.') == NULL )
        {
            idlOS::strcat(filename, ".sql");
        }
    }

    fp = isql_fopen(filename, "r");
    IDE_TEST_RAISE(fp != NULL, already_exist_file);

    fp = isql_fopen(filename, "wt");  // BUGBUG option : append/replace, history no
    IDE_TEST_RAISE(fp == NULL, fail_open_file); 

    idlOS::fprintf(fp, "%s", a_Command);
    idlOS::fclose(fp);

    idlOS::sprintf(gSpool->m_Buf, "Save completed.\n");
    gSpool->Print();

    return IDE_SUCCESS;

    IDE_EXCEPTION(already_exist_file); 
    {
        idlOS::fclose(fp);
        idlOS::sprintf(gSpool->m_Buf, "Already exist file. [%s]\n", a_FileName);
        gSpool->Print();
    }

    IDE_EXCEPTION(fail_open_file); 
    {
        idlOS::sprintf(gSpool->m_Buf, "Can not open file. [%s]\n", a_FileName);
        gSpool->Print();
    }
    IDE_EXCEPTION(err_home_path); 
    {
        idlOS::sprintf(gSpool->m_Buf, "Set environment ALTIBASE_HOME");
        gSpool->Print();
    }

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC 
iSQLCompiler::SaveCommandToFile2( SChar * a_Command )
{
    FILE  *fp;

    fp = isql_fopen(ISQL_BUF, "wt");  // BUGBUG option : append/replace, history no
    IDE_TEST_RAISE(fp == NULL, fail_open_file); 

    idlOS::fprintf(fp, "%s", a_Command);
    idlOS::fclose(fp);

    return IDE_SUCCESS;

    IDE_EXCEPTION(fail_open_file); 
    {
        idlOS::sprintf(gSpool->m_Buf, "Can not open file. [%s]\n", ISQL_BUF);
        gSpool->Print();
    }

    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

void 
iSQLCompiler::SetPrompt( idBool a_IsATC )
{
    if ( a_IsATC == ID_TRUE )
    {
        idlOS::strcpy(m_Prompt, "iSQL");
    }
    else
    {
        idlOS::strcpy(m_Prompt, "    ");
    }
}

void 
iSQLCompiler::PrintPrompt()
{
#ifdef USE_READLINE
    if ( (gProgOption.IsATC() != ID_TRUE) && (gProgOption.IsInFile() != ID_TRUE) )
    {
        el_set(gEdo, EL_PROMPT, isqlprompt);
    }
#endif
    if ( !g_glogin && !g_login && !IsFileRead() ) 
    {        
        m_LineNum = 2;
        m_Spool.PrintPrompt();
    }
}

void 
iSQLCompiler::PrintLineNum()
{
    if ( !IsFileRead() && !g_glogin && !g_login ) 
    {        
        idlOS::sprintf(m_Spool.m_Buf, "%s%d ", m_Prompt, m_LineNum++);
#ifdef USE_READLINE
        if ( (gProgOption.IsATC() == ID_TRUE) || (gProgOption.IsInFile() == ID_TRUE) )
        {
            m_Spool.Print();
        }
        else
        {
            el_set(gEdo, EL_PROMPT, isqlprompt2);
        }
#else
        m_Spool.Print();
#endif
    }
}

/* ============================================
 * Write command to stdout or output file
 * case of -f, load, @, start
 * ============================================ */
void 
iSQLCompiler::PrintCommand()
{
    if ( IsFileRead() && !g_glogin && !g_login ) 
    {        
        idlOS::strcpy(gTmpBuf, gBufMgr->GetBuf());
        idlOS::sprintf(m_Spool.m_Buf, "iSQL> %s", gBufMgr->GetBuf());
        m_Spool.Print();
    }
}

/******************************
 * iSQLBufMgr
 ******************************/
iSQLBufMgr::iSQLBufMgr( SInt a_bufSize )
{
    if ( ( m_Buf = (SChar*)idlOS::malloc(a_bufSize) ) == NULL )
    {
        idlOS::fprintf(stderr, 
                "Memory allocation error!!! --- (%d, %s)\n", 
                __LINE__, __FILE__);
        exit(0);
    }

    idlOS::memset(m_Buf, 0x00, a_bufSize);

    m_BufPtr     = m_Buf;

    m_MaxBuf     = a_bufSize;
}

iSQLBufMgr::~iSQLBufMgr()
{
    if ( m_Buf != NULL )
    {
        idlOS::free(m_Buf);
    }
}

IDE_RC    
iSQLBufMgr::Append( SChar * a_Str )
{
    SInt len;

    len = idlOS::strlen(a_Str);

    if ( (m_BufPtr - m_Buf) + len  > m_MaxBuf )
    {
        idlOS::sprintf(m_Spool.m_Buf, 
                "[Error] Query is too long, max query is %d.\n", 
                m_MaxBuf);
        m_Spool.Print();
        return IDE_FAILURE;
    }
    else 
    {
        idlOS::strcat(m_Buf, a_Str); 
        return IDE_SUCCESS;
    }
}

void    
iSQLBufMgr::Reset()           
{
    idlOS::memset(m_Buf, 0x00, m_MaxBuf);
    m_BufPtr = m_Buf;
}
