###########################################################################
# Native Global Index - catalog inspection helpers
#
# 구버전(PROJ-1624)의 meta 테스트는 "숨김 객체가 이렇게 보인다"를
# 검증했다. 네이티브에서는 검증 방향이 정반대다: 숨김 객체가
# 생기지 않아야 하고, 대신 SYS_PART_INDICES_ 에 판별자 행이 하나 있어야
# 한다.
###########################################################################

#
# 숨김 글로벌 인덱스 객체가 하나도 없어야 한다.
# 구버전은 여기서 $GIT_/$GIK_/$GIR_ 가 줄줄이 나왔다.
#
DEF CHECK_NO_HIDDEN_OBJECT()
{
  # 숨김 인덱스 테이블 ($GIT_) - 없어야 정상
  select u.user_name, t.table_name, t.table_type
  from system_.sys_tables_ t, system_.sys_users_ u
  where t.table_name like '$GIT[_]%' escape '['
    and t.user_id = u.user_id
  order by t.table_name;

  # 숨김 인덱스 테이블의 인덱스 ($GIK_, $GIR_) - 없어야 정상
  select u.user_name, i.index_name
  from system_.sys_indices_ i, system_.sys_users_ u
  where ( i.index_name like '$GIK[_]%' escape '['
       or i.index_name like '$GIR[_]%' escape '[' )
    and i.user_id = u.user_id
  order by i.index_name;
}

#
# SYS_INDICES_ 에서 본 글로벌 인덱스의 모습.
#
# 네이티브 글로벌 인덱스는 숨김 방식과 마찬가지로 IS_PARTITIONED = 'F'
# 이지만, INDEX_TABLE_ID 가 0 이어야 한다(숨김 테이블이 없으므로).
# 숨김 방식은 INDEX_TABLE_ID 가 0 이 아니다. 이것이 두 방식의
# 카탈로그 상 구분점이다.
#
DEF SELECT_SYS_INDICES( @aTable )
{
  select i.index_name,
         i.is_unique,
         i.is_partitioned,
         decode(i.index_table_id, 0, 'ZERO', 'NONZERO') index_table_id_kind
  from system_.sys_indices_ i, system_.sys_tables_ t
  where i.table_id = t.table_id
    and t.table_name = upper('@{aTable}')
    and t.user_id = user_id()
  order by i.index_name;
}

#
# SYS_PART_INDICES_ 의 판별자 행.
#
# 네이티브 글로벌 인덱스는 여기에 행을 하나 남긴다. 캐시 로더가
# IS_PARTITIONED='F' 를 보고 무조건 non-partitioned 로 하드코딩하기
# 때문에, 재기동 후에도 네이티브임을 알아보려면 이 행이 필요하다.
# 숨김 방식은 이 행을 만들지 않는다.
#
DEF SELECT_SYS_PART_INDICES( @aTable )
{
  select i.index_name, p.partition_type
  from system_.sys_part_indices_ p, system_.sys_indices_ i, system_.sys_tables_ t
  where p.index_id = i.index_id
    and i.table_id = t.table_id
    and t.table_name = upper('@{aTable}')
    and t.user_id = user_id()
  order by i.index_name;
}

#
# SYS_INDEX_PARTITIONS_ 에는 행이 없어야 한다.
# 물리 인덱스가 파티션별로 존재하지 않는 것이 로컬 인덱스와의 구분점이다.
#
DEF SELECT_SYS_INDEX_PARTITIONS( @aTable )
{
  select i.index_name, count(*) part_index_cnt
  from system_.sys_index_partitions_ p, system_.sys_indices_ i, system_.sys_tables_ t
  where p.index_id = i.index_id
    and i.table_id = t.table_id
    and t.table_name = upper('@{aTable}')
    and t.user_id = user_id()
  group by i.index_name
  order by i.index_name;
}

#
# 한 테이블의 인덱스 카탈로그 전경.
#
DEF SELECT_INDEX_META( @aTable )
{
  CALL SELECT_SYS_INDICES( "@{aTable}" );
  CALL SELECT_SYS_PART_INDICES( "@{aTable}" );
  CALL SELECT_SYS_INDEX_PARTITIONS( "@{aTable}" );
  CALL CHECK_NO_HIDDEN_OBJECT();
}
