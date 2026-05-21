/*
   NAME
    uttTimeStat.cpp - QCU TimeStat

   DESCRIPTION

   PUBLIC FUNCTION(S)

   PRIVATE FUNCTION(S)

   NOTES

   MODIFIED   (MM/DD/YY)
*/
#include <idl.h>
#include <string.h>
#include <math.h>
#include <stdarg.h>

#include <uttTimeStat.h>

static int doubleCompare(const void *num1, const void *num2)
{
    SDouble tmp1, tmp2;
    tmp1 = *(SDouble*) num1;
    tmp2 = *(SDouble*) num2;
    
    if (tmp1 < tmp2)
        return -1;
    else if (tmp1 > tmp2)
        return 1;
    else
        return 0;
}

/*--------------------- uttTimeStat ---------------------------*/
/*
  NAME
   uttTimeStat -

  DESCRIPTION

  ARGUMENTS

  RETURNS

  NOTES
*/
uttTimeStat::uttTimeStat()
{
	idlOS::strncpy(time_name_, "Run Time", 60);
    time_name_[60]             = 0;
    times_     = NULL;
    size_      = 0;
    curr_size_ = 0;
}

uttTimeStat::~uttTimeStat()
{
	if (times_)
        free(times_);
}
    
SInt uttTimeStat::add(uttTime* qc)
{
    if (curr_size_ >= size_)
    {
        return -1;
    }
    times_[curr_size_++] = qc;
    return 0;
}

void uttTimeStat::reset()
{
    int inx;

    if (times_)
    {
        for (inx = 0; inx < curr_size_; inx++)
        {
            if (times_[inx] != NULL)
            {
                delete times_[inx];
            }
        }
        free(times_);
        times_ = NULL;
    }
    size_      = 0;
    curr_size_ = 0;
}

/*--------------------- uttTimeStat ---------------------------*/
/*
  NAME
   uttTimeStat -

  DESCRIPTION

  ARGUMENTS

  RETURNS

  NOTES
*/

void uttTimeStat::setName(const char * t_name)
{
	idlOS::strncpy(time_name_, t_name, 60);
    time_name_[60] = 0;
}

SInt uttTimeStat::setSize(int t_size)
{
    if((times_ = (uttTime**)malloc(sizeof(uttTime*)*t_size)) == NULL)
    {
        idlOS::printf("Memory Allocation error!!! --- %s(%d)\n",
                      __FILE__, __LINE__);
        return -1;
    }
    size_ = t_size;

    return 0;
}

SDouble uttTimeStat::median(UTTTimeClass tc, UTTTimeScale ts)
{
    int inx;
    SDouble* tmp_time;
    SDouble  rtn_time;

    if (curr_size_ == 0)
    {
        return 0.0;
    }
    
    if (curr_size_ == 1)
    {
        return times_[0]->getTime(tc, ts);
    }

    tmp_time = (SDouble*) malloc(sizeof(SDouble)*curr_size_);

    for (inx = 0; inx < curr_size_; inx++)
    {
        tmp_time[inx] = times_[inx]->getTime(tc, ts);
    }

    qsort((void*)tmp_time, (size_t) curr_size_, sizeof(SDouble), doubleCompare);

    if (curr_size_%2 == 0)
        rtn_time = tmp_time[ (curr_size_ -1)/2];
    else
        rtn_time = tmp_time[ curr_size_/2 ];

    free(tmp_time);
    return rtn_time;
}

SDouble uttTimeStat::avg(UTTTimeClass tc, UTTTimeScale ts)
{
    int inx;
    SDouble sum = 0.0;

    if (curr_size_ == 0)
    {
        return 0.0;
    }
    
    for (inx = 0; inx < curr_size_; inx++)
    {
        sum += times_[inx]->getTime(tc, ts);
    }

    return sum/curr_size_;
}

SDouble uttTimeStat::stddev(UTTTimeClass tc, UTTTimeScale ts)
{
    int     inx;
    SDouble sum = 0.0;
    SDouble sqr_sum = 0.0;
    SDouble tmp_time;

    if (curr_size_ == 0)
    {
        return 0.0;
    }
    
    for (inx = 0; inx < curr_size_; inx++)
    {
        tmp_time = times_[inx]->getTime(tc, ts);
        sum += tmp_time;
        sqr_sum += tmp_time * tmp_time;
    }

    return sqrt((curr_size_*sqr_sum - sum*sum) / (curr_size_*(curr_size_-1)));
}

SDouble uttTimeStat::min(UTTTimeClass tc, UTTTimeScale ts)
{
    int     inx;
    SDouble min_time;

    if (curr_size_ == 0)
    {
        return 0.0;
    }
    
    min_time = times_[0]->getTime(tc, ts);

    for (inx = 1; inx < curr_size_; inx++)
    {
        if (times_[inx]->getTime(tc, ts) < min_time)
        {
            min_time = times_[inx]->getTime(tc, ts);
        }
    }

    return min_time;
}

SDouble uttTimeStat::max(UTTTimeClass tc, UTTTimeScale ts)
{
    int     inx;
    SDouble max_time;

    if (curr_size_ == 0)
    {
        return 0.0;
    }
    
    max_time = times_[0]->getTime(tc, ts);

    for (inx = 1; inx < curr_size_; inx++)
    {
        if (times_[inx]->getTime(tc, ts) > max_time)
        {
            max_time = times_[inx]->getTime(tc, ts);
        }
    }

    return max_time;
}

void   uttTimeStat::printStat(UTTTimeClass tc, UTTTimeScale ts)
{
    SDouble t_min   =-1;
    SDouble t_max   =-1;
    SDouble t_stddev=-1;
    SDouble t_avg   =-1;
    SDouble t_median=-1;
    
    if (curr_size_ == 0)
    {
        return;
    }
    
    t_min = min(tc,ts);
    t_max = max(tc,ts);
    t_stddev = stddev(tc,ts);
    t_avg = avg(tc,ts);
    t_median = median(tc,ts);

    idlOS::printf("%s >>> (scale: %d) min = %.4f, max = %.4f, stddev = %.4f,"
                  "avg = %.4f, median = %.4f\n",
                  time_name_, ts, t_min, t_max, t_stddev, t_avg, t_median);
}

void   uttTimeStat::printStat(UTTTimeClass tc, UTTTimeScale ts, int n, ...)
{
    UTTTimeStat t_stat;
    SDouble     t_min   =-1;
    SDouble     t_max   =-1;
    SDouble     t_stddev=-1;
    SDouble     t_avg   =-1;
    SDouble     t_median=-1;
    int         inx;
    
    if (curr_size_ == 0)
    {
        return;
    }
    
    va_list ap;
    va_start(ap, n);
    for (inx = 0; inx < n; inx++)
    {
        t_stat = (UTTTimeStat)va_arg(ap, SInt); /* BUGBUG gcc 2.96 */
        switch(t_stat)
        {
        case UTT_MIN:
            t_min = min(tc,ts);
            break;
        case UTT_MAX:
            t_max = max(tc,ts);
            break;
        case UTT_STDDEV:
            t_stddev = stddev(tc,ts);
            break;
        case UTT_AVG:
            t_avg = avg(tc,ts);
            break;
        case UTT_MEDIAN:
            t_median = median(tc,ts);
            break;
        default:
            break;
        }
    }
    va_end(ap);

    idlOS::printf("%s >>> (scale: %d) min = %.4f, max = %.4f, stddev = %.4f,"
                  "avg = %.4f, median = %.4f\n",
                  time_name_, ts, t_min, t_max, t_stddev, t_avg, t_median);
}

void uttTimeStat::show()
{
    int inx;
    for(inx=0; inx < curr_size_; inx++)
    {
        times_[inx]->showAutoScale();
    }
}
            
        










