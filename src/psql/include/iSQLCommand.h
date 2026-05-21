/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iSQLCommand.h 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/

#ifndef _O_ISQLCOMMAND_H_
#define _O_ISQLCOMMAND_H_ 1

#include <sqlcli.h>
#include <iSQL.h>
#include <ulAmi.h>

class iSQLCommand
{
public:
    iSQLCommand();
    ~iSQLCommand();

    void reset();
    void setAll(iSQLCommand * a_SrcCommand, iSQLCommand * a_DesCommand);
    
    void              SetCommandKind(iSQLCommandKind a_CommandKind)         
                                      { m_CommandKind = a_CommandKind; }     
    iSQLCommandKind   GetCommandKind()                                      
                                      { return m_CommandKind; }
    void              SetHelpKind(iSQLCommandKind a_HelpKind)               
                                      { m_HelpKind = a_HelpKind; }         
    iSQLCommandKind   GetHelpKind()                                         
                                      { return m_HelpKind; }
    void              SetiSQLOptionKind(iSQLOptionKind a_iSQLOptionKind)    
                                      { m_iSQLOptionKind = a_iSQLOptionKind; } 
    iSQLOptionKind    GetiSQLOptionKind()                                   
                                      { return m_iSQLOptionKind; }
    
    IDE_RC            SetQuery(SChar * a_Query);    
    void              SetQueryStr( const SChar * a_Query );
    SChar           * GetQuery()                                    
                                      { return m_Query; }
    void              SetCommandStr(SChar * a_CommandStr);   
    void              SetCommandStr(SChar * a_CommandStr1,
                                    SChar * a_CommandStr2);
    SChar           * GetCommandStr()                               
                                      { return m_CommandStr; }
    void              SetShellCommand(SChar * a_ShellCommand);   
    SChar           * GetShellCommand()                             
                                      { return m_ShellCommand; }
    void              SetChangeCommand(SChar * a_ChangeCommand);
    void              SetOtherCommand(SChar * a_OtherCommandStr);   
    
    void              SetOnOff(SChar * a_OnOff);                   
    idBool            GetOnOff()                                    
                                      { return m_OnOff; }

    void              SetFileName(SChar * a_FileName,
                                  iSQLPathType a_PathType = ISQL_PATH_CWD);            
    SChar           * GetFileName()                                 
                                      { return m_FileName; }
    iSQLPathType      GetPathType()                                 
                                      { return m_PathType; }
    void              SetUserName(SChar * a_UserName);           
    SChar           * GetUserName()                                 
                                      { return m_UserName; }  
    void              SetPasswd(SChar * a_Passwd);         
    SChar           * GetPasswd()                                   
                                      { return m_Passwd; } 
    void              SetTableName(SChar * a_TableName);     
    SChar           * GetTableName()                                
                                      { return m_TableName; }

    void              SetColsize(SChar * a_Colsize);      
    SInt              GetColsize()                                 
                                      { return m_Colsize; } 
    void              SetLinesize(SChar * a_Linesize);      
    SInt              GetLinesize()                                 
                                      { return m_Linesize; } 
    void              SetPagesize(SChar * a_Pagesize);    
    SInt              GetPagesize()                                 
                                      { return m_Pagesize; }  
    void              SetHistoryNo(SChar * a_HistoryNo);    
    SInt              GetHistoryNo()                                
                                      { return m_HistoryNo; }
    void              SetTimescale(iSQLTimeScale a_Timescale)       
                                      { m_Timescale = a_Timescale; }  
    iSQLTimeScale     GetTimescale()                                
                                      { return m_Timescale; }        

    void              SetChangeKind(iSQLChangeKind a_ChangeKind)    
                                      { m_ChangeKind = a_ChangeKind; }
    iSQLChangeKind    GetChangeKind()                               
                                      { return m_ChangeKind; }
    void              SetChangeNo(SChar * a_HistoryNo);    
    SInt              GetChangeNo()                                 
                                      { return m_ChangeNo; }
    void              SetOldStr(SChar * a_OldStr);         
    SChar           * GetOldStr()                                   
                                      { return m_OldStr; }
    void              SetNewStr(SChar * a_NewStr);        
    SChar           * GetNewStr()                                   
                                      { return m_NewStr; }

    void              SetProcName(SChar * a_ProcName);   
    SChar           * GetProcName()                                 
                                      { return m_ProcName; }
    void              SetHostVarName(SChar * a_HostVarName);   
    SChar           * GetHostVarName()                              
                                      { return m_HostVarName; }

    // for admin
    void              SetAdminOption(ADM_STAT_ID a_AdminOption)    
                                      { m_AdminOption = a_AdminOption; } 
    ADM_STAT_ID       GetAdminOption()                                   
                                      { return m_AdminOption; }
    void              SetOptionStr(SChar * a_OptionStr);   
    SChar           * GetOptionStr()                              
                                      { return m_OptionStr; }

    void              setSysdba(idBool aMode)
                                      { m_Sysdba = aMode; }
    idBool            IsSysdba()      { return m_Sysdba; }
    // for admin

private:
    iSQLCommandKind   m_CommandKind;              // kind of command
    iSQLCommandKind   m_HelpKind;                 // kind of help 
    iSQLOptionKind    m_iSQLOptionKind;           // kind of set, show 
    ADM_STAT_ID       m_AdminOption;              // admin option
    iSQLPathType      m_PathType;
    
    SChar           * m_Query;                    // query for SQLExecDirect()
    SChar           * m_CommandStr;               // add history
    SChar             m_ShellCommand[WORD_LEN];   // !shell_command
    
    idBool            m_OnOff;
    idBool            m_Sysdba;

    SChar             m_FileName[WORD_LEN]; 
    SChar             m_UserName[WORD_LEN]; 
    SChar             m_Passwd[WORD_LEN]; 
    SChar             m_TableName[WORD_LEN];
    
    SInt              m_Colsize; 
    SInt              m_Linesize; 
    SInt              m_Pagesize;
    SInt              m_HistoryNo;
    iSQLTimeScale     m_Timescale;

    // for change command
    SChar             m_OldStr[WORD_LEN];
    SChar             m_NewStr[WORD_LEN];
    SInt              m_ChangeNo;
    iSQLChangeKind    m_ChangeKind;         

    SChar             m_ProcName[WORD_LEN];
    SChar             m_HostVarName[WORD_LEN];

    // for dbadmin
    SChar             m_OptionStr[WORD_LEN];
};

#endif // _O_ISQLCOMMAND_H_
