# $Id: Makefile 3267 2007-02-06 03:05:11Z sjkim $
#
include $(ALTIBASE_HOME)/install/altibase_env.mk

DIRS=src

install: compile

all: compile

compile:
	for i in $(DIRS); do (cd $$i; make ses_conn.$(OBJEXT); ) done

archive:
	for i in $(DIRS); do (cd $$i; make archive;) done

clean:
	for i in $(DIRS); do (cd $$i; make clean;) done

alint:
	for i in $(DIRS); do (cd $$i; make alint;) done

clearall:
	for i in $(DIRS); do (cd $$i; rm -rf core *.o *.p *.log .pure SunWS_cache;) done

ctags:
	find `pwd` \( -name "*.h" -o -name "*.cpp" -o -name "*.i" \) -exec ctags -f ../../tags -a {} \;
	-rm -f tags; ln -s ../../tags tags
	-cd src; rm -f tags; ln -s ../../../tags tags
	-cd include; rm -f tags; ln -s ../../../tags tags

sure:
