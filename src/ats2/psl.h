/***********************************************************************
 * Copyright 1999-2001, ALTIBase Corporation or its subsidiaries.
 * All rights reserved.
 **********************************************************************/

/***********************************************************************
 * $Id$
 **********************************************************************/

#ifndef _O_PSL_H_
#define _O_PSL_H_ 1

#undef yyFlexLexer
#define yyFlexLexer psFlexLexer
#if !defined(yyFlexLexerOnce)
#   include <FlexLexer.h>
#endif

#define ERROR_SIZE (65536)

class psLexer : public psFlexLexer
{
public:
    psLexer( SChar*  aBuffer,
             UInt    aBufferLength );

    int    yylex( void );
    void   getPosition( psNamePosition* aPosition );
    SChar* getLexLastError( SChar *aMessage );

    SChar* mBuffer;
    SChar* mBufferCursor;
    SChar* mBufferLast;
    SChar* mBufferInput;
    UInt   mBufferLength;
    UInt   mBufferRemain;
    SChar  mMessage[ERROR_SIZE];

private:

    int    LexerInput( char* aInBuf, int aMaximum );
};

#endif
