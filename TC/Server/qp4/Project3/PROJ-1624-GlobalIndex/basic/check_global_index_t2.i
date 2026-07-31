DEF CHECK_GLOBAL_INDEX_T2()
{
###################################
# create index t2_pk;
###################################

set linesize 200;
alter session set explain plan = off;

# should be no rows
select a.*, b.*
from 
(
  select nvl(i2,-1000) i2, nvl(i1,-1000) i1, get_oid('T2','P1') oid, cast(_prowid as bigint) rid from t2 partition (p1)
  union all
  select nvl(i2,-1000) i2, nvl(i1,-1000) i1, get_oid('T2','P2') oid, cast(_prowid as bigint) rid from t2 partition (p2)
  union all
  select nvl(i2,-1000) i2, nvl(i1,-1000) i1, get_oid('T2','P3') oid, cast(_prowid as bigint) rid from t2 partition (p3)
  union all
  select nvl(i2,-1000) i2, nvl(i1,-1000) i1, get_oid('T2','P4') oid, cast(_prowid as bigint) rid from t2 partition (p4)
  union all
  select nvl(i2,-1000) i2, nvl(i1,-1000) i1, get_oid('T2','PD') oid, cast(_prowid as bigint) rid from t2 partition (pd)
) a 
full outer join
(
  select nvl(i2,-1000) i2, nvl(i1,-1000) i1, "$GIT_OID", "$GIT_RID" from "$GIT_T2_PK"
) b 
on a.i2 = b.i2 and a.i1 = b.i1 and a.oid = b."$GIT_OID" and a.rid = b."$GIT_RID"
where a.rid is null or b."$GIT_RID" is null;

###################################
# create index t2_uk;
###################################

# should be no rows
select a.*, b.*
from 
(
  select nvl(i3,-1000) i3, nvl(i2,-1000) i2, nvl(i1,-1000) i1, get_oid('T2','P1') oid, cast(_prowid as bigint) rid from t2 partition (p1)
  union all
  select nvl(i3,-1000) i3, nvl(i2,-1000) i2, nvl(i1,-1000) i1, get_oid('T2','P2') oid, cast(_prowid as bigint) rid from t2 partition (p2)
  union all
  select nvl(i3,-1000) i3, nvl(i2,-1000) i2, nvl(i1,-1000) i1, get_oid('T2','P3') oid, cast(_prowid as bigint) rid from t2 partition (p3)
  union all
  select nvl(i3,-1000) i3, nvl(i2,-1000) i2, nvl(i1,-1000) i1, get_oid('T2','P4') oid, cast(_prowid as bigint) rid from t2 partition (p4)
  union all
  select nvl(i3,-1000) i3, nvl(i2,-1000) i2, nvl(i1,-1000) i1, get_oid('T2','PD') oid, cast(_prowid as bigint) rid from t2 partition (pd)
) a 
full outer join 
(
  select nvl(i3,-1000) i3, nvl(i2,-1000) i2, nvl(i1,-1000) i1, "$GIT_OID", "$GIT_RID" from "$GIT_T2_UK"
) b
on a.i3 = b.i3 and a.i2 = b.i2 and a.i1 = b.i1 and a.oid = b."$GIT_OID" and a.rid = b."$GIT_RID"
where a.rid is null or b."$GIT_RID" is null;

###################################
# create index t2_idx1 on t1(i2);
###################################

# should be no rows
select a.*, b.*
from 
(
  select nvl(i2,-1000) i2, get_oid('T2','P1') oid, cast(_prowid as bigint) rid from t2 partition (p1)
  union all
  select nvl(i2,-1000) i2, get_oid('T2','P2') oid, cast(_prowid as bigint) rid from t2 partition (p2)
  union all
  select nvl(i2,-1000) i2, get_oid('T2','P3') oid, cast(_prowid as bigint) rid from t2 partition (p3)
  union all
  select nvl(i2,-1000) i2, get_oid('T2','P4') oid, cast(_prowid as bigint) rid from t2 partition (p4)
  union all
  select nvl(i2,-1000) i2, get_oid('T2','PD') oid, cast(_prowid as bigint) rid from t2 partition (pd)
) a 
full outer join
(
  select nvl(i2,-1000) i2, "$GIT_OID", "$GIT_RID" from "$GIT_T2_IDX1"
) b
on a.i2 = b.i2 and a.oid = b."$GIT_OID" and a.rid = b."$GIT_RID"
where a.rid is null or b."$GIT_RID" is null;

###################################
# create index t2_idx2 on t1(i2, i3, i4);
###################################

# should be no rows
select a.*, b.*
from 
(
  select nvl(i2,-1000) i2, nvl(i3,-1000) i3, nvl(i4,-1000) i4, get_oid('T2','P1') oid, cast(_prowid as bigint) rid from t2 partition (p1)
  union all
  select nvl(i2,-1000) i2, nvl(i3,-1000) i3, nvl(i4,-1000) i4, get_oid('T2','P2') oid, cast(_prowid as bigint) rid from t2 partition (p2)
  union all
  select nvl(i2,-1000) i2, nvl(i3,-1000) i3, nvl(i4,-1000) i4, get_oid('T2','P3') oid, cast(_prowid as bigint) rid from t2 partition (p3)
  union all
  select nvl(i2,-1000) i2, nvl(i3,-1000) i3, nvl(i4,-1000) i4, get_oid('T2','P4') oid, cast(_prowid as bigint) rid from t2 partition (p4)
  union all
  select nvl(i2,-1000) i2, nvl(i3,-1000) i3, nvl(i4,-1000) i4, get_oid('T2','PD') oid, cast(_prowid as bigint) rid from t2 partition (pd)
) a 
full outer join
(
  select nvl(i2,-1000) i2, nvl(i3,-1000) i3, nvl(i4,-1000) i4, "$GIT_OID", "$GIT_RID" from "$GIT_T2_IDX2"
) b
on a.i2 = b.i2 and a.i3 = b.i3 and a.i4 = b.i4 and a.oid = b."$GIT_OID" and a.rid = b."$GIT_RID"
where a.rid is null or b."$GIT_RID" is null;

###################################
# create index t2_idx3 on t1(i3, i2);
###################################

# should be no rows
select a.*, b.*
from 
(
  select nvl(i3,-1000) i3, nvl(i2,-1000) i2, get_oid('T2','P1') oid, cast(_prowid as bigint) rid from t2 partition (p1)
  union all
  select nvl(i3,-1000) i3, nvl(i2,-1000) i2, get_oid('T2','P2') oid, cast(_prowid as bigint) rid from t2 partition (p2)
  union all
  select nvl(i3,-1000) i3, nvl(i2,-1000) i2, get_oid('T2','P3') oid, cast(_prowid as bigint) rid from t2 partition (p3)
  union all
  select nvl(i3,-1000) i3, nvl(i2,-1000) i2, get_oid('T2','P4') oid, cast(_prowid as bigint) rid from t2 partition (p4)
  union all
  select nvl(i3,-1000) i3, nvl(i2,-1000) i2, get_oid('T2','PD') oid, cast(_prowid as bigint) rid from t2 partition (pd)
) a 
full outer join
(
  select nvl(i3,-1000) i3, nvl(i2,-1000) i2, "$GIT_OID", "$GIT_RID" from "$GIT_T2_IDX3"
) b
on a.i3 = b.i3 and a.i2 = b.i2 and a.oid = b."$GIT_OID" and a.rid = b."$GIT_RID"
where a.rid is null or b."$GIT_RID" is null;

###################################
# create index t2_idx4 on t1(i4, i3);
###################################

# should be no rows
select a.*, b.*
from 
(
  select nvl(i4,-1000) i4, nvl(i3,-1000) i3, get_oid('T2','P1') oid, cast(_prowid as bigint) rid from t2 partition (p1)
  union all
  select nvl(i4,-1000) i4, nvl(i3,-1000) i3, get_oid('T2','P2') oid, cast(_prowid as bigint) rid from t2 partition (p2)
  union all
  select nvl(i4,-1000) i4, nvl(i3,-1000) i3, get_oid('T2','P3') oid, cast(_prowid as bigint) rid from t2 partition (p3)
  union all
  select nvl(i4,-1000) i4, nvl(i3,-1000) i3, get_oid('T2','P4') oid, cast(_prowid as bigint) rid from t2 partition (p4)
  union all
  select nvl(i4,-1000) i4, nvl(i3,-1000) i3, get_oid('T2','PD') oid, cast(_prowid as bigint) rid from t2 partition (pd)
) a 
full outer join
(
  select nvl(i4,-1000) i4, nvl(i3,-1000) i3, "$GIT_OID", "$GIT_RID" from "$GIT_T2_IDX4"
) b
on a.i4 = b.i4 and a.i3 = b.i3 and a.oid = b."$GIT_OID" and a.rid = b."$GIT_RID"
where a.rid is null or b."$GIT_RID" is null;

###################################
# create index t2_idx5 on t1(i4);
###################################

# should be no rows
select a.*, b.*
from 
(
  select nvl(i4,-1000) i4, get_oid('T2','P1') oid, cast(_prowid as bigint) rid from t2 partition (p1)
  union all
  select nvl(i4,-1000) i4, get_oid('T2','P2') oid, cast(_prowid as bigint) rid from t2 partition (p2)
  union all
  select nvl(i4,-1000) i4, get_oid('T2','P3') oid, cast(_prowid as bigint) rid from t2 partition (p3)
  union all
  select nvl(i4,-1000) i4, get_oid('T2','P4') oid, cast(_prowid as bigint) rid from t2 partition (p4)
  union all
  select nvl(i4,-1000) i4, get_oid('T2','PD') oid, cast(_prowid as bigint) rid from t2 partition (pd)
) a 
full outer join 
(
  select nvl(i4,-1000) i4, "$GIT_OID", "$GIT_RID" from "$GIT_T2_IDX5"
) b
on a.i4 = b.i4 and a.oid = b."$GIT_OID" and a.rid = b."$GIT_RID"
where a.rid is null or b."$GIT_RID" is null;

alter session set explain plan = on;

}
