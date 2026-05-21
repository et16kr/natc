include $(ALTIBASE_HOME)/install/altibase_env.mk

INCLUDES += $(IDROPT)../include $(IDROPT)$(ATAF_TEST_RESULT)/include $(IDROPT). $(IDROPT)$(ALTIBASE_DEV)/pd/src/include $(IDROPT)$(ALTIBASE_DEV)/pd/src/makeinclude $(IDROPT)$(ALTIBASE_DEV)/id/src/include $(IDROPT)$(ALTIBASE_DEV)/id/src $(IDROPT)$(ALTIBASE_HOME)/include 
LIBDIRS  += $(LDROPT)$(ALTIBASE_HOME)/lib

%.cpp : %.sc
	sesc -t cpp $<

all: archive

archive: ses_conn.$(OBJEXT) ses_conn.cpp
	$(AR) $(ARFLAGS) $(AROUT)../lib/$(LIBPRE)sesconn.$(LIBEXT) ses_conn.$(OBJEXT)

clean:
	-rm -rf *.$(OBJEXT) core *.class *.cpp ../lib/$(LIBPRE)sesconn.$(LIBEXT)

dep:
	-rm -rf ./.dependency
	$(CXX) $(CXXOPT_DEPENDANCY) $(INCLUDES) $(DEFINES) test_cli.c test_qpi.c > .dependency

ifeq (./.dependency,$(wildcard ./.dependency))
include ./.dependency
endif

