include $(ALTIBASE_HOME)/install/altibase_env.mk

INCLUDES = -I$(ALTIBASE_HOME)/include -I.
LIBDIRS  = -L$(ALTIBASE_HOME)/lib

%.cpp : %.sc
	sesc -t cpp $<

all: archive

archive: conn.o conn.cpp
	$(AR) $(ARFLAGS) libconn.a conn.o

clean:
	-rm -rf *.o core *.class *.cpp libnist.a

dep:
	-rm -rf ./.dependency
	$(CXX) $(CXXOPT_DEPENDANCY) $(INCLUDES) $(DEFINES) test_cli.c test_qpi.c > .dependency

ifeq (./.dependency,$(wildcard ./.dependency))
include ./.dependency
endif

