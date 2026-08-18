--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/PDT/Design/ALTER_TABLE/ROW_MOVEMENT/ListPartTable_Integer.sql
--#
--# Body below is byte-identical to the original. The one line this port
--# adds is the premise: the original measures these statements on the
--# $GIT_ hidden-table implementation, this file measures the same
--# statements on the native global index (F07 -- see include/pinNative.sql).
--###########################################################################
--+LOAD_SQL ../../../../include/pinNative.sql;

--###################################################################
--# ALTER TABLE ... ENABLE/DISABLE ROWMOVEMENT(PartKey: INTEGER)
--###################################################################

--###################################################################
--+SECTOR; PREPARATION
--###################################################################

--+SKIP BEGIN;
DROP TABLE T1;
DROP TABLE T2;
DROP TABLE T3;
--+SKIP END;

--+APPEND_LST Schema_List_Integer.sql;
--+SYSTEM is -silent -f Schema_List_Integer.sql;

--###################################################################
--+ SECTOR; BASIC TEST
--###################################################################
--##############################
--+SECTOR; 문법 체크
--##############################
DROP TABLE TEST;

-- should be fail
CREATE TABLE TEST( I1 INTEGER, I2 INTEGER )
PARTITION BY LIST(I1)
(
    PARTITION P1 VALUES (100),
    PARTITION P2 VALUES (200),
    PARTITION P3 VALUES (300),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS ENABLE ROW MOVEMENT;

-- should be fail
CREATE TABLE TEST( I1 INTEGER, I2 INTEGER )
PARTITION BY LIST(I1)
(
    PARTITION P1 VALUES (100),
    PARTITION P2 VALUES (200),
    PARTITION P3 VALUES (300) ENABLE ROW MOVEMENT,
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS;

-- should be success
CREATE TABLE TEST( I1 INTEGER, I2 INTEGER )
PARTITION BY LIST(I1)
(
    PARTITION P1 VALUES (100),
    PARTITION P2 VALUES (200),
    PARTITION P3 VALUES (300),
    PARTITION P4 VALUES DEFAULT
) ENABLE ROW MOVEMENT TABLESPACE PDT_TBS;


--##############################
--+SECTOR; 파티션의 개수
--##############################
--#############
--# 4개
--#############
--+SYSTEM is -silent -f Schema_List_Integer.sql;

ALTER TABLE T1
ENABLE ROW MOVEMENT;

UPDATE T1 SET I1 = I1 + 50;

-- result: 1
SELECT COUNT(*) FROM T1 PARTITION (P1);
-- result: 3
SELECT COUNT(*) FROM T1 PARTITION (P2);
-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P3);
-- result: 7
SELECT COUNT(*) FROM T1 PARTITION (P4);


ALTER TABLE T2
ENABLE ROW MOVEMENT;

UPDATE T2 SET I1 = I1 + 50;

-- result: 1
SELECT COUNT(*) FROM T2 PARTITION (P1);
-- result: 3
SELECT COUNT(*) FROM T2 PARTITION (P2);
-- result: 2
SELECT COUNT(*) FROM T2 PARTITION (P3);
-- result: 7
SELECT COUNT(*) FROM T2 PARTITION (P4);

--#############
--# 1개
--#############
--+SYSTEM is -silent -f Schema_List_Integer.sql;

ALTER TABLE T1
ENABLE ROW MOVEMENT;

ALTER TABLE T1 
MERGE PARTITIONS P1, P2 INTO PARTITION P1;

ALTER TABLE T1 
MERGE PARTITIONS P3, P4 INTO PARTITION P3;

ALTER TABLE T1 
MERGE PARTITIONS P1, P3 INTO PARTITION P1;

UPDATE T1 SET I1 = I1 + 50;

-- result: 13
SELECT COUNT(*) FROM T1;


ALTER TABLE T2
ENABLE ROW MOVEMENT;

ALTER TABLE T2 
MERGE PARTITIONS P1, P2 INTO PARTITION P1;

ALTER TABLE T2 
MERGE PARTITIONS P3, P4 INTO PARTITION P3;

ALTER TABLE T2 
MERGE PARTITIONS P1, P3 INTO PARTITION P1;

UPDATE T2 SET I1 = I1 + 50;

-- result: 13
SELECT COUNT(*) FROM T2;


--##############################
--+SECTOR; LOB 컬럼이 있는 경우
--##############################
DROP TABLE T1;
CREATE TABLE T1 ( I1 INTEGER, I2 BLOB, I3 CLOB )
PARTITION BY LIST(I1) 
( PARTITION P1 VALUES (0, 50, 75) TABLESPACE PDT_TBS 
                        LOB(I2, I3) STORE AS ( TABLESPACE PDT_TBS2 ), 
  PARTITION P2 VALUES (100, 150, 175, NULL) TABLESPACE PDT_TBS3,
  PARTITION P3 VALUES (200, 250, 275) TABLESPACE PDT_TBS4,
  PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS4 LOB(I3) STORE AS ( TABLESPACE PDT_TBS5 );

CREATE INDEX IDX_LOB ON T1(I1) LOCAL;

INSERT INTO T1 VALUES ( NULL,'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 0,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 50,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 75,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 100,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 150,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 175,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 200,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 250,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 275,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 300,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 350,   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( 375,   'ABC', 'DEF' );

ALTER TABLE T1
ENABLE ROW MOVEMENT;

UPDATE T1 SET I1 = I1 + 50;

-- result: 1
SELECT COUNT(*) FROM T1 PARTITION (P1);
-- result: 3
SELECT COUNT(*) FROM T1 PARTITION (P2);
-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P3);
-- result: 7
SELECT COUNT(*) FROM T1 PARTITION (P4);



--##################################################################
--+SECTOR; UPDATE 조건에 따른 검사
--##################################################################
--##############################
--+SECTOR; 여러 파티션으로 분산
--##############################
--+SYSTEM is -silent -f Schema_List_Integer.sql;

ALTER TABLE T1
ENABLE ROW MOVEMENT;

UPDATE T1 SET I1 = I1 + 50;

-- result: 1
SELECT COUNT(*) FROM T1 PARTITION (P1);
-- result: 3
SELECT COUNT(*) FROM T1 PARTITION (P2);
-- result: 2
SELECT COUNT(*) FROM T1 PARTITION (P3);
-- result: 7
SELECT COUNT(*) FROM T1 PARTITION (P4);


ALTER TABLE T2
ENABLE ROW MOVEMENT;

UPDATE T2 SET I1 = I1 + 50;

-- result: 1
SELECT COUNT(*) FROM T2 PARTITION (P1);
-- result: 3
SELECT COUNT(*) FROM T2 PARTITION (P2);
-- result: 2
SELECT COUNT(*) FROM T2 PARTITION (P3);
-- result: 7
SELECT COUNT(*) FROM T2 PARTITION (P4);


--##############################
--+SECTOR; 모두 같은 파티션으로 이동
--##############################
--+SYSTEM is -silent -f Schema_List_Integer.sql;

ALTER TABLE T1
ENABLE ROW MOVEMENT;

UPDATE T1 SET I1 = 50;
-- result: 13
SELECT COUNT(*) FROM T1 PARTITION (P1);
-- result: 0
SELECT COUNT(*) FROM T1 PARTITION (P2);
-- result: 0
SELECT COUNT(*) FROM T1 PARTITION (P3);
-- result: 0
SELECT COUNT(*) FROM T1 PARTITION (P4);

UPDATE T1 SET I1 = 150;
-- result: 0
SELECT COUNT(*) FROM T1 PARTITION (P1);
-- result: 13
SELECT COUNT(*) FROM T1 PARTITION (P2);
-- result: 0
SELECT COUNT(*) FROM T1 PARTITION (P3);
-- result: 0
SELECT COUNT(*) FROM T1 PARTITION (P4);

UPDATE T1 SET I1 = 250;
-- result: 0
SELECT COUNT(*) FROM T1 PARTITION (P1);
-- result: 0
SELECT COUNT(*) FROM T1 PARTITION (P2);
-- result: 13
SELECT COUNT(*) FROM T1 PARTITION (P3);
-- result: 0
SELECT COUNT(*) FROM T1 PARTITION (P4);

UPDATE T1 SET I1 = 1000;
-- result: 0
SELECT COUNT(*) FROM T1 PARTITION (P1);
-- result: 0
SELECT COUNT(*) FROM T1 PARTITION (P2);
-- result: 0
SELECT COUNT(*) FROM T1 PARTITION (P3);
-- result: 13
SELECT COUNT(*) FROM T1 PARTITION (P4);


ALTER TABLE T2
ENABLE ROW MOVEMENT;

UPDATE T2 SET I1 = 50;
-- result: 13
SELECT COUNT(*) FROM T2 PARTITION (P1);
-- result: 0
SELECT COUNT(*) FROM T2 PARTITION (P2);
-- result: 0
SELECT COUNT(*) FROM T2 PARTITION (P3);
-- result: 0
SELECT COUNT(*) FROM T2 PARTITION (P4);

UPDATE T2 SET I1 = 150;
-- result: 0
SELECT COUNT(*) FROM T2 PARTITION (P1);
-- result: 13
SELECT COUNT(*) FROM T2 PARTITION (P2);
-- result: 0
SELECT COUNT(*) FROM T2 PARTITION (P3);
-- result: 0
SELECT COUNT(*) FROM T2 PARTITION (P4);

UPDATE T2 SET I1 = 250;
-- result: 0
SELECT COUNT(*) FROM T2 PARTITION (P1);
-- result: 0
SELECT COUNT(*) FROM T2 PARTITION (P2);
-- result: 13
SELECT COUNT(*) FROM T2 PARTITION (P3);
-- result: 0
SELECT COUNT(*) FROM T2 PARTITION (P4);

UPDATE T2 SET I1 = 1000;
-- result: 0
SELECT COUNT(*) FROM T2 PARTITION (P1);
-- result: 0
SELECT COUNT(*) FROM T2 PARTITION (P2);
-- result: 0
SELECT COUNT(*) FROM T2 PARTITION (P3);
-- result: 13
SELECT COUNT(*) FROM T2 PARTITION (P4);



--##################################################################
--+SECTOR; FINALIZATION
--##################################################################
--+SKIP BEGIN;
DROP TABLE T1;
DROP TABLE T2;
DROP TABLE T3;
--+SKIP END;
