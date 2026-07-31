--###############################################################
--# PR-4365
--###############################################################

--+SKIP BEGIN;
drop table t1;
drop table t2;
drop table t3;
drop table t4;
--+SKIP END;

--#######################################
--+SECTOR; PRIMARY KEY
--#######################################
create table t1 (i1 integer constraint t1_pk primary key, i2 integer) TABLESPACE SYS_TBS_DISK_DATA;
desc t1;
create index t1_pk on t1 (i2);

create table t2 (i1 integer, i2 integer, constraint t2_pk primary key (i1,i2)) TABLESPACE SYS_TBS_DISK_DATA;
desc t2;
alter table t2 add column (i3 integer constraint t2_pk not null);

create table t3 (i1 integer, i2 integer) TABLESPACE SYS_TBS_DISK_DATA;
alter table t3 add column (i3 integer constraint t3_pk primary key);
desc t3;

create table t4 (i1 integer, i2 integer) TABLESPACE SYS_TBS_DISK_DATA;
alter table t4 add constraint t4_pk primary key (i1,i2);
desc t4;

--#######################################
--+SECTOR; UNIQUE KEY
--#######################################

--+SKIP BEGIN;
drop table t1;
drop table t2;
drop table t3;
drop table t4;
--+SKIP END;

create table t1 (i1 integer constraint t1_uk unique, i2 integer) TABLESPACE SYS_TBS_DISK_DATA;
desc t1;
create index t1_uk on t1 (i2);

create table t2 (i1 integer, i2 integer, constraint t2_uk unique (i1,i2)) TABLESPACE SYS_TBS_DISK_DATA;
desc t2;
alter table t2 add column (i3 integer constraint t2_uk not null);

create table t3 (i1 integer, i2 integer) TABLESPACE SYS_TBS_DISK_DATA;
alter table t3 add column (i3 integer constraint t3_uk unique );
desc t3;

create table t4 (i1 integer, i2 integer) TABLESPACE SYS_TBS_DISK_DATA;
alter table t4 add constraint t4_uk unique (i1,i2);
desc t4;

--#######################################
--+SECTOR; FINALIZATION
--#######################################

--+SKIP BEGIN;
drop table t1;
drop table t2;
drop table t3;
drop table t4;
--+SKIP END;
