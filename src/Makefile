JAVA_DIRS=java ses

DIRS=$(JAVA_DIRS)

all: install

install:
	for i in $(DIRS); do (cd $$i; make install;) done
clean:
	for i in $(DIRS); do (cd $$i; make clean;) done
