#include <allimPoint.h>
#include <acp.h>

#define LINE_LENGTH 2048

#define DISK_JUNK "/allimjunk.dat"

enum
{
    SETREAL_OPTION_HELP    = 1,
    SETREAL_OPTION_MEMORY  = 2,
    SETREAL_OPTION_PATH    = 3,
    SETREAL_OPTION_DISK    = 4,
    SETREAL_OPTION_DESC    = 5,
    SETREAL_OPTION_FREE    = 6,
    SETREAL_OPTION_DISPLAY = 7
};

static acp_opt_def_t gOptDef[] =
{
    {
        SETREAL_OPTION_HELP,
        ACP_OPT_ARG_NOTEXIST,
        'h',
        "help",
        NULL,
        NULL,
        "Prints this help message."
    },
    {
        SETREAL_OPTION_MEMORY,
        ACP_OPT_ARG_REQUIRED,
        'm',
        "memory",
        NULL,
        "(number|inf)",
        "Sets the amount of memory to be wasted in Kilo, Mega, Gigabytes. Can be inf[inity]."
    },
    {
        SETREAL_OPTION_PATH,
        ACP_OPT_ARG_REQUIRED,
        'p',
        "path",
        NULL,
        "pathname",
        "Sets the location of disk to be wasted."
    },
    {
        SETREAL_OPTION_DISK,
        ACP_OPT_ARG_REQUIRED,
        'k',
        "disk",
        NULL,
        "(number|inf)",
        "Sets the amount of disk to be wasted in Kilo, Mega, Giga, Terabytes. Can be inf[inity]."
    },
    {
        SETREAL_OPTION_DESC,
        ACP_OPT_ARG_REQUIRED,
        'e',
        "desc",
        NULL,
        "(number|inf)",
        "Sets the amount of descriptors to be wasted in numbers. Can be inf[inity]."
    },
    {
        SETREAL_OPTION_FREE,
        ACP_OPT_ARG_NOTEXIST,
        'f',
        "free",
        NULL,
        NULL,
        "Sets the amount of all wasted resources as 0."
    },
    {
        SETREAL_OPTION_DISPLAY,
        ACP_OPT_ARG_NOTEXIST,
        'd',
        "display",
        NULL,
        NULL,
        "Displays current setting of resource setting."
    },
    ACP_OPT_SENTINEL
};

void printUsage(acp_char_t* aExe, acp_sint32_t aExit)
{
    acp_char_t sHelp[LINE_LENGTH];
    (void)acpPrintf("Usage   : %s [options]\n", aExe);
    (void)acpPrintf("Example : %s -m 10k -d 1G -e inf\n", aExe);
    (void)acpOptHelp(gOptDef, NULL, sHelp, sizeof(sHelp) - 1);
    (void)acpPrintf("%s\n", sHelp);
    acpProcExit(aExit);
}

void displayReal(void)
{
    acp_rc_t        sRC;
    acp_char_t      sPath[ACP_PATH_MAX_LENGTH] = {0, };
    acp_sint64_t    sDestMemory;
    acp_sint64_t    sDestDisk;
    acp_sint64_t    sDestDesc;
    acp_sint64_t    sMemory;
    acp_sint64_t    sDisk;
    acp_sint64_t    sDesc;

    sRC = allimGetMemoryWaste(&sDestMemory, &sMemory);
    if(ACP_RC_IS_SUCCESS(sRC))
    {
        (void)allimGetDiskWaste(sPath, &sDestDisk, &sDisk);
        (void)allimGetDescWaste(&sDestDesc, &sDesc);
        (void)acpPrintf("Amount of memory waste     : %lld(%llX)/%lld(%llX)\n",
                        sMemory, sMemory, sDestMemory, sDestMemory);
        (void)acpPrintf("Amount of disk waste       : %lld(%llX)/%lld(%llX) on  [%s]\n",
                        sDisk, sDisk, sDestDisk, sDestDisk, sPath);
        (void)acpPrintf("Amount of descriptor waste : %lld(%llX)/%lld(%llX)\n",
                        sDesc, sDesc, sDestDesc, sDestDesc);
    }
    else
    {
        (void)acpPrintf("Internal Error! : [error=%d]\n", sRC);
        acpProcExit(1);
    }
}

void parseNumber(const char* aArg, acp_sint64_t* aValue)
{
    acp_sint32_t    sSign;
    acp_char_t*     sUnit;
    acp_rc_t        sRC;

    if(0 == acpCStrCmp(aArg, "inf", 3))
    {
        *aValue = ACP_SINT64_MAX;
    }
    else if(0 == acpCStrCmp(aArg, "-inf", 4))
    {
        *aValue = ACP_SINT64_LITERAL(0);
    }
    else
    {
        sRC = acpCStrToInt64(aArg, LINE_LENGTH,
                             &sSign, (acp_uint64_t*)aValue,
                             10, &sUnit);
        ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

        if(0 == acpCStrCmp(sUnit, "k", 1))
        {
            *aValue *= ACP_SINT64_LITERAL(1024);
        }
        else if(0 == acpCStrCmp(sUnit, "m", 1))
        {
            *aValue *= ACP_SINT64_LITERAL(1024) * 1024;
        }
        else if(0 == acpCStrCmp(sUnit, "g", 1))
        {
            *aValue *= ACP_SINT64_LITERAL(1024) * 1024 * 1024;
        }
        else if(0 == acpCStrCmp(sUnit, "t", 1))
        {
            *aValue *= ACP_SINT64_LITERAL(1024) * 1024 * 1024 * 1024;
        }
        else if(0 == acpCStrLen(sUnit, LINE_LENGTH))
        {
            /* Do nothing */
        }
        else
        {
            ACP_RAISE(E_UNITNOTRECOG);
        }
    }

    return;

    ACP_EXCEPTION(E_UNITNOTRECOG);
    ACP_EXCEPTION_END;

    acpPrintf("Invalid value : [%s] %s\n", aArg, sUnit);
    acpPrintf("Please refer to help!\n");
    acpProcExit(1);
}

void wasteDisk(const acp_char_t*    aPath,
               const acp_sint64_t   aWaste,
               acp_sint64_t*        aAfterWaste)
{
    static acp_char_t sJunk[1024] = {0xAA, 0x55, 0x55, 0xAA, 0,};

    acp_file_t      sFile;
    acp_offset_t    sOffset;
    acp_size_t      sWritten;
    acp_rc_t        sRC;
    acp_char_t      sPath[ACP_PATH_MAX_LENGTH];

    (void)acpCStrCpy(sPath,     ACP_PATH_MAX_LENGTH,
                     aPath,     ACP_PATH_MAX_LENGTH);
    (void)acpCStrCat(sPath,     ACP_PATH_MAX_LENGTH,
                     DISK_JUNK, ACP_PATH_MAX_LENGTH);

    sRC = acpFileOpen(&sFile, sPath, ACP_O_CREAT | ACP_O_RDWR, 0666);
    ACP_TEST_RAISE(ACP_RC_NOT_SUCCESS(sRC), E_CANNOTOPEN);
    sRC = acpFileSeek(&sFile, 0, ACP_SEEK_END, &sOffset);
    ACP_TEST_RAISE(ACP_RC_NOT_SUCCESS(sRC), E_CANNOTSEEK);

    if((acp_sint64_t)sOffset >= aWaste)
    {
        sRC = acpFileTruncate(&sFile, (acp_offset_t)aWaste);
        ACP_TEST_RAISE(ACP_RC_NOT_SUCCESS(sRC), E_CANNOTTRUNC);
    }
    else
    {
        while((acp_sint64_t)sOffset < aWaste)
        {
            sRC = acpFileWrite(&sFile, sJunk, sizeof(sJunk), &sWritten);
            if(ACP_RC_NOT_SUCCESS(sRC))
            {
                break;
            }
            else
            {
                sOffset += (acp_offset_t)sWritten;
            }
        }
    }

    if(ACP_RC_IS_SUCCESS(sRC) || ACP_RC_IS_ENOSPC(sRC))
    {
        sRC = acpFileSeek(&sFile, 0, ACP_SEEK_END, &sOffset);
        ACP_TEST_RAISE(ACP_RC_NOT_SUCCESS(sRC), E_CANNOTSEEK);
        *aAfterWaste = (acp_sint64_t)sOffset;
    }
    else
    {
        ACP_TEST_RAISE(ACP_RC_NOT_SUCCESS(sRC), E_CANNOTWRITE);
    }

    return;

    ACP_EXCEPTION(E_CANNOTOPEN)
    {
        acpPrintf("Error while opening file [%s]! errno=%d\n", sPath, sRC);
    }

    ACP_EXCEPTION(E_CANNOTSEEK)
    {
        acpPrintf("Error while scanning file [%s]! errno=%d\n", sPath, sRC);
    }

    ACP_EXCEPTION(E_CANNOTTRUNC)
    {
        acpPrintf("Error while truncating file [%s] to [%lld]! errno=%d\n", sPath, aWaste, sRC);
    }

    ACP_EXCEPTION(E_CANNOTWRITE)
    {
        acpPrintf("Error while writing file [%s]! errno=%d\n", sPath, sRC);
    }

    ACP_EXCEPTION_END;
    return;
}

acp_sint32_t parseCmdLine(acp_sint32_t aArgc, acp_char_t** aArgv)
{
    acp_opt_t       sOpt;
    acp_rc_t        sRC;
    acp_sint32_t    sValue;
    acp_char_t*     sArg;

    acp_char_t      sPath[ACP_PATH_MAX_LENGTH] = {0, };
    acp_bool_t      sNeedMemory  = ACP_FALSE;
    acp_bool_t      sNeedDisk    = ACP_FALSE;
    acp_bool_t      sNeedDesc    = ACP_FALSE;
    acp_bool_t      sNeedFree    = ACP_FALSE;
    acp_bool_t      sNeedDisplay = ACP_FALSE;
    acp_char_t      sError[LINE_LENGTH] = {0, };

    acp_sint64_t    sMemory;
    acp_sint64_t    sDisk;
    acp_sint64_t    sDesc;
    acp_sint64_t    sDummy;
  
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

    sRC = allimGetDiskWaste(sPath, &sDisk, &sDummy);
    ACP_TEST_RAISE(ACP_RC_NOT_SUCCESS(sRC), E_CANNOTREAD);

    while(ACP_RC_IS_SUCCESS(sRC = acpOptGet(
                                &sOpt, gOptDef, NULL, &sValue,
                                &sArg, sError, sizeof(sError) - 1)))
    {
        switch(sValue)
        {
        case SETREAL_OPTION_HELP:
            printUsage(aArgv[0], 0);
            break;
        case SETREAL_OPTION_MEMORY:
            sNeedMemory = ACP_TRUE;
            parseNumber(sArg, &sMemory);
            break;
        case SETREAL_OPTION_PATH:
            sNeedDisk = ACP_TRUE;
            acpCStrCpy(sPath, ACP_PATH_MAX_LENGTH, sArg, ACP_PATH_MAX_LENGTH);
            break;
        case SETREAL_OPTION_DISK:
            sNeedDisk = ACP_TRUE;
            parseNumber(sArg, &sDisk);
            break;
        case SETREAL_OPTION_DESC:
            sNeedDesc = ACP_TRUE;
            parseNumber(sArg, &sDesc);
            break;
        case SETREAL_OPTION_FREE:
            sNeedFree = ACP_TRUE;
            parseNumber(sArg, &sDesc);
            break;
        case SETREAL_OPTION_DISPLAY:
            sNeedDisplay = ACP_TRUE;
            break;
        default:
            ACP_RAISE(INVALIDARG);
            break;
        }
    }

    ACP_TEST_RAISE(ACP_RC_NOT_EOF(sRC), INVALIDARG);

    if(ACP_TRUE == sNeedFree)
    {
        ACP_TEST(ACP_RC_NOT_SUCCESS(allimSetMemoryWaste(0)));
        ACP_TEST(ACP_RC_NOT_SUCCESS(allimSetDiskWaste(sPath, 0)));
        ACP_TEST(ACP_RC_NOT_SUCCESS(allimSetDescWaste(0)));
    }
    else
    {
        if(ACP_TRUE == sNeedMemory)
        {
            ACP_TEST(ACP_RC_NOT_SUCCESS(allimSetMemoryWaste(sMemory)));
        }
        else
        {
            /* Do nothing */
        }
        if(ACP_TRUE == sNeedDisk)
        {
            (void)wasteDisk(sPath, sDisk, &sDisk);
            ACP_TEST(ACP_RC_NOT_SUCCESS(allimSetDiskWaste(sPath, sDisk)));
        }
        else
        {
            /* Do nothing */
        }
        if(ACP_TRUE == sNeedDesc)
        {
            ACP_TEST(ACP_RC_NOT_SUCCESS(allimSetDescWaste(sDesc)));
        }
        else
        {
            /* Do nothing */
        }
    }

    if(ACP_TRUE == sNeedDisplay)
    {
        displayReal();
    }
    else
    {
        /* Do nothing */
    }

    return;


    ACP_EXCEPTION(INVALIDARG);
    {
        (void)acpPrintf("Error encountered : %s\n", sError);
        printUsage(aArgv[0], 1);
    }
    ACP_EXCEPTION(E_CANNOTREAD)
    {
        (void)acpPrintf("Cannot read limit test shared memory : [errno=%d]\n", sRC);
    }
    ACP_EXCEPTION_END;
    (void)acpPrintf("Cannot set resources properly : [errno=%d]\n", sRC);
}

acp_sint32_t main(acp_sint32_t aArgc, acp_char_t** aArgv)
{
    acp_rc_t            sRC;
    acp_shm_t           sShm;
    allimPoint*         sPoint;

    if(aArgc < 2)
    {
        printUsage(aArgv[0], 0);
    }
    else
    {
        parseCmdLine(aArgc, aArgv);
    }


    sRC = allimGetSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
    sPoint = (allimPoint*)acpShmGetAddress(&sShm);
    sRC = allimReleaseSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
    return 0;

    ACP_EXCEPTION_END;
    return 1;
}
