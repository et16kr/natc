ODBC_HOME = ${PTIME_HOME}/sdk/odbc
include ${ODBC_HOME}/makefile/Makefile_linux_gcc.inc

PESQL_HOME = ${PTIME_HOME}/sdk/pesql

PESQL_LIB_DIR = -L${PTIME_HOME}/sdk/odbc/lib64 -lptimeodbc-linux_x86_64-gcc_3.4.3-ansi-3.3 -L${PTIME_HOME}/sdk/pesql/lib64 -lptimepesql-linux_x86_64-gcc_3.4.3-3.3

PESQL_INC_DIR = -I${PESQL_HOME}/include ${ODBC_INCDIR} -I. -I${PESQL_HOME}/include

CCFLAGS = ${OPT_FLAGS} ${PESQL_INC_DIR} -I. -I../include -I../../lib -I${ALTIBASE_HOME}/include -I${ALTIDEV_HOME}/id/src/include -I${ALTIDEV_HOME}/ul/sqlcli/include -I${ATC_HOME}/include
LDFLAGS = -L../../lib ${PESQL_LIB_DIR} -L${ALTIBASE_HOME}/lib -lid -lpd -lpthread -lcrypt -lrt -ldl

.SUFFIXES: .cpp .o
.cpp.o:
	${CPP} -c -o $*.o ${CCFLAGS} $*.cpp

LEX=flex
LEXFLAGS= -Cfar
YACC=bison
YACCFLAGS= -d -v

.l.cpp :
	$(LEX) $(LEXFLAGS) -o$*.cpp $*.l
	sed s/"^class istream;$$"/"#include <iostream.h>"/ $*.cpp > $*.cpp.old
	mv $*.cpp.old $*.cpp

BINS=psql

SRCS = abc_analysis.cpp iSQLExecuteCommand.cpp iSQLPreLexer.cpp uttMemory.cpp \
       abc_time.cpp iSQLHelp.cpp iSQLPrepareCommand.cpp uttString.cpp \
       iSQLHostVarMgr.cpp iSQLProgOption.cpp uttTime.cpp \
       iSQLAdminCommand.cpp iSQLLexer.cpp iSQLProperty.cpp uttTimeStat.cpp \
       iSQLCommand.cpp iSQLMain.cpp iSQLSpool.cpp \
       iSQLCommandQueue.cpp iSQLParser.cpp utISPApi.cpp \
       iSQLCompiler.cpp iSQLPassword.cpp utString.cpp

OBJS = $(SRCS:.cpp=.o)

all : iSQLParser.cpp iSQLPreLexer.cpp iSQLLexer.cpp $(BINS)

iSQLParser.cpp: iSQLParser.y
	$(YACC) $(YACCFLAGS) -p iSQLParser -o iSQLParser.cpp iSQLParser.y

psql : $(OBJS)
	${CPP} ${CCFLAGS} -o $@  $(OBJS) ${LDFLAGS}
	-mv ${ALTIBASE_HOME}/bin/isql ${ALTIBASE_HOME}/bin/isql.old
	cp psql ${ALTIBASE_HOME}/bin/isql
	-mv ${ALTIBASE_HOME}/bin/server ${ALTIBASE_HOME}/bin/server.old
	cp server ${ALTIBASE_HOME}/bin/server
	-mv ${ALTIBASE_HOME}/bin/is ${ALTIBASE_HOME}/bin/is.old
	cp is ${ALTIBASE_HOME}/bin/is

clean:
	rm -rf core *.o *.d SunWS_cache $(BINS) iSQLPreLexer.cpp iSQLLexer.cpp iSQLParser.cpp iSQLParser.cpp.h
