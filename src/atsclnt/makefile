ifeq ($(OS_NAME),linux)
    CC = g++

    LD = g++

    TARGET = atsc

    CFLAGS = -D_XOPEN_SOURCE \
             -D_BSD_SOURCE \
             -DSTAF_OS_NAME_LINUX \
             -DSTAF_GETHOSTBYNAME_R_6PARM \
             -DSTAF_GETHOSTBYADDR_R_8PARM \
             -D_GNU_SOURCE \
             -DNDEBUG \
             -D_PTHREADS \
             -DSTAF_NATIVE_COMPILER \
             -O3 -funroll-loops \
	     -D_FORTIFY_SOURCE=0 \
             -Wno-deprecated 

    LIBS = -lpthread \
           -lcrypt \
           -ldl \
           -lrt \
           -lSTAF
else 
ifeq ($(OS_NAME),solaris)
    CC = g++

    LD = g++

    TARGET = atsc 

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

    LIBS = -lpthread \
           -lcrypt \
           -ldl \
           -lrt \
           -lnsl \
           -lSTAF
else
ifeq ($(OS_NAME),dec)
    CC = g++

    LD = g++

    TARGET = atsc 

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

    LIBS = -ltli \
           -lrt \
           -lpthread \
           -lm \
           -lSTAF
else
ifeq ($(OS_NAME),hpux)
    CC = aCC +DD64

    LD = aCC +DD64

    TARGET = atsc 

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

    LIBS = -lpthread \
           -lSTAF
else
ifeq ($(OS_NAME),hpux-ia64)
    CC = aCC -AA

    LD = aCC -AA

    TARGET = atsc 

    CFLAGS = -DSTAF_OS_NAME_HPUX \
             -D_REENTRANT \
             -DSTAF_NO_GETHOSTBYNAME_R \
             -DSTAF_NO_GETHOSTBYADDR_R \
             -D_POSIX_C_SOURCE=199506L \
             -DSTAF_NATIVE_COMPILER \
             -D_HPUX_SOURCE \
             +W302 \
             +O1 \
             +DD64 \
             -mt \
             +z \
             +W829 

    LIBS = -lpthread \
           -lSTAF
else
ifeq ($(OS_NAME),aix)
    CC = xlC_r 

    LD = xlC_r

    TARGET = atsc 

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

    LIBS = -lpthread \
           -lSTAF
else
ifeq ($(OS_NAME),win32)
    CC = cl -nologo

    LD = cl -nologo /F 10000000

    TARGET = atsc.exe

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
             -O2 \
             -MT

    LIBS = advapi32.lib \
           user32.lib \
           comctl32.lib \
           netapi32.lib \
           ws2_32.lib \
           $(STAF_HOME)/lib/STAF.lib
else
    $(error not implemented yet)
endif
endif
endif
endif
endif
endif
endif

INCLUDES = -I$(STAF_HOME)/include \
           -I/usr/local/include \
           -I../services/ats2 \
           -I../ats2 \
           -I.

ifneq ($(OS_NAME),win32)
LDFLAGS = -L$(STAF_HOME)/lib
endif

ifeq ($(OS_NAME),win32)
OBJEXT = obj
else
OBJEXT = o
endif
 
SRCS = atsc.cpp caseManager.cpp platformManager.cpp

OBJECTS = $(SRCS:.cpp=.$(OBJEXT)) 

.SUFFIXES: .cpp .obj .o

.cpp.$(OBJEXT):
	@echo "CC" $*.$(OBJEXT)
	@$(CC) -c $(CFLAGS) $(INCLUDES) $<

install: $(TARGET)

$(TARGET): $(OBJECTS)
	@echo "LD" $(ATAF_TEST_CASE)/bin/$(TARGET) 
	@$(LD) -o $(ATAF_TEST_CASE)/bin/$(TARGET) $(CFLAGS) $(LDFLAGS) $(LIBS) $(OBJECTS)
	cp atsclnt atsclnt.bat $(ATAF_TEST_CASE)/bin
	cp atsclnt2 $(ATAF_TEST_CASE)/bin
	cp atsclntp $(ATAF_TEST_CASE)/bin
	cp pre_atsclntp $(ATAF_TEST_CASE)/bin
	cp artclnt  $(ATAF_TEST_CASE)/bin
	cp artclnt2  $(ATAF_TEST_CASE)/bin
clean:
	rm -rf $(OBJECTS) $(ATAF_TEST_CASE)/lib/$(TARGET)
