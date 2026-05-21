ifeq ($(OS_NAME),linux)
    CC = g++ -g

    LD = g++

    TARGET = target

    CFLAGS = -D_XOPEN_SOURCE \
             -D_BSD_SOURCE \
             -DSTAF_OS_NAME_LINUX \
             -DSTAF_GETHOSTBYNAME_R_6PARM \
             -DSTAF_GETHOSTBYADDR_R_8PARM \
             -D_GNU_SOURCE \
             -DNDEBUG \
             -D_PTHREADS \
             -DSTAF_NATIVE_COMPILER \
             -O2 \
             -Wno-deprecated

    LIBS = 

else 
ifeq ($(OS_NAME),solaris)
    CC = g++

    LD = g++

    TARGET = target

    CFLAGS = -DSTAF_OS_NAME_SOLARIS \
             -D_REENTRANT \
             -DSTAF_GETHOSTBYNAME_R_5PARM \
             -DSTAF_GETHOSTBYADDR_R_7PARM \
             -D_POSIX_PTHREAD_SEMANTICS \
             -DNDEBUG \
             -D_PTHREADS \
             -DSTAF_NATIVE_COMPILER	\
             -O2 \
             -Wno-deprecated
	
    LIBS =   -lsocket \
			 -lnsl
else
ifeq ($(OS_NAME),dec)
    CC = g++

    LD = g++

    TARGET = target

    CFLAGS = -DSTAF_OS_NAME_DEC \
             -D_REENTRANT \
             -DSTAF_GETHOSTBYNAME_R_3PARM \
             -DSTAF_GETHOSTBYADDR_R_5PARM \
             -DDIGITAL_UNIX=0x500 \
             -DNDEBUG \
             -D_PTHREADS \
             -DSTAF_NATIVE_COMPILER \
             -O2 \
             -Wno-deprecated

    LIBS = 
else
ifeq ($(OS_NAME),hpux)
    CC = aCC 

    LD = aCC

    TARGET = target

    CFLAGS = -DSTAF_OS_NAME_HPUX \
             -D_REENTRANT \
             -DSTAF_NO_GETHOSTBYNAME_R \
             -DSTAF_NO_GETHOSTBYADDR_R \
             -D_POSIX_C_SOURCE=199506L \
             -D_HPUX_SOURCE \
             -Dstd= \
             -DSTAF_Config_NoSTDIOStreamSupport \
             -DSTAF_Config_NoSTDFStreamSupport \
             -DSTAF_NATIVE_COMPILER \
             +z \
             +O1 \
             +W302 \
             +W829 \
             -Wl,+s

    LIBS = 
else
ifeq ($(OS_NAME),hpux-ia64)
    CC = aCC -AA

    LD = aCC -AA

    TARGET = target

    CFLAGS = -DSTAF_OS_NAME_HPUX \
             -D_REENTRANT \
             -DSTAF_NO_GETHOSTBYNAME_R \
             -DSTAF_NO_GETHOSTBYADDR_R \
             -D_POSIX_C_SOURCE=199506L \
             -DSTAF_NATIVE_COMPILER \
             -D_HPUX_SOURCE \
             +W302 \
             +O1 \
             +DD32 \
             -mt \
             +z \
             +W829

    LIBS = 
else
ifeq ($(OS_NAME),aix)
    CC = xlC_r 

    LD = xlC_r 

    TARGET = target

    CFLAGS = -DSTAF_OS_NAME_AIX \
             -DSTAF_GETHOSTBYNAME_R_3PARM \
             -DSTAF_GETHOSTBYADDR_R_5PARM \
             -DSTAF_Config_NoSTDIOStreamSupport=1 \
             -DSTAF_Config_NoSTDFStreamSupport=1 \
             -DSTAF_NATIVE_COMPILER \
             -D_POSIX_PTHREAD_SEMANTICS \
             -D_REENTRANT \
             -qcheck=nobounds:div:null \
             -qtempinc \
             -qinfo \
             -qspill=32000 \
             -qflag=w:w \
             -qinline \
             -O \
             -bmaxdata:0x40000000 \
             -brtl

    LIBS = 
else
ifeq ($(OS_NAME),win32)
    CC = cl -nologo 

    LD = cl -nologo

    TARGET = target.exe

    CFLAGS = -DSTAF_OS_NAME_WIN32 \
             -D_CONSOLE \
             -D_MBCS \
             -DWIN32 \
             -D_WINDOWS \
             -D_MBCS \
             -DNDEBUG \
             -D_LIB \
             -D_WIN32_WINNT=0x0400 \
             -DUSE_NEW_IOSTREAM \
             -D_CRT_SECURE_NO_DEPRECATE \
             -W3 \
             -EHsc \
             -Ob1 \
             -Oi \
             -Ot \
             -MT

    LIBS = 
else
    $(error not implemented yet)
endif
endif
endif
endif
endif
endif
endif

INCLUDES = -I$(ATAF_TEST_CASE)/src/target_agent/include/ \
		   -I$(ATAF_TEST_CASE)/src/ats2/ \
           -I.

ifeq ($(OS_NAME),win32)
	mv $*.obj $*.o
endif

$(TARGET): target.cpp
	@echo $(CC) $<
	@$(CC) -o $@ $< $(CFLAGS) $(LIBS) $(INCLUDES)

clean:
	rm -f *.o target
