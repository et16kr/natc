
/*
pthread.h

POSIX wrapper layer for windows threads

Copyright (C) 2005  Rajulu Ponnada

License: LGPL (see COPYING file in this distribution)

contact Rajulu Ponnada at open.ponnada@gmail.com
*/


#ifndef _PTHREAD_H_
#define _PTHREAD_H_

#include <windows.h>

#define NONZERO (!(0))

#define PTHREAD_CANCEL_ASYNCHRONOUS 1
#define PTHREAD_CANCEL_ENABLE       2
#define PTHREAD_CANCEL_DEFERRED     3
#define PTHREAD_CANCEL_DISABLE      4
#define PTHREAD_CANCELED            5
#define PTHREAD_COND_INITIALIZER    6
#define PTHREAD_CREATE_DETACHED     7
#define PTHREAD_CREATE_JOINABLE     8
#define PTHREAD_EXPLICIT_SCHED      9
#define PTHREAD_INHERIT_SCHED       10
#define PTHREAD_MUTEX_DEFAULT       11
#define PTHREAD_MUTEX_ERRORCHECK    12
#define PTHREAD_MUTEX_NORMAL        13
#define PTHREAD_MUTEX_INITIALIZER   14
#define PTHREAD_MUTEX_RECURSIVE     15
#define PTHREAD_ONCE_INIT           16
#define PTHREAD_PRIO_INHERIT		17
#define PTHREAD_PRIO_NONE			18
#define PTHREAD_PRIO_PROTECT		19
#define PTHREAD_PROCESS_SHARED		20	
#define PTHREAD_PROCESS_PRIVATE		21
#define PTHREAD_RWLOCK_INITIALIZER	22
#define PTHREAD_SCOPE_PROCESS		23
#define PTHREAD_SCOPE_SYSTEM		24


typedef struct
{
	LPSECURITY_ATTRIBUTES threadAttributes;
	SIZE_T stackSize;
	void * stackAddr;
	DWORD creationFlags;
	int detachState;
	int contentionScope;
	int policy; /*supported values: SCHED_FIFO, SCHED_RR, and SCHED_OTHER*/
	int inheritSched;
	int detach;
}pthread_attr_t;

typedef struct
{
	HANDLE cond;
	HANDLE mutex;
	
	int signalled;
	int signal_all;
	int num_waiting;
}pthread_cond_t;

typedef struct
{
	int cond_attr;
}pthread_condattr_t;

typedef struct
{
	int key;
}pthread_key_t;

typedef struct
{
	HANDLE mutex;
	int destroyed;
	int init;
	int lockedOrReferenced;
}pthread_mutex_t;

typedef struct
{
	int protocol;
	int pShared;
	int prioCeiling;
	int type;
}pthread_mutexattr_t;

typedef struct pthread_once_t
{
	int once;
}pthread_once_t;

typedef struct pthread_rwlock_t
{
	HANDLE read_event;
	HANDLE write_mutex;
	long readers;
}pthread_rwlock_t;

typedef struct pthread_rwlockattr_t
{
	int lock;
}pthread_rwlockattr_t;

typedef struct
{
	HANDLE handle;
	unsigned int tid;
}pthread_t;


int   pthread_attr_destroy(pthread_attr_t *);
int   pthread_attr_getdetachstate(const pthread_attr_t *, int *);
int   pthread_attr_getguardsize(const pthread_attr_t *, size_t *);
int   pthread_attr_getinheritsched(const pthread_attr_t *, int *);
//int   pthread_attr_getschedparam(const pthread_attr_t *, struct sched_param *);
int   pthread_attr_getschedpolicy(const pthread_attr_t *, int *);
int   pthread_attr_getscope(const pthread_attr_t *, int *);
int   pthread_attr_getstackaddr(const pthread_attr_t *, void **);
int   pthread_attr_getstacksize(const pthread_attr_t *, size_t *);
int   pthread_attr_init(pthread_attr_t *);
int   pthread_attr_setdetachstate(pthread_attr_t *, int);
int   pthread_attr_setguardsize(pthread_attr_t *, size_t);
int   pthread_attr_setinheritsched(pthread_attr_t *, int);
//int   pthread_attr_setschedparam(pthread_attr_t *, const struct sched_param *);
int   pthread_attr_setschedpolicy(pthread_attr_t *, int);
int   pthread_attr_setscope(pthread_attr_t *, int);
int   pthread_attr_setstackaddr(pthread_attr_t *, void *);
int   pthread_attr_setstacksize(pthread_attr_t *, size_t);
int   pthread_cancel(pthread_t);
void  pthread_cleanup_push(void*);
void  pthread_cleanup_pop(int);
int   pthread_cond_broadcast(pthread_cond_t *);
int   pthread_cond_destroy(pthread_cond_t *);
int   pthread_cond_init(pthread_cond_t *, const pthread_condattr_t *);
int   pthread_cond_signal(pthread_cond_t *);
//int   pthread_cond_timedwait(pthread_cond_t *, pthread_mutex_t *, const struct timespec *);
int   pthread_cond_wait(pthread_cond_t *, pthread_mutex_t *);
int   pthread_condattr_destroy(pthread_condattr_t *);
int   pthread_condattr_getpshared(const pthread_condattr_t *, int *);
int   pthread_condattr_init(pthread_condattr_t *);
int   pthread_condattr_setpshared(pthread_condattr_t *, int);
int   pthread_create(pthread_t *, const pthread_attr_t *, void *(*)(void *), void *);
int   pthread_detach(pthread_t);
int   pthread_equal(pthread_t, pthread_t);
void  pthread_exit(void *);
int   pthread_getconcurrency(void);
int   pthread_getschedparam(pthread_t, int *, struct sched_param *);
void *pthread_getspecific(pthread_key_t);
int   pthread_join(pthread_t, void **);
int   pthread_key_create(pthread_key_t *, void (*)(void *));
int   pthread_key_delete(pthread_key_t);
int   pthread_mutex_destroy(pthread_mutex_t *);
int   pthread_mutex_getprioceiling(const pthread_mutex_t *, int *);
int   pthread_mutex_init(pthread_mutex_t *, const pthread_mutexattr_t *);
int   pthread_mutex_lock(pthread_mutex_t *);
int   pthread_mutex_setprioceiling(pthread_mutex_t *, int, int *);
int   pthread_mutex_trylock(pthread_mutex_t *);
int   pthread_mutex_unlock(pthread_mutex_t *);
int   pthread_mutexattr_destroy(pthread_mutexattr_t *);
int   pthread_mutexattr_getprioceiling(const pthread_mutexattr_t *, int *);
int   pthread_mutexattr_getprotocol(const pthread_mutexattr_t *, int *);
int   pthread_mutexattr_getpshared(const pthread_mutexattr_t *, int *);
int   pthread_mutexattr_gettype(const pthread_mutexattr_t *, int *);
int   pthread_mutexattr_init(pthread_mutexattr_t *);
int   pthread_mutexattr_setprioceiling(pthread_mutexattr_t *, int);
int   pthread_mutexattr_setprotocol(pthread_mutexattr_t *, int);
int   pthread_mutexattr_setpshared(pthread_mutexattr_t *, int);
int   pthread_mutexattr_settype(pthread_mutexattr_t *, int);
int   pthread_once(pthread_once_t *, void (*)(void));
int   pthread_rwlock_destroy(pthread_rwlock_t *);
int   pthread_rwlock_init(pthread_rwlock_t *, const pthread_rwlockattr_t *);
int   pthread_rwlock_rdlock(pthread_rwlock_t *);
int   pthread_rwlock_tryrdlock(pthread_rwlock_t *);
int   pthread_rwlock_trywrlock(pthread_rwlock_t *);
int   pthread_rwlock_unlock(pthread_rwlock_t *);
int   pthread_rwlock_wrlock(pthread_rwlock_t *);
int   pthread_rwlockattr_destroy(pthread_rwlockattr_t *);
int   pthread_rwlockattr_getpshared(const pthread_rwlockattr_t *, int *);
int   pthread_rwlockattr_init(pthread_rwlockattr_t *);
int   pthread_rwlockattr_setpshared(pthread_rwlockattr_t *, int);
pthread_t pthread_self(void);
int   pthread_setcancelstate(int, int *);
int   pthread_setcanceltype(int, int *);
int   pthread_setconcurrency(int);
//int   pthread_setschedparam(pthread_t, int , const struct sched_param *);
int   pthread_setspecific(pthread_key_t, const void *);
void  pthread_testcancel(void);
int   pthread_kill(pthread_t, int);


#endif /*_PTHREAD_H_*/
