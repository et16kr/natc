/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iloDataFile.cpp 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/
 
#include <ilo.h>

extern idBool     gAddFlag;
extern iloProgOption       gProgOption;

iloDataFile::iloDataFile()
{
    m_DataFp = NULL;
    idlOS::strcpy(m_FieldTerm, "^");
    idlOS::strcpy(m_RowTerm, "\n");
    idlOS::strcpy(m_Enclosing, "");
    m_SetEnclosing = isql_false;
}

isql_bool iloDataFile::OpenFile(SChar *szFileName, SChar *szMode)
{
    m_DataFp = ilo_fopen(szFileName, szMode);
    IDE_TEST( m_DataFp == NULL );

    m_SetNextToken = isql_false;
    m_nFTLen = idlOS::strlen(m_FieldTerm);
    m_nRTLen = idlOS::strlen(m_RowTerm);
    m_nEnLen = idlOS::strlen(m_Enclosing);

    m_nCurReadPos = 0;
    m_nReadSize = 0;

    return isql_true;

    IDE_EXCEPTION_END;

    return isql_false;
}

isql_bool iloDataFile::OpenFile(SChar *szFileName, SInt sFileCnt, SChar *szMode)
{
    SChar sFileName[256];

    idlOS::sprintf(sFileName, "%s%d", szFileName, sFileCnt);

    return OpenFile(sFileName, szMode);
}

isql_bool iloDataFile::CloseFile()
{
    IDE_TEST( idlOS::fclose(m_DataFp) != 0 );

    return isql_true;

    IDE_EXCEPTION_END;

    return isql_false;
}

void iloDataFile::SetTerminator(SChar *szFiledTerm, SChar *szRowTerm)
{
    idlOS::strcpy(m_FieldTerm, szFiledTerm);
    idlOS::strcpy(m_RowTerm, szRowTerm);
}

void iloDataFile::SetEnclosing(isql_bool bSetEnclosing, SChar *szEnclosing)
{
    m_SetEnclosing = bSetEnclosing;
    if (m_SetEnclosing)
    {
        strcpy(m_Enclosing, szEnclosing);
    }
}

isql_bool iloDataFile::PrintOneRecord(iloColumns *pCols)
{
    SInt i;

    for (i=0; i < pCols->GetSize(); i++)
    {
        if (m_SetEnclosing)
        {
            idlOS::fprintf(m_DataFp, "%s", m_Enclosing);
        }
        switch (pCols->GetType(i))
        {
        case ISP_INTEGER : /* SQLBindCol에서 CHAR로 지정함 */
        case SQL_SMALLINT:
        case SQL_BIGINT  :
        case ISP_NIBBLE :
        case ISP_BYTES :
        case ISP_CHAR :
        case ISP_VARCHAR :
        case ISP_NUMERIC :
        case SQL_DECIMAL :
        case SQL_DOUBLE  :
        case SQL_FLOAT   :
        case SQL_REAL   :
        case ISP_DATE :
        case SQL_DATE :
            idlOS::fprintf(m_DataFp, "%s", pCols->m_Value[i].C_Col);
            break;
        case SQL_BINARY :
            idlOS::fprintf(m_DataFp, "%s", pCols->m_Value[i].C_Col);
            break;
        default :
            idlOS::fprintf(m_DataFp, "unknown type");
            break;
        }
        if (m_SetEnclosing)
        {
            idlOS::fprintf(m_DataFp, "%s", m_Enclosing);
        }
        if ( i == pCols->GetSize()-1 )
        {
            if ( gProgOption.mInformix == isql_true )
            {
                idlOS::fprintf(m_DataFp, "%s", m_FieldTerm);
            }
            idlOS::fprintf(m_DataFp, "%s", m_RowTerm);
        }
        else
        {
            idlOS::fprintf(m_DataFp, "%s", m_FieldTerm);
        }
    }
    return isql_true;
}

EDataToken iloDataFile::GetToken()
{
    static EDataToken eNextToken;
    SInt vix = 0;
    SInt ixFT = 0;
    SInt ixRT = 0;
    SInt ixEn = -1;
    SInt ch;
    SInt enFlag = -1;
    SInt encloseLoopCnt = 0;
    SInt j;

    IDE_TEST_RAISE( m_SetNextToken == isql_true, err_next_token )

    m_SetNextToken = isql_false;

    if (m_SetEnclosing)
    {
        ixEn = 0;  
    }

    ch = GetChar();
    if (ch == '\r') // DOS File handling \n\r or \r\n ==> \n
    {
        ch = GetChar();
    }
    IDE_TEST_RAISE( ch == EOF, err_eof );

    while (isql_true)
    {
        if (ch == EOF)
        {
            m_SetNextToken = isql_true;
            eNextToken = TEOF;
            break;
        }

        m_TokenValue[vix++] = (SChar)ch;
        IDE_TEST_RAISE( (UInt)vix >= MAX_TOKEN_VALUE_LEN, err_token_overflow );

        if (enFlag == -1 && ch == m_FieldTerm[ixFT])
        {
            ixFT++;
        }
        else if (ixFT > 0) 
        {
            //ixFT = (ch == m_FieldTerm[0]) ? 1 : 0;
            //<- 구분자의 길이가 1 보다 클 경우 에러 발생함 ( BUG-3606 )
            /* 구분자 비교중 앞쪽이 맞는 상황에서 뒤쪽에서 틀린경우가 발생하면
             * 다시 구분자를 체크해야 한다. */
            SInt sMinFT = ( vix > m_nFTLen ) ? m_nFTLen : vix;
            ixFT = 0;
            for ( j = 1; j <= sMinFT; j++ )
            {
                if ( idlOS::strncmp( m_TokenValue + vix - j, 
                                     m_FieldTerm, j ) == 0 )
                {
                    ixFT = j;
                }
            }
        }

        if (ixFT == m_nFTLen)
        {
            if ( vix == m_nFTLen )
            {
                return TFIELD_TERM;
            }
            else
            {
                m_SetNextToken = isql_true;
                eNextToken = TFIELD_TERM;
                vix -= m_nFTLen;
                break;
            }
        }
        
        if (enFlag == -1 && ch == m_RowTerm[ixRT])
        {
            ixRT++;
        }
        else if (ixRT > 0) 
        {
            //ixRT = (ch == m_RowTerm[0]) ? 1 : 0; <- 구분자의 길이가 1 보다 클 경우 에러 발생함
            SInt sMinRT = ( vix > m_nRTLen ) ? m_nRTLen : vix;
            ixRT = 0;
            for ( j = 1; j <= sMinRT; j++ )
            {
                if ( idlOS::strncmp( m_TokenValue + vix - j, 
                                     m_RowTerm, j ) == 0 )
                {
                    ixRT = j;
                }
            }
        }

        if (ixRT == m_nRTLen)
        {
            if ( vix == m_nRTLen )
            {
                return TROW_TERM;
            }
            else
            {
                m_SetNextToken = isql_true;
                eNextToken = TROW_TERM;
                vix -= m_nRTLen;
                break;
            }
        }
        
        if (ixEn >= 0)
        {
            m_SetEnclosing = isql_true;
        }

        if (m_SetEnclosing == isql_true && ixFT == 0 && ixRT == 0)
        {
            if (ch == m_Enclosing[ixEn])
            {
                ixEn++;
            }
            else if (ixEn > 0) 
            {
                // BUG-3606 발생할 소지가 있음
                ixEn = (ch == m_Enclosing[0]) ? 1 : 0;
            }
            
            if (ixEn ==  m_nEnLen)
            {
                if (vix == m_nEnLen)
                {
                    vix = 0;
                    ixEn = 0;
                    ixFT = 0;
                    ixRT = 0;
                    if (encloseLoopCnt++ == m_nEnLen)
                        break;
                }
                else
                {
                    vix -= m_nEnLen;
                    break;
                }
            }
            enFlag = 0;
        }
        ch = GetChar();
        if (ch == '\r') // DOS File handling \n\r or \r\n ==> \n
        {
            ch = GetChar();
        }
    }
    m_TokenValue[vix] = '\0';

    return TVALUE;

    IDE_EXCEPTION( err_next_token );
    {
        m_SetNextToken = isql_false;
        return eNextToken;
    }
    IDE_EXCEPTION( err_eof );
    {
        return (TEOF);
    }
    IDE_EXCEPTION( err_token_overflow );
    {
        m_TokenValue[vix] = '\0';
fprintf(stderr,"%s:%d Error: token value length overflow. maximum token length=%d. m_TokenValue=[%s]\n", __FILE__, __LINE__, MAX_TOKEN_VALUE_LEN, m_TokenValue);
        return (TEOF);
    }
    IDE_EXCEPTION_END;
    return (TEOF);
}

void iloDataFile::rtrim()
{
    SInt   cnt = 0;
    SInt   len = 0;
    SChar *ptr;
    len = idlOS::strlen(m_TokenValue);
    ptr =  m_TokenValue + len;
    while (cnt < len)
    {
        if (*ptr != ' ') break;
        ptr--;
        cnt++;
    }
    if (cnt < len)
    {
        *ptr = '\0';
    }
}

/*
    Return Value 
    0 : Error
    1 : Success
    2 : End of File
*/
SInt iloDataFile::ReadOneRecord(iloTableInfo *pTableInfo, SInt aArrayCount)
{
    EDataToken eToken;
    SInt i = 0;

    eToken = GetToken();
    if ( i+1 < pTableInfo->GetAttrCount() &&
         pTableInfo->GetAttrType(i) == ISP_ATTR_TIMESTAMP &&
         gAddFlag == ID_TRUE )
    {
        i++;
    }

    for ( ; i < pTableInfo->GetAttrCount(); i++)
    {
        if (eToken == TEOF)
        {
            pTableInfo->SetReadCount(i, aArrayCount);

            return 2;
        }
        else if (eToken == TVALUE)
        {
            pTableInfo->SetAttrValue(i, GetTokenValue(), aArrayCount );
            pTableInfo->SetAttrLen(i, (SInt)SQL_NTS, aArrayCount );
            eToken = GetToken();
            if ( i+1 < pTableInfo->GetAttrCount() &&
                 pTableInfo->GetAttrType(i+1) == ISP_ATTR_TIMESTAMP &&
                 gAddFlag == ID_TRUE )
            {
                i++;
            }
        }
        else if ((eToken == TROW_TERM) || (eToken == TFIELD_TERM))
        {
            pTableInfo->SetAttrValue(i, (SChar *)"", aArrayCount );
            pTableInfo->SetAttrLen(i, (SInt)SQL_NULL_DATA, aArrayCount );
        }
        else 
        {
            pTableInfo->SetReadCount(i, aArrayCount);
            return 0;
        } 

        if ((i == pTableInfo->GetAttrCount()-1) && (eToken == TEOF))
        {
            pTableInfo->SetReadCount(i, aArrayCount);            
            return 1;
        }
    
        if (gProgOption.mInformix == isql_true &&
            (i == pTableInfo->GetAttrCount()-1) && (eToken == TFIELD_TERM))
        {
            eToken = GetToken();
            if (eToken == TEOF)
            {
                pTableInfo->SetReadCount(i, aArrayCount);
                return 1;
            }
            else if (eToken != TROW_TERM)
            {
                pTableInfo->SetReadCount(i, aArrayCount);
                return 0;
            }
        }
        else if ((i == pTableInfo->GetAttrCount()-1) && (eToken != TROW_TERM))
        {
            pTableInfo->SetReadCount(i, aArrayCount);
            return 0;
        }
        else if ( (i < pTableInfo->GetAttrCount()-1) && 
                  (eToken != TFIELD_TERM) )
        {
            pTableInfo->SetReadCount(i, aArrayCount);
            return 0;
        }

        if (i < pTableInfo->GetAttrCount()-1)
        {
            eToken = GetToken();
            if ( i+1 < pTableInfo->GetAttrCount() &&
                 pTableInfo->GetAttrType(i) == ISP_ATTR_TIMESTAMP &&
                 gAddFlag == ID_TRUE )
            {
                i++;
            }
        }
    }

    pTableInfo->SetReadCount(i, aArrayCount);
    return 1;
}

SInt iloDataFile::strtonumCheck(SChar *p)
{
    SChar c;
    while((c = *p) == ' ' || (c = *p) == '\t' )
    {
        p++;
    }
    
    if (c == '-' || c == '+')
        p++;
    else
        ;
    
    while ((c = *p++), isdigit(c))
        ;
    
    if (c=='.')
    {
        while ((c = *p++), isdigit(c)) ;
    }
    else if (c=='\0')
    {
        return 1;
    }
    else
    {
        return 0;
    }
    
    if ((c == 'E') || (c == 'e'))
    {
        if ((c= *p++) == '+')
            ;
        else if (c=='-')
           ;
        else
           --p;
        while ((c = *p++), isdigit(c))
          ;
    }
    
    if ( c == '\0' )
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

