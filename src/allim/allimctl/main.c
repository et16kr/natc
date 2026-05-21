#include <allimPoint.h>
#include <acp.h>

#define LINE_LENGTH 2048

acp_sint32_t gExitCode = 0;

enum
{
    ALLIMCTL_OPTION_HELP    = 1,
    ALLIMCTL_OPTION_CREATE  = 2,
    ALLIMCTL_OPTION_MEMORY  = 3,
    ALLIMCTL_OPTION_FILE    = 4,
    ALLIMCTL_OPTION_LOG     = 5,
    ALLIMCTL_OPTION_ALL     = 6,
    ALLIMCTL_OPTION_COPY    = 7,
    ALLIMCTL_OPTION_CLEANUP = 8
};

static acp_opt_def_t gOptDef[] =
{
    {
        ALLIMCTL_OPTION_HELP,
        ACP_OPT_ARG_NOTEXIST,
        'h',
        "help",
        NULL,
        NULL,
        "Prints this help message."
    },
    {
        ALLIMCTL_OPTION_CREATE,
        ACP_OPT_ARG_NOTEXIST,
        'c',
        "create",
        NULL,
        NULL,
        "Creates shared memory for limit test."
    },
    {
        ALLIMCTL_OPTION_MEMORY,
        ACP_OPT_ARG_NOTEXIST,
        'm',
        "memory",
        NULL,
        NULL,
        "Displays shared memory status for limit test."
    },
    {
        ALLIMCTL_OPTION_FILE,
        ACP_OPT_ARG_NOTEXIST,
        'f',
        "file",
        NULL,
        NULL,
        "Displays log file status for limit test."
    },
    {
        ALLIMCTL_OPTION_LOG,
        ACP_OPT_ARG_REQUIRED,
        'l',
        "log",
        NULL,
        "string",
        "Adds string to log"
    },
    {
        ALLIMCTL_OPTION_ALL,
        ACP_OPT_ARG_NOTEXIST,
        'a',
        "all",
        NULL,
        NULL,
        "Displays shared memory status and log file status for limit test."
    },
    {
        ALLIMCTL_OPTION_COPY,
        ACP_OPT_ARG_REQUIRED,
        'o',
        "copy",
        NULL,
        "filename",
        "Copies log file to filename."
    },
    {
        ALLIMCTL_OPTION_CLEANUP,
        ACP_OPT_ARG_NOTEXIST,
        'd',
        "destroy",
        NULL,
        NULL,
        "Cleans up log file and shared memory."
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

void createSharedMemory(void)
{
    acp_rc_t        sRC;
    acp_sint32_t    sKey;
    acp_bool_t      sProceeding;

    sProceeding = allimIsProceeding();
    ACP_TEST_RAISE(ACP_TRUE == sProceeding, E_EXIST);

    sKey = (acp_key_t)acpProcGetSelfID();
    while(ACP_RC_IS_EEXIST(sRC = allimCreate(sKey)))
    {
        sKey++;
    }
    ACP_TEST_RAISE(ACP_RC_NOT_SUCCESS(sRC), E_CANNOTCREATE);

    ACP_EXCEPTION(E_EXIST)
    {
        acpPrintf("Test already proceeding!\n");
        gExitCode = 1;
    }

    ACP_EXCEPTION(E_CANNOTCREATE)
    {
        acpPrintf("Cannot create shared memory : [errno=%d]\n", sRC);
        gExitCode = 1;
    }

    ACP_EXCEPTION_END;
}

void displayMemoryState(void)
{
    acp_rc_t        sRC;
    acp_shm_t       sShm;

    sRC = allimGetSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
    (void)acpPrintf("Shared memory status;\n");
#if !defined(VC_WIN32)
    (void)acpPrintf("\tID       : %X\n", sShm.mShmID);
#endif
    (void)acpPrintf("\tSize     : %d\n", sShm.mSize);
    (void)acpPrintf("\tAddress  : %p\n", sShm.mAddr);

    sRC = allimReleaseSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

    return;

    ACP_EXCEPTION_END;
    (void)acpPrintf("Cannot state shared memory! [errno=%d]\n", sRC);
    gExitCode = 1;
}

void displayFileState(void)
{
    acp_rc_t        sRC;
    acp_file_t      sFile;
    acp_stat_t      sStat;
    acp_char_t      sFilename[ACP_PATH_MAX_LENGTH];
    acp_char_t*     sDir;

    (void)acpPrintf("Log file : Environment[$%s/trc/allim.log];\n", ALLIM_LIMITTEST_LOGDIR);
    sRC = acpEnvGet(ALLIM_LIMITTEST_LOGDIR, &sDir);
    ACP_TEST_RAISE(ACP_RC_NOT_SUCCESS(sRC), E_NOENV);

    (void)acpCStrCpy(sFilename, ACP_PATH_MAX_LENGTH,
                     sDir,      ACP_PATH_MAX_LENGTH);
    (void)acpCStrCat(sFilename, ACP_PATH_MAX_LENGTH,
                     ALLIM_LIMITTEST_LOGFILE, ACP_PATH_MAX_LENGTH);

    (void)acpPrintf("\tFilename : %s\n", sFilename);

    sRC = allimOpenLog(&sFile);
    ACP_TEST_RAISE(ACP_RC_NOT_SUCCESS(sRC), E_CANNOTOPEN);

    sRC = acpFileStat(&sFile, &sStat);
    ACP_TEST_RAISE(ACP_RC_NOT_SUCCESS(sRC), E_CANNOTSTAT);

    (void)acpPrintf("\tSize     : %d\n", sStat.mSize);

    sRC = allimCloseLog(&sFile);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

    return;

    ACP_EXCEPTION(E_NOENV)
    {
        (void)acpPrintf("No environment for limit test [%s]\n"
                        "Please check your environment settings.\n",
                        ALLIM_LIMITTEST_LOGFILE);
    }

    ACP_EXCEPTION(E_CANNOTOPEN)
    {
        (void)acpPrintf("Cannot open log file! [errno=%d]\n", sRC);
    }

    ACP_EXCEPTION(E_CANNOTSTAT)
    {
        (void)allimCloseLog(&sFile);
        (void)acpPrintf("Cannot state log file! [errno=%d]\n", sRC);
    }

    ACP_EXCEPTION_END;
    gExitCode = 1;
}

void copyFile(acp_char_t* aDest)
{
    acp_rc_t        sRC;
    acp_char_t      sFilename[ACP_PATH_MAX_LENGTH];
    acp_char_t*     sDir;

    ACP_TEST_RAISE(ACP_RC_NOT_SUCCESS(sRC), E_NOENV);

    (void)acpCStrCpy(sFilename, ACP_PATH_MAX_LENGTH,
                     sDir,      ACP_PATH_MAX_LENGTH);
    (void)acpCStrCat(sFilename, ACP_PATH_MAX_LENGTH,
                     ALLIM_LIMITTEST_LOGFILE, ACP_PATH_MAX_LENGTH);

    sRC = acpFileCopy(sFilename, aDest, ACP_TRUE);
    ACP_TEST_RAISE(ACP_RC_NOT_SUCCESS(sRC), E_CANNOTCOPY);

    return;

    ACP_EXCEPTION(E_NOENV)
    {
        (void)acpPrintf("No environment for limit test [%s]\n"
                        "Please check your environment settings.\n",
                        ALLIM_LIMITTEST_LOGFILE);
    }

    ACP_EXCEPTION(E_CANNOTCOPY)
    {
        (void)acpPrintf("Cannot copy from from [%s] to [%s] "
                        "errno = [%d].",
                        sFilename, aDest, sRC);
    }

    ACP_EXCEPTION_END;
    gExitCode = 1;
}

void addLog(acp_char_t* sLine)
{
    acp_rc_t        sRC;
    acp_shm_t       sShm;
    allimPoint*     sPoint;

    sRC = allimGetSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
    sPoint = (allimPoint*)acpShmGetAddress(&sShm);

    sRC = allimLogWrite(sPoint, "%s\n", sLine);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

    sRC = allimReleaseSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

    return;

    ACP_EXCEPTION_END;
    (void)acpPrintf("Cannot add log! [errno=%d]\n", sRC);
    gExitCode = 1;
}

void cleanupResource(void)
{
    acp_rc_t        sRC;
    acp_shm_t       sShm;
    acp_char_t      sFilename[ACP_PATH_MAX_LENGTH];
    acp_char_t*     sDir;

    sRC = allimDestroy();
    if(ACP_RC_NOT_SUCCESS(sRC))
    {
        (void)acpPrintf("Cannot destroy shared memory! [errno=%d]\n"
                        "Please check whether other process is using it, "
                        "or the resources have been cleaned up.\n",
                        sRC);
        gExitCode = 1;
    }
    else
    {
        /* Do nothing */
    }

    sRC = acpEnvGet(ALLIM_LIMITTEST_LOGDIR, &sDir);
    ACP_TEST_RAISE(ACP_RC_NOT_SUCCESS(sRC), E_NOENV);

    (void)acpCStrCpy(sFilename, ACP_PATH_MAX_LENGTH,
                     sDir,      ACP_PATH_MAX_LENGTH);
    (void)acpCStrCat(sFilename, ACP_PATH_MAX_LENGTH,
                     ALLIM_LIMITTEST_SHMFILE, ACP_PATH_MAX_LENGTH);

    sRC = acpFileRemove(sFilename);
    ACP_TEST_RAISE(ACP_RC_NOT_SUCCESS(sRC), E_CANNOTREMOVE);

    /* All resources cleared. */
    return;

    ACP_EXCEPTION(E_NOENV)
    {
        (void)acpPrintf("No environment for limit test [%s]\n"
                        "Please check your environment settings.\n",
                        ALLIM_LIMITTEST_LOGFILE);
    }

    ACP_EXCEPTION(E_CANNOTREMOVE)
    {
        (void)acpPrintf("Cannot remove shm file [%s] [errno=%d]\n"
                        "Please check whether other process is using it, "
                        "or the resources have been cleaned up.\n",
                        sFilename, sRC);
    }

    ACP_EXCEPTION_END;
    gExitCode = 1;
}

acp_sint32_t parseCmdLine(acp_sint32_t aArgc, acp_char_t** aArgv)
{
    acp_opt_t       sOpt;
    acp_rc_t        sRC;
    acp_sint32_t    sValue;
    acp_char_t*     sArg;

    acp_char_t      sDest[ACP_PATH_MAX_LENGTH] = {0, };

    acp_bool_t      sNeedCreate  = ACP_FALSE;
    acp_bool_t      sNeedMem     = ACP_FALSE;
    acp_bool_t      sNeedFile    = ACP_FALSE;
    acp_bool_t      sNeedCopy    = ACP_FALSE;
    acp_bool_t      sNeedCleanup = ACP_FALSE;
    acp_char_t      sError[LINE_LENGTH] = {0, };
  
    sRC = acpOptInit(&sOpt, aArgc, aArgv);

    if(ACP_RC_NOT_SUCCESS(sRC))
    {
        (void)acpPrintf("Internal Error! : [error=%d]\n", sRC);
        acpProcExit(1);
    }
    else
    {
        /* Do nothing */
    }                      

    while(ACP_RC_IS_SUCCESS(sRC = acpOptGet(
                                &sOpt, gOptDef, NULL, &sValue,
                                &sArg, sError, sizeof(sError) - 1)))
    {
        switch(sValue)
        {
        case ALLIMCTL_OPTION_HELP:
            printUsage(aArgv[0], 0);
            break;
        case ALLIMCTL_OPTION_CREATE:
            sNeedCreate     = ACP_TRUE;
            break;
        case ALLIMCTL_OPTION_MEMORY:
            sNeedMem        = ACP_TRUE;
            break;
        case ALLIMCTL_OPTION_FILE:
            sNeedFile       = ACP_TRUE;
            break;
        case ALLIMCTL_OPTION_LOG:
            addLog(sArg);
            break;
        case ALLIMCTL_OPTION_ALL:
            sNeedMem        = ACP_TRUE;
            sNeedFile       = ACP_TRUE;
            break;
        case ALLIMCTL_OPTION_COPY:
            sNeedCopy       = ACP_TRUE;
            (void)acpCStrCpy(sDest, ACP_PATH_MAX_LENGTH, sArg, ACP_PATH_MAX_LENGTH);
            break;
        case ALLIMCTL_OPTION_CLEANUP:
            sNeedCleanup    = ACP_TRUE;
            break;
        default:
            break;
        }
    }

    if(ACP_RC_IS_EOF(sRC))
    {
        /* Do nothing */
    }
    else
    {
        (void)acpPrintf("Error encountered : %s\n", sError);
        printUsage(aArgv[0], 1);
    }

    if(ACP_TRUE == sNeedCreate)
    {
        createSharedMemory();
    }
    else
    {
        /* Do nothing */
    }

    if(ACP_TRUE == sNeedMem)
    {
        displayMemoryState();
    }
    else
    {
        /* DN */
    }

    if(ACP_TRUE == sNeedFile)
    {
        displayFileState();
    }
    else
    {
        /* DN */
    }

    if(ACP_TRUE == sNeedCopy)
    {
        copyFile(sDest);
    }
    else
    {
        /* DN */
    }

    if(ACP_TRUE == sNeedCleanup)
    {
        cleanupResource();
    }
    else
    {
        /* DN */
    }
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
    return gExitCode;
}
