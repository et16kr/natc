#ifndef	_UTT_TIMESTAT_H_
#define	_UTT_TIMESTAT_H_

#include <uttTime.h>

enum UTTTimeStat {UTT_MIN=1, UTT_MAX, UTT_STDDEV, UTT_AVG, UTT_MEDIAN};

class uttTimeStat {
public:
    uttTimeStat();
    ~uttTimeStat();

    SInt   add(uttTime* qc);
    void   reset();
    void   show();
    void   printStat(UTTTimeClass tc = UTT_WALL_TIME,
                     UTTTimeScale ts = UTT_MSEC);
    void   printStat(UTTTimeClass tc,
                     UTTTimeScale ts, int n, ...);
    void   setName(const char* name);
    SInt   setSize(int size);
    double median(UTTTimeClass tc = UTT_WALL_TIME,
                  UTTTimeScale ts = UTT_MSEC);
    double avg(UTTTimeClass tc = UTT_WALL_TIME,
               UTTTimeScale ts = UTT_MSEC);
    double stddev(UTTTimeClass tc = UTT_WALL_TIME,
                  UTTTimeScale ts = UTT_MSEC);
    double min(UTTTimeClass tc = UTT_WALL_TIME,
               UTTTimeScale ts = UTT_MSEC);
    double max(UTTTimeClass tc = UTT_WALL_TIME,
               UTTTimeScale ts = UTT_MSEC);

private:
    SChar  time_name_[61];
    int    size_;
    int    curr_size_;
    uttTime** times_;
};
#endif
