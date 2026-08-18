--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/PDT/Design/CREATE_INDEX/LOCAL_UNIQUE/integer_range.sql
--#
--# Body below is byte-identical to the original. The one line this port
--# adds is the premise: the original measures these statements on the
--# $GIT_ hidden-table implementation, this file measures the same
--# statements on the native global index (F07 -- see include/pinNative.sql).
--###########################################################################
--+LOAD_SQL ../../../../include/pinNative.sql;

--######################################################
-- INDEX UNIQUE ON RANGE PDT( PK:INTEGER )
--######################################################

--###################################
--+SECTOR; INTIALIZE
--###################################

--+SKIP BEGIN;
DROP TABLE PDT_RANGE;
DROP TABLE T;
--+SKIP END;


--#########################################
--+SECTOR; DO JOB #1 (1. Basic Test)
--#########################################

----------------------------------------
-- 2.1 CREATING INDEX USING CREATE_TABLE
----------------------------------------
CREATE TABLE PDT_RANGE
(
    F1   INTEGER UNIQUE,
    F2   INTEGER
) 
PARTITION BY RANGE( F1 )
(
    PARTITION P1 VALUES LESS THAN ( 10 ),
    PARTITION P2 VALUES LESS THAN ( 20 ),
    PARTITION P3 VALUES LESS THAN ( 30 ),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS;
INSERT INTO PDT_RANGE VALUES( 35, 0 );
INSERT INTO PDT_RANGE VALUES( 30, 0 );
INSERT INTO PDT_RANGE VALUES( 25, 0 );
INSERT INTO PDT_RANGE VALUES( 20, 0 );
INSERT INTO PDT_RANGE VALUES( 15, 0 );
INSERT INTO PDT_RANGE VALUES( 10, 0 );
INSERT INTO PDT_RANGE VALUES( 5, 0 );
INSERT INTO PDT_RANGE VALUES( 0, 0 );

-- should be {0}
SELECT F1 FROM PDT_RANGE
WHERE F1 >= 0 LIMIT 1;

----------------------------------------
-- 2.2 CREATING INDEX USING CREATE_INDEX
----------------------------------------
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
INSERT INTO PDT_RANGE VALUES( 35, 0 );
INSERT INTO PDT_RANGE VALUES( 30, 0 );
INSERT INTO PDT_RANGE VALUES( 25, 0 );
INSERT INTO PDT_RANGE VALUES( 20, 0 );
INSERT INTO PDT_RANGE VALUES( 15, 0 );
INSERT INTO PDT_RANGE VALUES( 10, 0 );
INSERT INTO PDT_RANGE VALUES( 5, 0 );
INSERT INTO PDT_RANGE VALUES( 0, 0 );

-- should be {5}
SELECT F1 FROM PDT_RANGE PARTITION( P1 ) LIMIT 1;

CREATE UNIQUE INDEX IDX 
ON PDT_RANGE( F1 );

-- should be {0}
SELECT /*+ INDEX ASC ( PDT_RANGE, IDX ) */ F1
FROM PDT_RANGE PARTITION( P1 ) LIMIT 1;

--#########################################
--+SECTOR; DO JOB #2 (2. Validation Test)
--#########################################

----------------------------
-- 2.1 파티셔너블 객체 검사 
----------------------------
CREATE TABLE T
(
    F1   INTEGER,
    F2   INTEGER
);
-- should be fail
CREATE UNIQUE INDEX IDX 
ON T( F1 );

-----------------------------------
-- 2.2 유니크 인덱스 생성 여부 검사 
-----------------------------------
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
CREATE UNIQUE INDEX IDX 
ON PDT_RANGE( F2 );
-- should be success
CREATE UNIQUE INDEX IDX 
ON PDT_RANGE( F2 );

-----------------------------------
-- 2.3 인덱스 파티션 개수 검사 
-----------------------------------
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
CREATE UNIQUE INDEX IDX 
ON PDT_RANGE( F1 );

-- should be fail
CREATE UNIQUE INDEX IDX 
ON PDT_RANGE( F1 );

-- should be success
CREATE UNIQUE INDEX IDX 
ON PDT_RANGE( F1 );

-----------------------------------
-- 2.4 인덱스 이름 중복 검사
-----------------------------------
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
CREATE UNIQUE INDEX IDX 
ON PDT_RANGE( F1 );

-- should be fail
CREATE UNIQUE INDEX IDX 
ON PDT_RANGE( F1 );

-----------------------------------
-- 2.5 테이블스페이스 검사 
-----------------------------------
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

-- memory tablespace
-- should be fail
CREATE UNIQUE INDEX IDX 
ON PDT_RANGE( F1 );

-- should be fail
-- temporary tablespace
CREATE UNIQUE INDEX IDX 
ON PDT_RANGE( F1 );

-- should be fail
-- undo tablespace
CREATE UNIQUE INDEX IDX 
ON PDT_RANGE( F1 );

--#########################################
--+SECTOR; DO JOB #3 (3. Execution Test)
--#########################################

-----------------------------------------
-- 3.1 Preserved Order(프리픽스드 인덱스)
-----------------------------------------
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
INSERT INTO PDT_RANGE VALUES( 35, 0 );
INSERT INTO PDT_RANGE VALUES( 30, 0 );
INSERT INTO PDT_RANGE VALUES( 25, 0 );
INSERT INTO PDT_RANGE VALUES( 20, 0 );
INSERT INTO PDT_RANGE VALUES( 15, 0 );
INSERT INTO PDT_RANGE VALUES( 10, 0 );
INSERT INTO PDT_RANGE VALUES( 5, 0 );
INSERT INTO PDT_RANGE VALUES( 0, 0 );

CREATE UNIQUE INDEX IDX 
ON PDT_RANGE( F1 );

-- should be {0,5,10,15,20,25,30,35}
SELECT /*+ INDEX ASC ( PDT_RANGE, IDX ) */ F1
FROM PDT_RANGE;

-----------------------------------------------
-- 3.2 Non-Preserved Order(논프리픽스드 인덱스)
-----------------------------------------------
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
INSERT INTO PDT_RANGE VALUES( 35, 10 );
INSERT INTO PDT_RANGE VALUES( 30, 15 );
INSERT INTO PDT_RANGE VALUES( 25, 20 );
INSERT INTO PDT_RANGE VALUES( 20, 25 );
INSERT INTO PDT_RANGE VALUES( 15, 30 );
INSERT INTO PDT_RANGE VALUES( 10, 35 );
INSERT INTO PDT_RANGE VALUES( 5, 0 );
INSERT INTO PDT_RANGE VALUES( 0, 5 );

CREATE UNIQUE INDEX IDX 
ON PDT_RANGE( F2 );

-- will be {10,15,20,25,30,35,0,5}
SELECT /*+ INDEX ASC ( PDT_RANGE, IDX ) */ F2
FROM PDT_RANGE;

-----------------------------------------
-- 3.3 Local Unique violation
-----------------------------------------
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
INSERT INTO PDT_RANGE VALUES( 35, 10 );
INSERT INTO PDT_RANGE VALUES( 30, 15 );
INSERT INTO PDT_RANGE VALUES( 25, 20 );
INSERT INTO PDT_RANGE VALUES( 20, 25 );
INSERT INTO PDT_RANGE VALUES( 15, 30 );
INSERT INTO PDT_RANGE VALUES( 10, 35 );
INSERT INTO PDT_RANGE VALUES( 5, 0 );
INSERT INTO PDT_RANGE VALUES( 0, 5 );

CREATE UNIQUE INDEX IDX 
ON PDT_RANGE( F2 );

INSERT INTO PDT_RANGE VALUES( 35, 20 );
INSERT INTO PDT_RANGE VALUES( 30, 25 );
INSERT INTO PDT_RANGE VALUES( 25, 30 );
INSERT INTO PDT_RANGE VALUES( 20, 35 );
INSERT INTO PDT_RANGE VALUES( 15, 0 );
INSERT INTO PDT_RANGE VALUES( 10, 5 );
INSERT INTO PDT_RANGE VALUES( 5, 10 );
INSERT INTO PDT_RANGE VALUES( 0, 15 );

-- should be 2
SELECT COUNT(*) FROM PDT_RANGE 
WHERE F2 = 20;

-- should be fail
INSERT INTO PDT_RANGE VALUES( 35, 10 );
-- should be fail
INSERT INTO PDT_RANGE VALUES( 30, 15 );
-- should be fail
INSERT INTO PDT_RANGE VALUES( 25, 20 );
-- should be fail
INSERT INTO PDT_RANGE VALUES( 20, 25 );
-- should be fail
INSERT INTO PDT_RANGE VALUES( 15, 30 );
-- should be fail
INSERT INTO PDT_RANGE VALUES( 10, 35 );
-- should be fail
INSERT INTO PDT_RANGE VALUES( 5, 0 );
-- should be fail
INSERT INTO PDT_RANGE VALUES( 0, 5 );

-----------------------------------------------------
-- 3.4 Local Unique violation caused by Row Movement
-----------------------------------------------------
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
INSERT INTO PDT_RANGE VALUES( 35, 0 );
INSERT INTO PDT_RANGE VALUES( 30, 0 );
INSERT INTO PDT_RANGE VALUES( 25, 0 );
INSERT INTO PDT_RANGE VALUES( 20, 0 );
INSERT INTO PDT_RANGE VALUES( 15, 0 );
INSERT INTO PDT_RANGE VALUES( 10, 0 );
INSERT INTO PDT_RANGE VALUES( 5, 0 );
INSERT INTO PDT_RANGE VALUES( 0, 0 );

CREATE UNIQUE INDEX IDX 
ON PDT_RANGE( F1 );

ALTER TABLE PDT_RANGE
ENABLE ROW MOVEMENT;

-- BUGBUG
-- should be fail
-- UPDATE PDT_RANGE SET F1 = 20
-- WHERE F1 = 30;

--###################################
--+SECTOR; FINALIZE
--###################################

DROP TABLE PDT_RANGE;
