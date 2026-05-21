#include "common.h"

struct tm * 
localtime_r (const time_t *timer, struct tm *result) 
{ 
#if defined(STAF_OS_NAME_WIN32)
  SYSTEMTIME tlocal;
  ::GetLocalTime(&tlocal);

  result->tm_sec  = tlocal.wSecond;
  result->tm_min  = tlocal.wMinute;
  result->tm_hour = tlocal.wHour;
  result->tm_mday = tlocal.wDay;
  result->tm_mon  = tlocal.wMonth - 1;
  result->tm_year = tlocal.wYear - 1900;

  return result;
#else

   struct tm *local_result; 
   local_result = localtime (timer); 

   if (local_result == NULL || result == NULL) 
     return NULL; 

   memcpy (result, local_result, sizeof (result)); 
   return result; 
#endif
} 

#if defined(_MSC_VER) || defined(_MSC_EXTENSIONS)
  #define DELTA_EPOCH_IN_MICROSECS  11644473600000000Ui64
#else
  #define DELTA_EPOCH_IN_MICROSECS  11644473600000000ULL
#endif

struct timezone 
{
  int  tz_minuteswest; /* minutes W of Greenwich */
  int  tz_dsttime;     /* type of dst correction */
};
 
int gettimeofday(struct timeval *tv, struct timezone *tz)
{
  FILETIME ft;
  unsigned __int64 tmpres = 0;
  static int tzflag;
 
  if (NULL != tv)
  {
    GetSystemTimeAsFileTime(&ft);
 
    tmpres |= ft.dwHighDateTime;
    tmpres <<= 32;
    tmpres |= ft.dwLowDateTime;
 
    /*converting file time to unix epoch*/
    tmpres /= 10;  /*convert into microseconds*/
    tmpres -= DELTA_EPOCH_IN_MICROSECS; 
    tv->tv_sec = (long)(tmpres / 1000000UL);
    tv->tv_usec = (long)(tmpres % 1000000UL);
  }
 
  if (NULL != tz)
  {
    if (!tzflag)
    {
      _tzset();
      tzflag++;
    }
    tz->tz_minuteswest = _timezone / 60;
    tz->tz_dsttime = _daylight;
  }
 
  return 0;
}

int sleep( unsigned int seconds )
{
    ::Sleep (seconds * 1000L);
    return 0;
}

int usleep( unsigned long useconds )
{
    if (useconds > 500)
        Sleep ((useconds+500)/1000);
    else if (useconds > 0)
        Sleep (1);
    else
        Sleep (0);

    return 0;
}

int kill( pid_t, int )
{
    exit(0);
    return 0;
}
