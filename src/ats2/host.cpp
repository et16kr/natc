#if defined(WIN32)
#include <windows.h>
#include <winsock.h>
#else
#include <fcntl.h>
#include <stdlib.h>
#endif

#include "common.h"
#include "host.h"

#define DEBUG_MODE 0

int parsing(char * aToken);
int executeOpt(char * aOption, char * aEnvp, int aFd, rsysBuf * aRsysBuf);
int putOpt(char * aOption, int aFd, rsysBuf * aRsysBuf, char * aPath);
int getOpt(char * aFilePath, int aFd, rsysBuf * aRsysBuf, char * aPath);
int manageOpt(int aOption, char * aName, int aFd, rsysBuf * aRsysBuf);
int copyOpt(char * aOption, int aFd, rsysBuf * aRsysBuf);
int recv_nn(int aFd, char *aBuffer, int aSize);
int messagePrint(char * aMessage, rsysBuf * aRsysBuf);
int getErrno();
// int serverOpt(char * aOption, int aFd, rsysBuf * aRsysBuf);

extern int connectServer(char * aAddr, int aPort);
extern int execute(int aFd, char * aBuf, char * aEnvp, char *aMessage, char * aPath);
extern int disconnectServer(int aFd, rsysBuf * aRsysBuf);
extern int terminateServer(int aFd, rsysBuf * aRsysBuf);

char * gSep = " \n\t";

char * gUsage[] = {
    "\tquit - disconnect from target and terminate host program",
    "\tserver - Please use execute operation instead of server operation",
    "\tput -  put file(_path) (directory)",
    "\tget -  get file(_path)",
    "\tmkdir -  mkdir directory(_path)",
    "\trmdir - rmdir directory(_path)",
    "\texecute -  execute file(_path) (args) (envs) (return stdout)",
    "\thelp - print operations",
    "\tdelete - delete file(_path)",
    "\tcopy - copy file(_path) file(_path)",
    "\tterminate - terminate target program",
};

#if defined(WIN32)
#define O_RDONLY 0x0001  /* open for reading only */
#define O_WRONLY 0x0002  /* open for writing only */
#define O_RDWR   0x0010  /* open for reading and writing */

#define O_CREAT  0x0100  /* create and open file */
#define O_TRUNC  0x0200  /* open and truncate */

size_t read_(int fd, void *buffer, size_t length)
{
    BOOL rc;
    DWORD dw;

    rc = ReadFile((HANDLE)fd, buffer, length, &dw, NULL);

    return rc == 0 ? -1 : (int)dw;
}

size_t write_(int fd, const void *buffer, size_t length)
{
    BOOL rc;
    DWORD dw;

    rc = WriteFile((HANDLE)fd, buffer, length, &dw, NULL);

    return rc == 0 ? -1 : (int)dw;
}

int open_(const char *file, int mode, int)
{
    DWORD access = 0, share = 0, create = 0;
    HANDLE h;

    if((mode & O_RDWR) != 0)
        access = GENERIC_READ|GENERIC_WRITE;
    else if((mode & O_RDONLY) != 0)
        access = GENERIC_READ;
    else if((mode & O_WRONLY) != 0)
        access = GENERIC_WRITE;

    if((mode & O_CREAT) != 0)
        create = CREATE_ALWAYS;
    else
        create = OPEN_ALWAYS;

    h = CreateFile(file, access, share, NULL, create, 0, NULL);

    return h == INVALID_HANDLE_VALUE ? -1 : (int)h;
}

int close_(int fd)
{
    BOOL rc;

    rc = CloseHandle((HANDLE)fd);

    return rc == 0 ? -1 : 0;
}

int lseek_(int fd, int offset, int whence)
{
    DWORD flag;

    switch(whence)
    {
        case SEEK_SET: flag = FILE_BEGIN;   break;
        case SEEK_CUR: flag = FILE_CURRENT; break;
        case SEEK_END: flag = FILE_END;     break;
        default:       flag = FILE_CURRENT; break;
    }

    LARGE_INTEGER li;
    li.QuadPart = offset;

    if(0xFFFFFFFF == ::SetFilePointer((HANDLE)fd, li.LowPart, &li.HighPart, flag) && GetLastError() != NO_ERROR)
    {
        return -1;
    }
    else
    {
        return li.QuadPart;
    }
}
#else
size_t read_(int fd, void *buffer, size_t length)
{
    return read(fd, buffer, length);
}

size_t write_(int fd, const void *buffer, size_t length)
{
    return write(fd, buffer, length);
}

int open_(const char *file, int mode, int option)
{
    return open(file, mode, option);
}

int close_(int fd)
{
    return close(fd);
}

int lseek_(int fd, int offset, int whence)
{
    return lseek(fd, offset, whence);
}
#endif

int getErrno()
{
    int sErrno;
#if defined(WIN32)
    sErrno = GetLastError();
#else
    sErrno = errno;
#endif
    return sErrno;
}

int messagePrint (char * aMessage, rsysBuf * aRsysBuf)
{
    int sRc = -1;

    if( aRsysBuf != NULL )
    {
        if(strlen(aMessage) + aRsysBuf->cursor < RSYSTEM_BUFFER_SIZE)
        {
            strcat(&aRsysBuf->buffer[aRsysBuf->cursor], aMessage);
            sRc = 0;
            aRsysBuf->cursor += strlen(aMessage);
        }
    }
    // called by disconnectServer
    else
    {
        sRc = 0;
    }

    return sRc;
}    // end MessagePrint

int connectServer(
    char * aAddr,     // address of target agent
    int aPort        // port of target agent
) // it returns Sockfd
{
    int sSockfd;        // return when it is connected to target
    int sRc = FAILURE;    // return when it fails to connect to target
    int sLen;

    struct sockaddr_in sAddress;

    sSockfd = socket(AF_INET, SOCK_STREAM, 0);
    if(sSockfd == -1)
    {
#if DEBUG_MODE > 0
        perror("socket error ");
#endif
        IDE_TEST(sRc == -1);
//        return sRc;
    }

    sAddress.sin_family = AF_INET;
    sAddress.sin_addr.s_addr = inet_addr(aAddr);
    sAddress.sin_port = htons((short int) aPort);
    sLen = sizeof(sAddress);
    
    sRc = connect(sSockfd, (struct sockaddr *) &sAddress, sLen);

    if(sRc == -1)
    {
#if DEBUG_MODE > 0
        perror("connection failed ");
#endif
        IDE_TEST(sRc == -1);
//        return sRc;        // return -1 if connection is failed
    }
    else
    {
#if DEBUG_MODE > 0
        printf("connected to server.. [%s @ %d]\n", aAddr, aPort); 
#endif
//        return sSockfd;
    }

    return sSockfd;

    IDE_EXCEPTION_END;

    return sRc;

}    //end connectServer

int execute(
    int aFd,     // Sockfd
    char * aBuf,     // operation + options
    char * aEnvp,    // additional environment options
    rsysBuf * aRsysBuf,
    char * aPath
)
{
    int sRc = FAILURE;    // return value
    int sOpt;
    
    char * sOrigin;    // backup of operation + options
    char * sBuf;    // copy of operation + options
    char * sToken;    // token of operation + options
    char returnMessage[1024];

    aRsysBuf->cursor = 0;
    aRsysBuf->buffer[0] = '\0'; 

    if(strcmp(aBuf, "\n") == 0)
    {
        return NOTHING;
    }

    sOrigin = (char *) malloc(BUF_SIZE);
    if(sOrigin == NULL)
    {
        return sRc;
    }
    sBuf = (char *) malloc(BUF_SIZE);
    if(sBuf == NULL)
    {
        free(sOrigin);
        return sRc;
    }

    memset(sBuf, 0, BUF_SIZE);
    strcpy(sBuf, aBuf);
    memset(sOrigin, 0, BUF_SIZE);
    memcpy(sOrigin, sBuf, BUF_SIZE);
    strcpy(returnMessage, sBuf);

    sToken = strtok(sBuf, gSep);
    if(sToken == NULL)
    {
        free(sOrigin);
        free(sBuf);
        return NOTHING;
    }
    sOpt= parsing(sToken);
    
    switch(sOpt)
    {
    case EXECUTE:            // execute
        sRc = executeOpt(sOrigin, aEnvp, aFd, aRsysBuf);
        break;
    case SERVER:            // server
#if DEBUG_MODE > 0
        messagePrint("Please use e(xecute) operation\n", aRsysBuf);
#endif
        sRc = NOTHING;
//        sToken = strtok(NULL, gSep);
//        sRc = serverOpt(sToken, aFd, aRsysBuf);
        break;
    case PUT:            // put
        sToken = strtok(NULL, gSep);
        if(sToken != NULL)
        {
            sRc = putOpt(sOrigin, aFd, aRsysBuf, aPath);
        }
        else
        {
#if DEBUG_MODE > 0
            messagePrint("\tusage : put file(_path) (directory)\n", aRsysBuf);
#endif
            sRc = NOTHING;
        }
        break;
    case GET:            // get
        sToken = strtok(NULL, gSep);
        if(sToken != NULL)
        {
            sRc = getOpt(sToken, aFd, aRsysBuf, aPath);
        }
        else
        {
#if DEBUG_MODE > 0
            messagePrint("\tusage : get file(_path)\n", aRsysBuf);
#endif
            sRc = NOTHING;
        }
        break;
    case MKDIR:            // mkdir
        sToken = strtok(NULL, gSep);
        if(sToken != NULL)
        {
            sRc = manageOpt(sOpt, sToken, aFd, aRsysBuf);
        }
        else
        {
#if DEBUG_MODE > 0
            messagePrint("\tusage : mkdir directory(_path)\n", aRsysBuf);
#endif
            sRc = NOTHING;
        }
        break;
    case RMDIR:            // rmdir
        sToken = strtok(NULL, gSep);
        if(sToken != NULL)
        {
            sRc = manageOpt(sOpt, sToken, aFd, aRsysBuf);
        }
        else
        {
#if DEBUG_MODE > 0
            messagePrint("\tusage : rmdir directory(_path)\n", aRsysBuf);
#endif
            sRc = NOTHING;
        }
        break;
    case QUIT:            // quit
        sRc = disconnectServer(aFd, aRsysBuf);
        break;
    case TERMINATE:
        sRc = terminateServer(aFd, aRsysBuf);
        break;
    case HELP:            // help
#if DEBUG_MODE > 0
        if(sToken != NULL)
        {
            sToken = strtok(NULL, gSep);
            if(sToken != NULL)
            {
                sRc = parsing(sToken);
                if(sRc >= 0 && sRc < 10)
                {
                    printf("%s\n", gUsage[sRc]);
                }
                else
                {
                    printf("\tinvalid operation\n");
                }
            }        
            else
            {
                messagePrint("\n\t\t  ************* help *************\n\n\
  operations { execute, put, get, mkdir, rmdir, delete, \
copy, quit, help }\n\n", aRsysBuf);
            }
        }
#endif
        sRc = NOTHING;
        break;
    case DELETEFILE:            // delete
        sToken = strtok(NULL, gSep);
        if(sToken != NULL)
        {
            sRc = manageOpt(sOpt, sToken, aFd, aRsysBuf);
        }
        else
        {
#if DEBUG_MODE > 0
            messagePrint("\tusage : delete file(_path)\n", aRsysBuf);
#endif
            sRc = NOTHING;
        }
        break;
    case COPY:                        // copy
        strtok(NULL, gSep);
        if(sToken != NULL)            // src_file
        {
            sToken = strtok(NULL, gSep);
            if(sToken != NULL)        // dest_file
            {
                sRc = copyOpt(sOrigin, aFd, aRsysBuf);
                break;
            }
        }
#if DEBUG_MODE > 0
        messagePrint("\tusage : copy file(_path) file(_path)\n", aRsysBuf);
#endif
        sRc = NOTHING;
        break;
    default:                // invalid
        messagePrint("invalid operation\n", aRsysBuf);
        sRc = NOTHING;
        break;
    }

    if(sRc == SUCCESS)
    {
        strcat(returnMessage, " - SUCCESS\n");
        messagePrint(returnMessage, aRsysBuf);
    }
    else if(sRc == FAILURE)
    {
        strcat(returnMessage, " - FAIL\n");
        messagePrint(returnMessage, aRsysBuf);
    }
        
    free(sOrigin);
    free(sBuf);
    return sRc;    
}    // end execute

int terminateServer(int aFd, rsysBuf * aRsysBuf)
{
    int sRc = FAILURE;
    int sRet;
    int sErrno;
    char returnMessage [64];

    strHeader sHeader;
        
    sHeader.type = htonl(TERMINATE);
    sHeader.size = htonl(0);

    sRet = send(aFd, (const char *)&sHeader, sizeof(strHeader), 0);
    if(sRet == -1)
    {
        sErrno = getErrno();
        sprintf(returnMessage, "%d send error: %d\n", __LINE__, sErrno);
        messagePrint(returnMessage, aRsysBuf);
        IDE_TEST(sRet == -1);
    }
    sRet = recv_nn(aFd, (char *) &sHeader, sizeof(strHeader));
    if(sRet == -1)
    {
        sErrno = getErrno();
        sprintf(returnMessage, "%d recv error : %d\n", __LINE__,  sErrno);
        messagePrint(returnMessage, aRsysBuf);
        IDE_TEST(sRet == -1);
    }

    if(ntohl(sHeader.type) == TERMINATE)
    {
        sRc = TERMINATE;
#if defined(WIN32)
        closesocket(aFd);
#else
        close(aFd);
#endif
        messagePrint("target agent is terminated\n", aRsysBuf);
    }

    IDE_EXCEPTION_END;

    return sRc;
}    // end terminateServer

int disconnectServer(int aFd, rsysBuf * aRsysBuf)
{
    int sRc = FAILURE;
    int sRet;
    int sErrno;
    char returnMessage [64];

    strHeader sHeader;
        
    sHeader.type = htonl(QUIT);
    sHeader.size = htonl(0);

    sRet = send(aFd, (const char *)&sHeader, sizeof(strHeader), 0);
    if(sRet == -1)
    {
        sErrno = getErrno();
        sprintf(returnMessage, "%d send error: %d\n", __LINE__, sErrno);
        messagePrint(returnMessage, aRsysBuf);
        IDE_TEST(sRet == -1);
    }
    sRet = recv_nn(aFd, (char *) &sHeader, sizeof(strHeader));
    if(sRet == -1)
    {
        sErrno = getErrno();
        sprintf(returnMessage, "%d recv error : %d\n", __LINE__,  sErrno);
        messagePrint(returnMessage, aRsysBuf);
        IDE_TEST(sRet == -1);
    }

    if(ntohl(sHeader.type) == QUIT)
    {
        messagePrint("disconnected from server\n", aRsysBuf);
        sRc = QUIT;
#if defined(WIN32)
        closesocket(aFd);
#else
        close(aFd);
#endif
    }

    IDE_EXCEPTION_END;

    return sRc;
}    // end disconnectServer

int manageOpt (
    int aOption,         // denote operation {mkdir | rmdir | delete}
    char * aName,         // file name or directory name
    int aFd,            // Sockfd
    rsysBuf * aRsysBuf
)
{    // mkdir, rmdir, delete operations
    int sRc = FAILURE;
    int sRet;
    strHeader sHeader;
    strPathName sPath;
    char returnMessage[64];
    int sErrno;

    if(aName == NULL)
    {
        return sRc;
    }
    else
    {
        sHeader.type = htonl(aOption);
        sHeader.size = htonl(sizeof(strPathName));
        sRet = send(aFd, (const char *)&sHeader, sizeof(strHeader), 0);
        if(sRet == -1)
        {
            sErrno = getErrno();
            sprintf(returnMessage, "%d send error: %d\n", __LINE__, sErrno);
            messagePrint(returnMessage, aRsysBuf);
            IDE_TEST(sRet == -1);
        }
        strcpy(sPath.name, aName);
        sRet = send(aFd, (const char *)&sPath, sizeof(strPathName), 0);
        if(sRet == -1)
        {
            sErrno = getErrno();
            sprintf(returnMessage, "%d send error: %d\n", __LINE__, sErrno);
            messagePrint(returnMessage, aRsysBuf);
            IDE_TEST(sRet == -1);
        }

        sRet = recv_nn(aFd, (char *) &sHeader, sizeof(strHeader));
        if(sRet == -1)
        {
            sErrno = getErrno();
            sprintf(returnMessage, "%d recv error : %d\n", __LINE__,  sErrno);
            messagePrint(returnMessage, aRsysBuf);
            IDE_TEST(sRet == -1);
        }
        sHeader.type = ntohl(sHeader.type);
        sHeader.size = ntohl(sHeader.size);

#if DEBUG_MODE > 0
        printf("type : %d, size : %d\n", sHeader.type, sHeader.size);
#endif

        IDE_TEST(sHeader.type != SUCCESS);

/*
        if(sHeader.type == SUCCESS)
        {
            sRc = SUCCESS;
        }
        else if(sHeader.type == FAILURE)
        {
        }
        else
        {
            sprintf(returnMessage, "[%2d] wrong message type from target..\n", htonl(sHeader.type));
            messagePrint(returnMessage, aRsysBuf);
            return sRc;
        }
*/
/*
        if(sHeader.size > 0)
        {
            sRet = recv_nn(aFd, (char *) &sMessage, sizeof(strMessage));
            if(sRet == -1)
            {
                printf("recv error\n");
            }
            printf("msg - %s\n", sMessage.msg);
        }
*/
    }

    return SUCCESS;

    IDE_EXCEPTION_END;

    return FAILURE;
}    // end manageOpt

int executeOpt(char * aOrigin, char * aEnvp, int aFd, rsysBuf * aRsysBuf)
{
    char * sToken;
    char * sEnvp = NULL;
    char sMessage [1024 + 1];
    char returnMessage[64];

    int sRc = SUCCESS;
    int sRet;
    int sCount = 0;
    int sErrno;

    strExecute sExecute;
    strHeader sHeader;

    if(aEnvp != NULL)
    {
        sEnvp = (char *) malloc(BUF_SIZE);

        if(sEnvp == NULL)
        {
            messagePrint("malloc failed\n", aRsysBuf);
            IDE_TEST(sEnvp == NULL);
        }
        memset(sEnvp, 0, BUF_SIZE);
        strcpy(sEnvp, aEnvp);
    }

    sExecute.argc = htonl(0);
    sExecute.envc= htonl(0);
    sExecute.returnOption = htonl(0);

    sToken = strtok(aOrigin, gSep);        // execute
    sToken = strtok(NULL, gSep);        // operation

    if(sToken != NULL)
    {
        strcpy(sExecute.function, sToken);    // input operation
    }
    else        // function is NULL
    {
#if DEBUG_MODE > 0
        printf("\tusage : execute file(_path) (args) (envs) (return stdout)\n");
#endif
        IDE_TEST(sToken == NULL);
    }

    sToken = strtok(NULL, gSep);    // args ? envs ? return ?

    if(sToken != NULL)
    {
        if((strcmp(sToken, "args")) == 0)
        {
#if DEBUG_MODE > 0
            printf("args...\n");
#endif
            while(sToken != NULL)
            {
                sToken = strtok(NULL, gSep);
                if(sToken == NULL)
                {
                    break;
                }
                if((strcmp(sToken, "envs")) == 0 \
                    || (strcmp(sToken, "return")) == 0 \
                    || sCount >= MAX_ARGS)
                {
                    break;
                }
                else
                {
                    strcpy(sExecute.argv[sCount], sToken);
                    sCount++;
                }
            }
        }

        sExecute.argc= htonl(sCount);
        sCount = 0;

        if(sToken != NULL && (strcmp(sToken, "envs")) == 0)
        {
#if DEBUG_MODE > 0
            printf("envs...\n");
#endif
            while(sToken != NULL)
            {
                sToken = strtok(NULL, gSep);
                if(sToken == NULL)
                {
                    break;
                }
                if((strcmp(sToken, "return")) == 0 \
                    || sCount >=  MAX_ARGS)
                {
                    break;
                }
                else
                {
                    strcpy(sExecute.envp[sCount], sToken);
                    sCount++;
                }
            }
        }

        sExecute.envc = htonl(sCount);

        if(sToken != NULL && strcmp(sToken, "return") == 0)
        {
#if DEBUG_MODE > 0
            printf("return..\n");
#endif
            if(sToken != NULL)
            {
                sToken = strtok(NULL, gSep);
                if(sToken != NULL && strcmp(sToken, "stdout") == 0)
                {
                    sToken = strtok(NULL, gSep);
                    sExecute.returnOption = 1;
                }
                else if(sToken != NULL)
                {
//                    sToken = strtok(NULL, gSep);
//                    sRc = FAILURE;
                    messagePrint("invalid return option\n", aRsysBuf);
                    IDE_TEST(sToken != NULL);
                }
                else
                {
                    sExecute.returnOption = 0;
                }
            }
        }
    }

    if(sToken != NULL)
    {
        sRc = FAILURE;
        IDE_TEST(sToken != NULL)
#if DEBUG_MODE
        messagePrint("\tusage : execute file(_path) (args) (envs) (return stdout)\n", aRsysBuf);
#endif
    }

    if(sEnvp != NULL && sRc != -1)
    {
        sToken = strtok(sEnvp, gSep);
        if(strcmp(sToken, "envs") != 0)
        {
            sRc = FAILURE;
            messagePrint("invalid envs option\n", aRsysBuf);
        }
        else
        {
            while(sToken != NULL && sCount < MAX_ARGS)
            {
                sToken = strtok(NULL, gSep);
                if(sToken != NULL)
                {
                    strcpy(sExecute.envp[sCount], sToken);
                    sCount++;
                }
            }

            sExecute.envc = htonl(sCount);
        }
    }
    if(sCount > MAX_ARGS)
    {
        sRc = FAILURE;
        messagePrint("envp is overflow!\n", aRsysBuf);
    }
    if(sRc == SUCCESS)
    {
#if DEBUG_MODE > 0
        printf("execute : [%s]\n", sExecute.function);
        if(ntohl(sExecute.argc) > 0)
        {
            printf("argv : ");
            for(sCount = 0; sCount < (int) ntohl(sExecute.argc); sCount++)
            {
                printf(" [%s]", sExecute.argv[sCount]);
            }
            printf("\n");
        }
        if(ntohl(sExecute.envc) > 0)
        {
            printf("envc : ");
            for(sCount = 0; sCount < (int) ntohl(sExecute.envc); sCount++)
            {
                printf(" [%s]", sExecute.envp[sCount]);
            }
            printf("\n");
        }
        if(sExecute.returnOption > 0)
        {
            printf("return : stdout\n");
        }
#endif
        sHeader.type = htonl(EXECUTE);
        sHeader.size = htonl(sizeof(strExecute));
        sRet = send(aFd, (const char *)&sHeader, sizeof(strHeader), 0);    //1.send header
        if(sRet == -1)
        {
            sErrno = getErrno();
            sprintf(returnMessage, "%d send error: %d\n", __LINE__, sErrno);
            messagePrint(returnMessage, aRsysBuf);
            IDE_TEST(sRet == -1);
        }
        sRet = send(aFd, (const char *)&sExecute, sizeof(strExecute), 0);//2.send execute
        if(sRet == -1)
        {
            sErrno = getErrno();
            sprintf(returnMessage, "%d send error: %d\n", __LINE__, sErrno);
            messagePrint(returnMessage, aRsysBuf);
            IDE_TEST(sRet == -1);
        }
        sRet = recv_nn(aFd, (char *) &sHeader, sizeof(strHeader));//3.recv header
        if(sRet == -1)
        {
            sErrno = getErrno();
            sprintf(returnMessage, "%d recv error: %d\n", __LINE__, sErrno);
            messagePrint(returnMessage, aRsysBuf);
            IDE_TEST(sRet == -1);
        }
        if(sExecute.returnOption > 0)
        {
#if DEBUG_MODE > 0
            printf("\n****************** return ********************\n\n");
#else
            messagePrint("\n", aRsysBuf);
#endif
        }

        while(ntohl(sHeader.type) == MESSAGE)
        {
            sRet = recv_nn(aFd, (char *) sMessage, ntohl(sHeader.size));//4. recv header
            if(sRet == -1)
            {
                sErrno = getErrno();
                sprintf(returnMessage, "%d recv error : %d\n", __LINE__,  sErrno);
                messagePrint(returnMessage, aRsysBuf);
                IDE_TEST(sRet == -1);
            }
            sMessage[ntohl(sHeader.size)] = '\0';
            messagePrint(sMessage, aRsysBuf);

            sHeader.type = htonl(SUCCESS);
            sHeader.size = htonl(0);
            sRet = send(aFd, (const char *)&sHeader, sizeof(strHeader), 0); //5.send header
            if(sRet == -1)
            {
                sErrno = getErrno();
                sprintf(returnMessage, "%d send error: %d\n", __LINE__, sErrno);
                messagePrint(returnMessage, aRsysBuf);
                IDE_TEST(sRet == -1);
            }
            sRet = recv_nn(aFd, (char *) &sHeader, sizeof(strHeader)); //6.recv header
            if(sRet == -1)
            {
                sErrno = getErrno();
                sprintf(returnMessage, "%d recv error: %d\n", __LINE__, sErrno);
                messagePrint(returnMessage, aRsysBuf);
                IDE_TEST(sRet == -1);
            }
        }
        if(sExecute.returnOption > 0)
        {
#if DEBUG_MODE > 0
            printf("\n**************** return end ******************\n\n");
#else
            messagePrint("\n", aRsysBuf);
#endif
        }
    }

    free (sEnvp);

    return SUCCESS;

    IDE_EXCEPTION_END;

    if(aEnvp != NULL)
    {
        free(sEnvp);
    }
    return FAILURE;
}    // end executeOpt

/*
int serverOpt (char * aOption, int aFd, rsysBuf * aRsysBuf)
{
    int sIndex;
    int sCount;
    int sRet;
    int sErrno;
    strServer svr;
    strHeader sHeader;
    char * sFind;
    char sOpt[][OPT_SIZE] = {"start", "stop", "kill", "status", "create", "restart"};

    sCount = sizeof(sOpt) / OPT_SIZE;

    for(sIndex = 0; sIndex < sCount; ++sIndex)
    {        // Is token existed in aOption[sIndex] ??
        sFind = strstr(sOpt[sIndex], aOption);

        if(sFind != NULL && sFind == sOpt[sIndex])
        {   // token is existed in aOption[sIndex]
            break;
        }
    }

    if(sIndex >= 0)
    {
        sHeader.type = htonl(SERVER);
        sHeader.size = htonl(sizeof(strServer));
        sRet = send(aFd, (const char *)&sHeader, sizeof(strHeader), 0);
        if(sRet == -1)
        {
                sErrno = getErrno();
                printf("%d send error: %d\n", __LINE__, sErrno);
        }
        svr.option = htonl(sIndex);
        svr.returnOption = htonl(0);
        sRet = send(aFd, (const char *)&svr, sizeof(strServer), 0);
        if(sRet == -1)
        {
                sErrno = getErrno();
                printf("%d send error: %d\n", __LINE__, sErrno);
        }
    }

    return sIndex;
}
*/

int copyOpt(char *  aOrigin, int aFd, rsysBuf * aRsysBuf)
{
    int sRc = FAILURE;    // return value
    int sRet;
    char * sToken;
    char returnMessage[64];
    int sErrno;

    strHeader sHeader;
    strCopyFile cf;

    sToken = strtok(aOrigin, gSep);
    IDE_TEST(sToken == NULL);

    sToken = strtok(NULL, gSep);
    strcpy(cf.srcName, sToken);

    IDE_TEST(sToken == NULL);
    sToken = strtok(NULL, gSep);

    IDE_TEST(sToken == NULL);
    strcpy(cf.destName, sToken);

    sHeader.type = htonl(COPY);
    sHeader.size = htonl(sizeof(strCopyFile));
    
    sRet = send(aFd, (const char *)&sHeader, sizeof(strHeader), 0);

    if(sRet == -1)
    {
        sErrno = getErrno();
        sprintf(returnMessage, "%d send error: %d\n", __LINE__, sErrno);
        messagePrint(returnMessage, aRsysBuf);
        IDE_TEST(sRet == -1);
    }
    
    sRet = send(aFd, (const char *)&cf, sizeof(strCopyFile), 0);
    
    if(sRet == -1)
    {
        sErrno = getErrno();
        sprintf(returnMessage, "%d send error: %d\n", __LINE__, sErrno);
        messagePrint(returnMessage, aRsysBuf);
        IDE_TEST(sRet == -1);
    }

    sRet = recv_nn(aFd, (char *) &sHeader, sizeof(strHeader));
    
    if(sRet == -1)
    {
        sErrno = getErrno();
        sprintf(returnMessage, "%d recv error: %d\n", __LINE__, sErrno);
        messagePrint(returnMessage, aRsysBuf);
        IDE_TEST(sRet == -1);
    }
    
    sRc = ntohl(sHeader.type);
    
    if (sRc != SUCCESS)
    {
        sRc = FAILURE;
    }
        
    return sRc;

    IDE_EXCEPTION_END;

    return FAILURE;
}    // end copyOpt

int getOpt(char * aFilePath, int aFd, rsysBuf * aRsysBuf, char * aPath)
{
    char * sBuf = NULL;
    char * sFileName;
    char * sDirPath = NULL;
    char returnMessage [64];
    int sFileLen;
    int sFileSize;
    int sFd = -1;
    int sRc = FAILURE;
    int sRet;
    int sErrno;

    strHeader sHeader;
    strPathName sPath;
    strFileInfo sFileInfo;

    sBuf = (char *) malloc(MAX_BUF_SIZE);
    IDE_TEST(sBuf == NULL);
    
    sDirPath = (char *) malloc(BUF_SIZE);
    IDE_TEST(sDirPath == NULL);
        
    strcpy(sPath.name, aFilePath);
    strcpy(sDirPath, aFilePath);
    sFileName = strtok(sDirPath, "/");
    while(sDirPath != NULL)
    {
        sDirPath = strtok(NULL, "/");
        if(sDirPath != NULL)
        {
            sFileName = sDirPath;
        }
    }

    strcat(aPath, sFileName);

    sFd = open_(aPath, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if(sFd == -1)
    {
        messagePrint("file open error!\n", aRsysBuf);
        IDE_TEST(sFd == -1);
    }

    sHeader.type = htonl(GET);
    sHeader.size = htonl(sizeof(strPathName));
    sRet = send(aFd, (const char *)&sHeader, sizeof(strHeader), 0);    // 1.send strHeader
    if(sRet == -1)
    {
        sErrno = getErrno();
        sprintf(returnMessage, "%d send error: %d\n", __LINE__, sErrno);
        messagePrint(returnMessage, aRsysBuf);
        IDE_TEST(sRet == -1);
    }
    sRet = send(aFd, (const char *)&sPath, sizeof(strPathName), 0);    // 2.send file path
    if(sRet == -1)
    {
        sErrno = getErrno();
        sprintf(returnMessage, "%d send error: %d\n", __LINE__, sErrno);
        messagePrint(returnMessage, aRsysBuf);
        IDE_TEST(sRet == -1);
    }

    sRet = recv_nn(aFd, (char *) &sHeader, sizeof(strHeader));    // 3.recv strHeader
    if(sRet == -1)
    {
        sErrno = getErrno();
        sprintf(returnMessage, "%d recv error : %d\n", __LINE__,  sErrno);
        messagePrint(returnMessage, aRsysBuf);
        IDE_TEST(sRet == -1);
    }
    if(ntohl(sHeader.type) == FAILURE)
    {
        messagePrint("file open error from host\n", aRsysBuf);
        IDE_TEST(ntohl(sHeader.type) == FAILURE);
    }
    sRet = recv_nn(aFd, (char *) &sFileInfo, ntohl(sHeader.size));// 4.recv file info
    if(sRet == -1)
    {
        sErrno = getErrno();
        sprintf(returnMessage, "%d recv error : %d\n", __LINE__,  sErrno);
        messagePrint(returnMessage, aRsysBuf);
        IDE_TEST(sRet == -1);
    }
    sFileSize = ntohl(sFileInfo.size);

    if(sFileSize == 0)
    {
        sRc = SUCCESS;
        sRet = recv_nn(aFd, (char *) &sHeader, sizeof(strHeader));// 5.recv strHeader
        if(sRet == -1)
        {
            sErrno = getErrno();
            sprintf(returnMessage, "%d recv error : %d\n", __LINE__,  sErrno);
            messagePrint(returnMessage, aRsysBuf);
            IDE_TEST(sRet == -1);
        }
        free(sBuf);
        free(sDirPath);
        close_(sFd);
        return sRc;
    }
    sRet = recv_nn(aFd, (char *) &sHeader, sizeof(strHeader));    // 5.recv strHeader
    if(sRet == -1)
    {
        sErrno = getErrno();
        sprintf(returnMessage, "%d recv error : %d\n", __LINE__,  sErrno);
        messagePrint(returnMessage, aRsysBuf);
        IDE_TEST(sRet == -1);
    }
    sFileLen = (int) ntohl(sHeader.size);

    while((sFileLen = recv_nn(aFd, (char *) sBuf, sFileLen)) > 0) //6.recv file
       {
        sFileLen = write_(sFd, sBuf, sFileLen);    // write to file
        sFileSize -= sFileLen;
        
        sRet = send(aFd, (const char *)&sHeader, sizeof(strHeader), 0);// 7. send strHeader
        if(sRet == -1)
        {
            sErrno = getErrno();
            sprintf(returnMessage, "%d send error: %d\n", __LINE__, sErrno);
            messagePrint(returnMessage, aRsysBuf);
            IDE_TEST(sRet == -1);
        }

        if (sFileSize <= 0)
        {
            sRc = SUCCESS;
            sHeader.type = htonl(SUCCESS);
            sHeader.size = htonl(0);
            sRet = recv_nn(aFd, (char *) &sHeader, sizeof(strHeader));    // 8. recv strHeader
            if(sRet == -1)
            {
                sErrno = getErrno();
                sprintf(returnMessage, "%d recv error : %d\n", __LINE__,  sErrno);
                messagePrint(returnMessage, aRsysBuf);
                IDE_TEST(sRet == -1);
            }
            break;
        }
        sRet = recv_nn(aFd, (char *) &sHeader, sizeof(strHeader));// 8.recv strHeader
        if(sRet == -1)
        {
            sErrno = getErrno();
            sprintf(returnMessage, "%d recv error : %d\n", __LINE__,  sErrno);
            messagePrint(returnMessage, aRsysBuf);
            IDE_TEST(sRet == -1);
        }
        sFileLen = (int) ntohl(sHeader.size);
    }
    close_(sFd);
       free(sBuf);
    free(sDirPath);
    return sRc;

    IDE_EXCEPTION_END;

    if(sBuf != NULL)
    {
        free(sBuf);
    }
    if(sDirPath != NULL)
    {
        free(sDirPath);
    }
    if(sFd != -1)
    {
        close_(sFd);
    }

    return FAILURE;
}    // end getOpt

int putOpt(char * aOrigin, int aFd, rsysBuf * aRsysBuf, char * aPath)
{
    char * sBuf = NULL;
    char * sToken;
    char * sFileName;
    char * sFilePath = NULL;
    char * sDirPath = NULL;
    char returnMessage [64];

    int sFd = -1;
    int sRc = FAILURE;
    int sFileSize = 0;
    int sFileLen;
    int sRet;
    int sErrno;

    strHeader sHeader;
    strFileInfo sFileInfo;

    sBuf = (char *) malloc(MAX_BUF_SIZE);
    IDE_TEST(sBuf == NULL);

    sDirPath = (char *) malloc(BUF_SIZE);
    IDE_TEST(sDirPath == NULL);
    
    sFilePath = (char *) malloc(BUF_SIZE);
    IDE_TEST(sFilePath == NULL);

    memset(sDirPath, 0, BUF_SIZE);
    sToken = strtok(aOrigin, gSep);    // cut operation (put)
    sToken = strtok(NULL, gSep);        // sFilePath
    strcpy(sFilePath, sToken);
    strcat(aPath, sFilePath);
    sFd = open_(aPath, O_RDONLY, 0);
    
    IDE_TEST(sFd == -1);
        
    sHeader.type = htonl(PUT);
    sHeader.size = htonl(sizeof(strFileInfo));
    sRet = send(aFd, (const char *)&sHeader, sizeof(strHeader), 0);// 1.send strHeader
    
    if(sRet == -1)
    {    
        sErrno = getErrno();
        sprintf(returnMessage, "%d send error: %d\n", __LINE__, sErrno);
        messagePrint(returnMessage, aRsysBuf);
        IDE_TEST(sRet == -1);
    }
    
    if(sToken != NULL)
    {
        sToken = strtok(NULL, gSep);
        if(sToken != NULL)
        {
            strcpy(sDirPath, sToken);
            if(sDirPath[strlen(sDirPath) -1] != '/')
            {
                sDirPath[strlen(sDirPath)] = '/';
                sDirPath[strlen(sDirPath) + 1] = '\0';
            }
        }
    }
    sFileName = strtok(sFilePath, "/");

    while(sFilePath != NULL)
    {
        sFilePath = strtok(NULL, "/");
        if(sFilePath != NULL)
        {
            sFileName = sFilePath;
        }
    }
    strcat(sDirPath, sFileName);
    strcpy(sFileInfo.name, sDirPath);

#if defined(WIN32)
    sFileSize = GetFileSize((HANDLE)sFd, NULL);
#else
    sFileSize = lseek_(sFd, -1, SEEK_END);
    sFileSize++;
#endif
    sFileInfo.size = htonl(sFileSize);

    sRet = send(aFd, (const char *)&sFileInfo, sizeof(strFileInfo), 0);// 2.send file info
    if(sRet == -1)
    {
        sErrno = getErrno();
        sprintf(returnMessage, "%d send error: %d\n", __LINE__, sErrno);
        messagePrint(returnMessage, aRsysBuf);
        IDE_TEST(sRet == -1);
    }
    sRet = recv_nn(aFd, (char *) &sHeader, sizeof(strHeader));    // 3.recv strHeader
    if(sRet == -1)
    {
        sErrno = getErrno();
        sprintf(returnMessage, "%d recv error : %d\n", __LINE__,  sErrno);
        messagePrint(returnMessage, aRsysBuf);
        IDE_TEST(sRet == -1);
    }

    if(ntohl(sHeader.type) == FAILURE)
    {
        messagePrint("fail to put file from target\n", aRsysBuf);
        IDE_TEST(ntohl(sHeader.type) == FAILURE);
    }
    if(sFileSize == 0)
    {
        sRc = SUCCESS;
        close_(sFd);
        free(sBuf);
        free(sDirPath);
        free(sFilePath);
        return sRc;
    }

    sHeader.type = htonl(SUCCESS);
    lseek_(sFd, 0, SEEK_SET);
    while((sFileLen = read_(sFd, sBuf, MAX_BUF_SIZE)) >= 0)    //read file
    {
        sHeader.size = htonl(sFileLen);
        sRet = send(aFd, (const char *)&sHeader, sizeof(strHeader), 0); //4.send strHeader
        if(sRet == -1)
        {
            sErrno = getErrno();
            sprintf(returnMessage, "%d send error: %d\n", __LINE__, sErrno);
            messagePrint(returnMessage, aRsysBuf);
            IDE_TEST(sRet == -1);
        }
        sFileSize -= sFileLen;
        if(sFileLen > 0)
        {
            sRet = send(aFd, (const char *)sBuf, sFileLen, 0);    //5.send file
            if(sRet == -1)
            {
                sErrno = getErrno();
                sprintf(returnMessage, "%d send error: %d\n", __LINE__, sErrno);
                messagePrint(returnMessage, aRsysBuf);
                IDE_TEST(sRet == -1);
            }
            
            if(sFileSize <= 0)
            {
                sRet = recv_nn(aFd, (char *) &sHeader, sizeof(strHeader));    //6.recv strHeader
                if(sRet == -1)
                {
                    sErrno = getErrno();
                    sprintf(returnMessage, "%d recv error : %d\n", __LINE__,  sErrno);
                    messagePrint(returnMessage, aRsysBuf);
                    IDE_TEST(sRet == -1);
                }
                sRc = SUCCESS;
                break;
            }
        }
        else if(sFileLen == -1)    // never occurred
        {
            break;
        }
        sRet = recv_nn(aFd, (char *) &sHeader, sizeof(strHeader));    //6.recv strHeader
        if(sRet == -1)
        {
            sErrno = getErrno();
            sprintf(returnMessage, "%d recv error : %d\n", __LINE__,  sErrno);
            messagePrint(returnMessage, aRsysBuf);
            IDE_TEST(sRet == -1);
        }
        if(ntohl(sHeader.type) == FAILURE)
        {
            messagePrint("put file error\n", aRsysBuf);
            IDE_TEST(ntohl(sHeader.type) == FAILURE);
/*
            if(ntohl(sHeader.size) > 0)
            {
                sRet = recv_nn(aFd, (char *) &sMessage, sizeof(strMessage));//7.recv message
                if(sRet == -1)
                {
                    printf("recv error\n");
                }
                sprintf(returnMessage "msg- %s\n", sMessage.msg);
            }
*/
            break;
        }
    }

    free(sBuf);
    free(sDirPath);
    free(sFilePath);
    close_(sFd);

    return sRc;

    IDE_EXCEPTION_END;

    if(sBuf != NULL)
    {
        free(sBuf);
    }
    if(sDirPath != NULL)
    {
        free(sDirPath);
    }
    if(sFilePath != NULL)
    {
        free(sFilePath);
    }
    if(sFd != -1)
    {
        close_(sFd);
    }
    return FAILURE;
}    // end putOpt

int parsing(char * aToken)    // compare given token and operation
{
    int sIndex;
    int sCount;
    char * sFind;
    char sOpt [][OPT_SIZE] = {"quit", "server", "put", "get",\
"mkdir", "rmdir", "execute", "help", "delete", "copy", "terminate"};

    sCount = sizeof(sOpt) / OPT_SIZE;    // OPT_SIZE = 10, strlen operation

    for(sIndex = 0; sIndex < sCount; ++sIndex)
    {        // Is Token existed in sOpt[sIndex] ??
        sFind = strstr(sOpt[sIndex], aToken);

        if(sFind != NULL && sFind == sOpt[sIndex])
        {   // Token is existed in sOpt[sIndex]
            return sIndex;
        }
    }

    return -1;
}    // end parsing

int recv_nn( 
    int aFd,             // Sockfd
    char *aBuffer,         // Dest
    int aSize             // total recv size
)
{
    int sRet = 0;
    int sSize = 0;
    int sCursor = 0;
    int sGetSize = 1024;
    //int sErrno;

    while( 1 )
    {
        if((aSize - sSize) < sGetSize)
        {
            sGetSize = aSize - sSize;
        }

        sRet = recv( aFd, &aBuffer[sCursor], sGetSize, 0 );

        if( sRet < 0 )
        {
/*
            sErrno = getErrno();
            sprintf(returnMessage, "%d recv error : %d\n", __LINE__,  sErrno);
            messagePrint(returnMessage, aRsysBuf);
*/
            return -1;
        }
 
        sSize += sRet; 

        if( aSize == sSize )
        {
            break;
        }
        else
        {
            sCursor += sRet;
        }
    }

    return sSize; 
}    // end recv_nn

