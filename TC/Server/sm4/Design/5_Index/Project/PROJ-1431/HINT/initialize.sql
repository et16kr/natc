--#######################################################
--# SORT TEMP TABLE TEST USING HINT : INITIALIZE
--#######################################################

--+SKIP BEGIN;
DROP TABLE TEST_TABLE;
--+SKIP END;

CREATE TABLE TEST_TABLE 
(
     TenK    INTEGER,  -- 10K Cardinality Value
     Hun    INTEGER,  -- 100 Cardinality Value
     Ten     INTEGER   --  10 Cardinality Value
) TABLESPACE SYS_TBS_DISK_DATA;

CREATE OR REPLACE PROCEDURE BUILD_DATA
AS
BEGIN
    FOR I IN 1 .. 10000 LOOP
        INSERT INTO TEST_TABLE VALUES
           ( i, MOD(i,100), MOD(i,10) );
    END LOOP;
END;
/

EXEC BUILD_DATA;

SELECT COUNT(*) FROM TEST_TABLE;
