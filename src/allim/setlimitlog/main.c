#include <allimPoint.h>
#include <acp.h>

#define LINE_LENGTH 2048

enum
{
    SETLOG_OPTION_HELP    = 1,
    SETLOG_OPTION_PASS    = 2,
    SETLOG_OPTION_HIT     = 3,
    SETLOG_OPTION_SET     = 4,
    SETLOG_OPTION_LIMIT   = 5,
    SETLOG_OPTION_STACK   = 6,
    SETLOG_OPTION_REAL    = 7,
    SETLOG_OPTION_LOG     = 8,
    SETLOG_OPTION_ALL     = 9,
    SETLOG_OPTION_DISPLAY = 10
};

static acp_opt_def_t gOptDef[] =
{
    {
        SETLOG_OPTION_HELP,
        ACP_OPT_ARG_NOTEXIST,
        'h',
        "help",
        NULL,
        NULL,
        "Prints this help message."
    },
    {
        SETLOG_OPTION_PASS,
        ACP_OPT_ARG_REQUIRED,
        'p',
        "pass",
        NULL,
        "(on|off)",
        "Logs when passing limit point."
    },
    {
        SETLOG_OPTION_HIT,
        ACP_OPT_ARG_REQUIRED,
        'h',
        "hit",
        NULL,
        "(on|off)",
        "Logs when limit point is hit."
    },
    {
        SETLOG_OPTION_SET,
        ACP_OPT_ARG_REQUIRED,
        's',
        "set",
        NULL,
        "(on|off)",
        "Logs when limit point is set."
    },
    {
        SETLOG_OPTION_LIMIT,
        ACP_OPT_ARG_REQUIRED,
        'i',
        "limit",
        NULL,
        "(on|off)",
        "Logs when activating limit point."
    },
    {
        SETLOG_OPTION_STACK,
        ACP_OPT_ARG_REQUIRED,
        't',
        "callstack",
        NULL,
        "(on|off)",
        "Logs callstack when activating limitpoint."
    },
    {
        SETLOG_OPTION_REAL,
        ACP_OPT_ARG_REQUIRED,
        'r',
        "real",
        NULL,
        "(on|off)",
        "Logs when real limit situation is activated."
    },
    {
        SETLOG_OPTION_LOG,
        ACP_OPT_ARG_REQUIRED,
        'l',
        "log",
        NULL,
        "(on|off)",
        "Enables/disables logging."
    },
    {
        SETLOG_OPTION_ALL,
        ACP_OPT_ARG_REQUIRED,
        'a',
        "all",
        NULL,
        "(on|off)",
        "Turn on/off all logging. With this option, other "
            "options except -d are ignored."
    },
    {
        SETLOG_OPTION_DISPLAY,
        ACP_OPT_ARG_NOTEXIST,
        'd',
        "display",
        NULL,
        "(on|off)",
        "Displays current setting of logging."
    },
    ACP_OPT_SENTINEL
};

void printUsage(acp_char_t* aExe, acp_sint32_t aExit)
{
    acp_char_t sHelp[LINE_LENGTH];
    (void)acpPrintf("Usage : %s [options]\n", aExe);
    (void)acpOptHelp(gOptDef, NULL, sHelp, sizeof(sHelp) - 1);
    (void)acpPrintf("%s\n", sHelp);
    acpProcExit(aExit);
}

void displayLogState(void)
{
    acp_rc_t        sRC;
    acp_char_t      sFile[ACP_PATH_MAX_LENGTH] = {0, };
    acp_char_t      sID[ALLIM_LIMITPOINT_MAX_LENGTH] = {0, };
    acp_sint32_t    sCount;
    acp_sint32_t    sErrNo;

    acp_sint32_t    sLog;
    acp_sint32_t    sLogPass;
    acp_sint32_t    sLogHit;
    acp_sint32_t    sLogLimit;
    acp_sint32_t    sLogStack;
    acp_sint32_t    sLogSet;
    acp_sint32_t    sLogReal;

    sRC = allimGetLogging(&sLog, &sLogPass, &sLogHit, &sLogLimit, &sLogStack,
                          &sLogSet, &sLogReal);

    if(ACP_RC_IS_SUCCESS(sRC))
    {
        (void)acpPrintf("Logging             : [%s].\n",
                        (0 != sLog)?      "on" : "off");
        (void)acpPrintf("Passing limit point : [%s].\n",
                        (0 != sLogPass)?  "on" : "off");
        (void)acpPrintf("Limit point hit     : [%s].\n",
                        (0 != sLogHit)?   "on" : "off");
        (void)acpPrintf("Activate limitation : [%s].\n",
                        (0 != sLogLimit)? "on" : "off");
        (void)acpPrintf("Log callstack       : [%s].\n",
                        (0 != sLogStack)? "on" : "off");
        (void)acpPrintf("Limit point set     : [%s].\n",
                        (0 != sLogSet)?   "on" : "off");
        (void)acpPrintf("Real limitation     : [%s].\n",
                        (0 != sLogReal)?  "on" : "off");
    }
    else
    {
        (void)acpPrintf("Internal Error! : [error=%d]\n", sRC);
        acpProcExit(1);
    }
}

acp_sint32_t parseOnOff(acp_char_t* aArg)
{
    acp_sint32_t sR;
    if(0 == acpCStrCmp(aArg, "on", 2))
    {
        sR = 1;
    }
    else if(0 == acpCStrCmp(aArg, "off", 3))
    {
        sR = 0;
    }
    else
    {
        (void)acpPrintf("Invalid value [%s]!\n", aArg);
        acpProcExit(1);
    }

    return sR;
}

acp_sint32_t parseCmdLine(acp_sint32_t aArgc, acp_char_t** aArgv)
{
    acp_opt_t       sOpt;
    acp_rc_t        sRC;
    acp_sint32_t    sValue;
    acp_char_t*     sArg;

    acp_char_t      sFile[ACP_PATH_MAX_LENGTH] = {0, };
    acp_char_t      sID[ALLIM_LIMITPOINT_MAX_LENGTH] = {0, };
    acp_sint32_t    sErrNo;

    acp_sint32_t    sLog;
    acp_sint32_t    sLogPass;
    acp_sint32_t    sLogHit;
    acp_sint32_t    sLogLimit;
    acp_sint32_t    sLogStack;
    acp_sint32_t    sLogSet;
    acp_sint32_t    sLogReal;
    acp_sint32_t    sLogAll;

    acp_bool_t      sNeedSet     = ACP_FALSE;
    acp_bool_t      sNeedAll     = ACP_FALSE;
    acp_bool_t      sNeedDisplay = ACP_FALSE;
    acp_char_t      sError[LINE_LENGTH] = {0, };
  
    sRC = acpOptInit(&sOpt, aArgc, aArgv);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

    sRC = allimGetLogging(&sLog, &sLogPass, &sLogHit, &sLogLimit, &sLogStack,
                          &sLogSet, &sLogReal);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

    while(ACP_RC_IS_SUCCESS(sRC = acpOptGet(
                                &sOpt, gOptDef, NULL, &sValue,
                                &sArg, sError, sizeof(sError) - 1)))
    {
        switch(sValue)
        {
        case SETLOG_OPTION_HELP:
            printUsage(aArgv[0], 0);
            break;
        case SETLOG_OPTION_LOG:
            sLog = parseOnOff(sArg);
            sNeedSet = ACP_TRUE;
            break;
        case SETLOG_OPTION_PASS:
            sLogPass = parseOnOff(sArg);
            sNeedSet = ACP_TRUE;
            break;
        case SETLOG_OPTION_HIT:
            sLogHit = parseOnOff(sArg);
            sNeedSet = ACP_TRUE;
            break;
        case SETLOG_OPTION_LIMIT:
            sLogLimit = parseOnOff(sArg);
            sNeedSet = ACP_TRUE;
            break;
        case SETLOG_OPTION_STACK:
            sLogStack = parseOnOff(sArg);
            sNeedSet = ACP_TRUE;
            break;
        case SETLOG_OPTION_SET:
            sLogSet= parseOnOff(sArg);
            sNeedSet = ACP_TRUE;
            break;
        case SETLOG_OPTION_REAL:
            sLogReal = parseOnOff(sArg);
            sNeedSet = ACP_TRUE;
            break;
        case SETLOG_OPTION_ALL:
            sLogAll = parseOnOff(sArg);
            sNeedAll = ACP_TRUE;
            break;
        case SETLOG_OPTION_DISPLAY:
            sNeedDisplay = ACP_TRUE;
            break;
        default:
            ACP_RAISE(INVALIDARG);
            break;
        }
    }

    ACP_TEST_RAISE(ACP_RC_NOT_EOF(sRC), INVALIDARG);

    if(ACP_TRUE == sNeedAll)
    {
        sRC = allimEnableLogging(sLogAll);
        sRC = allimSetLogging(sLogAll, sLogAll, sLogAll, sLogAll, sLogAll, sLogAll);
    }
    else if(ACP_TRUE == sNeedSet)
    {
        sRC = allimEnableLogging(sLog);
        sRC = allimSetLogging(sLogPass, sLogHit, sLogLimit, sLogStack, sLogSet, sLogReal);
    }
    else
    {
        /* Do nothing */
    }

    if(ACP_TRUE == sNeedDisplay)
    {
        displayLogState();
    }
    else
    {
        /* Do nothing */
    }
    return 0;

    ACP_EXCEPTION(INVALIDARG);
    {
        (void)acpPrintf("Error encountered : %s\n", sError);
        printUsage(aArgv[0], 1);
    }

    ACP_EXCEPTION_END;
    (void)acpPrintf("Internal Error! : [error=%d]\n", sRC);
    acpProcExit(1);
}

acp_sint32_t main(acp_sint32_t aArgc, acp_char_t** aArgv)
{
    if(aArgc < 2)
    {
        printUsage(aArgv[0], 0);
    }
    else
    {
        parseCmdLine(aArgc, aArgv);
    }
    return 0;
}
