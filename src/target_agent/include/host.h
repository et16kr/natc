#ifndef _HOST_H_
#define _HOST_H_

#ifndef _TARGET_H_
#include "target.h"
#endif

#define RSYSTEM_BUFFER_SIZE (32768)

typedef struct rsysBuf
{
    int cursor;
    char buffer[RSYSTEM_BUFFER_SIZE];
} rsysBuf;

int connectServer    (char * aAddr, int aPort);
int execute            (int aFd, char * aBuf, char * aEnvp, rsysBuf * aRsysBuf, char * aPath);
int disconnectServer (int aFd, rsysBuf * aRsysBuf);

#endif
