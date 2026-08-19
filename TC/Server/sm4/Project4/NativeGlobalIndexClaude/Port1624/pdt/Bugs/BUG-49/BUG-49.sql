--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/PDT/Bugs/BUG-49/BUG-49.sql
--#
--# Body below is byte-identical to the original. The one line this port
--# adds is the premise: the original measures these statements on the
--# $GIT_ hidden-table implementation, this file measures the same
--# statements on the native global index (F07 -- see include/pinNative.sql).
--###########################################################################
--+LOAD_SQL ../../../include/pinNative.sql;

--###############################################################
--# HINTS TEST SET
--###############################################################

--+SKIP BEGIN;
DROP TABLE T1;
--+SKIP END;

--######################################
--+SECTOR; PREPARATION
--######################################

CREATE TABLE T1 ( I1 INTEGER, I2 INTEGER, I3 INTEGER ) 
PARTITION BY RANGE(I1) ( PARTITION P1 VALUES DEFAULT TABLESPACE PDT_TBS ) 
TABLESPACE SYS_TBS_DISK_DATA;

CREATE INDEX T1_IDX1 ON T1(I1);
CREATE INDEX T1_IDX2 ON T1(I1, i2);
CREATE INDEX T1_IDX3 ON T1(I1, i2, i3);
CREATE INDEX T1_IDX4 ON T1(I2);
CREATE INDEX T1_IDX5 ON T1(I3 ASC);
CREATE INDEX T1_IDX6 ON T1(I3 DESC);

INSERT INTO T1 VALUES (2,1,8);
INSERT INTO T1 VALUES (1,2,7);
INSERT INTO T1 VALUES (3,3,4);
INSERT INTO T1 VALUES (5,1,9);
INSERT INTO T1 VALUES (4,2,4);
INSERT INTO T1 VALUES (6,3,1);
INSERT INTO T1 VALUES (9,1,3);
INSERT INTO T1 VALUES (8,2,2);
INSERT INTO T1 VALUES (7,3,5);

--######################################
--+SECTOR; DO JOB
--######################################

SELECT /*+ INDEX DESC ( T1, T1_IDX5 ) */ I3 FROM T1 GROUP BY I3;

--######################################
--+SECTOR; FINALIZATION
--######################################

--+SKIP BEGIN;
DROP TABLE T1;
--+SKIP END;
