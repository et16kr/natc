#include <allimPoint.h>
#include <acp.h>

#define LINE_LENGTH 2048

enum
{
    SETPOINT_OPTION_HELP    = 1,
    SETPOINT_OPTION_FILE    = 2,
    SETPOINT_OPTION_ID      = 3,
    SETPOINT_OPTION_COUNT   = 4,
    SETPOINT_OPTION_ERRNO   = 5,
    SETPOINT_OPTION_CLEAR   = 6,
    SETPOINT_OPTION_DISPLAY = 7
};

static acp_opt_def_t gOptDef[] =
{
    {
        SETPOINT_OPTION_HELP,
        ACP_OPT_ARG_NOTEXIST,
        'h',
        "help",
        NULL,
        NULL,
        "Prints this help message."
    },
    {
        SETPOINT_OPTION_FILE,
        ACP_OPT_ARG_REQUIRED,
        'f',
        "file",
        NULL,
        "filename",
        "Sets source file of limit point. Can be EVERYWHERE."
    },
    {
        SETPOINT_OPTION_ID,
        ACP_OPT_ARG_REQUIRED,
        'i',
        "id",
        NULL,
        "id",
        "Sets id of limit point. Can be EVERYWHERE."
    },
    {
        SETPOINT_OPTION_COUNT,
        ACP_OPT_ARG_REQUIRED,
        'c',
        "count",
        "1",
        "count",
        "Sets count of hit. Must be a number."
    },
    {
        SETPOINT_OPTION_ERRNO,
        ACP_OPT_ARG_REQUIRED,
        'e',
        "errno",
        "0",
        "errno",
        "Sets errno when limit point was hit. Must be a number."
    },
    {
        SETPOINT_OPTION_CLEAR,
        ACP_OPT_ARG_NOTEXIST,
        'k',
        "clear",
        NULL,
        NULL,
        "Clears limitpoint."
    },
    {
        SETPOINT_OPTION_DISPLAY,
        ACP_OPT_ARG_NOTEXIST,
        'd',
        "display",
        NULL,
        NULL,
        "Displays current setting of limitpoint."
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

void displayLimitPoint(void)
{
    acp_rc_t        sRC;
    acp_char_t      sFile[ACP_PATH_MAX_LENGTH] = {0, };
    acp_char_t      sID[ALLIM_LIMITPOINT_MAX_LENGTH] = {0, };
    acp_sint32_t    sCount;
    acp_sint32_t    sErrNo;

    sRC = allimPointGet(sFile, sID, &sCount, &sErrNo);
    if(ACP_RC_IS_SUCCESS(sRC))
    {
        (void)acpPrintf("Limit point file  : %s\n", sFile);
        (void)acpPrintf("Limit point id    : %s\n", sID);
        (void)acpPrintf("Limit point count : %d\n", sCount);
        (void)acpPrintf("Limit point errno : %d\n", sErrNo);
    }
    else
    {
        (void)acpPrintf("Cannot read shared memory! : [error=%d]\n", sRC);
        acpProcExit(1);
    }
}

acp_sint32_t parseCmdLine(acp_sint32_t aArgc, acp_char_t** aArgv)
{
    acp_opt_t       sOpt;
    acp_rc_t        sRC;
    acp_sint32_t    sValue;
    acp_char_t*     sArg;

    acp_char_t      sFile[ACP_PATH_MAX_LENGTH] = {0, };
    acp_char_t      sID[ALLIM_LIMITPOINT_MAX_LENGTH] = {0, };
    acp_sint32_t    sSign;
    acp_sint32_t    sCount = 1;
    acp_sint32_t    sErrNo;

    acp_bool_t      sNeedSet     = ACP_FALSE;
    acp_bool_t      sNeedClear   = ACP_FALSE;
    acp_bool_t      sNeedDisplay = ACP_FALSE;
    acp_char_t      sError[LINE_LENGTH] = {0, };
  
    sRC = acpOptInit(&sOpt, aArgc, aArgv);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

    while(ACP_RC_IS_SUCCESS(sRC = acpOptGet(
                                &sOpt, gOptDef, NULL, &sValue,
                                &sArg, sError, sizeof(sError) - 1)))
    {
        switch(sValue)
        {
        case SETPOINT_OPTION_HELP:
            printUsage(aArgv[0], 0);
            break;
        case SETPOINT_OPTION_FILE:
            (void)acpCStrCpy(sFile, ACP_PATH_MAX_LENGTH,
                             sArg,  ACP_PATH_MAX_LENGTH);
            sNeedSet = ACP_TRUE;
            break;
        case SETPOINT_OPTION_ID:
            (void)acpCStrCpy(sID,  ALLIM_LIMITPOINT_MAX_LENGTH,
                             sArg, ALLIM_LIMITPOINT_MAX_LENGTH);
            sNeedSet = ACP_TRUE;
            break;
        case SETPOINT_OPTION_COUNT:
            sRC = acpCStrToInt32(sArg, ALLIM_LIMITPOINT_MAX_LENGTH,
                                 &sSign, (acp_uint32_t*)&sCount, 10, NULL);
            if(ACP_RC_NOT_SUCCESS(sRC))
            {
                (void)acpPrintf("Invalid value for count : %s\n", sArg);
                printUsage(aArgv[0], 1);
            }
            sNeedSet = ACP_TRUE;
            break;
        case SETPOINT_OPTION_ERRNO:
            sRC = acpCStrToInt32(sArg, ALLIM_LIMITPOINT_MAX_LENGTH,
                                 &sSign, (acp_uint32_t*)&sErrNo, 10, NULL);
            if(ACP_RC_NOT_SUCCESS(sRC))
            {
                (void)acpPrintf("Invalid value for errno : %s\n", sArg);
                printUsage(aArgv[0], 1);
            }
            sNeedSet = ACP_TRUE;
            break;
        case SETPOINT_OPTION_CLEAR:
            sNeedClear = ACP_TRUE;
            break;
        case SETPOINT_OPTION_DISPLAY:
            sNeedDisplay = ACP_TRUE;
            break;
        default:
            ACP_RAISE(INVALIDARG);
            break;
        }
    }

    ACP_TEST_RAISE(ACP_RC_NOT_EOF(sRC), INVALIDARG);

    if(ACP_TRUE == sNeedClear)
    {
        sRC = allimPointClear();
        ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
    }
    else if(ACP_TRUE == sNeedSet)
    {
        /* if -k(--clear) was given, other options except display is ignored */
        sRC = allimPointSet(sFile, sID, sCount, sErrNo);
        ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
    }
    else
    {
        /* Do nothing */
    }

    if(ACP_TRUE == sNeedDisplay)
    {
        displayLimitPoint();
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
    (void)acpPrintf("Cannot read or set limit point! : [errno=%d]\n", sRC);
    acpProcExit(1);

    /* return -1; */
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
