--#######################################################################
--# Initialize tables
--#######################################################################

--##################################
--+SECTOR; PREPARATION
--##################################

--+SKIP BEGIN;
drop table t1;
drop table t2;
drop table t3;
drop table t4;
drop table t5;
drop table t6;
--+SKIP END;

create table t1 ( i1 integer constraint t1_pk primary key );
create table t2 ( i1 integer constraint t2_pk primary key );
create table t3 ( i1 integer constraint t3_pk primary key );
create table t4 ( i1 integer constraint t4_pk primary key );
create table t5 ( i1 integer constraint t5_pk primary key );
create table t6 ( i1 integer constraint t6_pk primary key );

insert into t1 select a from ( select level a from dual connect by level < 100 ) where mod(a,1) = 0;
insert into t2 select a from ( select level a from dual connect by level < 100 ) where mod(a,2) = 0;
insert into t3 select a from ( select level a from dual connect by level < 100 ) where mod(a,3) = 0;
insert into t4 select a from ( select level a from dual connect by level < 100 ) where mod(a,4) = 0;
insert into t5 select a from ( select level a from dual connect by level < 100 ) where mod(a,5) = 0;
insert into t6 select a from ( select level a from dual connect by level < 100 ) where mod(a,6) = 0;

--+LOAD_SQL set_property.sql;
