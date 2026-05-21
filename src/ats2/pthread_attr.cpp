
/*
pthread_attr.c

POSIX wrapper layer for windows threads

Copyright (C) 2005  Rajulu Ponnada

License: LGPL (see COPYING file in this distribution)

contact Rajulu Ponnada at open.ponnada@gmail.com
*/


#include "_pthread.h"
#include "_errno.h"

int pthread_attr_init(pthread_attr_t *attr)
{
	attr->stackSize = 0;
	attr->stackAddr = NULL;
	attr->creationFlags = 0;  /*alternative is CREATE_SUSPENDED*/
	attr->threadAttributes = NULL;  /*can childthreads inherit attributes*/
	attr->detachState = PTHREAD_CREATE_JOINABLE;
	attr->contentionScope = PTHREAD_SCOPE_PROCESS;
	return 0;
}

int pthread_attr_destroy(pthread_attr_t *attr)
{
	/*nothing to implement*/
	return 0;
}


int   pthread_attr_getdetachstate(const pthread_attr_t *attr, int *detachstate)
{
	if(attr && detachstate)
		*detachstate = attr->detachState;

	return 0;
}

int   pthread_attr_getguardsize(const pthread_attr_t *attr, size_t *guardsize)
{
	return 0;
}

int   pthread_attr_getinheritsched(const pthread_attr_t *attr, int *inheritsched)
{
	return 0;
}

//int   pthread_attr_getschedparam(const pthread_attr_t *, struct sched_param *);

int   pthread_attr_getschedpolicy(const pthread_attr_t *attr, int *policy)
{
	return 0;
}

int   pthread_attr_getscope(const pthread_attr_t *attr, int *scope)
{
	if(scope && attr)
		*scope = attr->contentionScope;

	return 0;
}

int   pthread_attr_getstackaddr(const pthread_attr_t *attr, void **stackaddr)
{
	if(stackaddr && attr)
		*stackaddr = attr->stackAddr;

	return 0;
}

int   pthread_attr_getstacksize(const pthread_attr_t *attr, size_t *stacksize)
{
	if(stacksize && attr)
		*stacksize = attr->stackSize;

	return 0;
}

int   pthread_attr_setdetachstate(pthread_attr_t *attr, int detachstate)
{
	/*check the validity of detach state*/
	if((detachstate != PTHREAD_CREATE_JOINABLE) && (detachstate != PTHREAD_CREATE_DETACHED))
		return EINVAL;
	 
	/*set the deatch state*/
	if(attr)
		attr->detachState = detachstate;

	return 0;
}

int   pthread_attr_setguardsize(pthread_attr_t *attr, size_t guardsize)
{
	return 0;
}

int   pthread_attr_setinheritsched(pthread_attr_t *attr, int inheritsched)
{
	return 0;
}

//int   pthread_attr_setschedparam(pthread_attr_t *, const struct sched_param *);

int   pthread_attr_setschedpolicy(pthread_attr_t *attr, int policy)
{
	return 0;
}

int   pthread_attr_setscope(pthread_attr_t *attr, int scope)
{
	/*check the validity of connection scope*/
	if((scope != PTHREAD_SCOPE_PROCESS) && (scope != PTHREAD_SCOPE_SYSTEM))
		return ENOTSUP;
	 

	/*set the connection scope*/
	if(attr)
		attr->contentionScope = scope;

	return 0;
}

int   pthread_attr_setstackaddr(pthread_attr_t *attr, void *stackaddr)
{
	if(attr && stackaddr)
		attr->stackAddr = stackaddr;

	return 0;
}

int   pthread_attr_setstacksize(pthread_attr_t *attr, size_t stacksize)
{
	/*if(stacksize < PTHREAD_STACK_MIN || stacksize > MAX_SYS_STACK_SIZE)
		return EINVAL;
	 */

	if(attr)
		attr->stackSize = stacksize;

	return 0;
}

