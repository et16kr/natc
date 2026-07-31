--######################################################
-- RENAME PARTITIOIN
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

CREATE INDEX IDX ON PDT_RANGE(F1);

--#########################################
--+SECTOR; DO JOB #1 (1. Basic Test)
--#########################################

ALTER TABLE PDT_RANGE
RENAME PARTITION P1 TO P1_1;

--#########################################
--+SECTOR; DO JOB #2 (2. Validation Test)
--#########################################

----------------------------
-- 2.1 파티션 이름 중복 검사
----------------------------
-- should be fail
ALTER TABLE PDT_RANGE
RENAME PARTITION P1_1 TO P1_1;

ALTER TABLE PDT_RANGE
RENAME PARTITION P1_1 TO P3;


--#########################################
--+SECTOR; DO JOB #3 (3. Execution Test)
--#########################################

DROP TABLE PDT_RANGE;
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
INSERT INTO PDT_RANGE VALUES( 0, 0 );
INSERT INTO PDT_RANGE VALUES( 10, 0 );
INSERT INTO PDT_RANGE VALUES( 20, 0 );
INSERT INTO PDT_RANGE VALUES( 30, 0 );

-- should be 4
SELECT COUNT(*) FROM PDT_RANGE;

ALTER TABLE PDT_RANGE
RENAME PARTITION P1 TO P1_1;

-- should be 4
SELECT COUNT(*) FROM PDT_RANGE;

-- should be 1
SELECT COUNT(*) FROM PDT_RANGE PARTITION( P1_1 );
-- should be fail
SELECT COUNT(*) FROM PDT_RANGE PARTITION( P1 );


--###################################
--+SECTOR; FINALIZE
--###################################

DROP TABLE PDT_RANGE;
