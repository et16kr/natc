/***********************************************************************
 * Copyright 1999-2000, RTBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: uttMemory.cpp 2 2006-04-13 15:48:39Z copyrei $
 **********************************************************************/

/***********************************************************************
 *
 * NAME
 *   uttMemory.h
 *
 * DESCRIPTION
 *   Dynamic memory allocator.
 *
 * PUBLIC FUNCTION(S)
 *   uttMemory( ULong BufferSize )
 *      BufferSize는 메모리 할당을 위한 중간 버퍼의 크기 할당받는
 *      메모리의 크기는 BufferSize를 초과할 수 없습니다.
 *
 *   void* alloc( size_t Size )
 *      Size만큼의 메모리를 할당해 줍니다.
 *
 *   void clear( )
 *      할당받은 모든 메모리를 해제 합니다.
 *
 * NOTES
 *
 * MODIFIED    (MM/DD/YYYY)
 *    assam     01/12/2000 - Created
 *
 **********************************************************************/

#include <idl.h>
#include <uttMemory.h>
#include <ideErrorMgr.h>
#include <ideMsgLog.h>

#define UTTM_DEFAULT_BUFFER_SIZE  (65536)

uttMemory::uttMemory()
{

    #define IDE_FN "FuncName"
    IDE_MSGLOG_FUNC(IDE_MSGLOG_BODY(""));

    init( 0 );


    #undef IDE_FN
}

uttMemory::uttMemory( ULong BufferSize )
{

    #define IDE_FN "FuncName"
    IDE_MSGLOG_FUNC(IDE_MSGLOG_BODY(""));

    init( BufferSize );


    #undef IDE_FN
}

uttMemory::~uttMemory( )
{

    #define IDE_FN "FuncName"
    IDE_MSGLOG_FUNC(IDE_MSGLOG_BODY(""));

    freeAll();
    buffer_size_ = 0;


    #undef IDE_FN
}

void uttMemory::init( ULong BufferSize )
{

    #define IDE_FN "FuncName"
    IDE_MSGLOG_FUNC(IDE_MSGLOG_BODY(""));

    current_ = head_ = NULL;
    buffer_size_     = BufferSize;
#ifdef DEBUG_MEM
    buffer_size_     = 0;
#endif


    #undef IDE_FN
}

void* uttMemory::header( void )
{

    #define IDE_FN "FuncName"
    IDE_MSGLOG_FUNC(IDE_MSGLOG_BODY(""));

    if( head_ == NULL ){
        if( buffer_size_ == 0 ){
            buffer_size_ = UTTM_DEFAULT_BUFFER_SIZE;
#ifdef DEBUG_MEM
	    buffer_size_ = idlOS::align8((UInt)sizeof(uttMemoryHeader));
#endif
        }
        current_ = head_ = (uttMemoryHeader*)idlOS::malloc( buffer_size_ );
        if( current_ != NULL ){
            current_->next   = NULL;
            current_->cursor = idlOS::align8((UInt)sizeof(uttMemoryHeader));
            current_->length = buffer_size_;
            current_->buffer = ((char*)current_);
        }
    }
    
    return current_;


    #undef IDE_FN
}

void* uttMemory::extend( ULong bufferSize )
{

    #define IDE_FN "FuncName"
    IDE_MSGLOG_FUNC(IDE_MSGLOG_BODY(""));

    if( bufferSize == 0 ){
	bufferSize = buffer_size_;
    }
    if( current_ != NULL ){
        if( current_->next != NULL ){
            current_         = current_->next;
            current_->cursor = idlOS::align8((UInt)sizeof(uttMemoryHeader));
        }else{
	    current_->next = (uttMemoryHeader*)idlOS::malloc( bufferSize );
            if( current_->next != NULL ){
                current_         = current_->next;
                current_->next   = NULL;
                current_->cursor = idlOS::align8((UInt)sizeof(uttMemoryHeader));
                current_->length = bufferSize;
                current_->buffer = ((char*)current_);
            }else{
                return NULL;
            }
        }
    }
    
    return current_;


    #undef IDE_FN
}

void uttMemory::release( uttMemoryHeader* Clue )
{

    #define IDE_FN "FuncName"
    IDE_MSGLOG_FUNC(IDE_MSGLOG_BODY(""));

    uttMemoryHeader* clue;
    uttMemoryHeader* next;
    
    for( clue = Clue; clue != NULL; clue = next ){
	    next = clue->next;
        idlOS::free( clue );
    }


    #undef IDE_FN
}

void* uttMemory::cralloc( size_t Size )
{

    #define IDE_FN "FuncName"
    IDE_MSGLOG_FUNC(IDE_MSGLOG_BODY(""));

    void *result;
    
    result = alloc(Size);
    if( result != NULL ){
    	idlOS::memset(result, 0, Size);
    }
    
    return result;


    #undef IDE_FN
}

void* uttMemory::alloc( size_t Size )
{

    #define IDE_FN "FuncName"
    IDE_MSGLOG_FUNC(IDE_MSGLOG_BODY(""));

    void* result;

    if( header() == NULL ){
        return NULL;
    }
    Size = idlOS::align8((UInt)Size);
    if( Size == 0 ){
        return NULL;
    }else if( Size > buffer_size_-idlOS::align8((UInt)sizeof(uttMemoryHeader)) ){
	if( extend( Size+idlOS::align8((UInt)sizeof(uttMemoryHeader)) ) == NULL ){
	    return NULL;
	}
    }
    if( Size > ( current_->length - current_->cursor ) ){
        if( extend( 0 ) == NULL ){
            return NULL;
        }
    }
    result = current_->buffer + current_->cursor;
    current_->cursor += Size;
    
    return result;


    #undef IDE_FN
}

/*----------------------------------------------------------- 
 * Never use it if s1 is defined as an array.
 * Never use it if s1 is not null.
 *----------------------------------------------------------*/
SChar* uttMemory::utt_strdup(const SChar* s)
{
    SChar* temp;
    
    if (s == NULL)
    {
        return NULL;
    }
    if ((temp = (SChar*)alloc(idlOS::strlen(s)+1)) == NULL)
    {
        return temp;
    }
    idlOS::strcpy(temp, s);
    return temp;
}

/*----------------------------------------------------------- 
 * Use it only when s1 is defined as an array.
 * Never use it if s1 is a pointer allocated dynamically
 *----------------------------------------------------------*/
/*
SInt  uttMemory::strcpy(SChar* s1, const SChar* s2)
{
    if (s == NULL)
    {
        return NULL;
    }

    if (sizeof(s1) < idlOS::strlen(s2)+1)
    {
        return -1;
    }
    idlOS::strcpy(s1,s2);
    return 0;
}
*/

SInt  uttMemory::getStatus( uttMemoryStatus* Status )
{

    #define IDE_FN "FuncName"
    IDE_MSGLOG_FUNC(IDE_MSGLOG_BODY(""));

    if( head_ == NULL && current_ == NULL ){
	Status->savedCurrent = NULL;
	Status->savedCursor  = 0;
    }else{
	IDE_TEST_RAISE( head_ == NULL || current_ == NULL, ERR_INVALID_STATUS );
	Status->savedCurrent = current_;
	Status->savedCursor  = current_->cursor;
    }
	
    return IDE_SUCCESS;

    IDE_EXCEPTION( ERR_INVALID_STATUS );
    //IDE_SET(ideSetErrorCode(qpERR_ABORT_UTT_MEMORY_INVALID_STATUS));

    IDE_EXCEPTION_END;

    return IDE_FAILURE;


    #undef IDE_FN
}

SInt  uttMemory::setStatus( uttMemoryStatus* Status )
{

    #define IDE_FN "FuncName"
    IDE_MSGLOG_FUNC(IDE_MSGLOG_BODY(""));

    uttMemoryHeader* cursor;
    
    if( head_ == NULL && current_ == NULL ){
	IDE_TEST_RAISE( Status->savedCurrent != NULL || Status->savedCursor != 0, ERR_INVALID_STATUS );
    }else{
	IDE_TEST_RAISE( head_ == NULL || current_ == NULL, ERR_INVALID_STATUS );
	if( Status->savedCurrent == NULL && Status->savedCursor == 0 ){
	    current_         = head_;
	    current_->cursor = idlOS::align8((UInt)sizeof(uttMemoryHeader));
	}else{
	    for( cursor = head_; cursor != NULL; cursor=cursor->next ){
		if( cursor == Status->savedCurrent ){
		    IDE_TEST_RAISE( Status->savedCursor != idlOS::align8((UInt)Status->savedCursor), ERR_INVALID_STATUS );
		    IDE_TEST_RAISE( Status->savedCursor < idlOS::align8((UInt)sizeof(uttMemoryHeader)), ERR_INVALID_STATUS );
		    IDE_TEST_RAISE( Status->savedCursor > cursor->cursor, ERR_INVALID_STATUS );
		    current_         = Status->savedCurrent;
		    current_->cursor = Status->savedCursor;
		    break;
		}
		IDE_TEST_RAISE( cursor == current_, ERR_INVALID_STATUS );
	    }
	    IDE_TEST_RAISE( cursor == NULL, ERR_INVALID_STATUS );
	}
    }
#ifdef DEBUG_MEM
    freeUnused();
#endif
    
    return IDE_SUCCESS;

    IDE_EXCEPTION( ERR_INVALID_STATUS );
    //IDE_SET(ideSetErrorCode(qpERR_ABORT_UTT_MEMORY_INVALID_STATUS));

    IDE_EXCEPTION_END;

    return IDE_FAILURE;


    #undef IDE_FN
}

void uttMemory::clear( void )
{

    #define IDE_FN "FuncName"
    IDE_MSGLOG_FUNC(IDE_MSGLOG_BODY(""));

    if( head_ != NULL )
    {
        current_         = head_;
        current_->cursor = idlOS::align8((UInt)sizeof(uttMemoryHeader));
    }


    #undef IDE_FN
}

void uttMemory::freeAll( void )
{

    #define IDE_FN "FuncName"
    IDE_MSGLOG_FUNC(IDE_MSGLOG_BODY(""));

    if( head_ != NULL )
    {
        release( head_ );
        current_ = head_ = NULL;
    }


    #undef IDE_FN
}

void uttMemory::freeUnused( void )
{

    #define IDE_FN "FuncName"
    IDE_MSGLOG_FUNC(IDE_MSGLOG_BODY(""));

    if( current_ != NULL )
    {
        release( current_->next );
        current_->next = NULL;
    }


    #undef IDE_FN
}
