--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/PDT/Design/MOVE/integer_list.sql
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
-- MOVE LIST PARTITIOIN ( PK:INTEGER )
--######################################################

--###################################
--+SECTOR; INTIALIZE
--###################################

--+SKIP BEGIN;
DROP TABLE PDT_LIST;
DROP TABLE PDT_LIST_SRC;
--+SKIP END;

CREATE TABLE PDT_LIST_SRC
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

INSERT INTO PDT_LIST_SRC VALUES( 10, 0 );
INSERT INTO PDT_LIST_SRC VALUES( 20, 0 );
INSERT INTO PDT_LIST_SRC VALUES( 30, 0 );
INSERT INTO PDT_LIST_SRC VALUES( 40, 0 );


--#########################################
--+SECTOR; DO JOB #1 (1. Basic Test)
--#########################################

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

MOVE INTO PDT_LIST PARTITION( P1 ) FROM PDT_LIST_SRC PARTITION( P1 );
MOVE INTO PDT_LIST PARTITION( P2 ) FROM PDT_LIST_SRC PARTITION( P2 );
MOVE INTO PDT_LIST PARTITION( P3 ) FROM PDT_LIST_SRC PARTITION( P3 );
MOVE INTO PDT_LIST PARTITION( P4 ) FROM PDT_LIST_SRC PARTITION( P4 );

-- should be [10]
SELECT F1 FROM PDT_LIST PARTITION( P1 );
-- should be [20]
SELECT F1 FROM PDT_LIST PARTITION( P2 );
-- should be [30]
SELECT F1 FROM PDT_LIST PARTITION( P3 );
-- should be [40]
SELECT F1 FROM PDT_LIST PARTITION( P4 );

MOVE INTO PDT_LIST FROM PDT_LIST_SRC PARTITION( P1 );
MOVE INTO PDT_LIST FROM PDT_LIST_SRC PARTITION( P2 );
MOVE INTO PDT_LIST FROM PDT_LIST_SRC PARTITION( P3 );
MOVE INTO PDT_LIST FROM PDT_LIST_SRC PARTITION( P4 );

-- should be [10,10]
SELECT F1 FROM PDT_LIST PARTITION( P1 );
-- should be [20,20]
SELECT F1 FROM PDT_LIST PARTITION( P2 );
-- should be [30,30]
SELECT F1 FROM PDT_LIST PARTITION( P3 );
-- should be [40,40]
SELECT F1 FROM PDT_LIST PARTITION( P4 );


--#########################################
--+SECTOR; DO JOB #2 (2. Validation Test)
--#########################################

INSERT INTO PDT_LIST_SRC VALUES( 10, 0 );
INSERT INTO PDT_LIST_SRC VALUES( 20, 0 );
INSERT INTO PDT_LIST_SRC VALUES( 30, 0 );
INSERT INTO PDT_LIST_SRC VALUES( 40, 0 );

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
MOVE INTO PDT_LIST PARTITION( P1 ) FROM PDT_LIST_SRC;

-- should be fail
MOVE INTO PDT_LIST PARTITION( P1 ) FROM PDT_LIST_SRC PARTITION( P2 );
-- should be fail
MOVE INTO PDT_LIST PARTITION( P2 ) FROM PDT_LIST_SRC PARTITION( P3 );
-- should be fail
MOVE INTO PDT_LIST PARTITION( P3 ) FROM PDT_LIST_SRC PARTITION( P4 );
-- should be fail
MOVE INTO PDT_LIST PARTITION( P4 ) FROM PDT_LIST_SRC PARTITION( P1 );

-- should be 0
SELECT COUNT(*) FROM PDT_LIST PARTITION( P1 );
-- should be 0
SELECT COUNT(*) FROM PDT_LIST PARTITION( P2 );
-- should be 0
SELECT COUNT(*) FROM PDT_LIST PARTITION( P3 );
-- should be 0
SELECT COUNT(*) FROM PDT_LIST PARTITION( P4 );
-- should be 0
SELECT COUNT(*) FROM PDT_LIST;

-- should be fail
MOVE INTO PDT_LIST PARTITION( P1 ) FROM PDT_LIST_SRC WHERE F1 = 20;
-- should be fail
MOVE INTO PDT_LIST PARTITION( P2 ) FROM PDT_LIST_SRC WHERE F1 = 30;
-- should be fail
MOVE INTO PDT_LIST PARTITION( P3 ) FROM PDT_LIST_SRC WHERE F1 = 40;
-- should be fail
MOVE INTO PDT_LIST PARTITION( P4 ) FROM PDT_LIST_SRC WHERE F1 = 10;

-- should be 0
SELECT COUNT(*) FROM PDT_LIST PARTITION( P1 );
-- should be 0
SELECT COUNT(*) FROM PDT_LIST PARTITION( P2 );
-- should be 0
SELECT COUNT(*) FROM PDT_LIST PARTITION( P3 );
-- should be 0
SELECT COUNT(*) FROM PDT_LIST PARTITION( P4 );
-- should be 0
SELECT COUNT(*) FROM PDT_LIST;


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
    PARTITION P1 VALUES ( 10, 15 ),
    PARTITION P2 VALUES ( 20, 25 ),
    PARTITION P3 VALUES ( 30, 35 ),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS;

-- should be success
MOVE INTO PDT_LIST PARTITION( P1 ) FROM PDT_LIST_SRC WHERE F1 = 10;
-- should be success
MOVE INTO PDT_LIST PARTITION( P2 ) FROM PDT_LIST_SRC WHERE F1 = 20;
-- should be success
MOVE INTO PDT_LIST PARTITION( P3 ) FROM PDT_LIST_SRC WHERE F1 = 30;
-- should be success
MOVE INTO PDT_LIST PARTITION( P4 ) FROM PDT_LIST_SRC WHERE F1 = 40;

-- should be 1
SELECT COUNT(*) FROM PDT_LIST PARTITION( P1 );
-- should be 1
SELECT COUNT(*) FROM PDT_LIST PARTITION( P2 );
-- should be 1
SELECT COUNT(*) FROM PDT_LIST PARTITION( P3 );
-- should be 1
SELECT COUNT(*) FROM PDT_LIST PARTITION( P4 );


--###################################
--+SECTOR; FINALIZE
--###################################

DROP TABLE PDT_LIST;
DROP TABLE PDT_LIST_SRC;
