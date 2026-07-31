--######################################################
-- DROP PARTITIOIN ( PK:INTEGER )
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


--#########################################
--+SECTOR; DO JOB #1 (1. Basic Test)
--#########################################

INSERT INTO PDT_LIST VALUES( 10, 0 );
INSERT INTO PDT_LIST VALUES( 20, 0 );
INSERT INTO PDT_LIST VALUES( 30, 0 );
INSERT INTO PDT_LIST VALUES( 40, 0 );

SELECT F1 FROM PDT_LIST PARTITION( P1 );
SELECT F1 FROM PDT_LIST PARTITION( P2 );
SELECT F1 FROM PDT_LIST PARTITION( P3 );
SELECT F1 FROM PDT_LIST PARTITION( P4 );

-- should be 4
SELECT COUNT(*) FROM PDT_LIST;

ALTER TABLE PDT_LIST
DROP PARTITION P1;

-- should be [20, 30, 40]
SELECT F1 FROM PDT_LIST;

--#########################################
--+SECTOR; DO JOB #2 (2. Validation Test)
--#########################################

----------------------------
-- 2.1 최소 파티션 개수 유지
----------------------------
-- should be success
ALTER TABLE PDT_LIST
DROP PARTITION P2;
-- should be success
ALTER TABLE PDT_LIST
DROP PARTITION P3;
-- should be fail
ALTER TABLE PDT_LIST
DROP PARTITION P4;

--------------------------------------
-- 2.2 기본 파티션 삭제 허용 여부 검사
--------------------------------------
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

-- should be fail
ALTER TABLE PDT_LIST
DROP PARTITION P4;

--#########################################
--+SECTOR; DO JOB #3 (3. Execution Test)
--#########################################

-------------------------------------
-- 3.1 기본 파티션의 파티션 조건 수정
-------------------------------------
INSERT INTO PDT_LIST VALUES( 10, 0 );
INSERT INTO PDT_LIST VALUES( 20, 0 );
INSERT INTO PDT_LIST VALUES( 30, 0 );
INSERT INTO PDT_LIST VALUES( 40, 0 );

SELECT F1 FROM PDT_LIST PARTITION( P1 );
SELECT F1 FROM PDT_LIST PARTITION( P2 );
SELECT F1 FROM PDT_LIST PARTITION( P3 );
SELECT F1 FROM PDT_LIST PARTITION( P4 );

-- should be 4
SELECT COUNT(*) FROM PDT_LIST;

ALTER TABLE PDT_LIST
DROP PARTITION P1;

-- should be 3
SELECT COUNT(*) FROM PDT_LIST;

INSERT INTO PDT_LIST VALUES( 10, 0 );

-- should be 1
SELECT COUNT(*) FROM PDT_LIST PARTITION( P2 );
-- should be 2
SELECT COUNT(*) FROM PDT_LIST PARTITION( P4 );

ALTER TABLE PDT_LIST
DROP PARTITION P3;

-- should be 3
SELECT COUNT(*) FROM PDT_LIST;

INSERT INTO PDT_LIST VALUES( 30, 0 );

-- should be 3
SELECT COUNT(*) FROM PDT_LIST PARTITION( P4 );


--###################################
--+SECTOR; FINALIZE
--###################################

DROP TABLE PDT_LIST;
