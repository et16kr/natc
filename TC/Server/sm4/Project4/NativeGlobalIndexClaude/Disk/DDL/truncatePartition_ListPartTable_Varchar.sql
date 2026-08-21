--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/PDT/Design/ALTER_TABLE/TRUNCATE/ListPartTable_Varchar.sql
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
--# ALTER TABLE ... TRUNCATE PARTITION (PartKey: VARCHAR)
--###################################################################

--###################################################################
--+SECTOR; PREPARATION
--###################################################################

--+SKIP BEGIN;
DROP TABLE T1;
DROP TABLE T2;
DROP TABLE T3;
--+SKIP END;

--+APPEND_LST truncatePartition_ListPartTable_Varchar_Schema_List_Varchar.sql;
--+SYSTEM is -silent -f truncatePartition_ListPartTable_Varchar_Schema_List_Varchar.sql;

--###################################################################
--+ SECTOR; BASIC TEST
--###################################################################
--##############################
--+SECTOR; 문법 체크
--##############################
DROP TABLE TEST;
CREATE TABLE TEST( I1 VARCHAR(1000), I2 INTEGER )
PARTITION BY LIST(I1)
(
    PARTITION P1 VALUES ('100'),
    PARTITION P2 VALUES ('200'),
    PARTITION P3 VALUES ('300'),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS;

-- should be fail
ALTER TABLE TEST 
TRUNCATE PARTITION P1_1 TABLESPACE PDT_TBS2;

DROP TABLE TEST;

--##############################
--+SECTOR; 파티션드 테이블인지 체크
--##############################
DROP TABLE TEST;
CREATE TABLE TEST( I1 VARCHAR(1000), I2 INTEGER );

-- should be fail
ALTER TABLE TEST 
TRUNCATE PARTITION P1_1;

DROP TABLE TEST;


--##############################
--+SECTOR; 파티션 이름 체크
--##############################
--+SYSTEM is -silent -f truncatePartition_ListPartTable_Varchar_Schema_List_Varchar.sql;

-- should be fail
ALTER TABLE T1 
TRUNCATE PARTITION P5;

-- should be success
ALTER TABLE T1 
TRUNCATE PARTITION P4;

-- should be success
ALTER TABLE T1 
TRUNCATE PARTITION P3;

-- should be success
ALTER TABLE T1 
TRUNCATE PARTITION P2;

-- should be success
ALTER TABLE T1 
TRUNCATE PARTITION P1;



--##############################
--+SECTOR; LOB 컬럼이 있는 경우의 TRUNCATE PARTITION
--##############################
DROP TABLE T1;
CREATE TABLE T1 ( I1 VARCHAR(1000), I2 BLOB, I3 CLOB )
PARTITION BY LIST(I1) 
( PARTITION P1 VALUES ('100', '150') TABLESPACE PDT_TBS 
                        LOB(I2, I3) STORE AS ( TABLESPACE PDT_TBS2 ), 
  PARTITION P2 VALUES ('200', '250') TABLESPACE PDT_TBS3,
  PARTITION P3 VALUES DEFAULT
) TABLESPACE PDT_TBS4 LOB(I3) STORE AS ( TABLESPACE PDT_TBS5 );

INSERT INTO T1 VALUES ( '100',   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( '150',   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( '200',   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( '250',   'ABC', 'DEF' );

-- should be success
ALTER TABLE T1
TRUNCATE PARTITION P3;

-- result: 4
SELECT COUNT(*) FROM T1;

ALTER TABLE T1
TRUNCATE PARTITION P2;

-- result: 2
SELECT COUNT(*) FROM T1;

ALTER TABLE T1
TRUNCATE PARTITION P1;

-- result: 0
SELECT COUNT(*) FROM T1;



--##################################################################
--+SECTOR; 인덱스 검사
--##################################################################
--+SYSTEM is -silent -f truncatePartition_ListPartTable_Varchar_Schema_List_Varchar.sql;

-- result: 000, 100, 100
SELECT /* INDEX ASC ( T2, IDX1 ) */ *
FROM T2 LIMIT 1;

ALTER TABLE T2
TRUNCATE PARTITION P1;

ALTER TABLE T2
TRUNCATE PARTITION P2;

ALTER TABLE T2
TRUNCATE PARTITION P3;

ALTER TABLE T2
TRUNCATE PARTITION P4;

INSERT INTO T2 VALUES ('000', '350', 444 );
INSERT INTO T2 VALUES ('050', '300', 111);
INSERT INTO T2 VALUES ('100', '250', 555);
INSERT INTO T2 VALUES ('150', '200', 888);
INSERT INTO T2 VALUES ('200', '150', 777);
INSERT INTO T2 VALUES ('250', '100', 666);
INSERT INTO T2 VALUES ('300', '050', 333);
INSERT INTO T2 VALUES ('350', '000', 222);

-- result: 000, 350, 444
SELECT /* INDEX ASC ( T2, IDX1 ) */ *
FROM T2 LIMIT 1;

-- result: 050, 350, 111
SELECT /* INDEX ASC ( T2, IDX2 ) */ *
FROM T2 LIMIT 1;

-- result: 350, 000, 222
SELECT /* INDEX ASC ( T2, IDX3 ) */ *
FROM T2 LIMIT 1;



--##################################################################
--+SECTOR; FINALIZATION
--##################################################################
--+SKIP BEGIN;
DROP TABLE T1;
DROP TABLE T2;
DROP TABLE T3;
--+SKIP END;
