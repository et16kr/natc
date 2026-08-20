--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/PDT/Bugs/BUG-27/BUG-27.sql
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

--##################################
--+SECTOR; DROP USER
--##################################
--+SKIP BEGIN;
DROP TABLE JYLEE.PDT;
DROP USER MKKIM CASCADE;
DROP USER JYLEE CASCADE;
--+SKIP END;

CREATE USER MKKIM IDENTIFIED BY MKKIMPWD DEFAULT TABLESPACE SYS_TBS_DISK_DATA;
GRANT ALL PRIVILEGES TO MKKIM;
CREATE USER JYLEE IDENTIFIED BY JYLEEPWD DEFAULT TABLESPACE SYS_TBS_DISK_DATA;
GRANT ALL PRIVILEGES TO JYLEE;

CONNECT JYLEE/JYLEEPWD;
CREATE TABLE PDT
(
    F1 INTEGER,
    F2 INTEGER
)
PARTITION BY RANGE( F1 )
(
    PARTITION P1 VALUES LESS THAN( 10 ),
    PARTITION P2 VALUES LESS THAN( 20 ),
    PARTITION P3 VALUES LESS THAN( 30 ),
    PARTITION P4 VALUES DEFAULT
);

CONNECT MKKIM/MKKIMPWD;

CREATE INDEX IDX_PDT1 ON JYLEE.PDT( F1 );
CREATE INDEX IDX_PDT2 ON JYLEE.PDT( F2 );
CREATE INDEX IDX_PDT3 ON JYLEE.PDT( F1, F2 );

INSERT INTO JYLEE.PDT VALUES( 1, 1 );

CONNECT SYS/MANAGER;

-- should be success
DROP USER MKKIM CASCADE;

-- should be success
SELECT COUNT(*) FROM JYLEE.PDT;

CONNECT SYS/MANAGER;
-- should be success
DROP USER JYLEE CASCADE;
-- should be fail
SELECT COUNT(*) FROM JYLEE.PDT;

--+SKIP BEGIN;
DROP TABLE JYLEE.PDT;
DROP USER MKKIM CASCADE;
DROP USER JYLEE CASCADE;
--+SKIP END;
