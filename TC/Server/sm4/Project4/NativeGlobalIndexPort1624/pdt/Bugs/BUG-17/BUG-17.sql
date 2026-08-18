--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/PDT/Bugs/BUG-17/BUG-17.sql
--#
--# Body below is byte-identical to the original. The one line this port
--# adds is the premise: the original measures these statements on the
--# $GIT_ hidden-table implementation, this file measures the same
--# statements on the native global index (F07 -- see include/pinNative.sql).
--###########################################################################
--+LOAD_SQL ../../../include/pinNative.sql;

--###################################################################
--# CREATE INDEX BUG
--###################################################################

--###################################################################
--+SECTOR; PREPARATION
--###################################################################

--+SKIP BEGIN;
DROP TABLE T1;
--+SKIP END;

CREATE TABLE T1
(
    I1 INTEGER PRIMARY KEY, 
    I2 INTEGER, 
    I3 VARCHAR(10), 
    I4 INTEGER 
) 
PARTITION BY RANGE( I1 ) 
( 
    PARTITION P1 VALUES DEFAULT 
) TABLESPACE SYS_TBS_DISK_DATA;

CREATE INDEX T1_IDX1 ON T1(I2 ASC);

--#########################################
--+SECTOR; DO JOB
--#########################################

INSERT INTO T1 VALUES(1 , 1 , 'a', 1);
INSERT INTO T1 VALUES(2 , 2 , 'b', 2);
INSERT INTO T1 VALUES(3 , 4 , 'c', 3);
INSERT INTO T1 VALUES(4 , 5 , 'd', 4);
INSERT INTO T1 VALUES(5 , 9 , 'e', 5);
-- should be success
INSERT INTO T1 VALUES(6 , 1 , 'f', 6);

--###################################################################
--+SECTOR; FINALIZATION
--###################################################################

--+SKIP BEGIN;
DROP TABLE T1;
--+SKIP END;

