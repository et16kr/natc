/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iSQLExecuteCommand.h 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/

#ifndef _O_ISQLEXECUTECOMMAND_H_
#define _O_ISQLEXECUTECOMMAND_H_ 1

#include <uttTime.h>
#include <utISPApi.h>
#include <iSQL.h>
#include <iSQLSpool.h>

class iSQLExecuteCommand
{
public:
    iSQLExecuteCommand( SInt a_bufSize );
    ~iSQLExecuteCommand();

    IDE_RC ConnectDB( SChar * a_Host, 
                      SChar * a_UserID, 
                      SChar * a_Passwd, 
                      SChar * a_NLS,  
                      SInt    a_Port,   
                      SInt    a_Conntype );
    void   DisconnectDB();

    IDE_RC DisplayTableList( SChar * a_CommandStr );
    IDE_RC DisplayFixedTableList( SChar * a_CommandStr,
                                  SChar * a_PrefixName,
                                  SChar * a_TableType );
    IDE_RC DisplaySequenceList( SChar * a_CommandStr );
    IDE_RC DisplayAttributeList( SChar * a_CommandStr, 
                                 SChar * a_UserName, 
                                 SChar * a_TableName );
    IDE_RC DisplayAttributeList4FTnPV( SChar * a_CommandStr, 
                                       SChar * a_UserName, 
                                       SChar * a_TableName );
    
    IDE_RC BindParam(SInt **aLen);
    IDE_RC ExecuteDDLStmt( SChar           * a_CommandStr, 
                           SChar           * a_DDLStmt, 
                           iSQLCommandKind   a_CommandKind ); 
    IDE_RC PrepareDMLStmt( SChar           * a_CommandStr, 
                           SChar           * a_DMLStmt, 
                           iSQLCommandKind   a_CommandKind );
    IDE_RC ExecuteDMLStmt( SChar           * a_CommandStr, 
                           SChar           * a_DMLStmt, 
                           iSQLCommandKind   a_CommandKind );
    IDE_RC ExecutePSMStmt( SChar * a_CommandStr, 
                           SChar * a_PSMStmt, 
                           SChar * a_UserName, 
                           SChar * a_ProcName, 
                           idBool  a_IsFunc );
    IDE_RC ExecuteOtherCommandStmt( SChar * a_CommandStr, 
                                    SChar * a_OtherCommandStmt );    
    IDE_RC ExecuteSysdbaCommandStmt( SChar * a_CommandStr, 
                                     SChar * a_SysdbaCommandStmt );    

    IDE_RC ExecuteConnectStmt( SChar * a_CommandStr, 
                               SChar * a_Host, 
                               SChar * a_UserName, 
                               SChar * a_Passwd, 
                               SChar * a_NLS, 
                               SInt    a_Port, 
                               SInt    a_Conntype );
    void   ExecuteDisconnectStmt( SChar * a_CommandStr,
                                  idBool  aDisplayMode ); 
    IDE_RC ExecuteAutoCommitStmt( SChar * a_CommandStr, 
                                  idBool  a_IsAutoCommitOn );
    IDE_RC ExecuteEndTranStmt( SChar * a_CommandStr, 
                               idBool  a_IsCommit );

    void   ExecuteSpoolStmt( SChar        * a_FileName,
                             iSQLPathType   a_PathType );
    void   ExecuteSpoolOffStmt();

    void   ExecuteShellStmt( SChar * a_ShellStmt );
    void   ExecuteEditStmt( SChar        * a_InFileName, 
                            iSQLPathType   a_PathType,
                            SChar        * a_OutFileName );
    IDE_RC PrintHelpString( SChar           * a_CommandStr, 
                            iSQLCommandKind   eHelpArguKind );

    void   ShowElapsedTime();

    void   ShowHostVar( SChar * a_CommandSt );
    void   ShowHostVar( SChar * a_CommandStr, 
                        SChar * a_HostVarName );

    void   PrintHeader( SInt * ColSize, 
                        SInt * pg, 
                        SInt * space );
    IDE_RC PrepareSelectStmt( SChar * a_CommandStr, 
                              SChar * szSelectStmt );
    idBool ExecuteSelectStmt( SChar * a_CommandStr, 
                              SChar * szSelectStmt );
    IDE_RC FetchSelectStmt(idBool aPrepare);

    IDE_RC ShowColumns( SChar * a_UserName, 
                        SChar * a_TableName );
    IDE_RC ShowColumns4FTnPV( SChar * a_UserName, 
                              SChar * a_TableName );
    IDE_RC ShowIndexInfo( SChar * a_UserName, 
                          SChar * a_TableName );
    IDE_RC ShowPrimaryKeys( SChar * a_UserName, 
                            SChar * a_TableName );
    IDE_RC ShowForeignKeys( SChar * a_UserName, 
                            SChar * a_TableName );

    // for admin
    IDE_RC Startup(SChar * a_CommandStr,
                   SInt    aMode);
    IDE_RC Shutdown(SChar * a_CommandStr,
                    SInt    aMode);
    IDE_RC Status(SChar * a_CommandStr, SInt aStatID, SChar *aArg);
    IDE_RC Terminate(SChar * a_CommandStr,  SChar *aNumber);

private:
    uttTime      m_uttTime;
    utISPApi   * m_ISPApi;
    iSQLSpool    m_Spool;
    SDouble      m_ElapsedTime;
};

#endif // _O_ISQLEXECUTECOMMAND_H_

