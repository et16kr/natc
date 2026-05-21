/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iSQLSpool.cpp 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/

#include <ida.h>
#include <ideErrorMgr.h>
#include <iSQLProperty.h>
#include <iSQLProgOption.h>
#include <iSQLSpool.h>
#include <iSQLCompiler.h>

extern iSQLProperty    gProperty;
extern iSQLProgOption  gProgOption;
extern iSQLCompiler   *gSQLCompiler;

iSQLSpool::iSQLSpool()
{
    idlOS::memset(m_SpoolFileName, 0x00, sizeof(m_SpoolFileName));
    m_bSpoolOn = ID_FALSE;
    m_fpSpool  = NULL;

    if ( (m_Buf = (SChar*)idlOS::malloc(gProperty.GetCommandLen())) == NULL )
    {
        idlOS::fprintf(stderr, "Memory allocation error!!! --- (%d, %s)\n",
                       __LINE__, __FILE__);
        exit(0);
    }
    idlOS::memset(m_Buf, 0x00, gProperty.GetCommandLen());
}

iSQLSpool::~iSQLSpool()
{
    if ( m_Buf != NULL )
    {
        idlOS::free(m_Buf);
        m_Buf = NULL;
    }
}

IDE_RC 
iSQLSpool::SetSpoolFile( SChar * a_FileName )
{
    IDE_TEST_RAISE(m_bSpoolOn == ID_TRUE, already_spool_on);

    m_fpSpool = isql_fopen(a_FileName, "r");
    IDE_TEST_RAISE(m_fpSpool != NULL, already_exist_file);

    m_fpSpool = isql_fopen(a_FileName, "wt");
    IDE_TEST_RAISE(m_fpSpool == NULL, fail_open_file); 

    m_bSpoolOn = ID_TRUE;
    idlOS::strcpy(m_SpoolFileName, a_FileName);
    idlOS::sprintf(m_Buf, (SChar*)"Spool start. [%s]\n", a_FileName);
    PrintOutFile();

    return IDE_SUCCESS;

    IDE_EXCEPTION(already_spool_on);
    {
        idlOS::sprintf(m_Buf, (SChar*)"Already spool on state. [%s]\n",
                       m_SpoolFileName);
        PrintOutFile();
    }
    IDE_EXCEPTION(already_exist_file); 
    {
        idlOS::fclose( m_fpSpool );
        idlOS::sprintf(m_Buf, "Already exist file. [%s]\n", a_FileName);
        PrintOutFile();
    }
    IDE_EXCEPTION(fail_open_file); 
    {
        idlOS::sprintf(m_Buf, "Can not open file. [%s]\n", a_FileName);
        PrintOutFile();
    }
    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

IDE_RC 
iSQLSpool::SpoolOff()
{
    IDE_TEST_RAISE(m_bSpoolOn == ID_FALSE, not_spool_on);

    IDE_TEST_RAISE(idlOS::fclose(m_fpSpool) != 0, fail_close_file);

    m_bSpoolOn         = ID_FALSE;
    m_fpSpool          = NULL;

    idlOS::sprintf(m_Buf, (SChar*)"Spool Stop\n");
    PrintOutFile();
    
    m_SpoolFileName[0] = '\0';

    return IDE_SUCCESS;

    IDE_EXCEPTION(not_spool_on);
    {
        idlOS::strcpy(m_Buf, (SChar*)"Is not spool on state.\n");
        PrintOutFile();
    }
    IDE_EXCEPTION(fail_close_file);
    {
        m_bSpoolOn         = ID_FALSE;
        m_fpSpool          = NULL;
        idlOS::sprintf(m_Buf, "Fail close file. [%s]", m_SpoolFileName);
        PrintOutFile();
    }
    IDE_EXCEPTION_END;

    return IDE_FAILURE;
}

void 
iSQLSpool::PrintPrompt()
{
#ifdef USE_READLINE
    if ( (gProgOption.IsATC() == ID_TRUE) || (gProgOption.IsInFile() == ID_TRUE))
    {
        idlOS::fprintf(gProgOption.m_OutFile, "iSQL> ");
        idlOS::fflush(gProgOption.m_OutFile);
    }
#else
    idlOS::fprintf(gProgOption.m_OutFile, "iSQL> ");
    idlOS::fflush(gProgOption.m_OutFile);
#endif

    if ( m_bSpoolOn == ID_TRUE && m_fpSpool != NULL )
    {
        idlOS::fprintf(m_fpSpool, "iSQL> ", m_Buf);
        idlOS::fflush(m_fpSpool);
    }
}

void 
iSQLSpool::Print()
{
    if (gProperty.GetTerm() == ID_TRUE ||
        gSQLCompiler->IsFileRead() == ID_FALSE )
    {
        idlOS::fprintf(gProgOption.m_OutFile, "%s", m_Buf);
        idlOS::fflush(gProgOption.m_OutFile);
    }

    if ( m_bSpoolOn == ID_TRUE && m_fpSpool != NULL )
    {
        idlOS::fprintf(m_fpSpool, "%s", m_Buf);
        idlOS::fflush(m_fpSpool);
    }
}

void 
iSQLSpool::PrintOutFile()
{
    idlOS::fprintf(gProgOption.m_OutFile, "%s", m_Buf);
    idlOS::fflush(gProgOption.m_OutFile);
}

void 
iSQLSpool::PrintCommand()
{
/*    if ( gProgOption.IsVerbose() == ID_TRUE )
    {
        idlOS::fprintf(gProgOption.m_OutFile, "%s\n", m_Buf);
        idlOS::fflush(gProgOption.m_OutFile);
    }
*/
    if ( m_bSpoolOn == ID_TRUE && m_fpSpool != NULL )
    {
        idlOS::fprintf(m_fpSpool, "iSQL> %s", m_Buf);
        idlOS::fflush(m_fpSpool);
    }
}

void 
iSQLSpool::PrintWithDouble(SInt *aPos)
{
/***********************************************************************
 *
 * Description :
 *    DOUBLE 값을 적절한 포멧으로 출력
 *
 * Implementation :
 *
 ***********************************************************************/

    SInt   sPos = 0;
    SChar  sTmp[32];

    // fix PR-12295
    // 0에 가까운 작은 값은 0으로 출력함.
    if( ( m_DoubleBuf < 1E-7 ) &&
        ( m_DoubleBuf > -1E-7 ) )
    {
        idlOS::sprintf(sTmp, "0");
    }
    else
    {
        idlOS::sprintf(sTmp, "%"ID_DOUBLE_G_FMT"", m_DoubleBuf);
    }
    
    sPos = *aPos;
    *aPos += idlOS::sprintf(m_Buf + sPos, "%-22s", sTmp);
    m_Buf[*aPos] = ' ';
}

void 
iSQLSpool::PrintWithFloat(SInt *aPos)
{
/***********************************************************************
 *
 * Description :
 *    REAL 값을 적절한 포멧으로 출력
 *
 * Implementation :
 *
 ***********************************************************************/

    SChar sTmp[16];
    SInt  sPos = 0;

    // fix PR-12295
    // 0에 가까운 작은 값은 0으로 출력함.
    if( ( m_FloatBuf < 1E-7 ) &&
        ( m_FloatBuf > -1E-7 ) )
    {
        idlOS::sprintf(sTmp, "0");
    }
    else
    {
        idlOS::sprintf(sTmp, "%"ID_FLOAT_G_FMT"", m_FloatBuf);
    }
    
    sPos = *aPos;
    *aPos += idlOS::sprintf(m_Buf + sPos, "%-13s", sTmp);
    m_Buf[*aPos] = ' ';
}
