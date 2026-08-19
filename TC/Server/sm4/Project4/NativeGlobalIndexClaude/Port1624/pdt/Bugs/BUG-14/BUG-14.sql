--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/PDT/Bugs/BUG-14/BUG-14.sql
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

