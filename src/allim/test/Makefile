include $(ALTICORE_HOME)/makefiles/config.mk
include $(ALTICORE_HOME)/makefiles/platform.mk

TARGET = 		testallim$(EXEC_SUF)
OBJS = 			testallim.o

CCFLAGS = 
ifeq ($(ACP_CFG_OS),WINDOWS)
LDFLAGS += /LIBPATH:../lib allib.lib
else
LDFLAGS += -L$(ATAF_TEST_CASE)/lib -lallib
endif

POSTBUILD = ./$(TARGET)
CLEANCMD  = rm -Rf *.dat

include ../common.mk

