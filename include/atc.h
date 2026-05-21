#ifndef _O_ATC_H_
#define _O_ATC_H_ 1

#include <idl.h>
#include <sqlcli.h>


static SInt atc_is_success(SQLRETURN aSqlReturn)
{
    if(aSqlReturn == SQL_SUCCESS || aSqlReturn == SQL_SUCCESS_WITH_INFO)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

static const SChar *atc_print_sql_retcode(SQLRETURN aSqlReturn)
{
    switch(aSqlReturn)
    {
        case SQL_SUCCESS:
            return "SQL_SUCCESS";
        case SQL_SUCCESS_WITH_INFO:
            return "SQL_SUCCESS_WITH_INFO";
        case SQL_NO_DATA:
            return "SQL_NO_DATA";
        case SQL_ERROR:
            return "SQL_ERROR";
        case SQL_INVALID_HANDLE:
            return "SQL_INVALID_HANDLE";
        case SQL_STILL_EXECUTING:
            return "SQL_STILL_EXECUTING";
        case SQL_NEED_DATA:
            return "SQL_NEED_DATA";
        default:
            return "Unknown Return Code";
            break;
    }
}

static void atc_print_diagnostic(SQLSMALLINT aHandleType, SQLHANDLE aHandle)
{
    UInt i;

    SQLRETURN   sRetCode;
    SQLCHAR     sSqlState[6];
    SQLCHAR     sMessage[2048];
    SQLSMALLINT sMessageLength;
    SQLINTEGER  sNativeError;
    SQLLEN      sRowNumber;
    SQLSMALLINT sRowNumberLength;
    SQLINTEGER  sColumnNumber;
    SQLSMALLINT sColumnNumberLength;

    i = 1;

    while((sRetCode = SQLGetDiagRec(aHandleType,
                                    aHandle,
                                    i,
                                    sSqlState,
                                    &sNativeError,
                                    sMessage,
                                    sizeof(sMessage),
                                    &sMessageLength)) != SQL_NO_DATA)
    {
        if (i == 1)
        {
            switch(aHandleType)
            {
                case SQL_HANDLE_ENV:
                    idlOS::printf("   GetDiagRec(ENV) -------------------------------------\n");
                    break;
                case SQL_HANDLE_DBC:
                    idlOS::printf("   GetDiagRec(DBC) -------------------------------------\n");
                    break;
                case SQL_HANDLE_STMT:
                    idlOS::printf("   GetDiagRec(STMT) ------------------------------------\n");
                    break;
                case SQL_HANDLE_DESC:
                    idlOS::printf("   GetDiagRec(DESC) ------------------------------------\n");
                    break;
            }
        }

        idlOS::printf("   Diagnostic Record %d\n", i);
        idlOS::printf("     SQLSTATE     : %s\n", sSqlState);
        idlOS::printf("     Message text : %s\n", sMessage);
        idlOS::printf("     message len  : %d\n", sMessageLength);
        idlOS::printf("     native       : 0x%X\n", sNativeError);

        idlOS::printf("   SQLGetDiagRec's return code = %s\n", atc_print_sql_retcode(sRetCode));

        if(!atc_is_success(sRetCode))
        {
            break;
        }

        sRetCode = SQLGetDiagField(aHandleType,
                                   aHandle,
                                   i,
                                   SQL_DIAG_ROW_NUMBER,
                                   &sRowNumber,
                                   ID_SIZEOF(SQLINTEGER),
                                   &sRowNumberLength);

        if(sRetCode != SQL_SUCCESS)
        {
            idlOS::printf("   SQLGetDiagField() returned %s.\n", atc_print_sql_retcode(sRetCode));
        }
        else
        {
            switch((int)sRowNumber)
            {
                case SQL_NO_ROW_NUMBER:
                    idlOS::printf("     RowNumber    : SQL_NO_ROW_NUMBER\n");
                    break;
                case SQL_ROW_NUMBER_UNKNOWN:
                    idlOS::printf("     RowNumber    : SQL_ROW_NUMBER_UNKNOWN\n");
                    break;
                default:
                    idlOS::printf("     RowNumber    : %d\n", sRowNumber);
                    break;
            }
        }

        sRetCode = SQLGetDiagField(aHandleType,
                                   aHandle,
                                   i,
                                   SQL_DIAG_COLUMN_NUMBER,
                                   &sColumnNumber,
                                   ID_SIZEOF(SQLINTEGER),
                                   &sColumnNumberLength);

        if(sRetCode != SQL_SUCCESS)
        {
            idlOS::printf("   SQLGetDiagField() returned %s.\n", atc_print_sql_retcode(sRetCode));
        }
        else
        {
            switch((int)sColumnNumber)
            {
                case SQL_NO_COLUMN_NUMBER:
                    idlOS::printf("     ColumnNumber : SQL_NO_COLUMN_NUMBER\n");
                    break;
                case SQL_COLUMN_NUMBER_UNKNOWN:
                    idlOS::printf("     ColumnNumber : SQL_COLUMN_NUMBER_UNKNOWN\n");
                    break;
                default:
                    idlOS::printf("     ColumnNumber : %d\n", sColumnNumber);
                    break;
            }
        }

        i++;
    }

    if (i > 1)
    {
        idlOS::printf("  ---------------------------\n");
    }
}


#define ATC_SECTOR( msg )                                                     \
( fprintf(stdout,                                                             \
"\n\n"                                                                        \
"+-------------------------------------------------------------------+\n"     \
"--+SECTOR; (%s) %s\n"                                                     \
"+-------------------------------------------------------------------+\n"     \
"\n", __FILE__, #msg ) )

#define ATC_MSG(msg) ( fprintf(stdout,#msg) )

#define ATC_EVAL(exp)        if (exp)                 \
                             {                        \
                               ATC_SUCCESS;           \
                             }                        \
                             else                     \
                             {                        \
                               fprintf(stdout,        \
                               "FAILURE: (%s:%d)\n",  \
                               __FILE__,              \
                               __LINE__ );            \
                             }
#define ATC_EVAL_MSG(exp, msg)  if (exp)            \
                             {                        \
                               ATC_SUCCESS_MSG_S(#msg); \
                             }                        \
                             else                     \
                             {                        \
                               fprintf(stdout,        \
                               "FAILURE: (%s:%d) %s\n", \
                               __FILE__,              \
                               __LINE__,              \
                               #msg );                \
                             }
#if defined(ATC_NO_SUCCESS)
#define ATC_SUCCESS          /* quiet */
#define ATC_SUCCESS_MSG(msg) /* quiet */
#define ATC_SUCCESS_MSG_S(s) /* quiet */
#else
#define ATC_SUCCESS          fprintf(stdout, "SUCCESS: (%s)\n", __FILE__)
#define ATC_SUCCESS_MSG(msg) fprintf(stdout, "SUCCESS: (%s) %s\n", __FILE__, #msg)
#define ATC_SUCCESS_MSG_S(s) fprintf(stdout, "SUCCESS: (%s) %s\n", __FILE__, s)
#endif
#define ATC_FAILURE ( fprintf(stdout,                \
                              "FAILURE: (%s:%d)\n",    \
                              __FILE__,              \
                              __LINE__ ) )
#define ATC_FAILURE_MSG(msg)                         \
                    ( fprintf(stdout,                \
                              "FAILURE: (%s:%d) %s\n", \
                              __FILE__,              \
                              __LINE__,              \
                              #msg ) )

#define ATC_SQL_EVAL_COND(handleType, handle, exp, cond)        \
    {                                                           \
        SQLRETURN atcSqlRet = exp;                              \
        if (atcSqlRet cond)                                     \
        {                                                       \
            ATC_SUCCESS;                                        \
        }                                                       \
        else                                                    \
        {                                                       \
            idlOS::printf("FAILURE: (%s:%d)\n"                  \
                          "SHOULD : %s %s, but %s\n",           \
                          __FILE__,                             \
                          __LINE__,                             \
                          #exp,                                 \
                          #cond,                                \
                          atc_print_sql_retcode(atcSqlRet));    \
            atc_print_diagnostic(handleType, handle);           \
        }                                                       \
    }

#define ATC_SQL_EVAL(handleType, handle, exp)                   \
    ATC_SQL_EVAL_COND(handleType, handle, exp, == SQL_SUCCESS)

#endif /* _O_ATC_H_ */

