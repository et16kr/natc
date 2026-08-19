--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/PDT/Design/ALTER_TABLE/TRUNCATE/RangePartTable_Varchar.sql
--#
--# Body below is byte-identical to the original. The one line this port
--# adds is the premise: the original measures these statements on the
--# $GIT_ hidden-table implementation, this file measures the same
--# statements on the native global index (F07 -- see include/pinNative.sql).
--###########################################################################
--+LOAD_SQL ../../../../include/pinNative.sql;

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

--+APPEND_LST Schema_Range_Varchar.sql;
--+SYSTEM is -silent -f Schema_Range_Varchar.sql;

--###################################################################
--+ SECTOR; BASIC TEST
--###################################################################
--##############################
--+SECTOR; 문법 체크
--##############################
DROP TABLE TEST;
CREATE TABLE TEST( I1 VARCHAR(10), I2 INTEGER )
PARTITION BY RANGE(I1)
(
    PARTITION P1 VALUES LESS THAN ('100'),
    PARTITION P2 VALUES LESS THAN ('200'),
    PARTITION P3 VALUES LESS THAN ('300'),
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
CREATE TABLE TEST( I1 VARCHAR(10), I2 INTEGER );

-- should be fail
ALTER TABLE TEST 
TRUNCATE PARTITION P1_1;

DROP TABLE TEST;


--##############################
--+SECTOR; 파티션 이름 체크
--##############################
--+SYSTEM is -silent -f Schema_Range_Varchar.sql;

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

-- should be success
ALTER TABLE T1
TRUNCATE PARTITION P3;

-- result: 2
SELECT COUNT(*) FROM T1;

ALTER TABLE T1
TRUNCATE PARTITION P2;

-- result: 0
SELECT COUNT(*) FROM T1;

ALTER TABLE T1
TRUNCATE PARTITION P1;

-- result: 0
SELECT COUNT(*) FROM T1;



--##################################################################
--+SECTOR; 인덱스 검사
--##################################################################
--+SYSTEM is -silent -f Schema_Range_Varchar.sql;

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

INSERT INTO T2 VALUES ('000', '350', '444' );
INSERT INTO T2 VALUES ('050', '300', '111');
INSERT INTO T2 VALUES ('100', '250', '555');
INSERT INTO T2 VALUES ('150', '200', '888');
INSERT INTO T2 VALUES ('200', '150', '777');
INSERT INTO T2 VALUES ('250', '100', '666');
INSERT INTO T2 VALUES ('300', '050', '333');
INSERT INTO T2 VALUES ('350', '000', '222');

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
