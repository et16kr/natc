#if !defined(__HOOK_TEST_H__)
#define __HOOK_TEST_H__

#define _GNU_SOURCE
#include <dlfcn.h>

typedef struct hookpoint
{
    char            mFile[1024];
    char            mFunc[1024];
    int             mLine;
    char            mTargetFile[1024];
    char            mTargetFunc[1024];
    int             mTargetLine;
    int             mErrno;
    char            mDummy[1024 - sizeof(int) * 5];
} hookpoint;

static inline void hooktestSetHookID(const char* file, const int line, const char* func, const char* id)
{
    typedef void setpoint(const char*, const int, const char*, const char*);
    setpoint* sp = (setpoint*)dlsym(RTLD_NEXT, "setHookPoint");
    if((setpoint*)0 == sp)
    {
        return;
    }
    else
    {
        (*sp)(file, line, func, id);
    }
}

#define SETHOOKID(aID) hooktestSetHookID(__FILE__, __LINE__, __func__, aID)

#endif
