DEF FINALIZE_CHECK_GLOBAL_INDEX()
{
SKIP BEGIN;
drop function get_oid;
SKIP END;
}

DEF PREPARE_CHECK_GLOBAL_INDEX()
{
SKIP BEGIN;
drop function get_oid;
SKIP END;
    
create function get_oid( tablename varchar(40), partname varchar(40) )
return bigint
as
  v1 bigint;
begin
  select p.partition_oid into v1
  from system_.sys_tables_ t, system_.sys_table_partitions_ p
  where t.table_name = tablename and t.user_id = user_id() and p.partition_name = partname
  and t.table_id = p.table_id;

  return v1;
end;
/
}

DEF CHECK_GLOBAL_INDEX()
{
###################################
# create index t1_pk;
###################################

set linesize 200;
alter session set explain plan = off;

# should be no rows
select a.*, b.*
from 
(
  select nvl(i2,-1000) i2, nvl(i1,-1000) i1, get_oid('T1','P1') oid, cast(_prowid as bigint) rid from t1 partition (p1)
  union all
  select nvl(i2,-1000) i2, nvl(i1,-1000) i1, get_oid('T1','P2') oid, cast(_prowid as bigint) rid from t1 partition (p2)
  union all
  select nvl(i2,-1000) i2, nvl(i1,-1000) i1, get_oid('T1','P3') oid, cast(_prowid as bigint) rid from t1 partition (p3)
  union all
  select nvl(i2,-1000) i2, nvl(i1,-1000) i1, get_oid('T1','P4') oid, cast(_prowid as bigint) rid from t1 partition (p4)
  union all
  select nvl(i2,-1000) i2, nvl(i1,-1000) i1, get_oid('T1','PD') oid, cast(_prowid as bigint) rid from t1 partition (pd)
) a 
full outer join
(
  select nvl(i2,-1000) i2, nvl(i1,-1000) i1, "$GIT_OID", "$GIT_RID" from "$GIT_T1_PK"
) b 
on a.i2 = b.i2 and a.i1 = b.i1 and a.oid = b."$GIT_OID" and a.rid = b."$GIT_RID"
where a.rid is null or b."$GIT_RID" is null;

###################################
# create index t1_uk;
###################################

# should be no rows
select a.*, b.*
from 
(
  select nvl(i3,-1000) i3, nvl(i2,-1000) i2, nvl(i1,-1000) i1, get_oid('T1','P1') oid, cast(_prowid as bigint) rid from t1 partition (p1)
  union all
  select nvl(i3,-1000) i3, nvl(i2,-1000) i2, nvl(i1,-1000) i1, get_oid('T1','P2') oid, cast(_prowid as bigint) rid from t1 partition (p2)
  union all
  select nvl(i3,-1000) i3, nvl(i2,-1000) i2, nvl(i1,-1000) i1, get_oid('T1','P3') oid, cast(_prowid as bigint) rid from t1 partition (p3)
  union all
  select nvl(i3,-1000) i3, nvl(i2,-1000) i2, nvl(i1,-1000) i1, get_oid('T1','P4') oid, cast(_prowid as bigint) rid from t1 partition (p4)
  union all
  select nvl(i3,-1000) i3, nvl(i2,-1000) i2, nvl(i1,-1000) i1, get_oid('T1','PD') oid, cast(_prowid as bigint) rid from t1 partition (pd)
) a 
full outer join 
(
  select nvl(i3,-1000) i3, nvl(i2,-1000) i2, nvl(i1,-1000) i1, "$GIT_OID", "$GIT_RID" from "$GIT_T1_UK"
) b
on a.i3 = b.i3 and a.i2 = b.i2 and a.i1 = b.i1 and a.oid = b."$GIT_OID" and a.rid = b."$GIT_RID"
where a.rid is null or b."$GIT_RID" is null;

###################################
# create index t1_idx1 on t1(i2);
###################################

# should be no rows
select a.*, b.*
from 
(
  select nvl(i2,-1000) i2, get_oid('T1','P1') oid, cast(_prowid as bigint) rid from t1 partition (p1)
  union all
  select nvl(i2,-1000) i2, get_oid('T1','P2') oid, cast(_prowid as bigint) rid from t1 partition (p2)
  union all
  select nvl(i2,-1000) i2, get_oid('T1','P3') oid, cast(_prowid as bigint) rid from t1 partition (p3)
  union all
  select nvl(i2,-1000) i2, get_oid('T1','P4') oid, cast(_prowid as bigint) rid from t1 partition (p4)
  union all
  select nvl(i2,-1000) i2, get_oid('T1','PD') oid, cast(_prowid as bigint) rid from t1 partition (pd)
) a 
full outer join
(
  select nvl(i2,-1000) i2, "$GIT_OID", "$GIT_RID" from "$GIT_T1_IDX1"
) b
on a.i2 = b.i2 and a.oid = b."$GIT_OID" and a.rid = b."$GIT_RID"
where a.rid is null or b."$GIT_RID" is null;

###################################
# create index t1_idx2 on t1(i2, i3, i4);
###################################

# should be no rows
select a.*, b.*
from 
(
  select nvl(i2,-1000) i2, nvl(i3,-1000) i3, nvl(i4,-1000) i4, get_oid('T1','P1') oid, cast(_prowid as bigint) rid from t1 partition (p1)
  union all
  select nvl(i2,-1000) i2, nvl(i3,-1000) i3, nvl(i4,-1000) i4, get_oid('T1','P2') oid, cast(_prowid as bigint) rid from t1 partition (p2)
  union all
  select nvl(i2,-1000) i2, nvl(i3,-1000) i3, nvl(i4,-1000) i4, get_oid('T1','P3') oid, cast(_prowid as bigint) rid from t1 partition (p3)
  union all
  select nvl(i2,-1000) i2, nvl(i3,-1000) i3, nvl(i4,-1000) i4, get_oid('T1','P4') oid, cast(_prowid as bigint) rid from t1 partition (p4)
  union all
  select nvl(i2,-1000) i2, nvl(i3,-1000) i3, nvl(i4,-1000) i4, get_oid('T1','PD') oid, cast(_prowid as bigint) rid from t1 partition (pd)
) a 
full outer join
(
  select nvl(i2,-1000) i2, nvl(i3,-1000) i3, nvl(i4,-1000) i4, "$GIT_OID", "$GIT_RID" from "$GIT_T1_IDX2"
) b
on a.i2 = b.i2 and a.i3 = b.i3 and a.i4 = b.i4 and a.oid = b."$GIT_OID" and a.rid = b."$GIT_RID"
where a.rid is null or b."$GIT_RID" is null;

###################################
# create index t1_idx3 on t1(i3, i2);
###################################

# should be no rows
select a.*, b.*
from 
(
  select nvl(i3,-1000) i3, nvl(i2,-1000) i2, get_oid('T1','P1') oid, cast(_prowid as bigint) rid from t1 partition (p1)
  union all
  select nvl(i3,-1000) i3, nvl(i2,-1000) i2, get_oid('T1','P2') oid, cast(_prowid as bigint) rid from t1 partition (p2)
  union all
  select nvl(i3,-1000) i3, nvl(i2,-1000) i2, get_oid('T1','P3') oid, cast(_prowid as bigint) rid from t1 partition (p3)
  union all
  select nvl(i3,-1000) i3, nvl(i2,-1000) i2, get_oid('T1','P4') oid, cast(_prowid as bigint) rid from t1 partition (p4)
  union all
  select nvl(i3,-1000) i3, nvl(i2,-1000) i2, get_oid('T1','PD') oid, cast(_prowid as bigint) rid from t1 partition (pd)
) a 
full outer join
(
  select nvl(i3,-1000) i3, nvl(i2,-1000) i2, "$GIT_OID", "$GIT_RID" from "$GIT_T1_IDX3"
) b
on a.i3 = b.i3 and a.i2 = b.i2 and a.oid = b."$GIT_OID" and a.rid = b."$GIT_RID"
where a.rid is null or b."$GIT_RID" is null;

###################################
# create index t1_idx4 on t1(i4, i3);
###################################

# should be no rows
select a.*, b.*
from 
(
  select nvl(i4,-1000) i4, nvl(i3,-1000) i3, get_oid('T1','P1') oid, cast(_prowid as bigint) rid from t1 partition (p1)
  union all
  select nvl(i4,-1000) i4, nvl(i3,-1000) i3, get_oid('T1','P2') oid, cast(_prowid as bigint) rid from t1 partition (p2)
  union all
  select nvl(i4,-1000) i4, nvl(i3,-1000) i3, get_oid('T1','P3') oid, cast(_prowid as bigint) rid from t1 partition (p3)
  union all
  select nvl(i4,-1000) i4, nvl(i3,-1000) i3, get_oid('T1','P4') oid, cast(_prowid as bigint) rid from t1 partition (p4)
  union all
  select nvl(i4,-1000) i4, nvl(i3,-1000) i3, get_oid('T1','PD') oid, cast(_prowid as bigint) rid from t1 partition (pd)
) a 
full outer join
(
  select nvl(i4,-1000) i4, nvl(i3,-1000) i3, "$GIT_OID", "$GIT_RID" from "$GIT_T1_IDX4"
) b
on a.i4 = b.i4 and a.i3 = b.i3 and a.oid = b."$GIT_OID" and a.rid = b."$GIT_RID"
where a.rid is null or b."$GIT_RID" is null;

###################################
# create index t1_idx5 on t1(i4);
###################################

# should be no rows
select a.*, b.*
from 
(
  select nvl(i4,-1000) i4, get_oid('T1','P1') oid, cast(_prowid as bigint) rid from t1 partition (p1)
  union all
  select nvl(i4,-1000) i4, get_oid('T1','P2') oid, cast(_prowid as bigint) rid from t1 partition (p2)
  union all
  select nvl(i4,-1000) i4, get_oid('T1','P3') oid, cast(_prowid as bigint) rid from t1 partition (p3)
  union all
  select nvl(i4,-1000) i4, get_oid('T1','P4') oid, cast(_prowid as bigint) rid from t1 partition (p4)
  union all
  select nvl(i4,-1000) i4, get_oid('T1','PD') oid, cast(_prowid as bigint) rid from t1 partition (pd)
) a 
full outer join 
(
  select nvl(i4,-1000) i4, "$GIT_OID", "$GIT_RID" from "$GIT_T1_IDX5"
) b
on a.i4 = b.i4 and a.oid = b."$GIT_OID" and a.rid = b."$GIT_RID"
where a.rid is null or b."$GIT_RID" is null;

alter session set explain plan = on;

}
