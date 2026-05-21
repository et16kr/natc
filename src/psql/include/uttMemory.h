/***********************************************************************
 * Copyright 1999-2000, RTBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id: uttMemory.h 2 2006-04-13 15:48:39Z copyrei $
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
 *   uttMemory( ULong BufferSize, ULong Align )
 *      BufferSize는 메모리 할당을 위한 중간 버퍼의 크기 할당받는
 *      메모리의 크기는 BufferSize를 초과할 수 없습니다.
 *      Align은 할당된 메모리의 포인터를 Align의 배수로 할것을
 *      지정하는 것입니다. 기본 값은 8Bytes 입니다.
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

#ifndef _O_UTTMEMORY_H_
# define _O_UTTMEMORY_H_  1

#include <idl.h>

typedef struct uttMemoryHeader {
    uttMemoryHeader* next;
    char*            buffer;
    ULong            length;
    ULong            cursor;
} uttMemoryHeader;

typedef struct uttMemoryStatus {
    uttMemoryHeader* savedCurrent;
    ULong            savedCursor;
} uttMemoryStatus;

class uttMemory {
 private:
    uttMemoryHeader* head_;
    uttMemoryHeader* current_;
    ULong            buffer_size_;
    
    void*  header( void );
    void*  extend( ULong bufferSize );
    void   release( uttMemoryHeader* Clue );
 public:
    uttMemory();
    uttMemory( ULong BufferSize );
    ~uttMemory( );
    void  init( ULong BufferSize = 0 );
    void* cralloc( size_t Size );
    void* alloc( size_t Size );
    
   /*----------------------------------------------------------- 
    * Use it only when s1 is defined as an array.
    * Never use it if s1 is a pointer allocated dynamically
    *----------------------------------------------------------*/
    //SInt   strcpy(SChar* s1, const SChar* s2);
    
   /*----------------------------------------------------------- 
    * Never use it if s1 is defined as an array.
    * Never use it if s1 is not null.
    *----------------------------------------------------------*/
    SChar* utt_strdup(const SChar* s);
    
    SInt  getStatus( uttMemoryStatus* Status );
    SInt  setStatus( uttMemoryStatus* Status );
    
    void  clear( void );
    
    void  freeAll( void );
    void  freeUnused( void );
};

#endif /* _O_UTTMEMORY_H_ */
