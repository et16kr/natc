# Native Global Index 테스트 통합 계획

- 목적지: **`TC/Server/sm4/Project4/NativeGlobalIndexClaude`**
- 흡수: `NativeGlobalIndexPort1624` 전량 + `NativeGlobalIndexCodex` **선별** +
  제품 저장소 밖 그물(`altibase/scripts/global-index/`)에서 **건질 수 있는 것**
- 실측 기준: 2026-08-19
- 상태: **계획 — 착수 전.** 선행 조건은 §2, 남은 결정은 §10

---

## 0. 확정된 것 (이 개정에서)

| # | 결정 | 내용 |
|---|---|---|
| 1 | **목적지** | `NativeGlobalIndexClaude`. 새 디렉터리를 만들지 않는다 — 이 작업은 claude 브랜치의 것이고 그 스위트가 이 브랜치의 자리다 |
| 2 | **뼈대** | `NativeGlobalIndexCodex` 의 **매체 × 영역** 축을 차용한다 (§3.1) |
| 3 | **Codex 처리** | **선별 흡수. 디렉터리는 삭제하지 않는다** — codex 브랜치가 관리하는 별개의 테스트다 (§5) |
| 4 | **Port1624 처리** | 서브트리로 편입하되 **계보를 보존**한다. 영역별 재배치 금지 (§6) |
| 5 | **include 정책** | **프로젝트 로컬 `.i` 를 0 으로.** `.tc` 는 자족적으로 돈다. 허용되는 것은 프레임워크 표준 `INCLUDE stdFunc.i;` 하나 (§7) |
| 6 | **매체 분리가 먼저** | `Disk/` 와 `Memory/` 를 가르는 것이 첫 작업이고, **두 매체의 영역 집합은 대칭일 필요가 없다** — 매체가 테스트의 성격 자체를 가른다 (§3.2) |
| 7 | **`Regress` 는 매체별로** | 기존 케이스는 쪼개지 않는다 (§10 ①) |
| 8 | **`sm-matrix-check` 분해** | 9 절을 영역별 케이스로. 실질 7 개 (§8.2.1) |
| 9 | **MANIFEST** | 작업 중에는 `manifest.tc` 로 자동 대조, **완성 시점에 대조표로 넘기고 `.tc` 는 걷는다** (§8.4) |
| 10 | **복제 레인** | 프레임워크는 막지 않는다. **원본 스위트의 `initialize.tc` 가 템플릿**이고, 막았던 것은 `server.conf` 블록 부재와 이 프로젝트의 격리 인스턴스 전제였다 (§9.3) |
| 11 | **러너를 새로 만들지 않는다** | `natc-check.sh` 의 두 안전 스위치는 격리 인스턴스 때문에 있었다. **회사 러너 + auto-init ON** 이 답이고 `NEEDS_FRESH_INSTANCE` 도 그것으로 충족된다 (§8.7) |
| 12 | **레인마다 브리프가 다르다** | TC_GUIDE 의 Hard Stops 는 금지가 아니라 **그 브리프의 범위**다. 범위 밖 레인(재기동·다중 세션·복제·FIT)은 케이스 첫 주석에 그 사실을 적는다 (§3.3) |

> **★ 이 문서를 이어받는 사람에게**
>
> - **선행 조건은 풀렸다** — V4 J25 완료(`c6bffafc`, 27/27 Done). Phase A 부터
>   착수 가능하다. 다만 **실행 검증은 J24 이후 빌드에서만** 뜻이 있다 (§2.1).
> - 이 조사는 **부분 체크아웃** 둘에서 했다(`TC/Server/repl4` 추적 파일
>   37 개, 공식 트리는 수백 개). §9.3 의 ATAF 관용구 표는 **공식 트리의 실물
>   케이스에서 옮겨 적은 것이라 이 체크아웃에서는 재검증할 수 없다**
>   (`repl4/ActiveStandby/Bugs/BUG-52439`·`BUG-52224`). 공식 트리에서 한 번
>   대조할 것.
> - `conf/server.conf` 도 잘려 있을 수 있다 (§10.1 의 남은 단서).

---

## 1. 왜 지금인가

**① 스위트가 셋으로 갈라져 있다.** 같은 기능을 세 뿌리가 따로 검증한다.
축이 셋 다 다르고, 같은 이름의 include 가 서로 다른 내용으로 두 벌 있으며
(§7.2), 어느 케이스가 어느 것과 겹치는지 세어 본 적이 없다.

**② 저장소 밖 그물이 사라진다.** `altibase/scripts/global-index/` 의
105 `.sh` + 32 `.cpp` 는 회사의 테스트 추가 정책을 따른 것이 아니라
**반영 시 삭제 예정**이다. NATC 로 옮기면 그대로 서는 검사가 상당수 있고,
삭제 전에 건지지 않으면 그 검증은 남지 않는다.

통합만 하면 곧 사라질 그물을 다시 세우게 되고, 건지기만 하면 통합 뒤에 또
재편해야 한다. 그래서 한 계획으로 다룬다.

---

## 2. 선행 조건 — V4 J25 ✅ **해제됨 (2026-08-19)**

이 계획의 어떤 Phase 도 V4 워크플로의 J25(종결)가 끝나기 전에 시작하지
않기로 했었다. **끝났다.**

```
altibase HEAD  c6bffafc  Close V4, and find that the last thing in the way is ours, not $GIT_'s (J25)
               jobs.tsv  27 / 27 Done   (v2·v3·v4·disk·memory·followup 전 워크플로 Done)
```

막고 있던 이유는 J25 의 1단계(클린 재실행)가 두 스위트를 **이름과 경로로**
돌리기 때문이었다 — `natc-check.sh` 가
`SUITE_ROOT="$ATAF_TEST_CASE/TC/Server/sm4/Project4"` 아래 이름으로
디렉터리를 찾고 없으면 `exit 2` 한다. 이제 그 실행이 끝났으므로 Phase A 부터
착수할 수 있다.

### 2.1 착수 전 실측 조건 — 빌드가 J24 이후여야 한다

**설치된 서버 바이너리가 J19b·J20~J24 보다 앞서면 어떤 실행 검증도 틀린
것을 잰다.** Port1624 배치 3~7 의 `.lst` 도, J23/J24 가 새로 찍은 섹터도
그 바이너리에서는 재현되지 않는다.

```bash
( cd <altibase> && make build -j"$(nproc)" )
<altibase>/scripts/global-index/testdb.sh restart      # ★ 반드시
```

재빌드 뒤 `restart` 가 필수인 이유: `bin` 이 빌드 산출물로 가는 심볼릭
링크라, 인스턴스가 떠 있으면 **옛 바이너리로 테스트가 돈다.**

Phase A(판정)는 파일을 읽고 판정표를 만드는 일이라 서버 없이 진행할 수
있다 — **다만 Codex 판정은 반쪽만 가능하다**(§5.3).

---

## 3. 목표 구조

### 3.1 디렉터리

```
NativeGlobalIndexClaude/
    NativeGlobalIndex.ts              ← 유일한 루트 (기존 파일명 유지)
    Disk/
        Catalog/ Create/ Query/ DML/ DDL/
        Transaction/ Boundary/ Unsupported/
        Concurrency/ Lifecycle/       ← 계약이 필요한 레인 (오늘 비어 있다)
        Regress/                      ← 회귀 게이트 (신설)
    Memory/
        (같은 영역)
    Port1624/                         ← 계보 보존, 재배치 금지
        basic/ pdt/ design/ bugs/ tool/ DDL/ meta/ qc/
        MANIFEST                      ← 208 대조 (§8.4)
    Deferred/
        README.md                     ← 레인 · 계약 · 상태 · 여는 조건
```

영역 10 개는 Codex 가 이미 쓰는 것을 그대로 가져온다(`Concurrency`·
`Lifecycle` 은 Codex 에서도 비어 있다 — 다중 세션·재기동 계약이 필요한
자리로 예약돼 있다). **`Regress` 만 신설**한다 — Claude 의
`regress/noGlobalIndexUnchanged`·`propertyRuntimeChange` 가 영역이 아니라
게이트라서 8 개 영역 어디에도 안 들어간다.

### 3.2 매체가 1급 축인 이유 — 성격이 다르다

**매체 분리가 이 작업의 첫 단계다.** 단순한 정리 축이 아니라 두 구현의
성격이 다르기 때문이다.

| | 디스크 | 메모리 |
|---|---|---|
| 인덱스 로깅 | **있다** — GIDX 로그 6 종 · 언두 3 종 | **없다** |
| 재기동 | 로그로 복구 | **다시 만든다** (리빌드) |
| 온디스크 이미지 | 있다 (멤버 디렉터리 격자 등) | 없다 |

이 하나가 여러 영역의 뜻을 갈라 놓는다.

- **`Lifecycle/` 이 서로 다른 것을 잰다.** 디스크는 복구·미디어 리커버리·
  재기동 후 트리 정합이고, 메모리는 **리빌드 정합**이다 — 글로벌 인덱스는
  여러 파티션의 로우를 입력으로 삼으므로 **모든 멤버 파티션의 복구가 끝난
  뒤에** 빌드가 시작돼야 한다. 순서가 어긋나면 미완료 로우를 인덱싱한다.
- **`Regress/`(회귀 0)는 본래 디스크의 것**이다 — "프로퍼티 off 면 바이트가
  같다" 는 온디스크 이미지가 있어야 성립한다.
- **복구·언두 계열은 메모리에 대응이 없다.**

그래서 **두 매체의 영역 집합이 대칭일 필요가 없다.** Codex 가 Disk 58 /
Memory 58 로 강제 대칭을 세운 것은 매트릭스로서는 깔끔하지만, 위 셋을
표현하지 못한다. 통합 스위트는 **공통 영역은 같은 이름으로 두되, 매체
고유 영역은 한쪽에만 둔다.**

측정된 근거도 있다 — Port1624 DDL 배치 25 개를 이식하기 전 자매 스위트와
중복 판정을 했더니 **완전 중복 0** 이었고, 가르는 축은 문장이 아니라
매체였다.

### 3.3 레인마다 따르는 브리프가 다르다

`docs/TC_GUIDE.md` 의 **Hard Stops** 는 "server restart, multi-server
topology, HDB/XDB, WhiteBox, fault injection, external processes" 를 만나면
**멈추라**고 한다. 이 계획의 여러 레인이 거기 걸린다 — 그러나 **금지가
아니라 브리프의 범위 문제**다. TC_GUIDE 는 첫 문단에서 스스로 선을 긋는다:

> FIT, fault injection, WhiteBox, restart/recovery 테스트는 이 브리프의
> 범위가 아니다. 그런 요청이면 이 브리프로 작업하지 말고 중단한다.

그리고 `docs/FIT_GUIDE.md` 가 따로 있고, `TC/Server/repl4/` 가 multi-server
를 실제로 하고 있다. 그러므로 **레인마다 따르는 브리프를 명시한다.**

| 레인 | 따르는 것 | 비고 |
|---|---|---|
| `Catalog`·`Create`·`Query`·`DML`·`DDL`·`Transaction`·`Boundary`·`Unsupported`·`Regress` | **`docs/TC_GUIDE.md`** | 일반 SQL regression. 이 계획의 대부분 |
| `Lifecycle/`(재기동·복구) | TC_GUIDE **범위 밖** — 별도 계약 필요 | Hard Stops 의 "server restart" |
| `Concurrency/`(다중 세션) | TC_GUIDE **범위 밖** | |
| FIT 계열(크래시 주입) | **`docs/FIT_GUIDE.md`** | `stdFit.i`·`##fail`/`##success` |
| 복제(`Deferred/Replication`) | **`repl4` 의 실사용 패턴** (§9.3) | Hard Stops 의 "multi-server topology" |
| `manifest.tc`(§8.4) · `ngi_cli`(§8.3) | TC_GUIDE 의 "Do Not Generate — Shell or Python wrappers" 와 맞닿는다 | 그 줄의 단서는 **"for behavior that TC syntax can express directly"** 다. C 프로그램 빌드·원본 `.ts` 전개는 TC 문법으로 표현할 수 없으므로 그 단서에 걸리지 않는다. 다만 **한시적**임을 케이스 주석에 적는다 |

**규칙**: TC_GUIDE 범위 밖 레인의 케이스는 그 사실을 케이스 첫 주석에
적는다. 그러지 않으면 다음 사람이 TC_GUIDE 하나만 들고 와서 "이건 규약
위반" 이라고 읽는다.

---

## 4. 무엇이 어디로 — 전체 지도

| 출처 | 수 | 목적지 | 성격 |
|---|---:|---|---|
| `NativeGlobalIndexClaude` 기존 | 37 | `Memory/*` + `Disk/` 1 | 재배치 (§4.1) |
| `NativeGlobalIndexCodex` | 116 중 **선별 ~30** | `Disk/*` · `Memory/*` | 복사 (§5) |
| `NativeGlobalIndexPort1624` | 97 파일 / 208 단위 | `Port1624/` | 이동, 재배치 없음 (§6) |
| 삭제될 그물 — SQL 전용 | **21** | `Disk/*` 위주 | **재작성** (§8.2) |
| 삭제될 그물 — 부분 | 7 | 절 단위 분해 | **재작성** (§8.3) |
| 삭제될 그물 — 나머지 | 76 + 32 `.cpp` | **못 건진다** | §9 |

### 4.1 기존 Claude 37 의 재배치

전량 메모리 스위트지만 **한 케이스만 디스크**다.

| 현재 | 목적지 | 비고 |
|---|---|---|
| `ddl/createIndex` · `createIndexError` · `createTableFromSchema` | `Memory/Create/` | |
| `ddl/alterIndex` · `alterIndexRebuild` · `alterTableColumn` · `constraint` · `dropCascade` · `dropIndex` | `Memory/DDL/` | |
| `ddl/indexBudget` · `ddl/allIndexAndTablespace` | `Memory/Boundary/` | 예산 64 / 인덱스+테이블스페이스 조합 |
| **`ddl/diskPartitionedTable`** | **`Disk/DDL/`** | 섹터마다 `DISK_GLOBAL_INDEX_ENABLE` 을 0/1 로 못박는다 — 매체가 갈리는 유일한 케이스 |
| `dml/insert` · `updateDelete` · `nullValue` · `dpathInsert` · `updateInPlace` · `rowMovement` | `Memory/DML/` | |
| `dml/isolation` | `Memory/Transaction/` | |
| `meta/nativeCatalog` | `Memory/Catalog/` | |
| `partition/addTruncatePartition` · `dropPartition` · `splitMergeReplace` · `coalesceAndBoundary` | `Memory/DDL/` | Codex 가 파티션 DDL 을 `DDL/` 에 둔다 — 축을 따른다 |
| `scan/hostVariable` · `joinAndFilter` · `preservedOrder` · `scanAndLock` · `tableLock` | `Memory/Query/` | |
| `unique/primaryKey` · `crossPartition` | `Memory/Create/` | Codex 의 `Create/keyAndConstraint` 계열과 같은 자리 |
| `tablespace/multiTablespace` | `Memory/Boundary/` | Codex 의 `Create/sameMediaTablespaces` 와 중복 판정 대상 |
| `datatype/variableColumn` | `Memory/DML/` | |
| `datatype/functionIndex` | `Memory/Unsupported/` | 거절이 기대값이다 |
| `regress/noGlobalIndexUnchanged` · `propertyRuntimeChange` | `Memory/Regress/` | 신설 영역 |
| `repl/replicationReject` | ~~`Memory/Unsupported/`~~ → **`Memory/DDL/`** | **Phase B 에서 이탈했다.** 이 케이스가 재는 것은 거절이 아니라 **허용**이다 — 섹터가 `GLOBAL INDEX ON A REPLICATED TABLE IS ALLOWED` · `THE INDEX SURVIVES DROPPING THE REPLICATION` 이다(V3 B-5 가 `ERR-61183` 게이트를 걷은 결과). "허용" 을 재는 케이스를 `Unsupported/` 에 두면 읽는 사람을 영구히 오도한다. 단일 인스턴스에서 도는 **복제 DDL 게이트** 검사이므로 `DDL/` 이 맞다. 두 서버가 필요한 복제 검증은 그대로 `Deferred/Replication`(§9.2·§9.3) |

`.tc` 아닌 잔재 셋도 지도에 넣는다:

| 현재 | 처리 |
|---|---|
| `tools/lint-tc.py` | **프로젝트 로컬 파이썬.** TC_GUIDE 의 "Do Not Generate — Shell or Python wrappers" 에 걸린다. 남길지 걷을지 Phase A 에서 판정 |
| `deferred/` (소문자) | `Deferred/` 로 통일. 내용(재기동이 필요한 항목 목록)은 §9.2 표로 흡수 |
| `README` · `TEST_SCENARIOS.md` | 통합 후 내용이 어긋난다. Phase B 에서 갱신 |

---

## 5. Codex 선별 흡수

### 5.1 원칙

- **디렉터리를 삭제하지 않는다.** codex 브랜치가 관리한다. 이력상으로도
  2026-08-05 이후 이 브랜치가 손댄 적이 없다(`3c4c042`).
- **Claude 에 없는 커버리지만** 복사한다. 복사한 케이스마다 출처를 주석
  첫 줄에 적는다 — 나중에 원본이 고쳐졌을 때 찾을 수 있어야 한다.
- 복사 후 §7 의 자족 규칙을 적용한다(Codex 는 이미 자족이라 손댈 것이 적다).

### 5.2 1차 후보 (Phase A 에서 확정)

| Codex 영역 | Disk | Memory | Claude 대응 | 판단 |
|---|---:|---:|---|---|
| **Transaction** | 4 | 4 | `dml/isolation` 하나뿐 | **흡수 유력** — savepoint · statement · transaction rollback · DDL guard |
| **Unsupported** | 9 | 9 | `ddl/createIndexError` · `datatype/functionIndex` | **흡수 유력** — 거절 매트릭스가 통째로 없다 |
| **Boundary** | 6 | 6 | `ddl/indexBudget` | **부분** — `globalIndexCount64/65Reject` 는 겹칠 수 있다. `participantCount65` · `recreateObjectIdentity` 는 없다 |
| **Query** | 10 | 10 | `scan/` 5 | **부분** — `pruningCardinality` · `statisticsContinuity` · `optimizerSelection` 은 없다 |
| Catalog | 2 | 2 | `meta/nativeCatalog` | 중복 유력 |
| Create · DDL · DML | 27 | 27 | 대응 있음 | 중복 유력 |

거친 추정 **~30**. Disk 쪽은 Port1624 와도 겹치므로 3자 판정이 필요하다.

### 5.3 ★ Codex 흡수분에는 `.lst` 무변경이 성립하지 않는다

Codex 의 `.lst` 는 **2026-08-02~08-05 기록**이고, 그 뒤 제품이 세 번
바뀌었다:

| 잡 | 바꾼 것 |
|---|---|
| J19b | 파티션 키 OR 체인의 프루닝 오답 수리 — **플랜이 바뀐다** |
| J23 | `ALTER INDEX … REBUILD` 로 `$GIT_` 전환 |
| J24 | 프로퍼티 0 의 뜻이 **거절(`ERR-314B6`)** 로 바뀜 |

그러므로:

1. **§8.6 의 "`.lst` 무변경" 은 Claude·Port1624 이동에만 적용된다.** Codex
   복사분은 **재기록이 전제**다. 이 예외를 판정표에 명시한다.
2. **선별 ~30 이라는 추정 자체가 한 번 돌려 본 뒤에 선다** — Codex 116 은
   08-05 이후 실행 이력이 없어 **오늘 그린인지 알 수 없다.** Phase A 의
   Codex 칸은 빌드가 선 뒤에 채운다(§2.1).

### 5.4 ★ Codex 는 프로퍼티를 한 자리도 못박지 않는다

실측: Codex 116 케이스에서 `GLOBAL_INDEX_ENABLE` 참조 **0 건**.

> **[Phase D 실측, 2026-08-19] 이 위험이 현실로 나타났다.**
>
> Codex 116 을 오늘 빌드에서 처음 돌렸더니 **17 PASS / 99 FAIL** 이었다.
> 원인을 §5.3(제품이 세 번 바뀌었다)으로 읽기 쉬우나 **아니었다.** 붉은
> 케이스의 첫 어긋남이 전부 이것이다:
>
> ```
> [ERR-313D0 : A non-partitioned index can be created on a disk partitioned table.]
> ```
>
> 즉 `MEM_GLOBAL_INDEX_ENABLE` 이 **0** 인 상태에서 돌았다. 직전에 돌린
> `NativeGlobalIndexClaude` 의 `regress/noGlobalIndexUnchanged` 가 FINALIZE
> 에서 `DISABLE_GLOBAL_INDEX()` 로 끄고 끝났고, 프로퍼티는 비영속이되
> **도는 인스턴스 안에서는 남는다.** 자기 전제를 세우지 않는 Codex 가 그
> 값을 그대로 물려받은 것이다.
>
> 재기동으로 파일 기본값(**1**)을 복원한 뒤 다시 잰다. 이 절의 요구는
> 이제 권고가 아니라 **흡수의 전제**다 — 못박지 않은 케이스는 앞에 무엇이
> 돌았는지에 따라 다른 것을 잰다.
>
> **곁가지로 확인된 것**: `include/globalIndexEnv.i` 의 헤더 주석이
> "파일 값(기본 0)" 이라고 적고 있는데 **낡았다.** `altibase.properties` 는
> `MEM_/DISK_GLOBAL_INDEX_ENABLE` 둘 다 `default = 1` 이다(2026-08-06 전환).
> §7 자족화 때 함께 고친다.

§8.5 규약 ②("케이스마다 자기 전제를 세운다")의 정면 위반이다. J24 로
프로퍼티 0 의 뜻이 "거절" 이 된 만큼, **흡수할 때 프로퍼티 못박기를 넣는
것이 필수 작업**이다. 넣지 않으면 기본값이 움직이는 날 조용히 다른 것을
재게 된다 — 원본 PROJ-1624 와 `ddl/diskPartitionedTable` 이 실제로 그렇게
어긋났다.

매체 축은 맞다 — `Disk/Catalog/implementationType` 이
`INDEX_IMPL_TYPE = 3` · `INDEX_TABLE_ID = 0` 으로 네이티브를 재고 있다.

---

## 6. Port1624 편입

**서브트리 통째로 옮기고 재배치하지 않는다.** 이 스위트의 값은 공식 원본
`qp4/Project3/PROJ-1624-GlobalIndex` 와의 1:1 추적성이고, 영역별로 다시
파일링하면 그 값이 사라진다. 통합이 뜻하는 것은 **루트 `.ts` 하나로
모으는 것**이지 케이스 재배치가 아니다.

- 실행 단위 **208** = 그린 203 + 보류 5. 파일 수(97 `.tc` + 155 `.sql`)와
  다르다.
- `NEEDS_FRESH_INSTANCE` 규약을 통합 스위트 전체로 승격한다 (§8.5).
- 보류 5(배치 2 의 1 + `repl/` 4)는 §9.2 형식으로 옮긴다.

---

## 7. include 자족 — `.tc` 는 혼자 돈다

### 7.1 규칙

**프로젝트 로컬 `.i` 를 0 으로 만든다.** `.tc` 안에서 허용되는 include 는
프레임워크 표준 하나다:

```
INCLUDE stdFunc.i;
```

Codex 가 이미 그 모델이다 — 116 케이스 전부 `stdFunc.i` **하나만** 부르고
프로젝트 로컬 `.i` 가 하나도 없다. 통합 스위트는 그 규약을 따른다.

### 7.2 인라인 대상 — 실측

| 스위트 | 로컬 `.i` | INCLUDE 쓰는 `.tc` |
|---|---|---:|
| Claude | 4 (`checkGlobalIndex` 7.4KB · `createMemPartTable` 5.1KB · `globalIndexEnv` 1.2KB · `selectMeta` 3.4KB) | 37 / 37 |
| Port1624 | **9** + `include/pinNative.sql` | 93 / 97 |
| Codex | **0** | 116 (전부 `stdFunc.i` 만) |

Port1624 의 9 는 `include/` 아래 넷만이 아니라 **배치 로컬이 다섯** 더
있다 — 처음 셀 때 놓쳤다:

```
include/checkGlobalIndex.i   include/globalIndexEnv.i
include/descIndex.i          include/checkFunctionIndex.i
DDL/check_global_index.i     DDL/desc_global_index.i
meta/desc_global_index.i     meta/select_meta.i
qc/select_meta.i
```

**합치기는 생각보다 싸다** — `desc_global_index.i` 두 벌(`DDL/`·`meta/`)과
`select_meta.i` 두 벌(`meta/`·`qc/`)이 **바이트 동일**이다. 교차 스위트
동명이체(`checkGlobalIndex.i`·`globalIndexEnv.i`)만 내용이 갈린다.

**이름 충돌 둘이 실측돼 있다** — `checkGlobalIndex.i` 와 `globalIndexEnv.i`
가 Claude·Port1624 에 **같은 이름·다른 내용**으로 있다(메모리 판별자 vs
디스크 판별자). 자족화하면 이 충돌은 저절로 사라진다 — 각 케이스가 자기
매체의 판별을 자기 안에 갖는다.

### 7.3 값과 비용

- **값**: 케이스 하나를 읽으면 그것이 무엇을 재는지 다 보인다. 매체별로
  갈린 헬퍼를 추적할 필요가 없다. 케이스를 다른 스위트로 옮겨도 따라오는
  것이 없다.
- **비용**: `DEF` 본문이 케이스마다 복제된다. 판별 로직이 바뀌면 여러
  자리를 고쳐야 한다.
- **완화**: 자족은 "복붙"이 아니라 **케이스가 자기에게 필요한 것만 갖는
  것**이다. `checkGlobalIndex.i` 7.4KB 를 통째로 붙이는 게 아니라, 그
  케이스가 실제로 부르는 `DEF` 만 가져온다.
- **경계**: 자족화로 **출력이 바뀌면 안 된다.** `.lst` 무변경이 이 작업의
  수용 기준이다(§8.6).

---

## 8. 삭제될 그물에서 건지기

### 8.1 판정 요약

| 부류 | 수 | 판정 |
|---|---:|---|
| SQL 전용 검사 | **21** | **○ 건진다** — 서버 + `isql` 만 쓴다 |
| SQL 검사 (부분 의존) | 7 | **◐ 절 단위로 건진다** |
| 재기동·크래시 | 8 | **△ `Lifecycle/` · FIT 레인** — 계약이 따로다 |
| 복제 2 인스턴스 | 5 | **◐ ConfigPending** — 진단이 바뀌었다 (§9.3) |
| C++ 단위 테스트 | 28 / 29 | **✗ 못 건진다** (§9.1) |
| 정적 소스 감사 | 4 | **✗ 대상 아님** (§9.1) |
| 골든·회귀 0 | 6 + 기준선 9 파일 | **✗ 못 건진다 — 가장 큰 손실** (§9.1) |
| 벤치·시뮬 | 10 | **✗ 부적합** |
| 러너·기반 | ~14 | **✗ 대상 아님** |

### 8.2 건지는 21 — 어디로

전부 디스크 축이다(스크립트 그물이 디스크 위에서 섰다).

| 스크립트 | 목적지 | 비고 |
|---|---|---|
| `catalog-check` · `disk-catalog-check` | `Disk/Catalog/` | `disk-catalog-check` 는 208 검사 — 절 단위 분해 필요 |
| `allindex-check` · `column-ddl-check` · `dropidentity-check` · `empty-table-ddl-check` | `Disk/DDL/` | |
| `partition-reorg-check` · `reorg-ddl-check` | `Disk/DDL/` | 파티션 재구성 |
| `cost-model-check` · `disk-planstat-check` · `select-plan-check` | `Disk/Query/` | 플랜 전사가 곧 기대값 — `.lst` 와 궁합이 좋다 |
| `global-partfilter-check` · `partition-filter-check` | `Disk/Query/` | 프루닝 |
| `parallel-answer-check` · `parallelbuild-check` | `Disk/Query/` | **병렬** — 비결정성 주의 (§8.5) |
| `dml-handoff-check` · `fk-routing-check` | `Disk/DML/` | |
| `tbsonline-check` | `Disk/Boundary/` | |
| `4k-native-index-check` | `Disk/Boundary/` | 4K 축 — 페이지 크기 전제를 케이스가 세울 수 있는지 확인 필요 |
| `o1-legacy-corrupt-check` | `Disk/Lifecycle/` | 은퇴 경로 |
| `sm-matrix-check` | **9 절을 분해** | §8.2.1 |

### 8.2.1 `sm-matrix-check` 분해 — 절 이름이 곧 영역이다

절이 이미 A~I 로 갈려 있고 이름이 영역과 1:1 이라, 분해에 판정이 거의 필요
없다. 반대로 하나로 두면 어느 영역의 회귀인지 `.lst` 덩어리에서 못 가른다 —
이 그물이 갖고 있던 `PASS=n FAIL=n` 의 진단력을 잃는 자리가 정확히 여기다.

| 절 | 검사 | 내용 | 목적지 |
|---|---:|---|---|
| A | 15 | Comparator — 다른 테이블스페이스의 같은 rowOID | `Disk/Boundary/` |
| B | 17 | var 컬럼 colSpace | `Disk/DML/` |
| C | 16 | insert / delete / ager | `Disk/DML/` (ager 절은 `Disk/Lifecycle/`) |
| D | 21 | in-place update undo | `Disk/DML/` |
| E | 7 | 파티션 간 유니크 · **동시 세션** | `Disk/Create/` + **`Concurrency/` (막힘)** |
| F | 14 | 빌드: 여러 파티션 · 빈 것 · **재기동 리빌드** | `Disk/Create/` + **`Disk/Lifecycle/` (막힘)** |
| **G** | **61** | 파티션 DDL | `Disk/DDL/` — 크므로 DDL 종류별 재분할 검토 |
| H | 15 | 회귀 — 프로퍼티 off | `Disk/Regress/` |
| I | 11 | 트랜잭션 격리 수준 | `Disk/Transaction/` |
| 합 | ~177 | | **실질 7 개 케이스** — E·F 의 동시 세션·재기동 부분은 계약이 없어 §9.2 보류로 이름을 붙여 남긴다 |

### 8.3 부분 건지기 7

본체는 SQL 인데 일부 절이 소스 grep · `ngi_cli` · 골든에 매달려 있다.
**그 절만 떼고** 옮긴다.

| 스크립트 | 검사 | 떼야 하는 것 |
|---|---:|---|
| `sql-level-check` | 370 | 최대 건. 절 단위로 나눠 `Disk/Query`·`DML`·`DDL` 로 분산 |
| `disk-review-fix-check` | 128 | FIT 절과 골든 절 |
| `disk-matrix-check` | — | 골든 참조 |
| `media-recovery-check` | — | 재기동 절 → `Lifecycle/` |
| `memberoverflow-check` | — | `ngi_cli` 절 — **떼지 않아도 된다**(아래) |
| `multibuild-check` · `write-concurrency-check` | — | `ngi_cli` 절은 유지, 다중 세션 절만 → `Concurrency/` |

> **★ `ngi_cli` 는 살릴 수 있다.** `ngi_cli.cpp`(76 KB)는 서버 내부가 아니라
> **CLI/ODBC 클라이언트**다(`#include <sqlcli.h>`). ATAF 케이스는 자기
> 디렉터리에 Makefile + C 프로그램을 두고 부를 수 있다 —
> `SHELL "make";` / `SHELL -o $sResult "./ngi_cli ...";`
> (선례: `repl4/.../BUG-52224` 의 `./insertRecord`). 그래서 "`ngi_cli` 절을
> 떼야 한다" 던 종전 판정은 취소한다.

### 8.4 208 대조를 잃지 않는다

Port1624 의 "조용히 빠진 케이스가 없다" 를 오늘 세는 것은
`natc-port-check.sh` **절 H** 다 — 원본 루트 `.ts` 둘을 전개해 208 을 다시
만들고 배치 표와 맞춘다. **그 스크립트도 삭제된다.**

**대체 — 두 단계로 간다.**

1. **작업 중**(Phase C~E): `Port1624/manifest.tc` 를 세워 자동으로 대조한다.
   케이스가 원본 `.ts` 트리를 전개해 208 을 다시 만들고 포트 트리와 맞춘 뒤,
   `.lst` 에는 결과만 박는다 — `missing 0 / extra 0 / held 5`. 케이스를
   빼먹거나 `held` 에 `.lst` 를 찍으면 그 자리에서 붉어진다.
2. **완성 시점**: 결과를 `Port1624/MANIFEST`(208 행 — 원본 경로 → 이식 경로
   → 판정 → `held` 사유)로 **동결하고 `manifest.tc` 는 걷는다.**

이 순서를 택하는 이유는 자동 대조의 값이 **움직이는 동안에만** 크기
때문이다. 케이스가 옮겨 다니는 Phase C~E 가 정확히 "조용히 빠지는" 사고가
나는 구간이고, 스위트가 굳은 뒤에는 표 하나로 충분하다. 그리고 `manifest.tc`
가 부르는 대조 도구는 결국 **지금 삭제되는 종류의 것**(프로젝트가 붙인
스크립트)이라 영구히 두면 같은 문제를 NATC 안으로 옮기는 셈이 된다 —
한시적으로 쓰고 걷으면 그 부담이 남지 않는다.

**동결 후의 보완**: `Port1624/` 아래 케이스를 더하거나 빼는 변경은
MANIFEST 동시 갱신을 리뷰 체크리스트로 명시한다.

### 8.5 판정 모델을 바꿔야 한다 — 공수의 대부분

| | NATC | 삭제될 스크립트 |
|---|---|---|
| 판정 | `.tc` 출력을 `.lst` 와 **바이트 diff** | 스스로 계산해 `ok/fail` + `PASS=n FAIL=n` |
| 기대값 | 파일에 박힌 전사 | 코드 안의 동적 단언 |

"합집합 == 전체", "교집합 == 공집합", "마진 부호가 음수" 같은 **동적
단언**은 `.lst` 로 그대로 옮겨지지 않는다. 값을 SQL 로 유도해 **boolean 한
줄**로 찍게 다시 써야 한다. 이식이 아니라 재작성이다.

**비결정성**도 같은 자리에서 물린다. 이미 실증돼 있다 — Port1624 의
`NEEDS_FRESH_INSTANCE` 가 그 문서다(객체 ID 일련번호 5 건, 이웃 케이스의
잔재 6 건). 두 규약을 통합 스위트 전체에 적용한다:

1. **카탈로그 행을 나열하는 케이스는 자기 객체로 범위를 좁힌다.**
2. **케이스마다 자기 전제를 세운다** — 프로퍼티 기본값에 기대지 않는다.
   기본값이 움직이는 날 "네이티브를 잰다"고 적어 놓고 `$GIT_` 를 재게 된다
   (원본 PROJ-1624 와 `ddl/diskPartitionedTable` 이 실제로 그렇게 어긋났다).

병렬 검사(`parallel-*`)는 여기에 셋째가 붙는다 — **실스레드 수·슬라이스
분배는 실행마다 갈릴 수 있다.** `.lst` 에 박을 것은 스레드 수가 아니라
**직렬과 같은 체크섬**이다.

### 8.6 `.lst` 무변경 원칙 — 적용 범위를 못박는다

이동·자족화로 **`.lst` 가 한 줄도 바뀌면 안 된다.** 바뀌었다면 옮기다가
무언가를 바꾼 것이고, 그것이 곧 결함이다.

**적용되는 것**: Claude 37 재배치(Phase B) · Port1624 서브트리 이동(Phase C)
· 두 스위트의 `.i` 자족화.

**적용되지 않는 것**:
- 새로 쓰는 케이스(§8.2·8.3) — 처음부터 새로 찍는다.
- **Codex 흡수분(Phase D) — 재기록이 전제다** (§5.3).

### 8.7 러너 — 삭제되는 것과 남는 것

`natc-check.sh` 도 삭제 대상 `scripts/global-index/` 소속이다. 그 스크립트에
용접돼 있던 것 셋을 각각 따진다.

| 용접돼 있던 것 | 통합 후 |
|---|---|
| `--auto-init=OFF` | **필요 없어진다.** 이 스위치는 ATAF 의 초기화 TC 가 `natc/bin/createdb` 를 돌려 **이 프로젝트의 격리 인스턴스를 지워 버리는 것**을 막으려고 켠 것이다. 격리 인스턴스가 사라지면 이유도 사라진다 |
| `--core=OFF` | **필요 없어진다.** 코어 수집기가 이 기계에 없는 경로를 원해서 껐던 것이다 |
| `NEEDS_FRESH_INSTANCE` 처리 | **회사 러너가 대신한다.** 그 파일 자신이 그렇게 적어 두었다 — *"the original suite… never noticed because **ATAF's auto-init recreates the database on every run.** natc-check.sh keeps auto-init OFF on purpose (it would destroy the isolated instance), so it reads this file instead."* auto-init ON 이면 매 실행 DB 가 새로 만들어져 요구가 저절로 충족된다 |

남는 위험은 그 파일이 적은 **두 번째**뿐이다 — 같은 실행 안에서 **이웃
케이스가 남긴 것**을 보는 것(신선한 DB 로도 안 풀린다). 그것은 §8.5 규약
①(카탈로그 나열은 자기 객체로 범위를 좁힌다)이 이미 덮는다.

**결론**: 러너를 새로 만들 필요가 없다. 회사 러너 + auto-init ON 이 답이고,
**비표준이었던 것은 우리 쪽이었다** — 복제 레인(§9.3)과 같은 결론이다.

---

## 9. 못 건지는 것과 보류

### 9.1 사라지는 것 — 명시

NATC 로 옮길 수 없고 스크립트와 함께 사라진다. 조용히 넘기지 않기 위해
적는다.

| 잃는 것 | 크기 | 무엇이었나 |
|---|---|---|
| **골든 / 회귀 0 게이트** | 검사 6 종 + 기준선 9 파일 | "글로벌 인덱스를 안 쓰면 바이트가 오늘과 같다" 를 페이지·로그 **바이트 이미지 diff** 로 재던 것(8K·4K 양축). `.lst` 로 바꾸는 것 자체가 골든을 다시 찍는 일이라 성립하지 않는다 |
| **정적 소스 감사** | 4 종 | `discriminator-check`(매체 분기 없는 캐스팅 21 자리) · `dassert-sweep`(`IDE_DASSERT` 인자 9,182 개의 부수효과) · `syntax-check` · `natc-port-check`. 서버를 안 띄우고 `src/` 를 훑는다 — DB 테스트가 아니다 |
| **C++ 단위 테스트** | **28 / 29** (상시 그물 19 종 중 **12**) | 제품 **내부 헤더**에 링크한다 — 실측: `sqlcli.h` 를 쓰는 것 **0**, `sdnb*`·`smn*`·`sdp*` 를 쓰는 것 **28**(`slicebound_test` → `smnSliceBound.h`, `memberpersist_test` → `sdnbModule.h`). ATAF 가 `SHELL "make"` 를 지원해도 **서버 내부 링크는 케이스 디렉터리에서 못 만든다.** 나머지 1 = `ngi_cli`(클라이언트) 는 살린다 |
| **벤치·수지 시뮬** | 10 | 비용 모델·병렬 임계·memberNo 수지의 근거 수치 |

**NATC 안에 살릴 길이 없다.** 남는 선택지 둘은 이 계획의 범위 밖이다 —
회사 정책이 허용하는 자리로 옮기거나, 문서로만 남기고 검사는 포기하거나.

### 9.2 보류 레인 — 형식 통일

세 스위트가 각자 다르게 적고 있다. Codex `Deferred/README.md` 의 표를
표준으로 쓴다.

| 레인 | 출처 | 필요한 계약 | 상태 |
|---|---|---|---|
| Replication | Port1624 `repl/` 4 · Claude `repl/` 1 · 삭제될 `replication-check`(427 검사) | `server.conf` 에 우리 서버 블록 둘 (§9.3) | **ConfigPending** ← `EnvironmentBlocked` 에서 내렸다 |
| AdminTool | Codex Deferred | 격리 admin 계정 · 파일 정책 | EnvironmentBlocked |
| Performance | Codex Deferred · 삭제될 벤치 10 | 교정된 하드웨어 · 비교 기준선 | EnvironmentBlocked |
| Restart / Crash | Claude `deferred/README` · 삭제될 8 | FIT 레인 계약(`docs/FIT_GUIDE.md`) | 계약 있음, 미착수 |

### 9.3 복제 레인 — 진단을 고쳤다

종전 진단은 "프레임워크가 막는다" 였다. **틀렸다.** 막은 것은 우리 쪽 사정
둘이고, 템플릿은 **원본 스위트가 이미 갖고 있다.**

#### 관례 — 프로젝트마다 자기 서버를 세운다

```
qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/repl/initialize.tc
    include stdFunc.i;
    $ALTIBASE_HOME_C0 = $ALTIBASE_HOME;          # 컨트롤러 home 을 먼저 잡는다
    DECLARE SERVER PROJ_1624_SERVER1 DB1;        # ★ 자기 이름
    DECLARE SERVER PROJ_1624_SERVER2 DB2;
    DECLARE CLIENT DEFAULT C11 (SERVER=DB1);
    DEF MAIN() {
      THREAD T11 C11 {
        MKDIR "db1"; MKDIR "db1/conf"; MKDIR "db1/dbs"; ...
        CP -r "${ALTIBASE_HOME_C0}/bin" "db1/bin";
        CALL stdServerKill(); CALL stdClean(); CALL stdServerStart();
      }
      THREAD T21 C21 { ... db2 ... }
      join;
    }
```

`replication.ts` 는 `initialize.tc → createIndex.tc → NoIndexCreate.tc →
finalize.tc` 순이다 — **자기가 세우고 자기가 걷는다.**

같은 패턴이 sm4 안에도 있다: `sm4/Project3/PROJ-2429/initialize.tc` 가
`PROJ_2429_SERVER1/2` 를 선언하고 `stdServerStart()` 를 부른다.

`REPL_SERVER1/2/3` 은 **repl4 전용**이다 — `server.conf` 가
`ALTIBASE_HOME = $ATC_HOME/TC/Server/repl4/db1` 로 박아 두었다. 남의 것을
쓰지 않는다.

#### 막았던 것 둘 — 둘 다 우리 쪽이다

1. **`server.conf` 에 `PROJ_1624_SERVER1/2` 블록이 없다.** 이 체크아웃의
   148 블록 어디에도 없다. 원본 `initialize.tc` 는 그 블록이 있는 환경에서
   쓰였다. → **블록을 더하면 된다.**
2. **`stdClean()` 이 격리 인스턴스를 겨눴다.** `$gStdIsqlSys` 가 include
   시점의 `${ALTIBASE_HOME}` 으로 굳는데 그 값이 하필 이 프로젝트가 따로
   만든 `~/.ngi-testdb` 였다. 컨트롤러가 표준 설치인 정상 실행에서는 같은
   자리를 가리키므로 문제가 되지 않는다. → **격리 인스턴스 전제는 삭제될
   그물과 함께 사라진다.**

즉 프레임워크 결함이 아니라 **환경 설정의 문제**다. 상태를
`EnvironmentBlocked` 에서 **`ConfigPending`** 으로 내린다.

#### 알아 둘 ATAF 관용구 — 실측한 것

케이스를 쓰는 사람이 바로 쓸 수 있도록 적어 둔다
(출처: `repl4/ActiveStandby/Bugs/BUG-52439`, `BUG-52224`).

| 관용구 | 무엇 |
|---|---|
| `'${HOST_IP@DB3}'` · `${ALTIBASE_REPLICATION_PORT_NO@DB3}` | 다른 서버의 값을 참조한다. **`.lst` 에는 전개되지 않은 원문 그대로 찍힌다** — 호스트·포트가 기대값에 새지 않아 케이스가 기계 독립이다 |
| `.lst` 배치 | `T0` 블록엔 제어 흐름만(`THREAD`/`JOIN`, 본문 없음), 그다음 **스레드별로 묶어서** 전사(`$T1>` 전부 → `$T2>` → `$T3>`). **시간순 인터리브가 아니라서 결정적이다** |
| `ALTER REPLICATION <n> FLUSH;` | 수신 측을 읽기 전의 동기화 배리어. `JOIN;` 은 스레드 배리어 |
| `X$REPRECEIVER` | 복제 오라클 — `INSERT/UPDATE/DELETE_{SUCCESS,FAILURE}_COUNT` · `COMMIT_COUNT` · `ROLLBACK_COUNT`. `V$REPSENDER` 는 송신 측 |
| `SHELL "make";` · `SHELL -o $v "./prog args";` | 케이스 디렉터리의 Makefile·프로그램을 빌드/실행하고 출력을 변수로 받는다 |
| `GETROW -f "<file>" "<패턴>" $v;` | 트레이스 로그(`trc/altibase_rp.log`)를 오라클로 쓴다 |
| `IF/ELSE` · `LOOP $n` · `$v = expr` · `SLEEP` · `MV`/`RM`/`NODISPLAY` | 제어·파일 조작 |
| 오류 | 기대값에 그대로 박는다 (`[ERR-61027 : Replication did not start.]`) |

**"apply 됐다" 를 재는 방법은 값이다** — 송신 측에 N 건을 넣고 수신 측에서
N 건이 같은 값으로 보이면 통과다. row movement 로 한 UPDATE 가 송신에서
delete+insert 로 갈려도, 수신 측 행 수와 값이 송신과 같으면 그것이 곧
"정확히 한 행" 이다. 별도 계수 장치가 필요 없다.

#### DDL 복제 — Level 0 / 1 축을 케이스에 넣는다

`Replication Manual`(7.3) 기준. 우리 케이스에 직접 걸리는 것만 추린다.

| 사실 | 케이스 설계에 주는 것 |
|---|---|
| `REPLICATION_DDL_ENABLE_LEVEL` — **Level 0**: 비유니크·비함수기반 인덱스 생성/삭제, 무제약 컬럼 추가, TRUNCATE / **Level 1**: 유니크·함수기반 인덱스, **파티션 연산(SPLIT/MERGE/DROP)**, 제약 변경 | 글로벌 인덱스 DDL 케이스는 **0/1 두 축**으로 갈라 잰다. 글로벌 유니크는 Level 1 이다 |
| Level 1 은 **`REPLICATION_SQL_APPLY_ENABLE` 이 전제** | 케이스가 스스로 켜고 FINALIZE 에서 되돌린다 |
| "원격/지역 서버의 **파티션 방법이 동일**해야 하고 파티션 이름도 같아야 한다" | 글로벌 인덱스는 파티션드 테이블 위에만 서므로 이것이 픽스처 규약이 된다 |
| **PK 변경은 복제 불가** | 경계를 케이스 주석에 못박는다 — 이 프로젝트가 연 것은 **글로벌 PK 테이블의 데이터 복제**이지 PK DDL 이 아니다 |
| `REPLICATION_DDL_SYNC` · `REPLICATION_DDL_SYNC_TIMEOUT` | V3 B-5(GR-07)가 걷은 `ERR-61183` 게이트가 이 축이다 |

**보류는 이름과 여는 조건을 갖는다.** 조건 없는 보류는 만들지 않는다.

---

## 10. 결정 — 넷 다 정해졌다

| # | 결정 | 근거 |
|---|---|---|
| ① | **`Regress` 는 매체별로 둘. 기존 케이스는 쪼개지 않는다** | `propertyRuntimeChange` 는 `MEM_` 만 만지는 순수 메모리이고, 건져올 디스크 회귀가 실재한다(`sm-matrix` H 절 15 검사). 다만 `noGlobalIndexUnchanged` 는 `DISK PARTITIONED TABLE` 섹터를 이미 품고 있어 쪼개면 `.lst` 가 바뀐다 — **매체 혼합인 채로 `Memory/Regress/` 에 두고 주석으로 명시**하고, 디스크 회귀는 새로 쓴다 |
| ② | **`sm-matrix-check` 분해** | 절 이름이 곧 영역이라 판정 비용이 거의 없다 (§8.2.1). 실질 7 개 |
| ③ | **`manifest.tc` 로 시작해 완성 시점에 대조표로 동결** | 자동 대조의 값은 케이스가 움직이는 동안에만 크다 (§8.4) |
| ④ | **원본 스위트의 `initialize.tc` 를 템플릿으로 쓴다** | 프레임워크는 막지 않는다. 관례는 "프로젝트마다 자기 서버 이름과 자기 `db1`/`db2`" 이고 원본 PROJ-1624 와 sm4 PROJ-2429 가 같은 패턴이다. 막았던 둘은 `server.conf` 블록 부재와 격리 인스턴스 전제 — 둘 다 우리 쪽이다 (§9.3) |

### 10.1 ④ 의 확인 — 돌렸다. 경로 ② 확정

두 체크아웃에서 각각 돌렸고 결과가 같다.

| 확인 | 결과 |
|---|---|
| `grep -n "PROJ_1624_SERVER" conf/server.conf` | **없음** |
| `grep -n "^\[PROJ_2429_SERVER1\]" conf/server.conf` | **있음** — `:2074` (그리고 `:2124` 에 같은 이름이 한 번 더 — **중복 정의다**) |
| `PROJ-1624-QC/repl/initialize.tc` 템플릿 | 실재 |

그러므로 **경로 ②** 다 — `PROJ_2429_SERVER1` 블록을 본떠 우리 블록 둘을
더한다:

```
[NGI_SERVER1]
ALTIBASE_SID = altibase1
ALTIBASE_PORT_NO = %PORT_NO<n>
ALTIBASE_REPLICATION_PORT_NO = %REPLICATION_PORT_NO<n>
...
ALTIBASE_HOME = $ATC_HOME/TC/Server/sm4/Project4/NativeGlobalIndexClaude/db1
```

그다음은 `PROJ-1624-QC/repl/initialize.tc` 를 복사해 서버 이름과 경로만
바꾸는 일이다. 이것으로 `Replication` 레인의 `ConfigPending` 이 사라지고
**427 검사 + 5 케이스**가 보류에서 풀린다.

**남은 단서 둘**:
- 두 체크아웃 모두 **부분**이다(`TC/Server/repl4` 추적 37 개). 공식 트리의
  `conf/server.conf` 에 `PROJ_1624_SERVER` 가 있을 가능성은 남아 있다 —
  있으면 새 블록 없이 그것을 쓴다.
- `%PORT_NO<n>` 자리를 고를 때 다른 프로젝트와 충돌하지 않게 확인할 것.
  `PROJ_2429_SERVER1` 이 두 번 정의된 것을 보면 이 파일에 그런 사고가
  실제로 있었다.

---

## 11. 단계

각 단계는 독립으로 커밋 가능하고, 앞 단계가 그린이 아니면 다음으로 가지
않는다. **전부 V4 J25 이후**(§2).

### Phase A — 판정 (파일 안 움직임)
1. **중복 판정표.** Claude 37 × Codex 116 전량. Port1624 는 매체가 갈라
   원칙적으로 중복 아님이나 **DDL·meta 배치는 3 자 확인**. 판정은
   (ㄱ) 완전 중복 / (ㄴ) 부분 중복 / (ㄷ) 중복 아님, 행 수 = 대상 쌍 수.
   - **Codex 칸의 "오늘 그린인가" 는 빌드가 선 뒤에 채운다** (§2.1 · §5.3).
     주제 겹침 판정은 서버 없이 먼저 끝낼 수 있다.
2. **건지기 분해표.** 삭제될 47 `*-check.sh` 를 케이스 단위로 쪼개고,
   동적 단언마다 "`.lst` 로 어떻게 찍을지" 한 줄씩.
   - `sm-matrix-check` **G 절 61 검사**를 파티션 DDL 종류별로 재분할할지
     여기서 정한다 (§8.2.1).
3. 함께 판정할 것:
   - **Codex 흡수 시 프로퍼티 못박기** 를 어떤 형태로 넣을지 (§5.4).
   - `tools/lint-tc.py` 를 남길지 걷을지 (§4.1).
   - 각 레인이 따르는 브리프를 케이스 주석에 어떻게 적을지 (§3.3).
- **완료 조건**: 판정표 두 장. 스위트는 한 줄도 안 움직였다.

### Phase B — 매체 분리와 뼈대
1. **매체를 먼저 가른다** — `Disk/`·`Memory/`·`Port1624/` 골격 생성.
   영역은 매체별로 필요한 것만 만든다(§3.2 — 대칭 강제 금지).
2. 기존 37 을 §4.1 대로 재배치 — 36 은 `Memory/*`, `ddl/diskPartitionedTable`
   하나만 `Disk/DDL/`. 루트 `.ts` 갱신.
3. **자족화** — 로컬 `.i` 4 개를 케이스 안으로 인라인하고 `include/` 삭제.
   케이스가 실제로 부르는 `DEF` 만 가져온다(§7.3).
- **완료 조건**: 37/37, **`.lst` 무변경**.

### Phase C — Port1624 편입
1. 서브트리 이동, 재배치 없음. 로컬 `.i` 5 개 자족화.
2. `MANIFEST` 208 행.
3. 보류 5 를 §9.2 형식으로.
- **완료 조건**: 203 그린 / 5 보류, 합 208, `.lst` 무변경.

### Phase D — Codex 선별 흡수
1. **먼저 Codex 116 을 오늘 빌드에서 돌린다** — 08-05 이후 실행 이력이 없어
   그린 여부를 모른다 (§5.3). 붉은 것이 있으면 원인을 가른 뒤에 고른다.
2. Phase A 판정대로 복사. **Codex 디렉터리는 손대지 않는다.**
3. 복사한 케이스마다 **출처 주석** + **프로퍼티 못박기 추가** (§5.4).
4. **`.lst` 재기록** — 이 Phase 에만 §8.6 의 예외가 적용된다 (§5.3).
- **완료 조건**: 흡수분 전량 그린, 판정표에 없는 복사 0, **Codex 무변경**,
  흡수분 전량이 자기 프로퍼티 전제를 세운다.

### Phase E — 그물 건지기 (**스크립트 삭제의 선행 조건**)
1. 21 개를 §8.2 대로 `.tc` 화. 배치 단위 커밋.
2. 부분 7 을 절 단위로. 못 옮기는 절은 §9.1 에 적는다.
3. `Lifecycle`·`Concurrency`·FIT 레인은 계약을 세운 뒤 별건.
- **완료 조건**: 옮긴 검사 수가 원본 검사 수와 맞고, 못 옮긴 것마다 이유가
  적혀 있다.

**Phase E 가 끝나기 전에 `scripts/global-index/` 를 지우면 건질 것이
사라진다.**

---

## 12. 완료 조건

1. 네이티브 글로벌 인덱스 검증이 `NativeGlobalIndexClaude` **하나**로 돈다
   (Codex 는 병행으로 남는다).
2. 루트 `.ts` 하나로 전량이 돌고 **두 번 연속** 같은 결과다.
3. **프로젝트 로컬 `.i` 가 0** 이다.
4. 중복 판정표가 있고, 판정 없이 삭제·복사된 케이스가 0 이다.
5. Port1624 208 이 MANIFEST 로 세어지고 203/5 가 유지된다.
6. 보류가 전부 §9.2 형식(레인 · 계약 · 상태 · 여는 조건)을 갖는다.
7. **건진 것과 못 건진 것이 각각 목록으로** 있다 — 못 건진 것에는 크기와
   이유가 붙는다.
8. 이동·자족화만으로 바뀐 `.lst` 가 0 이다.

---

## 13. 규모

| Phase | 대상 | 성격 |
|---|---|---|
| A | 판정표 2 장 | 읽기·판정 |
| B | 37 재배치 + `.i` 4 인라인 | 기계적 + 검증 |
| C | 97 파일 + `.i` 5 인라인 + MANIFEST 208 | 기계적 + 목록 |
| D | ~30 복사 | 판정 결과 적용 |
| E | 21 + 부분 7 | **재작성 — 공수의 대부분** |

E 가 큰 이유는 §8.5 다. 동적 단언을 `.lst` 전사로 바꾸는 것은 옮기는 일이
아니라 다시 쓰는 일이다.

---

## 14. 이 계획이 받지 않는 것 — 이름을 붙여 넘긴다

V4 종결(J25)이 남긴 것 중 **통합의 몫이 아닌 것**이다. 조용히 사라지지
않도록 여기 적는다.

| 항목 | 무엇 | 왜 여기가 아닌가 |
|---|---|---|
| **O-8** | 멀티테이블 `UPDATE` 의 row movement 가 **`ERR-91015` 로 서버를 죽인다.** J25 가 08-19 HEAD 에서 재현을 재확인했고 **담당 잡이 없다** | 죽는 결함은 일반 `.tc` 로 담을 수 없다. 세 스위트 어디에도 커버가 없다. **제품 별건으로 열어야 한다** — 고쳐진 뒤에 케이스가 붙는다 |
| **GR-11 프루닝 칸** | 비용 모델의 재료 교체(`qmgPartition::reviseAccessMethodsCost` 의 네이티브 글로벌 분기 → `mPrePruningPartRef`). J25 기록: *"판정·좌표·수용 기준이 다 있었는데 `jobs.tsv` 에 행이 없어 아무도 받지 않았다"* | 제품 코드 변경이다. 수용 기준이 `stat-bias-sweep` 24 칸 — 그 스윕도 삭제될 그물에 있으므로 **그물이 사라지기 전에** 처리해야 한다 |
| `Concurrency/` · `Lifecycle/` | 세 스위트 모두 **0**. 계획서가 "계약이 필요한 레인" 으로 예약해 둔 자리 | 계약(다중 세션·재기동)이 서면 그때 채운다. §3.3 이 어느 브리프를 따를지 적어 두었다 |

**GR-11 은 순서가 걸려 있다** — 수용 기준인 `stat-bias-sweep` 이 Phase E
에서 건지는 목록에 없다(벤치·스윕 계열은 §9.1 "못 건지는 것"). 그러므로
GR-11 을 넣으려면 **그물이 살아 있는 동안**이어야 한다. 이 계획보다 앞선다.
