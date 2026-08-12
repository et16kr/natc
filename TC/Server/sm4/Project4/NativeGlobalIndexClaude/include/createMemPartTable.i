###########################################################################
# Native Global Index - memory partitioned table helpers
#
# 구버전(PROJ-1624) 테스트는 파티션드 테이블을 전부 디스크
# (tablespace sys_tbs_disk_data)에 만들었다. 당시 서버가 메모리 파티션드
# 테이블의 글로벌 인덱스를 전면 금지했기 때문이다.
#
# 이 스위트가 검증하는 것은 그 반대다. 여기서 만드는 테이블은 전부
# 메모리 테이블스페이스에 있다.
###########################################################################

#
# 단일 메모리 테이블스페이스에 파티션 3개를 만든다.
#
# @aPartType : range | hash | list
# @aKeyType  : 파티션 키 컬럼 타입
# @aColType  : 나머지 컬럼 타입
#
# 컬럼 구성: i1(파티션 키), i2, i3, i4
#
DEF CREATE_MEM_PART_TABLE( @aPartType, @aKeyType, @aColType )
{
NODISPLAY ON;
SKIP BEGIN;
drop table t1;
SKIP END;
NODISPLAY OFF;

if ( @aPartType == 'range' )
{

create table t1( i1 @{aKeyType}, i2 @{aColType}, i3 @{aColType}, i4 @{aColType} )
partition by range(i1)
(
  partition p1 values less than (100),
  partition p2 values less than (200),
  partition p3 values default
)
tablespace sys_tbs_mem_data;

}
elsif ( @aPartType == 'hash' )
{

create table t1( i1 @{aKeyType}, i2 @{aColType}, i3 @{aColType}, i4 @{aColType} )
partition by hash(i1)
(
  partition p1,
  partition p2,
  partition p3
)
tablespace sys_tbs_mem_data;

}
elsif ( @aPartType == 'list' )
{

create table t1( i1 @{aKeyType}, i2 @{aColType}, i3 @{aColType}, i4 @{aColType} )
partition by list(i1)
(
  partition p1 values (100),
  partition p2 values (200),
  partition p3 values default
)
tablespace sys_tbs_mem_data;

}
else
{
  print "error: unknown partition type @{aPartType}";
}

}

#
# 파티션을 서로 다른 메모리 테이블스페이스에 흩어 놓는다.
#
# 이 구성이 네이티브 글로벌 인덱스에서 가장 위험하다:
#   - rowOID 는 테이블스페이스 안에서만 유일하다. 서로 다른 TBS 의 두
#     로우가 같은 rowOID 를 가질 수 있고, tie-break 가 (tableOID, rowOID)
#     로 확장되지 않았다면 두 키를 같은 것으로 오인한다.
#   - variable 컬럼의 out-of-row piece 접근은 컬럼 서술자의 colSpace 로
#     테이블스페이스를 고른다. 보정이 없으면 다른 파티션 로우의 값을
#     엉뚱한 TBS 에서 읽는다(크래시가 아니라 조용한 오독).
#
# PREPARE_MEM_TBS() 로 만든 mem1/mem2/mem3 를 쓴다.
#
DEF CREATE_MEM_PART_TABLE_MULTI_TBS( @aPartType, @aKeyType, @aColType )
{
NODISPLAY ON;
SKIP BEGIN;
drop table t1;
SKIP END;
NODISPLAY OFF;

if ( @aPartType == 'range' )
{

create table t1( i1 @{aKeyType}, i2 @{aColType}, i3 @{aColType}, i4 @{aColType} )
partition by range(i1)
(
  partition p1 values less than (100) tablespace mem1,
  partition p2 values less than (200) tablespace mem2,
  partition p3 values default tablespace mem3
);

}
elsif ( @aPartType == 'hash' )
{

create table t1( i1 @{aKeyType}, i2 @{aColType}, i3 @{aColType}, i4 @{aColType} )
partition by hash(i1)
(
  partition p1 tablespace mem1,
  partition p2 tablespace mem2,
  partition p3 tablespace mem3
);

}
elsif ( @aPartType == 'list' )
{

create table t1( i1 @{aKeyType}, i2 @{aColType}, i3 @{aColType}, i4 @{aColType} )
partition by list(i1)
(
  partition p1 values (100) tablespace mem1,
  partition p2 values (200) tablespace mem2,
  partition p3 values default tablespace mem3
);

}
else
{
  print "error: unknown partition type @{aPartType}";
}

}

#
# 다중 TBS 테스트용 메모리 테이블스페이스를 만든다.
#
DEF PREPARE_MEM_TBS()
{
CALL FINALIZE_MEM_TBS();

create memory tablespace mem1 size 32M autoextend on checkpoint path 'dbs';
create memory tablespace mem2 size 32M autoextend on checkpoint path 'dbs';
create memory tablespace mem3 size 32M autoextend on checkpoint path 'dbs';
}

DEF FINALIZE_MEM_TBS()
{
SKIP BEGIN;
drop tablespace mem1 including contents and datafiles;
drop tablespace mem2 including contents and datafiles;
drop tablespace mem3 including contents and datafiles;
SKIP END;
}

#
# range 파티션 기준으로 세 파티션에 고르게 데이터를 넣는다.
# i1: 파티션 키, i2/i3/i4: 값
#
DEF FILL_RANGE_DATA()
{
insert into t1 select level,        level,        level * 2, level * 3 from dual connect by level <= 30;
insert into t1 select level + 100,  level + 100,  level * 2, level * 3 from dual connect by level <= 30;
insert into t1 select level + 200,  level + 200,  level * 2, level * 3 from dual connect by level <= 30;
commit;
}

#
# hash/list 파티션 테이블에 데이터를 넣는다.
#
DEF FILL_HASH_DATA()
{
insert into t1 select level, level, level * 2, level * 3 from dual connect by level <= 90;
commit;
}

DEF FILL_LIST_DATA()
{
insert into t1 values (100, 1, 2, 3);
insert into t1 values (100, 4, 5, 6);
insert into t1 values (200, 7, 8, 9);
insert into t1 values (200, 10, 11, 12);
insert into t1 values (300, 13, 14, 15);
insert into t1 values (400, 16, 17, 18);
commit;
}
