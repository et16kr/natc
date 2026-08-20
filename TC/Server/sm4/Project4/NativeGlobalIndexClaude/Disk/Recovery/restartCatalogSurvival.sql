--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/PDT/Design/CREATE_TABLE/RangePartTable.sql
--#   (the last sector, original lines 1789-1854)
--#
--# WHY THIS IS A CASE OF ITS OWN, AND WHY IT IS BACK
--#
--# The port dropped this sector and wrote down two reasons. Both are void.
--#
--#   1. "natc's clean is destroydb + createdb: it wipes the database this
--#      suite runs on."  True, and no longer a problem. That objection was
--#      about the isolated instance natc-check.sh guarded with
--#      --auto-init=OFF; the isolated instance is gone with the shell net,
--#      and the runner's database is a development one that ATAF recreates
--#      per run anyway (consolidation plan section 8.7).
--#
--#   2. "the sector freezes an absolute TABLE_ID, and without a pristine
--#      database that value is unstable."  Read the other way round: the
--#      sector's first act IS to make the database pristine. The wipe is
--#      what makes the id stable, not what threatens it. The sector is
--#      self-contained -- after clean it recreates its own tablespaces and
--#      its own table before measuring anything.
--#
--# WHAT IT MEASURES, AND WHY IT MATTERS HERE
--#   kill -> clean -> start -> recreate -> read the catalog. It is the only
--#   thing in this suite that measures the catalog on a database that has
--#   just come up. Recovery/ exists for cases shaped like this and runs
--#   last, because clean wipes what every earlier case built.
--###########################################################################

--##################################################################
--+SECTOR; ��Ÿ ���̺� üũ
--##################################################################

--+SYSTEM server kill;
--+SYSTEM clean;
--+SYSTEM server start;

--+SYSTEM is -f restartCatalogSurvival_INITIALIZE.sql

-- clean 후는 새 세션이라 앞에서 잡은 설정이 날아간다.
-- 전사 폭을 클라이언트 기본값에 맡기지 않고 여기서 못박는다.
SET LINESIZE 200;

DROP TABLE T1;
CREATE TABLE T1 ( I1 INTEGER, I2 DATE, I3 BLOB, I4 CLOB )
PARTITION BY RANGE (I1, I2)
( PARTITION P1 VALUES LESS THAN (100, TO_DATE('2007-04-01', 'YYYY-MM-DD') ) 
            TABLESPACE PDT_TBS LOB(I3, I4) STORE AS ( TABLESPACE PDT_TBS2 ),
  PARTITION P2 VALUES LESS THAN (200, TO_DATE('2007-05-01', 'YYYY-MM-DD') ) 
            TABLESPACE PDT_TBS3,
  PARTITION P3 VALUES DEFAULT
) TABLESPACE PDT_TBS4 LOB(I4) STORE AS ( TABLESPACE PDT_TBS5 );

--##############################
--+SECTOR; SYS_TABLES_
--##############################
SELECT TAB.TABLE_NAME, TAB.COLUMN_COUNT, TAB.IS_PARTITIONED
FROM SYSTEM_.SYS_TABLES_ TAB
WHERE TABLE_NAME='T1'
ORDER BY TABLE_ID;

--##############################
--+SECTOR; SYS_PART_TABLES_
--##############################
SELECT A.*
FROM SYSTEM_.SYS_PART_TABLES_ A, SYSTEM_.SYS_TABLES_ B
WHERE A.TABLE_ID = B.TABLE_ID
    AND B.TABLE_NAME='T1'
ORDER BY A.TABLE_ID;

--##############################
--+SECTOR; SYS_TABLE_PARTITIONS_
--##############################
SELECT A.USER_ID, A.TABLE_ID, A.PARTITION_NAME, A.PARTITION_MIN_VALUE, 
       A.PARTITION_MAX_VALUE, A.PARTITION_ORDER, A.TBS_ID
FROM SYSTEM_.SYS_TABLE_PARTITIONS_ A, SYSTEM_.SYS_TABLES_ B
WHERE A.TABLE_ID = B.TABLE_ID
    AND B.TABLE_NAME='T1'
ORDER BY B.TABLE_ID, A.PARTITION_ID;

--##############################
--+SECTOR; SYS_PART_KEY_COLUMNS_
--##############################
SELECT A.PARTITION_OBJ_ID, A.OBJECT_TYPE, A.PART_COL_ORDER 
FROM SYSTEM_.SYS_PART_KEY_COLUMNS_ A, SYSTEM_.SYS_TABLES_ B
WHERE A.PARTITION_OBJ_ID = B.TABLE_ID
    AND B.TABLE_NAME='T1'
ORDER BY A.PARTITION_OBJ_ID;

--##############################
--+SECTOR; SYS_PART_LOBS_
--##############################
SELECT A.TABLE_ID, A.PARTITION_ID, A.TBS_ID 
FROM SYSTEM_.SYS_PART_LOBS_ A, SYSTEM_.SYS_TABLES_ B
WHERE A.TABLE_ID = B.TABLE_ID
    AND B.TABLE_NAME='T1'
ORDER BY A.TABLE_ID, A.PARTITION_ID;


