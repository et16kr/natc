include $(ALTICORE_HOME)/makefiles/config.mk
include $(ALTICORE_HOME)/makefiles/platform.mk

TARGET = 		setlimitpoint$(EXEC_SUF)
OBJS = 			main.o

CCFLAGS = 
ifeq ($(ACP_CFG_OS),WINDOWS)
LDFLAGS += /LIBPATH:../lib allib.lib
else
LDFLAGS += -L$(ATAF_TEST_CASE)/lib -lallib
endif

POSTBUILD = 
INSTALLCMD = cp $(TARGET) $(ATAF_TEST_CASE)/bin

include ../common.mk
