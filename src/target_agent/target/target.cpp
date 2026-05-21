//CE에서는 UNDER_CE라는 매크로가 정의된다.
#if defined(UNDER_CE)
#include <windows.h>
#include <winsock.h>
#else
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#endif

#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

//natc/src/target_agent/include에 존재한다.
#include <target.h>

#define DEBUG_MODE 0

int    handleFile(int aFd, int aOpt);
int    copyFile(int aFd);
int    putFile(int aFd);
int    getFile(int aFd);
//server 명령어는 execute 명령어로 대치한다.
//int  serverOpt(int aFd);
//execute 명령어는 CE에서 구현을 다시해야 한다.
int    executeOpt(int aFd);
int    recv_nn(int aFd, char *aBuffer, int aSize);
//모든 출력은 stdout.txt 파일에 기록된다.
void   _printf(const char * format, ...);

//target agent는 pd(platform dependent) 라이브러리를 링크하지 않는다.
//따라서 CE에서는 아래 함수를 새로 구현해야 한다.
#if defined(UNDER_CE)
typedef int socklen_t;

#define O_RDONLY 0x0001  /* open for reading only */
#define O_WRONLY 0x0002  /* open for writing only */
#define O_RDWR   0x0010  /* open for reading and writing */

#define O_CREAT  0x0100  /* create and open file */
#define O_TRUNC  0x0200  /* open and truncate */

int        vsnprintf(char *buf, size_t size, const char *format, va_list ap);
int        snprintf(char *buf, size_t size, const char *format, ...);

int        open(const char *file, int mode, int);
int        lseek(int fd, int offset, int origin);
size_t     read(int fd, void *buffer, size_t length);
size_t     write(int fd, const void *buffer, size_t length);
int        close(int fd);
int        mkdir(const char *dir, int mode);
int        rmdir(const char *dir);
int        remove(const char *file);
time_t     time(time_t *timer);
struct tm *localtime(const time_t *timer);
wchar_t   *wce_mbtowc(const char* a);
#endif

int main()
{
    int sOpt;
    int sError = FAILURE;
    int sRs;

    int sServerFd;
    int sClientFd;
    int sAddrLen;

    char sPort[128];

    struct sockaddr_in sServerAddress;
    struct sockaddr_in sClientAddress;

    FILE * sFd;

    strHeader sHeader;

    int sQuit = 0;

    sFd = fopen("tagent.conf", "r");
    if(sFd == NULL)
    {
        _printf("cannot open \"server.conf\"\n");
        return sError;
    }
    fgets(sPort, sizeof(sPort), sFd);
    fclose(sFd);

    sServerFd = socket(AF_INET, SOCK_STREAM, 0);
    sServerAddress.sin_family = AF_INET;
    sServerAddress.sin_addr.s_addr = htonl(INADDR_ANY); 
    sServerAddress.sin_port = htons((short int)atoi(sPort));
    sAddrLen = sizeof(sServerAddress);

    sOpt = 1;
    sRs = setsockopt( sServerFd, SOL_SOCKET, SO_REUSEADDR, (const char *)&sOpt, sizeof(sOpt) );
    if(sRs == -1)
    {
        _printf("setsockopt error\n");
        exit(0);
    }

    sRs = bind(sServerFd, (struct sockaddr *) & sServerAddress, sAddrLen);
    if(sRs == -1)
    {
        _printf("bind error\n");
        exit(0);
    }

    sRs = listen(sServerFd, 9);
    if(sRs == -1)
    {
        _printf("listen error\n");
        exit(0);
    }

    while(1)
    {
        sQuit = 0;

        _printf("server waiting\n");

        sAddrLen = sizeof(sClientAddress);
        sClientFd = accept(sServerFd, (struct sockaddr *) &sClientAddress, (socklen_t*) &sAddrLen);
        if(sClientFd == -1)
        {
            _printf("accept error\n");
            exit(0);
        }

        while( sQuit == 0 )
        {
            _printf("wait operation\n");
            sRs = recv_nn(sClientFd, (char *)&sHeader, sizeof(strHeader)); // 1.recv header
 
            if(sRs == -1)
            {
                _printf("%d recv error\n", __LINE__);
                break;
            }
            sOpt = ntohl(sHeader.type);

            switch(sOpt)
            {
            case EXECUTE :
                _printf("execute\n");
                sError = executeOpt(sClientFd);
                break;
            case SERVER :
                _printf("server\n");
//                sError = serverOpt(sClientFd);
                break;
            case PUT :
                _printf("put\n");
                sError = putFile(sClientFd);
                break;
            case GET :
                _printf("get\n");
                sError = getFile(sClientFd);
                break;
            case MKDIR :
                _printf("mkdir\n");
                sError = handleFile(sClientFd, sOpt);
                break;
            case RMDIR :
                _printf("rmdir\n");
                sError = handleFile(sClientFd, sOpt);
                break;
            case QUIT :
                _printf("quit\n");
                sHeader.type = htonl(QUIT);
                sHeader.size = htonl(0);
                sRs = send(sClientFd, (const char *)&sHeader, sizeof(strHeader), 0);
                if(sRs == -1)
                {
                    _printf("%d send error\n", __LINE__);
                }
#if defined(UNDER_CE)
                sRs = closesocket(sClientFd);
#else
                sRs = close(sClientFd);
#endif
                if(sRs == -1)
                {
                    _printf("client is disconnected abnormally\n");
                }
                else
                {
                    _printf("client is disconnected\n");
                }
                sQuit = 1; 
                //exit(0);
                break;
            case DELETEFILE:
                _printf("delete\n");
                sError = handleFile(sClientFd, sOpt);
                break;
            case COPY :
                _printf("copy\n");
                sError = copyFile(sClientFd);
                break;
            case TERMINATE:
                _printf("terminate\n");
                sHeader.type = htonl(TERMINATE);
                sHeader.size = htonl(0);
                sRs = send(sClientFd, (const char *)&sHeader, sizeof(strHeader), 0);
                if(sRs == -1)
                {
                    _printf("%d send error\n", __LINE__);
                }
#if defined(UNDER_CE)
                sRs = closesocket(sClientFd);
#else
                sRs = close(sClientFd);
#endif
                if(sRs == -1)
                {
                    _printf("client is disconnected abnormally\n");
                }
                else
                {
                    _printf("client is disconnected\n");
                }
                sQuit = 1; 
                _printf("target agent is terminated\n");
                exit(0);
                break;
            default :
                sHeader.type = htonl(FAILURE);
                sHeader.size = htonl(0);
                sRs = send(sClientFd, (const char *)&sHeader, sizeof(strHeader), 0);
                
                if(sRs == -1)
                {
                    _printf("%d send error\n", __LINE__);
#if defined(UNDER_CE)
                    sRs = closesocket(sClientFd);
#else
                    sRs = close(sClientFd);
#endif
                    if(sRs == -1)
                    {
                        _printf("client is disconnected abnormally\n");
                    }
                    else
                    {
                        _printf("client is disconnected\n");
                    }
                    sQuit = 1; 
                }
                break;
            }
        }
    }
    /* close connection */
#if defined(UNDER_CE)
    closesocket(sClientFd);
#else
    close(sClientFd);
#endif
    return 0;
}    // end main

/*
int serverOpt(int aFd)
{
    pid_t pid;
    strServer svr;
    int option;
    int returnOption;
    int sRs;

    sRs = recv(aFd, &svr, sizeof(strServer), 0);
    
    if(sRs == -1)
    {
        _printf("%d recv error\n", __LINE__);
    }
    
    option = ntohl(svr.option);
    returnOption = ntohl(svr.returnOption);

    pid = fork();

    switch(pid)
    {
        case -1:
            _printf("fork error\n");
            break;
        case 0:
            _printf("server %d return - %d\n", option, returnOption);
            exit(0);
            break;
        default:
            break;
    }
    return 0;
}
*/

strExecute sExecute;

int executeOpt(int aFd)
{
#if !defined(UNDER_CE)
    int sError = FAILURE;        // return value
    int sRs;
    int sLen;

    int sArgc;                // the number of argv
    int sEnvc;                // the number of envp
    int sLoop;                // variable for loop
    int sPipe[2];

    pid_t sPid;                // variable for for()

    char * sArgv [MAX_ARGS+2];    // copy of execute.argv
    char * sEnvp [MAX_ARGS+1];    // copy of execute.envp
    char sMessage [1024];        // return chars
    char sFunctionName [1024];

    char * sBuf;
    char * sEnv;

    strHeader sHeader;

    sRs = recv_nn(aFd, (char *)&sExecute, sizeof(strExecute));    //2.recv execute

    if(sRs == -1)
    {
        _printf("%d recv error\n", __LINE__);
    }

    sBuf = (char *) malloc(1024 + 1);
    if(sBuf == NULL)
    {
        _printf("malloc error\n");
        sHeader.type = htonl(FAILURE);
        sHeader.size = htonl(0);
        sRs = send(aFd, (const char *)&sHeader, sizeof(strHeader), 0); //3.send header
        if(sRs == -1)
        {
            _printf("%d send error\n", __LINE__);
        }
        return sError;
    }

    if(pipe(sPipe) == -1)
    {
        _printf("pipe error\n");
        sHeader.type = htonl(FAILURE);
        sHeader.size = htonl(0);
        sRs = send(aFd, (const char *)&sHeader, sizeof(strHeader), 0); //3.send header
        if(sRs == -1)
        {
            _printf("%d send error\n", __LINE__);
        }
        free(sBuf);
        return sError;
    }

    sPid = fork();

    switch(sPid)
    {
    case -1:
        _printf("fork error\n");
        sHeader.type = htonl(FAILURE);
        sHeader.size = htonl(0);
        sRs = send(aFd, (const char *)&sHeader, sizeof(strHeader), 0);//3. send header
        if(sRs == -1)
        {
            _printf("%d send error\n", __LINE__);
        }
        break;
    case 0:
        sArgc = ntohl(sExecute.argc);
        if(sArgc > MAX_ARGS)
        {
            _printf("sArgc[%d] is larger than MAX_ARGS[%d]\n", sArgc, MAX_ARGS);
        }
        sEnvc = ntohl(sExecute.envc);
        if(sEnvc > MAX_ARGS)
        {
            _printf("sEnvc[%d] is larger than MAX_ARGS[%d]\n", sEnvc, MAX_ARGS);
        }

        if(sEnvc > 0 && sExecute.function[0] == '/')
        {
            sEnv = getenv("ALTIBASE_HOME");
            if(sEnv != NULL)
            {
                strcpy(sFunctionName, sEnv);
                strcat(sFunctionName, "/bin");
                strcat(sFunctionName, sExecute.function);
            }
            else
            {
                strcpy(sFunctionName, sExecute.function);
            }
        }
        else
        {
            strcpy(sFunctionName, sExecute.function);
        }
        
        sArgv[0] = sFunctionName;
        for(sLoop = 0; sLoop < sArgc; sLoop++)
        {
            sArgv[sLoop + 1] = sExecute.argv[sLoop];
        }
        sArgv[sLoop + 1] = 0;
        for(sLoop = 0; sLoop < sEnvc; sLoop++)
        {
            sEnvp[sLoop] = sExecute.envp[sLoop];
        }
        sEnvp[sLoop] = 0;
#if DEBUG_MODE > 0
        for(sLoop = 0; sLoop < sArgc + 1; sLoop++)
        {
            _printf("argv[%d] : %s\n", sLoop, sArgv[sLoop]);
        }
        for(sLoop = 0; sLoop < sEnvc; sLoop++)
        {
            _printf("envp[%d] : %s\n", sLoop, sEnvp[sLoop]);
        }

        _printf("function : %s\n", sArgv[0]);
#endif

        if(sEnvc == 0)
        {
            close(1);
            dup(sPipe[1]);
            dup2(1,2);
            close(sPipe[0]);
            close(sPipe[1]);

            sRs = execvp(sArgv[0], sArgv);
        }
        else
        {
            close(1);
            dup(sPipe[1]);
            dup2(1,2);
            close(sPipe[0]);
            close(sPipe[1]);

            sRs = execve(sArgv[0], sArgv, sEnvp);
        }

        if(sRs == -1)
        {
            _printf("execvp error\n");
        }
        exit(0);
        break;
    default:
        memset(sBuf, '\0', 1024); 
        close(sPipe[1]);
#if DEBUG_MODE > 0
        if(sExecute.returnOption == 0)
        {
            _printf("\n****************** return ********************\n\n");
        }
#endif
        while((sLen = read(sPipe[0],sBuf, 1024)) > 0)
        {
            if(sExecute.returnOption > 0)
            {
                sHeader.type = htonl(MESSAGE);
                sHeader.size = htonl(sLen);

                memcpy(sMessage, sBuf, sLen); 

                sRs = send(aFd, &sHeader, sizeof(strHeader), 0); //3. send header
                if(sRs == -1)
                {
                    _printf("%d send error\n", __LINE__);
                }
                sRs = send(aFd, sMessage, sLen, 0); // 4. send message
                if(sRs == -1)
                {
                    _printf("%d send error\n", __LINE__);
                }
                sRs = recv_nn(aFd, (char *) &sHeader, sizeof(strHeader));
                //5. recv header
                if(sRs == -1)
                {
                    _printf("%d recv error\n", __LINE__);
                }
            }
            else
            {
                sBuf[sLen] = '\0';
                _printf("%s", sBuf);
            }
        }
#if DEBUG_MODE > 0
        if(sExecute.returnOption == 0)
        {
            _printf("\n**************** return end ******************\n\n");
        }
#endif
        wait(&sRs);
        close(sPipe[0]);

        sHeader.type = htonl(SUCCESS);
        sHeader.size = htonl(0);
        sRs = send(aFd, &sHeader, sizeof(strHeader), 0);// 6.send header
        if(sRs == -1)
        {
            _printf("%d send error\n", __LINE__);
        }
        break;
    }

    sError = SUCCESS;
    free(sBuf);
    return sError; 
#else
    int sError = FAILURE;        // return value
    int sRs;

    int sArgc;                // the number of argv
    int sEnvc;                // the number of envp
    int sLoop;                // variable for loop

    char * sArgv [MAX_ARGS+2];    // copy of execute.argv
    char * sEnvp [MAX_ARGS+1];    // copy of execute.envp
    char sFunctionName [1024];
    char sFunctionName2 [1024];

    char * sBuf;

    SECURITY_ATTRIBUTES sa;
    PROCESS_INFORMATION piProcInfo;
    wchar_t * sArgvW;
    wchar_t * sArgvW2;

    sa.nLength                  = sizeof( SECURITY_ATTRIBUTES );
    sa.bInheritHandle           = TRUE;
    sa.lpSecurityDescriptor     = NULL;

    memset( &piProcInfo, 0, sizeof(piProcInfo) );
 
    strHeader sHeader;

    sRs = recv_nn(aFd, (char *)&sExecute, sizeof(strExecute));    //2.recv execute

    if(sRs == -1)
    {
        _printf("%d recv error\n", __LINE__);
    }

    sBuf = (char *) malloc(1024 + 1);
    if(sBuf == NULL)
    {
        _printf("malloc error\n");
        sHeader.type = htonl(FAILURE);
        sHeader.size = htonl(0);
        sRs = send(aFd, (const char *)&sHeader, sizeof(strHeader), 0); //3.send header
        if(sRs == -1)
        {
            _printf("%d send error\n", __LINE__);
        }
        return sError;
    }

    sArgc = ntohl(sExecute.argc);
    if(sArgc > MAX_ARGS)
    {
        _printf("sArgc[%d] is larger than MAX_ARGS[%d]\n", sArgc, MAX_ARGS);
    }
    sEnvc = ntohl(sExecute.envc);
    if(sEnvc > MAX_ARGS)
    {
        _printf("sEnvc[%d] is larger than MAX_ARGS[%d]\n", sEnvc, MAX_ARGS);
    }

    strcpy(sFunctionName, sExecute.function);
    strcpy(sFunctionName2, sExecute.function);
        
    sArgv[0] = sFunctionName;
    for(sLoop = 0; sLoop < sArgc; sLoop++)
    {
        sArgv[sLoop + 1] = sExecute.argv[sLoop];
        strcat(sFunctionName2, " ");
        strcat(sFunctionName2, sExecute.argv[sLoop]);
    }
    _printf("%s\n", sFunctionName2);
    sArgv[sLoop + 1] = 0;
    for(sLoop = 0; sLoop < sEnvc; sLoop++)
    {
        sEnvp[sLoop] = sExecute.envp[sLoop];
    }
    sEnvp[sLoop] = 0;

    sArgvW = wce_mbtowc(sArgv[0]);
    sArgvW2 = wce_mbtowc(sFunctionName2);

    sError = CreateProcess( sArgvW,
                            sArgvW2,      // command line
                            NULL,         // process security attributes
                            NULL,         // primary thread security attributes
                            FALSE,        // handles are inherited
                            0,            // creation flags
                            NULL,         // use parent's environment
                            NULL,         // use parent's current directory
                            NULL,         // STARTUPINFO pointer
                            &piProcInfo); // receives PROCESS_INFORMATION

    if(sError == 0)
    {
        _printf("CreateProcess error\n");
    }

    memset(sBuf, '\0', 1024); 

    sHeader.type = htonl(SUCCESS);
    sHeader.size = htonl(0);
    sRs = send(aFd, (const char *)&sHeader, sizeof(strHeader), 0);// 6.send header
    if(sRs == -1)
    {
        _printf("%d send error\n", __LINE__);
    }

    sError = SUCCESS;
    free(sBuf);
    free(sArgvW);
    free(sArgvW2);

    return sError; 
#endif
}    // end executeOpt

int getFile(int aFd)
{
    char * sBuf;
    char sFileName[1024];
    int sFd;
    int sFileSize = 0;
    int sFileLen;
    int sError = FAILURE;
    int sRs;

    strPathName sPath;
    strHeader sHeader;
    strFileInfo sFileInfo;

    sRs = recv_nn(aFd, (char *) &sPath, sizeof(strPathName));    // 2.recv file sPath

    if(sRs == -1)
    {
        _printf("%d recv error\n", __LINE__);
    }

    strcpy(sFileName, sPath.name);

    sBuf = (char *) malloc(MAX_BUF_SIZE);
    if(sBuf == NULL)
    {
        sHeader.type = htonl(FAILURE);
        sHeader.size = htonl(0);
        sRs = send(aFd, (const char *)&sHeader, sizeof(strHeader), 0);    // 3.send header
        if(sRs == -1)
        {
            _printf("%d send error\n", __LINE__);
        }

        return sError;
    }

    sFd = open(sFileName, O_RDONLY, 0);
    if(sFd == -1)
    {
        _printf("open error\n");
        sHeader.type = htonl(FAILURE);
        sHeader.size = htonl(0);
        sRs = send(aFd, (const char *)&sHeader, sizeof(strHeader), 0);    // 3.send header
        if(sRs == -1)
        {
            _printf("%d send error\n", __LINE__);
        }

        free(sBuf);
        return sError;
    }
    else
    {
        sHeader.type = htonl(SUCCESS);
        sHeader.size = htonl(sizeof(strFileInfo));
        sRs = send(aFd, (const char *)&sHeader, sizeof(strHeader), 0);    // 3.send header
        if(sRs == -1)
        {
            _printf("%d send error\n", __LINE__);
        }
    }

    memset (sBuf, 0, MAX_BUF_SIZE);
#if defined(UNDER_CE)
    sFileSize = GetFileSize((HANDLE)sFd, NULL) ; 
#else
    sFileSize = lseek(sFd, -1, SEEK_END);
    sFileSize++;
#endif

    strcpy(sFileInfo.name, sFileName);
    sFileInfo.size = htonl(sFileSize);
    sRs = send(aFd, (const char *)&sFileInfo, sizeof(strFileInfo), 0);    // 4.send file info
    if(sRs == -1)
    {
        _printf("%d send error\n", __LINE__);
    }

    sHeader.type = htonl(SUCCESS);
    
    if(sFileSize == 0)
    {
        sError = SUCCESS;
        sHeader.type = htonl(SUCCESS);
        sHeader.size = htonl(0);
        sRs = send(aFd, (const char *)&sHeader, sizeof(strHeader), 0);    // 5.send header
                
        if(sRs == -1)        
        {
            _printf("%d send error\n", __LINE__);
        }
        free(sBuf);
        close(sFd);
        return sError;
    }

    lseek(sFd, 0, SEEK_SET);
    while((sFileLen = read(sFd, sBuf, MAX_BUF_SIZE)) >= 0)    // read file
    {
        sHeader.size = htonl(sFileLen);
        sRs = send(aFd, (const char *)&sHeader, sizeof(strHeader), 0);    // 5.send header

        if(sRs == -1)
        {
            _printf("%d send error\n", __LINE__);
        }

        sRs = send(aFd, sBuf, sFileLen, 0);        // 6.send file
        if(sRs == -1)
        {
            _printf("%d send error\n", __LINE__);
        }
        sRs = recv_nn(aFd, (char *) &sHeader, sizeof(strHeader));//7.recv header

        if(sRs == -1)
        {
            _printf("%d recv error\n", __LINE__);
        }
        if(ntohl(sHeader.type) == FAILURE)
        {
            sRs = send(aFd, (const char *)&sHeader, sizeof(strHeader), 0);
            if(sRs == -1)
            {
                _printf("%d send error\n", __LINE__);
            }
            _printf("error from host\n");
            break;
        }
        sFileSize -= sFileLen;

        sHeader.type = htonl(SUCCESS);
        if(sFileSize <= 0)
        {
            sError = SUCCESS;
            sHeader.size = htonl(0);
            sRs = send(aFd, (const char *)&sHeader, sizeof(strHeader), 0);//8.send header
            if(sRs == -1)
            {
                _printf("%d send error\n", __LINE__);
            }
            break;
        }
    }

    free(sBuf);
    close(sFd);
    return sError;
}

int copyFile(int aFd)
{
    char * sBuf;
    int sSrcFd;
    int sDestFd;
    int sStrLen = 0;
    int sError = FAILURE;
    int sRs;
    
    strHeader sHeader;
    strCopyFile SCopyFile;
                
    sRs = recv_nn(aFd, (char *)&SCopyFile, sizeof(strCopyFile));

    if(sRs == -1)
    {
        _printf("%d recv error\n", __LINE__);
    }

    sBuf = (char *) malloc(BUF_SIZE);

    if(sBuf == NULL)
    {
        sHeader.type = htonl(FAILURE);
        sHeader.size = htonl(0);
        sRs = send(aFd, (const char *)&sHeader, sizeof(strHeader), 0);
        if(sRs == -1)
        {
            _printf("%d send error\n", __LINE__);
        }
        return sError;
    }

    sSrcFd = open(SCopyFile.srcName, O_RDONLY, 0);
    if(sSrcFd == -1)
    {
        sHeader.type = htonl(FAILURE);
        sHeader.size = htonl(0);
        sRs = send(aFd, (const char *)&sHeader, sizeof(strHeader), 0);
        if(sRs == -1)
        {
            _printf("%d send error\n", __LINE__);
        }
        free(sBuf);
        return sError;
    }
    sDestFd = open(SCopyFile.destName, O_WRONLY | O_CREAT | O_TRUNC, 0644);

    if(sDestFd == -1)
    {
        sHeader.type = htonl(FAILURE);
        sHeader.size = htonl(0);
        sRs = send(aFd, (const char *)&sHeader, sizeof(strHeader), 0);
        if(sRs == -1)
        {
            _printf("%d send error\n", __LINE__);
        }
        free(sBuf);
        close(sSrcFd);
        return sError;
    }

    while((sStrLen = read(sSrcFd, sBuf, BUF_SIZE)) > 0)
    {
        write(sDestFd, sBuf, sStrLen);
    }

    _printf("copy [%s] to [%s]\n", SCopyFile.srcName, SCopyFile.destName);
    sHeader.type = htonl(SUCCESS);
    sHeader.size = htonl(0);
    sRs = send(aFd, (const char *)&sHeader, sizeof(strHeader), 0);
    if(sRs == -1)
    {
        _printf("%d send error\n", __LINE__);
    }
    sError = SUCCESS;

    close(sSrcFd);
    close(sDestFd);
    free(sBuf);

    return sError;
}



int handleFile(int aFd, int opt)
{
    int sError = FAILURE;
    strPathName sPath;
    strHeader sHeader;
    int sRs;

    sRs = recv_nn(aFd, (char *)&sPath, sizeof(strPathName));

    if(sRs == -1)
    {
        _printf("%d recv error\n", __LINE__);
    }

    if(opt == MKDIR)
    {
        sError = mkdir(sPath.name, 0755);
    }
    else if(opt == RMDIR)
    {
        sError = rmdir(sPath.name);
    }
    else if(opt == DELETEFILE)
    {
        sError = remove(sPath.name);
    }
    if(sError == -1)
    {
        sHeader.type = htonl(FAILURE);
    }
    else if(sError == 0)
    {
        sHeader.type = htonl(SUCCESS);
    }
    sHeader.size = htonl(0);

    sRs = send(aFd, (const char *)&sHeader, sizeof(strHeader), 0);
    
    if(sRs == -1)
    {
        _printf("%d send error\n", __LINE__);
    }

    if(sError == 0)
    {
        sError = SUCCESS;
    }
    else if(sError == -1)
    {
        sError = FAILURE;
    }

    return sError;
}

int putFile(int aFd)
{
    char * sBuf;
    int sFileSize;
    int sFileLen;
    int sFd;
    int sError = FAILURE;
    int sRs;

    strHeader sHeader;
    strFileInfo sFileInfo;
    strMessage msg;

    sRs = recv_nn(aFd, (char *)&sFileInfo, sizeof(strFileInfo));    // 2.recv file info
    
    if(sRs == -1)
    {
        _printf("%d recv error\n", __LINE__);
    }

    sFileSize = ntohl(sFileInfo.size);

    sBuf = (char *) malloc(MAX_BUF_SIZE);
    if(sBuf == NULL)
    {
        sHeader.type = htonl(FAILURE);
        sHeader.size = htonl(0);
        sRs = send(aFd, (const char *)&sHeader, sizeof(strHeader), 0); //3.send header
        if(sRs == -1)
        {
            _printf("%d send error\n", __LINE__);
        }
        free(sBuf);
        return sError;
    }

    sFd = open(sFileInfo.name, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if(sFd == -1)                            // if fail to file open
    {
        _printf("open error\n");
        sHeader.type = htonl(FAILURE);
        sHeader.size = htonl(0);
        sRs = send(aFd, (const char *)&sHeader, sizeof(strHeader), 0); //3.send header
        if(sRs == -1)
        {
            _printf("%d send error\n", __LINE__);
        }
        free(sBuf);
        return sError;
    }
    else                // send confirm message
    {
        sHeader.type = htonl(SUCCESS);
        sHeader.size = htonl(0);
        sRs = send(aFd, (const char *)&sHeader, sizeof(strHeader), 0);//3.send header
        if(sRs == -1)
        {
            _printf("%d send error\n", __LINE__);
        }
        if(sFileSize == 0)
        {
            sError = SUCCESS;
            close(sFd);
            free(sBuf);
            return sError;
        }
    }
    sRs = recv_nn(aFd, (char *) &sHeader, sizeof(strHeader));//4.recv header
    if(sRs == -1)
    {
        _printf("%d recv error\n", __LINE__);
    }
    sFileLen = ntohl(sHeader.size);

    while((sFileLen = recv_nn(aFd, (char *) sBuf, sFileLen)) > 0)
    {                            // 5. recv file
        if(sFileSize < sFileLen)    // file size is less than sBuf size
        {
            sFileLen = write(sFd, sBuf, sFileSize);
        }
        else                    // file size is larger than sBuf size
        {
            sFileLen = write(sFd, sBuf, sFileLen);
        }
        sFileSize -= sFileLen;            // decrease left file size

        if(sFileSize <= 0)    /// left file size is 0 or less than 
        {
            sError = SUCCESS;
            sHeader.type = htonl(SUCCESS);
            sHeader.size = htonl(0);
            sRs = send(aFd, (const char *)&sHeader, sizeof(strHeader), 0);//6.send header
            if(sRs == -1)
            {
                _printf("%d send error\n", __LINE__);
            }
            break;
        }
        else if(sFileLen == -1)                // fail to read file
        {
            _printf("put error\n");
            sHeader.type = htonl(FAILURE);
            sHeader.size = htonl(sizeof(strMessage));
            sRs = send(aFd, (const char *)&sHeader, sizeof(strHeader), 0);//6.send header
            if(sRs == -1)
            {
                _printf("%d send error\n", __LINE__);
            }
            strcpy(msg.msg, "put error");
            sRs = send(aFd, (const char *)&msg, sizeof(strMessage), 0);//7.send message
            if(sRs == -1)
            {
                _printf("%d send error\n", __LINE__);
            }
            break;
        }
        else
        {
            sHeader.type = htonl(SUCCESS);
            sHeader.size = htonl(0);
            sRs = send(aFd, (const char *)&sHeader, sizeof(strHeader), 0);//6.send header
            if(sRs == -1)
            {
                _printf("%d send error\n", __LINE__);
            }
            sRs = recv_nn(aFd, (char *) &sHeader, sizeof(strHeader));
            if(sRs == -1)
            {
                _printf("%d recv error\n", __LINE__);
            }
            sFileLen = ntohl(sHeader.size);
        }
    }

    close(sFd);                                // close file pointer
    free(sBuf);
    return sError;
}

int recv_nn( int aFd, char *aBuffer, int aSize )
{
    int sRs = 0;           // recv size
    int sSize = 0;          // total recv size
    int sCursor = 0;        // buffer cursor
    int sGetSize = 1024;    // get size

    while( 1 )
    {
        if((aSize - sSize) < sGetSize)
        {
            sGetSize = aSize - sSize;
        }

        sRs = recv( aFd, &aBuffer[sCursor], sGetSize, 0 );

        if( sRs < 0 )
        {
            return -1;
        }
 
        sSize += sRs; 

        if( aSize == sSize )
        {
            break;
        }
        else
        {
            sCursor += sRs;
        }
    }

    return sSize; 
}

void _printf( const char * format, ... )
{
    char         buf[4096];
    va_list      ap;
    FILE       * sFd;

#if defined(UNDER_CE)
    int          lastError = GetLastError();
#else
    int          lastError = errno;
#endif

    sFd = fopen("stdout.txt" , "a+");

    memset(buf, '\0', sizeof(buf));

    time_t       timet;
    struct  tm * now; 

    time(&timet);
    now = localtime(&timet);

    fprintf( sFd,
             "[%4d/%02d/%02d %02d:%02d:%02d] (%d) ",
             now->tm_year + 1900,
             now->tm_mon + 1,
             now->tm_mday,
             now->tm_hour,
             now->tm_min,
             now->tm_sec,
             lastError);

    va_start(ap, format);

    vsnprintf(buf, 4096, format, ap);

    va_end(ap);

    fwrite(buf, strlen(buf), 1, sFd);

    fclose(sFd);
}

//CE에서는 main 함수의 이름이 다르다.
#if defined(UNDER_CE)
int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPTSTR lpCmdLine, int nCmdShow)
{
    WORD sVersion = MAKEWORD(1, 1);
    WSADATA sWsaData = { 0 };

    (void)WSAStartup(sVersion, &sWsaData);

    return main();
}
#endif
