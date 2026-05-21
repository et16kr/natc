#
#
#

%.class:%.java
	javac $<
		
# Source list 
SRCS=\
./TimeStampIdx.java\
./aVector.java\
./aVectorTDX.java\
./PropertiesATC.java\
./TableMap.java\
./TableSorter.java\
./JTableTDX.java\
./ATMdbManager.java\
./TDX_View.java

OBJS=$(SRCS:.java=.class)

COMPILE_ALL = install

all: $(COMPILE_ALL)

install: compile archive
	cp TDX_View.jar $(ATC_HOME)/bin

upload:
compile: $(OBJS)
#	javac $(SRCS)

archive: $(OBJS)
#	jar -cmf MANIFEST.MF   TDX_View.jar $(OBJS)
	jar -cmf MANIFEST.MF   TDX_View.jar *.class

clean:
	-rm -f *.class 
	-rm -f *.jar
