--######################################################
-- RENAME PARTITIOIN
--######################################################

--###################################
--+SECTOR; INTIALIZE
--###################################

--+SKIP BEGIN;
DROP TABLE PDT_LIST;
--+SKIP END;

CREATE TABLE PDT_LIST
(
    F1   INTEGER,
    F2   INTEGER
) 
PARTITION BY LIST( F1 )
(
    PARTITION P1 VALUES ( 10 ),
    PARTITION P2 VALUES ( 20 ),
    PARTITION P3 VALUES ( 30 ),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS;

CREATE INDEX IDX ON PDT_LIST(F1);

--#########################################
--+SECTOR; DO JOB #1 (1. Basic Test)
--#########################################

ALTER TABLE PDT_LIST
RENAME PARTITION P1 TO P1_1;

--#########################################
--+SECTOR; DO JOB #2 (2. Validation Test)
--#########################################

----------------------------
-- 2.1 파티션 이름 중복 검사
----------------------------
-- should be fail
ALTER TABLE PDT_LIST
RENAME PARTITION P1_1 TO P1_1;

ALTER TABLE PDT_LIST
RENAME PARTITION P1_1 TO P3;


--#########################################
--+SECTOR; DO JOB #3 (3. Execution Test)
--#########################################

DROP TABLE PDT_LIST;
CREATE TABLE PDT_LIST
(
    F1   INTEGER,
    F2   INTEGER
) 
PARTITION BY LIST( F1 )
(
    PARTITION P1 VALUES ( 10 ),
    PARTITION P2 VALUES ( 20 ),
    PARTITION P3 VALUES ( 30 ),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS;
INSERT INTO PDT_LIST VALUES( 10, 0 );
INSERT INTO PDT_LIST VALUES( 20, 0 );
INSERT INTO PDT_LIST VALUES( 30, 0 );
INSERT INTO PDT_LIST VALUES( 40, 0 );

-- should be 4
SELECT COUNT(*) FROM PDT_LIST;

ALTER TABLE PDT_LIST
RENAME PARTITION P1 TO P1_1;

-- should be 4
SELECT COUNT(*) FROM PDT_LIST;

-- should be 1
SELECT COUNT(*) FROM PDT_LIST PARTITION( P1_1 );
-- should be fail
SELECT COUNT(*) FROM PDT_LIST PARTITION( P1 );


--###################################
--+SECTOR; FINALIZE
--###################################

DROP TABLE PDT_LIST;
