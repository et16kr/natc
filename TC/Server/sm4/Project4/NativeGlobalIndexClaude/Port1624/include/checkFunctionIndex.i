###########################################################################
# NativeGlobalIndexPort1624 - 정합성 검사, 함수 기반 키까지 (배치 4)
#
# checkGlobalIndex.i 가 원본 basic/check_global_index.i 를 대신하듯, 이
# 파일은 원본 bugs/function_index.tc 가 **자기 안에** 들고 있던
# DEF CHECK_GLOBAL_INDEX() 를 대신한다. 원본의 그것은 두 겹으로 이식이
# 불가능하다 -- 1 차 배치가 겪은 것과 같은 두 겹이다:
#
#   1. "$GIT_T1_PK" / "$GIT_T1_IDX1" 을 힙과 FULL OUTER JOIN 한다.
#      네이티브에는 그 테이블이 없고 b-tree 내용은 SQL 로 볼 수 없다.
#   2. 힙 쪽 SELECT 가 cast(_prowid as bigint) 를 쓴다. 디스크 테이블은
#      _PROWID 를 지원하지 않아 원본 .lst 의 그 자리 **열 개가 전부**
#      [ERR-31385 : _PROWID is not supported.] 로 굳어 있다 -- 이 패턴이
#      울리는 변경이 존재하지 않는 감시자였다(v3-natc-port.md 3.1).
#
# ---------------------------------------------------------------------
# ★ 왜 checkGlobalIndex.i 를 고치지 않고 형제 파일을 두는가
# ---------------------------------------------------------------------
# ATC 는 INCLUDE 한 파일을 **주석까지** 케이스 전사에 인라인한다. 공유
# 파일에 한 줄만 더해도 그것을 INCLUDE 한 1 차 배치 14 개의 .lst 가 전부
# 움직인다. 얻는 것 없이 굳힌 기대 14 개를 다시 찍는 일이므로, 확장은
# 이 형제 파일에 둔다. 같은 이유로 이 스위트는 자매 스위트
# (NativeGlobalIndexClaude)의 공유 include 도 건드리지 않았다 -- README.
#
# ---------------------------------------------------------------------
# ★ 무엇이 새로 필요한가 -- 함수 기반 키는 오늘 거절된다
# ---------------------------------------------------------------------
#   create index t1_idx1 on t1( i1+i2 );
#
# 는 파티션 키(i4)를 담지 않으므로 네이티브 글로벌 인덱스 후보이고,
# qdx::validateNativeGlobalIndex(qdx.cpp) 가 숨김(함수 기반) 키 컬럼을
# 보고 거절한다:
#
#   [ERR-314AD : A native global index cannot be created with this index
#                option or key column type: FUNCTION-BASED key.]
#
# $GIT_ 는 같은 문장을 받아 숨김 테이블 위에 만들었다. 그래서 이 케이스가
# 재는 것은 "함수 기반 글로벌 인덱스의 정합성"이 아니라 **거절이 무엇을
# 남기는가**로 바뀐다. 그것을 에러 문구가 아니라 **값**으로 적는다
# (v3-natc-port.md 6.1 -- "에러가 난다"를 기대로 굳히지 않는다):
#
#   겹 0. 거절이 흔적을 남기지 않았다 -- 숨김 컬럼 0, 숨김 테이블 0.
#         qdx.cpp 의 그 검사는 "숨김 컬럼이 실제로 붙기 전에 돈다"고
#         주석에 적혀 있고, FN_HIDDEN_KEY_COLUMNS 가 그 주석을 실물로
#         확인하는 자리다. 프로퍼티 0 에서는 1 이 된다.
#   겹 1~3. 이 픽스처에 실제로 남는 네이티브 글로벌 인덱스 T1_PK(i1) 를
#         checkGlobalIndex.i 와 같은 세 겹으로 검사한다 -- 양방향 차집합,
#         카운트/합계 교차, 그리고 힌트가 정말 그 인덱스를 잡았다는 플랜
#         증거. 겹 3 이 없으면 겹 1 은 "풀스캔 minus 풀스캔"이라 무조건
#         0 행이다.
#
# 이 케이스의 t1 은 파티션 키가 i4 이고 T1_PK 는 i1 하나이므로 비선두다
# -- 원본 fixture 의 T1_PK(i2,i1) 과 달리 **정말로 글로벌**이고, 그래서
# 행 이동(update ... i4 = i4+10)을 가로질러 검사할 값이 있다.
###########################################################################

#
# 인덱스 하나를 세 겹으로 검사한다. checkGlobalIndex.i 의 CHECK_ONE_INDEX
# 와 같은 모양이다 -- 이름을 달리한 것은 두 파일을 같은 케이스에서
# INCLUDE 할 일이 없고, 공유 파일을 건드리지 않기 위해서다.
#
# @aTable : 테이블 이름
# @aIndex : 검사할 인덱스 이름
# @aPred  : 그 인덱스를 태울 술어. 전 행(널 포함)을 덮어야 한다.
#
DEF CHECK_ONE_INDEX_FN( @aTable, @aIndex, @aPred )
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
# 함수 기반 키가 남긴 흔적을 센다.
#
# PROJ-1090 의 함수 기반 인덱스는 식을 담을 **숨김 컬럼**을 테이블에
# 붙이고 그 위에 인덱스를 만든다(SYS_COLUMNS_.IS_HIDDEN = 'T').
#   프로퍼티 1(네이티브) : CREATE INDEX 가 ERR-314AD 로 거절되고,
#                          숨김 컬럼은 붙기 전이라 0 이다.
#   프로퍼티 0($GIT_)    : 같은 문장이 성공하고 숨김 컬럼이 1 이다.
# 즉 이 한 줄이 이 케이스의 이빨이다.
#
DEF SHOW_FUNCTION_KEY_TRACE( @aTable )
{
  select count(*) fn_hidden_key_columns
  from system_.sys_columns_ c, system_.sys_tables_ t
  where c.table_id = t.table_id
    and t.user_id = user_id()
    and t.table_name = upper('@{aTable}')
    and c.is_hidden = 'T';
}

#
# 원본이 자기 안에 들고 있던 DEF 와 **같은 이름, 같은 인자(없음)**다.
# 그래서 MAIN 의 다섯 CALL 자리는 원본과 바이트 동일하게 남는다.
#
DEF CHECK_GLOBAL_INDEX()
{
  set linesize 200;
  alter session set explain plan = off;

  CALL SHOW_INDEX_MEDIA( "t1" );
  CALL SHOW_NO_HIDDEN_TABLE();
  CALL SHOW_FUNCTION_KEY_TRACE( "t1" );

  select /*+ FULL SCAN(t1) */
         count(*) c, sum(i1) s1, sum(i2) s2, sum(i3) s3, sum(i4) s4
  from t1;

  CALL CHECK_ONE_INDEX_FN( "t1", "t1_pk", "i1 is not null or i1 is null" );

  alter session set explain plan = on;
}
