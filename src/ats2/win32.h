#include <windows.h>
#include <io.h>
#include <time.h>
#include <winsock.h>
#include <_pthread.h>
#include <malloc.h>

#define F_OK 0
#define strcasecmp ::_stricmp
#define strncasecmp ::_strnicmp
#define access _access
#define getpid _getpid
//#define read _read
#define close _close
#define open _open
//#define write _write
#define lseek _lseek

typedef int pid_t;

int gettimeofday( struct timeval *, struct timezone * );
int sleep( unsigned int );
int usleep( unsigned long );
struct tm * localtime_r( const time_t *, struct tm * );

int kill( pid_t, int );
