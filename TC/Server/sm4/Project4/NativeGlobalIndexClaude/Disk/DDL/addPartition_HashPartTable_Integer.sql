--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/PDT/Design/ALTER_TABLE/ADD/HashPartTable_Integer.sql
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
--# ALTER TABLE ... ADD PARTITION (PartKey: INTEGER)
--###################################################################

--###################################################################
--+SECTOR; PREPARATION
--###################################################################

--+SKIP BEGIN;
DROP TABLE T1;
DROP TABLE T2;
DROP TABLE T3;
--+SKIP END;

--+APPEND_LST addPartition_HashPartTable_Integer_Schema_Hash_Integer.sql;
--+SYSTEM is -silent -f addPartition_HashPartTable_Integer_Schema_Hash_Integer.sql;

--###################################################################
--+ SECTOR; BASIC TEST
--###################################################################
--##############################
--+SECTOR; 문법 체크
--##############################
DROP TABLE TEST;
CREATE TABLE TEST( I1 INTEGER, I2 INTEGER )
PARTITION BY HASH(I1)
(
    PARTITION P1,
    PARTITION P2,
    PARTITION P3,
    PARTITION P4
) TABLESPACE PDT_TBS;

-- should be fail
ALTER TABLE TEST 
ADD PARTITION P1_1 TABLESPACE PDT_TBS2, P1_2;

DROP TABLE TEST;

--##############################
--+SECTOR; 파티션드 테이블인지 체크
--##############################
DROP TABLE TEST;
CREATE TABLE TEST( I1 INTEGER, I2 INTEGER );

-- should be fail
ALTER TABLE TEST 
ADD PARTITION P1_1 TABLESPACE PDT_TBS2;

DROP TABLE TEST;


--##############################
--+SECTOR; DstPart 파티션 이름 체크
--##############################
--+SYSTEM is -silent -f addPartition_HashPartTable_Integer_Schema_Hash_Integer.sql;

-- should be fail
ALTER TABLE T1 
ADD PARTITION P1;

-- should be fail
ALTER TABLE T1 
ADD PARTITION P2;

-- should be fail
ALTER TABLE T1 
ADD PARTITION P3;

-- should be fail
ALTER TABLE T1 
ADD PARTITION P4;

-- should be success 
ALTER TABLE T1 
ADD PARTITION P5;

-- should be fail
ALTER TABLE T1 
ADD PARTITION P5;

-- should be fail
ALTER TABLE T1 
ADD PARTITION P5 TABLESPACE PDT_TBS3;

-- should be fail
ALTER TABLE T1 
ADD PARTITION P4 TABLESPACE PDT_TBS2;

-- should be fail
ALTER TABLE T1 
ADD PARTITION P3 TABLESPACE PDT_TBS;


--##############################
--+SECTOR; DstPart의 TBS 체크
--##############################
--+SYSTEM is -silent -f addPartition_HashPartTable_Integer_Schema_Hash_Integer.sql;

ALTER TABLE T1 
ADD PARTITION P5;

-- Result: PDT_TBS
SELECT C.NAME
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ A, SYSTEM_.SYS_TABLES_ B, V$TABLESPACES C
WHERE A.TABLE_ID = B.TABLE_ID AND 
      A.TBS_ID = C.ID AND
      B.TABLE_NAME = 'T1' AND
      A.PARTITION_NAME = 'P5';

ALTER TABLE T1 
ADD PARTITION P6 TABLESPACE PDT_TBS3;

-- Result: PDT_TBS3
SELECT C.NAME
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ A, SYSTEM_.SYS_TABLES_ B, V$TABLESPACES C
WHERE A.TABLE_ID = B.TABLE_ID AND 
      A.TBS_ID = C.ID AND
      B.TABLE_NAME = 'T1' AND
      A.PARTITION_NAME = 'P5';


ALTER TABLE T2 
ADD PARTITION P5;

-- Result: PDT_TBS
SELECT C.NAME
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ A, SYSTEM_.SYS_TABLES_ B, V$TABLESPACES C
WHERE A.TABLE_ID = B.TABLE_ID AND 
      A.TBS_ID = C.ID AND
      B.TABLE_NAME = 'T2' AND
      A.PARTITION_NAME = 'P5';

ALTER TABLE T2 
ADD PARTITION P6 TABLESPACE PDT_TBS3;

-- Result: PDT_TBS3
SELECT C.NAME
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ A, SYSTEM_.SYS_TABLES_ B, V$TABLESPACES C
WHERE A.TABLE_ID = B.TABLE_ID AND 
      A.TBS_ID = C.ID AND
      B.TABLE_NAME = 'T2' AND
      A.PARTITION_NAME = 'P6';



--##############################
--+SECTOR; DstPart의 LOB 컬럼의 TBS 체크
--##############################
DROP TABLE T1;
CREATE TABLE T1 ( I1 INTEGER, I2 BLOB, I3 CLOB )
PARTITION BY HASH (I1) 
( PARTITION P1 TABLESPACE PDT_TBS 
                        LOB(I2, I3) STORE AS ( TABLESPACE PDT_TBS2 ), 
  PARTITION P2 TABLESPACE PDT_TBS3,
  PARTITION P3
) TABLESPACE PDT_TBS4 LOB(I3) STORE AS ( TABLESPACE PDT_TBS5 );

INSERT INTO T1 VALUES ( 100,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 150,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 200,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 250,   'ABC', 'DEF' );

ALTER TABLE T1
ADD PARTITION P4;

-- result: 4
SELECT COUNT(*) FROM T1;

-- result: PDT_TBS4
SELECT C.NAME
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ A, SYSTEM_.SYS_TABLES_ B, V$TABLESPACES C
WHERE A.TABLE_ID = B.TABLE_ID AND
      A.TBS_ID = C.ID AND
      B.TABLE_NAME = 'T1' AND
      A.PARTITION_NAME='P4';

-- Result: PDT_TBS4, PDT_TBS5
SELECT TBS.NAME
FROM SYSTEM_.SYS_TABLES_ TAB, SYSTEM_.SYS_PART_LOBS_ LOBS, SYSTEM_.SYS_TABLE_PARTITIONS_ PART, V$TABLESPACES TBS
WHERE TAB.TABLE_ID = LOBS.TABLE_ID AND
      PART.PARTITION_ID = LOBS.PARTITION_ID AND
      LOBS.TBS_ID = TBS.ID AND
      TAB.TABLE_NAME = 'T1' AND
      PART.PARTITION_NAME = 'P4'
ORDER BY LOBS.COLUMN_ID ASC;


DROP TABLE T1;
CREATE TABLE T1 ( I1 INTEGER, I2 BLOB, I3 CLOB )
PARTITION BY HASH (I1) 
( PARTITION P1 TABLESPACE PDT_TBS 
                            LOB(I2, I3) STORE AS ( TABLESPACE PDT_TBS2 ), 
  PARTITION P2 TABLESPACE PDT_TBS3,
  PARTITION P3
) TABLESPACE PDT_TBS4 LOB(I3) STORE AS ( TABLESPACE PDT_TBS5 );

INSERT INTO T1 VALUES ( 100,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 150,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 200,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 250,   'ABC', 'DEF' );

ALTER TABLE T1
ADD PARTITION P4 TABLESPACE PDT_TBS2 LOB(I2) STORE AS ( TABLESPACE PDT_TBS3 );

-- result: 4
SELECT COUNT(*) FROM T1;

-- result: PDT_TBS2
SELECT C.NAME
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ A, SYSTEM_.SYS_TABLES_ B, V$TABLESPACES C
WHERE A.TABLE_ID = B.TABLE_ID AND
      A.TBS_ID = C.ID AND
      B.TABLE_NAME = 'T1' AND
      A.PARTITION_NAME='P4';

-- Result: PDT_TBS3, PDT_TBS5
SELECT TBS.NAME
FROM SYSTEM_.SYS_TABLES_ TAB, SYSTEM_.SYS_PART_LOBS_ LOBS, SYSTEM_.SYS_TABLE_PARTITIONS_ PART, V$TABLESPACES TBS
WHERE TAB.TABLE_ID = LOBS.TABLE_ID AND
      PART.PARTITION_ID = LOBS.PARTITION_ID AND
      LOBS.TBS_ID = TBS.ID AND
      TAB.TABLE_NAME = 'T1' AND
      PART.PARTITION_NAME = 'P4'
ORDER BY LOBS.COLUMN_ID ASC;


DROP TABLE T1;
CREATE TABLE T1 ( I1 INTEGER, I2 BLOB, I3 CLOB )
PARTITION BY HASH (I1)
( PARTITION P1 TABLESPACE PDT_TBS                  
                            LOB(I2, I3) STORE AS ( TABLESPACE PDT_TBS2 ),  
  PARTITION P2 TABLESPACE PDT_TBS3,
  PARTITION P3 
) TABLESPACE PDT_TBS4 LOB(I3) STORE AS ( TABLESPACE PDT_TBS5 );

INSERT INTO T1 VALUES ( 100,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 150,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 200,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 250,   'ABC', 'DEF' );

ALTER TABLE T1
ADD PARTITION P4 TABLESPACE PDT_TBS2;

-- result: 4
SELECT COUNT(*) FROM T1;

-- result: PDT_TBS2
SELECT C.NAME
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ A, SYSTEM_.SYS_TABLES_ B, V$TABLESPACES C
WHERE A.TABLE_ID = B.TABLE_ID AND
      A.TBS_ID = C.ID AND
      B.TABLE_NAME = 'T1' AND
      A.PARTITION_NAME='P4';

-- Result: PDT_TBS2, PDT_TBS5
SELECT TBS.NAME
FROM SYSTEM_.SYS_TABLES_ TAB, SYSTEM_.SYS_PART_LOBS_ LOBS, SYSTEM_.SYS_TABLE_PARTITIONS_ PART, V$TABLESPACES TBS
WHERE TAB.TABLE_ID = LOBS.TABLE_ID AND
      PART.PARTITION_ID = LOBS.PARTITION_ID AND
      LOBS.TBS_ID = TBS.ID AND
      TAB.TABLE_NAME = 'T1' AND
      PART.PARTITION_NAME = 'P4'
ORDER BY LOBS.COLUMN_ID ASC;


DROP TABLE T1;
CREATE TABLE T1 ( I1 INTEGER, I2 BLOB, I3 CLOB )
PARTITION BY HASH (I1)
( PARTITION P1 TABLESPACE PDT_TBS                  
                            LOB(I2, I3) STORE AS ( TABLESPACE PDT_TBS2 ),  
  PARTITION P2 TABLESPACE PDT_TBS3,
  PARTITION P3 
) TABLESPACE PDT_TBS4 LOB(I3) STORE AS ( TABLESPACE PDT_TBS5 );

INSERT INTO T1 VALUES ( 100,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 150,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 200,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 250,   'ABC', 'DEF' );

ALTER TABLE T1
ADD PARTITION P4 LOB STORE AS ( TABLESPACE PDT_TBS3 );

-- result: 4
SELECT COUNT(*) FROM T1;

-- result: PDT_TBS4
SELECT C.NAME
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ A, SYSTEM_.SYS_TABLES_ B, V$TABLESPACES C
WHERE A.TABLE_ID = B.TABLE_ID AND
      A.TBS_ID = C.ID AND
      B.TABLE_NAME = 'T1' AND
      A.PARTITION_NAME='P4';

-- Result: PDT_TBS3, PDT_TBS3
SELECT TBS.NAME
FROM SYSTEM_.SYS_TABLES_ TAB, SYSTEM_.SYS_PART_LOBS_ LOBS, SYSTEM_.SYS_TABLE_PARTITIONS_ PART, V$TABLESPACES TBS
WHERE TAB.TABLE_ID = LOBS.TABLE_ID AND
      PART.PARTITION_ID = LOBS.PARTITION_ID AND
      LOBS.TBS_ID = TBS.ID AND
      TAB.TABLE_NAME = 'T1' AND
      PART.PARTITION_NAME = 'P4'
ORDER BY LOBS.COLUMN_ID ASC;



--##################################################################
--+SECTOR; DATA 비교(create 5 partition VS. create 4 partition + add partition)
--##################################################################
--+SYSTEM is -silent -f addPartition_HashPartTable_Integer_Schema_Hash_Integer.sql;

CREATE TABLE TEST( I1 INTEGER, I2 INTEGER, I3 INTEGER )
PARTITION BY HASH (I1)
(
    PARTITION P1,
    PARTITION P2,
    PARTITION P3,
    PARTITION P4,
    PARTITION P5
) TABLESPACE PDT_TBS;

INSERT INTO TEST VALUES (NULL, 100, 100);
INSERT INTO TEST VALUES (0, 100, 100);
INSERT INTO TEST VALUES (50, 100, 100);
INSERT INTO TEST VALUES (75, 100, 100);
INSERT INTO TEST VALUES (100, 100, 100);
INSERT INTO TEST VALUES (150, 100, 100);
INSERT INTO TEST VALUES (175, 100, 100);
INSERT INTO TEST VALUES (200, 100, 100);
INSERT INTO TEST VALUES (250, 100, 100);
INSERT INTO TEST VALUES (275, 100, 100);
INSERT INTO TEST VALUES (300, 100, 100);
INSERT INTO TEST VALUES (350, 100, 100);
INSERT INTO TEST VALUES (375, 100, 100);

SELECT COUNT(*) FROM TEST PARTITION (P1);
SELECT COUNT(*) FROM TEST PARTITION (P2);
SELECT COUNT(*) FROM TEST PARTITION (P3);
SELECT COUNT(*) FROM TEST PARTITION (P4);
SELECT COUNT(*) FROM TEST PARTITION (P5);

ALTER TABLE T1 ADD PARTITION P5;

SELECT COUNT(*) FROM T1 PARTITION (P1);
SELECT COUNT(*) FROM T1 PARTITION (P2);
SELECT COUNT(*) FROM T1 PARTITION (P3);
SELECT COUNT(*) FROM T1 PARTITION (P4);
SELECT COUNT(*) FROM T1 PARTITION (P5);

ALTER TABLE T2 ADD PARTITION P5;

SELECT COUNT(*) FROM T2 PARTITION (P1) WHERE I1 < 1000 OR I1 IS NULL;
SELECT COUNT(*) FROM T2 PARTITION (P2) WHERE I1 < 1000 OR I1 IS NULL;
SELECT COUNT(*) FROM T2 PARTITION (P3) WHERE I1 < 1000 OR I1 IS NULL;
SELECT COUNT(*) FROM T2 PARTITION (P4) WHERE I1 < 1000 OR I1 IS NULL;
SELECT COUNT(*) FROM T2 PARTITION (P5) WHERE I1 < 1000 OR I1 IS NULL;

DROP TABLE TEST;


--##################################################################
--+SECTOR; FINALIZATION
--##################################################################
--+SKIP BEGIN;
DROP TABLE T1;
DROP TABLE T2;
DROP TABLE T3;
--+SKIP END;
