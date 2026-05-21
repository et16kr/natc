--# 테스트 케이스를 효율적으로 실행하기 위해 MEM_MAX_DB_SIZE를 줄인다.

--+SKIP BEGIN;
--+SYSTEM server kill;
--+SET_ENV ALTIBASE_MEM_MAX_DB_SIZE=13M;
--+SYSTEM clean;
--+SYSTEM server start;
--+SKIP END;
SELECT * FROM DUAL;
