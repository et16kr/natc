/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: iSQLPassword.cpp 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/
#include <idl.h>
#include <iSQL.h>
#include <iSQLProgOption.h>

SChar *
getpass( const SChar * prompt )
{
    static SChar buf[MAX_PASS_LEN+1];

    SChar          *ptr;
    FILE           *fp;
    SInt            c;

#if defined(VC_WIN32)
    
    DWORD flag;
    BOOL  isConsole;
    
    if ( (fp = stdin) == NULL )
        return NULL;
    
    isConsole = GetConsoleMode( GetStdHandle( STD_INPUT_HANDLE ), &flag );
    
    if ( isConsole )
    {
        (void)SetConsoleMode( GetStdHandle( STD_INPUT_HANDLE ),
                              flag & (~ENABLE_ECHO_INPUT) );
    }
    
    idlOS::fprintf( stdout, "%s", prompt );
    idlOS::fflush( stdout );

#else
    struct termios  term, termsave;
    sigset_t        sig, sigsave;
    
# if defined(HP_HPUX)
    if ( (fp = idlOS::fopen(ctermid(ttyname(0)), "r+")) == NULL )
        return NULL;
# else
    if ( (fp = idlOS::fopen(ctermid(NULL), "r+")) == NULL )
        return NULL;
# endif
    
    setbuf(fp, NULL);
    
    idlOS::sigemptyset(&sig);
    idlOS::sigaddset(&sig, SIGINT);
    idlOS::sigaddset(&sig, SIGTSTP);
    idlOS::sigprocmask(SIG_BLOCK, &sig, &sigsave);
    
    idlOS::tcgetattr(fileno(fp), &termsave);
    term = termsave;
    term.c_lflag &= ~(ECHO | ECHOE | ECHOK | ECHONL);
    idlOS::tcsetattr(fileno(fp), TCSAFLUSH, &term);

    idlOS::fputs(prompt, fp);
    
#endif
    
    ptr = buf;
    while ( (c = getc(fp)) != EOF && c != '\n' )
    {
        if (ptr < &buf[MAX_PASS_LEN])
            *ptr++ = c;
    }
    *ptr = 0;
    
#if defined(VC_WIN32)

    if ( isConsole )
    {
        (void)SetConsoleMode( GetStdHandle( STD_INPUT_HANDLE ), flag );
        idlOS::fprintf( stdout, "\n" );
        idlOS::fflush( stdout );
    }

#else
    
    putc('\n', fp);
    
    idlOS::tcsetattr(fileno(fp), TCSAFLUSH, &termsave);
    
    idlOS::sigprocmask(SIG_SETMASK, &sigsave, NULL);
    idlOS::fclose(fp);
    
#endif
    
    return buf;
}

