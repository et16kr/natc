--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/PDT/Design/DELETE/integer_hash.sql
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
-- INSERT HASH PARTITIOIN ( PK:INTEGER )
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

DELETE FROM PDT_HASH PARTITION( P1 );

-- should be [ ]
SELECT F1 FROM PDT_HASH PARTITION( P1 );
-- should be [1]
SELECT F1 FROM PDT_HASH PARTITION( P2 );
-- should be [2]
SELECT F1 FROM PDT_HASH PARTITION( P3 );
-- should be [3]
SELECT F1 FROM PDT_HASH PARTITION( P4 );


--#########################################
--+SECTOR; DO JOB #2 (2. Validation Test)
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

-- should be fail
DELETE FROM PDT_HASH PARTITION( P5 );


--#########################################
--+SECTOR; DO JOB #3 (3. Execution Test)
--#########################################

-------------------------------------
-- 3.1 Partition Pruning ( User )
-------------------------------------
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

-- please check plan
ALTER SESSION SET EXPLAIN PLAN = ON;
DELETE FROM PDT_HASH PARTITION( P1 );
DELETE FROM PDT_HASH PARTITION( P2 );
DELETE FROM PDT_HASH PARTITION( P3 );
DELETE FROM PDT_HASH PARTITION( P4 );
ALTER SESSION SET EXPLAIN PLAN = OFF;

-------------------------------------
-- 3.2 Partition filtering
-------------------------------------
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

-- less than 
ALTER SESSION SET EXPLAIN PLAN = ON;
DELETE FROM PDT_HASH WHERE F1 < 10;
DELETE FROM PDT_HASH WHERE F1 < 20;
DELETE FROM PDT_HASH WHERE F1 < 30;
DELETE FROM PDT_HASH WHERE F1 < 40;
ALTER SESSION SET EXPLAIN PLAN = OFF;

INSERT INTO PDT_HASH VALUES( 0, 0 );
INSERT INTO PDT_HASH VALUES( 1, 0 );
INSERT INTO PDT_HASH VALUES( 2, 0 );
INSERT INTO PDT_HASH VALUES( 3, 0 );

-- equal
ALTER SESSION SET EXPLAIN PLAN = ON;
DELETE FROM PDT_HASH WHERE F1 = 10;
DELETE FROM PDT_HASH WHERE F1 = 20;
DELETE FROM PDT_HASH WHERE F1 = 30;
DELETE FROM PDT_HASH WHERE F1 = 40;
ALTER SESSION SET EXPLAIN PLAN = OFF;

INSERT INTO PDT_HASH VALUES( 0, 0 );
INSERT INTO PDT_HASH VALUES( 1, 0 );
INSERT INTO PDT_HASH VALUES( 2, 0 );
INSERT INTO PDT_HASH VALUES( 3, 0 );

-- greater than
ALTER SESSION SET EXPLAIN PLAN = ON;
DELETE FROM PDT_HASH WHERE F1 > 10;
DELETE FROM PDT_HASH WHERE F1 > 20;
DELETE FROM PDT_HASH WHERE F1 > 30;
DELETE FROM PDT_HASH WHERE F1 > 40;
ALTER SESSION SET EXPLAIN PLAN = OFF;

INSERT INTO PDT_HASH VALUES( 0, 0 );
INSERT INTO PDT_HASH VALUES( 1, 0 );
INSERT INTO PDT_HASH VALUES( 2, 0 );
INSERT INTO PDT_HASH VALUES( 3, 0 );

-- less equal than
ALTER SESSION SET EXPLAIN PLAN = ON;
DELETE FROM PDT_HASH WHERE F1 <= 10;
DELETE FROM PDT_HASH WHERE F1 <= 20;
DELETE FROM PDT_HASH WHERE F1 <= 30;
DELETE FROM PDT_HASH WHERE F1 <= 40;
ALTER SESSION SET EXPLAIN PLAN = OFF;

INSERT INTO PDT_HASH VALUES( 0, 0 );
INSERT INTO PDT_HASH VALUES( 1, 0 );
INSERT INTO PDT_HASH VALUES( 2, 0 );
INSERT INTO PDT_HASH VALUES( 3, 0 );

-- greater equal than
ALTER SESSION SET EXPLAIN PLAN = ON;
DELETE FROM PDT_HASH WHERE F1 >= 10;
DELETE FROM PDT_HASH WHERE F1 >= 20;
DELETE FROM PDT_HASH WHERE F1 >= 30;
DELETE FROM PDT_HASH WHERE F1 >= 40;
ALTER SESSION SET EXPLAIN PLAN = OFF;

INSERT INTO PDT_HASH VALUES( 0, 0 );
INSERT INTO PDT_HASH VALUES( 1, 0 );
INSERT INTO PDT_HASH VALUES( 2, 0 );
INSERT INTO PDT_HASH VALUES( 3, 0 );

ALTER SESSION SET EXPLAIN PLAN = ON;
DELETE FROM PDT_HASH WHERE F1 >= 10 AND F1 < 20;
DELETE FROM PDT_HASH WHERE F1 >= 20 AND F1 < 30;
ALTER SESSION SET EXPLAIN PLAN = OFF;

INSERT INTO PDT_HASH VALUES( 0, 0 );
INSERT INTO PDT_HASH VALUES( 1, 0 );
INSERT INTO PDT_HASH VALUES( 2, 0 );
INSERT INTO PDT_HASH VALUES( 3, 0 );

-- not equal
ALTER SESSION SET EXPLAIN PLAN = ON;
DELETE FROM PDT_HASH;
DELETE FROM PDT_HASH WHERE F1 != 10;
DELETE FROM PDT_HASH WHERE F1 != 20;
DELETE FROM PDT_HASH WHERE F1 != 30;
DELETE FROM PDT_HASH WHERE F1 != 40;
ALTER SESSION SET EXPLAIN PLAN = OFF;

INSERT INTO PDT_HASH VALUES( 0, 0 );
INSERT INTO PDT_HASH VALUES( 1, 0 );
INSERT INTO PDT_HASH VALUES( 2, 0 );
INSERT INTO PDT_HASH VALUES( 3, 0 );

ALTER SESSION SET EXPLAIN PLAN = ON;
DELETE FROM PDT_HASH;
DELETE FROM PDT_HASH WHERE F2 = 0;
DELETE FROM PDT_HASH WHERE F1 = F1;
DELETE FROM PDT_HASH WHERE F1 = F2;
ALTER SESSION SET EXPLAIN PLAN = OFF;

-------------------------------------
-- 3.4 Foreign Key Check
-------------------------------------
--+SKIP BEGIN;
DROP TABLE T3 CASCADE;
DROP TABLE T2 CASCADE;
DROP TABLE T1 CASCADE;
--+SKIP END;

CREATE TABLE T1
(
    I1   INTEGER UNIQUE,
    I2   INTEGER
)
PARTITION BY HASH( I1 )
(
    PARTITION P1,
    PARTITION P2,
    PARTITION P3,
    PARTITION P4
) TABLESPACE PDT_TBS;

CREATE TABLE T2
(
    I1 INTEGER UNIQUE,
    I2 INTEGER
);

CREATE TABLE T3
(
    I1   INTEGER UNIQUE,
    I2   INTEGER
)
PARTITION BY HASH( I1 )
(
    PARTITION P1,
    PARTITION P2,
    PARTITION P3,
    PARTITION P4
) TABLESPACE PDT_TBS;

ALTER TABLE T2 ADD CONSTRAINT T2_FK FOREIGN KEY(I2) REFERENCES T1(I1);
ALTER TABLE T3 ADD CONSTRAINT T3_FK FOREIGN KEY(I2) REFERENCES T2(I1);

INSERT INTO T1 VALUES ( 0, 0 );
INSERT INTO T1 VALUES ( 1, 1 );
INSERT INTO T1 VALUES ( 2, 2 );
INSERT INTO T1 VALUES ( 3, 3 );

INSERT INTO T2 VALUES ( 0, 0 );
INSERT INTO T2 VALUES ( 1, 1 );
INSERT INTO T2 VALUES ( 2, 2 );
INSERT INTO T2 VALUES ( 3, 3 );

INSERT INTO T3 VALUES ( 0, 0 );
INSERT INTO T3 VALUES ( 1, 1 );
INSERT INTO T3 VALUES ( 2, 2 );
INSERT INTO T3 VALUES ( 3, 3 );

-- should be fail
DELETE FROM T1 WHERE I1 = 0;
DELETE FROM T1 WHERE I1 = 1;
DELETE FROM T1 WHERE I1 = 2;
DELETE FROM T1 WHERE I1 = 3;

ALTER TABLE T2 DROP CONSTRAINT T2_FK;
ALTER TABLE T3 DROP CONSTRAINT T3_FK;

TRUNCATE TABLE T1;
TRUNCATE TABLE T2;
TRUNCATE TABLE T3;

ALTER TABLE T2 ADD CONSTRAINT T2_FK FOREIGN KEY(I2) REFERENCES T1(I1) ON DELETE CASCADE;
ALTER TABLE T3 ADD CONSTRAINT T3_FK FOREIGN KEY(I2) REFERENCES T2(I1) ON DELETE CASCADE;

INSERT INTO T1 VALUES ( 0, 0 );
INSERT INTO T1 VALUES ( 1, 1 );
INSERT INTO T1 VALUES ( 2, 2 );
INSERT INTO T1 VALUES ( 3, 3 );

INSERT INTO T2 VALUES ( 0, 0 );
INSERT INTO T2 VALUES ( 1, 1 );
INSERT INTO T2 VALUES ( 2, 2 );
INSERT INTO T2 VALUES ( 3, 3 );

INSERT INTO T3 VALUES ( 0, 0 );
INSERT INTO T3 VALUES ( 1, 1 );
INSERT INTO T3 VALUES ( 2, 2 );
INSERT INTO T3 VALUES ( 3, 3 );

-- should be success
DELETE FROM T1 WHERE I1 = 0;
DELETE FROM T1 WHERE I1 = 1;
DELETE FROM T1 WHERE I1 = 2;
DELETE FROM T1 WHERE I1 = 3;

-- should be 0
SELECT COUNT(*) FROM T1;
-- should be 0
SELECT COUNT(*) FROM T2;
-- should be 0
SELECT COUNT(*) FROM T3;

--###################################
--+SECTOR; FINALIZE
--###################################

DROP TABLE PDT_HASH;
