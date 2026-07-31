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
