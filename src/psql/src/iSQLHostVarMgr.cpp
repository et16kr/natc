/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iSQLHostVarMgr.cpp 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/

#include <ideErrorMgr.h>
#include <ulCli.h>
#include <utString.h>
#include <iSQLSpool.h>
#include <iSQLHostVarMgr.h>

extern utString  gString;
extern iSQLSpool *gSpool;

iSQLHostVarMgr::iSQLHostVarMgr()
{
    SInt i;
    
    m_BindList      = NULL;
    m_Head = m_Tail = NULL;
    m_BindListCnt   = 0;

    for (i=0; i<MAX_TABLE_ELEMENTS; i++) 
    {
        m_SymbolTable[i] = NULL;
    }
}

iSQLHostVarMgr::~iSQLHostVarMgr()
{
    SInt i;
    HostVarNode *t_node;
    HostVarNode *t_node_b;
    
    for (i=0; i<MAX_TABLE_ELEMENTS; i++)
    {
        t_node = m_SymbolTable[i];
        while (t_node != NULL)
        {
            t_node_b = t_node;
            if (t_node_b->element.c_value != NULL)
            {
                idlOS::free(t_node_b->element.c_value);
            }
            t_node   = t_node->next;
            idlOS::free(t_node_b);
        }
        m_SymbolTable[i] = NULL;
    }
    initBindList();
    m_BindList      = NULL;
    m_Head = m_Tail = NULL;
    m_BindListCnt   = 0;
}
 
void
iSQLHostVarMgr::initBindList()
{
    HostVarNode *sNode = NULL;
    HostVarNode *sCurNode = NULL;
    sNode = sCurNode = m_Head;
    while ( sNode != NULL )
    {
        sCurNode = sNode;
        if (sCurNode->element.c_value != NULL)
        {
            idlOS::free(sCurNode->element.c_value);
        }
        sNode = sCurNode->host_var_next;
        idlOS::free(sCurNode);
    }
    m_BindList      = NULL;
    m_Head = m_Tail = NULL;
    m_BindListCnt   = 0;
}

IDE_RC 
iSQLHostVarMgr::add( SChar       * a_name, 
                     iSQLVarType   a_type, 
                     SInt          a_precision, 
                     SChar       * a_scale )
{
    HostVarNode *t_node;
    HostVarNode *s_node;
    UInt i_hash      = 0;
    
    IDE_TEST_RAISE(a_type == iSQL_BAD, invalid_datatype);

    IDE_TEST_RAISE(idlOS::strlen(a_name) > QP_MAX_NAME_LEN, name_len_error);

    gString.toUpper(a_name);

    if ( (t_node = getVar(a_name)) == NULL )
    {
        // memory alloc error 가 발생한 경우
        t_node = (HostVarNode*) idlOS::malloc(sizeof(HostVarNode));
        IDE_TEST_RAISE( t_node == NULL, mem_alloc_error );
        idlOS::memset(t_node, 0x00, sizeof(HostVarNode));

        switch (a_type)
        {
        case iSQL_REAL   :
        case iSQL_DOUBLE :
            t_node->element.size = 0;
            break;
        case iSQL_CHAR       : 
        case iSQL_VARCHAR    :
        case iSQL_NIBBLE :
        case iSQL_BLOB       : 
            t_node->element.size = a_precision;
            break;
        case iSQL_SMALLINT :
            t_node->element.size = 21;//SMALLINT_SIZE;
            break;
        case iSQL_INTEGER :
            t_node->element.size = 21;//INTEGER_SIZE;
            break;
        case iSQL_BIGINT :
            t_node->element.size = 21;//BIGINT_SIZE;
            break;
        case iSQL_FLOAT   :
        case iSQL_DECIMAL :
        case iSQL_NUMERIC :
        case iSQL_NUMBER  :
            t_node->element.size = 21;//NUMBER_SIZE;
            break;
        case iSQL_DATE :
            t_node->element.size = DATE_SIZE;
            break;
        case iSQL_BYTE :
            t_node->element.size = a_precision*2;
            break;
        default :
            IDE_RAISE( invalid_datatype );
            break;
        }
        if (a_type != iSQL_DOUBLE && a_type != iSQL_REAL)
        {
            IDE_TEST_RAISE( (t_node->element.c_value =
                                (SChar*)idlOS::malloc(t_node->element.size+1))
                             == NULL, mem_alloc_error );
            idlOS::memset(t_node->element.c_value, 0x00,
                          t_node->element.size+1);
        }
        else
        {
            t_node->element.c_value = NULL;
        }

        idlOS::strcpy(t_node->element.name, a_name);
        idlOS::strcpy(t_node->element.scale, a_scale);
        t_node->element.type      = a_type;
        t_node->element.precision = a_precision;
        t_node->element.d_value   = 0;
        t_node->element.f_value   = 0;
        t_node->element.assigned  = ID_FALSE;
        t_node->element.order     = 0;
        t_node->host_var_next     = NULL;
        i_hash = hashing(a_name);

        if ( (s_node = m_SymbolTable[i_hash]) != NULL )
        {
            t_node->next = s_node;
        }
        else
        {
            t_node->next = NULL;
        }
        m_SymbolTable[i_hash] = t_node;   
    }
    else
    {
        if (t_node->element.c_value != NULL)
        {
            free(t_node->element.c_value);
            t_node->element.c_value = NULL;
        }
        switch (a_type)
        {
        case iSQL_REAL   :
        case iSQL_DOUBLE :
            t_node->element.size = 0;
            break;
        case iSQL_CHAR       : 
        case iSQL_VARCHAR    :
        case iSQL_NIBBLE :
        case iSQL_BLOB       : 
            t_node->element.size = a_precision;
            break;
        case iSQL_SMALLINT :
            t_node->element.size = 21;//SMALLINT_SIZE;
            break;
        case iSQL_INTEGER :
            t_node->element.size = 21;//INTEGER_SIZE;
            break;
        case iSQL_BIGINT :
            t_node->element.size = 21;//BIGINT_SIZE;
            break;
        case iSQL_FLOAT   :
        case iSQL_DECIMAL :
        case iSQL_NUMERIC :
        case iSQL_NUMBER  :
            t_node->element.size = 21;//NUMBER_SIZE;
            break;
        case iSQL_DATE :
            t_node->element.size = DATE_SIZE;
            break;
        case iSQL_BYTE :
            t_node->element.size = a_precision*2;
            break;
        default :
            IDE_RAISE( invalid_datatype );
            break;
        }
        if (a_type != iSQL_DOUBLE && a_type != iSQL_REAL)
        {
            IDE_TEST_RAISE( (t_node->element.c_value = (SChar*)
                              idlOS::malloc(t_node->element.size+1))
                            == NULL, mem_alloc_error );
            idlOS::memset(t_node->element.c_value, 0x00,
                          t_node->element.size+1);
        }

        idlOS::strcpy(t_node->element.name, a_name);
        idlOS::strcpy(t_node->element.scale, a_scale);
        t_node->element.type      = a_type;
        t_node->element.precision = a_precision;
        t_node->element.assigned  = ID_FALSE;
        t_node->element.d_value   = 0;
        t_node->element.f_value   = 0;
        t_node->element.assigned  = ID_FALSE;
        t_node->element.order     = 0;
        t_node->host_var_next     = NULL;
    }

    return IDE_SUCCESS;
    
    IDE_EXCEPTION(invalid_datatype);
    {
        idlOS::sprintf(gSpool->m_Buf, "Invalid data type error.\n");
        gSpool->Print();
    }

    IDE_EXCEPTION(name_len_error);
    {
        idlOS::sprintf(gSpool->m_Buf,
                    "A length of host variable name have to less than 40.\n");
        gSpool->Print();
    }

    IDE_EXCEPTION(mem_alloc_error);
    {
        idlOS::fprintf(stderr, "Memory allocation error!!! --- (%d, %s)\n",
                       __LINE__, __FILE__);
        exit(0);
    }

    IDE_EXCEPTION_END;
    
    return IDE_FAILURE;
}

IDE_RC 
iSQLHostVarMgr::setValue( SChar * a_name )
{
    HostVarNode *t_node;

    // 선언되지 않은 호스트 변수
    IDE_TEST_RAISE((t_node = getVar(a_name)) == NULL, not_defined);                    
    t_node->element.assigned = ID_FALSE;

    idlOS::sprintf(gSpool->m_Buf, "Execute success.\n");
    gSpool->Print();

    return IDE_SUCCESS;
    
    IDE_EXCEPTION(not_defined);
    {
        idlOS::sprintf(gSpool->m_Buf, "%s not defined.\n", a_name);
        gSpool->Print();
    }

    IDE_EXCEPTION_END;
    
    return IDE_FAILURE;
}    

IDE_RC 
iSQLHostVarMgr::setValue( SChar * a_name, 
                          SChar * a_value )
{
    HostVarNode *t_node;
    SChar *begin_pos, *end_pos;

    // 선언되지 않은 호스트 변수
    IDE_TEST_RAISE((t_node = getVar(a_name)) == NULL, not_defined);     
    
    if ( idlOS::strcasecmp(a_value, "NULL") == 0 )
    {
        return setValue(a_name);
    }

    switch (t_node->element.type)
    {
    case iSQL_CHAR       :
    case iSQL_DATE       :
    case iSQL_BYTE  :
    case iSQL_NIBBLE :
    case iSQL_VARCHAR    :  // value가 const string('...') 이어야 한다.
        begin_pos = idlOS::strchr(a_value, '\'');
        IDE_TEST_RAISE(begin_pos == NULL, type_mismatch); // value가 const string이 아닌경우                              
        
        end_pos = idlOS::strrchr(begin_pos+1, '\'');
        IDE_TEST_RAISE(end_pos == NULL, type_mismatch);   // value가 '로 끝나지 않은 경우, 절대 들어올 수 없는 경우                             
        // value가 null string 인 경우
        IDE_TEST_RAISE(end_pos-begin_pos == 1, null_value);     

        idlOS::memset(t_node->element.c_value, 0x00,
                      t_node->element.size+1);
        IDE_TEST_RAISE( end_pos-begin_pos-1 > t_node->element.size, too_large_error );
        idlOS::strncpy(t_node->element.c_value, begin_pos+1,
                       end_pos-begin_pos-1);
        t_node->element.c_value[end_pos-begin_pos-1] = '\0';
        break;
    case iSQL_FLOAT    :
    case iSQL_DECIMAL  :
    case iSQL_NUMBER   :
    case iSQL_NUMERIC  :
    case iSQL_BIGINT   :
    case iSQL_INTEGER  :
    case iSQL_SMALLINT :
        begin_pos = idlOS::strchr(a_value, '\'');
        if (begin_pos != NULL)    // value가 const string이 아닌경우                              
        { 
            end_pos = idlOS::strrchr(begin_pos+1, '\'');
            IDE_TEST_RAISE(end_pos == NULL, type_mismatch); // value가 '로 끝나지 않은 경우, 절대 들어올 수 없는 경우                             
            // value가 null string 인 경우
            IDE_TEST_RAISE(end_pos-begin_pos == 1, null_value);     
        
            // value가 const string인 경우
            IDE_RAISE(type_mismatch);                                  
        }

        idlOS::memset(t_node->element.c_value, 0x00, t_node->element.size+1);
        IDE_TEST_RAISE( idlOS::strlen(a_value) > t_node->element.size,
                        too_large_error );
        idlOS::strcpy(t_node->element.c_value, a_value);
        if ( t_node->element.type == iSQL_SMALLINT )
        {
            errno = 0;
            SInt sTmpInt = idlOS::atoi( (const char *) a_value );
            IDE_TEST_RAISE( sTmpInt > (SShort)0x7FFF ||
                            sTmpInt < (SShort)0x8001 ||
                            errno == ERANGE, outof_range_error );
        }
        else if ( t_node->element.type == iSQL_INTEGER )
        {
            errno = 0;
            SLong sTmpLong = Strtoll( (char *) a_value, (char**) NULL, 10 );
            IDE_TEST_RAISE( sTmpLong > (SInt)0x7FFFFFFF ||
                            sTmpLong < (SInt)0x80000001 ||
                            errno == ERANGE, outof_range_error );
        }
        break;
    case iSQL_DOUBLE :
        begin_pos = idlOS::strchr(a_value, '\'');
        if (begin_pos != NULL)    // value가 const string이 아닌경우                              
        { 
            end_pos = idlOS::strrchr(begin_pos+1, '\'');
            IDE_TEST_RAISE(end_pos == NULL, type_mismatch); // value가 '로 끝나지 않은 경우, 절대 들어올 수 없는 경우                             
            // value가 null string 인 경우
            IDE_TEST_RAISE(end_pos-begin_pos == 1, null_value);     

            // value가 const string인 경우
            IDE_RAISE(type_mismatch);
        }

        t_node->element.d_value = (SDouble)atof(a_value);
        break;
    case iSQL_REAL :
        begin_pos = idlOS::strchr(a_value, '\'');
        if (begin_pos != NULL)    // value가 const string이 아닌경우                              
        { 
            end_pos = idlOS::strrchr(begin_pos+1, '\'');
            IDE_TEST_RAISE(end_pos == NULL, type_mismatch); // value가 '로 끝나지 않은 경우, 절대 들어올 수 없는 경우       

            // value가 null string 인 경우
            IDE_TEST_RAISE(end_pos-begin_pos == 1, null_value);     

            // value가 const string인 경우
            IDE_RAISE(type_mismatch);
        }

        t_node->element.f_value = (SFloat)atof(a_value);
        break;
     default:
        IDE_RAISE(type_mismatch);
        break;
    }

    t_node->element.assigned = ID_TRUE;

    idlOS::sprintf(gSpool->m_Buf, "Execute success.\n");
    gSpool->Print();

    return IDE_SUCCESS;
    
    IDE_EXCEPTION(null_value);
    {
        t_node->element.assigned = ID_FALSE;
        idlOS::sprintf(gSpool->m_Buf, "Execute success.\n");
        gSpool->Print();
        return IDE_SUCCESS;
    }
    IDE_EXCEPTION(not_defined);
    {
        idlOS::sprintf(gSpool->m_Buf, "%s not defined.\n", a_name);
        gSpool->Print();
    }
    IDE_EXCEPTION(type_mismatch);
    {
        idlOS::strcpy(gSpool->m_Buf, "Type mismatch error.\n");
        gSpool->Print();
    }
    IDE_EXCEPTION(too_large_error);
    {
        idlOS::strcpy(gSpool->m_Buf, "Too large data size.\n");
        gSpool->Print();
    }
    IDE_EXCEPTION(outof_range_error);
    {
        idlOS::strcpy(gSpool->m_Buf, "Host value out of range.\n");
        gSpool->Print();
    }
    IDE_EXCEPTION_END;
    
    return IDE_FAILURE;
}    

IDE_RC 
iSQLHostVarMgr::lookup( SChar * a_name )
{
    return ( getVar(a_name) != NULL ) ? IDE_SUCCESS : IDE_FAILURE;
}

HostVarNode *
iSQLHostVarMgr::getVar( SChar * a_name )
{
    UInt key = hashing(a_name);

    return getVar(key, a_name);
}

HostVarNode *
iSQLHostVarMgr::getVar( UInt    a_key, 
                        SChar * a_name )
{
    HostVarNode *t_node = m_SymbolTable[a_key];
    
    gString.toUpper(a_name);

    while(t_node != NULL)
    {
        if ( idlOS::strcmp(t_node->element.name, a_name) == 0)
        {
            return t_node;
        }
        t_node = t_node->next;
    }
    return NULL;
}

UInt 
iSQLHostVarMgr::hashing( SChar * a_name )
{
    SChar *t_ptr = a_name;
    ULong  key = 0;
    
    while (*t_ptr != 0)
    {
        key = key*31 + *t_ptr++;
    }
    
    return (UInt)(key%MAX_TABLE_ELEMENTS);
}

IDE_RC 
iSQLHostVarMgr::typeConvert( HostVarElement * a_host_var, 
                             SChar          * r_type )
{
    SChar tmp[WORD_LEN];

    switch (a_host_var->type)
    {
    case iSQL_BIGINT     : idlOS::strcpy(tmp, "BIGINT");      break;
    case iSQL_BLOB       : idlOS::strcpy(tmp, "BLOB");        break;
    case iSQL_CHAR       : idlOS::strcpy(tmp, "CHAR");        break;
    case iSQL_DATE       : idlOS::strcpy(tmp, "DATE");        break;
    case iSQL_DECIMAL    : idlOS::strcpy(tmp, "DECIMAL");     break;
    case iSQL_DOUBLE     : idlOS::strcpy(tmp, "DOUBLE");      break;
    case iSQL_FLOAT      : idlOS::strcpy(tmp, "FLOAT");       break;
    case iSQL_BYTE  : idlOS::strcpy(tmp, "BYTE");   break;
    case iSQL_NIBBLE : idlOS::strcpy(tmp, "NIBBLE");  break;
    case iSQL_INTEGER    : idlOS::strcpy(tmp, "INTEGER");     break;
    case iSQL_NUMBER     : idlOS::strcpy(tmp, "NUMBER");      break;
    case iSQL_NUMERIC    : idlOS::strcpy(tmp, "NUMERIC");     break;
    case iSQL_REAL       : idlOS::strcpy(tmp, "REAL");        break;
    case iSQL_SMALLINT   : idlOS::strcpy(tmp, "SMALLINT");    break;
    case iSQL_VARCHAR    : idlOS::strcpy(tmp, "VARCHAR");     break;
    case iSQL_GEOMETRY   : idlOS::strcpy(tmp, "GEOMETRY");    break;
    default              : return IDE_FAILURE;  
    }

    if (a_host_var->precision != -1)
    {
        if ( idlOS::strlen(a_host_var->scale) != 0 )
        {
            idlOS::sprintf(r_type, "%s(%d, %s)", tmp,
                           a_host_var->precision, a_host_var->scale);
        }
        else
        {
            idlOS::sprintf(r_type, "%s(%d)", tmp, a_host_var->precision);
        }
    }
    else
    {
        idlOS::sprintf(r_type, "%s", tmp);
    }

    return IDE_SUCCESS;
}

IDE_RC 
iSQLHostVarMgr::isCorrectType( iSQLVarType a_type )
{
    switch (a_type)
    {
    case iSQL_BIGINT     : 
    case iSQL_BLOB       : 
    case iSQL_CHAR       : 
    case iSQL_DATE       : 
    case iSQL_DECIMAL    : 
    case iSQL_DOUBLE     : 
    case iSQL_FLOAT      : 
    case iSQL_BYTE  : 
    case iSQL_NIBBLE : 
    case iSQL_INTEGER    : 
    case iSQL_NUMBER     : 
    case iSQL_NUMERIC    : 
    case iSQL_REAL       : 
    case iSQL_SMALLINT   : 
    case iSQL_VARCHAR    : 
    case iSQL_GEOMETRY   : return IDE_SUCCESS;
    default              : return IDE_FAILURE;  
    }
}

IDE_RC 
iSQLHostVarMgr::showVar( SChar * a_name )
{
    SChar tmp[WORD_LEN], tmp_name[QP_MAX_NAME_LEN+1];
    HostVarNode *t_node;

    IDE_TEST_RAISE((t_node = getVar(a_name)) == NULL, not_defined);
    
    idlOS::sprintf(gSpool->m_Buf, "NAME                 TYPE                 VALUE\n");
    gSpool->Print();
    idlOS::sprintf(gSpool->m_Buf, "-------------------------------------------------------\n");
    gSpool->Print();

    if ( idlOS::strlen(t_node->element.name) > 20 )
    {
        idlOS::strncpy(tmp_name, t_node->element.name, 20); 
    }
    else
    {
        idlOS::strcpy(tmp_name, t_node->element.name); 
    }

    typeConvert(&(t_node->element), tmp);

    if ( t_node->element.assigned == ID_TRUE )
    {
        switch (t_node->element.type)
        {
        case iSQL_DOUBLE :
            idlOS::sprintf(gSpool->m_Buf, "%-20s %-20s %f\n",
                           tmp_name, tmp, t_node->element.d_value);
            break;
        case iSQL_REAL :
            idlOS::sprintf(gSpool->m_Buf, "%-20s %-20s %f\n",
                           tmp_name, tmp, t_node->element.f_value);
            break;
        default :
            idlOS::sprintf(gSpool->m_Buf, "%-20s %-20s %s\n",
                           tmp_name, tmp, t_node->element.c_value);
            break;
        }
    }
    else
    {
        idlOS::sprintf(gSpool->m_Buf, "%-20s %-20s\n", tmp_name, tmp);
    }
    gSpool->Print();

    return IDE_SUCCESS;
    
    IDE_EXCEPTION(not_defined);
    {
        idlOS::sprintf(gSpool->m_Buf, "%s not defined.\n", a_name);
        gSpool->Print();
    }

    IDE_EXCEPTION_END;
    
    return IDE_FAILURE;
}

void 
iSQLHostVarMgr::print()
{
    SInt         ix;
    SChar        tmp[WORD_LEN], tmp_name[QP_MAX_NAME_LEN+1];
    HostVarNode* t_node;
    
    idlOS::sprintf(gSpool->m_Buf, "[ HOST VARIABLE ]\n");
    gSpool->Print();
    idlOS::sprintf(gSpool->m_Buf, "-------------------------------------------------------\n");
    gSpool->Print();
    idlOS::sprintf(gSpool->m_Buf, "NAME                 TYPE                 VALUE\n");
    gSpool->Print();
    idlOS::sprintf(gSpool->m_Buf, "-------------------------------------------------------\n");
    gSpool->Print();

    for (ix=0; ix<MAX_TABLE_ELEMENTS; ix++)
    {
        t_node = m_SymbolTable[ix];
        while (t_node != NULL)
        {
            if ( idlOS::strlen(t_node->element.name) > 20 )
            {
                idlOS::strncpy(tmp_name, t_node->element.name, 20); 
            }
            else
            {
                idlOS::strcpy(tmp_name, t_node->element.name); 
            }

            typeConvert(&(t_node->element), tmp);
            
            if ( t_node->element.assigned == ID_TRUE )
            {
                switch (t_node->element.type)
                {
                case iSQL_DOUBLE :
                    idlOS::sprintf(gSpool->m_Buf, "%-20s %-20s %f\n",
                                   tmp_name, tmp, t_node->element.d_value);
                    break;
                case iSQL_REAL :
                    idlOS::sprintf(gSpool->m_Buf, "%-20s %-20s %f\n",
                                   tmp_name, tmp, t_node->element.f_value);
                    break;
                default :
                    idlOS::sprintf(gSpool->m_Buf, "%-20s %-20s %s\n",
                                   tmp_name, tmp, t_node->element.c_value);
                    break;
                }
            }
            else
            {
                idlOS::sprintf(gSpool->m_Buf, "%-20s %-20s\n", tmp_name, tmp);
            }
            gSpool->Print();

            t_node = t_node->next;
        }
    }
}
IDE_RC 
iSQLHostVarMgr::putBindList( SChar * a_name, 
                             SInt    a_order, 
                             SShort  a_para_order )
{
    HostVarNode *t_node;
    HostVarNode *s_node;

    // 선언되지 않은 호스트 변수
    IDE_TEST_RAISE((t_node = getVar(a_name)) == NULL, not_defined);

    // memory alloc error 가 발생한 경우
    IDE_TEST_RAISE( (s_node = (HostVarNode*)
                              idlOS::malloc(sizeof(HostVarNode)))
                    == NULL, mem_alloc_error);
    idlOS::memset(s_node, 0x00, sizeof(HostVarNode) );
    
    idlOS::strcpy(s_node->element.name, t_node->element.name);
    idlOS::strcpy(s_node->element.scale, t_node->element.scale);
    s_node->element.type       = t_node->element.type;
    s_node->element.size       = t_node->element.size;
    s_node->element.precision  = t_node->element.precision;
    s_node->element.assigned   = t_node->element.assigned;
    s_node->element.order      = a_order;
    s_node->element.para_order = a_para_order;
    
    if (s_node->element.type == iSQL_DOUBLE)
    {
        s_node->element.d_value = t_node->element.d_value;
    }
    else if (s_node->element.type == iSQL_REAL)
    {
        s_node->element.f_value  = t_node->element.f_value;
    }
    else
    {
        IDE_TEST_RAISE((s_node->element.c_value = (SChar*)
                            idlOS::malloc(t_node->element.size+1))
                       == NULL, mem_alloc_error);
        idlOS::memset(s_node->element.c_value, 0x00, t_node->element.size+1);
        if ( s_node->element.assigned == ID_TRUE )
        {
            idlOS::strcpy(s_node->element.c_value, t_node->element.c_value);
        }
    }

    if (m_Head == NULL)
    {
        m_Head = m_Tail = s_node;
        s_node->host_var_next = NULL;
    }
    else
    {
        m_Tail->host_var_next = s_node;
        m_Tail = s_node;
    }
    
    m_BindListCnt++;

    return IDE_SUCCESS;
 
    IDE_EXCEPTION(not_defined);
    {
        idlOS::sprintf(gSpool->m_Buf, "%s not defined.\n", a_name);
        gSpool->Print();
    }

    IDE_EXCEPTION(mem_alloc_error);
    {
        idlOS::fprintf(stderr, "Memory allocation error!!! --- (%d, %s)\n",
                      __LINE__, __FILE__);
        exit(0);
    }

    IDE_EXCEPTION_END;
    
    return IDE_FAILURE;
}

void 
iSQLHostVarMgr::setHostVar( HostVarNode * /*a_host_var_list*/ )
{
    // after execute procedure/function, set value host var in m_SymbolTable
    HostVarNode *t_node;
    HostVarNode *s_node;
    HostVarNode *sHeadNode;

    sHeadNode = m_Head;
    t_node = m_Head;
    m_Head = t_node->host_var_next;
    
    while (1)
    {
        s_node = getVar(t_node->element.name);                    

        if (t_node->element.type == iSQL_DOUBLE)
        {
            s_node->element.d_value = t_node->element.d_value;
        }
        else if (t_node->element.type == iSQL_REAL)
        {
            s_node->element.f_value = t_node->element.f_value;
        }
        else
        {
            idlOS::strcpy(s_node->element.c_value, t_node->element.c_value);
        }

        s_node->element.assigned = ID_TRUE;

        t_node = m_Head;
        if (t_node != NULL)
        {
            m_Head = t_node->host_var_next;
        }
        else
        {
            break;
        }
    }
    m_Head = sHeadNode;
}
    
