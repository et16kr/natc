--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/PDT/Bugs/BUG-22/BUG-22.sql
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
--# PARTITION PRUNING
--###################################################################

--###################################################################
--+SECTOR; PREPARATION
--###################################################################

--+SKIP BEGIN;
DROP TABLE PROD_P_TBL;
--+SKIP END;

ALTER SESSION SET EXPLAIN PLAN = ON;
ALTER SESSION SET TRCLOG_DETAIL_PREDICATE = 1;

CREATE TABLE PROD_P_TBL  
( 
    PROD_SEQ    INTEGER, 
    PROD_DUMMY  INTEGER, 
    PROD_DATE   DATE     
) 
PARTITION BY RANGE( PROD_DATE ) 
( 
    PARTITION P01 VALUES LESS THAN( TO_DATE('01-FEB-2006') ),
    PARTITION P02 VALUES LESS THAN( TO_DATE('01-MAR-2006') ),
    PARTITION P03 VALUES LESS THAN( TO_DATE('01-APR-2006') ),
    PARTITION P04 VALUES LESS THAN( TO_DATE('01-MAY-2006') ),
    PARTITION P05 VALUES LESS THAN( TO_DATE('01-JUN-2006') ),
    PARTITION P06 VALUES LESS THAN( TO_DATE('01-JUL-2006') ),
    PARTITION P07 VALUES LESS THAN( TO_DATE('01-AUG-2006') ),
    PARTITION P08 VALUES LESS THAN( TO_DATE('01-SEP-2006') ),
    PARTITION P09 VALUES LESS THAN( TO_DATE('01-OCT-2006') ),
    PARTITION P10 VALUES LESS THAN( TO_DATE('01-NOV-2006') ),
    PARTITION P11 VALUES LESS THAN( TO_DATE('01-DEC-2006') ),
    PARTITION P12 VALUES LESS THAN( TO_DATE('01-JAN-2007') ),
    PARTITION DEF VALUES DEFAULT 
) TABLESPACE SYS_TBS_DISK_DATA;

CREATE INDEX PROD_P_IDX ON PROD_P_TBL( PROD_SEQ );

INSERT INTO PROD_P_TBL VALUES( 0, 1, TO_DATE('15-FEB-2006') );
INSERT INTO PROD_P_TBL VALUES( 1, 1, TO_DATE('15-FEB-2006') );
INSERT INTO PROD_P_TBL VALUES( 2, 1, TO_DATE('15-FEB-2006') );
INSERT INTO PROD_P_TBL VALUES( 3, 1, TO_DATE('15-FEB-2006') );
INSERT INTO PROD_P_TBL VALUES( 4, 1, TO_DATE('15-FEB-2006') );
INSERT INTO PROD_P_TBL VALUES( 5, 1, TO_DATE('15-FEB-2006') );
INSERT INTO PROD_P_TBL VALUES( 6, 1, TO_DATE('15-FEB-2006') );
INSERT INTO PROD_P_TBL VALUES( 7, 1, TO_DATE('15-FEB-2006') );
INSERT INTO PROD_P_TBL VALUES( 8, 1, TO_DATE('15-FEB-2006') );
INSERT INTO PROD_P_TBL VALUES( 9, 1, TO_DATE('15-FEB-2006') );

--#########################################
--+SECTOR; DO JOB
--#########################################

SELECT * FROM PROD_P_TBL 
WHERE PROD_DATE < TO_DATE('01-MAR-2006') AND 
      PROD_DATE >= TO_DATE('01-FEB-2006') AND 
      PROD_SEQ = 1;

UPDATE PROD_P_TBL 
SET PROD_DUMMY = PROD_DUMMY + 1
WHERE PROD_DATE < TO_DATE('01-MAR-2006') AND 
      PROD_DATE >= TO_DATE('01-FEB-2006') AND 
      PROD_SEQ = 1;

DELETE FROM PROD_P_TBL 
WHERE PROD_DATE < TO_DATE('01-MAR-2006') AND 
      PROD_DATE >= TO_DATE('01-FEB-2006') AND 
      PROD_SEQ = 1;

--###################################################################
--+SECTOR; FINALIZATION
--###################################################################

--+SKIP BEGIN;
DROP TABLE PROD_P_TBL;
--+SKIP END;

