ifeq ($(compile_bit),)
COMPILE_BIT=64
else
COMPILE_BIT=$(compile_bit)
endif

ifeq ($(ACP_CFG_OS),WINDOWS)
include $(ALTICORE_HOME)/env/env$(COMPILE_BIT).mk
endif
include $(ALTICORE_HOME)/makefiles/config.mk
include $(ALTICORE_HOME)/makefiles/platform.mk
ifneq ($(ACP_CFG_OS),WINDOWS)
include $(ALTICORE_HOME)/env/env$(COMPILE_BIT).mk
endif

INCLUDES += $(INC_OPT)$(ATAF_TEST_CASE)/src/allim/include/
INCLUDES += $(ALTICORE_INCLUDES)

ifneq ($(ACP_CFG_OS),WINDOWS)

CCFLAGS  += $(ALTICORE_CFLAGS) $(CC_FLAGS)
CCFLAGS  += $(ALTICORE_DEFINES)

LDFLAGS  += $(ALTICORE_LDFLAGS) $(LD_FLAGS)
CCFLAGS  += -D_GNU_SOURCE

SRCS = $(OBJS:.o=.c)

all: install

install: $(TARGET)
	$(POSTBUILD)
	$(INSTALLCMD)

clean:
	echo $(ACP_CFG_OS)
	rm -rf $(TARGET) $(OBJS) core
	$(CLEANCMD)

$(TARGET): $(OBJS)
	$(CC) -o $@ $(OBJS) $(LDFLAGS) $(CCFLAGS)

%.o: %.c
	$(CC) -o $@ -c $< $(INCLUDES) $(CCFLAGS)

else

CCFLAGS  += $(ALTICORE_CFLAGS) /DEBUG /DVC_WIN32
CCFLAGS  += $(ALTICORE_DEFINES)
LDFLAGS  += $(ALTICORE_LDFLAGS:_static.lib=.lib) /DEBUG /DVC_WIN32

OBJECTS = $(OBJS:.o=.obj)
SRCS = $(OBJS:.o=.c)

all: install

install: $(TARGET)
	$(POSTBUILD)
	$(INSTALLCMD)

clean:
	rm -rf $(TARGET) $(OBJECTS) *.pdb *.exp *.manifest *.map *.lib
	$(CLEANCMD)

$(TARGET): $(OBJECTS)
	$(LD) /OUT:$@ $(OBJECTS) $(LDFLAGS)

%.obj: %.c
	$(CC) /Fo$@ /c $< $(INCLUDES) $(CCFLAGS)

endif
