--###########################################################################
--# BUG-23628
--###########################################################################

--+SKIP BEGIN;

--+SYSTEM  server kill;
--+SYSTEM  clean;
--+SET_ENV ALTIBASE_QUERY_TIMEOUT=6000;
--+SET_ENV ALTIBASE_FETCH_TIMEOUT=6000;
--+SET_ENV ALTIBASE_UTRANS_TIMEOUT=6000;
--+SYSTEM  server start;

--+SKIP END;
