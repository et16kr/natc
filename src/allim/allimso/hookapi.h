#if !defined(__HOOKAPI_H__)
#define __HOOKAPI_H__

#if defined(ACP_CFG_OS_LINUX)

#define _GNU_SOURCE
#include <dlfcn.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>

#define ORIG_FUNC(funcname) funcname##_orig

#define DECLARE_HOOK_FUNCTION(functype, funcname, args)             \
typedef functype funcname##_functype args;                          \
static funcname##_functype* ORIG_FUNC(funcname);                    \
typedef int  funcname##_procb(void);                                \
functype funcname args;

#define SKEL_HOOK(functype, funcname, cb)                       \
    static funcname##_procb* pcb = cb;                          \

#define CALL_HOOK(funcname, args)                               \
    {                                                           \
        if(ACP_FALSE == gInsideHook) {                          \
            gInsideHook = ACP_TRUE;                             \
            if(NULL != pcb)                                     \
            {                                                   \
                (void)(*pcb)();                                 \
            }                                                   \
            gInsideHook = ACP_FALSE;                            \
        }                                                       \
        return ORIG_FUNC(funcname) args;                        \
    }

#define MAKE_HOOK(funcname)                                     \
    if(NULL == ORIG_FUNC(funcname)){                            \
        char* error;                                            \
        ORIG_FUNC(funcname) = dlsym(RTLD_NEXT, #funcname);      \
        if(NULL != (error = dlerror())){                        \
            write(2, "Error loading " #funcname,                \
                  15 + strlen(#funcname));                      \
            exit(255);                                          \
        }                                                       \
    }                                                           \


#define TYPE_REDIRECT(functype, funcname, args, argnames, cb)   \
functype funcname args                                          \
{                                                               \
    SKEL_HOOK(functype, funcname, cb);                          \
    MAKE_HOOK(funcname);                                        \
    CALL_HOOK(funcname, argnames);                              \
}

#define VOID_REDIRECT(funcname, args, argnames, cb)             \
void funcname args                                              \
{                                                               \
    SKEL_VOIDHOOK(funcname, cb);                                \
    MAKE_HOOK(funcname);                                        \
    CALL_VOIDHOOK(funcname, argnames);                          \
}

#endif

#endif
