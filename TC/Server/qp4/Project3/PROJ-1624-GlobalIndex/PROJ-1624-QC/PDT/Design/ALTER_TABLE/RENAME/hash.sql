--######################################################
-- RENAME PARTITIOIN
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

CREATE INDEX IDX ON PDT_HASH(F1);

--#########################################
--+SECTOR; DO JOB #1 (1. Basic Test)
--#########################################

ALTER TABLE PDT_HASH
RENAME PARTITION P1 TO P1_1;

--#########################################
--+SECTOR; DO JOB #2 (2. Validation Test)
--#########################################

----------------------------
-- 2.1 파티션 이름 중복 검사
----------------------------
-- should be fail
ALTER TABLE PDT_HASH
RENAME PARTITION P1_1 TO P1_1;

ALTER TABLE PDT_HASH
RENAME PARTITION P1_1 TO P3;


--#########################################
--+SECTOR; DO JOB #3 (3. Execution Test)
--#########################################

DROP TABLE PDT_HASH;
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
INSERT INTO PDT_HASH VALUES( 0, 0 );
INSERT INTO PDT_HASH VALUES( 1, 0 );
INSERT INTO PDT_HASH VALUES( 2, 0 );
INSERT INTO PDT_HASH VALUES( 3, 0 );
INSERT INTO PDT_HASH VALUES( 4, 0 );

-- should be 5
SELECT COUNT(*) FROM PDT_HASH;

ALTER TABLE PDT_HASH
RENAME PARTITION P1 TO P1_1;

-- should be 5
SELECT COUNT(*) FROM PDT_HASH;

-- should be success
SELECT COUNT(*) FROM PDT_HASH PARTITION( P1_1 );
-- should be fail
SELECT COUNT(*) FROM PDT_HASH PARTITION( P1 );


--###################################
--+SECTOR; FINALIZE
--###################################

DROP TABLE PDT_HASH;
