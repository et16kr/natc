SRCS=AtcLib.java
CLASSPATH_JDBC=$(CLASSPATH):$(ALTIBASE_HOME)/lib/Altibase.jar

all: install sample

install:
	javac -classpath $(CLASSPATH_JDBC) AtcLib.java
	jar cvf AtcLib.jar AtcLib.class

sample:
	javac -classpath $(CLASSPATH_JDBC):./ sample.java

clean:
	-rm -rf core .dependency .pure *.o *.d SunWS_cache *.class *.jar
