--+SKIP BEGIN;

ALTER SYSTEM SET QUERY_PROF_FLAG=0;
ALTER SYSTEM SET TIMED_STATISTICS=0;

--+SYSTEM server kill;

--+SYSTEM rm $ALTIBASE_HOME/trc/*.prof;

--+SYSTEM server start;

--+SYSTEM is -f schema.sql;

--+SKIP END;
