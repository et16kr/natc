include $(ALTIBASE_HOME)/install/altibase_env.mk

INCLUDES = -I./ -I$(ALTIBASE_HOME)/include -I$(ALTIDEV_HOME)/ut/util/include -I. -I$(ALTIDEV_HOME)/src/id/include -I$(ALTIDEV_HOME)/src/id -I$(ALTIDEV_HOME)/src/pd/include -I$(ALTIDEV_HOME)/src/pd/makeinclude 
LIBDIRS = -L$(ALTIBASE_HOME)/lib -L$(ALTIDEV_HOME)/ut/util/lib

SRCS=
OBJS=$(SRCS:.cpp=.o)
BINS=testLT testGT

all: $(BINS)

testLT : testLT.o $(OBJS) $(QPLIB)
	$(LD) $(LFLAGS) -o $@ $< -laltiutil -lid -lpd -lodbccli $(LIBS)

testGT : testGT.o $(OBJS) $(QPLIB)
	$(LD) $(LFLAGS) -o $@ $< -laltiutil -lid -lpd -lodbccli $(LIBS)

clean:
	-rm $(BINS) *.o core

dep:
	-rm -rf ./.dependency
	$(CXX) $(CXXOPT_DEPENDANCY) $(INCLUDES) $(DEFINES) > .dependency

ifeq (./.dependency,$(wildcard ./.dependency))
include ./.dependency
endif

