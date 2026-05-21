/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iSQLProperty.h 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/

#ifndef _O_ISQLPROPERTY_H_
#define _O_ISQLPROPERTY_H_ 1

#include <iSQL.h>

class iSQLProperty
{
public:
    iSQLProperty();
    ~iSQLProperty();

    void           SetEnv();
    void           SetColSize(SChar *a_CommandStr, SInt a_ColSize);
    SInt           GetColSize()     { return m_ColSize; }
    void           SetLineSize(SChar *a_CommandStr, SInt a_LineSize);
    SInt           GetLineSize()    { return m_LineSize; }
    void           SetPageSize(SChar *a_CommandStr, SInt a_PageSize);
    SInt           GetPageSize()    { return m_PageSize; }
    void           SetTerm(SChar *a_CommandStr, idBool a_IsTerm);
    idBool         GetTerm()        { return m_Term; }
    void           SetTiming(SChar *a_CommandStr, idBool a_IsTiming);
    idBool         GetTiming()      { return m_Timing; }
    void           SetHeading(SChar *a_CommandStr, idBool a_IsHeading);
    idBool         GetHeading()     { return m_Heading; }
    void           SetTimeScale(SChar *a_CommandStr, iSQLTimeScale a_Timescale);
    iSQLTimeScale  GetTimeScale()   { return m_TimeScale; }
    void           SetVerbose(SChar *a_CommandStr, idBool a_IsVerbose);
    idBool         GetVerbose()     { return m_Verbose; }
    void           SetComment(SChar *a_CommandStr, idBool a_IsDisplayComment);
    idBool         GetComment()     { return m_IsDisplayComment; }
    void           SetUserName(SChar *a_UserName);
    SChar        * GetUserName()    { return m_UserName; }

    SChar        * GetEditor()      { return m_Editor; }
    SChar        * GetConntype()    { return m_Conntype; }
    SInt           GetCommandLen()  { return m_CommandLen; }
    
    void           ShowStmt(SChar          * a_CommandStr, 
                            iSQLOptionKind   a_iSQLOptionKind);

    void           SetForeignKeys( SChar *a_CommandStr,
                                   idBool a_ShowForeignKeys );
    idBool         GetForeignKeys() { return m_ShowForeignKeys; }
    void           SetPlanCommit( SChar * a_CommandStr,
                                  idBool  a_Commit );
    idBool         GetPlanCommit()  { return m_PlanCommit; }

    void           SetQueryLogging( SChar * a_CommandStr, 
                                    idBool  a_Loggin ); 
    idBool         GetQueryLogging(){ return m_QueryLogging; }

private:
    SInt            m_ColSize;
    SInt            m_LineSize;
    SInt            m_PageSize;
    idBool          m_Term;
    idBool          m_Timing;
    idBool          m_Heading;
    idBool          m_Verbose;
    idBool          m_IsDisplayComment;
    idBool          m_ShowForeignKeys;
    idBool          m_PlanCommit;
    idBool          m_QueryLogging;
    iSQLTimeScale   m_TimeScale;
    SChar           m_UserName[WORD_LEN];

    SChar           m_Editor[WORD_LEN];
    SChar           m_Conntype[WORD_LEN];
    SInt            m_CommandLen;
};

#endif // _O_ISQLPROPERTY_H_

