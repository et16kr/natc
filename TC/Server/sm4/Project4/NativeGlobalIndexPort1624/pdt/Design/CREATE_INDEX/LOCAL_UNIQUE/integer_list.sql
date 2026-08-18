--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/PDT/Design/CREATE_INDEX/LOCAL_UNIQUE/integer_list.sql
--#
--# Body below is byte-identical to the original. The one line this port
--# adds is the premise: the original measures these statements on the
--# $GIT_ hidden-table implementation, this file measures the same
--# statements on the native global index (F07 -- see include/pinNative.sql).
--###########################################################################
--+LOAD_SQL ../../../../include/pinNative.sql;

--######################################################
-- INDEX UNIQUE ON LIST PDT( PK:INTEGER )
--######################################################

--###################################
--+SECTOR; INTIALIZE
--###################################

--+SKIP BEGIN;
DROP TABLE PDT_LIST;
DROP TABLE T;
--+SKIP END;


--#########################################
--+SECTOR; DO JOB #1 (1. Basic Test)
--#########################################

----------------------------------------
-- 2.1 CREATING INDEX USING CREATE_TABLE
----------------------------------------
CREATE TABLE PDT_LIST
(
    F1   INTEGER UNIQUE,
    F2   INTEGER
) 
PARTITION BY LIST( F1 )
(
    PARTITION P1 VALUES ( 10, 15 ),
    PARTITION P2 VALUES ( 20, 25 ),
    PARTITION P3 VALUES ( 30, 35 ),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS;
INSERT INTO PDT_LIST VALUES( 45, 0 );
INSERT INTO PDT_LIST VALUES( 40, 0 );
INSERT INTO PDT_LIST VALUES( 35, 0 );
INSERT INTO PDT_LIST VALUES( 30, 0 );
INSERT INTO PDT_LIST VALUES( 25, 0 );
INSERT INTO PDT_LIST VALUES( 20, 0 );
INSERT INTO PDT_LIST VALUES( 15, 0 );
INSERT INTO PDT_LIST VALUES( 10, 0 );

-- should be {10}
SELECT F1 FROM PDT_LIST
WHERE F1 >= 0 LIMIT 1;

----------------------------------------
-- 2.2 CREATING INDEX USING CREATE_INDEX
----------------------------------------
DROP TABLE PDT_LIST;
CREATE TABLE PDT_LIST
(
    F1   INTEGER,
    F2   INTEGER
) 
PARTITION BY LIST( F1 )
(
    PARTITION P1 VALUES ( 10, 15 ),
    PARTITION P2 VALUES ( 20, 25 ),
    PARTITION P3 VALUES ( 30, 35 ),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS;
INSERT INTO PDT_LIST VALUES( 45, 0 );
INSERT INTO PDT_LIST VALUES( 40, 0 );
INSERT INTO PDT_LIST VALUES( 35, 0 );
INSERT INTO PDT_LIST VALUES( 30, 0 );
INSERT INTO PDT_LIST VALUES( 25, 0 );
INSERT INTO PDT_LIST VALUES( 20, 0 );
INSERT INTO PDT_LIST VALUES( 15, 0 );
INSERT INTO PDT_LIST VALUES( 10, 0 );

-- should be {45}
SELECT F1 FROM PDT_LIST PARTITION( P1 ) LIMIT 1;

CREATE UNIQUE INDEX IDX 
ON PDT_LIST( F1 );

-- should be {10}
SELECT /*+ INDEX ASC ( PDT_LIST, IDX ) */ F1
FROM PDT_LIST PARTITION( P1 ) LIMIT 1;

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
ON T( F1 ) ;

-----------------------------------
-- 2.2 유니크 인덱스 생성 여부 검사 
-----------------------------------
DROP TABLE PDT_LIST;
CREATE TABLE PDT_LIST
(
    F1   INTEGER,
    F2   INTEGER
) 
PARTITION BY LIST( F1 )
(
    PARTITION P1 VALUES ( 10, 15 ),
    PARTITION P2 VALUES ( 20, 25 ),
    PARTITION P3 VALUES ( 30, 35 ),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS;

-- should be fail
CREATE INDEX IDX 
ON PDT_LIST( F2 );
-- should be success
CREATE UNIQUE INDEX IDX 
ON PDT_LIST( F2 );

-----------------------------------
-- 2.3 인덱스 파티션 개수 검사 
-----------------------------------
DROP TABLE PDT_LIST;
CREATE TABLE PDT_LIST
(
    F1   INTEGER,
    F2   INTEGER
) 
PARTITION BY LIST( F1 )
(
    PARTITION P1 VALUES ( 10, 15 ),
    PARTITION P2 VALUES ( 20, 25 ),
    PARTITION P3 VALUES ( 30, 35 ),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS;

-- should be fail
CREATE UNIQUE INDEX IDX 
ON PDT_LIST( F1 );

-- should be fail
CREATE UNIQUE INDEX IDX 
ON PDT_LIST( F1 );

-- should be success
CREATE UNIQUE INDEX IDX 
ON PDT_LIST( F1 );

-----------------------------------
-- 2.4 인덱스 이름 중복 검사
-----------------------------------
DROP TABLE PDT_LIST;
CREATE TABLE PDT_LIST
(
    F1   INTEGER,
    F2   INTEGER
) 
PARTITION BY LIST( F1 )
(
    PARTITION P1 VALUES ( 10, 15 ),
    PARTITION P2 VALUES ( 20, 25 ),
    PARTITION P3 VALUES ( 30, 35 ),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS;

-- should be fail
CREATE UNIQUE INDEX IDX 
ON PDT_LIST( F1 );

-- should be fail
CREATE UNIQUE INDEX IDX 
ON PDT_LIST( F1 );


-----------------------------------
-- 2.5 테이블스페이스 검사 
-----------------------------------
DROP TABLE PDT_LIST;
CREATE TABLE PDT_LIST
(
    F1   INTEGER,
    F2   INTEGER
) 
PARTITION BY LIST( F1 )
(
    PARTITION P1 VALUES ( 10, 15 ),
    PARTITION P2 VALUES ( 20, 25 ),
    PARTITION P3 VALUES ( 30, 35 ),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS;

-- memory tablespace
-- should be fail
CREATE UNIQUE INDEX IDX 
ON PDT_LIST( F1 );

-- should be fail
-- temporary tablespace
CREATE UNIQUE INDEX IDX 
ON PDT_LIST( F1 );

-- should be fail
-- undo tablespace
CREATE UNIQUE INDEX IDX 
ON PDT_LIST( F1 );

--#########################################
--+SECTOR; DO JOB #3 (3. Execution Test)
--#########################################

-----------------------------------------
-- 3.1 Preserved Order(프리픽스드 인덱스)
-----------------------------------------
DROP TABLE PDT_LIST;
CREATE TABLE PDT_LIST
(
    F1   INTEGER,
    F2   INTEGER
) 
PARTITION BY LIST( F1 )
(
    PARTITION P1 VALUES ( 10, 15 ),
    PARTITION P2 VALUES ( 20, 25 ),
    PARTITION P3 VALUES ( 30, 35 ),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS;
INSERT INTO PDT_LIST VALUES( 45, 0 );
INSERT INTO PDT_LIST VALUES( 40, 0 );
INSERT INTO PDT_LIST VALUES( 35, 0 );
INSERT INTO PDT_LIST VALUES( 30, 0 );
INSERT INTO PDT_LIST VALUES( 25, 0 );
INSERT INTO PDT_LIST VALUES( 20, 0 );
INSERT INTO PDT_LIST VALUES( 15, 0 );
INSERT INTO PDT_LIST VALUES( 10, 0 );

CREATE UNIQUE INDEX IDX 
ON PDT_LIST( F1 ) LOCAL;

-- should be {10,15,20,25,30,35,40,45}
SELECT /*+ INDEX ASC ( PDT_LIST, IDX ) */ F1
FROM PDT_LIST;

-----------------------------------------------
-- 3.2 Non-Preserved Order(논프리픽스드 인덱스)
-----------------------------------------------
DROP TABLE PDT_LIST;
CREATE TABLE PDT_LIST
(
    F1   INTEGER,
    F2   INTEGER
) 
PARTITION BY LIST( F1 )
(
    PARTITION P1 VALUES ( 10, 15 ),
    PARTITION P2 VALUES ( 20, 25 ),
    PARTITION P3 VALUES ( 30, 35 ),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS;
INSERT INTO PDT_LIST VALUES( 45, 20 );
INSERT INTO PDT_LIST VALUES( 40, 25 );
INSERT INTO PDT_LIST VALUES( 35, 30 );
INSERT INTO PDT_LIST VALUES( 30, 35 );
INSERT INTO PDT_LIST VALUES( 25, 40 );
INSERT INTO PDT_LIST VALUES( 20, 45 );
INSERT INTO PDT_LIST VALUES( 15, 10 );
INSERT INTO PDT_LIST VALUES( 10, 15 );

CREATE UNIQUE INDEX IDX 
ON PDT_LIST( F2 );

-- will be {20,25,30,35,40,45,10,15}
SELECT /*+ INDEX ASC ( PDT_LIST, IDX ) */ F2
FROM PDT_LIST;

-----------------------------------------
-- 3.3 Local Unique violation
-----------------------------------------
DROP TABLE PDT_LIST;
CREATE TABLE PDT_LIST
(
    F1   INTEGER,
    F2   INTEGER
) 
PARTITION BY LIST( F1 )
(
    PARTITION P1 VALUES ( 10, 15 ),
    PARTITION P2 VALUES ( 20, 25 ),
    PARTITION P3 VALUES ( 30, 35 ),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS;
INSERT INTO PDT_LIST VALUES( 45, 20 );
INSERT INTO PDT_LIST VALUES( 40, 25 );
INSERT INTO PDT_LIST VALUES( 35, 30 );
INSERT INTO PDT_LIST VALUES( 30, 35 );
INSERT INTO PDT_LIST VALUES( 25, 40 );
INSERT INTO PDT_LIST VALUES( 20, 45 );
INSERT INTO PDT_LIST VALUES( 15, 10 );
INSERT INTO PDT_LIST VALUES( 10, 15 );

CREATE UNIQUE INDEX IDX 
ON PDT_LIST( F2 );

INSERT INTO PDT_LIST VALUES( 45, 30 );
INSERT INTO PDT_LIST VALUES( 40, 35 );
INSERT INTO PDT_LIST VALUES( 35, 40 );
INSERT INTO PDT_LIST VALUES( 30, 45 );
INSERT INTO PDT_LIST VALUES( 25, 10 );
INSERT INTO PDT_LIST VALUES( 20, 15 );
INSERT INTO PDT_LIST VALUES( 15, 20 );
INSERT INTO PDT_LIST VALUES( 10, 25 );

-- should be 2
SELECT COUNT(*) FROM PDT_LIST 
WHERE F2 = 20;

-- should be fail
INSERT INTO PDT_LIST VALUES( 45, 20 );
-- should be fail
INSERT INTO PDT_LIST VALUES( 40, 25 );
-- should be fail
INSERT INTO PDT_LIST VALUES( 35, 30 );
-- should be fail
INSERT INTO PDT_LIST VALUES( 30, 35 );
-- should be fail
INSERT INTO PDT_LIST VALUES( 25, 40 );
-- should be fail
INSERT INTO PDT_LIST VALUES( 20, 45 );
-- should be fail
INSERT INTO PDT_LIST VALUES( 15, 10 );
-- should be fail
INSERT INTO PDT_LIST VALUES( 10, 15 );

-----------------------------------------------------
-- 3.4 Local Unique violation caused by Row Movement
-----------------------------------------------------
DROP TABLE PDT_LIST;
CREATE TABLE PDT_LIST
(
    F1   INTEGER,
    F2   INTEGER
) 
PARTITION BY LIST( F1 )
(
    PARTITION P1 VALUES ( 10, 15 ),
    PARTITION P2 VALUES ( 20, 25 ),
    PARTITION P3 VALUES ( 30, 35 ),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS;
INSERT INTO PDT_LIST VALUES( 45, 0 );
INSERT INTO PDT_LIST VALUES( 40, 0 );
INSERT INTO PDT_LIST VALUES( 35, 0 );
INSERT INTO PDT_LIST VALUES( 30, 0 );
INSERT INTO PDT_LIST VALUES( 25, 0 );
INSERT INTO PDT_LIST VALUES( 20, 0 );
INSERT INTO PDT_LIST VALUES( 15, 0 );
INSERT INTO PDT_LIST VALUES( 10, 0 );

CREATE UNIQUE INDEX IDX 
ON PDT_LIST( F1 );

ALTER TABLE PDT_LIST
ENABLE ROW MOVEMENT;

-- BUGBUG
-- should be fail
-- UPDATE PDT_LIST SET F1 = 20
-- WHERE F1 = 30;


--###################################
--+SECTOR; FINALIZE
--###################################

DROP TABLE PDT_LIST;
