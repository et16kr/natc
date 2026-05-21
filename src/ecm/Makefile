#
#
#

CLASSPATH=".$(JAVALIB)"
SRCDIR=./ErrorCaseManager

%.class:%.java
	javac -classpath $(CLASSPATH) $<
		
# Source list 
SRCS=\
$(SRCDIR)/ErrorCaseManager.java\
$(SRCDIR)/ViewDiff.java\
$(SRCDIR)/FindLstOut.java\
$(SRCDIR)/TDXView.java

OBJS=$(SRCS:.java=.class)

COMPILE_ALL = install

all: $(COMPILE_ALL)

install: compile archive
	cp ErrorCaseManager.jar $(ATC_HOME)/bin

upload:
compile: $(OBJS)
#	javac $(SRCS)

archive: $(OBJS)
#	jar -cmf MANIFEST.MF   TDX_View.jar $(OBJS)
	jar -cmf MANIFEST.MF   ErrorCaseManager.jar $(SRCDIR)/*.class
clean:
	-rm -f $(SRCDIR)/*.class 
	-rm -f *.jar
