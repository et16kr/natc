--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/PDT/Design/ALTER_TABLE/DROP_COLUMN/basic.sql
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

--###################################################################
--# ALTER TABLE ... DROP COLUMN
--###################################################################

--###################################################################
--+SECTOR; PREPARATION
--###################################################################

--+SKIP BEGIN;
DROP TABLE T1;
--+SKIP END;

CREATE TABLE T1
( I1 INTEGER, I2 CLOB DEFAULT 'DEFAULT', I3 INTEGER,  I4 BLOB, I5 INTEGER )
PARTITION BY RANGE (I1, I3, I5)
(
    PARTITION P1 VALUES LESS THAN (2),
    PARTITION P2 VALUES LESS THAN (3),
    PARTITION P3 VALUES LESS THAN (4),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE SYS_TBS_DISK_DATA;

CREATE INDEX IDX1 ON T1(I1, I3);

CREATE INDEX IDX2 ON T1(I3);

CREATE INDEX IDX3 ON T1(I1) LOCAL
(
    PARTITION IDX1_P3 ON P3,
    PARTITION IDX1_P4 ON P4
);

INSERT INTO T1 VALUES ( 1, 'CLOB1', 1, 'FF', 1 );
INSERT INTO T1 VALUES ( 2, 'CLOB2', 2, 'FFFF', 2 );
INSERT INTO T1 VALUES ( 3, 'CLOB3', 3, 'FFFFFF', 3 );
INSERT INTO T1 VALUES ( 4, 'CLOB4', 4, 'FFFFFFFF', 4 );
INSERT INTO T1 VALUES ( 5, 'CLOB5', 5, 'FFFFFFFFFF', 5 );

-- should be 5
SELECT COUNT(*) FROM T1;


-- should be 12
SELECT COUNT(*)
FROM SYSTEM_.SYS_PART_KEY_COLUMNS_ PARTKEY,
     SYSTEM_.SYS_TABLE_PARTITIONS_ PART,
     SYSTEM_.SYS_TABLES_ TAB
WHERE PART.TABLE_ID = TAB.TABLE_ID AND
      TAB.TABLE_NAME='T1';

-- should be 8
SELECT COUNT(*)
FROM SYSTEM_.SYS_PART_LOBS_ LOBS,
     SYSTEM_.SYS_TABLES_ TAB
WHERE LOBS.TABLE_ID = TAB.TABLE_ID AND
      TAB.TABLE_NAME='T1';


--#########################################################################
--+ SECTOR; VALIDATION
--#########################################################################
---------------------------------------------------
-- DROP PARTITIONING KEY
---------------------------------------------------
-- should be fail
ALTER TABLE T1 DROP COLUMN I1;

-- should be fail
ALTER TABLE T1 DROP COLUMN I3;

-- should be fail
ALTER TABLE T1 DROP COLUMN I5;



--#########################################################################
--+ SECTOR; EXECUTION
--#########################################################################
ALTER TABLE T1 DROP COLUMN I2;

INSERT INTO T1 VALUES ( 1, 1, 'FF', 1 );
INSERT INTO T1 VALUES ( 2, 2, 'FFFF', 2 );
INSERT INTO T1 VALUES ( 3, 3, 'FFFFFF', 3 );
INSERT INTO T1 VALUES ( 4, 4, 'FFFFFFFF', 4 );
INSERT INTO T1 VALUES ( 5, 5, 'FFFFFFFFFF', 5 );

-- should be 10
SELECT COUNT(*) FROM T1;

---------------------------------------------------
-- SYS_PART_KEY_COLUMNS_
---------------------------------------------------
-- should be 12
SELECT COUNT(*)
FROM SYSTEM_.SYS_TABLES_ TAB,
     SYSTEM_.SYS_TABLE_PARTITIONS_ PART,
     SYSTEM_.SYS_PART_KEY_COLUMNS_ PARTKEY
WHERE TAB.TABLE_NAME='T1' AND
      TAB.TABLE_ID = PART.TABLE_ID AND
      PART.TABLE_ID = PARTKEY.PARTITION_OBJ_ID;

---------------------------------------------------
-- SYS_PART_LOBS_
---------------------------------------------------
-- should be 4
SELECT COUNT(*)
FROM SYSTEM_.SYS_PART_LOBS_ LOBS,
     SYSTEM_.SYS_TABLES_ TAB
WHERE LOBS.TABLE_ID = TAB.TABLE_ID AND
      TAB.TABLE_NAME='T1';


ALTER TABLE T1 DROP COLUMN I4;

INSERT INTO T1 VALUES ( 1, 1, 1 );
INSERT INTO T1 VALUES ( 2, 2, 2 );
INSERT INTO T1 VALUES ( 3, 3, 3 );
INSERT INTO T1 VALUES ( 4, 4, 4 );
INSERT INTO T1 VALUES ( 5, 5, 5 );

-- should be 15
SELECT COUNT(*) FROM T1;

---------------------------------------------------
-- SYS_PART_KEY_COLUMNS_
---------------------------------------------------
-- should be 12
SELECT COUNT(*)
FROM SYSTEM_.SYS_TABLES_ TAB,
     SYSTEM_.SYS_TABLE_PARTITIONS_ PART,
     SYSTEM_.SYS_PART_KEY_COLUMNS_ PARTKEY
WHERE TAB.TABLE_NAME='T1' AND
      TAB.TABLE_ID = PART.TABLE_ID AND
      PART.TABLE_ID = PARTKEY.PARTITION_OBJ_ID;

---------------------------------------------------
-- SYS_PART_LOBS_
---------------------------------------------------
-- should be 0
SELECT COUNT(*)
FROM SYSTEM_.SYS_PART_LOBS_ LOBS,
     SYSTEM_.SYS_TABLES_ TAB
WHERE LOBS.TABLE_ID = TAB.TABLE_ID AND
      TAB.TABLE_NAME='T1';


ALTER TABLE T1 ADD COLUMN( I2 BLOB, I4 CLOB );

INSERT INTO T1 VALUES ( 1, 1, 1, 'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 2, 2, 2, 'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 3, 3, 3, 'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 4, 4, 4, 'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 5, 5, 5, 'ABC', 'DEF' );

-- should be 20
SELECT COUNT(*) FROM T1;


---------------------------------------------------
-- SYS_PART_KEY_COLUMNS_
---------------------------------------------------
-- should be 12
SELECT COUNT(*)
FROM SYSTEM_.SYS_TABLES_ TAB,
     SYSTEM_.SYS_TABLE_PARTITIONS_ PART,
     SYSTEM_.SYS_PART_KEY_COLUMNS_ PARTKEY
WHERE TAB.TABLE_NAME='T1' AND
      TAB.TABLE_ID = PART.TABLE_ID AND
      PART.TABLE_ID = PARTKEY.PARTITION_OBJ_ID;

---------------------------------------------------
-- SYS_PART_LOBS_
---------------------------------------------------
-- should be 8
SELECT COUNT(*)
FROM SYSTEM_.SYS_PART_LOBS_ LOBS,
     SYSTEM_.SYS_TABLES_ TAB
WHERE LOBS.TABLE_ID = TAB.TABLE_ID AND
      TAB.TABLE_NAME='T1';



--###################################################################
--+ SECTOR; FINALIZATION
--###################################################################

--+SKIP BEGIN;
DROP TABLE T1;
--+SKIP END;

