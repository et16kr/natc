#include <allimPoint.h>
#include <acp.h>

#define ALLIM_SHM_FORMAT        "%X\n"
#define ALLIM_LINE_MAX_LENGTH   256
#define ALLIM_MAX_CALLSTACK     64
#define ALLIM_CALLSTACK_BEGIN   " [Callstack] =>\n"
#define ALLIM_CALLSTACK_MSG     "\tCallstack available on only GNU/Linux\n"
#define ALLIM_CALLSTACK_END     "======= Limitpoint callstack end =======\n"
#define ALLIM_LIMITPOINT_EVERY  "EVERYWHERE"

#define ALLIM_CHUNKSIZE         (1024 * 1024)
#define ALLIM_DISKJUNK          "allimjunk"
#define ALLIM_DESCMAX           (65536)

typedef struct allimWasteChunk
{
    struct allimWasteChunk* mPrev;
    struct allimWasteChunk* mNext;
} allimWasteChunk;

static acp_key_t    gKey = (acp_key_t)0;

ACP_EXPORT acp_rc_t allimCreateLog(acp_file_t* aFile)
{
    acp_rc_t        sRC;
    acp_file_t      sLog;
    acp_char_t      sLogPath[ACP_PATH_MAX_LENGTH];
    acp_char_t*     sLogDir;

    sRC = acpEnvGet(ALLIM_LIMITTEST_LOGDIR, &sLogDir);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
    (void)acpCStrCpy(sLogPath, ACP_PATH_MAX_LENGTH,
                     sLogDir,  ACP_PATH_MAX_LENGTH);
    (void)acpCStrCat(sLogPath, ACP_PATH_MAX_LENGTH,
                     ALLIM_LIMITTEST_LOGFILE, ACP_PATH_MAX_LENGTH);
    
    sRC = acpFileOpen(aFile, sLogPath, ACP_O_CREAT | ACP_O_APPEND, 0666);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

    return ACP_RC_SUCCESS;

    ACP_EXCEPTION_END;
    /* Failed to create or log file */
    return sRC;
}

ACP_EXPORT acp_rc_t allimOpenLog(acp_file_t* aFile)
{
    static acp_bool_t sOpened = ACP_FALSE;
    static acp_file_t sLog;

    acp_rc_t        sRC;

    if(ACP_FALSE == sOpened)
    {
        acp_char_t      sLogPath[ACP_PATH_MAX_LENGTH];
        acp_char_t*     sLogDir;

        sRC = acpEnvGet(ALLIM_LIMITTEST_LOGDIR, &sLogDir);
        ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
        (void)acpCStrCpy(sLogPath, ACP_PATH_MAX_LENGTH,
                         sLogDir,  ACP_PATH_MAX_LENGTH);
        (void)acpCStrCat(sLogPath, ACP_PATH_MAX_LENGTH,
                         ALLIM_LIMITTEST_LOGFILE, ACP_PATH_MAX_LENGTH);
        sRC = acpFileOpen(&sLog, sLogPath, ACP_O_RDWR | ACP_O_APPEND, 0666);
        ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

        sOpened = ACP_TRUE;
    }
    else
    {
        /* Do nothing */
    }

    *aFile = sLog;
    return ACP_RC_SUCCESS;

    ACP_EXCEPTION_END;
    /* Failed to open log file */
    return sRC;
}

ACP_EXPORT acp_rc_t allimCloseLog(acp_file_t* aFile)
{
#if defined(VC_WIN32)
    (void)acpFileSync(aFile);
#else
    (void)acpFileSync(aFile);
#endif
    /*
    sRC = acpFileClose(aFile);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
    */
    return ACP_RC_SUCCESS;
}

ACP_EXPORT acp_rc_t allimLogCallstack(allimPoint* aPoint)
{
    acp_rc_t        sRC;

    if(0 != aPoint->mLogStack)
    {
#if defined(ACP_CFG_OS_LINUX)
        acp_file_t      sLog;
        acp_sint32_t    sCount = ALLIM_MAX_CALLSTACK;
        void*           sCallstack[ALLIM_MAX_CALLSTACK];

        acpSpinLockLock(&(aPoint->mLogLock));

        sRC = allimOpenLog(&sLog);
        ACP_TEST_RAISE(ACP_RC_NOT_SUCCESS(sRC), E_CANNOTOPEN);
        sRC = acpFileSeek(&sLog, 0, ACP_SEEK_END, NULL);
        ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

        sRC = acpFileWrite(&sLog,
                           ALLIM_CALLSTACK_BEGIN,
                           acpCStrLen(ALLIM_CALLSTACK_BEGIN, ALLIM_LINE_MAX_LENGTH),
                           NULL);
        ACP_TEST_RAISE(ACP_RC_NOT_SUCCESS(sRC), E_CANNOTWRITE);

        sCount = backtrace(sCallstack, sCount);
        backtrace_symbols_fd(sCallstack, sCount, sLog.mHandle);

        sRC = acpFileWrite(&sLog,
                           ALLIM_CALLSTACK_END,
                           acpCStrLen(ALLIM_CALLSTACK_END, ALLIM_LINE_MAX_LENGTH),
                           NULL);
        ACP_TEST_RAISE(ACP_RC_NOT_SUCCESS(sRC), E_CANNOTWRITE);

        (void)allimCloseLog(&sLog);

        acpSpinLockUnlock(&(aPoint->mLogLock));
        ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
#else
        acp_file_t      sLog;
        acpSpinLockLock(&(aPoint->mLogLock));

        sRC = allimOpenLog(&sLog);
        ACP_TEST_RAISE(ACP_RC_NOT_SUCCESS(sRC), E_CANNOTOPEN);
        sRC = acpFileSeek(&sLog, 0, ACP_SEEK_END, NULL);
        ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

        sRC = acpFileWrite(&sLog,
                           ALLIM_CALLSTACK_BEGIN,
                           acpCStrLen(ALLIM_CALLSTACK_BEGIN, ALLIM_LINE_MAX_LENGTH),
                           NULL);
        ACP_TEST_RAISE(ACP_RC_NOT_SUCCESS(sRC), E_CANNOTWRITE);

        sRC = acpFileWrite(&sLog,
                           ALLIM_CALLSTACK_MSG,
                           acpCStrLen(ALLIM_CALLSTACK_MSG, ALLIM_LINE_MAX_LENGTH),
                           NULL);
        ACP_TEST_RAISE(ACP_RC_NOT_SUCCESS(sRC), E_CANNOTWRITE);

        sRC = acpFileWrite(&sLog,
                           ALLIM_CALLSTACK_END,
                           acpCStrLen(ALLIM_CALLSTACK_END, ALLIM_LINE_MAX_LENGTH),
                           NULL);
        ACP_TEST_RAISE(ACP_RC_NOT_SUCCESS(sRC), E_CANNOTWRITE);

        (void)allimCloseLog(&sLog);
        acpSpinLockUnlock(&(aPoint->mLogLock));
#endif
    }
    else
    {
        /* Do nothing */
    }

    return ACP_RC_SUCCESS;

    ACP_EXCEPTION(E_CANNOTOPEN)
    {
        acpSpinLockUnlock(&(aPoint->mLogLock));
    }

    ACP_EXCEPTION(E_CANNOTWRITE)
    {
        acpSpinLockUnlock(&(aPoint->mLogLock));
    }

    ACP_EXCEPTION_END;
    return sRC;
}

#define ALLIM_LOCK(aPoint) \
    if(aPoint!=NULL) { acpSpinLockLock(&(aPoint->mLogLock)); }
#define ALLIM_UNLOCK(aPoint) \
    if(aPoint!=NULL) { acpSpinLockUnlock(&(aPoint->mLogLock)); }

ACP_EXPORT acp_rc_t allimLogWrite(allimPoint*          aPoint,
                       const acp_char_t*    aFormat,
                       ...)
{
    acp_file_t      sLog;
    acp_rc_t        sRC;
    acp_time_exp_t  sExpTime;
    va_list         sArgs;

    acp_char_t      sBuffer1[ALLIM_LINE_MAX_LENGTH];
    acp_char_t      sBuffer2[ALLIM_LINE_MAX_LENGTH];

    acpTimeGetLocalTime(acpTimeNow(), &sExpTime);
    (void)acpSnprintf(sBuffer1, ALLIM_LINE_MAX_LENGTH,
                      "[%04d-%02d-%02d %02d:%02d:%02d] %s",
                      sExpTime.mYear, sExpTime.mMonth, sExpTime.mDay,
                      sExpTime.mHour, sExpTime.mMin, sExpTime.mSec,
                      aFormat);
    va_start(sArgs, aFormat);
    sRC = acpVsnprintf(sBuffer2, ALLIM_LINE_MAX_LENGTH, sBuffer1, sArgs);
    va_end(sArgs);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

    ALLIM_LOCK(aPoint);

    sRC = allimOpenLog(&sLog);
    ACP_TEST_RAISE(ACP_RC_NOT_SUCCESS(sRC), E_CANNOTOPEN);
    sRC = acpFileSeek(&sLog, 0, ACP_SEEK_END, NULL);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
    sRC = acpFileWrite(&sLog,
                       sBuffer2,
                       acpCStrLen(sBuffer2, ALLIM_LINE_MAX_LENGTH),
                       NULL);
    ACP_TEST_RAISE(ACP_RC_NOT_SUCCESS(sRC), E_CANNOTWRITE);

    sRC = allimCloseLog(&sLog);
    ACP_TEST_RAISE(ACP_RC_NOT_SUCCESS(sRC), E_CANNOTCLOSE);

    ALLIM_UNLOCK(aPoint);
    return ACP_RC_SUCCESS;

    ACP_EXCEPTION(E_CANNOTOPEN)
    {
        ALLIM_UNLOCK(aPoint);
    }

    ACP_EXCEPTION(E_CANNOTWRITE)
    {
        ALLIM_UNLOCK(aPoint);
    }

    ACP_EXCEPTION(E_CANNOTCLOSE)
    {
        ALLIM_UNLOCK(aPoint);
    }

    ACP_EXCEPTION_END;
    return sRC;
}

ACP_EXPORT acp_bool_t allimIsProceeding(void)
{
    acp_rc_t    sRC;
    acp_shm_t   sShm;

    sRC = allimGetSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
    (void)allimReleaseSharedMemory(&sShm);

    return ACP_TRUE;

    ACP_EXCEPTION_END;
    allimLogWrite(NULL, "Altibase limit test not running!\n");
    return ACP_FALSE;
}

#define ALLIM_GETERRMSG(aRC, aLine) \
    acpErrorString(aRC, aLine, ALLIM_LINE_MAX_LENGTH)

ACP_EXPORT acp_rc_t allimGetSharedMemory(acp_shm_t* aShm)
{
    acp_rc_t        sRC;
    acp_sint32_t    sSign;
    acp_uint32_t    sKey;
    acp_file_t      sShmLog;
    acp_char_t*     sShmLogDir;
    acp_char_t      sShmLogPath[ACP_PATH_MAX_LENGTH];
    acp_char_t      sLine[ALLIM_LINE_MAX_LENGTH];

    if((acp_key_t)0 == acpAtomicGet32((acp_sint32_t*)&gKey))
    {
        sRC = acpEnvGet(ALLIM_LIMITTEST_LOGDIR, &sShmLogDir);
        ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
        (void)acpCStrCpy(sShmLogPath, ACP_PATH_MAX_LENGTH,
                         sShmLogDir,  ACP_PATH_MAX_LENGTH);
        (void)acpCStrCat(sShmLogPath, ACP_PATH_MAX_LENGTH,
                         ALLIM_LIMITTEST_SHMFILE, ACP_PATH_MAX_LENGTH);

        sRC = acpFileOpen(&sShmLog, sShmLogPath, ACP_O_RDONLY, 0666);
        ACP_TEST_RAISE(ACP_RC_NOT_SUCCESS(sRC), E_CANNOTOPENLOG);

        sRC = acpFileRead(&sShmLog, sLine, ALLIM_LINE_MAX_LENGTH, NULL);
        ACP_TEST_RAISE(ACP_RC_NOT_SUCCESS(sRC), E_CANNOTREADLOG);

        sRC = acpCStrToInt32(sLine, ALLIM_LINE_MAX_LENGTH,
                              &sSign, &sKey,
                              16, NULL);
        ACP_TEST_RAISE(ACP_RC_NOT_SUCCESS(sRC), E_CANNOTCONVERT);

        (void)acpFileClose(&sShmLog);
        acpAtomicSet32((acp_sint32_t*)&(gKey), (acp_sint32_t)sKey);
    }
    else
    {
        /* Just attach */
    }

#if defined(ACP_CFG_OS_HPUX)
    do
    {
        sRC = acpShmAttach(aShm, gKey);
    } while(ACP_RC_IS_EINVAL(sRC));
#else
    sRC = acpShmAttach(aShm, gKey);
#endif

    ACP_TEST_RAISE(ACP_RC_NOT_SUCCESS(sRC), E_CANNOTATTACH);

    return ACP_RC_SUCCESS;

    ACP_EXCEPTION(E_CANNOTOPENLOG)
    {
        ALLIM_GETERRMSG(sRC, sLine);
        allimLogWrite(NULL, "Cannot open log : %d(%s)\n", sRC, sLine);
    }

    ACP_EXCEPTION(E_CANNOTREADLOG)
    {
        ALLIM_GETERRMSG(sRC, sLine);
        allimLogWrite(NULL, "Cannot read log : %d(%s)\n", sRC, sLine);
    }

    ACP_EXCEPTION(E_CANNOTCONVERT)
    {
        allimLogWrite(NULL, "Cannot convert shmid : %s\n", sLine);
    }

    ACP_EXCEPTION(E_CANNOTATTACH)
    {
        ALLIM_GETERRMSG(sRC, sLine);
        allimLogWrite(NULL, "Cannot attach shared memory with key [%X] "
                      ": %d(%s)\n",
                      gKey, sRC, sLine);
    }

    ACP_EXCEPTION_END;
    return sRC;
}

ACP_EXPORT acp_rc_t allimReleaseSharedMemory(acp_shm_t* aShm)
{
    return acpShmDetach(aShm);
}

ACP_EXPORT acp_rc_t allimCreate(acp_key_t aKey)
{
    acp_rc_t            sRC;
    acp_shm_t           sShm;
    acp_file_t          sLog;
    allimPoint*         sPoint;
#if defined(VC_WIN32)
    acp_char_t          sTemp[1024];
#endif

    acp_spin_lock_t     sSpinlockInit = ACP_SPIN_LOCK_INITIALIZER(-1);

    /* Log shared memory ID */
    sRC = allimCreateLog(&sLog);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

    /* Create shared memory */
    sRC = acpShmCreate(aKey, ALLIM_SHAREDMEMORY_SIZE, 0666);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

    sRC = acpShmAttach(&sShm, aKey);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

    /* Initialize allimPoint */
    sPoint = (allimPoint*)acpShmGetAddress(&sShm);
    acpMemSet(sPoint, 0, ALLIM_SHAREDMEMORY_SIZE);
    sPoint->mLog        = 1;
    sPoint->mLogPass    = 0;
    sPoint->mLogHit     = 1;
    sPoint->mLogLimit   = 1;
    sPoint->mLogStack   = 1;
    sPoint->mLogSet     = 1;
    sPoint->mLogReal    = 1;

    acpMemCpy(&(sPoint->mLock),    &sSpinlockInit, sizeof(acp_spin_lock_t));
    acpMemCpy(&(sPoint->mLogLock), &sSpinlockInit, sizeof(acp_spin_lock_t));

    sRC = allimCloseLog(&sLog);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

    sRC = allimLogWrite(sPoint, ALLIM_SHM_FORMAT, aKey);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

    /* Log shared memory ID to shared memory log file */
    {
        acp_file_t      sShmLog;
        acp_char_t*     sShmLogDir;
        acp_char_t      sShmLogPath[ACP_PATH_MAX_LENGTH];
        acp_char_t      sLine[ALLIM_LINE_MAX_LENGTH];

        sRC = acpEnvGet(ALLIM_LIMITTEST_LOGDIR, &sShmLogDir);
        ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
        (void)acpCStrCpy(sShmLogPath, ACP_PATH_MAX_LENGTH,
                         sShmLogDir,  ACP_PATH_MAX_LENGTH);
        (void)acpCStrCat(sShmLogPath, ACP_PATH_MAX_LENGTH,
                         ALLIM_LIMITTEST_SHMFILE, ACP_PATH_MAX_LENGTH);

        sRC = acpFileOpen(&sShmLog, sShmLogPath,
                          ACP_O_CREAT | ACP_O_TRUNC | ACP_O_RDWR, 0666);
        ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

        sRC = acpSnprintf(sLine, ALLIM_LINE_MAX_LENGTH, ALLIM_SHM_FORMAT, aKey);
        ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

        sRC = acpFileWrite(&sShmLog, sLine,
                           acpCStrLen(sLine, ALLIM_LINE_MAX_LENGTH), NULL);
        ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

        sRC = acpFileClose(&sShmLog);
        ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
    }

    /* Release shared memory */
    sRC = acpShmDetach(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

    acpAtomicSet32((acp_sint32_t*)&(gKey), (acp_sint32_t)aKey);

    return ACP_RC_SUCCESS;

    ACP_EXCEPTION_END;
    /* Failed to create or attach shared memory */
    return sRC;
}

ACP_EXPORT acp_rc_t allimDestroy(void)
{
    acp_rc_t        sRC;
    acp_key_t       sKey;

    if(ACP_TRUE)/* ((acp_key_t)0 == gKey) */
    {
        acp_sint32_t    sSign;
        acp_file_t      sLog;
        acp_char_t*     sShmLogDir;
        acp_char_t      sShmLogPath[ACP_PATH_MAX_LENGTH];
        acp_char_t      sLine[ALLIM_LINE_MAX_LENGTH];

        sRC = acpEnvGet(ALLIM_LIMITTEST_LOGDIR, &sShmLogDir);
        ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
        (void)acpCStrCpy(sShmLogPath, ACP_PATH_MAX_LENGTH,
                         sShmLogDir,  ACP_PATH_MAX_LENGTH);
        (void)acpCStrCat(sShmLogPath, ACP_PATH_MAX_LENGTH,
                         ALLIM_LIMITTEST_SHMFILE, ACP_PATH_MAX_LENGTH);

        sRC = acpFileOpen(&sLog, sShmLogPath, ACP_O_RDONLY, 0666);
        ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

        sRC = acpFileSeek(&sLog, 0, ACP_SEEK_SET, NULL);
        ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

        sRC = acpFileRead(&sLog, sLine, ALLIM_LINE_MAX_LENGTH, NULL);
        ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

        sRC = acpCStrToInt32(sLine, ALLIM_LINE_MAX_LENGTH,
                              &sSign, (acp_uint32_t*)&sKey,
                              16, NULL);
        ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

        sRC = allimCloseLog(&sLog);
        ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
    }
    else
    {
        sKey = gKey;
    }

    sRC = acpShmDestroy(sKey);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

    return ACP_RC_SUCCESS;

    ACP_EXCEPTION(E_SCANFAIL)
    {
        sRC = ACP_RC_GET_OS_ERROR();
    }
    ACP_EXCEPTION_END;
    return sRC;
}

ACP_EXPORT acp_rc_t allimPointSet(const acp_char_t*     aFile,
                       const acp_char_t*     aID,
                       const acp_sint32_t    aCount,
                       const acp_sint32_t    aErrNo)
{
    acp_sint32_t        i;
    acp_rc_t            sRC;
    acp_shm_t           sShm;

    allimPoint*         sPoint;

    sRC = allimGetSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

    sPoint = (allimPoint*)acpShmGetAddress(&sShm);

    acpSpinLockLock(&(sPoint->mLock));

    if(0 < acpCStrLen(aFile, ACP_PATH_MAX_LENGTH))
    {
        acpCStrCpy(sPoint->mFile, ACP_PATH_MAX_LENGTH,
                   aFile,         ACP_PATH_MAX_LENGTH);
    }
    else
    {
        /* Do nothing */
    }
    if(0 < acpCStrLen(aID, ALLIM_LIMITPOINT_MAX_LENGTH))
    {
        acpCStrCpy(sPoint->mID,   ALLIM_LIMITPOINT_MAX_LENGTH,
                   aID,           ALLIM_LIMITPOINT_MAX_LENGTH);
    }
    else
    {
        /* Do nothing */
    }
    acpAtomicSet32(&(sPoint->mCount), aCount);
    acpAtomicSet32(&(sPoint->mErrNo), aErrNo);

    for(i = 0; i <  ALLIM_LIMITPOINT_MAX_THREADS; i++)
    {
        acpAtomicSet32(&(sPoint->mHitCounts[i]), aCount);
    }

    if((0 != sPoint->mLog) && (0 != sPoint->mLogSet))
    {
        (void)allimLogWrite(
            sPoint,
            "Setting limit point as %s::%s, count %d with errno [%d].\n", 
            aFile, aID, aCount, aErrNo);
    }
    else
    {
        /* Not logging */
    }

    acpSpinLockUnlock(&(sPoint->mLock));
    sRC = allimReleaseSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
    return ACP_RC_SUCCESS;

    ACP_EXCEPTION_END;
    return sRC;
}

ACP_EXPORT acp_rc_t allimPointGet(acp_char_t*     aFile,
                       acp_char_t*     aID,
                       acp_sint32_t*   aCount,
                       acp_sint32_t*   aErrNo)
{
    acp_sint32_t        i;
    acp_rc_t            sRC;
    acp_shm_t           sShm;

    allimPoint*         sPoint;

    sRC = allimGetSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

    sPoint = (allimPoint*)acpShmGetAddress(&sShm);

    acpSpinLockLock(&(sPoint->mLock));

    acpCStrCpy(aFile        , ACP_PATH_MAX_LENGTH,
               sPoint->mFile, ACP_PATH_MAX_LENGTH);
    acpCStrCpy(aID          , ALLIM_LIMITPOINT_MAX_LENGTH,
               sPoint->mID  , ALLIM_LIMITPOINT_MAX_LENGTH);
    *aCount = acpAtomicGet32(&(sPoint->mCount));
    *aErrNo = acpAtomicGet32(&(sPoint->mErrNo));

    acpSpinLockUnlock(&(sPoint->mLock));
    sRC = allimReleaseSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
    return ACP_RC_SUCCESS;

    ACP_EXCEPTION_END;
    return sRC;
}

ACP_EXPORT acp_rc_t allimPointClear(void)
{
    acp_rc_t            sRC;
    acp_shm_t           sShm;
    allimPoint*    sPoint;

    sRC = allimGetSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

    sPoint = (allimPoint*)acpShmGetAddress(&sShm);
    acpSpinLockLock(&(sPoint->mLock));

    acpMemSet(sPoint->mFile, 0, ACP_PATH_MAX_LENGTH);
    acpMemSet(sPoint->mID, 0, ALLIM_LIMITPOINT_MAX_LENGTH);
    acpAtomicSet32(&(sPoint->mCount), 0);
    acpAtomicSet32(&(sPoint->mErrNo), 0);

    if((0 != sPoint->mLog) && (0 != sPoint->mLogSet))
    {
        (void)allimLogWrite(
            sPoint,
            "Clearing limit point.\n");
    }
    else
    {
        /* Not logging */
    }

    acpSpinLockUnlock(&(sPoint->mLock));
    sRC = allimReleaseSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
    return ACP_RC_SUCCESS;

    ACP_EXCEPTION_END;
    return sRC;
}

ACP_EXPORT acp_rc_t allimPointPass(const acp_char_t*   aFile,
                        const acp_char_t*   aID,
                        acp_sint32_t*       aErrNo,
                        acp_bool_t*         aHit)
{
    acp_sint32_t        i;

    acp_rc_t            sRC;
    acp_shm_t           sShm;
    acp_sint32_t        sHitCount;
    acp_uint64_t        sThrID;
    allimPoint*         sPoint;

    *aErrNo = 0;
    *aHit   = ACP_FALSE;

    sRC = allimGetSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

    sPoint = (allimPoint*)acpShmGetAddress(&sShm);
    acpSpinLockLock(&(sPoint->mLock));

    if((0 != sPoint->mLog) && (0 != sPoint->mLogPass))
    {
        (void)allimLogWrite(
            sPoint,
            "Passing limit point %s::%s.\n",
            aFile, aID);
    }
    else
    {
        /* Not logging */
    }

    sThrID = acpThrGetSelfID();
    for(i = 0; i < ALLIM_LIMITPOINT_MAX_THREADS; i++)
    {
        if((sThrID == sPoint->mThreadIDs[i]) || (0 == sPoint->mThreadIDs[i]))
        {
            break;
        }
        else
        {
            /* continue; */
        }
    }

    ACP_TEST_RAISE(ALLIM_LIMITPOINT_MAX_THREADS == i, E_NOSPC);

    acpAtomicSet64(&(sPoint->mThreadIDs[i]), sThrID);
    if(0 == acpCStrCmp(sPoint->mFile,
                       ALLIM_LIMITPOINT_EVERY,
                       sizeof(sPoint->mFile))
       )
    {
        *aErrNo = acpAtomicGet32(&(sPoint->mErrNo));
        *aHit   = ACP_TRUE;
    }
    else
    {
        /*
         * pass directory 
         * acp has no strstr in current version.
         */
        acp_char_t* sNext;
#if defined(VC_WIN32)
	sNext = strstr(aFile, "\\");

	if( sNext == NULL )
	{
            while(NULL != (sNext = strstr(aFile, "/")))
          	aFile = sNext + 1;
	}
	else
	{
          aFile = sNext + 1;
	}	
#else
        while(NULL != (sNext = strstr(aFile, "/")))
            aFile = sNext + 1;
#endif
        if(0 == acpCStrCmp(sPoint->mFile, aFile, sizeof(sPoint->mFile)))
        {
            if(0 == acpCStrCmp(sPoint->mID,
                               ALLIM_LIMITPOINT_EVERY,
                               sizeof(sPoint->mID))
               )
            {
                *aErrNo = acpAtomicGet32(&(sPoint->mErrNo));
                *aHit   = ACP_TRUE;
            }
            else
            {
                if(0 == acpCStrCmp(sPoint->mID, aID, sizeof(sPoint->mID)))
                {
                    sHitCount = acpAtomicDec32(&(sPoint->mHitCounts[i]));
                    if((0 != sPoint->mLog) && (0 != sPoint->mLogHit))
                    {
                        (void)allimLogWrite(
                            sPoint,
                            "Limit point hit! %s::%s, count is %d.\n", 
                            sPoint->mFile, sPoint->mID, sHitCount);
                    }
                    else
                    {
                        /* Not logging */
                    }

                    if(0 == sHitCount)
                    {
                        if((0 != sPoint->mLog) && (0 != sPoint->mLogLimit))
                        {
                            (void)allimLogWrite(
                                sPoint,
                                "Activating limit point! Setting errno as [%d].",
                                acpAtomicGet32(&(sPoint->mErrNo)));
                            (void)allimLogCallstack(sPoint);
                        }
                        else
                        {
                            /* Not logging */
                        }

                        *aErrNo = acpAtomicGet32(&(sPoint->mErrNo));
                        *aHit   = ACP_TRUE;
                        (void)acpAtomicSet32(&(sPoint->mHitCounts[i]),
                                             acpAtomicGet32(&sPoint->mCount));
                    }
                    else
                    {
                        /* Hit but count not match */
                    }
                }
                else
                {
                    /* Not hit! */
                }
            }
        }
    }

    acpSpinLockUnlock(&(sPoint->mLock));
    sRC = allimReleaseSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
    return ACP_RC_SUCCESS;

    ACP_EXCEPTION(E_NOSPC)
    {
        sRC = ACP_RC_ENOSPC;
        acpSpinLockUnlock(&(sPoint->mLock));
        (void)allimReleaseSharedMemory(&sShm);
    }

    ACP_EXCEPTION_END;
    return sRC;
}

ACP_EXPORT acp_rc_t allimPointDone(void)
{
    acp_sint32_t        i;

    acp_rc_t            sRC;
    acp_shm_t           sShm;
    acp_sint32_t        sCount;
    acp_uint64_t        sThrID;
    allimPoint*         sPoint;

    sRC = allimGetSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

    sPoint = (allimPoint*)acpShmGetAddress(&sShm);
    acpSpinLockLock(&(sPoint->mLock));

    sThrID = acpThrGetSelfID();
    for(i = 0; i < ALLIM_LIMITPOINT_MAX_THREADS; i++)
    {
        if((sThrID == sPoint->mThreadIDs[i]) || (0 == sPoint->mThreadIDs[i]))
        {
            break;
        }
        else
        {
            /* continue; */
        }
    }

    ACP_TEST_RAISE(ALLIM_LIMITPOINT_MAX_THREADS == i, E_NOSPC);

    acpAtomicSet64(&(sPoint->mThreadIDs[i]), 0);

    acpSpinLockUnlock(&(sPoint->mLock));
    sRC = allimReleaseSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
    return ACP_RC_SUCCESS;

    ACP_EXCEPTION(E_NOSPC)
    {
        sRC = ACP_RC_ENOSPC;
        acpSpinLockUnlock(&(sPoint->mLock));
        (void)allimReleaseSharedMemory(&sShm);
    }

    ACP_EXCEPTION_END;
    return sRC;
}

ACP_EXPORT acp_rc_t allimEnableLogging(const acp_sint32_t aLog)
{
    acp_sint32_t        i;

    acp_rc_t            sRC;
    acp_shm_t           sShm;
    acp_sint32_t        sCount;
    acp_uint64_t        sThrID;
    allimPoint*         sPoint;

    sRC = allimGetSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

    sPoint = (allimPoint*)acpShmGetAddress(&sShm);
    acpSpinLockLock(&(sPoint->mLock));

    acpAtomicSet32(&(sPoint->mLog), aLog);

    if(0 != sPoint->mLog)
    {
        (void)allimLogWrite(sPoint, "Logging enabled.\n");
    }
    else
    {
        (void)allimLogWrite(sPoint, "Logging disabled.\n");
    }


    acpSpinLockUnlock(&(sPoint->mLock));
    sRC = allimReleaseSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
    return ACP_RC_SUCCESS;

    ACP_EXCEPTION_END;
    return sRC;
}

ACP_EXPORT acp_rc_t allimSetLogging(const acp_sint32_t aLogPass,
                         const acp_sint32_t aLogHit,
                         const acp_sint32_t aLogLimit,
                         const acp_sint32_t aLogStack,
                         const acp_sint32_t aLogSet,
                         const acp_sint32_t aLogReal)
{
    acp_sint32_t        i;

    acp_rc_t            sRC;
    acp_shm_t           sShm;
    acp_sint32_t        sCount;
    acp_uint64_t        sThrID;
    allimPoint*         sPoint;

    sRC = allimGetSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

    sPoint = (allimPoint*)acpShmGetAddress(&sShm);
    acpSpinLockLock(&(sPoint->mLock));

    acpAtomicSet32(&(sPoint->mLogPass),     aLogPass);
    acpAtomicSet32(&(sPoint->mLogHit),      aLogHit);
    acpAtomicSet32(&(sPoint->mLogLimit),    aLogLimit);
    acpAtomicSet32(&(sPoint->mLogStack),    aLogStack);
    acpAtomicSet32(&(sPoint->mLogSet),      aLogSet);
    acpAtomicSet32(&(sPoint->mLogReal),     aLogReal);

    if(0 != sPoint->mLog)
    {
        (void)allimLogWrite(sPoint, "Setting logging as;\n");
        (void)allimLogWrite(sPoint, "\tPassing limit point : [%s].\n",
                            (0 != aLogPass)?  "Enabled"    : "Disabled");
        (void)allimLogWrite(sPoint, "\tLimit point hit     : [%s].\n",
                            (0 != aLogHit)?   "Enabled"    : "Disabled");
        (void)allimLogWrite(sPoint, "\tActivate limitation : [%s].\n",
                            (0 != aLogLimit)? "Enabled"    : "Disabled");
        (void)allimLogWrite(sPoint, "\tLog callstack       : [%s].\n",
                            (0 != aLogStack)? "Enabled"    : "Disabled");
        (void)allimLogWrite(sPoint, "\tLimit point set     : [%s].\n",
                            (0 != aLogSet)?   "Enabled"    : "Disabled");
        (void)allimLogWrite(sPoint, "\tReal limitation     : [%s].\n",
                            (0 != aLogReal)? "Enabled"     : "Disabled");
    }
    else
    {
        /* Not logging */
    }

    acpSpinLockUnlock(&(sPoint->mLock));
    sRC = allimReleaseSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
    return ACP_RC_SUCCESS;

    ACP_EXCEPTION_END;
    return sRC;
}

ACP_EXPORT acp_rc_t allimGetLogging(acp_sint32_t* aLog,
                         acp_sint32_t* aLogPass,
                         acp_sint32_t* aLogHit,
                         acp_sint32_t* aLogLimit,
                         acp_sint32_t* aLogStack,
                         acp_sint32_t* aLogSet,
                         acp_sint32_t* aLogReal)
{
    acp_sint32_t        i;

    acp_rc_t            sRC;
    acp_shm_t           sShm;
    acp_sint32_t        sCount;
    acp_uint64_t        sThrID;
    allimPoint*         sPoint;

    sRC = allimGetSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

    sPoint = (allimPoint*)acpShmGetAddress(&sShm);
    acpSpinLockLock(&(sPoint->mLock));

    *aLog      = acpAtomicGet32(&(sPoint->mLog));
    *aLogPass  = acpAtomicGet32(&(sPoint->mLogPass));
    *aLogHit   = acpAtomicGet32(&(sPoint->mLogHit));
    *aLogLimit = acpAtomicGet32(&(sPoint->mLogLimit));
    *aLogStack = acpAtomicGet32(&(sPoint->mLogStack));
    *aLogSet   = acpAtomicGet32(&(sPoint->mLogSet));
    *aLogReal  = acpAtomicGet32(&(sPoint->mLogReal));

    acpSpinLockUnlock(&(sPoint->mLock));
    sRC = allimReleaseSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
    return ACP_RC_SUCCESS;

    ACP_EXCEPTION_END;
    return sRC;
}

static void allimWasteMemory(allimWasteChunk**  aHead,
                             acp_sint64_t       aCurrent,
                             acp_sint64_t       aDest,
                             acp_sint64_t*      aAfter)
{
    acp_rc_t            sRC;
    acp_size_t          sSize = ALLIM_CHUNKSIZE;
    allimWasteChunk*    sTemp;

    while((aCurrent < aDest) && (sSize > sizeof(allimWasteChunk)))
    {
        sRC = acpMemAlloc((void**)&sTemp, sSize);

        if(ACP_RC_IS_ENOMEM(sRC))
        {
            sSize /= 2;
        }
        else if(ACP_RC_IS_SUCCESS(sRC))
        {
            if(NULL == (*aHead))
            {
                *aHead = sTemp;
                (*aHead)->mPrev = (*aHead)->mNext = (*aHead);
            }
            else
            {
                sTemp->mNext            = (*aHead);
                sTemp->mPrev            = (*aHead)->mPrev;
                (*aHead)->mPrev->mNext  = sTemp;
                (*aHead)->mPrev         = sTemp;
            }

            aCurrent += ALLIM_CHUNKSIZE;
        }
        else
        {
            /* Other errors */
            break;
        }
    }

    *aAfter = aCurrent;
}

static void allimFreeMemory(allimWasteChunk**   aHead,
                            acp_sint64_t        aCurrent,
                            acp_sint64_t        aDest,
                            acp_sint64_t*       aAfter)
{
    allimWasteChunk*    sTemp;

    if(NULL == (*aHead))
    {
        aCurrent = 0;
    }
    else
    {
        while(aCurrent > aDest)
        {
            sTemp = (*aHead)->mPrev;
            if(sTemp == (*aHead))
            {
                (*aHead) = NULL;
            }
            else
            {
                (*aHead)->mPrev = sTemp->mPrev;
                sTemp->mPrev->mNext = (*aHead);
            }

            acpMemFree((void*)sTemp);
            aCurrent -= ALLIM_CHUNKSIZE;
        }
    }

    *aAfter = aCurrent;
}

ACP_EXPORT acp_rc_t allimSetMemoryWaste(acp_sint64_t aDest)
{
    acp_rc_t        sRC;
    acp_shm_t       sShm;
    allimPoint*     sPoint;

    sRC = allimGetSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

    sPoint = (allimPoint*)acpShmGetAddress(&sShm);
    acpSpinLockLock(&(sPoint->mLock));

    (void)acpAtomicSet64(&(sPoint->mDestMemory), aDest);

    if((0 != sPoint->mLog) && (0 != sPoint->mLogReal))
    {
        (void)allimLogWrite(sPoint, "%lld(%llX)bytes of memory shall be wasted\n", aDest, aDest);
    }
    else
    {
        /* Not logging */
    }

    acpSpinLockUnlock(&(sPoint->mLock));
    sRC = allimReleaseSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
    return ACP_RC_SUCCESS;

    ACP_EXCEPTION_END;
    return sRC;
}

ACP_EXPORT acp_rc_t allimGetMemoryWaste(acp_sint64_t* aDest, acp_sint64_t* aCurrent)
{
    acp_rc_t        sRC;
    acp_shm_t       sShm;
    allimPoint*     sPoint;

    sRC = allimGetSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

    sPoint = (allimPoint*)acpShmGetAddress(&sShm);
    acpSpinLockLock(&(sPoint->mLock));

    *aDest      = acpAtomicGet64(&(sPoint->mDestMemory));
    *aCurrent   = acpAtomicGet64(&(sPoint->mMemory));

    acpSpinLockUnlock(&(sPoint->mLock));
    sRC = allimReleaseSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
    return ACP_RC_SUCCESS;

    ACP_EXCEPTION_END;
    return sRC;
}

ACP_EXPORT acp_rc_t allimMemory(void)
{
    static allimWasteChunk* sChunk = NULL;

    acp_rc_t        sRC;
    acp_shm_t       sShm;
    acp_sint64_t    sDest;
    acp_sint64_t    sCurrent;
    allimPoint*     sPoint;

    sRC = allimGetSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

    sPoint = (allimPoint*)acpShmGetAddress(&sShm);
    acpSpinLockLock(&(sPoint->mLock));

    sDest    = acpAtomicGet64(&(sPoint->mDestMemory));
    sCurrent = acpAtomicGet64(&(sPoint->mMemory));

    if(sDest != sCurrent)
    {
        if(sCurrent < sDest)
        {
            /* Waste memory */
            allimWasteMemory(&sChunk, sCurrent, sDest, &sDest);
        }
        else
        {
            /* Free wasted memory  */
            allimFreeMemory(&sChunk, sCurrent, sDest, &sDest);
        }

        (void)acpAtomicSet64(&(sPoint->mMemory),     sDest);
        (void)acpAtomicSet64(&(sPoint->mDestMemory), sDest);

        if((0 != sPoint->mLog) && (0 != sPoint->mLogReal))
        {
            (void)allimLogWrite(sPoint, "%lld(%llX)bytes of memory has been wasted\n", sDest, sDest);
        }
        else
        {
            /* Not logging */
        }
    }
    else
    {
        /* Do nothing :p */
    }

    acpSpinLockUnlock(&(sPoint->mLock));
    sRC = allimReleaseSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
    return ACP_RC_SUCCESS;

    ACP_EXCEPTION_END;
    return sRC;
}

ACP_EXPORT acp_rc_t allimSetDiskWaste(acp_char_t* aPath, acp_sint64_t aDest)
{
    acp_rc_t        sRC;
    acp_shm_t       sShm;
    allimPoint*     sPoint;

    sRC = allimGetSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

    sPoint = (allimPoint*)acpShmGetAddress(&sShm);
    acpSpinLockLock(&(sPoint->mLock));

    (void)acpAtomicSet64(&(sPoint->mDestDisk), aDest);
    (void)acpAtomicSet64(&(sPoint->mDisk),     aDest);
    (void)acpCStrCpy(sPoint->mDestPath, ACP_PATH_MAX_LENGTH,
                     aPath,             ACP_PATH_MAX_LENGTH);

    if((0 != sPoint->mLog) && (0 != sPoint->mLogReal))
    {
        (void)allimLogWrite(sPoint, "%lld(%llX)bytes of disk shall be wasted\n", aDest, aDest);
    }
    else
    {
        /* Not logging */
    }

    acpSpinLockUnlock(&(sPoint->mLock));
    sRC = allimReleaseSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
    return ACP_RC_SUCCESS;

    ACP_EXCEPTION_END;
    return sRC;
}

ACP_EXPORT acp_rc_t allimGetDiskWaste(acp_char_t*      aPath,
                           acp_sint64_t*    aDest,
                           acp_sint64_t*    aCurrent)
{
    acp_rc_t        sRC;
    acp_shm_t       sShm;
    allimPoint*     sPoint;

    sRC = allimGetSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

    sPoint = (allimPoint*)acpShmGetAddress(&sShm);
    acpSpinLockLock(&(sPoint->mLock));

    (void)acpCStrCpy(aPath,             ACP_PATH_MAX_LENGTH,
                     sPoint->mDestPath, ACP_PATH_MAX_LENGTH);
    *aDest      = acpAtomicGet64(&(sPoint->mDestDisk));
    *aCurrent   = acpAtomicGet64(&(sPoint->mDisk));

    acpSpinLockUnlock(&(sPoint->mLock));
    sRC = allimReleaseSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
    return ACP_RC_SUCCESS;

    ACP_EXCEPTION_END;
    return sRC;
}

static void allimWasteDisk(const acp_char_t*   aPath,
                           acp_sint64_t        aCurrent,
                           acp_sint64_t        aDest,
                           acp_sint64_t*       aAfter)
{
    acp_rc_t        sRC;
    acp_size_t      sBlockSize;
    acp_char_t      sJunk[] = {0xAA, 0x55, 0x55, 0xAA};
    acp_char_t      sPath[ACP_PATH_MAX_LENGTH];
    acp_file_t      sFile;

    /*
     * A File takes 4k minimally, but acpSysGetBockSize returns 512.
     * sRC = acpSysGetBlockSize(&sBlockSize);
     * sBlockSize = ACP_RC_IS_SUCCESS(sRC)? sBlockSize : 4096;
    */
    sBlockSize = 4096;

    while(aCurrent < aDest)
    {
        sRC = acpSnprintf(sPath, ACP_PATH_MAX_LENGTH,
                          "%s/%s%016X.dat", aPath, ALLIM_DISKJUNK, aCurrent);

        sRC = acpFileOpen(&sFile, sPath, ACP_O_CREAT | ACP_O_TRUNC | ACP_O_RDWR, 0666);
        ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
        sRC = acpFileWrite(&sFile, sJunk, 4, NULL);
        ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
        (void)acpFileClose(&sFile);

        aCurrent += (acp_sint64_t)sBlockSize;
    }

    *aAfter = aCurrent;
    return;

    ACP_EXCEPTION_END;
    *aAfter = aCurrent;
    return;
}

static void allimFreeDisk(const acp_char_t*   aPath,
                          acp_sint64_t        aCurrent,
                          acp_sint64_t        aDest,
                          acp_sint64_t*       aAfter)
{
    acp_rc_t        sRC;
    acp_size_t      sBlockSize;
    acp_char_t      sPath[ACP_PATH_MAX_LENGTH];

    /*
     * A File takes 4k minimally, but acpSysGetBockSize returns 512.
     * sRC = acpSysGetBlockSize(&sBlockSize);
     * sBlockSize = ACP_RC_IS_SUCCESS(sRC)? sBlockSize : 4096;
    */
    sBlockSize = 4096;

    while(aCurrent > aDest)
    {
        aCurrent -= (acp_sint64_t)sBlockSize;
        sRC = acpSnprintf(sPath, ACP_PATH_MAX_LENGTH,
                          "%s/%s%016X.dat", aPath, ALLIM_DISKJUNK, aCurrent);
        sRC = acpFileRemove(sPath);
        ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
    }

    *aAfter = aCurrent;
    return;

    ACP_EXCEPTION_END;
    *aAfter = aCurrent + sBlockSize;
    return;
}

ACP_EXPORT acp_rc_t allimDisk(void)
{
    /*
     * No need of function
    acp_rc_t        sRC;
    acp_shm_t       sShm;
    acp_sint64_t    sDest;
    acp_sint64_t    sCurrent;
    allimPoint*     sPoint;

    sRC = allimGetSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

    sPoint = (allimPoint*)acpShmGetAddress(&sShm);
    acpSpinLockLock(&(sPoint->mLock));

    sDest    = acpAtomicGet64(&(sPoint->mDestDisk));
    sCurrent = acpAtomicGet64(&(sPoint->mDisk));

    if(sDest > sCurrent)
    {
        allimWasteDisk(sPoint->mDestPath, sCurrent, sDest, &sDest);
    }
    else
    {
        allimFreeDisk(sPoint->mDestPath, sCurrent, sDest, &sDest);
    }

    (void)acpAtomicSet64(&(sPoint->mDisk),     sDest);
    (void)acpAtomicSet64(&(sPoint->mDestDisk), sDest);

    if((0 != sPoint->mLog) && (0 != sPoint->mLogReal))
    {
        (void)allimLogWrite(sPoint, "%lld(%llX)bytes of disk has been wasted\n", sDest, sDest);
    }
    else
    {
    }

    acpSpinLockUnlock(&(sPoint->mLock));
    sRC = allimReleaseSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
    return ACP_RC_SUCCESS;

    ACP_EXCEPTION(E_FILEERROR)
    {
        acpSpinLockUnlock(&(sPoint->mLock));
        (void)allimReleaseSharedMemory(&sShm);
    }

    ACP_EXCEPTION_END;
    return sRC;
    */
    return ACP_RC_SUCCESS;
}

ACP_EXPORT acp_rc_t allimSetDescWaste(acp_sint64_t aDest)
{
    acp_rc_t        sRC;
    acp_shm_t       sShm;
    allimPoint*     sPoint;

    sRC = allimGetSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

    sPoint = (allimPoint*)acpShmGetAddress(&sShm);
    acpSpinLockLock(&(sPoint->mLock));

    (void)acpAtomicSet64(&(sPoint->mDestDesc), aDest);

    if((0 != sPoint->mLog) && (0 != sPoint->mLogReal))
    {
        (void)allimLogWrite(sPoint, "%lld descriptors shall be wasted\n", aDest);
    }
    else
    {
        /* Not logging */
    }

    acpSpinLockUnlock(&(sPoint->mLock));
    sRC = allimReleaseSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
    return ACP_RC_SUCCESS;

    ACP_EXCEPTION_END;
    return sRC;
}

ACP_EXPORT acp_rc_t allimGetDescWaste(acp_sint64_t* aDest, acp_sint64_t* aCurrent)
{
    acp_rc_t        sRC;
    acp_shm_t       sShm;
    allimPoint*     sPoint;

    sRC = allimGetSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

    sPoint = (allimPoint*)acpShmGetAddress(&sShm);
    acpSpinLockLock(&(sPoint->mLock));

    *aDest      = acpAtomicGet64(&(sPoint->mDestDesc));
    *aCurrent   = acpAtomicGet64(&(sPoint->mDesc));

    acpSpinLockUnlock(&(sPoint->mLock));
    sRC = allimReleaseSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
    return ACP_RC_SUCCESS;

    ACP_EXCEPTION_END;
    return sRC;
}

ACP_EXPORT acp_rc_t allimDesc(void)
{
    static acp_sock_t   sSocks[ALLIM_DESCMAX];

    acp_rc_t        sRC;
    acp_shm_t       sShm;
    acp_sint64_t    sDest;
    acp_sint64_t    sCurrent;
    allimPoint*     sPoint;

    sRC = allimGetSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));

    sPoint = (allimPoint*)acpShmGetAddress(&sShm);
    acpSpinLockLock(&(sPoint->mLock));

    sDest    = acpAtomicGet64(&(sPoint->mDestDesc));
    sCurrent = acpAtomicGet64(&(sPoint->mDesc));

    if(sDest != sCurrent)
    {
        if(sDest > sCurrent)
        {
            while(sDest > sCurrent)
            {
                sRC = acpSockOpen(&(sSocks[sCurrent]), ACP_AF_INET,
                                  ACP_SOCK_DGRAM, 0);
                if(ACP_RC_NOT_SUCCESS(sRC))
                {
                    break;
                }
                else
                {
                    sCurrent++;
                }
            }

            sDest = sCurrent;
        }
        else
        {
            while(sDest < sCurrent)
            {
                (void)acpSockClose(&(sSocks[sCurrent - 1]));
                sCurrent--;
            }

            sDest = sCurrent;
        }

        if((0 != sPoint->mLog) && (0 != sPoint->mLogReal))
        {
            (void)allimLogWrite(sPoint, "%lld descriptors has been wasted\n", sDest);
        }
        else
        {
            /* Not logging */
        }

        (void)acpAtomicSet64(&(sPoint->mDesc),     sDest);
        /* (void)acpAtomicSet64(&(sPoint->mDestDesc), sDest); */
    }
    else
    {
        /* Do nothing again */
    }

    acpSpinLockUnlock(&(sPoint->mLock));
    sRC = allimReleaseSharedMemory(&sShm);
    ACP_TEST(ACP_RC_NOT_SUCCESS(sRC));
    return ACP_RC_SUCCESS;

    ACP_EXCEPTION_END;
    return sRC;
}

