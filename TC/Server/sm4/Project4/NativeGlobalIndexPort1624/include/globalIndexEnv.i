###########################################################################
# NativeGlobalIndexPort1624 - 전제와 판별자
#
# 이 스위트의 전 케이스가 재는 것은 **디스크 파티션드 테이블 위의 네이티브
# 글로벌 인덱스**다. 원본(qp4/Project3/PROJ-1624-GlobalIndex)이 같은 문장으로
# 재던 것은 숨김 테이블 $GIT_ 였다. 갈림길은 프로퍼티 하나다:
#
#   DISK_GLOBAL_INDEX_ENABLE = 1  -> 네이티브 (이 스위트)
#   DISK_GLOBAL_INDEX_ENABLE = 0  -> $GIT_    (원본 스위트)
#
# ★ 그래서 케이스마다 자기 전제를 세운다(F07 규약).
#   파일 기본값은 2026-08-06 부터 1 이지만, 기본값에 기대면 그 값이 움직이는
#   날 이 스위트는 "네이티브를 잰다"고 적어 놓고 $GIT_ 를 재게 된다 --
#   원본 PROJ-1624 와 NATC ddl/diskPartitionedTable.tc 가 실제로 그렇게
#   어긋났었다(disk-natc.md 6).
#
# ★ 이 프로퍼티는 비영속이다. ALTER SYSTEM 값은 재기동하면 파일 값으로
#   돌아간다. 한 인스턴스 위에서 스위트가 이어 도는 동안은 FINALIZE 의
#   복원이 유일한 방벽이다.
###########################################################################

#
# 전제를 세우고, 세운 값을 전사에 남긴다.
# 전사가 자기 전제를 적게 하는 것이 목적이므로 v$property 조회를 뺄 수 없다.
#
DEF PIN_DISK_NATIVE()
{
  set linesize 200;
  alter system set DISK_GLOBAL_INDEX_ENABLE = 1;
  select cast(value1 as varchar(10)) disk_global_index_enable from v$property
  where name = 'DISK_GLOBAL_INDEX_ENABLE';
}

#
# 파일 기본값(1)으로 되돌린다. 다음 케이스에 0 이 새지 않게 한다.
#
DEF RESTORE_DISK_DEFAULT()
{
  alter system set DISK_GLOBAL_INDEX_ENABLE = 1;
}

#
# 인덱스가 어느 구현인지 카탈로그로 판별해 전사에 남긴다.
#
#   NATIVE GLOBAL : SYS_PART_INDICES_.PARTITION_TYPE = 101, INDEX_TABLE_ID = 0
#   LOCAL         : IS_PARTITIONED = 'T', SYS_INDEX_PARTITIONS_ 에 행
#   $GIT_ GLOBAL  : INDEX_TABLE_ID != 0 (숨김 테이블 OID)
#
# ★ 이 절이 이 스위트의 이빨이다. 프로퍼티가 0 이면 CREATE INDEX 로 만든
#   인덱스가 $GIT_ 로 내려가 KIND 가 통째로 바뀌고, 같은 문장을 재고 있다는
#   착각이 여기서 깨진다.
#
# ★ 원본 fixture 의 T1_PK(i2,i1) / T1_UK(i3,i2,i1) 은 파티션 키 i1 을
#   포함하므로 두 구현 어느 쪽에서도 글로벌이 아니라 LOCAL 이다. 원본
#   check_global_index.i 가 "$GIT_T1_PK" 를 조회한 것은 존재하지 않는
#   테이블을 겨눈 것이었다 -- v3-natc-port.md 3.2.
#
DEF SHOW_INDEX_MEDIA( @aTable )
{
  select cast(i.index_name as varchar(20)) index_name,
         cast( case when i.index_table_id != 0          then 'GIT-HIDDEN-TABLE'
                    when i.is_partitioned = 'T'         then 'LOCAL'
                    when nvl(p.partition_type,-1) = 101 then 'NATIVE-GLOBAL'
                    else 'UNKNOWN' end as varchar(16) ) kind,
         i.index_table_id,
         cast(i.is_partitioned as varchar(1)) is_part,
         nvl(p.partition_type,-1) part_type
  from system_.sys_indices_ i,
       system_.sys_tables_ t,
       ( select index_id, max(partition_type) partition_type
         from system_.sys_part_indices_ group by index_id ) p
  where i.table_id = t.table_id
    and t.table_name = upper('@{aTable}')
    and t.user_id = user_id()
    and i.index_id = p.index_id(+)
  order by 1;
}

#
# 숨김 테이블이 하나도 없다는 것을 남긴다.
# 네이티브 경로에서는 $GIT_ 가 만들어지지 않는다.
#
DEF SHOW_NO_HIDDEN_TABLE()
{
  select count(*) git_hidden_table_count
  from system_.sys_tables_
  where table_name like '$GIT!_%' escape '!'
    and user_id = user_id();
}
