/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id$
 **********************************************************************/

#ifndef _O_RECPOINT_MANAGER_H_
#define _O_RECPOINT_MANAGER_H_ 1

#include "common.h"

// PRJ-1552 복구지점 관리자 

class RecPointer
{
public:

    IDE_RC         initialize( STAFString aEnvHOME );
    IDE_RC         destroy();

    // 복구지점목록파일로 부터 STL map 구축
    IDE_RC         load( SChar        * aFileName );

    // altibase_boot.log로 마지막라인 반환
    STAFString     getLastLineFromBootLog();

    RecPtrMap    * getMap() { return &mRecPointMap; }

    IDE_RC         lock();
    IDE_RC         unlock();
    
private:

    // 복구지점목록 STL map
    RecPtrMap          mRecPointMap;

    // altibase_boot.log 판독시 동시성 제어
    pthread_mutex_t mCheckMutex;
    
    // altibase_boot.log 파일 handle
    FILE             * mBOOTLOG;

    // altibase_boot.log 파일 경로
    SChar              mBOOTLOG_PATH[1024];
    
    // altibase_boot.log 파일의 IO 버퍼
    SChar              mLastLine[1024];
    
    STAFString         mEnvHOME; // $ALTIBASE_HOME
};

#endif
