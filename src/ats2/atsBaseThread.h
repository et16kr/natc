#ifndef O_ATS_BASETHREAD_H
#define O_ATS_BASETHREAD_H   1

#include <common.h>

class atsBaseThread
{
private:
    SLong flags_;
    SInt size_;
    pthread_t tid_;
    idBool started_;     // 쓰레드로 시작되었는지 검사
    
    static void *staticRunner(void *);
public:
    atsBaseThread( SInt Stacksize = 1024*1024 ) { size_ = Stacksize; };

    virtual ~atsBaseThread() {};
            
    inline pthread_t getTid()
    {
        return tid_;
    }

    idBool isStarted();
    IDE_RC start();
    IDE_RC waitToStart(UInt second = 0); // forever wait
    IDE_RC isAlive(idBool& aAlive);
    
    void setFlag(SLong flag);
    void resetStarted() { started_ = ID_FALSE; }
    virtual void run() = 0;
    
};

#endif 
