###########################################################################
# Native Global Index - integrity check helpers
#
# 구버전(PROJ-1624)은 숨김 테이블 $GIT_ 와 베이스 테이블을 FULL OUTER JOIN
# 해서 정합성을 검사했다. 네이티브 글로벌 인덱스에는 조인할 테이블이 없고
# 인덱스 내용을 SQL로 직접 볼 수 없으므로, 아래 세 가지를 조합해서 같은
# 목적을 달성한다.
#
#   1. 인덱스 경유 결과 vs 풀스캔 결과의 양방향 차집합 (CHECK_INDEX_SCAN)
#   2. 카운트/집계 교차 확인                          (CHECK_INDEX_COUNT)
#   3. 유니크 제약을 살아 있는 검사기로 사용          (각 케이스에서 직접)
#
# ★ 1번과 2번은 index 힌트가 실제로 글로벌 인덱스를 잡았을 때만 의미가
#   있다. 잡지 못하면 "풀스캔 minus 풀스캔" 이 되어 무조건 0행이고, 아무것도
#   시험하지 않으면서 통과한다.
#
#   옵티마이저가 글로벌 SCAN 후보를 아예 내지 않는 조합이 있다
#   (qmoPartition::isUsableNativeGlobalIndex):
#
#     (a) memory variable 컬럼(varchar/nvarchar/...)의 colSpace 가 논리
#         테이블과 파티션 사이에서 다를 때. 파티션이 서로 다른 메모리
#         테이블스페이스에 있으면 여기 걸린다. 키 컬럼이 아니어도,
#         테이블에 그런 컬럼이 하나라도 있으면 닫힌다.
#     (b) 파티션 프루닝이 일어났고 인덱스 키 컬럼에 variable 이 있을 때.
#     (c) PARALLEL 힌트가 붙었을 때.
#
#   이 경우 인덱스 자체는 살아 있고 유니크 제약도 계속 강제된다.
#   스캔 플랜만 후보에서 빠지고 종전대로 PCRD 가 선택된다.
#
#   그래서 위 조합에서는 CHECK_INDEX_SCAN 대신
#   CHECK_INDEX_SCAN_CLOSED_GATE 를 쓴다 — 플랜에 GLOBAL-INDEX 가
#   "없다"는 것을 .lst 에 명시적으로 남기고, 정합성은 유니크 제약과
#   풀스캔 집계로만 판정한다.
###########################################################################

#
# 플랜 출력을 켠다. 어떤 접근 경로가 선택됐는지 .lst 에 남긴다.
#
DEF SHOW_PLAN_ON()
{
  alter session set explain plan = on;
}

DEF SHOW_PLAN_OFF()
{
  alter session set explain plan = off;
}

#
# 인덱스 경유 결과와 풀스캔 결과가 완전히 같은지 양방향으로 확인한다.
# 두 select 모두 0행이어야 정상이다.
#
# @aTable  : 테이블 이름
# @aIndex  : 글로벌 인덱스 이름
# @aCols   : 비교할 컬럼 목록 (예: "i1, i2")
# @aPred   : where 절 술어 (예: "i2 >= 0 or i2 is null")
#
# 바깥 ORDER BY 는 이름이 아니라 **위치**로 준다. @aCols 에 substr(...) 같은
# 표현식이 들어갈 수 있는데, 파생 테이블의 컬럼은 표현식 이름으로 참조할 수
# 없다(ERR-31058). 두 select 모두 0행이 정상이므로 정렬은 실패했을 때의
# 출력을 위한 것뿐이다.
#
# 주의: 인덱스 컬럼에 null 이 있으면 인덱스 스캔이 null 행을 건너뛸 수
#       있다. @aPred 를 null 행까지 포함하도록 주거나, null 케이스는
#       CHECK_INDEX_SCAN_NOTNULL 로 나눠서 확인한다.
#
DEF CHECK_INDEX_SCAN( @aTable, @aIndex, @aCols, @aPred )
{
  # 인덱스 경유 결과에만 있는 행 (없어야 정상)
  select * from
  (
    select /*+ index(@{aTable}, @{aIndex}) */ @{aCols} from @{aTable} where @{aPred}
    minus
    select /*+ FULL SCAN(@{aTable}) */ @{aCols} from @{aTable} where @{aPred}
  )
  order by 1;

  # 풀스캔 결과에만 있는 행 (없어야 정상)
  select * from
  (
    select /*+ FULL SCAN(@{aTable}) */ @{aCols} from @{aTable} where @{aPred}
    minus
    select /*+ index(@{aTable}, @{aIndex}) */ @{aCols} from @{aTable} where @{aPred}
  )
  order by 1;
}

#
# null 행을 제외하고 비교한다. 키 컬럼에 null 이 섞인 경우에 쓴다.
#
DEF CHECK_INDEX_SCAN_NOTNULL( @aTable, @aIndex, @aCols, @aKeyCol )
{
  CALL CHECK_INDEX_SCAN( "@{aTable}", "@{aIndex}", "@{aCols}", "@{aKeyCol} is not null" );
}

#
# 플랜이 열리는 조합에서 쓴다.
# 차집합 비교 앞에 플랜을 먼저 남겨, 힌트가 실제로 글로벌 인덱스를
# 잡았다는 증거를 .lst 에 박아 둔다. 플랜에 GLOBAL-INDEX 가 사라지면
# 차집합이 0행이어도 이 케이스는 FAIL 이 된다.
#
DEF CHECK_INDEX_SCAN_OPEN_GATE( @aTable, @aIndex, @aCols, @aPred )
{
  alter session set explain plan = on;

  select /*+ index(@{aTable}, @{aIndex}) */ count(*) from @{aTable} where @{aPred};

  alter session set explain plan = off;

  CALL CHECK_INDEX_SCAN( "@{aTable}", "@{aIndex}", "@{aCols}", "@{aPred}" );
}

#
# 플랜 게이트가 닫히는 조합에서 쓴다(위 (a)/(b)/(c)).
#
# 여기서는 차집합 비교가 무의미하다 — 양쪽 다 풀스캔이 되어 항상 0행이다.
# 대신 두 가지를 기록한다:
#   1. 힌트를 줘도 플랜에 GLOBAL-INDEX 가 나오지 않는다는 사실
#      (게이트 판정이 바뀌면 여기서 드러난다)
#   2. 값 자체는 풀스캔으로 확인
#
# 인덱스가 실제로 정합인지는 이 조합에서 유니크 제약으로만 증명할 수 있다.
# 호출하는 쪽에서 중복 삽입 시험을 반드시 함께 둘 것.
#
DEF CHECK_INDEX_SCAN_CLOSED_GATE( @aTable, @aIndex, @aCols, @aPred )
{
  alter session set explain plan = on;

  # 힌트를 줘도 글로벌 인덱스 스캔이 선택되지 않아야 한다
  select /*+ index(@{aTable}, @{aIndex}) */ count(*) from @{aTable} where @{aPred};

  # 대조군: 명시적 풀스캔
  select /*+ FULL SCAN(@{aTable}) */ count(*) from @{aTable} where @{aPred};

  alter session set explain plan = off;

  # 값은 풀스캔으로 확인한다
  select /*+ FULL SCAN(@{aTable}) */ @{aCols} from @{aTable}
   where @{aPred} order by @{aCols};
}

#
# 카운트와 집계를 교차 확인한다.
# 인덱스가 어떤 파티션의 키를 빠뜨리거나 유령 키를 갖고 있으면 어긋난다.
#
DEF CHECK_INDEX_COUNT( @aTable, @aIndex, @aKeyCol )
{
  select /*+ FULL SCAN(@{aTable}) */ count(*) full_cnt,
         count(@{aKeyCol}) full_key_cnt,
         nvl(sum(@{aKeyCol}), -1) full_sum,
         nvl(min(@{aKeyCol}), -1) full_min,
         nvl(max(@{aKeyCol}), -1) full_max
  from @{aTable};

  select /*+ index(@{aTable}, @{aIndex}) */ count(@{aKeyCol}) idx_key_cnt,
         nvl(sum(@{aKeyCol}), -1) idx_sum,
         nvl(min(@{aKeyCol}), -1) idx_min,
         nvl(max(@{aKeyCol}), -1) idx_max
  from @{aTable}
  where @{aKeyCol} is not null;
}

#
# 파티션별 행 수의 합이 전체와 같은지 확인한다.
# 파티션 3개 + default 구성(p1,p2,p3)을 전제한다.
#
DEF CHECK_PARTITION_COUNT( @aTable )
{
  select count(*) total_cnt from @{aTable};

  select 'P1' part_name, count(*) part_cnt from @{aTable} partition (p1)
  union all
  select 'P2', count(*) from @{aTable} partition (p2)
  union all
  select 'P3', count(*) from @{aTable} partition (p3)
  order by 1;
}

#
# 위 검사를 한 번에 수행한다. 시나리오 끝마다 호출한다.
#
DEF CHECK_GLOBAL_INDEX( @aTable, @aIndex, @aCols, @aKeyCol )
{
  CALL CHECK_INDEX_SCAN( "@{aTable}", "@{aIndex}", "@{aCols}", "@{aKeyCol} is not null" );
  CALL CHECK_INDEX_COUNT( "@{aTable}", "@{aIndex}", "@{aKeyCol}" );
  CALL CHECK_PARTITION_COUNT( "@{aTable}" );
}
