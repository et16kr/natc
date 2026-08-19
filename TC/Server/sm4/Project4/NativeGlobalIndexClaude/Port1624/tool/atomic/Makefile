include $(ALTIBASE_HOME)/install/altibase_env.mk

INCLUDES += $(IDROPT)$(ATC_HOME)/include $(IDROPT). $(IDROPT)$(ALTIBASE_DEV)/src/id/include $(IDROPT)$(ALTIBASE_DEV)/src/core/include $(IDROPT)$(ALTIBASE_DEV)/src/pd/include $(IDROPT)$(ALTIBASE_DEV)/src/pd/makeinclude
LIBDIRS  += $(LDROPT)$(ALTIBASE_HOME)/lib $(LDROPT).

SRCS=atomic_insert.sc
BINS=atomic_insert$(BINEXT)

SESS=$(SRCS:.sc=.cpp)
OBJS=$(SRCS:.cpp=.$(OBJEXT) )

%.cpp : %.sc
	sesc -atc -t cpp $<

all: $(BINS)

atomic_insert$(BINEXT): atomic_insert.$(OBJEXT)
	$(LD) $(LFLAGS) $(LDOUT)$@ $^ $(LIBOPT)sesc$(LIBAFT) $(LIBOPT)id$(LIBAFT) $(LIBOPT)pd$(LIBAFT) $(LIBOPT)odbccli$(LIBAFT) $(LIBS)

clean:
	-rm $(BINS) $(SESS) *.$(OBJEXT) core *.class *.res
