--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/PDT/Bugs/BUG-14/BUG-14.sql
--#
--# Body below is byte-identical to the original. The one line this port
--# adds is the premise: the original measures these statements on the
--# $GIT_ hidden-table implementation, this file measures the same
--# statements on the native global index (F07 -- see include/pinNative.sql).
--###########################################################################
--+LOAD_SQL ../../../include/pinNative.sql;

--###################################################################
--# DROP CONSTRAINT
--###################################################################

--###################################################################
--+SECTOR; PREPARATION
--###################################################################

--+SKIP BEGIN;
DROP TABLE T1;
--+SKIP END;

CREATE TABLE T1 
(
    I1 NUMERIC, 
    I2 NUMERIC, 
    I3 NUMERIC
) 
PARTITION BY RANGE( I3 )
(
    PARTITION P1 VALUES LESS THAN( 20 ),
    PARTITION P2 VALUES LESS THAN( 40 ),
    PARTITION P3 VALUES DEFAULT
) TABLESPACE SYS_TBS_DISK_DATA;

INSERT INTO T1 VALUES ( NULL, NULL, NULL );
INSERT INTO T1 VALUES ( NULL, NULL, NULL );

--#########################################
--+SECTOR; DO JOB
--#########################################

-- should be success
CREATE UNIQUE INDEX IDX_T1 ON T1 (I3 DESC);

--###################################################################
--+SECTOR; FINALIZATION
--###################################################################

--+SKIP BEGIN;
DROP TABLE T1;
--+SKIP END;

