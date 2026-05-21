#ifndef _TARGET_H_
#    define    _TARGET_H_

#define OPT_SIZE        10
#define BUF_SIZE        65536    
#define MAX_BUF_SIZE    1024*10

#ifdef _VXWORKS_
#    define MAX_ARGS    10
#else
#    define MAX_ARGS    32
#endif

#define MAX_ARG_LENGTH  1024 

enum {QUIT, SERVER, PUT, GET, MKDIR, RMDIR, EXECUTE, HELP, DELETEFILE, COPY, TERMINATE, SUCCESS, FAILURE, MESSAGE, NOTHING};

typedef struct strHeader
{
    int type;
    int size;
} strHeader;

typedef struct strExecute
{
#ifdef _VXWORKS_
    char module        [1024];
#endif
    char function    [1024];
    int argc;
    char argv        [MAX_ARGS][MAX_ARG_LENGTH];
    int envc;
    char envp        [MAX_ARGS][MAX_ARG_LENGTH];
    int returnOption;
} strExecute;

typedef struct strPathName
{
    char name        [1024];
} strPathName;

typedef struct strCopyFile 
{
    char srcName    [1024];
    char destName    [1024];
} strCopyFile;

typedef struct strServer
{
    int option;
    int returnOption;
} strServer;

typedef struct strMessage
{
    char msg [1024];
} strMessage;

typedef struct strFileInfo
{
    char name [1024];
    int size;
} strFileInfo;

#endif
