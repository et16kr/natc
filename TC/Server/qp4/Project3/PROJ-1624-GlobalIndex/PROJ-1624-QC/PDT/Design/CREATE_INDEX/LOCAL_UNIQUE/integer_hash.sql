--######################################################
-- INDEX UNIQUE ON HASH PDT( PK:INTEGER )
--######################################################

--###################################
--+SECTOR; INTIALIZE
--###################################

--+SKIP BEGIN;
DROP TABLE PDT_HASH;
DROP TABLE T;
--+SKIP END;


--#########################################
--+SECTOR; DO JOB #1 (1. Basic Test)
--#########################################

----------------------------------------
-- 2.1 CREATING INDEX USING CREATE_TABLE
----------------------------------------
CREATE TABLE PDT_HASH
(
    F1   INTEGER UNIQUE,
    F2   INTEGER
) 
PARTITION BY HASH( F1 )
(
    PARTITION P1,
    PARTITION P2,
    PARTITION P3,
    PARTITION P4
) TABLESPACE PDT_TBS;
INSERT INTO PDT_HASH VALUES( 7, 0 );
INSERT INTO PDT_HASH VALUES( 6, 0 );
INSERT INTO PDT_HASH VALUES( 5, 0 );
INSERT INTO PDT_HASH VALUES( 4, 0 );
INSERT INTO PDT_HASH VALUES( 3, 0 );
INSERT INTO PDT_HASH VALUES( 2, 0 );
INSERT INTO PDT_HASH VALUES( 1, 0 );
INSERT INTO PDT_HASH VALUES( 0, 0 );

-- should be {0}
SELECT F1 FROM PDT_HASH
WHERE F1 >= 0 LIMIT 1;

----------------------------------------
-- 2.2 CREATING INDEX USING CREATE_INDEX
----------------------------------------
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
INSERT INTO PDT_HASH VALUES( 7, 0 );
INSERT INTO PDT_HASH VALUES( 6, 0 );
INSERT INTO PDT_HASH VALUES( 5, 0 );
INSERT INTO PDT_HASH VALUES( 4, 0 );
INSERT INTO PDT_HASH VALUES( 3, 0 );
INSERT INTO PDT_HASH VALUES( 2, 0 );
INSERT INTO PDT_HASH VALUES( 1, 0 );
INSERT INTO PDT_HASH VALUES( 0, 0 );

-- should be {4}
SELECT F1 FROM PDT_HASH PARTITION( P1 ) LIMIT 1;

CREATE UNIQUE INDEX IDX
ON PDT_HASH( F1 );

-- should be {0}
SELECT /*+ INDEX ASC ( PDT_HASH, IDX ) */ F1
FROM PDT_HASH PARTITION( P1 ) LIMIT 1;

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
-- 2.2 로컬 유니크 인덱스 생성 여부 검사 
-----------------------------------
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

-- should be fail
CREATE INDEX IDX 
ON PDT_HASH( F2 );
-- should be success
CREATE UNIQUE INDEX IDX 
ON PDT_HASH( F2 );

-----------------------------------
-- 2.3 인덱스 파티션 개수 검사 
-----------------------------------
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

-- should be fail
CREATE UNIQUE INDEX IDX 
ON PDT_HASH( F1 );

-- should be fail
CREATE UNIQUE INDEX IDX 
ON PDT_HASH( F1 );

-- should be success
CREATE UNIQUE INDEX IDX 
ON PDT_HASH( F1 );

-----------------------------------
-- 2.4 인덱스 이름 중복 검사
-----------------------------------
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

-- should be fail
CREATE UNIQUE INDEX IDX 
ON PDT_HASH( F1 );

-- should be fail
CREATE UNIQUE INDEX IDX 
ON PDT_HASH( F1 );


-----------------------------------
-- 2.5 테이블스페이스 검사 
-----------------------------------
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

-- memory tablespace
-- should be fail
CREATE UNIQUE INDEX IDX 
ON PDT_HASH( F1 );

-- should be fail
-- temporary tablespace
CREATE UNIQUE INDEX IDX 
ON PDT_HASH( F1 );

-- should be fail
-- undo tablespace
CREATE UNIQUE INDEX IDX 
ON PDT_HASH( F1 );

--#########################################
--+SECTOR; DO JOB #3 (3. Execution Test)
--#########################################

-----------------------------------------
-- 3.1 Preserved Order(프리픽스드 인덱스)
-----------------------------------------
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
INSERT INTO PDT_HASH VALUES( 7, 0 );
INSERT INTO PDT_HASH VALUES( 6, 0 );
INSERT INTO PDT_HASH VALUES( 5, 0 );
INSERT INTO PDT_HASH VALUES( 4, 0 );
INSERT INTO PDT_HASH VALUES( 3, 0 );
INSERT INTO PDT_HASH VALUES( 2, 0 );
INSERT INTO PDT_HASH VALUES( 1, 0 );
INSERT INTO PDT_HASH VALUES( 0, 0 );

CREATE UNIQUE INDEX IDX 
ON PDT_HASH( F1 );

-- should be {0,1,2,3,4,5,6,7}
SELECT /*+ INDEX ASC ( PDT_HASH, IDX ) */ F1
FROM PDT_HASH;

-----------------------------------------------
-- 3.2 Non-Preserved Order(논프리픽스드 인덱스)
-----------------------------------------------
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
INSERT INTO PDT_HASH VALUES( 7, 2 );
INSERT INTO PDT_HASH VALUES( 6, 3 );
INSERT INTO PDT_HASH VALUES( 5, 4 );
INSERT INTO PDT_HASH VALUES( 4, 5 );
INSERT INTO PDT_HASH VALUES( 3, 6 );
INSERT INTO PDT_HASH VALUES( 2, 7 );
INSERT INTO PDT_HASH VALUES( 1, 0 );
INSERT INTO PDT_HASH VALUES( 0, 1 );

CREATE UNIQUE INDEX IDX 
ON PDT_HASH( F2 );

-- will be {1,5,0,4,3,7,2,6}
SELECT /*+ INDEX ASC ( PDT_HASH, IDX ) */ F2
FROM PDT_HASH;

-----------------------------------------
-- 3.3 Local Unique violation
-----------------------------------------
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
INSERT INTO PDT_HASH VALUES( 7, 2 );
INSERT INTO PDT_HASH VALUES( 6, 3 );
INSERT INTO PDT_HASH VALUES( 5, 4 );
INSERT INTO PDT_HASH VALUES( 4, 5 );
INSERT INTO PDT_HASH VALUES( 3, 6 );
INSERT INTO PDT_HASH VALUES( 2, 7 );
INSERT INTO PDT_HASH VALUES( 1, 0 );
INSERT INTO PDT_HASH VALUES( 0, 1 );

CREATE UNIQUE INDEX IDX 
ON PDT_HASH( F2 );

INSERT INTO PDT_HASH VALUES( 7, 3 );
INSERT INTO PDT_HASH VALUES( 6, 4 );
INSERT INTO PDT_HASH VALUES( 5, 5 );
INSERT INTO PDT_HASH VALUES( 4, 6 );
INSERT INTO PDT_HASH VALUES( 3, 7 );
INSERT INTO PDT_HASH VALUES( 2, 0 );
INSERT INTO PDT_HASH VALUES( 1, 1 );
INSERT INTO PDT_HASH VALUES( 0, 2 );

-- should be 2
SELECT COUNT(*) FROM PDT_HASH 
WHERE F2 = 3;

-- should be fail
INSERT INTO PDT_HASH VALUES( 7, 2 );
-- should be fail
INSERT INTO PDT_HASH VALUES( 6, 3 );
-- should be fail
INSERT INTO PDT_HASH VALUES( 5, 4 );
-- should be fail
INSERT INTO PDT_HASH VALUES( 4, 5 );
-- should be fail
INSERT INTO PDT_HASH VALUES( 3, 6 );
-- should be fail
INSERT INTO PDT_HASH VALUES( 2, 7 );
-- should be fail
INSERT INTO PDT_HASH VALUES( 1, 0 );
-- should be fail
INSERT INTO PDT_HASH VALUES( 0, 1 );

-----------------------------------------------------
-- 3.4 Local Unique violation caused by Row Movement
-----------------------------------------------------
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
INSERT INTO PDT_HASH VALUES( 7, 0 );
INSERT INTO PDT_HASH VALUES( 6, 0 );
INSERT INTO PDT_HASH VALUES( 5, 0 );
INSERT INTO PDT_HASH VALUES( 4, 0 );
INSERT INTO PDT_HASH VALUES( 3, 0 );
INSERT INTO PDT_HASH VALUES( 2, 0 );
INSERT INTO PDT_HASH VALUES( 1, 0 );
INSERT INTO PDT_HASH VALUES( 0, 0 );

CREATE UNIQUE INDEX IDX 
ON PDT_HASH( F1 );

ALTER TABLE PDT_HASH
ENABLE ROW MOVEMENT;

-- BUGBUG
-- should be fail
-- UPDATE PDT_HASH SET F1 = 20
-- WHERE F1 = 30;

--###################################
--+SECTOR; FINALIZE
--###################################

DROP TABLE PDT_HASH;
