--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/indexThrMovement.sql
--#
--# Body below is byte-identical to the original. The one line this port
--# adds is the premise: the original measures these statements on the
--# $GIT_ hidden-table implementation, this file measures the same
--# statements on the native global index (F07 -- see include/pinNative.sql).
--###########################################################################
--+LOAD_SQL ../include/pinNative.sql;

--##########################################################################
--# Parallel Index Rebuilding by Index Direction
--##########################################################################

--############################################################################
--# INDEX THREAD MOVEMENT RESTART PARALLEL
--############################################################################

--######################################
--+SECTOR; PREPARATION
--######################################

--+SYSTEM server kill;
--+SET_ENV ALTIBASE_PARALLEL_LOAD_FACTOR = 2;
--+SET_ENV ALTIBASE_INDEX_BUILD_THREAD_COUNT = 4;
--+SET_ENV ALTIBASE_INDEX_BUILD_MIN_RECORD_COUNT = 100;
--+SYSTEM server start;

--+SKIP BEGIN;
DROP TABLE klein;
DROP TABLE gross;
DROP TABLE gross2;
DROP TABLE gross3;
DROP TABLE gross4;
--+SKIP END;

create table klein (k integer)
partition by range(k)
(
	partition p1 values less than('3'),
	partition p2 values less than('7'),
	partition p3 values default
) tablespace sys_tbs_disk_data;

create table gross (i1 bigint, i2 blob, i3 char(10), i4 date, i5 decimal(10,2),
                    i6 double, i7 float, i8 byte(10), i9 nibble(10),
                    ia integer, ib number(10), ic real, id smallint, ie varchar(10)
)
partition by range(ia)
(
	partition p1 values less than('1000'),
	partition p2 values less than('3000'),
	partition p3 values less than('5000'),
	partition p4 values less than('7000'),
	partition p5 values less than('9000'),
	partition p6 values default
) tablespace sys_tbs_disk_data;

create table gross2 (i1 bigint, i2 blob, i3 char(10), i4 date, i5 decimal(10,2),
                    i6 double, i7 float, i8 byte(10), i9 nibble(10),
                    ia integer, ib number(10), ic real, id smallint, ie varchar(10)
)
partition by range(ia)
(
	partition p1 values less than('1000'),
	partition p2 values less than('3000'),
	partition p3 values less than('5000'),
	partition p4 values less than('7000'),
	partition p5 values less than('9000'),
	partition p6 values default
) tablespace sys_tbs_disk_data;

create table gross3 (i1 bigint, i2 blob, i3 char(10), i4 date, i5 decimal(10,2),
                    i6 double, i7 float, i8 byte(10), i9 nibble(10),
                    ia integer, ib number(10), ic real, id smallint, ie varchar(10)
)
partition by range(ia)
(
	partition p1 values less than('1000'),
	partition p2 values less than('3000'),
	partition p3 values less than('5000'),
	partition p4 values less than('7000'),
	partition p5 values less than('9000'),
	partition p6 values default
) tablespace sys_tbs_disk_data;

create table gross4 (i1 bigint, i2 blob, i3 char(10), i4 date, i5 decimal(10,2),
                    i6 double, i7 float, i8 byte(10), i9 nibble(10),
                    ia integer, ib number(10), ic real, id smallint, ie varchar(10)
)
partition by range(ia)
(
	partition p1 values less than('1000'),
	partition p2 values less than('3000'),
	partition p3 values less than('5000'),
	partition p4 values less than('7000'),
	partition p5 values less than('9000'),
	partition p6 values default
) tablespace sys_tbs_disk_data;

-- create 10 records 0..9
insert into klein(k) values(0);
insert into klein(k) values(1);
insert into klein(k) values(2);
insert into klein(k) values(3);
insert into klein(k) values(4);
insert into klein(k) values(5);
insert into klein(k) values(6);
insert into klein(k) values(7);
insert into klein(k) values(8);
insert into klein(k) values(9);
-- create 10000 records 0..9999
create index i_klein on klein(k);

insert into gross(ia,ib,id)
select
k1.k*1000+k2.k*100+k3.k*10+k4.k,
k1.k*1000+k2.k*100+k3.k*10+k4.k,
k1.k*1000+k2.k*100+k3.k*10+k4.k
from klein k1,
klein k2,
klein k3,
klein k4;

update gross set i3 = ia||'A', i4 = SYSDATE, ie = ia||'B';

insert into gross2 select * from gross;
insert into gross3 select * from gross;
insert into gross4 select * from gross;

--######################################
--+SECTOR; VALIDATION BEFORE
--######################################

select count(*) from gross;
select count(*) from gross where ia > 9000;
select i1,i3,i5,i6,i7,ia,ib,ic,id,ie from gross where ia = 8999;
select count(*) from gross where i3 > '9000A';
select i1,i3,i5,i6,i7,ia,ib,ic,id,ie from gross where i3 = '8999A';
select i1,i3,i5,i6,i7,ia,ib,ic,id,ie from gross where i3 like '8999%';

select count(*) from gross2;
select count(*) from gross2 where ia > 9000;
select i1,i3,i5,i6,i7,ia,ib,ic,id,ie from gross2 where ia = 8999;
select count(*) from gross2 where i3 > '9000A';
select i1,i3,i5,i6,i7,ia,ib,ic,id,ie from gross2 where i3 = '8999A';
select i1,i3,i5,i6,i7,ia,ib,ic,id,ie from gross2 where i3 like '8999%';

select count(*) from gross3;
select count(*) from gross3 where ia > 9000;
select i1,i3,i5,i6,i7,ia,ib,ic,id,ie from gross3 where ia = 8999;
select count(*) from gross3 where i3 > '9000A';
select i1,i3,i5,i6,i7,ia,ib,ic,id,ie from gross3 where i3 = '8999A';
select i1,i3,i5,i6,i7,ia,ib,ic,id,ie from gross3 where i3 like '8999%';

select count(*) from gross4;
select count(*) from gross4 where ia > 9000;
select i1,i3,i5,i6,i7,ia,ib,ic,id,ie from gross4 where ia = 8999;
select count(*) from gross4 where i3 > '9000A';
select i1,i3,i5,i6,i7,ia,ib,ic,id,ie from gross4 where i3 = '8999A';
select i1,i3,i5,i6,i7,ia,ib,ic,id,ie from gross4 where i3 like '8999%';

--######################################
--+SECTOR; INDEX CREATION
--######################################

    --+PROCESS P1;
    alter table gross add primary key (ia);
    create index i_gross_34 on gross( i3 asc, i4 desc) indextype is btree;
    create index i_gross_b on gross( ib desc ) indextype is ttree;
    create index i_gross_d on gross( id desc ) indextype is btree;
    create unique index i_gross_e on gross( ie );

        --+PROCESS P2;
        alter table gross2 add primary key (ia);
        create index i_gross2_34 on gross2( i3 asc, i4 desc) indextype is btree;
        create index i_gross2_b on gross2( ib desc ) indextype is ttree;
        create index i_gross2_d on gross2( id desc ) indextype is btree;
        create unique index i_gross2_e on gross2( ie );

            --+PROCESS P3;
            alter table gross3 add primary key (ia);
            create index i_gross3_34 on gross3( i3 asc, i4 desc) indextype is btree;
            create index i_gross3_b on gross3( ib desc ) indextype is ttree;
            create index i_gross3_d on gross3( id desc ) indextype is btree;
            create unique index i_gross3_e on gross3( ie );

                --+PROCESS P4;
                alter table gross4 add primary key (ia);
                create index i_gross4_34 on gross4( i3 asc, i4 desc) indextype is btree;
                create index i_gross4_b on gross4( ib desc ) indextype is ttree;
                create index i_gross4_d on gross4( id desc ) indextype is btree;
                create unique index i_gross4_e on gross4( ie );
    --+PWAIT;

--######################################
--+SECTOR; VALIDATION
--######################################

select count(*) from gross;
select count(*) from gross where ia > 9000;
select i1,i3,i5,i6,i7,ia,ib,ic,id,ie from gross where ia = 8999;
select count(*) from gross where i3 > '9000A';
select i1,i3,i5,i6,i7,ia,ib,ic,id,ie from gross where i3 = '8999A';
select i1,i3,i5,i6,i7,ia,ib,ic,id,ie from gross where i3 like '8999%';

select count(*) from gross2;
select count(*) from gross2 where ia > 9000;
select i1,i3,i5,i6,i7,ia,ib,ic,id,ie from gross2 where ia = 8999;
select count(*) from gross2 where i3 > '9000A';
select i1,i3,i5,i6,i7,ia,ib,ic,id,ie from gross2 where i3 = '8999A';
select i1,i3,i5,i6,i7,ia,ib,ic,id,ie from gross2 where i3 like '8999%';

select count(*) from gross3;
select count(*) from gross3 where ia > 9000;
select i1,i3,i5,i6,i7,ia,ib,ic,id,ie from gross3 where ia = 8999;
select count(*) from gross3 where i3 > '9000A';
select i1,i3,i5,i6,i7,ia,ib,ic,id,ie from gross3 where i3 = '8999A';
select i1,i3,i5,i6,i7,ia,ib,ic,id,ie from gross3 where i3 like '8999%';

select count(*) from gross4;
select count(*) from gross4 where ia > 9000;
select i1,i3,i5,i6,i7,ia,ib,ic,id,ie from gross4 where ia = 8999;
select count(*) from gross4 where i3 > '9000A';
select i1,i3,i5,i6,i7,ia,ib,ic,id,ie from gross4 where i3 = '8999A';
select i1,i3,i5,i6,i7,ia,ib,ic,id,ie from gross4 where i3 like '8999%';

--######################################
--+SECTOR; VALIDATION AFTER SERVER RESTART
--######################################

--+SYSTEM server kill;
--+SYSTEM server start;

select count(*) from gross;
select count(*) from gross where ia > 9000;
select i1,i3,i5,i6,i7,ia,ib,ic,id,ie from gross where ia = 8999;
select count(*) from gross where i3 > '9000A';
select i1,i3,i5,i6,i7,ia,ib,ic,id,ie from gross where i3 = '8999A';
select i1,i3,i5,i6,i7,ia,ib,ic,id,ie from gross where i3 like '8999%';

select count(*) from gross2;
select count(*) from gross2 where ia > 9000;
select i1,i3,i5,i6,i7,ia,ib,ic,id,ie from gross2 where ia = 8999;
select count(*) from gross2 where i3 > '9000A';
select i1,i3,i5,i6,i7,ia,ib,ic,id,ie from gross2 where i3 = '8999A';
select i1,i3,i5,i6,i7,ia,ib,ic,id,ie from gross2 where i3 like '8999%';

select count(*) from gross3;
select count(*) from gross3 where ia > 9000;
select i1,i3,i5,i6,i7,ia,ib,ic,id,ie from gross3 where ia = 8999;
select count(*) from gross3 where i3 > '9000A';
select i1,i3,i5,i6,i7,ia,ib,ic,id,ie from gross3 where i3 = '8999A';
select i1,i3,i5,i6,i7,ia,ib,ic,id,ie from gross3 where i3 like '8999%';

select count(*) from gross4;
select count(*) from gross4 where ia > 9000;
select i1,i3,i5,i6,i7,ia,ib,ic,id,ie from gross4 where ia = 8999;
select count(*) from gross4 where i3 > '9000A';
select i1,i3,i5,i6,i7,ia,ib,ic,id,ie from gross4 where i3 = '8999A';
select i1,i3,i5,i6,i7,ia,ib,ic,id,ie from gross4 where i3 like '8999%';

--######################################
--+SECTOR; FINALIZATION
--######################################

DROP TABLE gross;
DROP TABLE gross2;
DROP TABLE gross3;
DROP TABLE gross4;
drop table klein;
