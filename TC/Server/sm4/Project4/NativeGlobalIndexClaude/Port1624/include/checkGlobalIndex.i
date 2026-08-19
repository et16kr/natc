###########################################################################
# NativeGlobalIndexPort1624 - 정합성 검사
#
# 원본(PROJ-1624)의 basic/check_global_index.i 를 대신한다.
#
# ★ 원본은 이식할 수 없다. 두 가지 이유가 겹친다.
#
#   1. 조인할 테이블이 없다. 원본은 힙(파티션별 SELECT)과 숨김 테이블
#      "$GIT_T1_IDX1" 을 FULL OUTER JOIN 해서 한쪽에만 있는 행을 찾았다.
#      네이티브에는 그 테이블이 없고 b-tree 내용을 SQL 로 볼 수 없다.
#
#   2. 원본의 그 검사는 **한 번도 동작한 적이 없다.** 힙 쪽 SELECT 가
#      cast(_prowid as bigint) 를 쓰는데 디스크 테이블은 _PROWID 를
#      지원하지 않는다. 원본 .lst 22 개가 전부
#      [ERR-31385 : _PROWID is not supported.] 로 굳어 있다 --
#      "이 패턴이 울리는 변경"이 존재하지 않는 감시자였다.
#      근거와 수는 v3-natc-port.md 3.1.
#
# 그래서 목적(트리와 힙이 일치하는가)만 이어받고 방법은 새로 세운다.
# NativeGlobalIndexClaude/include/checkGlobalIndex.i 가 메모리 쪽에서 쓰는
# 것과 같은 세 겹이다:
#
#   1. 인덱스 경유 결과와 풀스캔 결과의 양방향 차집합  (행의 유무)
#   2. 카운트와 합계의 교차 확인                        (행의 중복·유령)
#   3. 힌트가 실제로 그 글로벌 인덱스를 잡았다는 플랜 증거
#
# ★ 3 이 없으면 1·2 는 "풀스캔 minus 풀스캔"이 되어 무조건 0행이다.
#   그것이 원본이 빠진 함정의 다른 얼굴이므로, 매 인덱스마다 플랜을
#   먼저 전사에 남긴다.
###########################################################################

#
# 인덱스 하나를 검사한다.
#
# @aTable : 테이블 이름
# @aIndex : 글로벌 인덱스 이름
# @aPred  : 그 인덱스를 태울 술어. 전 행(널 포함)을 덮어야 한다.
#
DEF CHECK_ONE_INDEX( @aTable, @aIndex, @aPred )
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

#
# 원본 fixture(i1..i4 + idx1..idx5)의 전 글로벌 인덱스를 검사한다.
#
# 호출 규약은 원본과 같은 자리에서 부르되 테이블을 인자로 받는다 --
# 원본은 t1 전용 check_global_index.i 와 t2 전용 check_global_index_t2.i
# 두 파일이었다.
#
# 인덱스별 선두 컬럼:
#   idx1(i2) idx2(i2,i3,i4) idx3(i3,i2) idx4(i4,i3) idx5(i4)
#
DEF CHECK_GLOBAL_INDEX( @aTable )
{
  set linesize 200;
  alter session set explain plan = off;

  CALL SHOW_INDEX_MEDIA( "@{aTable}" );
  CALL SHOW_NO_HIDDEN_TABLE();

  select /*+ FULL SCAN(@{aTable}) */
         count(*) c, sum(i1) s1, sum(i2) s2, sum(i3) s3, sum(i4) s4
  from @{aTable};

  CALL CHECK_ONE_INDEX( "@{aTable}", "@{aTable}_idx1", "i2 is not null or i2 is null" );
  CALL CHECK_ONE_INDEX( "@{aTable}", "@{aTable}_idx2", "i2 is not null or i2 is null" );
  CALL CHECK_ONE_INDEX( "@{aTable}", "@{aTable}_idx3", "i3 is not null or i3 is null" );
  CALL CHECK_ONE_INDEX( "@{aTable}", "@{aTable}_idx4", "i4 is not null or i4 is null" );
  CALL CHECK_ONE_INDEX( "@{aTable}", "@{aTable}_idx5", "i4 is not null or i4 is null" );

  alter session set explain plan = on;
}
