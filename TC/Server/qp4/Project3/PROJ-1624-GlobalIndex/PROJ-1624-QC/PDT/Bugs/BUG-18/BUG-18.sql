--###################################################################
--# DELETE HINT
--###################################################################

--###################################################################
--+SECTOR; PREPARATION
--###################################################################

--+SKIP BEGIN;
DROP TABLE T1;
--+SKIP END;

CREATE TABLE T1
(
    I1 INTEGER, 
    I2 INTEGER
) 
PARTITION BY RANGE( I1 ) 
( 
    PARTITION P1 VALUES DEFAULT 
) TABLESPACE SYS_TBS_DISK_DATA;

CREATE INDEX T1_IDX1 ON T1(I1 ASC);

CREATE INDEX T1_IDX2 ON T1(I1 DESC) INDEXTYPE IS BTREE;

INSERT INTO T1 VALUES(1, 1);
INSERT INTO T1 VALUES(2, 2);
INSERT INTO T1 VALUES(3, 3);
INSERT INTO T1 VALUES(4, 8);
INSERT INTO T1 VALUES(5, 6);
INSERT INTO T1 VALUES(6, 7);
INSERT INTO T1 VALUES(7, 4);
INSERT INTO T1 VALUES(8, 5);
INSERT INTO T1 VALUES(0, 5);
INSERT INTO T1 VALUES(10, 5);
INSERT INTO T1 VALUES(9, 5);
INSERT INTO T1 VALUES(11, 5);
INSERT INTO T1 VALUES(15, 5);
INSERT INTO T1 VALUES(12, 5);
INSERT INTO T1 VALUES(13, 5);
INSERT INTO T1 VALUES(14, 5);
INSERT INTO T1 VALUES(16, 5);

--#########################################
--+SECTOR; DO JOB
--#########################################

DELETE /*+ FULL SCAN(T1) */ FROM T1 WHERE I1 = 1;
DELETE /*+ INDEX(T1, T1_IDX2) */ FROM T1 WHERE I2 = 2;
DELETE /*+ NO INDEX(T1, T1_IDX2) */ FROM T1 WHERE I2 = 3;
DELETE /*+ RULE */ FROM T1 WHERE I2 = 4;
DELETE /*+ COST */ FROM T1 WHERE I2 = 5;
DELETE FROM T1 /*+ COST */ WHERE I2 = 5;

--###################################################################
--+SECTOR; FINALIZATION
--###################################################################

--+SKIP BEGIN;
DROP TABLE T1;
--+SKIP END;

