--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/PDT/Design/ALTER_TABLE/MERGE/RangePartTable_Integer.sql
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
--# ALTER TABLE ... MERGE PARTITIONS (PartKey: INTEGER)
--###################################################################

--###################################################################
--+SECTOR; PREPARATION
--###################################################################

--+SKIP BEGIN;
DROP TABLE T1;
DROP TABLE T2;
DROP TABLE T3;
--+SKIP END;

--+LOAD_SQL mergePartition_RangePartTable_Integer_Schema_Range_Integer.sql;

--###################################################################
--+ SECTOR; BASIC TEST
--###################################################################
--##############################
--+SECTOR; 문법 체크
--##############################
DROP TABLE TEST;
CREATE TABLE TEST( I1 INTEGER, I2 INTEGER )
PARTITION BY RANGE(I1)
(
    PARTITION P1 VALUES LESS THAN (100),
    PARTITION P2 VALUES LESS THAN (200),
    PARTITION P3 VALUES LESS THAN (300),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS;

-- should be fail
ALTER TABLE TEST 
MERGE PARTITIONS P1 TABLESPACE PDT_TBS2, P2 INTO
    PARTITION P1_1 TABLESPACE PDT_TBS2;

DROP TABLE TEST;

--##############################
--+SECTOR; 파티션드 테이블인지 체크
--##############################
DROP TABLE TEST;
CREATE TABLE TEST( I1 INTEGER, I2 INTEGER );

-- should be fail
ALTER TABLE TEST 
MERGE PARTITIONS P1, P2 INTO
    PARTITION P1_1 TABLESPACE PDT_TBS2;

DROP TABLE TEST;


--##############################
--+SECTOR; SrcPart 파티션 이름 체크
--##############################
-- should be fail
ALTER TABLE T1 
MERGE PARTITIONS P5, P1 INTO
    PARTITION P5_1 TABLESPACE PDT_TBS2;


--##############################
--+SECTOR; DstPart의 TBS 체크
--##############################
--##############
--# Left In-place 
--##############
--+LOAD_SQL mergePartition_RangePartTable_Integer_Schema_Range_Integer.sql;

ALTER TABLE T1 
MERGE PARTITIONS P1, P2 INTO
    PARTITION P1;

-- Result: PDT_TBS2, PDT_TBS, PDT_TBS
SELECT C.NAME
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ A, SYSTEM_.SYS_TABLES_ B, V$TABLESPACES C
WHERE A.TABLE_ID = B.TABLE_ID AND 
      A.TBS_ID = C.ID AND
      B.TABLE_NAME = 'T1'
ORDER BY A.PARTITION_NAME ASC;


ALTER TABLE T2 
MERGE PARTITIONS P3, P4 INTO
    PARTITION P3;

-- Result: PDT_TBS2, PDT_TBS3, PDT_TBS
SELECT C.NAME
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ A, SYSTEM_.SYS_TABLES_ B, V$TABLESPACES C
WHERE A.TABLE_ID = B.TABLE_ID AND 
      A.TBS_ID = C.ID AND
      B.TABLE_NAME = 'T2'
ORDER BY A.PARTITION_NAME ASC;


--##############
--# Right In-place 
--##############
--+LOAD_SQL mergePartition_RangePartTable_Integer_Schema_Range_Integer.sql;

ALTER TABLE T1 
MERGE PARTITIONS P1, P2 INTO
    PARTITION P2;

-- Result: PDT_TBS3, PDT_TBS, PDT_TBS
SELECT C.NAME
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ A, SYSTEM_.SYS_TABLES_ B, V$TABLESPACES C
WHERE A.TABLE_ID = B.TABLE_ID AND 
      A.TBS_ID = C.ID AND
      B.TABLE_NAME = 'T1'
ORDER BY A.PARTITION_NAME ASC;


ALTER TABLE T2 
MERGE PARTITIONS P3, P4 INTO
    PARTITION P4;

-- Result: PDT_TBS2, PDT_TBS3, PDT_TBS4
SELECT C.NAME
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ A, SYSTEM_.SYS_TABLES_ B, V$TABLESPACES C
WHERE A.TABLE_ID = B.TABLE_ID AND 
      A.TBS_ID = C.ID AND
      B.TABLE_NAME = 'T2'
ORDER BY A.PARTITION_NAME ASC;


--##############
--# Out-place 
--##############
--+LOAD_SQL mergePartition_RangePartTable_Integer_Schema_Range_Integer.sql;

ALTER TABLE T1 
MERGE PARTITIONS P1, P2 INTO
    PARTITION P1_2 TABLESPACE PDT_TBS5;

-- Result: PDT_TBS5, PDT_TBS, PDT_TBS
SELECT C.NAME
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ A, SYSTEM_.SYS_TABLES_ B, V$TABLESPACES C
WHERE A.TABLE_ID = B.TABLE_ID AND 
      A.TBS_ID = C.ID AND
      B.TABLE_NAME = 'T1'
ORDER BY A.PARTITION_NAME ASC;

ALTER TABLE T1 
MERGE PARTITIONS P3, P4 INTO
    PARTITION P3 TABLESPACE PDT_TBS4;

-- Result: PDT_TBS5, PDT_TBS4
SELECT C.NAME
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ A, SYSTEM_.SYS_TABLES_ B, V$TABLESPACES C
WHERE A.TABLE_ID = B.TABLE_ID AND 
      A.TBS_ID = C.ID AND
      B.TABLE_NAME = 'T1'
ORDER BY A.PARTITION_NAME ASC;


ALTER TABLE T2 
MERGE PARTITIONS P1, P2 INTO
    PARTITION P1_2 TABLESPACE PDT_TBS2;

-- Result: PDT_TBS2, PDT_TBS, PDT_TBS4
SELECT C.NAME
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ A, SYSTEM_.SYS_TABLES_ B, V$TABLESPACES C
WHERE A.TABLE_ID = B.TABLE_ID AND 
      A.TBS_ID = C.ID AND
      B.TABLE_NAME = 'T2'
ORDER BY A.PARTITION_NAME ASC;

ALTER TABLE T2 
MERGE PARTITIONS P3, P4 INTO
    PARTITION P4 TABLESPACE PDT_TBS5;

-- Result: PDT_TBS2, PDT_TBS5
SELECT C.NAME
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ A, SYSTEM_.SYS_TABLES_ B, V$TABLESPACES C
WHERE A.TABLE_ID = B.TABLE_ID AND 
      A.TBS_ID = C.ID AND
      B.TABLE_NAME = 'T2'
ORDER BY A.PARTITION_NAME ASC;


--##############################
--+SECTOR; DstPart의 LOB 컬럼의 TBS 체크
--##############################
--##############
--# Left In-place 
--##############
DROP TABLE T1;
CREATE TABLE T1 ( I1 INTEGER, I2 BLOB, I3 CLOB )
PARTITION BY RANGE (I1) 
( PARTITION P1 VALUES LESS THAN (50) TABLESPACE PDT_TBS 
                                    LOB(I2, I3) STORE AS ( TABLESPACE PDT_TBS2 ), 
  PARTITION P2 VALUES LESS THAN (100) TABLESPACE PDT_TBS3,
  PARTITION P3 VALUES DEFAULT
) TABLESPACE PDT_TBS4 LOB(I3) STORE AS ( TABLESPACE PDT_TBS5 );

INSERT INTO T1 VALUES ( 0,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 1,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 50,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 51,   'ABC', 'DEF' );

ALTER TABLE T1
MERGE PARTITIONS P1, P2 INTO
    PARTITION P1;

-- result: 4
SELECT COUNT(*) FROM T1 PARTITION(P1);

-- result: PDT_TBS
SELECT C.NAME
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ A, SYSTEM_.SYS_TABLES_ B, V$TABLESPACES C
WHERE A.TABLE_ID = B.TABLE_ID AND
      A.TBS_ID = C.ID AND
      B.TABLE_NAME = 'T1' AND
      A.PARTITION_NAME='P1';

-- Result: PDT_TBS2, PDT_TBS2
SELECT TBS.NAME
FROM SYSTEM_.SYS_TABLES_ TAB, SYSTEM_.SYS_PART_LOBS_ LOBS, SYSTEM_.SYS_TABLE_PARTITIONS_ PART, V$TABLESPACES TBS
WHERE TAB.TABLE_ID = LOBS.TABLE_ID AND
      PART.PARTITION_ID = LOBS.PARTITION_ID AND
      LOBS.TBS_ID = TBS.ID AND
      TAB.TABLE_NAME = 'T1' AND
      PART.PARTITION_NAME = 'P1'
ORDER BY LOBS.COLUMN_ID ASC;


--##############
--# Right In-place 
--##############
DROP TABLE T1;
CREATE TABLE T1 ( I1 INTEGER, I2 BLOB, I3 CLOB )
PARTITION BY RANGE (I1) 
( PARTITION P1 VALUES LESS THAN (50) TABLESPACE PDT_TBS 
                                    LOB(I2, I3) STORE AS ( TABLESPACE PDT_TBS2 ), 
  PARTITION P2 VALUES LESS THAN (100) TABLESPACE PDT_TBS3,
  PARTITION P3 VALUES DEFAULT
) TABLESPACE PDT_TBS4 LOB(I3) STORE AS ( TABLESPACE PDT_TBS5 );

INSERT INTO T1 VALUES ( 0,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 1,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 50,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 51,   'ABC', 'DEF' );

ALTER TABLE T1
MERGE PARTITIONS P1, P2 INTO
    PARTITION P2;

-- result: 4
SELECT COUNT(*) FROM T1 PARTITION(P2);

-- result: PDT_TBS3
SELECT C.NAME
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ A, SYSTEM_.SYS_TABLES_ B, V$TABLESPACES C
WHERE A.TABLE_ID = B.TABLE_ID AND
      A.TBS_ID = C.ID AND
      B.TABLE_NAME = 'T1' AND
      A.PARTITION_NAME='P2';

-- Result: PDT_TBS3, PDT_TBS5
SELECT TBS.NAME
FROM SYSTEM_.SYS_TABLES_ TAB, SYSTEM_.SYS_PART_LOBS_ LOBS, SYSTEM_.SYS_TABLE_PARTITIONS_ PART, V$TABLESPACES TBS
WHERE TAB.TABLE_ID = LOBS.TABLE_ID AND
      PART.PARTITION_ID = LOBS.PARTITION_ID AND
      LOBS.TBS_ID = TBS.ID AND
      TAB.TABLE_NAME = 'T1' AND
      PART.PARTITION_NAME = 'P2'
ORDER BY LOBS.COLUMN_ID ASC;


--##############
--# Out-place 
--##############
DROP TABLE T1;
CREATE TABLE T1 ( I1 INTEGER, I2 BLOB, I3 CLOB )
PARTITION BY RANGE (I1) 
( PARTITION P1 VALUES LESS THAN (50) TABLESPACE PDT_TBS 
                                    LOB(I2, I3) STORE AS ( TABLESPACE PDT_TBS2 ), 
  PARTITION P2 VALUES LESS THAN (100) TABLESPACE PDT_TBS3,
  PARTITION P3 VALUES DEFAULT
) TABLESPACE PDT_TBS4 LOB(I3) STORE AS ( TABLESPACE PDT_TBS5 );

INSERT INTO T1 VALUES ( 0,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 1,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 50,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 51,   'ABC', 'DEF' );

ALTER TABLE T1
MERGE PARTITIONS P1, P2 INTO
    PARTITION P1_2;

-- result: 4
SELECT COUNT(*) FROM T1 PARTITION(P1_2);

-- result: PDT_TBS4
SELECT C.NAME
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ A, SYSTEM_.SYS_TABLES_ B, V$TABLESPACES C
WHERE A.TABLE_ID = B.TABLE_ID AND
      A.TBS_ID = C.ID AND
      B.TABLE_NAME = 'T1' AND
      A.PARTITION_NAME='P1_2';

-- Result: PDT_TBS4, PDT_TBS5
SELECT TBS.NAME
FROM SYSTEM_.SYS_TABLES_ TAB, SYSTEM_.SYS_PART_LOBS_ LOBS, SYSTEM_.SYS_TABLE_PARTITIONS_ PART, V$TABLESPACES TBS
WHERE TAB.TABLE_ID = LOBS.TABLE_ID AND
      PART.PARTITION_ID = LOBS.PARTITION_ID AND
      LOBS.TBS_ID = TBS.ID AND
      TAB.TABLE_NAME = 'T1' AND
      PART.PARTITION_NAME = 'P1_2'
ORDER BY LOBS.COLUMN_ID ASC;


DROP TABLE T1;
CREATE TABLE T1 ( I1 INTEGER, I2 BLOB, I3 CLOB )
PARTITION BY RANGE (I1) 
( PARTITION P1 VALUES LESS THAN (50) TABLESPACE PDT_TBS 
                                    LOB(I2, I3) STORE AS ( TABLESPACE PDT_TBS2 ), 
  PARTITION P2 VALUES LESS THAN (100) TABLESPACE PDT_TBS3,
  PARTITION P3 VALUES DEFAULT
) TABLESPACE PDT_TBS4 LOB(I3) STORE AS ( TABLESPACE PDT_TBS5 );

INSERT INTO T1 VALUES ( 0,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 1,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 50,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 51,   'ABC', 'DEF' );

ALTER TABLE T1
MERGE PARTITIONS P1, P2 INTO
    PARTITION P1_2 TABLESPACE PDT_TBS2 LOB(I2) STORE AS ( TABLESPACE PDT_TBS3 );

-- result: 4
SELECT COUNT(*) FROM T1 PARTITION(P1_2);

-- result: PDT_TBS2
SELECT C.NAME
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ A, SYSTEM_.SYS_TABLES_ B, V$TABLESPACES C
WHERE A.TABLE_ID = B.TABLE_ID AND
      A.TBS_ID = C.ID AND
      B.TABLE_NAME = 'T1' AND
      A.PARTITION_NAME='P1_2';

-- Result: PDT_TBS3, PDT_TBS5
SELECT TBS.NAME
FROM SYSTEM_.SYS_TABLES_ TAB, SYSTEM_.SYS_PART_LOBS_ LOBS, SYSTEM_.SYS_TABLE_PARTITIONS_ PART, V$TABLESPACES TBS
WHERE TAB.TABLE_ID = LOBS.TABLE_ID AND
      PART.PARTITION_ID = LOBS.PARTITION_ID AND
      LOBS.TBS_ID = TBS.ID AND
      TAB.TABLE_NAME = 'T1' AND
      PART.PARTITION_NAME = 'P1_2'
ORDER BY LOBS.COLUMN_ID ASC;


DROP TABLE T1;
CREATE TABLE T1 ( I1 INTEGER, I2 BLOB, I3 CLOB )
PARTITION BY RANGE (I1) 
( PARTITION P1 VALUES LESS THAN (50) TABLESPACE PDT_TBS 
                                    LOB(I2, I3) STORE AS ( TABLESPACE PDT_TBS2 ), 
  PARTITION P2 VALUES LESS THAN (100) TABLESPACE PDT_TBS3,
  PARTITION P3 VALUES DEFAULT
) TABLESPACE PDT_TBS4 LOB(I3) STORE AS ( TABLESPACE PDT_TBS5 );

INSERT INTO T1 VALUES ( 0,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 1,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 50,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 51,   'ABC', 'DEF' );

ALTER TABLE T1
MERGE PARTITIONS P1, P2 INTO
    PARTITION P1_2 TABLESPACE PDT_TBS2;

-- result: 4
SELECT COUNT(*) FROM T1 PARTITION(P1_2);

-- result: PDT_TBS2
SELECT C.NAME
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ A, SYSTEM_.SYS_TABLES_ B, V$TABLESPACES C
WHERE A.TABLE_ID = B.TABLE_ID AND
      A.TBS_ID = C.ID AND
      B.TABLE_NAME = 'T1' AND
      A.PARTITION_NAME='P1_2';

-- Result: PDT_TBS2, PDT_TBS5
SELECT TBS.NAME
FROM SYSTEM_.SYS_TABLES_ TAB, SYSTEM_.SYS_PART_LOBS_ LOBS, SYSTEM_.SYS_TABLE_PARTITIONS_ PART, V$TABLESPACES TBS
WHERE TAB.TABLE_ID = LOBS.TABLE_ID AND
      PART.PARTITION_ID = LOBS.PARTITION_ID AND
      LOBS.TBS_ID = TBS.ID AND
      TAB.TABLE_NAME = 'T1' AND
      PART.PARTITION_NAME = 'P1_2'
ORDER BY LOBS.COLUMN_ID ASC;


DROP TABLE T1;
CREATE TABLE T1 ( I1 INTEGER, I2 BLOB, I3 CLOB )
PARTITION BY RANGE (I1) 
( PARTITION P1 VALUES LESS THAN (50) TABLESPACE PDT_TBS 
                                    LOB(I2, I3) STORE AS ( TABLESPACE PDT_TBS2 ), 
  PARTITION P2 VALUES LESS THAN (100) TABLESPACE PDT_TBS3,
  PARTITION P3 VALUES DEFAULT
) TABLESPACE PDT_TBS4 LOB(I3) STORE AS ( TABLESPACE PDT_TBS5 );

INSERT INTO T1 VALUES ( 0,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 1,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 50,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 51,   'ABC', 'DEF' );

ALTER TABLE T1
MERGE PARTITIONS P1, P2 INTO
    PARTITION P1_2 LOB STORE AS ( TABLESPACE PDT_TBS3 );

-- result: 4
SELECT COUNT(*) FROM T1 PARTITION(P1_2);

-- result: PDT_TBS4
SELECT C.NAME
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ A, SYSTEM_.SYS_TABLES_ B, V$TABLESPACES C
WHERE A.TABLE_ID = B.TABLE_ID AND
      A.TBS_ID = C.ID AND
      B.TABLE_NAME = 'T1' AND
      A.PARTITION_NAME='P1_2';

-- Result: PDT_TBS3, PDT_TBS3
SELECT TBS.NAME
FROM SYSTEM_.SYS_TABLES_ TAB, SYSTEM_.SYS_PART_LOBS_ LOBS, SYSTEM_.SYS_TABLE_PARTITIONS_ PART, V$TABLESPACES TBS
WHERE TAB.TABLE_ID = LOBS.TABLE_ID AND
      PART.PARTITION_ID = LOBS.PARTITION_ID AND
      LOBS.TBS_ID = TBS.ID AND
      TAB.TABLE_NAME = 'T1' AND
      PART.PARTITION_NAME = 'P1_2'
ORDER BY LOBS.COLUMN_ID ASC;



--###################################################################
--+ SECTOR; SrcPart1, SrcPart2, DstPart 이름 체크
--###################################################################
--##############################
--+SECTOR; Left In-place
--##############################
--+LOAD_SQL mergePartition_RangePartTable_Integer_Schema_Range_Integer.sql;

-- should be fail
ALTER TABLE T1 
MERGE PARTITIONS P1, P5 INTO
    PARTITION P1;

-- should be fail
ALTER TABLE T1 
MERGE PARTITIONS P5, P1 INTO
    PARTITION P5;

-- should be fail
ALTER TABLE T1 
MERGE PARTITIONS P2, P2 INTO
    PARTITION P2;


--##############################
--+SECTOR; Right In-place
--##############################
-- should be fail
ALTER TABLE T1 
MERGE PARTITIONS P5, P1 INTO
    PARTITION P1;

-- should be fail
ALTER TABLE T1 
MERGE PARTITIONS P1, P5 INTO
    PARTITION P5;

-- should be fail
ALTER TABLE T1 
MERGE PARTITIONS P2, P2 INTO
    PARTITION P2;


--##############################
--+SECTOR; Out-place
--##############################
-- should be fail
ALTER TABLE T1 
MERGE PARTITIONS P1,P2 INTO
    PARTITION P3;

-- should be fail
ALTER TABLE T1 
MERGE PARTITIONS P1, P5 INTO
    PARTITION P6;

-- should be fail
ALTER TABLE T1 
MERGE PARTITIONS P5, P1 INTO
    PARTITION P6;

-- should be fail
ALTER TABLE T1 
MERGE PARTITIONS P1, P1 INTO
    PARTITION P6;

-- should be fail
ALTER TABLE T1 
MERGE PARTITIONS P1, P2 INTO
    PARTITION P4 TABLESPACE PDT_TBS3;



--###################################################################
--+ SECTOR; 병합 기준 체크(인접 파티션 체크)
--###################################################################
--##############################
--+SECTOR; Left In-place
--##############################
--+LOAD_SQL mergePartition_RangePartTable_Integer_Schema_Range_Integer.sql;

-- should be fail
ALTER TABLE T1 
MERGE PARTITIONS P1, P3 INTO
    PARTITION P1;

-- should be fail
ALTER TABLE T1 
MERGE PARTITIONS P1, P4 INTO
    PARTITION P1;

-- should be fail
ALTER TABLE T1 
MERGE PARTITIONS P2, P4 INTO
    PARTITION P2;

-- should be success
ALTER TABLE T1 
MERGE PARTITIONS P1, P2 INTO
    PARTITION P1;

-- should be success
ALTER TABLE T1 
MERGE PARTITIONS P3, P4 INTO
    PARTITION P3;

--+LOAD_SQL mergePartition_RangePartTable_Integer_Schema_Range_Integer.sql;

-- should be success
ALTER TABLE T1 
MERGE PARTITIONS P2, P3 INTO
    PARTITION P2;


--##############################
--+SECTOR; Right In-place
--##############################
--+LOAD_SQL mergePartition_RangePartTable_Integer_Schema_Range_Integer.sql;

-- should be fail
ALTER TABLE T1 
MERGE PARTITIONS P1, P3 INTO
    PARTITION P3;

-- should be fail
ALTER TABLE T1 
MERGE PARTITIONS P1, P4 INTO
    PARTITION P4;

-- should be fail
ALTER TABLE T1 
MERGE PARTITIONS P2, P4 INTO
    PARTITION P4;

-- should be success
ALTER TABLE T1 
MERGE PARTITIONS P1, P2 INTO
    PARTITION P2;

-- should be success
ALTER TABLE T1 
MERGE PARTITIONS P3, P4 INTO
    PARTITION P4;

--+LOAD_SQL mergePartition_RangePartTable_Integer_Schema_Range_Integer.sql;

-- should be success
ALTER TABLE T1 
MERGE PARTITIONS P2, P3 INTO
    PARTITION P3;


--##############################
--+SECTOR; Out-place
--##############################
--+LOAD_SQL mergePartition_RangePartTable_Integer_Schema_Range_Integer.sql;

-- should be fail
ALTER TABLE T1 
MERGE PARTITIONS P1, P3 INTO
    PARTITION P1_3;

-- should be fail
ALTER TABLE T1 
MERGE PARTITIONS P1, P4 INTO
    PARTITION P1_4;

-- should be fail
ALTER TABLE T1 
MERGE PARTITIONS P2, P4 INTO
    PARTITION P2_4;

-- should be success
ALTER TABLE T1 
MERGE PARTITIONS P1, P2 INTO
    PARTITION P1_2;

-- should be success
ALTER TABLE T1 
MERGE PARTITIONS P3, P4 INTO
    PARTITION P3_4;

--+LOAD_SQL mergePartition_RangePartTable_Integer_Schema_Range_Integer.sql;

-- should be success
ALTER TABLE T1 
MERGE PARTITIONS P2, P3 INTO
    PARTITION P2_3;


-- should be fail
ALTER TABLE T2 
MERGE PARTITIONS P1, P3 INTO
    PARTITION P3 TABLESPACE PDT_TBS2;

-- should be fail
ALTER TABLE T2 
MERGE PARTITIONS P1, P4 INTO
    PARTITION P1 TABLESPACE PDT_TBS2;

-- should be fail
ALTER TABLE T2 
MERGE PARTITIONS P2, P4 INTO
    PARTITION P2_4;

-- should be success
ALTER TABLE T2 
MERGE PARTITIONS P1, P2 INTO
    PARTITION P2 TABLESPACE PDT_TBS2;

-- should be success
ALTER TABLE T2 
MERGE PARTITIONS P3, P4 INTO
    PARTITION P3_4;

--+LOAD_SQL mergePartition_RangePartTable_Integer_Schema_Range_Integer.sql;

-- should be success
ALTER TABLE T2 
MERGE PARTITIONS P2, P3 INTO
    PARTITION P2 TABLESPACE PDT_TBS2;



--###################################################################
--+ SECTOR; SrcPart1과 SrcPart2의 위치에 따른 병합
--###################################################################
--##############################
--+SECTOR; 가장 작은 파티션 + 중간 파티션
--##############################
--##############
--# Left In-place 
--##############
--+LOAD_SQL mergePartition_RangePartTable_Integer_Schema_Range_Integer.sql;
ALTER TABLE T1 
MERGE PARTITIONS P1, P2 INTO
    PARTITION P1;

-- Result: 
-- (P1,   NULL, 200)
-- (P3,   200,  300)
-- (P4,   300,  NULL)
SELECT PART.PARTITION_NAME, PART.PARTITION_MIN_VALUE, PART.PARTITION_MAX_VALUE
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ PART,
     SYSTEM_.SYS_TABLES_ TAB
WHERE TAB.TABLE_ID = PART.TABLE_ID AND
      TAB.TABLE_NAME='T1'
ORDER BY PART.PARTITION_NAME;

-- result: 4
SELECT COUNT(*) FROM T1 PARTITION (P1);
-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P3);
-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P4);


--##############
--# Right In-place 
--##############
--+LOAD_SQL mergePartition_RangePartTable_Integer_Schema_Range_Integer.sql;
ALTER TABLE T1 
MERGE PARTITIONS P1, P2 INTO
    PARTITION P2;

-- Result: 
-- (P2,   NULL, 200)
-- (P3,   200,  300)
-- (P4,   300,  NULL)
SELECT PART.PARTITION_NAME, PART.PARTITION_MIN_VALUE, PART.PARTITION_MAX_VALUE
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ PART,
     SYSTEM_.SYS_TABLES_ TAB
WHERE TAB.TABLE_ID = PART.TABLE_ID AND
      TAB.TABLE_NAME='T1'
ORDER BY PART.PARTITION_NAME;

-- result: 4
SELECT COUNT(*) FROM T1 PARTITION (P2);
-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P3);
-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P4);

--##############
--# Out-place 
--##############
--+LOAD_SQL mergePartition_RangePartTable_Integer_Schema_Range_Integer.sql;
ALTER TABLE T1 
MERGE PARTITIONS P1, P2 INTO
    PARTITION P1_2;

-- Result: 
-- (P1_2, NULL, 200)
-- (P3,   200,  300)
-- (P4,   300,  NULL)
SELECT PART.PARTITION_NAME, PART.PARTITION_MIN_VALUE, PART.PARTITION_MAX_VALUE
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ PART,
     SYSTEM_.SYS_TABLES_ TAB
WHERE TAB.TABLE_ID = PART.TABLE_ID AND
      TAB.TABLE_NAME='T1'
ORDER BY PART.PARTITION_NAME;

-- result: 4
SELECT COUNT(*) FROM T1 PARTITION (P1_2);
-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P3);
-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P4);

--##############################
--+SECTOR; 중간 파티션 + 중간 파티션
--##############################
--##############
--# Left In-place 
--##############
--+LOAD_SQL mergePartition_RangePartTable_Integer_Schema_Range_Integer.sql;
ALTER TABLE T1 
MERGE PARTITIONS P2, P3 INTO
    PARTITION P2;

-- Result: 
-- (P1,   NULL, 100)
-- (P2,   100,  300)
-- (P4,   300,  NULL)
SELECT PART.PARTITION_NAME, PART.PARTITION_MIN_VALUE, PART.PARTITION_MAX_VALUE
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ PART,
     SYSTEM_.SYS_TABLES_ TAB
WHERE TAB.TABLE_ID = PART.TABLE_ID AND
      TAB.TABLE_NAME='T1'
ORDER BY PART.PARTITION_NAME;

-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P1);
-- result: 4
SELECT COUNT(*) FROM T1 PARTITION (P2);
-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P4);


--##############
--# Right In-place 
--##############
--+LOAD_SQL mergePartition_RangePartTable_Integer_Schema_Range_Integer.sql;
ALTER TABLE T1 
MERGE PARTITIONS P2, P3 INTO
    PARTITION P3;

-- Result: 
-- (P1,   NULL, 100)
-- (P3,   100,  300)
-- (P4,   300,  NULL)
SELECT PART.PARTITION_NAME, PART.PARTITION_MIN_VALUE, PART.PARTITION_MAX_VALUE
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ PART,
     SYSTEM_.SYS_TABLES_ TAB
WHERE TAB.TABLE_ID = PART.TABLE_ID AND
      TAB.TABLE_NAME='T1'
ORDER BY PART.PARTITION_NAME;

-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P1);
-- result: 4
SELECT COUNT(*) FROM T1 PARTITION (P3);
-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P4);

--##############
--# Out-place 
--##############
--+LOAD_SQL mergePartition_RangePartTable_Integer_Schema_Range_Integer.sql;
ALTER TABLE T1 
MERGE PARTITIONS P2, P3 INTO
    PARTITION P2_3;

-- Result: 
-- (P1,   NULL, 100)
-- (P2_3, 100,  300)
-- (P4,   300,  NULL)
SELECT PART.PARTITION_NAME, PART.PARTITION_MIN_VALUE, PART.PARTITION_MAX_VALUE
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ PART,
     SYSTEM_.SYS_TABLES_ TAB
WHERE TAB.TABLE_ID = PART.TABLE_ID AND
      TAB.TABLE_NAME='T1'
ORDER BY PART.PARTITION_NAME;

-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P1);
-- result: 4
SELECT COUNT(*) FROM T1 PARTITION (P2_3);
-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P4);


--##############################
--+SECTOR; 중간 파티션 + 기본 파티션
--##############################
--##############
--# Left In-place 
--##############
--+LOAD_SQL mergePartition_RangePartTable_Integer_Schema_Range_Integer.sql;
ALTER TABLE T1 
MERGE PARTITIONS P3, P4 INTO
    PARTITION P3;

-- Result: 
-- (P1,   NULL, 100)
-- (P2,   100,  200)
-- (P3,   200,  NULL)
SELECT PART.PARTITION_NAME, PART.PARTITION_MIN_VALUE, PART.PARTITION_MAX_VALUE
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ PART,
     SYSTEM_.SYS_TABLES_ TAB
WHERE TAB.TABLE_ID = PART.TABLE_ID AND
      TAB.TABLE_NAME='T1'
ORDER BY PART.PARTITION_NAME;

-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P1);
-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P2);
-- result: 4
SELECT COUNT(*) FROM T1 PARTITION (P3);


--##############
--# Right In-place 
--##############
--+LOAD_SQL mergePartition_RangePartTable_Integer_Schema_Range_Integer.sql;
ALTER TABLE T1 
MERGE PARTITIONS P3, P4 INTO
    PARTITION P4;

-- Result: 
-- (P1,   NULL, 100)
-- (P2,   100,  200)
-- (P4,   200,  NULL)
SELECT PART.PARTITION_NAME, PART.PARTITION_MIN_VALUE, PART.PARTITION_MAX_VALUE
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ PART,
     SYSTEM_.SYS_TABLES_ TAB
WHERE TAB.TABLE_ID = PART.TABLE_ID AND
      TAB.TABLE_NAME='T1'
ORDER BY PART.PARTITION_NAME;

-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P1);
-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P2);
-- result: 4
SELECT COUNT(*) FROM T1 PARTITION (P4);

--##############
--# Out-place 
--##############
--+LOAD_SQL mergePartition_RangePartTable_Integer_Schema_Range_Integer.sql;
ALTER TABLE T1 
MERGE PARTITIONS P3, P4 INTO
    PARTITION P3_4;

-- Result: 
-- (P1,   NULL, 100)
-- (P2,   100,  200)
-- (P3_4, 200,  NULL)
SELECT PART.PARTITION_NAME, PART.PARTITION_MIN_VALUE, PART.PARTITION_MAX_VALUE
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ PART,
     SYSTEM_.SYS_TABLES_ TAB
WHERE TAB.TABLE_ID = PART.TABLE_ID AND
      TAB.TABLE_NAME='T1'
ORDER BY PART.PARTITION_NAME;

-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P1);
-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P2);
-- result: 4
SELECT COUNT(*) FROM T1 PARTITION (P3_4);



--###################################################################
--+ SECTOR; 병합 테스트 + 분할 테스트
--###################################################################
--+LOAD_SQL mergePartition_RangePartTable_Integer_Schema_Range_Integer.sql;

--##############################
--+SECTOR; Test for Table T1 (no index, single part key)
--##############################
-- should be success
ALTER TABLE T1 
MERGE PARTITIONS P1, P2 INTO
    PARTITION P1;

-- should be success
ALTER TABLE T1 
MERGE PARTITIONS P1, P3 INTO
    PARTITION P1;

-- should be success
ALTER TABLE T1 
MERGE PARTITIONS P1, P4 INTO
    PARTITION P1;

-- should be success
ALTER TABLE T1 
SPLIT PARTITION P1 AT (100) INTO
( 
    PARTITION P1,
    PARTITION P2
);

-- should be success
ALTER TABLE T1 
SPLIT PARTITION P2 AT (200) INTO
( 
    PARTITION P3,
    PARTITION P4
);

-- should be fail
ALTER TABLE T1 
MERGE PARTITIONS P1, P4 INTO
    PARTITION P1;

-- should be fail
ALTER TABLE T1 
MERGE PARTITIONS P1, P3 INTO
    PARTITION P4;

-- should be success
ALTER TABLE T1 
MERGE PARTITIONS P1, P3 INTO
    PARTITION P3;

-- should be success
ALTER TABLE T1 
MERGE PARTITIONS P3, P4 INTO
    PARTITION P5 TABLESPACE PDT_TBS5;

-- result: 8
SELECT COUNT(*) FROM T1 PARTITION (P5);


--##############################
--+SECTOR; Test for Table T2 (multi key index, multi part key)
--##############################
-- should be success
ALTER TABLE T2 
MERGE PARTITIONS P1, P2 INTO
    PARTITION P1;

-- should be success
ALTER TABLE T2 
MERGE PARTITIONS P1, P3 INTO
    PARTITION P1;

-- should be success
ALTER TABLE T2 
MERGE PARTITIONS P1, P4 INTO
    PARTITION P1;

-- should be success
ALTER TABLE T2 
SPLIT PARTITION P1 AT (100) INTO
( 
    PARTITION P1,
    PARTITION P2
);

-- should be success
ALTER TABLE T2 
SPLIT PARTITION P2 AT (200) INTO
( 
    PARTITION P3,
    PARTITION P4
);

-- should be fail
ALTER TABLE T2 
MERGE PARTITIONS P1, P4 INTO
    PARTITION P1;

-- should be fail
ALTER TABLE T2 
MERGE PARTITIONS P1, P3 INTO
    PARTITION P4;

-- should be success
ALTER TABLE T2 
MERGE PARTITIONS P1, P3 INTO
    PARTITION P3;

-- should be success
ALTER TABLE T2 
MERGE PARTITIONS P3, P4 INTO
    PARTITION P5 TABLESPACE PDT_TBS5;

-- result: 8
SELECT COUNT(*) FROM T1 PARTITION (P5);

-- result: 0
SELECT /* INDEX ASC ( T2, IDX1 ) */ I1
FROM T2 PARTITION (P5) LIMIT 1;



--##################################################################
--+SECTOR; FINALIZATION
--##################################################################
--+SKIP BEGIN;
DROP TABLE T1;
DROP TABLE T2;
DROP TABLE T3;
--+SKIP END;
