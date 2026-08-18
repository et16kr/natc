--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/PDT/Bugs/BUG-24/BUG-24.sql
--#
--# Body below is byte-identical to the original. The one line this port
--# adds is the premise: the original measures these statements on the
--# $GIT_ hidden-table implementation, this file measures the same
--# statements on the native global index (F07 -- see include/pinNative.sql).
--###########################################################################
--+LOAD_SQL ../../../include/pinNative.sql;

--##################################
--+SECTOR; CHECK DUPLICATE INDEX COLUMN
--##################################
--+SKIP BEGIN;
DROP TABLE T1;
DROP TABLE T2;
--+SKIP END;

CREATE TABLE T1 ( I1 INTEGER )
PARTITION BY RANGE(I1)
(
    PARTITION P1 VALUES LESS THAN (100),
    PARTITION P2 VALUES DEFAULT
) TABLESPACE SYS_TBS_DISK_DATA;

CREATE UNIQUE INDEX IDX1 ON T1(I1);

-- should be fail
ALTER TABLE T1 ADD CONSTRAINT T1_CONST1 UNIQUE(I1);



CREATE TABLE T2 ( I1 INTEGER, I2 INTEGER )
PARTITION BY RANGE(I1, I2)
(
    PARTITION P1 VALUES LESS THAN (100),
    PARTITION P2 VALUES DEFAULT
) TABLESPACE SYS_TBS_DISK_DATA;

CREATE UNIQUE INDEX IDX2 ON T2(I2, I1);

-- should be success
ALTER TABLE T2 ADD CONSTRAINT T2_CONST1 UNIQUE(I1);

-- should be success
ALTER TABLE T2 ADD CONSTRAINT T2_CONST2 UNIQUE(I2);

-- should be success
ALTER TABLE T2 ADD CONSTRAINT T2_CONST3 UNIQUE(I1, I2);

-- should be fail
ALTER TABLE T2 ADD CONSTRAINT T2_CONST4 UNIQUE(I2, I1);


--+SKIP BEGIN;
DROP TABLE T1;
DROP TABLE T2;
--+SKIP END;

