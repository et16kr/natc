--######################################################
-- CREATE RANGE PARTITIONED DISK TABLE 
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

------------------------------------------
-- 1.1 단일 컬럼 파티션닝
------------------------------------------
CREATE TABLE PDT
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

INSERT INTO PDT VALUES( 5, 0 );

INSERT INTO PDT VALUES( 15, 0 );
INSERT INTO PDT VALUES( 15, 0 );

INSERT INTO PDT VALUES( 25, 0 );
INSERT INTO PDT VALUES( 25, 0 );
INSERT INTO PDT VALUES( 25, 0 );

INSERT INTO PDT VALUES( 35, 0 );
INSERT INTO PDT VALUES( 35, 0 );
INSERT INTO PDT VALUES( 35, 0 );
INSERT INTO PDT VALUES( 35, 0 );

-- are u sure that COUNT(*) is 1
SELECT COUNT(*) FROM PDT PARTITION( P1 );
-- are u sure that COUNT(*) is 2
SELECT COUNT(*) FROM PDT PARTITION( P2 );
-- are u sure that COUNT(*) is 3
SELECT COUNT(*) FROM PDT PARTITION( P3 );
-- are u sure that COUNT(*) is 4
SELECT COUNT(*) FROM PDT PARTITION( P4 );

------------------------------------------
-- 1.2 다중 컬럼 파티셔닝
------------------------------------------
DROP TABLE PDT;
CREATE TABLE PDT
(
    F1   INTEGER,
    F2   INTEGER
) 
PARTITION BY RANGE( F1, F2 )
(
    PARTITION P1 VALUES LESS THAN ( 10, 100 ),
    PARTITION P2 VALUES LESS THAN ( 20, 200 ),
    PARTITION P3 VALUES LESS THAN ( 30, 300 ),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS;

INSERT INTO PDT VALUES( 5, 50 );

INSERT INTO PDT VALUES( 15, 150 );
INSERT INTO PDT VALUES( 15, 150 );

INSERT INTO PDT VALUES( 25, 250 );
INSERT INTO PDT VALUES( 25, 250 );
INSERT INTO PDT VALUES( 25, 250 );

INSERT INTO PDT VALUES( 35, 350 );
INSERT INTO PDT VALUES( 35, 350 );
INSERT INTO PDT VALUES( 35, 350 );
INSERT INTO PDT VALUES( 35, 350 );

-- are u sure that COUNT(*) is 1
SELECT COUNT(*) FROM PDT PARTITION( P1 );
-- are u sure that COUNT(*) is 2
SELECT COUNT(*) FROM PDT PARTITION( P2 );
-- are u sure that COUNT(*) is 3
SELECT COUNT(*) FROM PDT PARTITION( P3 );
-- are u sure that COUNT(*) is 4
SELECT COUNT(*) FROM PDT PARTITION( P4 );


--#########################################
--+SECTOR; DO JOB #2 (2. Validation Test)
--#########################################

------------------------------------------
-- 2.1 파티션 키 컬럼 개수 체크
------------------------------------------
-- should be success
DROP TABLE PDT;
CREATE TABLE PDT
(
    F1   INTEGER,
    F2   INTEGER,
    F3   INTEGER,
    F4   INTEGER,
    F5   INTEGER,
    F6   INTEGER,
    F7   INTEGER,
    F8   INTEGER,
    F9   INTEGER,
    F10  INTEGER,
    F11  INTEGER,
    F12  INTEGER,
    F13  INTEGER,
    F14  INTEGER,
    F15  INTEGER,
    F16  INTEGER,
    F17  INTEGER,
    F18  INTEGER,
    F19  INTEGER,
    F20  INTEGER,
    F21  INTEGER,
    F22  INTEGER,
    F23  INTEGER,
    F24  INTEGER,
    F25  INTEGER,
    F26  INTEGER,
    F27  INTEGER,
    F28  INTEGER,
    F29  INTEGER,
    F30  INTEGER,
    F31  INTEGER,
    F32  INTEGER,
    F33  INTEGER
) 
PARTITION BY RANGE(  F1, F2, F3, F4, F5, F6, F7, F8, F9,F10,
                    F11,F12,F13,F14,F15,F16,F17,F18,F19,F20,
                    F21,F22,F23,F24,F25,F26,F27,F28,F29,F30,
                    F31,F32 )
(
    PARTITION P1 VALUES LESS THAN ( 1,2,3,4,5,6,7,8,9,0,
                                    1,2,3,4,5,6,7,8,9,0,
                                    1,2,3,4,5,6,7,8,9,0,
                                    1 ),
    PARTITION P2 VALUES LESS THAN ( 1,2,3,4,5,6,7,8,9,0,
                                    1,2,3,4,5,6,7,8,9,0,
                                    1,2,3,4,5,6,7,8,9,0,
                                    2 ),
    PARTITION P3 VALUES LESS THAN ( 1,2,3,4,5,6,7,8,9,0,
                                    1,2,3,4,5,6,7,8,9,0,
                                    1,2,3,4,5,6,7,8,9,0,
                                    3 ),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS;

-- should be fail
DROP TABLE PDT;
CREATE TABLE PDT
(
    F1   INTEGER,
    F2   INTEGER,
    F3   INTEGER,
    F4   INTEGER,
    F5   INTEGER,
    F6   INTEGER,
    F7   INTEGER,
    F8   INTEGER,
    F9   INTEGER,
    F10  INTEGER,
    F11  INTEGER,
    F12  INTEGER,
    F13  INTEGER,
    F14  INTEGER,
    F15  INTEGER,
    F16  INTEGER,
    F17  INTEGER,
    F18  INTEGER,
    F19  INTEGER,
    F20  INTEGER,
    F21  INTEGER,
    F22  INTEGER,
    F23  INTEGER,
    F24  INTEGER,
    F25  INTEGER,
    F26  INTEGER,
    F27  INTEGER,
    F28  INTEGER,
    F29  INTEGER,
    F30  INTEGER,
    F31  INTEGER,
    F32  INTEGER,
    F33  INTEGER
) 
PARTITION BY RANGE(  F1, F2, F3, F4, F5, F6, F7, F8, F9,F10,
                    F11,F12,F13,F14,F15,F16,F17,F18,F19,F20,
                    F21,F22,F23,F24,F25,F26,F27,F28,F29,F30,
                    F31,F32,F33)
(
    PARTITION P1 VALUES LESS THAN ( 1,2,3,4,5,6,7,8,9,0,
                                    1,2,3,4,5,6,7,8,9,0,
                                    1,2,3,4,5,6,7,8,9,0,
                                    1,1 ),
    PARTITION P2 VALUES LESS THAN ( 1,2,3,4,5,6,7,8,9,0,
                                    1,2,3,4,5,6,7,8,9,0,
                                    1,2,3,4,5,6,7,8,9,0,
                                    1,2 ),
    PARTITION P3 VALUES LESS THAN ( 1,2,3,4,5,6,7,8,9,0,
                                    1,2,3,4,5,6,7,8,9,0,
                                    1,2,3,4,5,6,7,8,9,0,
                                    1,3 ),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS;

------------------------------------------
-- 2.2 키값의 개수 체크 
------------------------------------------
-- should be success
DROP TABLE PDT;
CREATE TABLE PDT
(
    F1   INTEGER,
    F2   INTEGER
) 
PARTITION BY RANGE( F1, F2 )
(
    PARTITION P1 VALUES LESS THAN ( 1,2 ),
    PARTITION P2 VALUES LESS THAN ( 2 ), 
    PARTITION P3 VALUES LESS THAN ( 3,1 ), 
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS;

-- should be fail
DROP TABLE PDT;
CREATE TABLE PDT
(
    F1   INTEGER,
    F2   INTEGER
) 
PARTITION BY RANGE( F1, F2 )
(
    PARTITION P1 VALUES LESS THAN ( 1,1,1 ),
    PARTITION P2 VALUES LESS THAN ( 1,2,1 ), 
    PARTITION P3 VALUES LESS THAN ( 1,3,1 ), 
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS;

------------------------------------------
-- 2.3 중복 파티션 조건값 체크 
------------------------------------------
-- should be fail
DROP TABLE PDT;
CREATE TABLE PDT
(
    F1   INTEGER,
    F2   INTEGER
) 
PARTITION BY RANGE( F1, F2 )
(
    PARTITION P1 VALUES LESS THAN ( 1,2 ),
    PARTITION P2 VALUES LESS THAN ( 2 ), 
    PARTITION P3 VALUES LESS THAN ( 1,2 ), 
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS;

------------------------------------------
-- 2.4 MAX 파티션 조건값 검사 
------------------------------------------
-- should be success
DROP TABLE PDT;
CREATE TABLE PDT
(
    F1   INTEGER,
    F2   INTEGER
) 
PARTITION BY RANGE( F1 )
(
    PARTITION P1 VALUES LESS THAN ( 1 ),
    PARTITION P2 VALUES LESS THAN ( 2 ), 
    PARTITION P3 VALUES LESS THAN ( 2147483647 ), 
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS;

INSERT INTO PDT VALUES( 2147483647, 0 );
-- should be fail
INSERT INTO PDT VALUES( 2147483648, 0 );

-- are u sure that COUNT(*) is 0
SELECT COUNT(*) FROM PDT PARTITION( P3 );
-- are u sure that COUNT(*) is 1
SELECT COUNT(*) FROM PDT PARTITION( P4 );

------------------------------------------
-- 2.5 메모리 테이블스페이스 검사
------------------------------------------
-- should be fail
DROP TABLE PDT;
CREATE TABLE PDT
(
    F1   INTEGER,
    F2   INTEGER
) 
PARTITION BY RANGE( F1 )
(
    PARTITION P1 VALUES LESS THAN ( 1 ),
    PARTITION P2 VALUES LESS THAN ( 2 ), 
    PARTITION P3 VALUES LESS THAN ( 3 ), 
    PARTITION P4 VALUES DEFAULT
) TABLESPACE SYS_TBS_MEM_DATA;

------------------------------------------
-- 2.6 파티션 키 컬럼 중복 검사
------------------------------------------
-- should be fail
DROP TABLE PDT;
CREATE TABLE PDT
(
    F1   INTEGER,
    F2   INTEGER
) 
PARTITION BY RANGE( F1, F1 )
(
    PARTITION P1 VALUES LESS THAN ( 1 ),
    PARTITION P2 VALUES LESS THAN ( 2 ), 
    PARTITION P3 VALUES LESS THAN ( 3 ), 
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS;

------------------------------------------
-- 2.7 파티션 이름 중복 검사
------------------------------------------
-- should be fail
DROP TABLE PDT;
CREATE TABLE PDT
(
    F1   INTEGER,
    F2   INTEGER
) 
PARTITION BY RANGE( F1 )
(
    PARTITION P1 VALUES LESS THAN ( 1 ),
    PARTITION P2 VALUES LESS THAN ( 2 ), 
    PARTITION P3 VALUES LESS THAN ( 3 ), 
    PARTITION P1 VALUES DEFAULT
) TABLESPACE PDT_TBS;

--#########################################
--+SECTOR; DO JOB #3 (3. Execution Test)
--#########################################

------------------------------------------
-- 3.1 Unique key
------------------------------------------
-- 단일 컬럼 파티셔닝
DROP TABLE PDT;
CREATE TABLE PDT
(
    F1   INTEGER PRIMARY KEY,
    F2   INTEGER
) 
PARTITION BY RANGE( F1 )
(
    PARTITION P1 VALUES LESS THAN ( 10 ),
    PARTITION P2 VALUES LESS THAN ( 20 ),
    PARTITION P3 VALUES LESS THAN ( 30 ),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS;

INSERT INTO PDT VALUES( 5, 50 );
-- should be fail
INSERT INTO PDT VALUES( 5, 50 );

INSERT INTO PDT VALUES( 15, 150 );
INSERT INTO PDT VALUES( 16, 150 );
-- should be fail
INSERT INTO PDT VALUES( 16, 150 );

INSERT INTO PDT VALUES( 25, 250 );
INSERT INTO PDT VALUES( 26, 250 );
INSERT INTO PDT VALUES( 27, 250 );
-- should be fail
INSERT INTO PDT VALUES( 27, 250 );

-- are u sure that COUNT(*) is 1
SELECT COUNT(*) FROM PDT PARTITION( P1 );
-- are u sure that COUNT(*) is 2
SELECT COUNT(*) FROM PDT PARTITION( P2 );
-- are u sure that COUNT(*) is 3
SELECT COUNT(*) FROM PDT PARTITION( P3 );
-- are u sure that COUNT(*) is 0
SELECT COUNT(*) FROM PDT PARTITION( P4 );

-- 다중 컬럼 파티셔닝
DROP TABLE PDT;
CREATE TABLE PDT
(
    F1   INTEGER,
    F2   INTEGER,
    PRIMARY KEY(F1, F2)
) 
PARTITION BY RANGE( F1, F2 )
(
    PARTITION P1 VALUES LESS THAN ( 10, 100 ),
    PARTITION P2 VALUES LESS THAN ( 20, 200 ),
    PARTITION P3 VALUES LESS THAN ( 30, 300 ),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS;

INSERT INTO PDT VALUES( 5, 50 );
INSERT INTO PDT VALUES( 5, 51 );
-- should be fail
INSERT INTO PDT VALUES( 5, 50 );

INSERT INTO PDT VALUES( 15, 150 );
INSERT INTO PDT VALUES( 15, 151 );
INSERT INTO PDT VALUES( 15, 152 );
-- should be fail
INSERT INTO PDT VALUES( 15, 151 );

INSERT INTO PDT VALUES( 25, 250 );
INSERT INTO PDT VALUES( 25, 251 );
INSERT INTO PDT VALUES( 25, 252 );
INSERT INTO PDT VALUES( 25, 253 );
-- should be fail
INSERT INTO PDT VALUES( 25, 252 );

-- are u sure that COUNT(*) is 2
SELECT COUNT(*) FROM PDT PARTITION( P1 );
-- are u sure that COUNT(*) is 3
SELECT COUNT(*) FROM PDT PARTITION( P2 );
-- are u sure that COUNT(*) is 4
SELECT COUNT(*) FROM PDT PARTITION( P3 );
-- are u sure that COUNT(*) is 0
SELECT COUNT(*) FROM PDT PARTITION( P4 );

------------------------------------------
-- 3.2 Boundary Checking
------------------------------------------
-- 단일 컬럼 파티셔닝
DROP TABLE PDT;
CREATE TABLE PDT
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

INSERT INTO PDT VALUES( 10, 0 );
INSERT INTO PDT VALUES( 20, 0 );
INSERT INTO PDT VALUES( 30, 0 );
-- MAX
INSERT INTO PDT VALUES( 2147483647, 0 );

-- are u sure that COUNT(*) is 0
SELECT COUNT(*) FROM PDT PARTITION( P1 );
-- are u sure that COUNT(*) is 1
SELECT COUNT(*) FROM PDT PARTITION( P2 );
-- are u sure that COUNT(*) is 1
SELECT COUNT(*) FROM PDT PARTITION( P3 );
-- are u sure that COUNT(*) is 2
SELECT COUNT(*) FROM PDT PARTITION( P4 );


-- 다중 컬럼 파티셔닝
DROP TABLE PDT;
CREATE TABLE PDT
(
    F1   INTEGER,
    F2   INTEGER
) 
PARTITION BY RANGE( F1, F2 )
(
    PARTITION P1 VALUES LESS THAN ( 10, 100 ),
    PARTITION P2 VALUES LESS THAN ( 20, 200 ),
    PARTITION P3 VALUES LESS THAN ( 30, 300 ),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS;

INSERT INTO PDT VALUES( 10, 100 );
INSERT INTO PDT VALUES( 20, 200 );
INSERT INTO PDT VALUES( 30, 300 );
-- MAX
INSERT INTO PDT VALUES( 2147483647, 2147483647 );

-- are u sure that COUNT(*) is 0
SELECT COUNT(*) FROM PDT PARTITION( P1 );
-- are u sure that COUNT(*) is 1
SELECT COUNT(*) FROM PDT PARTITION( P2 );
-- are u sure that COUNT(*) is 1
SELECT COUNT(*) FROM PDT PARTITION( P3 );
-- are u sure that COUNT(*) is 2
SELECT COUNT(*) FROM PDT PARTITION( P4 );


------------------------------------------
-- 3.3 NULL
------------------------------------------
-- 단일 컬럼 파티셔닝
DROP TABLE PDT;
CREATE TABLE PDT
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

INSERT INTO PDT VALUES( 10, 0 );
INSERT INTO PDT VALUES( 20, 0 );
INSERT INTO PDT VALUES( 30, 0 );
INSERT INTO PDT VALUES( NULL, 0 );

-- are u sure that COUNT(*) is 0
SELECT COUNT(*) FROM PDT PARTITION( P1 );
-- are u sure that COUNT(*) is 1
SELECT COUNT(*) FROM PDT PARTITION( P2 );
-- are u sure that COUNT(*) is 1
SELECT COUNT(*) FROM PDT PARTITION( P3 );
-- are u sure that COUNT(*) is 2
SELECT COUNT(*) FROM PDT PARTITION( P4 );


-- 다중 컬럼 파티셔닝
DROP TABLE PDT;
CREATE TABLE PDT
(
    F1   INTEGER,
    F2   INTEGER
) 
PARTITION BY RANGE( F1, F2 )
(
    PARTITION P1 VALUES LESS THAN ( 10, 100 ),
    PARTITION P2 VALUES LESS THAN ( 20, 200 ),
    PARTITION P3 VALUES LESS THAN ( 30, 300 ),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS;

INSERT INTO PDT VALUES( 10, 100 );
INSERT INTO PDT VALUES( 20, 200 );
INSERT INTO PDT VALUES( 30, 300 );
INSERT INTO PDT VALUES( NULL, 0 );
INSERT INTO PDT VALUES( 0, NULL );
INSERT INTO PDT VALUES( NULL, NULL );

-- are u sure that COUNT(*) is 1
SELECT COUNT(*) FROM PDT PARTITION( P1 );
-- are u sure that COUNT(*) is 1
SELECT COUNT(*) FROM PDT PARTITION( P2 );
-- are u sure that COUNT(*) is 1
SELECT COUNT(*) FROM PDT PARTITION( P3 );
-- are u sure that COUNT(*) is 3
SELECT COUNT(*) FROM PDT PARTITION( P4 );


--###################################
--+SECTOR; FINALIZE
--###################################

--+SKIP BEGIN;
DROP TABLE PDT;
--+SKIP END;
