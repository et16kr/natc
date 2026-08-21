--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/PDT/Design/ALTER_TABLE/ADD/integer_hash.sql
--#
--# Body below is byte-identical to the original. The one line this port
--# adds is the premise: the original measures these statements on the
--# $GIT_ hidden-table implementation, this file measures the same
--# statements on the native global index (F07 -- see include/pinNative.sql).
--###########################################################################
--###########################################################################
--# NativeGlobalIndexPort1624 - the premise of every ported .sql case.
--#
--# A .sql case cannot CALL a DEF the way a .tc case calls PIN_DISK_NATIVE(),
--# so the same two statements are pulled in per case with ATC's own include
--# directive:
--#
--#     --+LOAD_SQL <relative path>/include/pinNative.sql;
--#
--# ATC inlines this file into the case transcript between BEGIN/END markers,
--# which is exactly what F07 asks for: the case states its own premise at the
--# head of its own transcript instead of inheriting whatever the instance
--# happens to be configured with.
--#
--#     DISK_GLOBAL_INDEX_ENABLE = 1  -> native  (this suite)
--#     DISK_GLOBAL_INDEX_ENABLE = 0  -> $GIT_   (the original suite)
--#
--# The readout below is not decoration. It is the tooth: if the property is
--# ever 0 when a case runs, this one line differs and the case is red before
--# it has measured anything, instead of quietly measuring the other
--# implementation (disk-natc.md 6 records nine assertions that drifted that
--# way).
--#
--# ASCII only, on purpose: 87 of the ported case bodies are EUC-KR and their
--# bytes must stay untouched, so nothing this port adds may introduce a
--# second encoding into a transcript.
--###########################################################################

ALTER SYSTEM SET DISK_GLOBAL_INDEX_ENABLE = 1;

SELECT CAST(VALUE1 AS VARCHAR(10)) DISK_GLOBAL_INDEX_ENABLE
FROM V$PROPERTY WHERE NAME = 'DISK_GLOBAL_INDEX_ENABLE';

--######################################################
-- ADD PARTITIOIN ( PK:INTEGER )
--######################################################

--###################################
--+SECTOR; INTIALIZE
--###################################

--+SKIP BEGIN;
DROP TABLE PDT_HASH;
--+SKIP END;

--#########################################
--+SECTOR; DO JOB #1 (1. Basic Test)
--#########################################

------------------------------------------
-- 1.1 ADD PARTITION WITH 4 PARTITON
--     VS. PARTITIONED TABLE WITH 5 PARTITON
------------------------------------------
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
INSERT INTO PDT_HASH VALUES( 5, 0 );
INSERT INTO PDT_HASH VALUES( 6, 0 );
INSERT INTO PDT_HASH VALUES( 7, 0 );
INSERT INTO PDT_HASH VALUES( 8, 0 );
INSERT INTO PDT_HASH VALUES( 9, 0 );

SELECT F1 FROM PDT_HASH PARTITION( P1 );
SELECT F1 FROM PDT_HASH PARTITION( P2 );
SELECT F1 FROM PDT_HASH PARTITION( P3 );
SELECT F1 FROM PDT_HASH PARTITION( P4 );

-- should be 10
SELECT COUNT(*) FROM PDT_HASH;

ALTER TABLE PDT_HASH
ADD PARTITION P5;

SELECT F1 FROM PDT_HASH PARTITION( P1 );
SELECT F1 FROM PDT_HASH PARTITION( P2 );
SELECT F1 FROM PDT_HASH PARTITION( P3 );
SELECT F1 FROM PDT_HASH PARTITION( P4 );
SELECT F1 FROM PDT_HASH PARTITION( P5 );

-- should be 10
SELECT COUNT(*) FROM PDT_HASH;

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
    PARTITION P4,
    PARTITION P5
) TABLESPACE PDT_TBS;

INSERT INTO PDT_HASH VALUES( 0, 0 );
INSERT INTO PDT_HASH VALUES( 1, 0 );
INSERT INTO PDT_HASH VALUES( 2, 0 );
INSERT INTO PDT_HASH VALUES( 3, 0 );
INSERT INTO PDT_HASH VALUES( 4, 0 );
INSERT INTO PDT_HASH VALUES( 5, 0 );
INSERT INTO PDT_HASH VALUES( 6, 0 );
INSERT INTO PDT_HASH VALUES( 7, 0 );
INSERT INTO PDT_HASH VALUES( 8, 0 );
INSERT INTO PDT_HASH VALUES( 9, 0 );

SELECT F1 FROM PDT_HASH PARTITION( P1 );
SELECT F1 FROM PDT_HASH PARTITION( P2 );
SELECT F1 FROM PDT_HASH PARTITION( P3 );
SELECT F1 FROM PDT_HASH PARTITION( P4 );
SELECT F1 FROM PDT_HASH PARTITION( P5 );

-- should be 10
SELECT COUNT(*) FROM PDT_HASH;

------------------------------------------
-- 1.2 ADD PARTITION WITH 4 PARTITON(INDEX)
--     VS. PARTITIONED TABLE WITH 5 PARTITON
------------------------------------------
DROP TABLE PDT_HASH;

CREATE TABLE PDT_HASH
(
    F1   INTEGER PRIMARY KEY,
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
INSERT INTO PDT_HASH VALUES( 5, 0 );
INSERT INTO PDT_HASH VALUES( 6, 0 );
INSERT INTO PDT_HASH VALUES( 7, 0 );
INSERT INTO PDT_HASH VALUES( 8, 0 );
INSERT INTO PDT_HASH VALUES( 9, 0 );

SELECT F1 FROM PDT_HASH PARTITION( P1 ) WHERE F1 < 10;
SELECT F1 FROM PDT_HASH PARTITION( P2 ) WHERE F1 < 10;
SELECT F1 FROM PDT_HASH PARTITION( P3 ) WHERE F1 < 10;
SELECT F1 FROM PDT_HASH PARTITION( P4 ) WHERE F1 < 10;

-- should be 10
SELECT COUNT(*) FROM PDT_HASH;

ALTER TABLE PDT_HASH
ADD PARTITION P5;

SELECT F1 FROM PDT_HASH PARTITION( P1 ) WHERE F1 < 10;
SELECT F1 FROM PDT_HASH PARTITION( P2 ) WHERE F1 < 10;
SELECT F1 FROM PDT_HASH PARTITION( P3 ) WHERE F1 < 10;
SELECT F1 FROM PDT_HASH PARTITION( P4 ) WHERE F1 < 10;
SELECT F1 FROM PDT_HASH PARTITION( P5 ) WHERE F1 < 10;

-- should be 10
SELECT COUNT(*) FROM PDT_HASH;


DROP TABLE PDT_HASH;

CREATE TABLE PDT_HASH
(
    F1   INTEGER PRIMARY KEY,
    F2   INTEGER
) 
PARTITION BY HASH( F1 )
(
    PARTITION P1,
    PARTITION P2,
    PARTITION P3,
    PARTITION P4,
    PARTITION P5
) TABLESPACE PDT_TBS;

INSERT INTO PDT_HASH VALUES( 0, 0 );
INSERT INTO PDT_HASH VALUES( 1, 0 );
INSERT INTO PDT_HASH VALUES( 2, 0 );
INSERT INTO PDT_HASH VALUES( 3, 0 );
INSERT INTO PDT_HASH VALUES( 4, 0 );
INSERT INTO PDT_HASH VALUES( 5, 0 );
INSERT INTO PDT_HASH VALUES( 6, 0 );
INSERT INTO PDT_HASH VALUES( 7, 0 );
INSERT INTO PDT_HASH VALUES( 8, 0 );
INSERT INTO PDT_HASH VALUES( 9, 0 );

SELECT F1 FROM PDT_HASH PARTITION( P1 ) WHERE F1 < 10;
SELECT F1 FROM PDT_HASH PARTITION( P2 ) WHERE F1 < 10;
SELECT F1 FROM PDT_HASH PARTITION( P3 ) WHERE F1 < 10;
SELECT F1 FROM PDT_HASH PARTITION( P4 ) WHERE F1 < 10;
SELECT F1 FROM PDT_HASH PARTITION( P5 ) WHERE F1 < 10;

-- should be 10
SELECT COUNT(*) FROM PDT_HASH;

--#########################################
--+SECTOR; DO JOB #2 (2. Validation Test)
--#########################################

------------------------------------------
-- 2.1 파티션 이름 중복 검사
------------------------------------------
-- should be fail
ALTER TABLE PDT_HASH
ADD PARTITION P1;

------------------------------------------
-- 2.2 메모리 테이블스페이스 검사
------------------------------------------
-- should be fail
ALTER TABLE PDT_HASH
ADD PARTITION P6 
TABLESPACE SYS_TBS_MEM_DATA;


--#########################################
--+SECTOR; DO JOB #3 (3. Execution Test)
--#########################################

-- nothing to do


--###################################
--+SECTOR; FINALIZE
--###################################

DROP TABLE PDT_HASH;
