--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/PDT/Design/ALTER_TABLE/ADD/integer_list.sql
--#
--# Body below is byte-identical to the original. The one line this port
--# adds is the premise: the original measures these statements on the
--# $GIT_ hidden-table implementation, this file measures the same
--# statements on the native global index (F07 -- see include/pinNative.sql).
--###########################################################################
--+LOAD_SQL ../../../../include/pinNative.sql;

--######################################################
-- ADD PARTITIOIN ( PK:INTEGER )
--######################################################

--###################################
--+SECTOR; INTIALIZE
--###################################

--+SKIP BEGIN;
DROP TABLE PDT_LIST;
--+SKIP END;

CREATE TABLE PDT_LIST
(
    F1   INTEGER,
    F2   INTEGER
) 
PARTITION BY LIST( F1 )
(
    PARTITION P1 VALUES ( 10 ),
    PARTITION P2 VALUES ( 20 ),
    PARTITION P3 VALUES ( 30 ),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS;


--#########################################
--+SECTOR; DO JOB #1 (1. Basic Test)
--#########################################

-- nothing to do

--#########################################
--+SECTOR; DO JOB #2 (2. Validation Test)
--#########################################

------------------------------------------
-- 2.1 테이블의 종류에 따른 에러검사
------------------------------------------
-- should be fail
ALTER TABLE PDT_LIST
ADD PARTITION P5;

--#########################################
--+SECTOR; DO JOB #3 (3. Execution Test)
--#########################################

-- nothing to do


--###################################
--+SECTOR; FINALIZE
--###################################

DROP TABLE PDT_LIST;
