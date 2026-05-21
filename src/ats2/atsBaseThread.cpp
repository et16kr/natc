#include "atsBaseThread.h"

/*----------------------- staticRunner --------------------------------
     NAME
	     static Runner

     DESCRIPTION
		Private 함수로서 해당 클래스의 멤버 함수인
        run()을 쓰레드로 동작시킨다.
        
     ARGUMENTS
     	Arg : 클래스 포인터 (일반적으로 this)
        
     RETURNS
     	언제나 NULL
----------------------------------------------------------------------------*/
void *atsBaseThread::staticRunner(void *Arg)
{

#define IDE_FN "void *atsBaseThread::staticRunner(void *Arg)"

#if defined(ITRON)
    /* empty */
    return NULL;
#else
    atsBaseThread *thr_ = (atsBaseThread *)Arg;
    thr_->started_      = ID_TRUE;
    thr_->run();
    return NULL;
#endif

#undef IDE_FN
}


/*--------------------------- start  ---------------------------------------
     NAME
	     start()

     DESCRIPTION
     	해당 클래스를 쓰레드로 동작시킨다. (run()이 호출됨)
        
     ARGUMENTS
     	없음
        
     RETURNS
     	idlOS::thr_create() 함수의 리턴값
----------------------------------------------------------------------------*/
IDE_RC atsBaseThread::start()
{

#define IDE_FN "SInt atsBaseThread::start()"
    SInt rc;

    pthread_attr_t attr;

    pthread_attr_init( &attr );

    pthread_attr_setstacksize( &attr, size_ );

    rc = pthread_create( &tid_,
                         &attr,
                         staticRunner,
                         this );

    IDE_TEST_RAISE( rc != 0, error);
    
    return IDE_SUCCESS;

    IDE_EXCEPTION( error );
    IDE_EXCEPTION_END;

    return IDE_FAILURE;
    

#undef IDE_FN
}

/*--------------------------- isStarted()  ---------------------------------------
     NAME
	     isStated()

     DESCRIPTION
     	쓰레드가 생성되었는지 검사한다.
        
     ARGUMENTS
     	없음
        
     RETURNS
     	생성되었으면 IDE_SUCCESS,
        생성되지 않았으면, IDE_FAILURE 
----------------------------------------------------------------------------*/

idBool atsBaseThread::isStarted()
{

#define IDE_FN "SInt atsBaseThread::isStarted()"

    return started_;


#undef IDE_FN
}

#define IDT_WAIT_LOOP_PER_SECOND     10
// 쓰레드로 동작할 때 까지 대기
IDE_RC atsBaseThread::waitToStart(UInt second)
{
    return IDE_SUCCESS;
}

void atsBaseThread::setFlag(SLong flag)
{

#define IDE_FN "void atsBaseThread::setFlag(SLong flag)"

    flags_ = flag;


#undef IDE_FN
}

IDE_RC atsBaseThread::isAlive(idBool& aAlive)
{
#define IDE_FN "SInt atsBaseThread::isAlive()"

    IDE_TEST_RAISE( started_ != ID_TRUE,
                    not_started);

    if (pthread_kill(getTid(), 0) != 0)
    {
        aAlive = ID_FALSE;
    }
    else
    {
        aAlive = ID_TRUE;
    }
    return IDE_SUCCESS;
    
    IDE_EXCEPTION(not_started);
    {
        IDE_SET(ideSetErrorCode(idERR_FATAL_THR_NOT_CREATED_BUT_USED));
    }
    IDE_EXCEPTION_END;
    return IDE_FAILURE;

#undef IDE_FN
    
}
