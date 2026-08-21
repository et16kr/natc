--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/PDT/Design/ALTER_TABLE/SPLIT/ListPartTable_Varchar.sql
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
--# ALTER TABLE ... SPLIT PARTITION (PartKey: VARCHAR)
--###################################################################

--###################################################################
--+SECTOR; PREPARATION
--###################################################################

--+SKIP BEGIN;
DROP TABLE T1;
DROP TABLE T2;
DROP TABLE T3;
--+SKIP END;

--+LOAD_SQL splitPartition_ListPartTable_Varchar_Schema_List_Varchar.sql;

--###################################################################
--+ SECTOR; 문법 체크
--###################################################################
-- should be fail
ALTER TABLE T1 
SPLIT PARTITION P1 AT ( '100' ) INTO
(
    PARTITION P1_1 TABLESPACE PDT_TBS2,
    PARTITION P1_2 TABLESPACE PDT_TBS3
);
    
-- should be fail
ALTER TABLE T1 
SPLIT PARTITION P1 VALUES ( '100' ) INTO
(
    PARTITION P1_1 TABLESPACE PDT_TBS2,
    PARTITION P1_2
) TABLESPACE PDT_TBS4;


--##############################
--+SECTOR; 파티션드 테이블인지 체크
--##############################
DROP TABLE TEST;
CREATE TABLE TEST( I1 INTEGER, I2 INTEGER );

-- should be fail
ALTER TABLE TEST 
SPLIT PARTITION P1 VALUES ('050') INTO
(
    PARTITION P1_1 TABLESPACE PDT_TBS2,
    PARTITION P1_2 TABLESPACE PDT_TBS3
);

DROP TABLE TEST;


--##############################
--+SECTOR; SrcPart 파티션 이름 체크
--##############################
-- should be fail
ALTER TABLE T1 
SPLIT PARTITION P5 VALUES ( '100' ) INTO
(
    PARTITION P1_1 TABLESPACE PDT_TBS2,
    PARTITION P1_2
);


--##############################
--+SECTOR; DstPart1, DstPart2의 TBS 체크
--##############################
--##############
--# Left In-place 
--##############
--+LOAD_SQL splitPartition_ListPartTable_Varchar_Schema_List_Varchar.sql;

ALTER TABLE T1 
SPLIT PARTITION P1 VALUES ( '050' ) INTO
(
    PARTITION P1,
    PARTITION P1_2 TABLESPACE PDT_TBS2
);

-- Result: PDT_TBS, PDT_TBS2, PDT_TBS, PDT_TBS, PDT_TBS
SELECT C.NAME
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ A, SYSTEM_.SYS_TABLES_ B, V$TABLESPACES C
WHERE A.TABLE_ID = B.TABLE_ID AND 
      A.TBS_ID = C.ID AND
      B.TABLE_NAME = 'T1'
ORDER BY A.PARTITION_NAME ASC;


ALTER TABLE T2 
SPLIT PARTITION P3 VALUES ('250' ) INTO
(
    PARTITION P3,
    PARTITION P3_2 TABLESPACE PDT_TBS2
);

-- Result: PDT_TBS2, PDT_TBS3, PDT_TBS, PDT_TBS2, PDT_TBS
SELECT C.NAME
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ A, SYSTEM_.SYS_TABLES_ B, V$TABLESPACES C
WHERE A.TABLE_ID = B.TABLE_ID AND 
      A.TBS_ID = C.ID AND
      B.TABLE_NAME = 'T2'
ORDER BY A.PARTITION_NAME ASC;


--##############
--# Right In-place 
--##############
--+LOAD_SQL splitPartition_ListPartTable_Varchar_Schema_List_Varchar.sql;

ALTER TABLE T1 
SPLIT PARTITION P1 VALUES ( '050' ) INTO
(
    PARTITION P1_1 TABLESPACE PDT_TBS2,
    PARTITION P1
);

-- Result: PDT_TBS, PDT_TBS2, PDT_TBS, PDT_TBS, PDT_TBS
SELECT C.NAME
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ A, SYSTEM_.SYS_TABLES_ B, V$TABLESPACES C
WHERE A.TABLE_ID = B.TABLE_ID AND 
      A.TBS_ID = C.ID AND
      B.TABLE_NAME = 'T1'
ORDER BY A.PARTITION_NAME ASC;


ALTER TABLE T2 
SPLIT PARTITION P3 VALUES ( '250' ) INTO
(
    PARTITION P3_1 TABLESPACE PDT_TBS2,
    PARTITION P3
);

-- Result: PDT_TBS2, PDT_TBS3, PDT_TBS, PDT_TBS2, PDT_TBS
SELECT C.NAME
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ A, SYSTEM_.SYS_TABLES_ B, V$TABLESPACES C
WHERE A.TABLE_ID = B.TABLE_ID AND 
      A.TBS_ID = C.ID AND
      B.TABLE_NAME = 'T2'
ORDER BY A.PARTITION_NAME ASC;


--##############
--# Out-place 
--##############
--+LOAD_SQL splitPartition_ListPartTable_Varchar_Schema_List_Varchar.sql;

ALTER TABLE T1 
SPLIT PARTITION P1 VALUES ( '050' ) INTO
(
    PARTITION P1_1 TABLESPACE PDT_TBS2,
    PARTITION P1_2 TABLESPACE PDT_TBS3
);

-- Result: PDT_TBS2, PDT_TBS3, PDT_TBS, PDT_TBS, PDT_TBS
SELECT C.NAME
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ A, SYSTEM_.SYS_TABLES_ B, V$TABLESPACES C
WHERE A.TABLE_ID = B.TABLE_ID AND 
      A.TBS_ID = C.ID AND
      B.TABLE_NAME = 'T1'
ORDER BY A.PARTITION_NAME ASC;


ALTER TABLE T2 
SPLIT PARTITION P3 VALUES ( '250' ) INTO
(
    PARTITION P3_1 TABLESPACE PDT_TBS2,
    PARTITION P3_2 TABLESPACE PDT_TBS3
);

-- Result: PDT_TBS2, PDT_TBS3, PDT_TBS2, PDT_TBS3, PDT_TBS
SELECT C.NAME
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ A, SYSTEM_.SYS_TABLES_ B, V$TABLESPACES C
WHERE A.TABLE_ID = B.TABLE_ID AND 
      A.TBS_ID = C.ID AND
      B.TABLE_NAME = 'T2'
ORDER BY A.PARTITION_NAME ASC;


--##############################
--+SECTOR; DstPart1, DstPart2의 LOB 컬럼의 TBS 체크
--##############################
--##############
--# Left In-place 
--##############
DROP TABLE T1;
CREATE TABLE T1 ( I1 INTEGER, I2 BLOB, I3 CLOB )
PARTITION BY LIST (I1) 
( PARTITION P1 VALUES ('100', '150') TABLESPACE PDT_TBS 
                                    LOB(I2, I3) STORE AS ( TABLESPACE PDT_TBS2 ), 
  PARTITION P2 VALUES ('200', '250') TABLESPACE PDT_TBS3,
  PARTITION P3 VALUES DEFAULT
) TABLESPACE PDT_TBS4 LOB(I3) STORE AS ( TABLESPACE PDT_TBS5 );

INSERT INTO T1 VALUES ( '100',   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( '150',   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( '200',   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( '250',   'ABC', 'DEF' );

ALTER TABLE T1
SPLIT PARTITION P1 VALUES ('100') INTO
(
    PARTITION P1,
    PARTITION P1_1 LOB STORE AS ( TABLESPACE PDT_TBS4 )
);

-- result: {100}
SELECT I1 FROM T1 PARTITION(P1);

-- result: {150}
SELECT I1 FROM T1 PARTITION(P1_1);

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

-- Result: PDT_TBS4
SELECT TBS.NAME
FROM SYSTEM_.SYS_TABLES_ TAB, SYSTEM_.SYS_TABLE_PARTITIONS_ PART, V$TABLESPACES TBS
WHERE TAB.TABLE_ID = PART.TABLE_ID AND
      PART.TBS_ID = TBS.ID AND
      TAB.TABLE_NAME = 'T1' AND
      PART.PARTITION_NAME = 'P1_1';

-- Result: PDT_TBS4, PDT_TBS4
SELECT TBS.NAME
FROM SYSTEM_.SYS_TABLES_ TAB, SYSTEM_.SYS_PART_LOBS_ LOBS, SYSTEM_.SYS_TABLE_PARTITIONS_ PART, V$TABLESPACES TBS
WHERE TAB.TABLE_ID = LOBS.TABLE_ID AND
      PART.PARTITION_ID = LOBS.PARTITION_ID AND
      LOBS.TBS_ID = TBS.ID AND
      TAB.TABLE_NAME = 'T1' AND
      PART.PARTITION_NAME = 'P1_1'
ORDER BY LOBS.COLUMN_ID ASC;


--##############
--# Right In-place 
--##############
DROP TABLE T1;
CREATE TABLE T1 ( I1 INTEGER, I2 BLOB, I3 CLOB )
PARTITION BY LIST (I1) 
( PARTITION P1 VALUES ('100','150') TABLESPACE PDT_TBS 
                                    LOB(I2, I3) STORE AS ( TABLESPACE PDT_TBS2 ), 
  PARTITION P2 VALUES ('200','250') TABLESPACE PDT_TBS3,
  PARTITION P3 VALUES DEFAULT
) TABLESPACE PDT_TBS4 LOB(I3) STORE AS ( TABLESPACE PDT_TBS5 );

INSERT INTO T1 VALUES ( '100',   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( '150',   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( '200',   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( '250',   'ABC', 'DEF' );

ALTER TABLE T1
SPLIT PARTITION P1 VALUES ('100') INTO
(
    PARTITION P1_1 TABLESPACE PDT_TBS2 LOB STORE AS ( TABLESPACE PDT_TBS4 ),
    PARTITION P1
);

-- result: {100}
SELECT I1 FROM T1 PARTITION(P1_1);

-- result: {150}
SELECT I1 FROM T1 PARTITION(P1);

-- result: PDT_TBS4
SELECT C.NAME
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ A, SYSTEM_.SYS_TABLES_ B, V$TABLESPACES C
WHERE A.TABLE_ID = B.TABLE_ID AND
      A.TBS_ID = C.ID AND
      B.TABLE_NAME = 'T1' AND
      A.PARTITION_NAME='P1_1';

-- BUGBUG
-- Result: PDT_TBS4, PDT_TBS4
SELECT TBS.NAME
FROM SYSTEM_.SYS_TABLES_ TAB, SYSTEM_.SYS_PART_LOBS_ LOBS, SYSTEM_.SYS_TABLE_PARTITIONS_ PART, V$TABLESPACES TBS
WHERE TAB.TABLE_ID = LOBS.TABLE_ID AND
      PART.PARTITION_ID = LOBS.PARTITION_ID AND
      LOBS.TBS_ID = TBS.ID AND
      TAB.TABLE_NAME = 'T1' AND
      PART.PARTITION_NAME = 'P1_1'
ORDER BY LOBS.COLUMN_ID ASC;

-- BUGBUG
-- Result: PDT_TBS
SELECT TBS.NAME
FROM SYSTEM_.SYS_TABLES_ TAB, SYSTEM_.SYS_TABLE_PARTITIONS_ PART, V$TABLESPACES TBS
WHERE TAB.TABLE_ID = PART.TABLE_ID AND
      PART.TBS_ID = TBS.ID AND
      TAB.TABLE_NAME = 'T1' AND
      PART.PARTITION_NAME = 'P1';

-- BUGBUG
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
--# Out-place 
--##############
DROP TABLE T1;
CREATE TABLE T1 ( I1 INTEGER, I2 BLOB, I3 CLOB )
PARTITION BY LIST (I1) 
( PARTITION P1 VALUES ('100','150') TABLESPACE PDT_TBS 
                                    LOB(I2, I3) STORE AS ( TABLESPACE PDT_TBS2 ), 
  PARTITION P2 VALUES ('200','250') TABLESPACE PDT_TBS3,
  PARTITION P3 VALUES DEFAULT
) TABLESPACE PDT_TBS4 LOB(I3) STORE AS ( TABLESPACE PDT_TBS5 );

INSERT INTO T1 VALUES ( '100',   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( '150',   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( '200',   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( '250',   'ABC', 'DEF' );

ALTER TABLE T1
SPLIT PARTITION P1 VALUES ('100') INTO
(
    PARTITION P1_1 TABLESPACE PDT_TBS2 LOB(I3) STORE AS ( TABLESPACE PDT_TBS3 ),
    PARTITION P1_2 LOB STORE AS ( TABLESPACE PDT_TBS5 )
);

-- result: {100}
SELECT I1 FROM T1 PARTITION(P1_1);

-- result: {150}
SELECT I1 FROM T1 PARTITION(P1_2);

-- result: PDT_TBS2
SELECT C.NAME
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ A, SYSTEM_.SYS_TABLES_ B, V$TABLESPACES C
WHERE A.TABLE_ID = B.TABLE_ID AND
      A.TBS_ID = C.ID AND
      B.TABLE_NAME = 'T1' AND
      A.PARTITION_NAME='P1_1';

-- BUGBUG
-- Result: PDT_TBS2, PDT_TBS3
SELECT TBS.NAME
FROM SYSTEM_.SYS_TABLES_ TAB, SYSTEM_.SYS_PART_LOBS_ LOBS, SYSTEM_.SYS_TABLE_PARTITIONS_ PART, V$TABLESPACES TBS
WHERE TAB.TABLE_ID = LOBS.TABLE_ID AND
      PART.PARTITION_ID = LOBS.PARTITION_ID AND
      LOBS.TBS_ID = TBS.ID AND
      TAB.TABLE_NAME = 'T1' AND
      PART.PARTITION_NAME = 'P1_1'
ORDER BY LOBS.COLUMN_ID ASC;

-- Result: PDT_TBS4
SELECT TBS.NAME
FROM SYSTEM_.SYS_TABLES_ TAB, SYSTEM_.SYS_TABLE_PARTITIONS_ PART, V$TABLESPACES TBS
WHERE TAB.TABLE_ID = PART.TABLE_ID AND
      PART.TBS_ID = TBS.ID AND
      TAB.TABLE_NAME = 'T1' AND
      PART.PARTITION_NAME = 'P1_2';

-- BUGBUG
-- Result: PDT_TBS5, PDT_TBS5
SELECT TBS.NAME
FROM SYSTEM_.SYS_TABLES_ TAB, SYSTEM_.SYS_PART_LOBS_ LOBS, SYSTEM_.SYS_TABLE_PARTITIONS_ PART, V$TABLESPACES TBS
WHERE TAB.TABLE_ID = LOBS.TABLE_ID AND
      PART.PARTITION_ID = LOBS.PARTITION_ID AND
      LOBS.TBS_ID = TBS.ID AND
      TAB.TABLE_NAME = 'T1' AND
      PART.PARTITION_NAME = 'P1_2'
ORDER BY LOBS.COLUMN_ID ASC;



--###################################################################
--+ SECTOR; 파티션 분할 기준 값 체크
--###################################################################

--##############################
--+SECTOR; 분할 개수 체크
--##############################
--+LOAD_SQL splitPartition_ListPartTable_Varchar_Schema_List_Varchar.sql;

-- should be fail
ALTER TABLE T1 
SPLIT PARTITION P3 VALUES ('200', '250', '275') INTO
( 
    PARTITION P3_1,
    PARTITION P3_2
);

-- should be fail
ALTER TABLE T2 
SPLIT PARTITION P3 VALUES ('200', '100') INTO
( 
    PARTITION P3_1,
    PARTITION P3_2
);

-- should be success
ALTER TABLE T1 
SPLIT PARTITION P3 VALUES ('275', '200') INTO
( 
    PARTITION P3_1,
    PARTITION P3_2
);

-- result: 3
SELECT COUNT(*) FROM T1 PARTITION (P1);
-- result: 4
SELECT COUNT(*) FROM T1 PARTITION (P2);
-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P3_1);
-- result: 1
SELECT COUNT(*) FROM T1 PARTITION (P3_2);
-- result: 3
SELECT COUNT(*) FROM T1 PARTITION (P4);

-- should be success
ALTER TABLE T2 
SPLIT PARTITION P3 VALUES ('275','250') INTO
( 
    PARTITION P3_1,
    PARTITION P3_2
);

-- result: 3
SELECT COUNT(*) FROM T2 PARTITION (P1);
-- result: 4
SELECT COUNT(*) FROM T2 PARTITION (P2);
-- result: 2
SELECT COUNT(*) FROM T2 PARTITION (P3_1);
-- result: 1
SELECT COUNT(*) FROM T2 PARTITION (P3_2);
-- result: 3
SELECT COUNT(*) FROM T2 PARTITION (P4);


--##############################
--+SECTOR; 분할 값의 길이 체크
--##############################
-- PartKey: VARCHAR

--##############################
--+SECTOR; SrcPart에 속하는지 체크
--##############################
--+LOAD_SQL splitPartition_ListPartTable_Varchar_Schema_List_Varchar.sql;

-- should be fail
ALTER TABLE T1 
SPLIT PARTITION P1 VALUES ('100') INTO
( 
    PARTITION P1_1,
    PARTITION P1_2
);

-- should be fail
ALTER TABLE T1 
SPLIT PARTITION P1 VALUES ('050',' 050') INTO
( 
    PARTITION P1_1,
    PARTITION P1_2
);

-- should be fail
ALTER TABLE T1 
SPLIT PARTITION P1 VALUES ('075', '000', '050') INTO
( 
    PARTITION P1_1,
    PARTITION P1_2
);

-- should be fail
ALTER TABLE T1 
SPLIT PARTITION P2 VALUES ('200') INTO
( 
    PARTITION P2_1,
    PARTITION P2_2
);

-- should be success
ALTER TABLE T1 
SPLIT PARTITION P3 VALUES ('250') INTO
( 
    PARTITION P3_1,
    PARTITION P3_2
);

-- should be success
ALTER TABLE T1 
SPLIT PARTITION P2 VALUES ('175', NULL) INTO
( 
    PARTITION P2_1,
    PARTITION P2_2
);


-- should be fail
ALTER TABLE T2 
SPLIT PARTITION P1 VALUES ('100', '100') INTO
( 
    PARTITION P1_1,
    PARTITION P1_2
);

-- should be fail
ALTER TABLE T2 
SPLIT PARTITION P1 VALUES ('050', '050') INTO
(
    PARTITION P1_1,
    PARTITION P1_2
);

-- should be fail
ALTER TABLE T2 
SPLIT PARTITION P2 VALUES ('200', '100') INTO
( 
    PARTITION P2_1,
    PARTITION P2_2
);

-- should be fail
ALTER TABLE T2 
SPLIT PARTITION P3 VALUES ('250', '100') INTO
( 
    PARTITION P3_1,
    PARTITION P3_2
);

-- should be success
ALTER TABLE T2 
SPLIT PARTITION P2 VALUES ('100', NULL) INTO
( 
    PARTITION P2_1,
    PARTITION P2_2
);

-- should be fail
ALTER TABLE T2 
SPLIT PARTITION P4 VALUES (NULL) INTO
( 
    PARTITION P4_1,
    PARTITION P4_2
);

-- should be fail
ALTER TABLE T2 
SPLIT PARTITION P4 VALUES ('350', NULL) INTO
( 
    PARTITION P4_1,
    PARTITION P4_2
);



--###################################################################
--+ SECTOR; DstPart1, DstPart2 이름 체크
--###################################################################
--##############################
--+SECTOR; Left In-place
--##############################
--+LOAD_SQL splitPartition_ListPartTable_Varchar_Schema_List_Varchar.sql;

-- should be fail
ALTER TABLE T1 
SPLIT PARTITION P1 VALUES ('050') INTO
( 
    PARTITION P1,
    PARTITION P1
);

-- should be fail
ALTER TABLE T1 
SPLIT PARTITION P1 VALUES ('050') INTO
( 
    PARTITION P1,
    PARTITION P1 TABLESPACE PDT_TBS2
);

-- should be fail
ALTER TABLE T1 
SPLIT PARTITION P1 VALUES ('050') INTO
( 
    PARTITION P1,
    PARTITION P3
);

-- should be fail
ALTER TABLE T1 
SPLIT PARTITION P1 VALUES ('050') INTO
( 
    PARTITION P1,
    PARTITION P3 TABLESPACE PDT_TBS2
);


--##############################
--+SECTOR; Right In-place
--##############################
-- should be fail
ALTER TABLE T1 
SPLIT PARTITION P1 VALUES ('050') INTO
( 
    PARTITION P1,
    PARTITION P1
);

-- should be fail
ALTER TABLE T1 
SPLIT PARTITION P1 VALUES ('050') INTO
( 
    PARTITION P1 TABLESPACE PDT_TBS2,
    PARTITION P1
);

-- should be fail
ALTER TABLE T1 
SPLIT PARTITION P1 VALUES ('050') INTO
( 
    PARTITION P3,
    PARTITION P1
);

-- should be fail
ALTER TABLE T1 
SPLIT PARTITION P1 VALUES ('050') INTO
( 
    PARTITION P3 TABLESPACE PDT_TBS2,
    PARTITION P1
);


--##############################
--+SECTOR; Out-place
--##############################
-- should be fail
ALTER TABLE T1 
SPLIT PARTITION P1 VALUES ('050') INTO
( 
    PARTITION P1 TABLESPACE PDT_TBS2,
    PARTITION P1 TABLESPACE PDT_TBS3
);

-- should be fail
ALTER TABLE T1 
SPLIT PARTITION P1 VALUES ('050') INTO
( 
    PARTITION P3,
    PARTITION P1 TABLESPACE PDT_TBS2
);

-- should be fail
ALTER TABLE T1 
SPLIT PARTITION P1 VALUES ('050') INTO
( 
    PARTITION P1 TABLESPACE PDT_TBS2,
    PARTITION P3
);

-- should be fail
ALTER TABLE T1 
SPLIT PARTITION P1 VALUES ('050') INTO
( 
    PARTITION P1 TABLESPACE PDT_TBS2,
    PARTITION P3 TABLESPACE PDT_TBS3
);

-- should be fail
ALTER TABLE T1 
SPLIT PARTITION P1 VALUES ('050') INTO
( 
    PARTITION P3,
    PARTITION P3
);

-- should be fail
ALTER TABLE T1 
SPLIT PARTITION P1 VALUES ('050') INTO
( 
    PARTITION P3,
    PARTITION P3 TABLESPACE PDT_TBS2
);



--###################################################################
--+ SECTOR; SrcPart의 타입에 따른 분할
--###################################################################

--##############################
--+SECTOR; 기본 파티션이 아닌 파티션
--##############################
--##############
--# Left In-place 
--##############
--+LOAD_SQL splitPartition_ListPartTable_Varchar_Schema_List_Varchar.sql;
ALTER TABLE T1 
SPLIT PARTITION P2 VALUES ('150') INTO
( 
    PARTITION P2,
    PARTITION P2_1
);

-- Result: 
-- P1,   {0,50,75}
-- P2,   {150}
-- P2_1, {100, 175, NULL}
-- P3,   {200, 250, 275}
-- P4,   {}
SELECT PART.PARTITION_NAME, PART.PARTITION_MIN_VALUE
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ PART,
     SYSTEM_.SYS_TABLES_ TAB
WHERE TAB.TABLE_ID = PART.TABLE_ID AND
      TAB.TABLE_NAME='T1'
ORDER BY PART.PARTITION_NAME;

-- result: 3
SELECT COUNT(*) FROM T1 PARTITION (P1);
-- result: 1
SELECT COUNT(*) FROM T1 PARTITION (P2);
-- result: 3
SELECT COUNT(*) FROM T1 PARTITION (P2_1);
-- result: 3
SELECT COUNT(*) FROM T1 PARTITION (P3);
-- result: 3
SELECT COUNT(*) FROM T1 PARTITION (P4);

-- result: 0
SELECT COUNT(*)
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ PART,
     SYSTEM_.SYS_TABLES_ TAB
WHERE TAB.TABLE_ID = PART.TABLE_ID AND
      TAB.TABLE_NAME='T1' AND
      PART.PARTITION_MIN_VALUE <> PART.PARTITION_MAX_VALUE;

--##############
--# Right In-place 
--##############
--+LOAD_SQL splitPartition_ListPartTable_Varchar_Schema_List_Varchar.sql;
ALTER TABLE T1 
SPLIT PARTITION P2 VALUES ('150') INTO
( 
    PARTITION P2_1,
    PARTITION P2
);

-- Result: 
-- P1,   {0,50,75}
-- P2,   {100,175,NULL}
-- P2_1, {150}
-- P3,   {200, 250, 275}
-- P4,   {}
SELECT PART.PARTITION_NAME, PART.PARTITION_MIN_VALUE, PART.PARTITION_MAX_VALUE
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ PART,
     SYSTEM_.SYS_TABLES_ TAB
WHERE TAB.TABLE_ID = PART.TABLE_ID AND
      TAB.TABLE_NAME='T1'
ORDER BY PART.PARTITION_NAME;

-- result: 3
SELECT COUNT(*) FROM T1 PARTITION (P1);
-- result: 3
SELECT COUNT(*) FROM T1 PARTITION (P2);
-- result: 1
SELECT COUNT(*) FROM T1 PARTITION (P2_1);
-- result: 3
SELECT COUNT(*) FROM T1 PARTITION (P3);
-- result: 3
SELECT COUNT(*) FROM T1 PARTITION (P4);

-- result: 0
SELECT COUNT(*)
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ PART,
     SYSTEM_.SYS_TABLES_ TAB
WHERE TAB.TABLE_ID = PART.TABLE_ID AND
      TAB.TABLE_NAME='T1' AND
      PART.PARTITION_MIN_VALUE <> PART.PARTITION_MAX_VALUE;

--##############
--# Out-place 
--##############
--+LOAD_SQL splitPartition_ListPartTable_Varchar_Schema_List_Varchar.sql;
ALTER TABLE T1 
SPLIT PARTITION P2 VALUES ('150', NULL) INTO
( 
    PARTITION P2_1,
    PARTITION P2_2
);

-- Result: 
-- P1,   {0,50,75}
-- P2_1, {150,NULL}
-- P2_2, {100,175}
-- P3,   {200, 250, 275}
-- P4,   {}
SELECT PART.PARTITION_NAME, PART.PARTITION_MIN_VALUE, PART.PARTITION_MAX_VALUE
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ PART,
     SYSTEM_.SYS_TABLES_ TAB
WHERE TAB.TABLE_ID = PART.TABLE_ID AND
      TAB.TABLE_NAME='T1'
ORDER BY PART.PARTITION_NAME;

-- result: 3
SELECT COUNT(*) FROM T1 PARTITION (P1);
-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P2_1);
-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P2_2);
-- result: 3
SELECT COUNT(*) FROM T1 PARTITION (P3);
-- result: 3
SELECT COUNT(*) FROM T1 PARTITION (P4);

-- result: 0
SELECT COUNT(*)
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ PART,
     SYSTEM_.SYS_TABLES_ TAB
WHERE TAB.TABLE_ID = PART.TABLE_ID AND
      TAB.TABLE_NAME='T1' AND
      PART.PARTITION_MIN_VALUE <> PART.PARTITION_MAX_VALUE;


--##############################
--+SECTOR; 기본 파티션
--##############################
--##############
--# Left In-place 
--##############
--+LOAD_SQL splitPartition_ListPartTable_Varchar_Schema_List_Varchar.sql;
ALTER TABLE T1 
SPLIT PARTITION P4 VALUES ('375','300') INTO
( 
    PARTITION P4,
    PARTITION P4_1
);

-- Result: 
-- P1,   {0,50,75}
-- P2,   {100,150,175,NULL}
-- P3,   {200, 250, 275}
-- P4,   {375,300}
-- P4_1, {}
SELECT PART.PARTITION_NAME, PART.PARTITION_MIN_VALUE, PART.PARTITION_MAX_VALUE
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ PART,
     SYSTEM_.SYS_TABLES_ TAB
WHERE TAB.TABLE_ID = PART.TABLE_ID AND
      TAB.TABLE_NAME='T1'
ORDER BY PART.PARTITION_NAME;

-- result: 3
SELECT COUNT(*) FROM T1 PARTITION (P1);
-- result: 4
SELECT COUNT(*) FROM T1 PARTITION (P2);
-- result: 3
SELECT COUNT(*) FROM T1 PARTITION (P3);
-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P4);
-- result: 1
SELECT COUNT(*) FROM T1 PARTITION (P4_1);

-- result: 0
SELECT COUNT(*)
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ PART,
     SYSTEM_.SYS_TABLES_ TAB
WHERE TAB.TABLE_ID = PART.TABLE_ID AND
      TAB.TABLE_NAME='T1' AND
      PART.PARTITION_MIN_VALUE <> PART.PARTITION_MAX_VALUE;

--##############
--# Right In-place 
--##############
--+LOAD_SQL splitPartition_ListPartTable_Varchar_Schema_List_Varchar.sql;
ALTER TABLE T1 
SPLIT PARTITION P4 VALUES ('375','300') INTO
( 
    PARTITION P4_1,
    PARTITION P4
);

-- Result: 
-- P1,   {0,50,75}
-- P2,   {100,150,175,NULL}
-- P3,   {200, 250, 275}
-- P4_1, {375,300}
-- P4,   {350}
SELECT PART.PARTITION_NAME, PART.PARTITION_MIN_VALUE, PART.PARTITION_MAX_VALUE
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ PART,
     SYSTEM_.SYS_TABLES_ TAB
WHERE TAB.TABLE_ID = PART.TABLE_ID AND
      TAB.TABLE_NAME='T1'
ORDER BY PART.PARTITION_NAME;

-- result: 3
SELECT COUNT(*) FROM T1 PARTITION (P1);
-- result: 3
SELECT COUNT(*) FROM T1 PARTITION (P2);
-- result: 3
SELECT COUNT(*) FROM T1 PARTITION (P3);
-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P4);
-- result: 1
SELECT COUNT(*) FROM T1 PARTITION (P4_1);

-- result: 0
SELECT COUNT(*)
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ PART,
     SYSTEM_.SYS_TABLES_ TAB
WHERE TAB.TABLE_ID = PART.TABLE_ID AND
      TAB.TABLE_NAME='T1' AND
      PART.PARTITION_MIN_VALUE <> PART.PARTITION_MAX_VALUE;

--##############
--# Out-place 
--##############
--+LOAD_SQL splitPartition_ListPartTable_Varchar_Schema_List_Varchar.sql;
ALTER TABLE T1 
SPLIT PARTITION P4 VALUES ('375','300') INTO
( 
    PARTITION P4_1,
    PARTITION P4_2
);

-- Result: 
-- P1,   {0,50,75}
-- P2,   {100,150,175,NULL}
-- P3,   {200, 250, 275}
-- P4_1, {375,300}
-- P4_2, {}
SELECT PART.PARTITION_NAME, PART.PARTITION_MIN_VALUE, PART.PARTITION_MAX_VALUE
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ PART,
     SYSTEM_.SYS_TABLES_ TAB
WHERE TAB.TABLE_ID = PART.TABLE_ID AND
      TAB.TABLE_NAME='T1'
ORDER BY PART.PARTITION_NAME;

-- result: 3
SELECT COUNT(*) FROM T1 PARTITION (P1);
-- result: 4
SELECT COUNT(*) FROM T1 PARTITION (P2);
-- result: 3
SELECT COUNT(*) FROM T1 PARTITION (P3);
-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P4_1);
-- result: 1
SELECT COUNT(*) FROM T1 PARTITION (P4_2);

-- result: 0
SELECT COUNT(*)
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ PART,
     SYSTEM_.SYS_TABLES_ TAB
WHERE TAB.TABLE_ID = PART.TABLE_ID AND
      TAB.TABLE_NAME='T1' AND
      PART.PARTITION_MIN_VALUE <> PART.PARTITION_MAX_VALUE;



--###################################################################
--+ SECTOR; 계속 분할 테스트
--###################################################################
--+LOAD_SQL splitPartition_ListPartTable_Varchar_Schema_List_Varchar.sql;

--##############################
--+SECTOR; Test for Table T1 (no index, single part key)
--##############################
-- should be success
ALTER TABLE T1 
SPLIT PARTITION P1 VALUES ('050') INTO
( 
    PARTITION P1,
    PARTITION P1_1
);

-- should be success
ALTER TABLE T1 
SPLIT PARTITION P2 VALUES ('150') INTO
( 
    PARTITION P2_1,
    PARTITION P2_2
);

-- should be success
ALTER TABLE T1 
SPLIT PARTITION P2_2 VALUES (NULL) INTO
( 
    PARTITION P2_2_1,
    PARTITION P2_2_2
);

-- should be success
ALTER TABLE T1 
SPLIT PARTITION P3 VALUES ('250') INTO
( 
    PARTITION P3_1,
    PARTITION P3
);

-- should be fail
ALTER TABLE T1 
SPLIT PARTITION P1_1 VALUES ('075', 0) INTO
( 
    PARTITION P1_1_1,
    PARTITION P1_1_2
);

-- should be success
ALTER TABLE T1 
SPLIT PARTITION P1_1 VALUES ('075') INTO
( 
    PARTITION P1_1_1,
    PARTITION P1_1_2
);

-- should be fail
ALTER TABLE T1 
SPLIT PARTITION P3_1 VALUES ('250') INTO
( 
    PARTITION P3_1_1,
    PARTITION P3_1
);

-- should be success
ALTER TABLE T1
SPLIT PARTITION P3 VALUES ('200') INTO
( 
    PARTITION P3_2,
    PARTITION P3_3
);

-- should be success
ALTER TABLE T1 
SPLIT PARTITION P4 VALUES ('300', '350') INTO
( 
    PARTITION P4,
    PARTITION P4_1
);

-- result: 1
SELECT COUNT(*) FROM T1 PARTITION (P1);
-- result: 1
SELECT COUNT(*) FROM T1 PARTITION (P1_1_1);
-- result: 1
SELECT COUNT(*) FROM T1 PARTITION (P1_1_2);
-- result: 1
SELECT COUNT(*) FROM T1 PARTITION (P2_1);
-- result: 1
SELECT COUNT(*) FROM T1 PARTITION (P2_2_1);
-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P2_2_2);
-- result: 1
SELECT COUNT(*) FROM T1 PARTITION (P3_2);
-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P3_3);
-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P4);
-- result: 1
SELECT COUNT(*) FROM T1 PARTITION (P4_1);


--##############################
--+SECTOR; Test for Table T2 (multi key index, multi part key)
--##############################
-- should be success
ALTER TABLE T2 
SPLIT PARTITION P1 VALUES ('050') INTO
( 
    PARTITION P1,
    PARTITION P1_1
);

-- should be success
ALTER TABLE T2 
SPLIT PARTITION P2 VALUES ('150') INTO
( 
    PARTITION P2_1,
    PARTITION P2_2
);

-- should be success
ALTER TABLE T2 
SPLIT PARTITION P2_2 VALUES (NULL) INTO
( 
    PARTITION P2_2_1,
    PARTITION P2_2_2
);

-- should be success
ALTER TABLE T2 
SPLIT PARTITION P3 VALUES ('250') INTO
( 
    PARTITION P3_1,
    PARTITION P3
);

-- should be fail
ALTER TABLE T2 
SPLIT PARTITION P1_1 VALUES ('075', '000') INTO
( 
    PARTITION P1_1_1,
    PARTITION P1_1_2
);

-- should be success
ALTER TABLE T2 
SPLIT PARTITION P1_1 VALUES ('075') INTO
( 
    PARTITION P1_1_1,
    PARTITION P1_1_2
);

-- should be fail
ALTER TABLE T2 
SPLIT PARTITION P3_1 VALUES ('250') INTO
( 
    PARTITION P3_1_1,
    PARTITION P3_1
);

-- should be success
ALTER TABLE T2 
SPLIT PARTITION P3 VALUES ('200') INTO
( 
    PARTITION P3_2,
    PARTITION P3_3
);

-- should be success
ALTER TABLE T2 
SPLIT PARTITION P4 VALUES ('300', '350') INTO
( 
    PARTITION P4,
    PARTITION P4_1
);

-- result: 1
SELECT COUNT(*) FROM T2 PARTITION (P1);
-- result: 1
SELECT COUNT(*) FROM T2 PARTITION (P1_1_1);
-- result: 1
SELECT COUNT(*) FROM T2 PARTITION (P1_1_2);
-- result: 1
SELECT COUNT(*) FROM T2 PARTITION (P2_1);
-- result: 1
SELECT COUNT(*) FROM T2 PARTITION (P2_2_1);
-- result: 2
SELECT COUNT(*) FROM T2 PARTITION (P2_2_2);
-- result: 1
SELECT COUNT(*) FROM T2 PARTITION (P3_2);
-- result: 2
SELECT COUNT(*) FROM T2 PARTITION (P3_3);
-- result: 2
SELECT COUNT(*) FROM T2 PARTITION (P4);
-- result: 1
SELECT COUNT(*) FROM T2 PARTITION (P4_1);



--##################################################################
--+SECTOR; FINALIZATION
--##################################################################
--+SKIP BEGIN;
DROP TABLE T1;
DROP TABLE T2;
DROP TABLE T3;
--+SKIP END;
