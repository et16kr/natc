--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/PDT/Design/ALTER_TABLE/TRUNCATE/list.sql
--#
--# Body below is byte-identical to the original. The one line this port
--# adds is the premise: the original measures these statements on the
--# $GIT_ hidden-table implementation, this file measures the same
--# statements on the native global index (F07 -- see include/pinNative.sql).
--###########################################################################
--+LOAD_SQL ../../../../include/pinNative.sql;

--######################################################
-- TRUNCATE PARTITIOIN
--######################################################

--###################################
--+SECTOR; INTIALIZE
--###################################

--+SKIP BEGIN;
DROP TABLE T1 CASCADE;
DROP TABLE PDT_LIST CASCADE;
--+SKIP END;

CREATE TABLE PDT_LIST
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


--#########################################
--+SECTOR; DO JOB #1 (1. Basic Test)
--#########################################

INSERT INTO PDT_LIST VALUES( 10, 0 );
INSERT INTO PDT_LIST VALUES( 20, 0 );
INSERT INTO PDT_LIST VALUES( 30, 0 );
INSERT INTO PDT_LIST VALUES( 40, 0 );

-- should be 4
SELECT COUNT(*) FROM PDT_LIST;

ALTER TABLE PDT_LIST
TRUNCATE PARTITION P1;

-- should be 3
SELECT COUNT(*) FROM PDT_LIST;

-- should be 0
SELECT COUNT(*) FROM PDT_LIST PARTITION( P1 );

--#########################################
--+SECTOR; DO JOB #2 (2. Validation Test)
--#########################################

----------------------------
-- 2.1 파티션 이름 검사
----------------------------
-- should be fail
ALTER TABLE PDT_LIST
TRUNCATE PARTITION P5;

----------------------------
-- 2.2 참조키 검사 
----------------------------
DROP TABLE PDT_LIST;
CREATE TABLE PDT_LIST
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
INSERT INTO PDT_LIST VALUES( 10, 0 );
INSERT INTO PDT_LIST VALUES( 20, 0 );
INSERT INTO PDT_LIST VALUES( 30, 0 );
INSERT INTO PDT_LIST VALUES( 40, 0 );

CREATE TABLE T1
(
    F1  INTEGER CONSTRAINT FK_CONST REFERENCES PDT_LIST( F1 ),
    F2  INTEGER
);

-- should be fail
ALTER TABLE PDT_LIST
TRUNCATE PARTITION P1;

--#########################################
--+SECTOR; DO JOB #3 (3. Execution Test)
--#########################################

DROP TABLE T1 CASCADE;
DROP TABLE PDT_LIST CASCADE;

CREATE TABLE PDT_LIST
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
INSERT INTO PDT_LIST VALUES( 10, 0 );
INSERT INTO PDT_LIST VALUES( 20, 0 );
INSERT INTO PDT_LIST VALUES( 30, 0 );
INSERT INTO PDT_LIST VALUES( 40, 0 );
INSERT INTO PDT_LIST VALUES( NULL, 0 );
INSERT INTO PDT_LIST VALUES( NULL, 0 );

-- should be 6
SELECT COUNT(*) FROM PDT_LIST;

-- should be 3
SELECT COUNT(*) FROM PDT_LIST PARTITION( P4 );

ALTER TABLE PDT_LIST
TRUNCATE PARTITION P4;

-- should be 3
SELECT COUNT(*) FROM PDT_LIST;

-- should be 0
SELECT COUNT(*) FROM PDT_LIST PARTITION( P4 );


--###################################
--+SECTOR; FINALIZE
--###################################

DROP TABLE PDT_LIST CASCADE;
