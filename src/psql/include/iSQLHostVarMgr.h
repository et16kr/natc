/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iSQLHostVarMgr.h 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/

#ifndef _O_ISQLHOSTVARMGR_H_
#define _O_ISQLHOSTVARMGR_H_ 1

#include <utISPApi.h>
#include <iSQL.h>

class iSQLHostVarMgr; // host variable manger

enum iSQLInOutType
{
    iSQL_IN=1, iSQL_OUT=2, iSQL_IN_OUT=3
};

union hv_value
{
    SChar   * c_value;
    SFloat    f_value;
    SDouble   d_value;
};

typedef struct HostVarElement
{
    SChar           name[QP_MAX_NAME_LEN+1];
    iSQLVarType     type;
    SInt            precision;       // for show/print var   
    SChar           scale[WORD_LEN]; // for show/print var
    SInt            size;
    SChar         * c_value;
    SFloat          f_value;
    SDouble         d_value;
    idBool          assigned;        // init or null value ==> ID_FALSE
    SShort          order;           // binding sequence
    SShort          para_order;      // para order of procedure
} HostVarElement;

typedef struct HostVarNode
{
    HostVarElement   element;
    HostVarNode    * next;
    HostVarNode    * host_var_next;  // procedure 수행 시 호스트 변수들의 순서
} HostVarNode;

class iSQLHostVarMgr
{
public:
    iSQLHostVarMgr();
    ~iSQLHostVarMgr();
    
    IDE_RC add( SChar       * a_name,      
                iSQLVarType   a_type, 
                SInt          a_precision, 
                SChar       * a_ccale );
    IDE_RC setValue( SChar * a_name );
    IDE_RC setValue( SChar * a_name, SChar * a_value );
    IDE_RC lookup( SChar * a_name );    
    IDE_RC typeConvert( HostVarElement * a_host_var, SChar * r_type );
    IDE_RC isCorrectType( iSQLVarType a_type );
    IDE_RC showVar( SChar * a_name );
    void   print();

    HostVarElement * getHostVar( SChar * a_name );

    void             initBindList();
    IDE_RC           putBindList( SChar * a_name, 
                                  SInt    a_order, 
                                  SShort  a_para_order );
    HostVarNode    * getBindList()              { return m_Head; }         
    SInt             getBindListCnt()           { return m_BindListCnt; }
    void             setHostVar( HostVarNode * a_host_var_list );  

protected:
    UInt          hashing( SChar * a_name );
    HostVarNode * getVar( SChar * a_name );
    HostVarNode * getVar( UInt key, SChar * a_name );

private:
    /* ============================================
     * m_BindList    : for manage host variable with execute procedure/function 
     *                 append to last node, get from first node
     * m_Head        : first node of m_BindList
     * m_Tail        : last node of m_BindList
     * m_BindListCnt : count of node of m_BindList
     * ============================================ */
    HostVarNode * m_SymbolTable[MAX_TABLE_ELEMENTS];
    HostVarNode * m_BindList;  
                              
    HostVarNode * m_Head;    
    HostVarNode * m_Tail;   
    SInt          m_BindListCnt; 
};

#endif // _O_ISQLHOSTVARMGR_H_ 
