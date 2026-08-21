--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/PDT/Design/ALTER_TABLE/DROP/RangePartTable_Varchar.sql
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
--# ALTER TABLE ... DROP PARTITION (PartKey: VARCHAR)
--###################################################################

--###################################################################
--+SECTOR; PREPARATION
--###################################################################

--+SKIP BEGIN;
DROP TABLE T1;
DROP TABLE T2;
DROP TABLE T3;
--+SKIP END;

--+APPEND_LST dropPartition_RangePartTable_Varchar_Schema_Range_Varchar.sql;
--+SYSTEM is -silent -f dropPartition_RangePartTable_Varchar_Schema_Range_Varchar.sql;

--###################################################################
--+ SECTOR; BASIC TEST
--###################################################################
--##############################
--+SECTOR; 문법 체크
--##############################
DROP TABLE TEST;
CREATE TABLE TEST( I1 VARCHAR(1000), I2 INTEGER )
PARTITION BY RANGE(I1)
(
    PARTITION P1 VALUES LESS THAN (100),
    PARTITION P2 VALUES LESS THAN (200),
    PARTITION P3 VALUES LESS THAN (300),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS;

-- should be fail
ALTER TABLE TEST 
DROP PARTITION P1_1 TABLESPACE PDT_TBS2;

DROP TABLE TEST;

--##############################
--+SECTOR; 파티션드 테이블인지 체크
--##############################
DROP TABLE TEST;
CREATE TABLE TEST( I1 VARCHAR(10), I2 INTEGER );

-- should be fail
ALTER TABLE TEST 
DROP PARTITION P1_1;

DROP TABLE TEST;


--##############################
--+SECTOR; 파티션 이름 체크
--##############################
--+SYSTEM is -silent -f dropPartition_RangePartTable_Varchar_Schema_Range_Varchar.sql;

-- should be fail
ALTER TABLE T1 
DROP PARTITION P5;

-- should be fail
ALTER TABLE T1 
DROP PARTITION P4;

-- should be success
ALTER TABLE T1 
DROP PARTITION P3;

-- should be success
ALTER TABLE T1 
DROP PARTITION P2;

-- should be success
ALTER TABLE T1 
DROP PARTITION P1;



--##############################
--+SECTOR; LOB 컬럼이 있는 경우의 DROP PARTITION
--##############################
DROP TABLE T1;
CREATE TABLE T1 ( I1 VARCHAR(1000), I2 BLOB, I3 CLOB )
PARTITION BY RANGE(I1) 
( PARTITION P1 VALUES LESS THAN ('100') TABLESPACE PDT_TBS 
                        LOB(I2, I3) STORE AS ( TABLESPACE PDT_TBS2 ), 
  PARTITION P2 VALUES LESS THAN ('200') TABLESPACE PDT_TBS3,
  PARTITION P3 VALUES DEFAULT
) TABLESPACE PDT_TBS4 LOB(I3) STORE AS ( TABLESPACE PDT_TBS5 );

INSERT INTO T1 VALUES ( '100',   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( '150',   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( '200',   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( '250',   'ABC', 'DEF' );

-- should be fail
ALTER TABLE T1
DROP PARTITION P3;

-- result: 4
SELECT COUNT(*) FROM T1;

ALTER TABLE T1
DROP PARTITION P2;

-- result: 2
SELECT COUNT(*) FROM T1;

-- Result: 
-- (P1,   NULL, '100')
-- (P3,   '100',  NULL)
SELECT PART.PARTITION_NAME, PART.PARTITION_MIN_VALUE, PART.PARTITION_MAX_VALUE
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ PART,
     SYSTEM_.SYS_TABLES_ TAB
WHERE TAB.TABLE_ID = PART.TABLE_ID AND
      TAB.TABLE_NAME='T1'
ORDER BY PART.PARTITION_NAME;


ALTER TABLE T1
DROP PARTITION P1;


-- Result: 
-- (P3,   NULL,  NULL)
SELECT PART.PARTITION_NAME, PART.PARTITION_MIN_VALUE, PART.PARTITION_MAX_VALUE
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ PART,
     SYSTEM_.SYS_TABLES_ TAB
WHERE TAB.TABLE_ID = PART.TABLE_ID AND
      TAB.TABLE_NAME='T1'
ORDER BY PART.PARTITION_NAME;


-- result: 2
SELECT COUNT(*) FROM T1;



--##################################################################
--+SECTOR; SPLIT + MERGE + DROP
--##################################################################
--+SYSTEM is -silent -f dropPartition_RangePartTable_Varchar_Schema_Range_Varchar.sql;

ALTER TABLE T1
SPLIT PARTITION P1 AT ('050') INTO
(
    PARTITION P1_1, 
    PARTITION P1_2
);

ALTER TABLE T1
MERGE PARTITIONS P1_1, P1_2 INTO
PARTITION P1;

ALTER TABLE T1
DROP PARTITION P1;

ALTER TABLE T1
MERGE PARTITIONS P2, P3 INTO
PARTITION P2_3;

ALTER TABLE T1
DROP PARTITION P2_3;

-- result: 2
SELECT COUNT(*) FROM T1;

-- result: '300'
SELECT /* INDEX ASC ( T1, IDX1 ) */ I1
FROM T1 PARTITION (P4) LIMIT 1;


ALTER TABLE T2
SPLIT PARTITION P1 AT ('050') INTO
(
    PARTITION P1_1, 
    PARTITION P1_2
);

ALTER TABLE T2
MERGE PARTITIONS P1_1, P1_2 INTO
PARTITION P1;

ALTER TABLE T2
DROP PARTITION P1;

ALTER TABLE T2
MERGE PARTITIONS P2, P3 INTO
PARTITION P2_3;

ALTER TABLE T2
DROP PARTITION P2_3;

-- result: 2
SELECT COUNT(*) FROM T2;

-- result: '300'
SELECT /* INDEX ASC ( T2, IDX1 ) */ I1
FROM T2 PARTITION (P4) LIMIT 1;



--##################################################################
--+SECTOR; FINALIZATION
--##################################################################
--+SKIP BEGIN;
DROP TABLE T1;
DROP TABLE T2;
DROP TABLE T3;
--+SKIP END;
