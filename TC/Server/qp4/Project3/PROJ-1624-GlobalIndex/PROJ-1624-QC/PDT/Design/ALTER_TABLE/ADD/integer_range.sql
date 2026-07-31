--######################################################
-- ADD PARTITIOIN ( PK:INTEGER )
--######################################################

--###################################
--+SECTOR; INTIALIZE
--###################################

--+SKIP BEGIN;
DROP TABLE PDT_RANGE;
--+SKIP END;

CREATE TABLE PDT_RANGE
(
    F1   INTEGER,
    F2   INTEGER
) 
PARTITION BY RANGE( F1 )
(
    PARTITION P1 VALUES LESS THAN ( 10 ),
    PARTITION P2 VALUES LESS THAN ( 20 ),
    PARTITION P3 VALUES LESS THAN ( 30 ),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS;


--#########################################
--+SECTOR; DO JOB #1 (1. Basic Test)
--#########################################

-- nothing to do

--#########################################
--+SECTOR; DO JOB #2 (2. Validation Test)
--#########################################

------------------------------------------
-- 2.1 테이블의 종류에 따른 에러검사
------------------------------------------
-- should be fail
ALTER TABLE PDT_RANGE
ADD PARTITION P5;


--#########################################
--+SECTOR; DO JOB #3 (3. Execution Test)
--#########################################

-- nothing to do


--###################################
--+SECTOR; FINALIZE
--###################################

DROP TABLE PDT_RANGE;
