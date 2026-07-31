--###################################################################
--# ALTER TABLE ... TRUNCATE PARTITION (PartKey: DATE)
--###################################################################

--###################################################################
--+SECTOR; PREPARATION
--###################################################################

--+SKIP BEGIN;
DROP TABLE T1;
DROP TABLE T2;
DROP TABLE T3;
--+SKIP END;

--+APPEND_LST Schema_Hash_Date.sql;
--+SYSTEM is -silent -f Schema_Hash_Date.sql;

--###################################################################
--+ SECTOR; BASIC TEST
--###################################################################
--##############################
--+SECTOR; 문법 체크
--##############################
DROP TABLE TEST;
CREATE TABLE TEST( I1 DATE, I2 INTEGER )
PARTITION BY HASH(I1)
(
    PARTITION P1,
    PARTITION P2,
    PARTITION P3,
    PARTITION P4
) TABLESPACE PDT_TBS;

-- should be fail
ALTER TABLE TEST 
TRUNCATE PARTITION P1_1 TABLESPACE PDT_TBS2;

DROP TABLE TEST;

--##############################
--+SECTOR; 파티션드 테이블인지 체크
--##############################
DROP TABLE TEST;
CREATE TABLE TEST( I1 DATE, I2 INTEGER );

-- should be fail
ALTER TABLE TEST 
TRUNCATE PARTITION P1_1;

DROP TABLE TEST;


--##############################
--+SECTOR; 파티션 이름 체크
--##############################
--+SYSTEM is -silent -f Schema_Hash_Date.sql;

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
CREATE TABLE T1 ( I1 DATE, I2 BLOB, I3 CLOB )
PARTITION BY HASH(I1) 
( PARTITION P1 TABLESPACE PDT_TBS 
                        LOB(I2, I3) STORE AS ( TABLESPACE PDT_TBS2 ), 
  PARTITION P2 TABLESPACE PDT_TBS3,
  PARTITION P3
) TABLESPACE PDT_TBS4 LOB(I3) STORE AS ( TABLESPACE PDT_TBS5 );

INSERT INTO T1 VALUES ( TO_DATE('2007-05-01', 'YYYY-MM-DD'),   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( TO_DATE('2007-05-15', 'YYYY-MM-DD'),   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( TO_DATE('2007-06-01', 'YYYY-MM-DD'),   'ABC', 'DEF' );
INSERT INTO T1 VALUES ( TO_DATE('2007-06-15', 'YYYY-MM-DD'),   'ABC', 'DEF' );

ALTER TABLE T1
TRUNCATE PARTITION P3;

ALTER TABLE T1
TRUNCATE PARTITION P2;

ALTER TABLE T1
TRUNCATE PARTITION P1;

-- result: 0
SELECT COUNT(*) FROM T1;



--##################################################################
--+SECTOR; 인덱스 검사
--##################################################################
--+SYSTEM is -silent -f Schema_Hash_Date.sql;

-- result: 2007-05-01, 2007-05-05, 100
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

INSERT INTO T2 VALUES (TO_DATE('2007-05-01', 'YYYY-MM-DD'), TO_DATE('2007-08-05', 'YYYY-MM-DD'), 444);
INSERT INTO T2 VALUES (TO_DATE('2007-05-05', 'YYYY-MM-DD'), TO_DATE('2007-07-15', 'YYYY-MM-DD'), 111);
INSERT INTO T2 VALUES (TO_DATE('2007-05-15', 'YYYY-MM-DD'), TO_DATE('2007-07-05', 'YYYY-MM-DD'), 555);
INSERT INTO T2 VALUES (TO_DATE('2007-06-05', 'YYYY-MM-DD'), TO_DATE('2007-06-15', 'YYYY-MM-DD'), 888);
INSERT INTO T2 VALUES (TO_DATE('2007-06-15', 'YYYY-MM-DD'), TO_DATE('2007-06-05', 'YYYY-MM-DD'), 777);
INSERT INTO T2 VALUES (TO_DATE('2007-07-05', 'YYYY-MM-DD'), TO_DATE('2007-05-15', 'YYYY-MM-DD'), 666);
INSERT INTO T2 VALUES (TO_DATE('2007-07-15', 'YYYY-MM-DD'), TO_DATE('2007-05-05', 'YYYY-MM-DD'), 333);
INSERT INTO T2 VALUES (TO_DATE('2007-08-05', 'YYYY-MM-DD'), TO_DATE('2007-05-01', 'YYYY-MM-DD'), 222);

-- result: 2007-05-01, 2007-08-05, 444
SELECT /* INDEX ASC ( T2, IDX1 ) */ *
FROM T2 LIMIT 1;

-- result: 2007-05-05, 2007-07-15, 111
SELECT /* INDEX ASC ( T2, IDX2 ) */ *
FROM T2 LIMIT 1;

-- result: 2007-08-05, 2007-05-01, 222
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
