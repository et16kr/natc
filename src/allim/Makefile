ifeq ($(ACP_CFG_OS),WINDOWS)
DIRS = lib test allimso allimctl setlimitlog setlimitpoint setlimitreal
else
DIRS = lib allimso test allimctl setlimitlog setlimitpoint setlimitreal
endif

all: install

install:
	@for i in $(DIRS); do (cd $$i; make install;) done
clean:
	@for i in $(DIRS); do (cd $$i; make clean;) done
