--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/PDT/Bugs/BUG-20/BUG-20.sql
--#
--# Body below is byte-identical to the original. The one line this port
--# adds is the premise: the original measures these statements on the
--# $GIT_ hidden-table implementation, this file measures the same
--# statements on the native global index (F07 -- see include/pinNative.sql).
--###########################################################################
--+LOAD_SQL ../../../include/pinNative.sql;

--###################################################################
--# D$DISK_INDEX_BTREE_STRUCTURE
--###################################################################

--###################################################################
--+SECTOR; PREPARATION
--###################################################################

--+SKIP BEGIN;
DROP TABLE D1;
DROP TABLE D2;
DROP TABLE D3;
--+SKIP END;

CREATE TABLE D1 
( 
    I1 INTEGER, 
    I2 CHAR(3000), 
    I3 INTEGER 
) TABLESPACE SYS_TBS_DISK_DATA;

CREATE INDEX D1_IDX1 ON D1(I2);

INSERT INTO D1 VALUES ( 1, 1, 1 );

--#########################################
--+SECTOR; DO JOB
--#########################################

-- [Empty dump object]
CREATE TABLE D3 AS SELECT * FROM D$DISK_INDEX_BTREE_STRUCTURE;
-- should be success
CREATE TABLE D2 AS SELECT * FROM D$DISK_INDEX_BTREE_STRUCTURE(D1_IDX1);


--###################################################################
--+SECTOR; FINALIZATION
--###################################################################

--+SKIP BEGIN;
DROP TABLE D1;
DROP TABLE D2;
DROP TABLE D3;
--+SKIP END;

