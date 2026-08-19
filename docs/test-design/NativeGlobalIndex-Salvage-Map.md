# 건지기 분해표 — 삭제될 그물 47 개 검사 스크립트

- 통합 계획: `NativeGlobalIndex-Consolidation-Plan.md` (§8 · Phase A-2)
- 대상: `altibase/scripts/global-index/*-check.sh` **47 개** (반영 시 삭제 예정)
- 실측 기준: 2026-08-19

---

## 0. ★ 계획서 §8.2 를 정정한다 — 21 이 아니라 11 이다

계획서는 "SQL 전용 검사 21 개" 를 건진다고 적었다. **그 수는 틀렸다.**

원인은 재기동을 찾는 패턴이었다. 계획을 세울 때 `testdb.sh restart` 로만
찾았는데, 스크립트들은 실제로 **`"$TESTDB" restart`** 라고 쓴다. 그래서
재기동하는 스크립트 일곱이 "SQL 전용" 으로 잘못 분류됐다 —
`allindex-check` · `catalog-check` · `column-ddl-check` ·
`disk-catalog-check` · `empty-table-ddl-check` · `reorg-ddl-check` ·
`tbsonline-check`.

정정한 패턴 여섯으로 다시 세었다:

| 기호 | 찾은 것 |
|---|---|
| **R** | `"$TESTDB" restart` · `testdb.sh restart` · `shutdown abort` |
| **F** | `FIT_ENABLE` · `ngi_fit` |
| **C** | `ngi_cli` |
| **S** | `src/` grep · `trc/` · `altibase_boot.log` — **SQL 밖의 오라클** |
| **G** | `golden/` · `regression0` |
| **P** | `GLOBAL_INDEX_ENABLE` (프로퍼티를 못박는가 — 참고용) |

**R·F·C·S·G 가 전부 비고 단언이 1 개 이상인 것이 11 개다.**

---

## 1. 전수 분류 (47)

`단언` = `expect_ok` / `expect_err` / `expect_val` / `ok ` / `fail ` 의 합.

| 스크립트 | 단언 | R | F | C | S | G | P |
|---|---:|:-:|:-:|:-:|:-:|:-:|:-:|
| `cost-model-check` | 17 | | | | | | Y |
| `disk-planstat-check` | 41 | | | | | | Y |
| `dml-handoff-check` | 16 | | | | | | Y |
| `fk-restrict-check` | 14 | | | | | | Y |
| `fk-routing-check` | 38 | | | | | | Y |
| `global-partfilter-check` | 33 | | | | | | Y |
| `parallel-answer-check` | 7 | | | | | | Y |
| `partition-ddl-check` | 26 | | | | | | |
| `partition-filter-check` | 6 | | | | | | Y |
| `select-plan-check` | 3 | | | | | | Y |
| `uncommitted-check` | 33 | | | | | | Y |
| — 위 **11 = 의존 없음, 합 234 단언** — | | | | | | | |
| `allindex-check` | 67 | Y | | | | | Y |
| `catalog-check` | 33 | Y | | | Y | | Y |
| `column-ddl-check` | 76 | Y | | | | | Y |
| `disk-catalog-check` | 134 | Y | | | | | Y |
| `empty-table-ddl-check` | 57 | Y | | | | | Y |
| `media-recovery-check` | 61 | Y | | | Y | | Y |
| `memberoverflow-check` | 22 | Y | | | Y | | Y |
| `reorg-ddl-check` | 112 | Y | | | Y | | Y |
| `rowmovement-order-check` | 23 | Y | | | | | Y |
| `sm-matrix-check` | 157 | Y | | | Y | | Y |
| `tbsonline-check` | 86 | Y | | | Y | | Y |
| `partition-reorg-check` | 0 | Y | | | | | |
| `sql-level-check` | 279 | Y | | Y | Y | | Y |
| `write-concurrency-check` | 12 | Y | | Y | | | Y |
| `natc-check` | 0 | Y | | | | Y | Y |
| `disk-matrix-check` | 147 | Y | | | Y | Y | Y |
| `crash-injection-check` | 60 | | Y | | Y | | Y |
| `disk-crash-check` | 125 | | Y | | Y | Y | Y |
| `disk-review-fix-check` | 82 | | Y | | Y | Y | Y |
| `disk-undo-check` | 0 | | Y | | Y | | |
| `parallel-scan-check` | 37 | | Y | | Y | | Y |
| `dropidentity-check` | 94 | | | | Y | | Y |
| `multibuild-check` | 39 | | | | Y | | |
| `parallelbuild-check` | 6 | | | | Y | | Y |
| `replication-check` | 255 | | | | Y | | Y |
| `4k-native-index-check` | 8 | | | | Y | | Y |
| `cursorpos-check` · `keydelete-check` · `keyinsert-check` · `o1-legacy-corrupt-check` · `rowaccess-check` · `disk-logging-check` | 25·22·12·2·17·0 | | | | Y | | |
| `discriminator-check` | 3 | | | | Y | | |
| `natc-port-check` · `syntax-check` · `partition-ddl-lock-check` | 0·0·0 | | | | | | |

---

## 2. 건지는 11 — 레인 배치와 변환 모양

전부 디스크 축이다(그물이 디스크 위에서 섰다).

| 스크립트 | 단언 | 목적지 | 변환 |
|---|---:|---|---|
| `select-plan-check` | 3 | `Disk/Query/` | 플랜 전사 — `.lst` 와 궁합이 가장 좋다 |
| `disk-planstat-check` | 41 | `Disk/Query/` | 〃 |
| `cost-model-check` | 17 | `Disk/Query/` | 비용 비교 — **동적 단언**(마진 부호). §3 |
| `global-partfilter-check` | 33 | `Disk/Query/` | 프루닝 — J19b 회귀 축 |
| `partition-filter-check` | 6 | `Disk/Query/` | 〃 |
| `parallel-answer-check` | 7 | `Disk/Query/` | **병렬 — 체크섬만 박는다**(스레드 수 금지). §3 |
| `dml-handoff-check` | 16 | `Disk/DML/` | handoff 정합 |
| `fk-routing-check` | 38 | `Disk/DML/` | FK 라우팅 |
| `fk-restrict-check` | 14 | `Disk/DML/` | FK 제약 |
| `uncommitted-check` | 33 | `Disk/Transaction/` | 미커밋 가시성 |
| `partition-ddl-check` | 26 | `Disk/DDL/` | 파티션 DDL |

**합 234 단언.** 프로퍼티를 못박는 것이 11 중 10 — 통합 스위트의 규약과 맞다.

### 2.1 변환이 직접적인 이유 — 실측한 형태

`catalog-check` 의 헬퍼 셋이 전형이다:

```bash
expect_ok  "LOCAL index still works"                  "<SQL>"
expect_err "global PK ... refused"        "31415"     "<SQL>"
expect_val "... still builds a $GIT_ table"   1        "<SELECT>"
```

`.tc` 로 옮기면 **단언이 사라지고 전사가 그 자리를 대신한다**:

| 셸 | `.tc` | `.lst` 에 남는 것 |
|---|---|---|
| `expect_ok` | SQL 을 그냥 실행 | `Create success.` |
| `expect_err "…" "31415"` | SQL 을 그냥 실행 | `[ERR-31415 : …]` |
| `expect_val … 1 "<SELECT>"` | SELECT 를 그냥 실행 | 값 한 줄 |

세 헬퍼가 전체 단언의 대부분이므로, **11 개 중 대부분은 기계적 이식에
가깝다.** 공수는 §3 의 예외에 몰려 있다.

---

## 3. 기계적이지 않은 자리 — 여기에 공수가 있다

| 자리 | 문제 | 처리 |
|---|---|---|
| **동적 단언** | "마진이 음수인가", "합집합 == 전체", "교집합 == 공집합" 은 값이 아니라 **판정**이다. `.lst` 는 값만 받는다 | 값을 SQL 로 유도해 **boolean 한 줄**로 찍게 다시 쓴다 |
| **병렬** | 실스레드 수·슬라이스 분배가 실행마다 갈린다 | `.lst` 에 박을 것은 스레드 수가 아니라 **직렬과 같은 체크섬** |
| **비용 수치** | `cost-model-check` 가 찍는 비용은 통계·기계에 매달린다 | 절대값을 박지 않는다. 부호·순서만 |
| **카탈로그 나열** | 이웃 케이스의 잔재를 본다 | 자기 객체로 범위를 좁힌다(계획 §8.5 규약 ①) |

---

## 4. 재기동 절만 떼면 건질 수 있는 것 — 11 더

R 만 켜져 있고 F·C·G 가 꺼진 것들이다. **재기동 절을 `Disk/Lifecycle/` 로
분리하면 나머지 본문이 건져진다.**

| 스크립트 | 단언 | 재기동 절이 재는 것 |
|---|---:|---|
| `disk-catalog-check` | **134** | 재기동 3 회 — 네이티브 · 레거시 혼재 · 전환 후 |
| `column-ddl-check` | 76 | |
| `allindex-check` | 67 | |
| `empty-table-ddl-check` | 57 | |
| `reorg-ddl-check` | 112 | 멤버 집합 생존 |
| `tbsonline-check` | 86 | |
| `rowmovement-order-check` | 23 | |
| `sm-matrix-check` | 157 | §계획 8.2.1 의 9 절 분해와 겹친다 |
| `media-recovery-check` | 61 | 미디어 복구 — 본디 `Lifecycle/` |
| `memberoverflow-check` | 22 | |
| `catalog-check` | 33 | 재기동 + `altibase_boot.log` grep |

합 **828 단언**. 다만 `Lifecycle/` 은 TC_GUIDE 범위 밖이라 계약이 먼저다
(계획 §3.3).

---

## 5. 규모 — 정직하게

| 구간 | 스크립트 | 단언 | 상태 |
|---|---:|---:|---|
| 의존 없음 (§2) | 11 | 234 | **바로 착수 가능** |
| 재기동 절 분리 후 (§4) | 11 | 828 | `Lifecycle/` 계약 뒤 |
| FIT · 골든 · `ngi_cli` 혼합 | 8 | ~700 | 절 단위로 갈라야 한다 |
| 정적 소스 감사 · 러너 | 17 | — | **건지지 않는다** (계획 §9.1) |

**§2 의 234 단언이 오늘 착수 가능한 전부다.** 케이스 하나에 단언 여러 개가
들어가므로 `.tc` 수로는 이보다 훨씬 적지만, 각 단언마다 `.lst` 전사를 새로
찍어야 하므로 **이 구간만으로도 한 세션에 끝나지 않는다.**
