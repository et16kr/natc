/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iSQLCommandQueue.h 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/

#ifndef _O_ISQLCOMMANDQUEUE_H_ 
#define _O_ISQLCOMMANDQUEUE_H_ 1

#include <iSQLCommand.h>
#include <iSQLSpool.h>

class iSQLCommandQueue
{
public:
    iSQLCommandQueue();
    ~iSQLCommandQueue();

    void   DisplayHistory();
    void   AddCommand(iSQLCommand * a_Command);
    IDE_RC GetCommand(SInt a_HisNum, iSQLCommand * a_Command);
    SInt   GetCurHisNum()   { return m_CurHisNum; }
    IDE_RC ChangeCommand(SInt    a_HisNum, SChar * a_OldStr, 
                         SChar * a_NewStr, SChar * a_ChangeCommand);

private:
    IDE_RC CheckHisNum(SInt a_HisNum);

private:
    iSQLSpool     m_Spool;
    iSQLCommand   m_Queue[COM_QUEUE_SIZE];
    SInt          m_CurHisNum;
    SInt          m_MaxHisNum;
    SChar       * m_tmpBuf;
    SChar       * m_tmpBuf2;
};

#endif // _O_ISQLCOMMANDQUEUE_H_
