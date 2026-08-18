--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/PDT/Design/ALTER_TABLE/DROP/integer_range.sql
--#
--# Body below is byte-identical to the original. The one line this port
--# adds is the premise: the original measures these statements on the
--# $GIT_ hidden-table implementation, this file measures the same
--# statements on the native global index (F07 -- see include/pinNative.sql).
--###########################################################################
--+LOAD_SQL ../../../../include/pinNative.sql;

--######################################################
-- DROP PARTITIOIN ( PK:INTEGER )
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

INSERT INTO PDT_RANGE VALUES( 0, 0 );
INSERT INTO PDT_RANGE VALUES( 10, 0 );
INSERT INTO PDT_RANGE VALUES( 20, 0 );
INSERT INTO PDT_RANGE VALUES( 30, 0 );

SELECT F1 FROM PDT_RANGE PARTITION( P1 );
SELECT F1 FROM PDT_RANGE PARTITION( P2 );
SELECT F1 FROM PDT_RANGE PARTITION( P3 );
SELECT F1 FROM PDT_RANGE PARTITION( P4 );

-- should be 4
SELECT COUNT(*) FROM PDT_RANGE;

ALTER TABLE PDT_RANGE
DROP PARTITION P1;

-- should be [10, 20, 30]
SELECT F1 FROM PDT_RANGE;


--#########################################
--+SECTOR; DO JOB #2 (2. Validation Test)
--#########################################

----------------------------
-- 2.1 최소 파티션 개수 유지
----------------------------
-- should be success
ALTER TABLE PDT_RANGE
DROP PARTITION P2;
-- should be success
ALTER TABLE PDT_RANGE
DROP PARTITION P3;
-- should be fail
ALTER TABLE PDT_RANGE
DROP PARTITION P4;

--------------------------------------
-- 2.2 기본 파티션 삭제 허용 여부 검사
--------------------------------------
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

-- should be fail
ALTER TABLE PDT_RANGE
DROP PARTITION P4;


--#########################################
--+SECTOR; DO JOB #3 (3. Execution Test)
--#########################################

-------------------------------------
-- 3.1 이웃 파티션의 파티션 조건 수정
-------------------------------------
INSERT INTO PDT_RANGE VALUES( 0, 0 );
INSERT INTO PDT_RANGE VALUES( 10, 0 );
INSERT INTO PDT_RANGE VALUES( 20, 0 );
INSERT INTO PDT_RANGE VALUES( 30, 0 );

SELECT F1 FROM PDT_RANGE PARTITION( P1 );
SELECT F1 FROM PDT_RANGE PARTITION( P2 );
SELECT F1 FROM PDT_RANGE PARTITION( P3 );
SELECT F1 FROM PDT_RANGE PARTITION( P4 );

-- should be 4
SELECT COUNT(*) FROM PDT_RANGE;

ALTER TABLE PDT_RANGE
DROP PARTITION P1;

-- should be 3
SELECT COUNT(*) FROM PDT_RANGE;

INSERT INTO PDT_RANGE VALUES( 0, 0 );

-- should be 2
SELECT COUNT(*) FROM PDT_RANGE PARTITION( P2 );

ALTER TABLE PDT_RANGE
DROP PARTITION P3;

-- should be 3
SELECT COUNT(*) FROM PDT_RANGE;

INSERT INTO PDT_RANGE VALUES( 20, 0 );

-- should be 2
SELECT COUNT(*) FROM PDT_RANGE PARTITION( P4 );


--###################################
--+SECTOR; FINALIZE
--###################################

DROP TABLE PDT_RANGE;
