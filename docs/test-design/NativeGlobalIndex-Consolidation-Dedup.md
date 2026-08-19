# 통합 전 중복 판정표 — Claude 37 × Codex 116

- 통합 계획: `NativeGlobalIndex-Consolidation-Plan.md` (§4 · Phase A-1)
- 실측 기준: 2026-08-19, `rnd-ai5` 체크아웃
- 상태: **1차 판정.** 판정 근거와 확정도는 §1 을 먼저 읽을 것

---

## 0. 판정 규칙

계획 §4.2 의 셋을 그대로 쓴다.

| 판정 | 뜻 | 처리 |
|---|---|---|
| **(ㄱ) 완전 중복** | 같은 매체에서 같은 문장을 같은 관점으로 잰다 | 하나만 남긴다. **`.lst` 가 더 촘촘한 쪽**을 남긴다 |
| **(ㄴ) 부분 중복** | 겹치는 자리와 갈리는 자리가 있다 | 갈리는 자리를 남는 케이스에 흡수하고, 흡수한 자리를 주석에 적는다 |
| **(ㄷ) 중복 아님** | 매체 · 프로퍼티 축 · 관점 중 하나라도 다르다 | 둘 다 남긴다(= Codex 쪽을 흡수한다) |

**판정 없이 삭제·복사되는 케이스가 0** 이어야 한다. 이 표의 행 수가 그
보증이다.

---

## 1. 방법과 한계 — 이 표를 어디까지 믿을 것인가

### 1.1 무엇으로 판정했나

| 재료 | 썼다 |
|---|---|
| Claude 37 | `TestCase Description` + **`SECTOR` 목록 전량** |
| Codex 116 | `TestCase Description` + `Test ID` |
| 교차 확인 | 흡수 후보마다 Claude 전문 grep (§1.3) |

**Codex 는 `SECTOR` 주석이 Claude 와 형식이 달라 목록을 같은 방식으로 뽑지
못했다.** 그래서 Codex 쪽은 한 줄 설명이 판정의 주 근거다.

### 1.2 그래서 이 표는 1차다

행마다 **확정도**를 붙였다.

- **`측정`** — 기계적으로 확인했다(grep 으로 Claude 에 있고/없음을 셌다).
- **`제목`** — 제목과 SECTOR 만 보고 판정했다. **본문 대조가 남아 있다.**

`제목` 행을 그대로 삭제 근거로 쓰면 안 된다. Phase C·D 에서 그 행을 열 때
본문을 읽고 확정도를 `측정` 으로 올린 뒤 처리한다.

**선례가 이 조심의 근거다** — Port1624 DDL 배치 25 개를 이식하기 전 자매
스위트와 중복 판정을 했더니 **완전 중복이 0** 이었다. 제목이 겹쳐 보이는
것과 실제로 같은 것을 재는 것은 다르다.

### 1.3 흡수 후보의 기계 확인 — Claude 전문 grep

| 찾은 것 | Claude 안의 건수 | 뜻 |
|---|---:|---|
| `savepoint` | **2** | Codex Transaction 계열이 통째로 새것은 아니다 |
| DDL 과 트랜잭션 | 1 | 〃 |
| `GATHER_TABLE_STATS` · `ANALYZE` | **0** | 통계 수집 축이 **없다** |
| 인덱스 8 개 이상 동시 | **0** | 다중 인덱스 축이 **없다** |
| `CREATE VIEW` | **0** | 뷰 축이 **없다** |
| `MERGE INTO` | **0** | 두 스위트 다 없다 — 공백 (§5) |
| 파티션 65 개 | **0** | Claude 의 `65` 매치는 전부 **인덱스 예산**(64+1)이지 파티션 수가 아니다 |
| 힌트(`NO_INDEX` 등) | 25 | 힌트 축은 Claude 가 두껍다 |

---

## 2. 판정표 — Codex **Memory** 58 × Claude 37

Codex 영역 순서로 적는다. "Claude 대응" 이 비면 (ㄷ)이다.

### 2.1 Boundary (6)

| Codex Memory | Claude 대응 | 판정 | 확정도 | 근거 |
|---|---|---|---|---|
| `Boundary/singleAndManyPartitions` | `ddl/createIndex` | ㄴ | 제목 | 파티션 1 개 대 8 개의 대비가 Claude 에 명시적 섹터로 없다 |
| `Boundary/globalIndexCount64` | `ddl/indexBudget` | ㄴ | 측정 | Claude 는 **63 로컬 + 1 글로벌**(비트 예산)을 잰다. Codex 는 **글로벌 64 개**다 — 축이 다르다 |
| `Boundary/globalIndexCount65Reject` | `ddl/indexBudget` | ㄴ | 측정 | Claude 에 `ERR-314AC` 거절이 이미 있다(63+1+1, 64+0+1). Codex 의 "원자적 거절" 관점만 흡수 |
| `Boundary/dropCascade64` | `ddl/dropCascade` + `ddl/indexBudget` | ㄴ | 제목 | cascade drop 과 64 예산이 Claude 에는 **따로** 있다. 그 조합이 새것 |
| `Boundary/participantCount65` | — | **ㄷ** | **측정** | **파티션 65 개가 Claude 에 없다.** 흡수 |
| `Boundary/recreateObjectIdentity` | `ddl/dropCascade`(같은 이름 재생성) · `ddl/dropIndex`(RECREATE) | ㄴ | 제목 | 재생성 뒤 **낡은 식별자가 남지 않는가**가 갈리는 자리 |

### 2.2 Catalog (2)

| Codex Memory | Claude 대응 | 판정 | 확정도 | 근거 |
|---|---|---|---|---|
| `Catalog/implementationType` | `meta/nativeCatalog` | **ㄱ 유력** | 제목 | Claude 가 `SYS_INDICES_`·`SYS_PART_INDICES_`·`SYS_INDEX_PARTITIONS_` 를 전부 잰다 |
| `Catalog/noHiddenObjects` | `meta/nativeCatalog`(NO HIDDEN OBJECT 섹터) | **ㄱ 유력** | 제목 | 섹터 이름이 그대로 같다 |

### 2.3 Create (9)

| Codex Memory | Claude 대응 | 판정 | 확정도 |
|---|---|---|---|
| `Create/partitionKinds` | `ddl/createIndex` · `dml/insert`(RANGE/HASH/LIST) | ㄴ | 제목 |
| `Create/emptyAndPopulatedBuild` | `ddl/createIndex`(CREATE ON EXISTING DATA · EMPTY PARTITION INCLUDED) | **ㄱ 유력** | 제목 |
| `Create/keyAndConstraint` | `ddl/createIndex` · `datatype/variableColumn` | ㄴ | 제목 |
| `Create/keyShapeBoundary` | `dml/nullValue` · `datatype/variableColumn` · `scan/preservedOrder` | ㄴ | 제목 |
| `Create/tableConstraintForms` | `unique/primaryKey`(PK IN CREATE TABLE) | **ㄱ 유력** | 제목 |
| `Create/alterConstraintLifecycle` | `ddl/constraint` | ㄴ | 제목 |
| `Create/duplicateBuildAbort` | `ddl/constraint`(ADD CONSTRAINT ON DUPLICATE DATA) | ㄴ | 제목 |
| `Create/functionBased` | `datatype/functionIndex` | **ㄱ 유력** | 제목 |
| `Create/sameMediaTablespaces` | `tablespace/multiTablespace` | **ㄱ 유력** | 제목 |

### 2.4 DDL (9)

| Codex Memory | Claude 대응 | 판정 | 확정도 |
|---|---|---|---|
| `DDL/cascadeDrop` | `ddl/dropCascade` | **ㄱ 유력** | 제목 |
| `DDL/dropMultipleIndexes` | `ddl/dropIndex`(DROP ONE OF MANY · DROP ALL GLOBAL) | **ㄱ 유력** | 제목 |
| `DDL/rebuildAndDrop` | `ddl/alterIndexRebuild` | **ㄱ 유력** | 제목 |
| `DDL/schemaEvolution` | `ddl/alterTableColumn` | **ㄱ 유력** | 제목 |
| `DDL/indexedColumnDependency` | `ddl/alterTableColumn`(DROP COLUMN AFTER/BEFORE THE KEY) | **ㄱ 유력** | 제목 |
| `DDL/constraintCascade` | `ddl/constraint` | ㄴ | 제목 |
| `DDL/renameTableAndConstraint` | `ddl/alterIndex`(RENAME INDEX) | ㄴ | 제목 — Claude 는 **인덱스** rename, Codex 는 **테이블** rename |
| `DDL/truncateAndRename` | `partition/addTruncatePartition` | ㄴ | 제목 — Claude 는 **파티션** TRUNCATE, Codex 는 **테이블** TRUNCATE |
| `DDL/truncateReuseMultiIndex` | 〃 | ㄴ | 제목 |

### 2.5 DML (9)

| Codex Memory | Claude 대응 | 판정 | 확정도 |
|---|---|---|---|
| `DML/insertUpdateDelete` | `dml/insert` · `dml/updateDelete` | **ㄱ 유력** | 제목 |
| `DML/bulkDeterministicRows` | `dml/insert`(MANY ROWS) | **ㄱ 유력** | 제목 |
| `DML/insertSelectMultiIndex` | `dml/insert`(INSERT SELECT) | ㄴ | 제목 — 다중 인덱스 축이 갈린다 |
| `DML/hashListMutation` | `dml/insert` · `dml/rowMovement` | ㄴ | 제목 |
| `DML/repeatedRowMovement` | `dml/rowMovement` | **ㄱ 유력** | 제목 |
| `DML/rowMovementAndUnique` | `dml/rowMovement` · `unique/crossPartition` | **ㄱ 유력** | 제목 |
| `DML/deleteReinsertReuse` | `unique/crossPartition`(UNIQUE AFTER DELETE) | **ㄱ 유력** | 제목 |
| `DML/multiRowStatementAtomicity` | `dml/updateDelete`(UPDATE AND ROLLBACK) | ㄴ | 제목 — "유니크 오류에서 문장이 통째로 되돌아가는가"가 갈리는 자리 |
| `DML/manyGlobalIndexes` | — | **ㄷ** | **측정** | **인덱스 8 개를 한 DML 로 유지하는 축이 Claude 에 없다.** 흡수 |

### 2.6 Query (10)

| Codex Memory | Claude 대응 | 판정 | 확정도 |
|---|---|---|---|
| `Query/localGlobalCoexist` | `ddl/createIndex`(LOCAL VS GLOBAL) | **ㄱ 유력** | 제목 |
| `Query/forUpdateAndCursor` | `scan/scanAndLock`(SELECT FOR UPDATE) | **ㄱ 유력** | 제목 |
| `Query/joinSubqueryView` | `scan/joinAndFilter` | ㄴ | **측정** — 조인·서브쿼리는 겹치나 **`CREATE VIEW` 가 Claude 에 0 건**이다 |
| `Query/predicateMatrix` | `scan/scanAndLock` · `scan/hostVariable` | ㄴ | 제목 |
| `Query/descendingCompositeOrder` | `scan/preservedOrder` · `datatype/functionIndex`(DESCENDING KEY) | ㄴ | 제목 |
| `Query/nullSkewAndDuplicates` | `dml/nullValue` · `tablespace/multiTablespace` | ㄴ | 제목 |
| `Query/rangeOrderPruning` | `scan/scanAndLock` | ㄴ | 제목 |
| `Query/pruningCardinality` | `scan/scanAndLock`(PARTITION PRUNING BY KEY) | **ㄴ — 흡수 가치 큼** | 제목 | 0 / 1 / 다수 / 전체 파티션의 프루닝 기수. **J19b(파티션 키 OR 체인 프루닝 오답)의 회귀 축**이다 |
| `Query/optimizerSelection` | — | **ㄷ** | 제목 | 무힌트 · 로컬 · 네이티브 · 풀스캔 **비교**가 Claude 에 없다. Claude 가 힌트를 안 쓰는 것은 아니다 — `index(t1,gidx1)` 136 회 · `FULL SCAN(t1)` 73 회로 **못박는 데** 쓴다. 갈리는 것은 "네 경로를 나란히 놓고 옵티마이저의 선택과 견주는" 틀이다 |
| `Query/statisticsContinuity` | — | **ㄷ** | **측정** | **`GATHER_TABLE_STATS`·`ANALYZE` 가 Claude 에 0 건.** GR-11(통계 편향)과 인접한 축이다 |

### 2.7 Transaction (4) — Claude 는 `dml/isolation` 하나뿐

| Codex Memory | Claude 대응 | 판정 | 확정도 |
|---|---|---|---|
| `Transaction/transactionRollback` | `dml/updateDelete`(UPDATE AND ROLLBACK) | ㄴ | 제목 |
| `Transaction/savepointRollback` | `dml/updateDelete`(UPDATE AND SAVEPOINT) · `unique/crossPartition`(UNIQUE AND SAVEPOINT) | ㄴ | **측정** — savepoint 가 Claude 에 **2 건 있다.** 통째로 새것이 아니다 |
| `Transaction/statementRollback` | — | **ㄷ** | 제목 | 실패한 문장 뒤 인덱스 항목이 남는가 |
| `Transaction/ddlTransactionGuard` | — | **ㄷ** | 제목 | 트랜잭션 중 DDL 거절 |

### 2.8 Unsupported (9) — Claude 는 `ddl/createIndexError` 하나

Claude 의 섹터: MEDIA MISMATCH / HYBRID PARTITIONED TABLE / VOLATILE
PARTITION / DIRECTKEY INDEX / PERSISTENT INDEX / COMPRESSED KEY COLUMN /
PROPERTY OFF / NON-PARTITIONED …

| Codex Memory | Claude 대응 섹터 | 판정 | 확정도 |
|---|---|---|---|
| `Unsupported/mediaAndOptions` | MEDIA MISMATCH | **ㄱ 유력** | 제목 |
| `Unsupported/mixedMediaAndVolatile` | HYBRID · VOLATILE | **ㄱ 유력** | 제목 |
| `Unsupported/keyStorageOptions` | DIRECTKEY · PERSISTENT · COMPRESSED | **ㄱ 유력** | 제목 |
| `Unsupported/indexTypes` | (일부) | ㄴ | 제목 |
| `Unsupported/buildModes` | — | ㄷ | 제목 |
| `Unsupported/ddlCombination` | — | **ㄷ** | 제목 | 한 문장에 여러 개 생성 |
| `Unsupported/savepointDdlCombination` | — | **ㄷ** | 제목 | savepoint 를 가로지르는 DDL |
| `Unsupported/partitionDdl` | `partition/*` 의 거절 자리 | ㄴ | 제목 |
| `Unsupported/splitMergePartition` | `partition/splitMergeReplace` | ㄴ | 제목 |

---

## 3. Codex **Disk** 58 — 3 자 판정이 필요하다

Codex Disk 58 은 Memory 58 과 **이름이 거의 대칭**이다(Disk 에만
`Unsupported/buildOptions`, Memory 에만 `Unsupported/mediaAndOptions`).

그러나 디스크 쪽은 상대가 둘이다:

```
Codex Disk 58   ×   Claude (디스크 케이스 1: ddl/diskPartitionedTable)
                ×   Port1624 (208 실행 단위, 전부 디스크)
```

**그래서 §2 의 판정을 그대로 옮길 수 없다.** 매체가 갈라 Claude 와는
대부분 (ㄷ)이 되지만, **Port1624 와 겹치는지가 남는다** — 특히
`Catalog/*`(Port1624 `meta/` 8), `DDL/*`(Port1624 `DDL/` 25),
`Query/*`(Port1624 `design/` 16).

**이 절은 비워 둔다.** 채우는 조건은 §5 의 둘이다.

---

## 4. 1 차 흡수 목록 — 오늘 기준 **11**

(ㄷ) 로 판정했거나 (ㄴ) 중 갈리는 자리가 큰 것.

| # | Codex Memory | 왜 |
|---|---|---|
| 1 | `Boundary/participantCount65` | 파티션 65 개 — 측정으로 부재 확인 |
| 2 | `DML/manyGlobalIndexes` | 인덱스 8 개 동시 유지 — 측정으로 부재 확인 |
| 3 | `Query/statisticsContinuity` | 통계 수집 축 — 측정으로 부재 확인 |
| 4 | `Query/optimizerSelection` | 후보 비교 |
| 5 | `Query/pruningCardinality` | 프루닝 기수 — **J19b 회귀 축** |
| 6 | `Query/joinSubqueryView` | 뷰 축 — 측정으로 부재 확인 |
| 7 | `Transaction/statementRollback` | 실패 문장 뒤 정합 |
| 8 | `Transaction/ddlTransactionGuard` | 트랜잭션 중 DDL 거절 |
| 9 | `Unsupported/ddlCombination` | 한 문장 다중 생성 |
| 10 | `Unsupported/savepointDdlCombination` | savepoint 가로지르는 DDL |
| 11 | `Unsupported/buildModes` | 빌드 모드 거절 |

**계획서 §5.2 의 거친 추정 "~30" 은 과대였다.** 제목 기준 1 차에서는 11 이고,
(ㄴ) 의 흡수분(갈리는 섹터만 남는 케이스로 옮김)을 더해도 그보다 크게
늘지 않는다. Disk 쪽(§3)이 채워지면 다시 센다.

**흡수분 전부에 두 가지가 따라붙는다** (계획 §5.3 · §5.4):
1. **`.lst` 재기록** — Codex `.lst` 는 08-02~08-05 기록이고 그 뒤 제품이
   J19b · J23 · J24 로 바뀌었다.
2. **프로퍼티 못박기 추가** — Codex 116 은 `GLOBAL_INDEX_ENABLE` 을 한
   자리도 못박지 않는다.

---

## 4.1 ★ Phase D 실측 — 흡수 11 을 실제로 옮겼고, 그 과정에서 둘을 알았다

11 을 `NativeGlobalIndexClaude/Memory/` 로 복사해 배선했다(240 → 251, 전량
그린). 옮기며 실측한 것 둘은 이 표의 판정보다 크다.

### (1) Codex 는 오늘 빌드에서 **17 / 99** 였다 — 그러나 제품 탓이 아니었다

첫 실행이 116 중 99 붉음. §5.3(제품이 세 번 바뀌었다)으로 읽기 쉬우나
붉은 케이스의 첫 어긋남이 전부 이것이었다:

```
[ERR-313D0 : A non-partitioned index can be created on a disk partitioned table.]
```

`MEM_GLOBAL_INDEX_ENABLE` 이 **0** 인 상태로 돌았다. 직전에 돌린
`NativeGlobalIndexClaude` 의 `regress/noGlobalIndexUnchanged` 가 FINALIZE 에서
껐고, 프로퍼티는 비영속이되 **도는 인스턴스 안에서는 남는다.** 자기 전제를
세우지 않는 Codex 가 그것을 물려받았다. 재기동으로 파일 기본값(1)을
복원하니 **31 / 85**.

계획 §5.4 가 "권고" 로 적었던 것이 **흡수의 전제**임이 이렇게 확인됐다.

### (2) `INDEX_IMPL_TYPE` 은 **존재하지 않는 컬럼**이다

Codex 가 **50 번** 참조한다. 카탈로그로 확인:

```
SYS_INDICES_ 에 INDEX_IMPL_TYPE  -> 0 건
SYS_INDICES_ 에 INDEX_TABLE_ID   -> 1 건
```

그 질의들은 애초에 성공할 수 없고 `ERR-31058 : Column not found` 로 죽는다.
남은 85 붉음의 큰 몫이 이것이다 — **"제품이 바뀌어서" 가 아니라 "케이스가
틀려서" 붉은 쪽**이고, 계획 §5.3 이 가르라고 한 두 갈래 중 후자다.

판별자는 `INDEX_TABLE_ID`(네이티브 = 0) 하나로 충분하고 Codex 질의가 이미
그 컬럼을 함께 뽑고 있어서, 흡수본에서는 없는 컬럼만 뺐다.

### (3) 흡수본에 더한 것 셋

| | |
|---|---|
| 출처 주석 | 원본 경로와 "codex 브랜치가 관리한다" |
| 프로퍼티 못박기 | `PREPARATION` 머리에 `alter system set MEM_GLOBAL_INDEX_ENABLE = 1;` + `v$property` 확인 |
| 없는 컬럼 제거 | `INDEX_IMPL_TYPE` |

`.lst` 는 11 전부 **재기록**했다(계획 §8.6 의 이 Phase 예외). 기록 전에
절대 카탈로그 id · 시각 · 경로가 섞였는지 검사해 **0** 을 확인했다 —
Port1624 의 넷이 그것 때문에 순서에 묶인 것을 막 겪은 뒤였다.

**Codex 디렉터리는 한 줄도 건드리지 않았다.**

---

## 5. 이 표를 닫으려면 — 남은 둘

1. **Codex 116 을 오늘 빌드에서 돌린다.** 08-05 이후 실행 이력이 없어
   그린 여부를 모른다. 붉은 케이스는 흡수 대상에서 빼는 것이 아니라
   **원인을 가른 뒤** 판정한다 — 제품이 바뀌어서 붉은 것과 케이스가
   틀려서 붉은 것은 처리가 다르다.
2. **§3(Disk 58 의 3 자 판정)** — Port1624 와의 대조가 필요하다.

그리고 `제목` 확정도 행은 Phase C·D 에서 본문을 읽고 `측정` 으로 올린 뒤
처리한다 (§1.2).

---

## 6. 곁가지 — 두 스위트에 다 없는 것

중복 판정을 하다 보이는 공백이다. 통합의 범위는 아니지만 적어 둔다.

| 없는 것 | 확인 |
|---|---|
| `MERGE INTO` | **세 스위트 전부 0 건**(Claude 37 · Codex 116 · **Port1624 208 실행 단위 포함**). V4 A-7(J11)이 `MOVE`·`MERGE`·`INSERT…SELECT` 를 글로벌 플랜의 통과 목록에 넣었는데 **그 축을 재는 `.tc` 가 NATC 어디에도 없다.** 삭제될 그물의 `sql-level-check` K 절 22 칸이 오늘 그것을 재는 유일한 자리이므로, 계획 §8.3 의 `sql-level-check` 분해에서 이 절을 놓치면 검증이 통째로 사라진다 |
| `Concurrency/` · `Lifecycle/` | 세 스위트 모두 0 — 계획 §9.2 의 보류 레인 |
