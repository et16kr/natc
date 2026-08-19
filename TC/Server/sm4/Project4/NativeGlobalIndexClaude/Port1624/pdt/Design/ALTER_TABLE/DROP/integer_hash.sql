--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/PDT/Design/ALTER_TABLE/DROP/integer_hash.sql
--#
--# Body below is byte-identical to the original. The one line this port
--# adds is the premise: the original measures these statements on the
--# $GIT_ hidden-table implementation, this file measures the same
--# statements on the native global index (F07 -- see include/pinNative.sql).
--###########################################################################
--+LOAD_SQL ../../../../include/pinNative.sql;

--######################################################
-- DROP PARTITIOIN ( PK:INTEGER )
--######################################################

--###################################
--+SECTOR; INTIALIZE
--###################################

--+SKIP BEGIN;
DROP TABLE PDT_HASH;
--+SKIP END;

CREATE TABLE PDT_HASH
(
    F1   INTEGER,
    F2   INTEGER
) 
PARTITION BY HASH( F1 )
(
    PARTITION P1,
    PARTITION P2,
    PARTITION P3,
    PARTITION P4
) TABLESPACE PDT_TBS;

--#########################################
--+SECTOR; DO JOB #1 (1. Basic Test)
--#########################################

-- nothing to do

--#########################################
--+SECTOR; DO JOB #2 (2. Validation Test)
--#########################################

------------------------------------
-- 2.1 테이블의 종류에 따른 에러검사
------------------------------------
-- should be fail
ALTER TABLE PDT_HASH
ADD PARTITION P1;


--#########################################
--+SECTOR; DO JOB #3 (3. Execution Test)
--#########################################

-- nothing to do 

--###################################
--+SECTOR; FINALIZE
--###################################

DROP TABLE PDT_HASH;
