
/*
pthread_mutex.c

POSIX wrapper layer for windows threads

Copyright (C) 2005  Rajulu Ponnada

License: LGPL (see COPYING file in this distribution)

contact Rajulu Ponnada at open.ponnada@gmail.com
*/


#include "_pthread.h"
#include "_errno.h"

/*initialise mutex with attributes*/
int   pthread_mutex_init(pthread_mutex_t *mutex, const pthread_mutexattr_t *attr)
{
	if(mutex)
	{
		if(mutex->init && !mutex->destroyed)
			return EBUSY;

		mutex->mutex = CreateMutex(NULL, FALSE, NULL);
		mutex->destroyed = 0;
		mutex->init = 1;
		mutex->lockedOrReferenced = 0;
	}

	return 0;
}

/*obtain a lock*/
int   pthread_mutex_lock(pthread_mutex_t *mutex)
{
	DWORD ret;

	if(!mutex)
		return EINVAL;

	ret = WaitForSingleObject(mutex->mutex, INFINITE);

	if(ret != WAIT_FAILED)
	{
		mutex->lockedOrReferenced = 1;
		return 0;
	}
	else
		return EINVAL;
}

/*obtain a lock without waiting*/
int   pthread_mutex_trylock(pthread_mutex_t *mutex)
{
	DWORD ret;

	if(!mutex)
		return EINVAL;

	ret = WaitForSingleObject(mutex->mutex, 0);
	
	if(ret != WAIT_FAILED)
	{
		mutex->lockedOrReferenced = 1;
		return 0;
	}

	return EBUSY;
}

/*unlock*/
int   pthread_mutex_unlock(pthread_mutex_t *mutex)
{
	DWORD ret;

	if(!mutex)
		return EINVAL;

	ret = ReleaseMutex(mutex->mutex);

	if(ret != 0)
	{
		mutex->lockedOrReferenced = 0;
		return 0;
	}
	else
		return EPERM;
}

/*destroy the mutex required no longer*/
int   pthread_mutex_destroy(pthread_mutex_t *mutex)
{
	if(!mutex)
		return EINVAL;

	if(mutex->lockedOrReferenced)
		return EBUSY;

	mutex->destroyed = 1;
	return 0;
}

int   pthread_mutex_getprioceiling(const pthread_mutex_t *mutex, int *prioceiling)
{
	return 0;
}

int   pthread_mutex_setprioceiling(pthread_mutex_t *mutex, int prioceiling, int *old_ceiling)
{
	return 0;
}
