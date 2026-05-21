include $(ALTICORE_HOME)/makefiles/config.mk
include $(ALTICORE_HOME)/makefiles/platform.mk
TARGET = $(SHLIB_PRE)allib$(SHLIB_SUF)

OBJS = allib.o

CCFLAGS = $(PIC_FLAGS) $(DEF_OPT)ACP_CFG_DL_EXPORT
LDFLAGS = $(SO_FLAGS)

POSTBUILD = 
INSTALLCMD = cp $(TARGET) $(ATAF_TEST_CASE)/lib

include ../common.mk
