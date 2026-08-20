--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/PDT/Design/ALTER_TABLE/ROW_MOVEMENT/RangePartTable_Varchar.sql
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
--# ALTER TABLE ... ENABLE/DISABLE ROWMOVEMENT(PartKey: VARCHAR)
--###################################################################

--###################################################################
--+SECTOR; PREPARATION
--###################################################################

--+SKIP BEGIN;
DROP TABLE T1;
DROP TABLE T2;
DROP TABLE T3;
--+SKIP END;

--+APPEND_LST rowMovement_RangePartTable_Varchar_Schema_Range_Varchar.sql;
--+SYSTEM is -silent -f rowMovement_RangePartTable_Varchar_Schema_Range_Varchar.sql;

--###################################################################
--+ SECTOR; BASIC TEST
--###################################################################
--##############################
--+SECTOR; 문법 체크
--##############################
DROP TABLE TEST;

-- should be fail
CREATE TABLE TEST( I1 VARCHAR(1000), I2 INTEGER )
PARTITION BY RANGE(I1)
(
    PARTITION P1 VALUES LESS THAN ('100'),
    PARTITION P2 VALUES LESS THAN ('200'),
    PARTITION P3 VALUES LESS THAN ('300'),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS ENABLE ROW MOVEMENT;

-- should be fail
CREATE TABLE TEST( I1 VARCHAR(1000), I2 INTEGER )
PARTITION BY RANGE(I1)
(
    PARTITION P1 VALUES LESS THAN ('100'),
    PARTITION P2 VALUES LESS THAN ('200'),
    PARTITION P3 VALUES LESS THAN ('300') ENABLE ROW MOVEMENT,
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS;

-- should be success
CREATE TABLE TEST( I1 VARCHAR(1000), I2 INTEGER )
PARTITION BY RANGE(I1)
(
    PARTITION P1 VALUES LESS THAN ('100'),
    PARTITION P2 VALUES LESS THAN ('200'),
    PARTITION P3 VALUES LESS THAN ('300'),
    PARTITION P4 VALUES DEFAULT
) ENABLE ROW MOVEMENT TABLESPACE PDT_TBS;


--##############################
--+SECTOR; 파티션의 개수
--##############################
--#############
--# 4개
--#############
--+SYSTEM is -silent -f rowMovement_RangePartTable_Varchar_Schema_Range_Varchar.sql;

ALTER TABLE T1
ENABLE ROW MOVEMENT;

UPDATE T1 SET I1 = I1 + '050';

-- result: 0
SELECT COUNT(*) FROM T1 PARTITION (P1);
-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P2);
-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P3);
-- result: 4
SELECT COUNT(*) FROM T1 PARTITION (P4);


ALTER TABLE T2
ENABLE ROW MOVEMENT;

UPDATE T2 SET I1 = I1 + '050';

-- result: 0
SELECT COUNT(*) FROM T2 PARTITION (P1);
-- result: 2
SELECT COUNT(*) FROM T2 PARTITION (P2);
-- result: 2
SELECT COUNT(*) FROM T2 PARTITION (P3);
-- result: 4
SELECT COUNT(*) FROM T2 PARTITION (P4);

--#############
--# 1개
--#############
--+SYSTEM is -silent -f rowMovement_RangePartTable_Varchar_Schema_Range_Varchar.sql;

ALTER TABLE T1
ENABLE ROW MOVEMENT;

ALTER TABLE T1 
MERGE PARTITIONS P1, P2 INTO PARTITION P1;

ALTER TABLE T1 
MERGE PARTITIONS P3, P4 INTO PARTITION P3;

ALTER TABLE T1 
MERGE PARTITIONS P1, P3 INTO PARTITION P1;

UPDATE T1 SET I1 = I1 + '050';

-- result: 8
SELECT COUNT(*) FROM T1;


ALTER TABLE T2
ENABLE ROW MOVEMENT;

ALTER TABLE T2 
MERGE PARTITIONS P1, P2 INTO PARTITION P1;

ALTER TABLE T2 
MERGE PARTITIONS P3, P4 INTO PARTITION P3;

ALTER TABLE T2 
MERGE PARTITIONS P1, P3 INTO PARTITION P1;

UPDATE T2 SET I1 = I1 + '050';

-- result: 8
SELECT COUNT(*) FROM T2;


--##############################
--+SECTOR; LOB 컬럼이 있는 경우
--##############################
DROP TABLE T1;
CREATE TABLE T1 ( I1 VARCHAR(1000), I2 BLOB, I3 CLOB )
PARTITION BY RANGE(I1) 
( PARTITION P1 VALUES LESS THAN ('100') TABLESPACE PDT_TBS 
                        LOB(I2, I3) STORE AS ( TABLESPACE PDT_TBS2 ), 
  PARTITION P2 VALUES LESS THAN ('200') TABLESPACE PDT_TBS3,
  PARTITION P3 VALUES LESS THAN ('300') TABLESPACE PDT_TBS4,
  PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS4 LOB(I3) STORE AS ( TABLESPACE PDT_TBS5 );

CREATE INDEX IDX_LOB ON T1(I1);

INSERT INTO T1 VALUES ( '000',   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( '050',   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( '100',   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( '150',   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( '200',   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( '250',   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( '300',   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( '350',   'ABC', 'DEF' );

ALTER TABLE T1
ENABLE ROW MOVEMENT;

UPDATE T1 SET I1 = I1 + '050';

-- result: 1
SELECT COUNT(*) FROM T1 PARTITION (P1);
-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P2);
-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P3);
-- result: 3
SELECT COUNT(*) FROM T1 PARTITION (P4);



--##################################################################
--+SECTOR; UPDATE 조건에 따른 검사
--##################################################################
--##############################
--+SECTOR; 여러 파티션으로 분산
--##############################
--+SYSTEM is -silent -f rowMovement_RangePartTable_Varchar_Schema_Range_Varchar.sql;

ALTER TABLE T1
ENABLE ROW MOVEMENT;

UPDATE T1 SET I1 = I1 + '050';

-- result: 0
SELECT COUNT(*) FROM T1 PARTITION (P1);
-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P2);
-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P3);
-- result: 4
SELECT COUNT(*) FROM T1 PARTITION (P4);


ALTER TABLE T2
ENABLE ROW MOVEMENT;

UPDATE T2 SET I1 = I1 + '050';

-- result: 0
SELECT COUNT(*) FROM T2 PARTITION (P1);
-- result: 2
SELECT COUNT(*) FROM T2 PARTITION (P2);
-- result: 2
SELECT COUNT(*) FROM T2 PARTITION (P3);
-- result: 4
SELECT COUNT(*) FROM T2 PARTITION (P4);


--##############################
--+SECTOR; 모두 같은 파티션으로 이동
--##############################
--+SYSTEM is -silent -f rowMovement_RangePartTable_Varchar_Schema_Range_Varchar.sql;

ALTER TABLE T1
ENABLE ROW MOVEMENT;

UPDATE T1 SET I1 = '050';
-- result: 8
SELECT COUNT(*) FROM T1 PARTITION (P1);
-- result: 0
SELECT COUNT(*) FROM T1 PARTITION (P2);
-- result: 0
SELECT COUNT(*) FROM T1 PARTITION (P3);
-- result: 0
SELECT COUNT(*) FROM T1 PARTITION (P4);

UPDATE T1 SET I1 = '150';
-- result: 0
SELECT COUNT(*) FROM T1 PARTITION (P1);
-- result: 8
SELECT COUNT(*) FROM T1 PARTITION (P2);
-- result: 0
SELECT COUNT(*) FROM T1 PARTITION (P3);
-- result: 0
SELECT COUNT(*) FROM T1 PARTITION (P4);

UPDATE T1 SET I1 = '250';
-- result: 0
SELECT COUNT(*) FROM T1 PARTITION (P1);
-- result: 0
SELECT COUNT(*) FROM T1 PARTITION (P2);
-- result: 8
SELECT COUNT(*) FROM T1 PARTITION (P3);
-- result: 0
SELECT COUNT(*) FROM T1 PARTITION (P4);

UPDATE T1 SET I1 = '999';
-- result: 0
SELECT COUNT(*) FROM T1 PARTITION (P1);
-- result: 0
SELECT COUNT(*) FROM T1 PARTITION (P2);
-- result: 0
SELECT COUNT(*) FROM T1 PARTITION (P3);
-- result: 8
SELECT COUNT(*) FROM T1 PARTITION (P4);


ALTER TABLE T2
ENABLE ROW MOVEMENT;

UPDATE T2 SET I1 = '050';
-- result: 8
SELECT COUNT(*) FROM T2 PARTITION (P1);
-- result: 0
SELECT COUNT(*) FROM T2 PARTITION (P2);
-- result: 0
SELECT COUNT(*) FROM T2 PARTITION (P3);
-- result: 0
SELECT COUNT(*) FROM T2 PARTITION (P4);

UPDATE T2 SET I1 = '150';
-- result: 0
SELECT COUNT(*) FROM T2 PARTITION (P1);
-- result: 8
SELECT COUNT(*) FROM T2 PARTITION (P2);
-- result: 0
SELECT COUNT(*) FROM T2 PARTITION (P3);
-- result: 0
SELECT COUNT(*) FROM T2 PARTITION (P4);

UPDATE T2 SET I1 = '250';
-- result: 0
SELECT COUNT(*) FROM T2 PARTITION (P1);
-- result: 0
SELECT COUNT(*) FROM T2 PARTITION (P2);
-- result: 8
SELECT COUNT(*) FROM T2 PARTITION (P3);
-- result: 0
SELECT COUNT(*) FROM T2 PARTITION (P4);

UPDATE T2 SET I1 = '999';
-- result: 0
SELECT COUNT(*) FROM T2 PARTITION (P1);
-- result: 0
SELECT COUNT(*) FROM T2 PARTITION (P2);
-- result: 0
SELECT COUNT(*) FROM T2 PARTITION (P3);
-- result: 8
SELECT COUNT(*) FROM T2 PARTITION (P4);


--##############################
--+SECTOR; 현재 파티션에 그대로 있는 경우
--##############################
--+SYSTEM is -silent -f rowMovement_RangePartTable_Varchar_Schema_Range_Varchar.sql;

ALTER TABLE T1
ENABLE ROW MOVEMENT;

UPDATE T1 SET I1 = I1;

-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P1);
-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P2);
-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P3);
-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P4);


ALTER TABLE T2
ENABLE ROW MOVEMENT;

UPDATE T2 SET I1 = I1;

-- result: 2
SELECT COUNT(*) FROM T2 PARTITION (P1);
-- result: 2
SELECT COUNT(*) FROM T2 PARTITION (P2);
-- result: 2
SELECT COUNT(*) FROM T2 PARTITION (P3);
-- result: 2
SELECT COUNT(*) FROM T2 PARTITION (P4);



--##################################################################
--+SECTOR; FINALIZATION
--##################################################################
--+SKIP BEGIN;
DROP TABLE T1;
DROP TABLE T2;
DROP TABLE T3;
--+SKIP END;
