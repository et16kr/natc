#if !defined(__ALLIM_LIMITPOINT_H__)
#define __ALLIM_LIMITPOINT_H__

#include <acp.h>

#define ALLIM_LIMITPOINT_MAX_LENGTH   (64)
#define ALLIM_LIMITPOINT_MAX_THREADS  (256)
#define ALLIM_SHAREDMEMORY_SIZE       (sizeof(allimPoint))
#define ALLIM_LIMITTEST_LOGDIR        "ALTIBASE_HOME"
#define ALLIM_LIMITTEST_LOGFILE       "/trc/allim.log"
#define ALLIM_LIMITTEST_SHMFILE       "/trc/allimshm.log"

typedef struct allimPoint {
    /*
     * Limit Point Simulation 
     */
    acp_char_t      mFile[ACP_PATH_MAX_LENGTH];
    acp_char_t      mID[ALLIM_LIMITPOINT_MAX_LENGTH];
    acp_sint32_t    mErrNo;
    acp_sint32_t    mCount;
    acp_sint32_t    mHitCounts[ALLIM_LIMITPOINT_MAX_THREADS];

    /*
     * 실제 한계상황 플래그 
     */
    acp_sint64_t    mMemory;
    acp_sint64_t    mDisk;
    acp_sint64_t    mDesc;

    /*
     * 실제 한계상황 설정값 
     *  0 : 모두 해제 (-inf)
     */
    acp_sint64_t    mDestMemory;
    acp_char_t      mDestPath[ACP_PATH_MAX_LENGTH];
    acp_sint64_t    mDestDisk;
    acp_sint64_t    mDestDesc;

    /*
     * 로깅 플래그 
     */
    acp_sint32_t    mLog;
    acp_sint32_t    mLogPass;
    acp_sint32_t    mLogHit;
    acp_sint32_t    mLogLimit;
    acp_sint32_t    mLogStack;
    acp_sint32_t    mLogSet;
    acp_sint32_t    mLogReal;

    /*
     * 락
     */
    acp_spin_lock_t mLock;
    acp_spin_lock_t mLogLock;
    acp_uint64_t    mThreadIDs[ALLIM_LIMITPOINT_MAX_THREADS];

    /*
     * 기타 자료 
     */
    void*           mWasteHead;
} allimPoint;

/**
 * 한계상황 공유메모리 생성
 */
ACP_EXPORT acp_rc_t allimCreate(acp_key_t aKey);
/**
 * 한계상황 공유메모리 해제
 */
ACP_EXPORT acp_rc_t allimDestroy(void);
/**
 * 한계상황 진행중?
 */
ACP_EXPORT acp_bool_t allimIsProceeding(void);
/**
 * 한계상황 공유메모리 얻기
 */
ACP_EXPORT acp_rc_t allimGetSharedMemory(acp_shm_t* aShm);
/**
 * 한계상황 공유메모리 풀기
 */
ACP_EXPORT acp_rc_t allimReleaseSharedMemory(acp_shm_t* aShm);

/**
 * 한계상황 로그파일 열기
 */
ACP_EXPORT acp_rc_t allimOpenLog(acp_file_t* aFile);
/**
 * 한계상황 로그파일 닫기
 */
ACP_EXPORT acp_rc_t allimCloseLog(acp_file_t* aFile);
/**
 * 한계상황 로그 쓰기
 */
ACP_EXPORT acp_rc_t allimLogWrite(allimPoint*          aPoint,
                       const acp_char_t*    aFormat,
                       ...);

/**
 * 한계상황 위치 설정
 */
ACP_EXPORT acp_rc_t allimPointSet(const acp_char_t*     aFile,
                       const acp_char_t*     aID,
                       const acp_sint32_t    aCount,
                       const acp_sint32_t    aErrNo);
/**
 * 한계상황 위치 설정값 얻기
 */
ACP_EXPORT acp_rc_t allimPointGet(acp_char_t*     aFile,
                       acp_char_t*     aID,
                       acp_sint32_t*   aCount,
                       acp_sint32_t*   aErrNo);
/**
 * 한계상황 위치 해제
 */
ACP_EXPORT acp_rc_t allimPointClear(void);

/**
 * 한계상황 위치를 지나감 : IDU_LIMIT_POINT용
 */
ACP_EXPORT acp_rc_t allimPointPass(const acp_char_t*   aFile,
                        const acp_char_t*   aID,
                        acp_sint32_t*       aErrNo,
                        acp_bool_t*         aHit);
/**
 * 한계상황 테스트 완료
 */
ACP_EXPORT acp_rc_t allimPointDone(void);

/**
 * 한계상황 로깅 설정
 */
ACP_EXPORT acp_rc_t allimEnableLogging(const acp_sint32_t aLog);
ACP_EXPORT acp_rc_t allimSetLogging(const acp_sint32_t aLogPass,
                         const acp_sint32_t aLogHit,
                         const acp_sint32_t aLogLimit,
                         const acp_sint32_t aLogStack,
                         const acp_sint32_t aLogSet,
                         const acp_sint32_t aLogReal);
ACP_EXPORT acp_rc_t allimGetLogging(acp_sint32_t* aLog,
                         acp_sint32_t* aLogPass,
                         acp_sint32_t* aLogHit,
                         acp_sint32_t* aLogLimit,
                         acp_sint32_t* aLogStack,
                         acp_sint32_t* aLogSet,
                         acp_sint32_t* aLogReal);

/**
 * 메모리 소비 및 반환 함수
 */
ACP_EXPORT acp_rc_t allimGetMemoryWaste(acp_sint64_t* aDest, acp_sint64_t* aCurrent);
ACP_EXPORT acp_rc_t allimSetMemoryWaste(acp_sint64_t  aDest);
ACP_EXPORT acp_rc_t allimMemory(void);
/**
 * 디스크 소비 및 반환 함수
 */
ACP_EXPORT acp_rc_t allimGetDiskWaste(acp_char_t* aPath, acp_sint64_t* aDest, acp_sint64_t* aCurrent);
ACP_EXPORT acp_rc_t allimSetDiskWaste(acp_char_t* aPath, acp_sint64_t  aDest);
ACP_EXPORT acp_rc_t allimDisk(void);
/**
 * 디스크립터 소비 및 반환 함수
 */
ACP_EXPORT acp_rc_t allimGetDescWaste(acp_sint64_t* aDest, acp_sint64_t* aCurrent);
ACP_EXPORT acp_rc_t allimSetDescWaste(acp_sint64_t  aDest);
ACP_EXPORT acp_rc_t allimDesc(void);

#endif
