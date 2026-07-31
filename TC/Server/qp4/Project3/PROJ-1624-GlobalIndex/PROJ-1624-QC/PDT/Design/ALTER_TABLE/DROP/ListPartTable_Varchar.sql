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

--+APPEND_LST Schema_List_Varchar.sql;
--+SYSTEM is -silent -f Schema_List_Varchar.sql;

--###################################################################
--+ SECTOR; BASIC TEST
--###################################################################
--##############################
--+SECTOR; 문법 체크
--##############################
DROP TABLE TEST;
CREATE TABLE TEST( I1 VARCHAR(10), I2 INTEGER )
PARTITION BY LIST(I1)
(
    PARTITION P1 VALUES ('100'),
    PARTITION P2 VALUES ('200'),
    PARTITION P3 VALUES ('300'),
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
CREATE TABLE TEST( I1 VARCHAR(1000), I2 INTEGER );

-- should be fail
ALTER TABLE TEST 
DROP PARTITION P1_1;

DROP TABLE TEST;


--##############################
--+SECTOR; 파티션 이름 체크
--##############################
--+SYSTEM is -silent -f Schema_List_Varchar.sql;

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
CREATE TABLE T1 ( I1 VARCHAR(10), I2 BLOB, I3 CLOB )
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
-- P1,   {'100', '150'}
-- P3,   {}
SELECT PART.PARTITION_NAME, PART.PARTITION_MIN_VALUE
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ PART,
     SYSTEM_.SYS_TABLES_ TAB
WHERE TAB.TABLE_ID = PART.TABLE_ID AND
      TAB.TABLE_NAME='T1'
ORDER BY PART.PARTITION_NAME;


ALTER TABLE T1
DROP PARTITION P1;


-- Result: 
-- P3,   {}
SELECT PART.PARTITION_NAME, PART.PARTITION_MIN_VALUE
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ PART,
     SYSTEM_.SYS_TABLES_ TAB
WHERE TAB.TABLE_ID = PART.TABLE_ID AND
      TAB.TABLE_NAME='T1'
ORDER BY PART.PARTITION_NAME;

-- result: 0
SELECT COUNT(*) FROM T1;


--##################################################################
--+SECTOR; SPLIT + MERGE + DROP
--##################################################################
--+SYSTEM is -silent -f Schema_List_Varchar.sql;

ALTER TABLE T1
SPLIT PARTITION P1 VALUES ('050') INTO
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

-- result: 3
SELECT COUNT(*) FROM T1;

-- result: '300'
SELECT /* INDEX ASC ( T1, IDX1 ) */ I1
FROM T1 PARTITION (P4) LIMIT 1;


ALTER TABLE T2
SPLIT PARTITION P1 VALUES ('050') INTO
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

-- result: 3
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
