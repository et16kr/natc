ODBC_HOME = ${PTIME_HOME}/sdk/odbc
include ${ODBC_HOME}/makefile/Makefile_linux_gcc.inc

PESQL_HOME = ${PTIME_HOME}/sdk/pesql

PESQL_LIB_DIR = -L${PTIME_HOME}/sdk/odbc/lib64 -lptimeodbc-linux_x86_64-gcc_3.4.3-ansi-3.3 -L${PTIME_HOME}/sdk/pesql/lib64 -lptimepesql-linux_x86_64-gcc_3.4.3-3.3

PESQL_INC_DIR = -I${PESQL_HOME}/include ${ODBC_INCDIR} -I. -I${PESQL_HOME}/include

CCFLAGS = ${OPT_FLAGS} ${PESQL_INC_DIR} -I. -I../include -I../../lib -I${ALTIBASE_HOME}/include -I${ALTIDEV_HOME}/id/src/include -I${ALTIDEV_HOME}/ul/sqlcli/include -I${ATC_HOME}/include
LDFLAGS = -L../../lib ${PESQL_LIB_DIR} -L${ALTIBASE_HOME}/lib -lid -lpd -lpthread -lcrypt -lrt -ldl

.SUFFIXES: .c .cpp .o
.cpp.o:
	${CPP} -c -o $*.o ${CCFLAGS} $*.cpp

LEX=flex
LEXFLAGS= -Cfar
YACC=bison
YACCFLAGS=-d -t -v

.l.cpp :
	$(LEX) $(LEXFLAGS) -o$*.cpp $*.l
	sed s/"^class istream;$$"/"#include <iostream.h>"/ $*.cpp > $*.cpp.old
	mv $*.cpp.old $*.cpp

BINS=ploader

SRCS = iloCommandLexer.cpp iloFormLexer.cpp iloFormParser.cpp iloCommandParser.cpp iloBadFile.cpp iloLoad.cpp iloPassword.cpp iloTableInfo.cpp iloCommandCompiler.cpp iloFormCompiler.cpp iloLogFile.cpp iloProgOption.cpp iloDataFile.cpp iloFormDown.cpp iloMain.cpp iloSQLApi.cpp iloDownLoad.cpp abc_analysis.cpp abc_time.cpp uttMemory.cpp uttString.cpp uttTime.cpp uttTimeStat.cpp 

OBJS = $(SRCS:.cpp=.o)

all : iloCommandParser.cpp iloCommandLexer.cpp iloFormParser.cpp iloFormLexer.cpp $(BINS)

iloCommandParser.cpp: iloCommandParser.y
	$(YACC) $(YACCFLAGS) -p iloCommandParser -o iloCommandParser.cpp iloCommandParser.y

iloFormParser.cpp: iloFormParser.y
	$(YACC) $(YACCFLAGS) -o iloFormParser.cpp iloFormParser.y

ploader : ${OBJS}
	${CPP} ${CCFLAGS} -o $@  $(OBJS) ${LDFLAGS}
	-mv ${ALTIBASE_HOME}/bin/iloader ${ALTIBASE_HOME}/bin/iloader.old
	cp ploader ${ALTIBASE_HOME}/bin/iloader
	-mv ${ALTIBASE_HOME}/bin/il ${ALTIBASE_HOME}/bin/il.old
	cp il ${ALTIBASE_HOME}/bin/il

clean:
	rm -rf core *.o *.d SunWS_cache $(BINS) iloFormParser.cpp iloFormParser.cpp.h iloFormLexer.cpp iloFormLexer.h iloCommandParser.cpp iloCommandParser.cpp.h iloCommandLexer.cpp iloCommandLexer.h *.output
