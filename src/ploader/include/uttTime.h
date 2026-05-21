#ifndef	_UTT_TIME_H_
#define	_UTT_TIME_H_

/*BUGBUG_NT*/
#if !defined(VC_WIN32)
#    include <sys/time.h>
#    include <sys/times.h>
#endif /*!VC_WIN32*/
/*BUGBUG_NT ADD*/
enum UTTTimeClass {UTT_WALL_TIME, UTT_USER_TIME, UTT_SYS_TIME};
enum UTTTimeScale {UTT_SEC, UTT_MSEC, UTT_USEC};

class uttTime 
{
public:
    uttTime();
    void    setName(const char * t_name);
    void    start();
    void    stop();
    void    finish();
    void    reset();
    void    show();
    void    print(UTTTimeScale ts=UTT_MSEC);
    void    println(UTTTimeScale ts=UTT_MSEC);
    void    showAutoScale();
    SInt    getMicroseconds();
    SDouble getTime(UTTTimeClass tc, UTTTimeScale ts);
    SDouble getMicroSeconds(UTTTimeClass tc);
    SDouble getMilliSeconds(UTTTimeClass tc);
    SDouble getSeconds(UTTTimeClass tc);
    /*
    SInt getMicrosecondsUser();
    SInt getMicrosecondsSystem();
    float getMilliseconds();
    float getMillisecondsUser();
    float getMillisecondsSystem();
    */
private:
    SChar      time_name[61];
    struct tms start_time_tick;
    struct tms end_time_tick;
    timeval    start_time;
    timeval    end_time;
/*BUGBUG_NT*/
#if defined(VC_WIN32)
    SLong     m_seconds_wallclock;
    SLong     m_microseconds_wallclock;
    SLong     m_microseconds_user;
    SLong     m_microseconds_system;
#else
    ULong     m_seconds_wallclock;
    ULong     m_microseconds_wallclock;
    ULong     m_microseconds_user;
    ULong     m_microseconds_system;
#endif /*VC_WIN32*/
/*BUGBUG_NT*/
};

#endif

