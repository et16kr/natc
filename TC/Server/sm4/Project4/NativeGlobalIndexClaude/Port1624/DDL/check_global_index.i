###########################################################################
# NativeGlobalIndexPort1624 - DDL/ 픽스처의 정합성 검사 (배치 5)
#
# 원본 DDL/check_global_index.i 를 대신한다. 원본과 **같은 이름, 같은 인자**
# 의 DEF 셋(PREPARE_ / FINALIZE_CHECK_GLOBAL_INDEX, CHECK_GLOBAL_INDEX)만
# 정의하므로, 이 배치 파티션 DDL 여섯 케이스의 CALL 자리는 원본과 바이트
# 동일하게 남는다.
#
#   add_partition  coalesce_partition  drop_partition
#   merge_partition  split_partition  truncate_partition
#
# ---------------------------------------------------------------------
# ★ 원본은 이식할 수 없고, 무엇보다 한 번도 돈 적이 없다
# ---------------------------------------------------------------------
# 원본은 파티션별 SELECT 와 숨김 테이블 "$GIT_T1_PK" 등을 FULL OUTER JOIN
# 해서 한쪽에만 있는 행을 찾았다. 이식이 막히는 이유는 둘이다.
#
#   1. 조인할 테이블이 없다. 네이티브 b-tree 의 내용은 SQL 로 볼 수 없다.
#   2. 힙 쪽 SELECT 가 cast(_prowid as bigint) 를 쓴다. 디스크 테이블은
#      _PROWID 를 지원하지 않아 원본 .lst 의 그 자리가 전부
#      [ERR-31385 : _PROWID is not supported.] 로 굳어 있다.
#      basic/ 과 bugs/function_index 가 겪은 것과 같은 병이다
#      (v3-natc-port.md 3.1).
#
# 그래서 목적(트리와 힙이 일치하는가)만 이어받고 방법은
# include/checkGlobalIndex.i 와 같은 세 겹으로 새로 세운다. 그 파일을
# 그대로 쓰지 못하는 이유는 픽스처가 다르기 때문이다 -- 그쪽은 basic/ 의
# t1(i1..i4) + idx1..idx5 를, 이쪽은 DDL/ 의 t1 + t1_pk/t1_uk/t1_idx1/
# t1_idx3 을 검사한다. 공유 파일을 고치면 그것을 INCLUDE 한 배치 1 의 14
# 개 .lst 가 전부 움직이므로(ATC 는 INCLUDE 를 주석까지 전사에 인라인한다)
# 확장은 언제나 형제 파일에 둔다.
#
# ---------------------------------------------------------------------
# ★ 픽스처 -- 여섯 케이스가 공유한다
# ---------------------------------------------------------------------
#   t1 : partition by {hash|range|list}(i1), 컬럼은 i1..i4 또는 i1..i6
#   t1_idx1(i1)        LOCAL 키워드 없음 -> 글로벌. 파티션 키를 담아도 그렇다
#   t1_idx2(i2) local  로컬 (검사 대상 아님 -- 대조군)
#   t1_idx3(i2,i3,i4)  글로벌
#   t1_pk  : (i3) 또는 (i3,i4)   글로벌, 유니크
#   t1_uk  : (i4) 또는 (i5,i6)   글로벌, 유니크
#
# 술어는 i1..i4 만 쓴다. 여섯 케이스의 앞 섹터는 i4 까지만 있고 뒤 섹터가
# i6 까지 있는데, 0-인자 DEF 한 벌이 양쪽에서 그대로 펼쳐져야 하기 때문이다.
# t1_uk 가 (i5,i6) 인 섹터에서 i4 술어는 키 레인지가 아니라 필터가 되지만,
# 힌트가 인덱스를 잡았다는 사실은 겹 3(플랜 증거)이 줄 단위로 남긴다.
#
# ---------------------------------------------------------------------
# ★ t1_idx1 의 술어는 파티션 키다 -- J19b 를 여기서 되받는다
# ---------------------------------------------------------------------
# 넷 모두 자기 선두 키에 "<col> is not null or <col> is null" 을 건다.
# t1_idx1 의 키는 i1 이고 그것이 **파티션 키**여서, 이 OR 체인은 DNF 로
# 갈라져 가지마다 qmgPARTITION 그래프가 서고 가지마다 파티션 집합을
# 프루닝한다 -- J19b 가 고친 바로 그 자리다(가지들이 그래프 공용
# qmsTableRef::partitionRef 를 나눠 써서 makePlan 시점에 마지막 가지의
# 집합만 남았다).
#
# 이 잡의 앞선 회차는 J19b 가 열려 있어 여기서 100 행 중 33 행을 받았고
# (해시 3 파티션에서 실측), 틀린 답을 기대로 굳히지 않으려고 술어를 i2 로
# 피해 두었다. J19b 가 닫혔으므로(altibase 1144df58) 술어를 원래 자리인
# i1 로 되돌린다. 그래서 이 여섯 케이스는 파티션 DDL 이 지나간 뒤의
# 글로벌 트리를 **파티션 키 OR 체인으로** 훑는다 -- 공식 스위트 안에서
# J19b 의 회귀를 되받는 유일한 자리다. 감시자 쪽 대응물은
# global-partfilter-check.sh G 절이다.
###########################################################################

DEF FINALIZE_CHECK_GLOBAL_INDEX()
{
# 원본은 여기서 get_oid 를 지웠다. 네이티브 검사는 파티션 OID 로 힙과
# 트리를 짝짓지 않으므로 만든 것이 없고, 지울 것도 없다.
alter session set explain plan = off;
}

DEF PREPARE_CHECK_GLOBAL_INDEX()
{
# 원본은 여기서 get_oid 를 만들었다. 위와 같은 이유로 필요 없다.
set linesize 200;
}

#
# 인덱스 하나를 세 겹으로 검사한다.
#
# @aTable : 테이블 이름
# @aIndex : 검사할 인덱스 이름
# @aPred  : 그 인덱스를 태울 술어. 전 행(널 포함)을 덮어야 한다.
#
# ★ 겹 3(플랜 증거)이 없으면 겹 1 은 "풀스캔 minus 풀스캔"이라 무조건
#   0 행이다 -- 원본이 빠진 함정의 다른 얼굴이므로 먼저 남긴다.
#
DEF CHECK_ONE_INDEX_DDL( @aTable, @aIndex, @aPred )
{
  alter session set explain plan = on;
  select /*+ index(@{aTable}, @{aIndex}) */ count(*) from @{aTable} where @{aPred};
  alter session set explain plan = off;

  select * from
  (
    select /*+ index(@{aTable}, @{aIndex}) */ i1, i2, i3, i4 from @{aTable} where @{aPred}
    minus
    select /*+ FULL SCAN(@{aTable}) */ i1, i2, i3, i4 from @{aTable} where @{aPred}
  )
  order by 1, 2, 3, 4;

  select * from
  (
    select /*+ FULL SCAN(@{aTable}) */ i1, i2, i3, i4 from @{aTable} where @{aPred}
    minus
    select /*+ index(@{aTable}, @{aIndex}) */ i1, i2, i3, i4 from @{aTable} where @{aPred}
  )
  order by 1, 2, 3, 4;

  select /*+ index(@{aTable}, @{aIndex}) */
         count(*) c, sum(i1) s1, sum(i2) s2, sum(i3) s3, sum(i4) s4
  from @{aTable} where @{aPred};
}

DEF CHECK_GLOBAL_INDEX()
{
  set linesize 200;
  alter session set explain plan = off;

  CALL SHOW_INDEX_MEDIA( "t1" );
  CALL SHOW_NO_HIDDEN_TABLE();

  select /*+ FULL SCAN(t1) */
         count(*) c, sum(i1) s1, sum(i2) s2, sum(i3) s3, sum(i4) s4
  from t1;

  CALL CHECK_ONE_INDEX_DDL( "t1", "t1_pk",   "i3 is not null or i3 is null" );
  CALL CHECK_ONE_INDEX_DDL( "t1", "t1_uk",   "i4 is not null or i4 is null" );
  CALL CHECK_ONE_INDEX_DDL( "t1", "t1_idx1", "i1 is not null or i1 is null" );
  CALL CHECK_ONE_INDEX_DDL( "t1", "t1_idx3", "i2 is not null or i2 is null" );
}
