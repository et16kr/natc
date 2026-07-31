--######################################################
-- CREATE LIST PARTITIONED DISK TABLE 
-- PARTITION KEY : INTEGER
--######################################################

--###################################
--+SECTOR; INTIALIZE
--###################################

--+SKIP BEGIN;
DROP TABLE PDT;
--+SKIP END;

--#########################################
--+SECTOR; DO JOB #1 (1. Basic Test)
--#########################################

CREATE TABLE PDT
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

INSERT INTO PDT VALUES( 10, 0 );

INSERT INTO PDT VALUES( 20, 0 );
INSERT INTO PDT VALUES( 20, 0 );

INSERT INTO PDT VALUES( 30, 0 );
INSERT INTO PDT VALUES( 30, 0 );
INSERT INTO PDT VALUES( 30, 0 );

INSERT INTO PDT VALUES( 40, 0 );
INSERT INTO PDT VALUES( 40, 0 );
INSERT INTO PDT VALUES( 40, 0 );
INSERT INTO PDT VALUES( 40, 0 );

-- are u sure that COUNT(*) is 1
SELECT COUNT(*) FROM PDT PARTITION( P1 );
-- are u sure that COUNT(*) is 2
SELECT COUNT(*) FROM PDT PARTITION( P2 );
-- are u sure that COUNT(*) is 3
SELECT COUNT(*) FROM PDT PARTITION( P3 );
-- are u sure that COUNT(*) is 4
SELECT COUNT(*) FROM PDT PARTITION( P4 );

DROP TABLE PDT;

--#########################################
--+SECTOR; DO JOB #2 (2. Validation Test)
--#########################################

------------------------------------------
-- 2.1 파티션 키 컬럼 개수 체크
------------------------------------------
-- should be fail
CREATE TABLE PDT
(
    F1   INTEGER,
    F2   INTEGER
) 
PARTITION BY LIST( F1, F2 )
(
    PARTITION P1 VALUES ( 10 ),
    PARTITION P2 VALUES ( 20 ),
    PARTITION P3 VALUES ( 30 ),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS;
DROP TABLE PDT;

------------------------------------------
-- 2.2 중복 파티션 조건값 체크 
------------------------------------------
-- should be fail
CREATE TABLE PDT
(
    F1   INTEGER,
    F2   INTEGER
) 
PARTITION BY LIST( F1 )
(
    PARTITION P1 VALUES ( 10 ),
    PARTITION P2 VALUES ( 20 ),
    PARTITION P3 VALUES ( 10 ),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS;
DROP TABLE PDT;

------------------------------------------
-- 2.3 메모리 테이블스페이스 검사
------------------------------------------
-- should be fail
CREATE TABLE PDT
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
) TABLESPACE SYS_TBS_MEM_DATA;
DROP TABLE PDT;

------------------------------------------
-- 2.4 파티션 이름 중복 검사
------------------------------------------
-- should be fail
CREATE TABLE PDT
(
    F1   INTEGER,
    F2   INTEGER
) 
PARTITION BY LIST( F1 )
(
    PARTITION P1 VALUES ( 10 ),
    PARTITION P2 VALUES ( 20 ),
    PARTITION P3 VALUES ( 10 ),
    PARTITION P1 VALUES DEFAULT
) TABLESPACE PDT_TBS;
DROP TABLE PDT;

--#########################################
--+SECTOR; DO JOB #3 (3. Execution Test)
--#########################################

------------------------------------------
-- 3.1 Unique key
------------------------------------------
CREATE TABLE PDT
(
    F1   INTEGER PRIMARY KEY,
    F2   INTEGER
) 
PARTITION BY LIST( F1 )
(
    PARTITION P1 VALUES ( 10 ),
    PARTITION P2 VALUES ( 20 ),
    PARTITION P3 VALUES ( 30 ),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS;

INSERT INTO PDT VALUES( 10, 0 );
-- should be fail
INSERT INTO PDT VALUES( 10, 1 );

INSERT INTO PDT VALUES( 20, 0 );
-- should be fail
INSERT INTO PDT VALUES( 20, 1 );

INSERT INTO PDT VALUES( 30, 0 );
-- should be fail
INSERT INTO PDT VALUES( 30, 1 );

INSERT INTO PDT VALUES( 40, 0 );
-- should be fail
INSERT INTO PDT VALUES( 40, 1 );

-- are u sure that COUNT(*) is 1
SELECT COUNT(*) FROM PDT PARTITION( P1 );
-- are u sure that COUNT(*) is 1
SELECT COUNT(*) FROM PDT PARTITION( P2 );
-- are u sure that COUNT(*) is 1
SELECT COUNT(*) FROM PDT PARTITION( P3 );
-- are u sure that COUNT(*) is 1
SELECT COUNT(*) FROM PDT PARTITION( P4 );

DROP TABLE PDT;

------------------------------------------
-- 3.2 Boundary Checking
------------------------------------------
CREATE TABLE PDT
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

INSERT INTO PDT VALUES( 10, 0 );
INSERT INTO PDT VALUES( 20, 0 );
INSERT INTO PDT VALUES( 30, 0 );
-- MAX
INSERT INTO PDT VALUES( 2147483647, 0 );

-- are u sure that COUNT(*) is 1
SELECT COUNT(*) FROM PDT PARTITION( P1 );
-- are u sure that COUNT(*) is 1
SELECT COUNT(*) FROM PDT PARTITION( P2 );
-- are u sure that COUNT(*) is 1
SELECT COUNT(*) FROM PDT PARTITION( P3 );
-- are u sure that COUNT(*) is 1
SELECT COUNT(*) FROM PDT PARTITION( P4 );

DROP TABLE PDT;


------------------------------------------
-- 3.3 NULL
------------------------------------------
CREATE TABLE PDT
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

INSERT INTO PDT VALUES( 10, 0 );
INSERT INTO PDT VALUES( 20, 0 );
INSERT INTO PDT VALUES( 30, 0 );
-- NULL
INSERT INTO PDT VALUES( NULL, 0 );

-- are u sure that COUNT(*) is 1
SELECT COUNT(*) FROM PDT PARTITION( P1 );
-- are u sure that COUNT(*) is 1
SELECT COUNT(*) FROM PDT PARTITION( P2 );
-- are u sure that COUNT(*) is 1
SELECT COUNT(*) FROM PDT PARTITION( P3 );
-- are u sure that COUNT(*) is 1
SELECT COUNT(*) FROM PDT PARTITION( P4 );

DROP TABLE PDT;

--###################################
--+SECTOR; FINALIZE
--###################################

--+SKIP BEGIN;
DROP TABLE PDT;
--+SKIP END;
