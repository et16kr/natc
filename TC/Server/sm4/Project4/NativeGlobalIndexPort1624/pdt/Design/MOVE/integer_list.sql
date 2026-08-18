--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/PDT/Design/MOVE/integer_list.sql
--#
--# Body below is byte-identical to the original. The one line this port
--# adds is the premise: the original measures these statements on the
--# $GIT_ hidden-table implementation, this file measures the same
--# statements on the native global index (F07 -- see include/pinNative.sql).
--###########################################################################
--+LOAD_SQL ../../../include/pinNative.sql;

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
