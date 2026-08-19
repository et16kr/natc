--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/PDT/Bugs/BUG-45/BUG-45.sql
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

--############################################################################
--# PR-16131
--############################################################################

--#####################################
--+SECTOR; PREPARATION
--#####################################

--+SKIP BEGIN;
drop table t1 cascade;
drop index idx;
--+SKIP END;


--####################################
--+SECTOR; CREATE TABLE TEST
--####################################

drop table t1 cascade;
create table t1(
  i1 integer, 
  i2 geometry,
  primary key (i1)
)
PARTITION BY RANGE(I1)
(
    PARTITION P1 VALUES DEFAULT TABLESPACE PDT_TBS
) TABLESPACE SYS_TBS_DISK_DATA;

drop table t1 cascade;
create table t1(
  i1 integer, 
  i2 geometry,
  primary key (i2)
)
PARTITION BY RANGE(I2)
(
    PARTITION P1 VALUES DEFAULT TABLESPACE PDT_TBS
) TABLESPACE SYS_TBS_DISK_DATA;

drop table t1 cascade;
create table t1(
  i1 integer, 
  i2 geometry,
  unique (i1)
)
PARTITION BY RANGE(I1)
(
    PARTITION P1 VALUES DEFAULT TABLESPACE PDT_TBS
) TABLESPACE SYS_TBS_DISK_DATA;

drop table t1 cascade;
create table t1(
  i1 integer, 
  i2 geometry,
  unique (i2)
)
PARTITION BY RANGE(I2)
(
    PARTITION P1 VALUES DEFAULT TABLESPACE PDT_TBS
) TABLESPACE SYS_TBS_DISK_DATA;

drop table t1 cascade;
create table t1(
  i1 integer, 
  i2 geometry,
  primary key (i1,i2)
)
PARTITION BY RANGE(I1,I2)
(
    PARTITION P1 VALUES DEFAULT TABLESPACE PDT_TBS
) TABLESPACE SYS_TBS_DISK_DATA;

drop table t1 cascade;
create table t1(
  i1 integer, 
  i2 geometry,
  primary key (i2,i1)
)
PARTITION BY RANGE(I2,I1)
(
    PARTITION P1 VALUES DEFAULT TABLESPACE PDT_TBS
) TABLESPACE SYS_TBS_DISK_DATA;

drop table t1 cascade;
create table t1(
  i1 integer, 
  i2 geometry,
  unique (i1,i2)
)
PARTITION BY RANGE(I1,I2)
(
    PARTITION P1 VALUES DEFAULT TABLESPACE PDT_TBS
) TABLESPACE SYS_TBS_DISK_DATA;

drop table t1 cascade;
create table t1(
  i1 integer, 
  i2 geometry,
  unique (i2,i1)
)
PARTITION BY RANGE(I2,I1)
(
    PARTITION P1 VALUES DEFAULT TABLESPACE PDT_TBS
) TABLESPACE SYS_TBS_DISK_DATA;

--####################################
--+SECTOR; CREATE INDEX TEST
--####################################

drop table t1 cascade;
create table t1(i1 integer, i2 integer, i3 geometry, i4 geometry)
PARTITION BY RANGE(I1)
(
    PARTITION P1 VALUES DEFAULT TABLESPACE PDT_TBS
) TABLESPACE SYS_TBS_DISK_DATA;

create index idx on t1(i1);
drop index idx;
create index idx on t1(i1) indextype is btree;
drop index idx;
create index idx on t1(i1) indextype is rtree;
drop index idx;
create index idx on t1(i1) indextype is tdrtree;

drop index idx;
create index idx on t1(i3);
drop index idx;
create index idx on t1(i3) indextype is btree;
drop index idx;
create index idx on t1(i3) indextype is rtree;
drop index idx;
create index idx on t1(i3) indextype is tdrtree;

drop index idx;
create index idx on t1(i1,i2);
drop index idx;
create index idx on t1(i1,i2) indextype is btree;
drop index idx;
create index idx on t1(i1,i2) indextype is rtree;
drop index idx;
create index idx on t1(i1,i2) indextype is tdrtree;

drop index idx;
create index idx on t1(i1,i3);
drop index idx;
create index idx on t1(i1,i3) indextype is btree;
drop index idx;
create index idx on t1(i1,i3) indextype is rtree;
drop index idx;
create index idx on t1(i1,i3) indextype is tdrtree;

drop index idx;
create index idx on t1(i3,i1);
drop index idx;
create index idx on t1(i3,i1) indextype is btree;
drop index idx;
create index idx on t1(i3,i1) indextype is rtree;
drop index idx;
create index idx on t1(i3,i1) indextype is tdrtree;

drop index idx;
create index idx on t1(i3,i4);
drop index idx;
create index idx on t1(i3,i4) indextype is btree;
drop index idx;
create index idx on t1(i3,i4) indextype is rtree;
drop index idx;
create index idx on t1(i3,i4) indextype is tdrtree;

drop index idx;
create index idx on t1(i1,i1);
drop index idx;
create index idx on t1(i1,i1) indextype is btree;
drop index idx;
create index idx on t1(i1,i1) indextype is rtree;
drop index idx;
create index idx on t1(i1,i1) indextype is tdrtree;

drop index idx;
create index idx on t1(i3,i3);
drop index idx;
create index idx on t1(i3,i3) indextype is btree;
drop index idx;
create index idx on t1(i3,i3) indextype is rtree;
drop index idx;
create index idx on t1(i3,i3) indextype is tdrtree;

--####################################
--+SECTOR; FINALIZATION
--####################################

--+SKIP BEGIN;
drop table t1 cascade;
drop index idx;
--+SKIP END;
