--######################################################
-- DROP PARTITIOIN ( PK:INTEGER )
--######################################################

--###################################
--+SECTOR; INTIALIZE
--###################################

--+SKIP BEGIN;
DROP TABLE PDT_HASH;
--+SKIP END;

CREATE TABLE PDT_HASH
(
    F1   INTEGER,
    F2   INTEGER
) 
PARTITION BY HASH( F1 )
(
    PARTITION P1,
    PARTITION P2,
    PARTITION P3,
    PARTITION P4
) TABLESPACE PDT_TBS;

--#########################################
--+SECTOR; DO JOB #1 (1. Basic Test)
--#########################################

-- nothing to do

--#########################################
--+SECTOR; DO JOB #2 (2. Validation Test)
--#########################################

------------------------------------
-- 2.1 테이블의 종류에 따른 에러검사
------------------------------------
-- should be fail
ALTER TABLE PDT_HASH
ADD PARTITION P1;


--#########################################
--+SECTOR; DO JOB #3 (3. Execution Test)
--#########################################

-- nothing to do 

--###################################
--+SECTOR; FINALIZE
--###################################

DROP TABLE PDT_HASH;
