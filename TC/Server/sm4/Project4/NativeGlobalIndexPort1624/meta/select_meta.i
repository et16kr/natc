###########################################################################
# NativeGlobalIndexPort1624 - SELECT_META 의 네이티브 재정의 (배치 6·7)
#
# 원본 meta/select_meta.i (= PROJ-1624-QC/select_meta.i, 두 파일은 바이트
# 동일하다) 를 대신한다. 원본이 정의하던 DEF 넷을 **같은 이름, 같은 인자**
# 로 다시 정의하므로, 이 배치 11 개 케이스의 CALL 자리는 원본과 바이트
# 동일하게 남는다 -- 배치 4 의 checkFunctionIndex.i, 배치 5 의
# desc_global_index.i 가 쓴 것과 같은 수법이다.
#
# 넷 중 갈아 끼운 것은 SELECT_META() 하나다. CREATE_BACKUP_META() /
# DROP_BACKUP_META() / COMPARE_META() 는 매체를 묻지 않는다 -- 카탈로그
# 여섯 장을 통째로 떠서 DDL 앞뒤를 차집합으로 견주는 절이고, 네이티브
# 에서도 재는 것이 같다(오히려 여기서 더 값지다: 숨김 테이블이 없으므로
# 잔재가 남으면 그것을 가려 줄 것도 없다). 그래서 원본 그대로 옮겼다.
#
# ---------------------------------------------------------------------
# ★ 원본 SELECT_META() 는 무엇을 하고 있었나
# ---------------------------------------------------------------------
#   질의 1  sys_tables_   where table_name like '$%'   -> 숨김 테이블 목록
#   질의 2  sys_columns_  같은 테이블의 컬럼           -> $GIT_OID/$GIT_RID
#   질의 3  sys_indices_  where index_name like '$%'   -> $GIK_ / $GIR_
#   질의 4  sys_index_columns_ 그 인덱스들의 키 컬럼
#
# 즉 "글로벌 인덱스가 카탈로그에 **이렇게 보인다**" 이다. 네이티브에서는
# 그 넷이 전부 빈 표가 된다 -- 방향이 통째로 뒤집힌다. 빈 표만 적으면
# 질의가 깨져도 빈 표이므로(원본의 is_global 질의가 실제로 그렇게 죽어
# 있었다 -- v4-natc-port-4.md 2), 없음은 **값 0** 으로 적고 그 자리에
# 네이티브가 무엇을 두는지를 같은 수의 질의로 이어 적는다.
#
# ---------------------------------------------------------------------
# ★ 네 겹 (원본 네 질의와 자리를 맞춘다)
# ---------------------------------------------------------------------
#   겹 0  숨김 객체가 없다. $GIT_ 테이블 수와 $ 로 시작하는 테이블 수,
#         $GIK_/$GIR_ 인덱스 수와 $ 로 시작하는 인덱스 수를 따로 센다.
#         (원본 질의 1·3 의 자리. 전부 0 이어야 한다.)
#   겹 1  그 자리에 있는 것 -- 파티션드 테이블 위의 인덱스 전량과 판별자.
#         원본이 숨김 테이블의 소유자/유형/테이블스페이스를 적던 자리다.
#
# ★ 겹 1~3 은 **이 케이스가 만든 T1·T2 로 좁힌다.** 원본의 like '$%' 는
#   스스로 좁아 있었다(숨김 객체는 케이스가 만든 것뿐이다). 그것을 그대로
#   "파티션드 테이블 전량" 으로 옮기면 이웃 케이스가 남긴 테이블까지 세게
#   되고, 그러면 이 케이스의 기대값이 자기가 한 일이 아니라 스위트 순서의
#   함수가 된다 -- 배치 4 의 BUG-35460 이 실제로 그렇게 되어 있었다
#   (v4-natc-port-2.md 5.2). T1·T2·T3 은 이 조각을 INCLUDE 하는 11 개
#   케이스가 쓰는 이름 전부다(배치 6 의 여덟은 T1·T2, 배치 7 의
#   index.tc 가 T3 을 더한다). 겹 0 의 두 셈만 스위트 전역이며, 그것은
#   "이 스위트의 어느 케이스도 숨김 객체를 만들지 않는다" 라는 더 센
#   진술이라 일부러 좁히지 않았다.
#   겹 2  키 컬럼과 자료형. 원본 질의 2 가 숨김 테이블의 컬럼을 적던 자리
#         이며, 거기 있던 $GIT_OID/$GIT_RID BIGINT 두 줄이 네이티브에는
#         없다는 것이 겹 0 의 0 과 짝을 이룬다.
#   겹 3  SYS_PART_INDICES_ 의 판별자 행과 인덱스 파티션 수. 글로벌이면
#         파티션 수 0 · 판별자 101, 로컬이면 파티션 수 = 테이블 파티션 수.
#
# ★ 인덱스 ID·테이블 ID·OID 는 한 줄도 내지 않는다. 인스턴스가 여태 만든
#   객체 수의 함수라 실행마다 달라진다(NEEDS_FRESH_INSTANCE). 원본이
#   order by t.table_id / i.index_id 로 정렬하던 것도 이름 정렬로 바꿨다 --
#   ID 를 찍지 않으면서 ID 순서에 기대면 그 순서가 전사에만 남는다.
###########################################################################

DEF SELECT_META()
{
# 겹 0 -- 숨김 객체가 없다 (원본 질의 1·3 의 자리)
select count(case when t.table_name like '$GIT!_%' escape '!' then 1 end) git_table,
       count(*) dollar_table
from system_.sys_tables_ t
where t.table_name like '$%';

select count(case when i.index_name like '$GIK!_%' escape '!' then 1 end) gik_index,
       count(case when i.index_name like '$GIR!_%' escape '!' then 1 end) gir_index,
       count(*) dollar_index
from system_.sys_indices_ i
where i.index_name like '$%';

# 겹 1 -- 그 자리에 있는 것 (파티션드 테이블 위의 인덱스 전량)
select cast(u.user_name as varchar(8)) user_name,
       cast(t.table_name as varchar(6)) table_name,
       cast(i.index_name as varchar(8)) index_name,
       cast( case when i.index_table_id != 0          then 'GIT-HIDDEN-TABLE'
                  when i.is_partitioned = 'T'         then 'LOCAL'
                  when nvl(p.partition_type,-1) = 101 then 'NATIVE-GLOBAL'
                  else 'UNKNOWN' end as varchar(16) ) kind,
       cast(i.is_unique as varchar(2)) uq,
       cast(b.name as varchar(18)) tbs_name
from system_.sys_indices_ i, system_.sys_tables_ t, system_.sys_users_ u,
     v$tablespaces b,
     ( select index_id, max(partition_type) partition_type
       from system_.sys_part_indices_ group by index_id ) p
where i.table_id = t.table_id
  and i.user_id = u.user_id
  and i.tbs_id = b.id
  and i.index_id = p.index_id(+)
  and t.table_id in ( select table_id from system_.sys_part_tables_ )
  and t.table_name in ( 'T1', 'T2', 'T3' )
order by 1, 2, 3;

# 겹 2 -- 키 컬럼과 자료형 (원본 질의 2·4 의 자리)
select cast(u.user_name as varchar(8)) user_name,
       cast(t.table_name as varchar(6)) table_name,
       cast(i.index_name as varchar(8)) index_name,
       j.index_col_order ord,
       cast(c.column_name as varchar(8)) column_name,
       cast(d.type_name as varchar(10)) type_name,
       cast(j.sort_order as varchar(2)) sort_order
from system_.sys_indices_ i, system_.sys_tables_ t, system_.sys_users_ u,
     system_.sys_index_columns_ j, system_.sys_columns_ c, v$datatype d
where i.table_id = t.table_id
  and i.user_id = u.user_id
  and i.index_id = j.index_id
  and j.column_id = c.column_id
  and c.data_type = d.data_type
  and t.table_id in ( select table_id from system_.sys_part_tables_ )
  and t.table_name in ( 'T1', 'T2', 'T3' )
order by 1, 2, 3, 4;

# 겹 3 -- 판별자 행과 인덱스 파티션 수
select cast(u.user_name as varchar(8)) user_name,
       cast(t.table_name as varchar(6)) table_name,
       cast(i.index_name as varchar(8)) index_name,
       cast( ( select count(*) from system_.sys_part_indices_ pi
               where pi.index_id = i.index_id ) as integer ) part_idx_rows,
       cast( ( select max(pi.partition_type) from system_.sys_part_indices_ pi
               where pi.index_id = i.index_id ) as integer ) part_type,
       cast( ( select count(*) from system_.sys_index_partitions_ ip
               where ip.index_id = i.index_id ) as integer ) idx_partitions
from system_.sys_indices_ i, system_.sys_tables_ t, system_.sys_users_ u
where i.table_id = t.table_id
  and i.user_id = u.user_id
  and t.table_id in ( select table_id from system_.sys_part_tables_ )
  and t.table_name in ( 'T1', 'T2', 'T3' )
order by 1, 2, 3;
}

###########################################################################
# 아래 셋은 원본 그대로다 -- 매체를 묻지 않는 카탈로그 차집합 검사.
###########################################################################

DEF DROP_BACKUP_META()
{
NODISPLAY ON;
SKIP BEGIN;
for $sBackup in
    "sys_tables_"
    "sys_columns_"
    "sys_indices_"
    "sys_index_columns_"
    "sys_constraints_"
    "sys_constraint_columns_"
{
    drop table ${sBackup}backup;
}
SKIP END;
NODISPLAY OFF;
}

DEF CREATE_BACKUP_META()
{
CALL DROP_BACKUP_META();    

NODISPLAY ON;
for $sBackup in
    "sys_tables_"
    "sys_columns_"
    "sys_indices_"
    "sys_index_columns_"
    "sys_constraints_"
    "sys_constraint_columns_"
{
    create table ${sBackup}backup as select * from system_.${sBackup} limit 1;
    delete from ${sBackup}backup;
}

for $sBackup in
    "sys_tables_"
    "sys_columns_"
    "sys_indices_"
    "sys_index_columns_"
    "sys_constraints_"
    "sys_constraint_columns_"
{
    insert into ${sBackup}backup select * from system_.${sBackup};
}
NODISPLAY OFF;

}

DEF COMPARE_META()
{
select table_name from (
    select * from system_.sys_tables_ minus select * from sys_tables_backup
)
order by table_name;
select table_name from (
    select * from sys_tables_backup minus select * from system_.sys_tables_
)
order by table_name;
    
select column_name from (
    select * from system_.sys_columns_ minus select * from sys_columns_backup
)
order by column_name;
select column_name from (
    select * from sys_columns_backup minus select * from system_.sys_columns_
)
order by column_name;

select index_name from (
    select * from system_.sys_indices_ minus select * from sys_indices_backup
)
order by index_name;
select index_name from (
    select * from sys_indices_backup minus select * from system_.sys_indices_
)
order by index_name;

select c.column_name index_column_name from (
    select * from system_.sys_index_columns_ minus select * from sys_index_columns_backup
) v1, system_.sys_columns_ c
where v1.column_id = c.column_id
order by c.column_id;
select c.column_name index_column_name from (
    select * from sys_index_columns_backup minus select * from system_.sys_index_columns_
) v1, system_.sys_columns_ c
where v1.column_id = c.column_id
order by c.column_id;

select constraint_name from (
    select * from system_.sys_constraints_ minus select * from sys_constraints_backup
)
order by constraint_name;
select constraint_name from (
    select * from sys_constraints_backup minus select * from system_.sys_constraints_
)
order by constraint_name;

select c.column_name constraint_column_name from (
    select * from system_.sys_constraint_columns_ minus select * from sys_constraint_columns_backup
) v1, system_.sys_columns_ c
where v1.column_id = c.column_id
order by c.column_id;
select c.column_name constraint_column_name from (
    select * from sys_constraint_columns_backup minus select * from system_.sys_constraint_columns_
) v1, system_.sys_columns_ c
where v1.column_id = c.column_id
order by c.column_id;

CALL DROP_BACKUP_META();
}
