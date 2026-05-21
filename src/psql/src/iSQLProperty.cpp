/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iSQLProperty.cpp 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/

#include <idl.h>
#include <utString.h>
#include <utISPApi.h>
#include <iSQLSpool.h>
#include <iSQLProperty.h>

extern utString    gString;
extern iSQLSpool * gSpool;

iSQLProperty::iSQLProperty()
{ 
    m_ColSize   = 0;
    m_LineSize  = 80;
    m_PageSize  = 0;
    m_Term      = ID_TRUE;
    m_Timing    = ID_FALSE;
    m_Heading   = ID_TRUE;
    m_Verbose   = ID_TRUE;
    m_TimeScale = iSQL_SEC;
    m_IsDisplayComment = ID_FALSE;
    m_ShowForeignKeys = ID_FALSE;
    m_PlanCommit = ID_FALSE;
    m_QueryLogging = ID_FALSE;
    idlOS::memset(m_UserName, 0x00, sizeof(m_UserName));

    SetEnv();
}

iSQLProperty::~iSQLProperty()
{ 
}

/* ============================================
 * iSQL 관련 환경변수를 읽어서 세팅
 * ============================================ */
void
iSQLProperty::SetEnv()
{
    /* ============================================
     * ISQL_BUFFER_SIZE, default : 64K 
     * ============================================ */
    if (idlOS::getenv("ISQL_BUFFER_SIZE"))              
    {       
        m_CommandLen = atoi(idlOS::getenv("ISQL_BUFFER_SIZE"));
    }       
    else
    {           
        m_CommandLen = COMMAND_LEN;
    }
            
    /* ============================================
     * ISQL_EDITOR, default : /usr/bin/vi 
     * ============================================ */
    if (idlOS::getenv("ISQL_EDITOR"))
    {
        idlOS::strcpy(m_Editor, idlOS::getenv("ISQL_EDITOR"));
    }   
    else    
    {       
        idlOS::strcpy(m_Editor, ISQL_EDITOR);
    }

    /* ============================================
     * ISQL_CONNECTION, default : TCP 
     * ============================================ */
    if (idlOS::getenv("ISQL_CONNECTION"))
    {
        idlOS::strcpy(m_Conntype, idlOS::getenv("ISQL_CONNECTION"));
    }   
    else    
    {       
        idlOS::strcpy(m_Conntype, "TCP");
    }
}

/* ============================================
 * Set ColSize 
 * Display되는 한 컬럼(char,varchar 타입만 적용)의 길이.
 * ============================================ */
void 
iSQLProperty::SetColSize( SChar * a_CommandStr, 
                          SInt    a_ColSize )
{
    idlOS::sprintf(gSpool->m_Buf, "%s", a_CommandStr);  
    gSpool->PrintCommand();

    if ( (a_ColSize < 0) || (a_ColSize > 32767) )
    {
        idlOS::sprintf(gSpool->m_Buf, "%s", 
                (SChar*)"ColSize option value out of range(0 - 32767).\n");
        gSpool->Print();
    }
    else
    {
        m_ColSize = a_ColSize;
    }
}

/* ============================================
 * Set LineSize 
 * Display되는 한 라인의 길이.
 * ============================================ */
void 
iSQLProperty::SetLineSize( SChar * a_CommandStr, 
                           SInt    a_LineSize )
{
    idlOS::sprintf(gSpool->m_Buf, "%s", a_CommandStr);  
    gSpool->PrintCommand();

    if ( (a_LineSize < 10) || (a_LineSize > 32767) )
    {
        idlOS::sprintf(gSpool->m_Buf, "%s", 
                (SChar*)"LineSize option value out of range(10 - 32767).\n");
        gSpool->Print();
    }
    else
    {
        m_LineSize = a_LineSize;
    }
}

/* ============================================
 * Set PageSize 
 * 레코드를 몇 개 단위로 보여줄 것인가.
 * ============================================ */
void 
iSQLProperty::SetPageSize( SChar * a_CommandStr, 
                           SInt    a_PageSize )
{
    idlOS::sprintf(gSpool->m_Buf, "%s", a_CommandStr);  
    gSpool->PrintCommand();

    if ( a_PageSize < 0 || a_PageSize > 50000 )
    {
        idlOS::sprintf(gSpool->m_Buf, "%s", 
                (SChar*)"PageSize option value out of range(0 - 50000).\n");
        gSpool->Print();
    }
    else
    {
        m_PageSize = a_PageSize;
    }
}

/* ============================================
 * Set Term 
 * 콘솔 화면으로의 출력을 할 것인가 말 것인가.
 * ============================================ */
void 
iSQLProperty::SetTerm( SChar * a_CommandStr, 
                       idBool  a_IsTerm )
{
    idlOS::sprintf(gSpool->m_Buf, "%s", a_CommandStr);  
    gSpool->PrintCommand();

    m_Term = a_IsTerm;
}

/* ============================================
 * Set Timing 
 * 쿼리 수행 시간을 보여줄 것인가 말 것인가.
 * ============================================ */
void 
iSQLProperty::SetTiming( SChar * a_CommandStr, 
                         idBool  a_IsTiming )
{
    idlOS::sprintf(gSpool->m_Buf, "%s", a_CommandStr);  
    gSpool->PrintCommand();

    m_Timing = a_IsTiming;
}

/* ============================================
 * Set Heading 
 * 헤더(Column Name)를 보여줄 것인가 말 것인가.
 * ============================================ */
void 
iSQLProperty::SetHeading( SChar * a_CommandStr, 
                          idBool  a_IsHeading )
{
    idlOS::sprintf(gSpool->m_Buf, "%s", a_CommandStr);  
    gSpool->PrintCommand();

    m_Heading = a_IsHeading;
}

/* ============================================
 * Set TimeScale 
 * 쿼리 수행 시간의 단위  
 * ============================================ */
void 
iSQLProperty::SetTimeScale( SChar         * a_CommandStr, 
                            iSQLTimeScale   a_Timescale )
{
    idlOS::sprintf(gSpool->m_Buf, "%s", a_CommandStr);  
    gSpool->PrintCommand();

    m_TimeScale = a_Timescale;
}

/* ============================================
 * Set Verbose 
 * 결과 파일에 명령어를 출력할 것인가 말 것인가.
 * ============================================ */
void 
iSQLProperty::SetVerbose( SChar * a_CommandStr, 
                          idBool  a_IsVerbose )
{
    idlOS::sprintf(gSpool->m_Buf, "%s", a_CommandStr);  
    gSpool->PrintCommand();

    m_Verbose = a_IsVerbose;
}

/* ============================================
 * Set Comment 
 * 결과 파일에 주석을 출력할 것인가 말 것인가.
 * ============================================ */
void 
iSQLProperty::SetComment( SChar * a_CommandStr, 
                          idBool  a_IsDisplayComment )
{
    idlOS::sprintf(gSpool->m_Buf, "%s", a_CommandStr);  
    gSpool->PrintCommand();

    m_IsDisplayComment = a_IsDisplayComment;
}

/* ============================================
 * Set User 
 * Connect할 때마다 현재의 유저를 세팅한다.
 * ============================================ */
void 
iSQLProperty::SetUserName( SChar * a_UserName )
{ 
    gString.toUpper(a_UserName);
    idlOS::strcpy(m_UserName, a_UserName);
}

/* ============================================
 * Set ForeignKeys 
 * desc 결과에 foreign key 정보를 보여줄 것인지 
 * ============================================ */
void 
iSQLProperty::SetForeignKeys( SChar * a_CommandStr, 
                              idBool  a_ShowForeignKeys )
{
    idlOS::sprintf(gSpool->m_Buf, "%s", a_CommandStr);  
    gSpool->PrintCommand();

    m_ShowForeignKeys = a_ShowForeignKeys;
}

/* ============================================
 * Set PlanCommit
 * autocommit mode false 인 세션에서 explain plan 을
 * on 또는 only 로 했을 때, desc, select * From tab;
 * 간틍 명령어를 사용하게 되면, 이전에 수행중인
 * 트랜잭션이 존재할 경우에 에러가 발생하게 된다.
 * error -> The transaction is already active.
 * 이를 방지하기 위해서 수행전에 commit 을 자동으로
 * 수행하도록 하는 옵션을 줄 수 있다.
 * ============================================ */
void 
iSQLProperty::SetPlanCommit( SChar * a_CommandStr, 
                             idBool  a_Commit )
{
    idlOS::sprintf(gSpool->m_Buf, "%s", a_CommandStr);  
    gSpool->PrintCommand();

    m_PlanCommit = a_Commit;
}

void 
iSQLProperty::SetQueryLogging( SChar * a_CommandStr, 
                               idBool  a_Logging ) 
{ 
    idlOS::sprintf(gSpool->m_Buf, "%s", a_CommandStr); 
    gSpool->PrintCommand(); 

    m_QueryLogging = a_Logging; 
} 

/* ============================================
 * 현재의 iSQL Option을 보여준다. 
 * ============================================ */
void 
iSQLProperty::ShowStmt( SChar          * a_CommandStr, 
                        iSQLOptionKind   a_iSQLOptionKind )
{
    SChar tmp[20];

    idlOS::sprintf(gSpool->m_Buf, "%s", a_CommandStr);  
    gSpool->PrintCommand();

    switch(a_iSQLOptionKind)
    {
    case iSQL_SHOW_ALL :
        idlOS::sprintf(gSpool->m_Buf, "User      : %s\n", m_UserName);
        gSpool->Print();
        idlOS::sprintf(gSpool->m_Buf, "ColSize   : %d\n", m_ColSize);
        gSpool->Print();
        idlOS::sprintf(gSpool->m_Buf, "LineSize  : %d\n", m_LineSize);
        gSpool->Print();
        idlOS::sprintf(gSpool->m_Buf, "PageSize  : %d\n", m_PageSize);
        gSpool->Print();
/*        
        if (m_IsDisplayComment == ID_TRUE)
            idlOS::sprintf(gSpool->m_Buf, "%s", (SChar*)"Comment   : display\n");
        else
            idlOS::sprintf(gSpool->m_Buf, "%s", (SChar*)"Comment   : not display\n");
        gSpool->Print();
*/
        if (m_TimeScale == iSQL_SEC)
            idlOS::strcpy(tmp, "Second");
        else if (m_TimeScale == iSQL_MILSEC)
            idlOS::strcpy(tmp, "MilliSecond");
        else if (m_TimeScale == iSQL_MICSEC)
            idlOS::strcpy(tmp, "MicroSecond");
        else if (m_TimeScale == iSQL_NANSEC)
            idlOS::strcpy(tmp, "NanoSecond");
        idlOS::sprintf(gSpool->m_Buf, "TimeScale : %s\n", tmp);
        gSpool->Print();

        if (m_Heading == ID_TRUE)
            idlOS::sprintf(gSpool->m_Buf, "%s", (SChar*)"Heading   : On\n");
        else
            idlOS::sprintf(gSpool->m_Buf, "%s", (SChar*)"Heading   : Off\n");
        gSpool->Print();

        if (m_Timing == ID_TRUE)
            idlOS::sprintf(gSpool->m_Buf, "%s", (SChar*)"Timing    : On\n");
        else
            idlOS::sprintf(gSpool->m_Buf, "%s", (SChar*)"Timing    : Off\n");
        gSpool->Print();
        
        if (m_Verbose == ID_TRUE)
            idlOS::sprintf(gSpool->m_Buf, "%s", (SChar*)"Verbose   : On\n");
        else
            idlOS::sprintf(gSpool->m_Buf, "%s", (SChar*)"Verbose   : Off\n");
        gSpool->Print();

        if (m_ShowForeignKeys == ID_TRUE)
        {
            idlOS::sprintf(gSpool->m_Buf, "%s",
                           (SChar*)"ForeignKeys : On\n");
        }
        else
        {
            idlOS::sprintf(gSpool->m_Buf, "%s",
                           (SChar*)"ForeignKeys : Off\n");
        }
        gSpool->Print();

        if (m_PlanCommit == ID_TRUE)
        {
            idlOS::sprintf(gSpool->m_Buf, "%s",
                           (SChar*)"PlanCommit : On\n");
        }
        else
        {
            idlOS::sprintf(gSpool->m_Buf, "%s",
                           (SChar*)"PlanCommit : Off\n");
        }
        gSpool->Print();

        if (m_QueryLogging == ID_TRUE) 
        { 
            idlOS::sprintf(gSpool->m_Buf, "%s", 
                           (SChar*)"QueryLogging : On\n"); 
        } 
        else 
        { 
            idlOS::sprintf(gSpool->m_Buf, "%s", 
                           (SChar*)"QueryLogging : Off\n"); 
        } 
        gSpool->Print(); 

        break;
    case iSQL_HEADING :
        if (m_Heading == ID_TRUE)
            idlOS::sprintf(gSpool->m_Buf, "%s", (SChar*)"Heading : On\n");
        else
            idlOS::sprintf(gSpool->m_Buf, "%s", (SChar*)"Heading : Off\n");
        gSpool->Print();
        break;
    case iSQL_COLSIZE :
        idlOS::sprintf(gSpool->m_Buf, "ColSize  : %d\n", m_ColSize);
        gSpool->Print();
        break;
    case iSQL_LINESIZE :
        idlOS::sprintf(gSpool->m_Buf, "LineSize : %d\n", m_LineSize);
        gSpool->Print();
        break;
    case iSQL_PAGESIZE :
        idlOS::sprintf(gSpool->m_Buf, "PageSize : %d\n", m_PageSize);
        gSpool->Print();
        break;
    case iSQL_TERM :
        if (m_Term == ID_TRUE)
            idlOS::sprintf(gSpool->m_Buf, "%s", (SChar*)"Term : On\n");
        else
            idlOS::sprintf(gSpool->m_Buf, "%s", (SChar*)"Term : Off\n");
        gSpool->Print();
        break;
    case iSQL_TIMING :
        if (m_Timing == ID_TRUE)
            idlOS::sprintf(gSpool->m_Buf, "%s", (SChar*)"Timing : On\n");
        else
            idlOS::sprintf(gSpool->m_Buf, "%s", (SChar*)"Timing : Off\n");
        gSpool->Print();
        break;
    case iSQL_VERBOSE :
        if (m_Verbose == ID_TRUE)
            idlOS::sprintf(gSpool->m_Buf, "%s", (SChar*)"Verbose : On\n");
        else
            idlOS::sprintf(gSpool->m_Buf, "%s", (SChar*)"Verbose : Off\n");
        gSpool->Print();
        break;
    case iSQL_FOREIGNKEYS :
        if (m_ShowForeignKeys == ID_TRUE)
        {
            idlOS::sprintf(gSpool->m_Buf, "%s",
                           (SChar*)"ForeignKeys : On\n");
        }
        else
        {
            idlOS::sprintf(gSpool->m_Buf, "%s",
                           (SChar*)"ForeignKeys : Off\n");
        }
        gSpool->Print();
        break;
    case iSQL_PLANCOMMIT :
        if (m_PlanCommit == ID_TRUE)
        {
            idlOS::sprintf(gSpool->m_Buf, "%s",
                           (SChar*)"PlanCommit : On\n");
        }
        else
        {
            idlOS::sprintf(gSpool->m_Buf, "%s",
                           (SChar*)"PlanCommit : Off\n");
        }
        gSpool->Print();
        break;
    case iSQL_QUERYLOGGING :
        if (m_QueryLogging  == ID_TRUE)
        {
            idlOS::sprintf(gSpool->m_Buf, "%s",
                           (SChar*)"QueryLogging : On\n");
        }
        else
        {
            idlOS::sprintf(gSpool->m_Buf, "%s",
                           (SChar*)"QueryLogging : Off\n");
        }
        gSpool->Print();
        break;
    case iSQL_USER :
        idlOS::sprintf(gSpool->m_Buf, "User : %s\n", m_UserName);
        gSpool->Print();
        break;
    case iSQL_TIMESCALE :
        if (m_TimeScale == iSQL_SEC)
            idlOS::strcpy(tmp, "Second");
        else if (m_TimeScale == iSQL_MILSEC)
            idlOS::strcpy(tmp, "MilliSecond");
        else if (m_TimeScale == iSQL_MICSEC)
            idlOS::strcpy(tmp, "MicroSecond");
        else if (m_TimeScale == iSQL_NANSEC)
            idlOS::strcpy(tmp, "NanoSecond");
        idlOS::sprintf(gSpool->m_Buf, "TimeScale : %s\n", tmp);
        gSpool->Print();
        break;
    case iSQL_COMMENT :
        if (m_IsDisplayComment == ID_TRUE)
            idlOS::sprintf(gSpool->m_Buf, "%s", 
                    (SChar*)"Display comment\n");
        else
            idlOS::sprintf(gSpool->m_Buf, "%s", 
                    (SChar*)"Not display comment\n");
        gSpool->Print();
        break;
    default :
        idlOS::sprintf(gSpool->m_Buf, "%s", (SChar*)"Have no information.\n");
        gSpool->Print();
        break;
    }
}

