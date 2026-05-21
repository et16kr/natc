
/*
pthread.c

POSIX wrapper layer for windows threads

Copyright (C) 2005  Rajulu Ponnada

License: LGPL (see COPYING file in this distribution)

contact Rajulu Ponnada at open.ponnada@gmail.com
*/

//todo: error mapping from win to posix

#include "_pthread.h"
#include "_errno.h"

int pthread_create(pthread_t *thread, const pthread_attr_t *attr, void *(*startup)(void *), void *params)
{
	DWORD threadid;
	HANDLE h;

	if(attr)
		h = CreateThread(attr->threadAttributes, 
							attr->stackSize, 
							(DWORD (WINAPI *)(LPVOID))startup, 
							params, 
							attr->creationFlags, 
							&threadid);
	else
		h = CreateThread(NULL, 
							0, 
							(DWORD (WINAPI *)(LPVOID))startup, 
							params, 
							0, 
							&threadid);
	thread->tid = threadid;

	if(!h)
		return -1;

	if(attr && (attr->detachState == PTHREAD_CREATE_DETACHED))
		CloseHandle(h);
	else
		thread->handle = h;


	return 0;
}

void pthread_exit(void *value_ptr)
{
	if(value_ptr)
		ExitThread(*(DWORD *)value_ptr);
	else
		ExitThread(0);
}

int pthread_equal(pthread_t t1, pthread_t t2)
{
	return (t1.tid == t2.tid);
}

/*ugly implementation; needs an alternative*/
pthread_t pthread_self(void)
{
	static pthread_t thread;

	thread.handle = GetCurrentThread();
	return thread;
}

int pthread_join(pthread_t thread, void **value_ptr)
{
	DWORD ret;

	if(!thread.handle)
	{
		//not joinable; detached thread
		return -1; 
	}

	ret = WaitForSingleObject(thread.handle, INFINITE);
	if(ret == WAIT_FAILED)
		return -1;
	else if((ret == WAIT_ABANDONED) || (ret == WAIT_OBJECT_0)) 
	{
		if(value_ptr)
			GetExitCodeThread(thread.handle, (LPDWORD)value_ptr);
	}
	return 0;
}

int pthread_detach(pthread_t thread)
{
	if(!thread.handle)
		return -1;

	CloseHandle(thread.handle);
	thread.handle = 0;
	return 0;
}

/*will be implemented in future*/
int pthread_kill(pthread_t thread, int sig)
{
	return 0;
}

int   pthread_cancel(pthread_t thread)
{
	return 0;
}

void  pthread_testcancel(void)
{
	return;
}

