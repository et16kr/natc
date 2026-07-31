drop tablespace test_tbs including contents and datafiles;
drop table lt;
drop table gt;

create tablespace test_tbs datafile 'test_tbs.dbf' size 300M autoextend off;

create table lt( i1 integer, i2 integer, i3 varchar(30) )
partition by range( i2 )
(
  partition p1 values less than (5),
  partition p2 values less than (8),
  partition p3 values less than (10),
  partition p4 values less than (11),
  partition p5 values less than (16),
  partition p6 values less than (19),
  partition p7 values less than (22),
  partition p8 values less than (30),
  partition p9 values less than (32),
  partition p10 values less than (38),
  partition p11 values less than (42),
  partition p12 values less than (49),
  partition p13 values less than (53),
  partition p14 values less than (61),
  partition p15 values less than (63),
  partition p16 values less than (70),
  partition p17 values less than (74),
  partition p18 values less than (80),
  partition p19 values less than (88),
  partition p20 values default
)
tablespace test_tbs;

create table gt( i1 integer, i2 integer, i3 varchar(30) )
partition by range( i2 )
(
  partition p1 values less than (5),
  partition p2 values less than (8),
  partition p3 values less than (10),
  partition p4 values less than (11),
  partition p5 values less than (16),
  partition p6 values less than (19),
  partition p7 values less than (22),
  partition p8 values less than (30),
  partition p9 values less than (32),
  partition p10 values less than (38),
  partition p11 values less than (42),
  partition p12 values less than (49),
  partition p13 values less than (53),
  partition p14 values less than (61),
  partition p15 values less than (63),
  partition p16 values less than (70),
  partition p17 values less than (74),
  partition p18 values less than (80),
  partition p19 values less than (88),
  partition p20 values default
)
tablespace test_tbs;

create index lt_idx1 on lt(i3) local;

create index gt_idx1 on gt(i3);
create index gt_idx2 on gt(i1);
create index gt_idx3 on gt(i2);
create index gt_idx4 on gt(i1,i2);