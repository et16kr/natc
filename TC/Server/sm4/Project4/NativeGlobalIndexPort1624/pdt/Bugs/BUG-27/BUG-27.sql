--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/PDT/Bugs/BUG-27/BUG-27.sql
--#
--# Body below is byte-identical to the original. The one line this port
--# adds is the premise: the original measures these statements on the
--# $GIT_ hidden-table implementation, this file measures the same
--# statements on the native global index (F07 -- see include/pinNative.sql).
--###########################################################################
--+LOAD_SQL ../../../include/pinNative.sql;

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
