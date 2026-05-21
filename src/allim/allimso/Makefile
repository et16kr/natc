include $(ALTICORE_HOME)/makefiles/config.mk
include $(ALTICORE_HOME)/makefiles/platform.mk

TARGET = $(SHLIB_PRE)allimso$(SHLIB_SUF)

OBJS = allimso.o hookapi.o

CCFLAGS = $(PIC_FLAGS) $(DEF_OPT)ACP_CFG_DL_EXPORT
LDFLAGS = $(SO_FLAGS)
ifeq ($(ACP_CFG_OS),WINDOWS)
LDFLAGS += /LIBPATH:../lib allib.lib
else
LDFLAGS += -L../lib -lallib
endif

POSTBUILD = 
INSTALLCMD = cp $(TARGET) $(ATAF_TEST_CASE)/lib

include ../common.mk
