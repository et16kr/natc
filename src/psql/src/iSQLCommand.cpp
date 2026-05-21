/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iSQLCommand.cpp 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/

#include <ideErrorMgr.h>
#include <utString.h>
#include <iSQLProperty.h>
#include <iSQLCommandQueue.h>
#include <iSQLCommand.h>

extern iSQLProperty gProperty;
extern iSQLCommandQueue *gCommandQueue;
extern utString gString;

iSQLCommand::iSQLCommand()
{
    if ( (m_Query = (SChar*)idlOS::malloc(gProperty.GetCommandLen())) == NULL )
    {
        idlOS::fprintf(stderr, "Memory allocation error!!! --- (%d, %s)\n", __LINE__, __FILE__);
        exit(0);    
    }
    idlOS::memset(m_Query, 0x00, gProperty.GetCommandLen());

    if ( (m_CommandStr = (SChar*)idlOS::malloc(gProperty.GetCommandLen())) == NULL )
    {
        idlOS::fprintf(stderr, "Memory allocation error!!! --- (%d, %s)\n", __LINE__, __FILE__);
        exit(0);    
    }
    idlOS::memset(m_CommandStr, 0x00, gProperty.GetCommandLen());

    reset();
}

iSQLCommand::~iSQLCommand()
{
    if ( m_Query != NULL )
    {
        idlOS::free(m_Query);
        m_Query = NULL;
    }

    if ( m_CommandStr != NULL )
    {
        idlOS::free(m_CommandStr);
        m_CommandStr = NULL;
    }
}

void 
iSQLCommand::reset()
{
    m_CommandKind     = NON_COM;
    m_HelpKind        = NON_COM;
    m_iSQLOptionKind  = iSQL_NON;
    m_ChangeKind      = NON_COMMAND;

    memset(m_Query, 0x00, sizeof(m_Query));
    memset(m_CommandStr, 0x00, sizeof(m_CommandStr));
    memset(m_ShellCommand, 0x00, sizeof(m_ShellCommand));
    memset(m_FileName, 0x00, sizeof(m_FileName));
    memset(m_UserName, 0x00, sizeof(m_UserName));
    memset(m_Passwd, 0x00, sizeof(m_Passwd));
    memset(m_TableName, 0x00, sizeof(m_TableName));
    memset(m_ProcName, 0x00, sizeof(m_ProcName));
    memset(m_HostVarName, 0x00, sizeof(m_HostVarName));
    memset(m_OldStr, 0x00, sizeof(m_OldStr));
    memset(m_NewStr, 0x00, sizeof(m_NewStr));

    m_Timescale   = iSQL_SEC;
    m_OnOff       = ID_FALSE;
    m_Colsize     = 0;
    m_Linesize    = 80;
    m_Pagesize    = 0;
    m_HistoryNo   = 0;
    m_ChangeNo    = 0; 
}

void 
iSQLCommand::setAll( iSQLCommand * a_SrcCommand, 
                     iSQLCommand * a_DesCommand )
{
    a_DesCommand->m_CommandKind    = a_SrcCommand->m_CommandKind;                
    a_DesCommand->m_HelpKind       = a_SrcCommand->m_HelpKind;                   
    a_DesCommand->m_iSQLOptionKind = a_SrcCommand->m_iSQLOptionKind;             
   
    strcpy(a_DesCommand->m_Query, a_SrcCommand->m_Query);       
    strcpy(a_DesCommand->m_CommandStr, a_SrcCommand->m_CommandStr);  
    strcpy(a_DesCommand->m_ShellCommand, a_SrcCommand->m_ShellCommand);     
   
    a_DesCommand->m_OnOff = a_SrcCommand->m_OnOff;
   
    strcpy(a_DesCommand->m_FileName, a_SrcCommand->m_FileName);
    strcpy(a_DesCommand->m_UserName, a_SrcCommand->m_UserName);
    strcpy(a_DesCommand->m_Passwd, a_SrcCommand->m_Passwd);
    strcpy(a_DesCommand->m_TableName, a_SrcCommand->m_TableName);
   
    a_DesCommand->m_Linesize  = a_SrcCommand->m_Linesize;
    a_DesCommand->m_Pagesize  = a_SrcCommand->m_Pagesize;
    a_DesCommand->m_HistoryNo = a_SrcCommand->m_HistoryNo;
    a_DesCommand->m_Timescale = a_SrcCommand->m_Timescale;
   
    strcpy(a_DesCommand->m_OldStr, a_SrcCommand->m_OldStr);
    strcpy(a_DesCommand->m_NewStr, a_SrcCommand->m_NewStr);
    a_DesCommand->m_ChangeNo   = a_SrcCommand->m_ChangeNo;
    a_DesCommand->m_ChangeKind = a_SrcCommand->m_ChangeKind;
   
    strcpy(a_DesCommand->m_ProcName, a_SrcCommand->m_ProcName);
    strcpy(a_DesCommand->m_HostVarName, a_SrcCommand->m_HostVarName);
}

IDE_RC 
iSQLCommand::SetQuery( SChar * a_Query )
{
    SChar * tmp;

    IDE_TEST(a_Query == NULL);

    tmp = idlOS::strrchr(a_Query, ';');

    IDE_TEST(tmp == NULL);

    *tmp = '\0';
    idlOS::strcpy(m_Query, a_Query);

    return IDE_SUCCESS;

    IDE_EXCEPTION_END;

    m_Query[0] = '\0';

    return IDE_FAILURE;
}

void 
iSQLCommand::SetQueryStr( const SChar * a_Query )
{
    idlOS::strcpy(m_Query, a_Query);
}
void 
iSQLCommand::SetCommandStr( SChar * a_CommandStr )
{
    if (a_CommandStr != NULL)
    {
        idlOS::strcpy(m_CommandStr, a_CommandStr);
    }
    else 
    {
        m_CommandStr[0] = '\0';
    }
}

void 
iSQLCommand::SetCommandStr( SChar * a_CommandStr1,
                            SChar * a_CommandStr2 )
{
    if (a_CommandStr1 != NULL)
    {
        idlOS::strcpy(m_CommandStr, a_CommandStr1);
    }
    else 
    {
        m_CommandStr[0] = '\0';
    }
    if (a_CommandStr2 != NULL)
    {
        idlOS::strcat(m_CommandStr, " ");
        idlOS::strcat(m_CommandStr, a_CommandStr2);
    }
}

void 
iSQLCommand::SetOtherCommand( SChar * a_OtherCommandStr )
{    
    SInt i;
    SInt nLen;

    nLen = idlOS::strlen(a_OtherCommandStr);
    
    for (i=0; i<nLen; i++)
    {
        if (a_OtherCommandStr[i] == ';')
        {
            m_CommandStr[i] = '\0';
            SetQuery(m_CommandStr);
            m_CommandStr[i] = a_OtherCommandStr[i];
            m_CommandStr[i+1] = '\0';
            m_CommandKind = OTHER_COM;
            return;
        }
        m_CommandStr[i] = a_OtherCommandStr[i];
    }

    m_CommandKind = NON_COM;
}

void 
iSQLCommand::SetOnOff( SChar * a_OnOff )
{
    if (a_OnOff != NULL)
    {
        if ( idlOS::strcasecmp(a_OnOff, "on") == 0 )
        {    
            m_OnOff = ID_TRUE;
        }
        else
        {
            m_OnOff = ID_FALSE;
        }
    }
}

void 
iSQLCommand::SetFileName( SChar        * a_FileName,
                          iSQLPathType   a_PathType )
{
    if (a_FileName != NULL)
    {
        gString.eraseWhiteSpace(a_FileName);
        idlOS::strcpy(m_FileName, a_FileName);
    }
    else 
    {
        m_FileName[0] = '\0';
    }
    m_PathType = a_PathType;
}

void 
iSQLCommand::SetUserName( SChar * a_UserName )
{
    if (a_UserName != NULL)
    {
        gString.eraseWhiteSpace(a_UserName);
        gString.toUpper(a_UserName);
        idlOS::strcpy(m_UserName, a_UserName);
    }
    else
    {
        m_UserName[0] = '\0';
    }
}

void 
iSQLCommand::SetPasswd( SChar * a_Passwd )
{
    if (a_Passwd != NULL)
    {
        gString.eraseWhiteSpace(a_Passwd);
        gString.toUpper(a_Passwd);
        idlOS::strcpy(m_Passwd, a_Passwd);
    }
    else
    {
        m_Passwd[0] = '\0';
    }
}

void 
iSQLCommand::SetTableName( SChar * a_TableName )
{
    if (a_TableName != NULL)
    {
        gString.eraseWhiteSpace(a_TableName);
        gString.toUpper(a_TableName);
        idlOS::strcpy(m_TableName, a_TableName);
    }
    else 
    {
        m_TableName[0] = '\0';
    }
}

void 
iSQLCommand::SetChangeCommand( SChar * a_ChangeCommand ) 
{
    SChar  tmp[WORD_LEN];
    SChar *pos1 = '\0';
    SChar *pos2 = '\0';

    idlOS::strcpy(tmp, a_ChangeCommand);
    pos1 = idlOS::strchr(tmp, '/');
    if (pos1 != NULL)
    {
        *pos1 = '\0';
        SetChangeNo(tmp);
        pos2 = idlOS::strchr(pos1+1, '/');
    }

    if (pos2 != NULL)
    {
        *pos2 = '\0';
        SetNewStr(pos2+1);
        SetOldStr(pos1+1);
    }
    else
    {
        SetNewStr(pos2);
        SetOldStr(pos1+1);
    }
}

void 
iSQLCommand::SetOldStr( SChar * a_OldStr )
{
    if (a_OldStr != NULL)
    {
        if ( idlOS::strcasecmp(a_OldStr, "^") == 0 )
        {
            SetChangeKind(FIRST_ADD_COMMAND);
        }
        else if ( idlOS::strcasecmp(a_OldStr, "$") == 0 )
        {
            SetChangeKind(LAST_ADD_COMMAND);
        }
        else
        {
            idlOS::strcpy(m_OldStr, a_OldStr);
        }
    }
    else 
    {
        m_OldStr[0] = '\0';
    }
}

void 
iSQLCommand::SetNewStr( SChar * a_NewStr )
{
    SChar *pos;

    if (a_NewStr != NULL)
    {
        pos = idlOS::strrchr(a_NewStr, '\n');
        if (pos)
        {
            *pos = '\0';
        }
        idlOS::strcpy(m_NewStr, a_NewStr);
        SetChangeKind(CHANGE_COMMAND);
    }
    else 
    {
        SetChangeKind(DELETE_COMMAND);
        m_NewStr[0] = '\0';
    }
}

void 
iSQLCommand::SetChangeNo( SChar * a_ChangeNo )   
{
    if (a_ChangeNo != NULL)
    {
        if ( idlOS::strcasecmp(a_ChangeNo, "C") == 0 )
        {
            m_ChangeNo = gCommandQueue->GetCurHisNum()-1;
        }
        else
        {
            m_ChangeNo = atoi(a_ChangeNo);
        }
    }
}

void 
iSQLCommand::SetShellCommand( SChar * a_ShellCommand )
{
    if (a_ShellCommand != NULL)
    {
        idlOS::strcpy(m_ShellCommand, a_ShellCommand);
    }
    else
    {
        m_ShellCommand[0] = '\0';
    }
}

void 
iSQLCommand::SetColsize( SChar * a_Colsize ) 
{
    if (a_Colsize != NULL)
    {
        m_Colsize = atoi(a_Colsize);
    }
}

void 
iSQLCommand::SetLinesize( SChar * a_Linesize ) 
{
    if (a_Linesize != NULL)
    {
        m_Linesize = atoi(a_Linesize);
    }
}

void 
iSQLCommand::SetPagesize( SChar * a_Pagesize )
{
    if (a_Pagesize != NULL)
    {
        m_Pagesize = atoi(a_Pagesize);
    }
}

void 
iSQLCommand::SetHistoryNo( SChar * a_HistoryNo )   
{
    if (a_HistoryNo != NULL)
    {
        m_HistoryNo = atoi(a_HistoryNo);
    }
}

void 
iSQLCommand::SetProcName( SChar * a_ProcName )
{
    if (a_ProcName != NULL)
    {
        gString.eraseWhiteSpace(a_ProcName);
        gString.toUpper(a_ProcName);
        idlOS::strcpy(m_ProcName, a_ProcName);
    }
    else 
    {
        m_ProcName[0] = '\0';
    }
}

void 
iSQLCommand::SetHostVarName( SChar * a_HostVarName )
{
    if (a_HostVarName != NULL)
    {
        gString.eraseWhiteSpace(a_HostVarName);
        gString.toUpper(a_HostVarName);
        idlOS::strcpy(m_HostVarName, a_HostVarName);
    }
    else 
    {
        m_HostVarName[0] = '\0';
    }
}

void 
iSQLCommand::SetOptionStr( SChar * a_OptionStr )
{
    idlOS::strcpy(m_OptionStr, a_OptionStr);
}
