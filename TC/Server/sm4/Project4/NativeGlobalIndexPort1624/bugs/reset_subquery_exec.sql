--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/bugs/reset_subquery_exec.sql
--#
--# Body below is byte-identical to the original. The one line this port
--# adds is the premise: the original measures these statements on the
--# $GIT_ hidden-table implementation, this file measures the same
--# statements on the native global index (F07 -- see include/pinNative.sql).
--###########################################################################
--+LOAD_SQL ../include/pinNative.sql;

--##########################################################################
--# BUG-31040
--#     distinct 한 하나의 value 만 필요한 부분에 subquery 가 사용되었을 경우 서버 사망
--##########################################################################

--#####################################
--# PREPARATION
--#####################################

--+SKIP BEGIN;
DROP TABLE A;
DROP TABLE B;
DROP TABLE C;
--+SKIP END;

CREATE TABLE A (A1 INTEGER);
CREATE TABLE B (B1 INTEGER);
CREATE TABLE C (C1 INTEGER)
partition by hash(c1)
(
  partition p1,
  partition p2
)
tablespace sys_tbs_disk_data;
 
INSERT INTO A VALUES (1);
INSERT INTO B VALUES (1);
INSERT INTO C VALUES (1);
 
CREATE INDEX ADX ON A ( A1 );

alter session set explain plan = on;
alter system set trclog_detail_predicate = 1;

--#####################################
--+ SECTOR; TEST
--#####################################

SELECT
    (SELECT A1 FROM A
     WHERE B.B1=A1 AND A1 IN (SELECT B1 FROM B)
     LIMIT 1 )
FROM B;

SELECT B1 FROM B ORDER BY
    (SELECT A1 FROM A WHERE B.B1 = A1 
     AND A1 IN (SELECT A1 FROM A)
     LIMIT 1);

SELECT B1 FROM B GROUP BY B1 HAVING
    B1 = (SELECT A1 FROM A WHERE B.B1 = A1 
          AND A1 IN (SELECT C1 FROM C)
          LIMIT 1);

SELECT B1 FROM B WHERE 
    3= (SELECT A1 FROM A WHERE B.B1 = A1 
          AND A1 IN (SELECT C1 FROM C)
          LIMIT 1);

--#####################################
--# FINALIZATION
--#####################################

DROP TABLE A;
DROP TABLE B;
DROP TABLE C;

alter session set explain plan = off;
alter system set trclog_detail_predicate = 0;
