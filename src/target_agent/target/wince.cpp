#include <windows.h>
#include <time.h>

//https://trac.xiph.org/browser/trunk/oggdsf/src/lib/helper/wince/wince.c?rev=15626

#define O_RDONLY 0x0001  /* open for reading only */
#define O_WRONLY 0x0002  /* open for writing only */
#define O_RDWR   0x0010  /* open for reading and writing */

#define O_CREAT  0x0100  /* create and open file */
#define O_TRUNC  0x0200  /* open and truncate */

/* char -> wchar_t */ 
wchar_t* wce_mbtowc(const char* a) 
{ 
    int length; 
    wchar_t *wbuf; 
 
    length = MultiByteToWideChar(CP_ACP, 0, a, -1, NULL, 0); 
    wbuf = (wchar_t*)malloc( (length+1)*sizeof(wchar_t) ); 
    MultiByteToWideChar(CP_ACP, 0, a, -1, wbuf, length); 
 
    return wbuf; 
} 
 
/* wchar_t -> char */ 
char* wce_wctomb(const wchar_t* w) 
{ 
    DWORD charlength; 
    char* pChar; 
 
    charlength = WideCharToMultiByte(CP_ACP, 0, w, -1, NULL, 0, NULL, NULL); 
    pChar = (char*)malloc(charlength+1); 
    WideCharToMultiByte(CP_ACP, 0, w, -1, pChar, charlength, NULL, NULL); 
 
    return pChar; 
} 

int vsnprintf(char *buf, size_t size, const char *format, va_list ap)
{
    int result = ::_vsnprintf (buf, size, format, ap);
    // Win32 doesn't 0-terminate the string if it overruns maxlen.
    if ((result == -1) && (size > 0))
    {
        buf[size - 1] = '\0';
        result = (int)size;
    }
    return result;
}

int
snprintf(char *buf, size_t size, const char *format, ...)
{
    int     result;
    va_list ap;

    va_start (ap, format);
    result = vsnprintf(buf, size, format, ap);
    va_end (ap);

    return result;
}

int open(const char *file, int mode, int)
{
    wchar_t *wfile; 
    DWORD access=0, share=0, create=0; 
    HANDLE h; 

    if( (mode&O_RDWR) != 0 ) 
        access = GENERIC_READ|GENERIC_WRITE; 
    else if( (mode&O_RDONLY) != 0 ) 
        access = GENERIC_READ; 
    else if( (mode&O_WRONLY) != 0 ) 
        access = GENERIC_WRITE; 

    if( (mode&O_CREAT) != 0 ) 
        create = CREATE_ALWAYS; 
    else 
        create = OPEN_ALWAYS; 

    wfile = wce_mbtowc(file); 

    h = CreateFileW(wfile, access, share, NULL, create, 0, NULL ); 

    free(wfile); 

    return h==INVALID_HANDLE_VALUE ? -1 : (int)h; 
}

int lseek(int fd, int offset, int origin)
{
    DWORD flag, ret; 

    switch(origin) 
    { 
        case SEEK_SET: flag = FILE_BEGIN;   break; 
        case SEEK_CUR: flag = FILE_CURRENT; break; 
        case SEEK_END: flag = FILE_END;     break; 
        default:       flag = FILE_CURRENT; break; 
    } 
 
    ret = SetFilePointer( (HANDLE)fd, offset, NULL, flag ); 

    return ret==0xFFFFFFFF ? -1 : 0; 
}

size_t read(int fd, void *buffer, size_t length)
{
    BOOL rc; 
    DWORD dw; 
    rc = ReadFile( (HANDLE)fd, buffer, length, &dw, NULL ); 

    return rc==0 ? -1 : (int)dw; 
}

size_t write(int fd, const void *buffer, size_t length)
{
    BOOL rc; 
    DWORD dw; 
    rc = WriteFile( (HANDLE)fd, buffer, length, &dw, NULL ); 

    return rc==0 ? -1 : (int)dw; 
}

int close(int fd)
{
    BOOL rc; 
    rc = CloseHandle( (HANDLE)fd ); 

    return rc==0 ? -1 : 0; 
}

int mkdir(const char *dir, int mode)
{
    wchar_t* wdir; 
    BOOL rc; 

    /* replace with CreateDirectory. */ 
    wdir = wce_mbtowc(dir); 
    rc = CreateDirectoryW(wdir, NULL); 
    free(wdir); 

    return rc==TRUE ? 0 : -1; 
}

int rmdir(const char *dir)
{
    wchar_t *wdir; 
    BOOL rc; 

    /* replace with RemoveDirectory. */ 
    wdir = wce_mbtowc(dir); 
    rc = RemoveDirectoryW(wdir); 
    free(wdir); 

    return rc==TRUE ? 0 : -1; 
}

int remove(const char *file)
{
    wchar_t *wfile; 
    BOOL rc; 

    /* replace with DeleteFile. */ 
    wfile = wce_mbtowc(file); 
    rc = DeleteFileW(wfile); 
    free(wfile); 

    return rc==TRUE ? 0 : -1; 
}

const __int64 _onesec_in100ns = (__int64)10000000; 
//int   timezone, _timezone, altzone; 
int   daylight; 
char *tzname[2]; 
 
/* __int64 <--> FILETIME */ 
static __int64 wce_FILETIME2int64(FILETIME f) 
{ 
    __int64 t; 
 
    t = f.dwHighDateTime; 
    t <<= 32; 
    t |= f.dwLowDateTime; 

    return t; 
} 
 
static FILETIME wce_int642FILETIME(__int64 t) 
{ 
    FILETIME f; 
 
    f.dwHighDateTime = (DWORD)((t >> 32) & 0x00000000FFFFFFFF); 
    f.dwLowDateTime  = (DWORD)( t        & 0x00000000FFFFFFFF); 

    return f; 
} 
 
/* FILETIME utility */ 
static FILETIME wce_getFILETIMEFromYear(WORD year) 
{ 
    SYSTEMTIME s={0}; 
    FILETIME f; 
 
    s.wYear      = year; 
    s.wMonth     = 1; 
    s.wDayOfWeek = 1; 
    s.wDay       = 1; 
 
    SystemTimeToFileTime( &s, &f ); 
 
   return f; 
} 
 
static time_t wce_getYdayFromSYSTEMTIME(const SYSTEMTIME* s) 
{ 
    __int64 t; 
    FILETIME f1, f2; 
 
    f1 = wce_getFILETIMEFromYear( s->wYear ); 
    SystemTimeToFileTime( s, &f2 ); 
 
    t = wce_FILETIME2int64(f2)-wce_FILETIME2int64(f1); 
 
    return (time_t)((t/_onesec_in100ns)/(60*60*24)); 
} 
 
/* tm <--> SYSTEMTIME */ 
static SYSTEMTIME wce_tm2SYSTEMTIME(struct tm *t) 
{ 
    SYSTEMTIME s; 
 
    s.wYear      = t->tm_year + 1900; 
    s.wMonth     = t->tm_mon  + 1; 
    s.wDayOfWeek = t->tm_wday; 
    s.wDay       = t->tm_mday; 
    s.wHour      = t->tm_hour; 
    s.wMinute    = t->tm_min; 
    s.wSecond    = t->tm_sec; 
    s.wMilliseconds = 0; 
 
    return s; 
} 
 
static struct tm wce_SYSTEMTIME2tm(SYSTEMTIME *s) 
{ 
    struct tm t; 
 
    t.tm_year  = s->wYear - 1900; 
    t.tm_mon   = s->wMonth- 1; 
    t.tm_wday  = s->wDayOfWeek; 
    t.tm_mday  = s->wDay; 
    t.tm_yday  = wce_getYdayFromSYSTEMTIME(s); 
    t.tm_hour  = s->wHour; 
    t.tm_min   = s->wMinute; 
    t.tm_sec   = s->wSecond; 
    t.tm_isdst = 0; 
  
    return t; 
} 
  
/* FILETIME <--> time_t */ 
time_t wce_FILETIME2time_t(const FILETIME* f) 
{ 
    FILETIME f1601, f1970; 
    __int64 t, offset; 
  
    f1601 = wce_getFILETIMEFromYear(1601); 
    f1970 = wce_getFILETIMEFromYear(1970); 
  
    offset = wce_FILETIME2int64(f1970) - wce_FILETIME2int64(f1601); 
  
    t = wce_FILETIME2int64(*f); 
  
    t -= offset; 

    return (time_t)(t / _onesec_in100ns); 
} 
  
FILETIME wce_time_t2FILETIME(const time_t t) 
{ 
    FILETIME f, f1970; 
    __int64 time; 
  
    f1970 = wce_getFILETIMEFromYear(1970); 
  
    time = t; 
    time *= _onesec_in100ns; 
    time += wce_FILETIME2int64(f1970); 
  
    f = wce_int642FILETIME(time); 
  
    return f; 
} 
  
/* time.h difinition */
time_t time( time_t *timer ) 
{ 
    SYSTEMTIME s; 
    FILETIME   f; 
 
    if( timer==NULL ) return 0; 
 
    GetSystemTime( &s ); 
 
    SystemTimeToFileTime( &s, &f ); 
 
    *timer = wce_FILETIME2time_t(&f); 

    return *timer; 
} 

struct tm *localtime( const time_t *timer ) 
{ 
    SYSTEMTIME ss, ls, s; 
    FILETIME   sf, lf, f; 
    __int64 t, diff; 
    static struct tm tms; 
 
    GetSystemTime(&ss); 
    GetLocalTime(&ls); 
 
    SystemTimeToFileTime( &ss, &sf ); 
    SystemTimeToFileTime( &ls, &lf ); 
 
    diff = wce_FILETIME2int64(sf) - wce_FILETIME2int64(lf); 
 
    f = wce_time_t2FILETIME(*timer); 
    t = wce_FILETIME2int64(f) - diff; 
    f = wce_int642FILETIME(t); 
 
    FileTimeToSystemTime( &f, &s ); 
 
    tms = wce_SYSTEMTIME2tm(&s); 
 
    return &tms; 
}
