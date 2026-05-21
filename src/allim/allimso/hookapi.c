#if defined(ACP_CFG_OS_LINUX)

#define SIZE 100

/*
 * 물리적으로 자원을 모두 소모시킨다.
 * Hooking 방식으로 작동하도록 한다.
 */

#include "hookapi.h"
#include <allimPoint.h>
#include <acp.h>

acp_bool_t gInsideHook = ACP_FALSE;
extern acp_bool_t gHookLoaded;

int anypcb(void)
{
    if(ACP_TRUE == gHookLoaded)
    {
        (void)allimMemory();
        (void)allimDisk();
        (void)allimDesc();
    }
    else
    {
        /* Do not waste resources until hooking SO is loaded */
    }
    return 0;
}

/*
 * Memory functions hooking
 */
DECLARE_HOOK_FUNCTION(void*, malloc, (size_t));
TYPE_REDIRECT(void*, malloc, (size_t size), (size), anypcb);

DECLARE_HOOK_FUNCTION(void*, realloc, (void*, size_t));
TYPE_REDIRECT(void*, realloc, (void* ptr, size_t size), (ptr, size), anypcb);

/*
 * File functions hooking
 */

typedef int                     open_functype(const char*, int, ...);
static  open_functype*          ORIG_FUNC(open);
typedef int  open_procb(void);

int open(const char* path, int mode, ...)
{
    va_list va;
    int vRet;

    SKEL_HOOK(int, open, anypcb);
    pcb = anypcb;
    MAKE_HOOK(open);

    {
        if(ACP_FALSE == gInsideHook)
        {
            gInsideHook = ACP_TRUE;
            if(NULL != pcb)
            {
                (void)(*pcb)();
            }
            gInsideHook = ACP_FALSE;
        }

        vRet = ORIG_FUNC(open)(path, mode, 0666);
    }
 
    return vRet;
}

DECLARE_HOOK_FUNCTION(int, creat, (const char*, mode_t));
TYPE_REDIRECT(int, creat, (const char* path, mode_t mode),
              (path, mode), anypcb);

DECLARE_HOOK_FUNCTION(int, close, (int));

/*
 * prevent closing the logging file descriptor
 * TYPE_REDIRECT(int, close, (int fd), (fd), closecb1, closepcb, closecb2, -1);
 */
int close(int fd)
{
    acp_file_t sLog;
    SKEL_HOOK(int, close, NULL);
    pcb = NULL;
    MAKE_HOOK(close);

    (void)allimOpenLog(&sLog);

    if(fd != sLog.mHandle)
    {
        CALL_HOOK(close, (fd));
    }
    else
    {
        /* pass logging fd */
        return 0;
    }
}

/*
 * Steamed File IO functions hooking
 */
DECLARE_HOOK_FUNCTION(FILE*, fopen, (const char*, const char*));
TYPE_REDIRECT(FILE*, fopen, (const char* path, const char* mode),
              (path, mode), anypcb);

DECLARE_HOOK_FUNCTION(FILE*, fdopen, (int, const char*));
TYPE_REDIRECT(FILE*, fdopen, (int fd, const char* mode),
              (fd, mode), anypcb);

/*
 * Socket functions hooking
 */

DECLARE_HOOK_FUNCTION(int, socket, (int, int, int));
TYPE_REDIRECT(int, socket, (int domain, int type, int protocol),
              (domain, type, protocol), anypcb);

DECLARE_HOOK_FUNCTION(int, accept, (int, struct sockaddr*, socklen_t*));
TYPE_REDIRECT(int, accept,
              (int sockfd, struct sockaddr *addr, socklen_t *addrlen),
              (sockfd, addr, addrlen), anypcb);

DECLARE_HOOK_FUNCTION(int, socketpair, (int, int, int, int[2]));
TYPE_REDIRECT(int, socketpair,
              (int domain, int type, int protocol, int sv[2]),
              (domain, type, protocol, sv), anypcb);

DECLARE_HOOK_FUNCTION(int, dup, (int));
TYPE_REDIRECT(int, dup, (int oldfd), (oldfd), anypcb);

DECLARE_HOOK_FUNCTION(int, dup2, (int, int));
TYPE_REDIRECT(int, dup2, (int oldfd, int newfd), (oldfd, newfd), anypcb);

DECLARE_HOOK_FUNCTION(void*, mmap,
                      (void *addr, size_t length, int prot,
                       int flags, int fd, off_t offset));

TYPE_REDIRECT(void*, mmap,
              (void *addr, size_t length, int prot, int flags, int fd, off_t offset),
              (addr, length, prot, flags, fd, offset), anypcb);

#endif
