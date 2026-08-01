# NativeGlobalIndexCodex V1 테스트 보강 계획

- 작성일: 2026-08-02
- 대상: `TC/Server/sm4/Project4/NativeGlobalIndexCodex`
- 구현 범위: Native Global Index V1
- 현재 제약: 서버 실행 불가, expected result(`*_A4_64.lst`) 생성 보류
- 문서 상태: 보강 작업용 계획 기준선

## 1. 목적

현재 `NativeGlobalIndexCodex`에는 Disk 20개, Memory 20개의 source-only SQL
prototype이 있다. 이 baseline은 native catalog identity, 기본 CREATE/Query/DML,
일부 DDL과 unsupported 동작을 넓게 확인하지만, V1 release gate에 필요한
transaction, concurrency, boundary, DDL dependency, optimizer proof,
lifecycle/recovery 항목은 충분히 깊지 않다.

이 계획의 목적은 서버를 사용할 수 없는 동안 다음 작업을 먼저 끝내는 것이다.

1. 실행 환경과 무관하게 작성 가능한 `.tc`와 `.ts` source를 보강한다.
2. Disk와 Memory의 공통 계약은 같은 test family로 만들되 artifact는 분리한다.
3. 실패 이후 catalog와 data가 변하지 않았다는 negative oracle을 강화한다.
4. restart, crash, FIT, replication처럼 환경 계약이 필요한 항목은 별도 backlog로
   분리하고 일반 SQL suite에 섞지 않는다.
5. 실제 서버가 준비되면 `.out` 검토, tagged `.lst` 생성, 재실행 PASS만 남도록
   traceability와 실행 순서를 정리한다.

## 2. 적용 규칙과 기준 문서

보강 artifact는 다음 문서를 따른다.

- NATC 일반 TC 규칙: `docs/TC_GUIDE.md`
- NATC FIT 규칙: `docs/FIT_GUIDE.md`
- 전체 전환 설계: `docs/test-design/PROJ-1624-NativeGlobalIndexV2.md`
- 현재 suite 계약: `TC/Server/sm4/Project4/NativeGlobalIndexCodex/README.md`
- 현재 case matrix: `TC/Server/sm4/Project4/NativeGlobalIndexCodex/TEST_MATRIX.md`
- 구버전 이관 기록: `TC/Server/sm4/Project4/NativeGlobalIndexCodex/LEGACY_COVERAGE.md`
- SQL/iSQL 문법 확인 기준:
  `altidev4_gi/docs/manuals/altibase/trunk/eng/iSQL User's Manual.md`
- hint와 plan 확인 기준:
  `altidev4_gi/docs/manuals/altibase/trunk/eng/Performance Tuning Guide.md`

새 `.tc`는 `DEF MAIN()`과 INITIALIZATION, PREPARATION, TEST, FINALIZATION
순서를 사용한다. 출력 row에는 결정적인 `ORDER BY`를 사용하며 case가 만든
object만 정리한다. old-style `--+` directive, guessed error text, guessed plan
text, `$GIT_*` physical row oracle은 추가하지 않는다.

## 3. 현재 기준선과 판단

현재 source baseline은 다음과 같다.

| Media | Catalog | Create | Query | DML | DDL | Unsupported | 합계 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Disk | 2 | 3 | 4 | 4 | 4 | 3 | 20 |
| Memory | 2 | 3 | 4 | 4 | 4 | 3 | 20 |
| 합계 | 4 | 6 | 8 | 8 | 8 | 6 | 40 |

현재 테스트는 V1 functional smoke prototype으로는 유효하지만 release-grade
coverage로는 부족하다. 특히 다음 공백을 우선 보강한다.

- statement/savepoint/transaction rollback
- 동일 unique key에 대한 multi-session wait/commit/rollback
- CREATE 실패와 DDL 실패의 atomicity
- CREATE TABLE 안의 PK/UK와 ALTER TABLE constraint lifecycle
- table/index/constraint/column rename 및 dependency DDL
- indexed column DROP 실패 후 object 불변성
- 1개, 여러 개, 최대 개수의 native global index 경계
- partition pruning 0/1/N/all과 unhinted optimizer 선택
- statistics 수집 전후 query correctness
- `SELECT ... FOR UPDATE`와 active cursor 상호작용
- unsupported index type/build option/media/transaction 조합
- large row set, long variable key, NULL/duplicate skew
- clean restart, crash recovery, upgrade, backup/restore의 executable lane

## 4. 보강 후 디렉터리 구조

기존 분류를 유지하고 부족한 성격별 폴더를 추가한다.

```text
NativeGlobalIndexCodex/
  Disk/
    Catalog/
    Create/
    Query/
    DML/
    Transaction/       # 신규
    Concurrency/       # 신규
    DDL/
    Boundary/          # 신규
    Unsupported/
    Lifecycle/         # 환경 계약 전에는 문서/manifest만 유지
  Memory/
    Catalog/
    Create/
    Query/
    DML/
    Transaction/       # 신규
    Concurrency/       # 신규
    DDL/
    Boundary/          # 신규
    Unsupported/
    Lifecycle/         # 환경 계약 전에는 문서/manifest만 유지
  Deferred/            # 기본 root suite에 연결하지 않는 환경별 계획
    AdminTool/
    Compatibility/
    Replication/
    Performance/
```

`Transaction`, `Concurrency`, `Boundary`는 V1 핵심 기능이므로 media root suite에
연결한다. `Deferred`와 `Lifecycle`은 helper와 실행 환경이 확정될 때까지 root
suite에 연결하지 않는다.

## 5. 이번 보강에서 작성할 source-only case

아래 case는 서버 없이 source를 작성하고 구조를 정적으로 검토할 수 있다.
Disk와 Memory는 object name과 tablespace clause를 분리하고 같은 test family
ID를 사용한다.

### 5.1 Transaction

| Family ID | 제안 파일 | 핵심 검증 | 주요 oracle |
| --- | --- | --- | --- |
| NGI-TRX-001 | `statementRollback.tc` | duplicate/실패 statement가 기존 entry를 훼손하지 않음 | ordered rows, count, catalog identity |
| NGI-TRX-002 | `savepointRollback.tc` | savepoint 뒤 INSERT/UPDATE/DELETE/row movement를 되돌림 | index/full scan 동등성 |
| NGI-TRX-003 | `transactionRollback.tc` | 여러 partition과 여러 global index 변경 전체 rollback | pre/post row set 동일 |
| NGI-TRX-004 | `ddlTransactionGuard.tc` | transaction 중 허용되지 않는 native DDL 사전 거부 | data/catalog 불변성 |

`ddlTransactionGuard.tc`는 최종 error text를 고정하지 않는다. DDL 직후 catalog
count, `INDEX_IMPL_TYPE`, `INDEX_TABLE_ID`, 기존 query 결과가 변하지 않았는지만
source oracle로 둔다.

### 5.2 Concurrency

| Family ID | 제안 파일 | 핵심 검증 | 작성 조건 |
| --- | --- | --- | --- |
| NGI-CON-001 | `uniqueWaitCommit.tc` | T1 commit 후 대기 중인 동일 key T2 실패 | 기존 NATC THREAD/connection idiom 확인 |
| NGI-CON-002 | `uniqueWaitRollback.tc` | T1 rollback 후 대기 중인 T2 성공 | 기존 NATC THREAD/connection idiom 확인 |
| NGI-CON-003 | `disjointPartitionDml.tc` | 서로 다른 partition 동시 INSERT/UPDATE/DELETE | deterministic synchronization 필요 |
| NGI-CON-004 | `activeCursorDdl.tc` | active cursor 중 DROP/REBUILD의 계약 | 최종 lock/error 계약 확인 필요 |

Concurrency source는 repository의 검증된 multi-session idiom을 재사용한다.
server timing에 의존하는 `sleep`만으로 순서를 맞추지 않고, lock 또는 명시적
synchronization point가 확인된 경우에만 root suite에 연결한다.

### 5.3 CREATE와 constraint

| Family ID | 제안 파일 | 핵심 검증 |
| --- | --- | --- |
| NGI-CRT-004 | `tableConstraintForms.tc` | CREATE TABLE inline/out-of-line PK/UK가 native global backing index를 생성 |
| NGI-CRT-005 | `alterConstraintLifecycle.tc` | ADD/DROP PK/UK와 backing index catalog 수명 |
| NGI-CRT-006 | `duplicateBuildAbort.tc` | 중복 row가 있는 unique/PK/UK build 실패 후 partial object 0개 |
| NGI-CRT-007 | `emptyAndPopulatedBuild.tc` | empty/non-empty CREATE와 이후 DML |
| NGI-CRT-008 | `keyShapeBoundary.tc` | NULL, composite, ASC/DESC, long variable key 조합 |
| NGI-CRT-009 | `sameMediaTablespaces.tc` | 동일 media의 서로 다른 participant TBS와 index TBS |

FK는 global index 자체를 소유하지 않더라도 PK/UK dependency 회귀를 찾는 데
필요하므로 `alterConstraintLifecycle.tc`에서 참조 constraint의 생성/삭제 순서와
parent backing index 보호를 확인한다.

### 5.4 Query와 optimizer

| Family ID | 제안 파일 | 핵심 검증 |
| --- | --- | --- |
| NGI-QRY-005 | `optimizerSelection.tc` | hint 없는 query에서 local/native/full scan 후보의 결과 동등성 |
| NGI-QRY-006 | `pruningCardinality.tc` | pruning 대상 0/1/N/all partition |
| NGI-QRY-007 | `forUpdateAndCursor.tc` | native predicate의 `FOR UPDATE`, fetch 이후 DML |
| NGI-QRY-008 | `statisticsContinuity.tc` | 통계 수집 전후 결과와 catalog identity 유지 |
| NGI-QRY-009 | `nullSkewAndDuplicates.tc` | NULL/skew/duplicate가 많은 non-unique tree 검색 |
| NGI-QRY-010 | `descendingCompositeOrder.tc` | mixed ASC/DESC composite의 range와 ORDER BY |

서버가 준비되기 전에는 plan node 문자열을 `.tc` 내부에서 parsing하지 않는다.
query 결과와 full-scan 결과를 독립 출력하고, 실제 실행 시 생성된 plan을 검토해
안정된 access-path oracle만 추후 `.lst`에 반영한다.

### 5.5 DML과 data volume

| Family ID | 제안 파일 | 핵심 검증 |
| --- | --- | --- |
| NGI-DML-005 | `mergeAndReplacePatterns.tc` | 지원되는 MERGE/UPSERT 계열 DML이 entry를 정확히 유지 |
| NGI-DML-006 | `multiRowStatementAtomicity.tc` | multi-row DML 일부 실패 시 statement 전체 atomicity |
| NGI-DML-007 | `repeatedRowMovement.tc` | 동일 row를 partition 사이에서 반복 이동 |
| NGI-DML-008 | `manyGlobalIndexes.tc` | 한 DML이 여러 global index를 모두 갱신 |
| NGI-DML-009 | `bulkDeterministicRows.tc` | 결정적으로 생성한 large row set의 count/min/max/group checksum |
| NGI-DML-010 | `deleteReinsertReuse.tc` | DELETE 후 동일 key 재삽입과 unique state 재사용 |

`MERGE` 또는 UPSERT 문법은 대상 버전 SQL manual에서 확인된 형태만 사용한다.
확정되지 않은 문법은 case 이름만 선점하지 않고 matrix에서 Planned 상태로 둔다.

### 5.6 DDL과 dependency

| Family ID | 제안 파일 | 핵심 검증 |
| --- | --- | --- |
| NGI-DDL-005 | `renameTableAndConstraint.tc` | table/constraint rename 뒤 index identity와 DML 연속성 |
| NGI-DDL-006 | `indexedColumnDependency.tc` | indexed column DROP/변경 실패 후 data/catalog 불변 |
| NGI-DDL-007 | `constraintCascade.tc` | FK 존재 시 PK/UK/backing index DROP 순서와 보호 |
| NGI-DDL-008 | `rebuildFailureAtomicity.tc` | REBUILD 실패 시 기존 generation이 계속 사용 가능 |
| NGI-DDL-009 | `dropMultipleIndexes.tc` | 2개 이상의 global index DROP과 table cascade |
| NGI-DDL-010 | `truncateReuseMultiIndex.tc` | whole-table TRUNCATE 뒤 여러 index 재사용 |

`rebuildFailureAtomicity.tc`는 정상 SQL만으로 재현 가능한 실패 조건이 확인되는
경우에만 일반 suite에 둔다. allocator/WAL failure가 필요한 분기는 FIT lane으로
보내고 임의 FIT point를 만들지 않는다.

### 5.7 Boundary

| Family ID | 제안 파일 | 핵심 검증 |
| --- | --- | --- |
| NGI-BND-001 | `singleAndManyPartitions.tc` | 1 partition과 다수 partition의 동일 계약 |
| NGI-BND-002 | `globalIndexCount64.tc` | 한 parent의 native global index 64개 생성·DML·DROP |
| NGI-BND-003 | `globalIndexCount65Reject.tc` | 65번째 사전 거부와 기존 64개 불변 |
| NGI-BND-004 | `dropCascade64.tc` | 64개 index를 가진 table DROP의 catalog cleanup |
| NGI-BND-005 | `maximumKeyShape.tc` | 지원 최대 column/key length 경계와 초과 거부 |
| NGI-BND-006 | `recreateObjectIdentity.tc` | 반복 DROP/CREATE에서 stale entry/object 참조가 없음 |

최대 key 길이와 index column 수는 manual 및 최종 구현 상수의 교집합으로
결정한다. 숫자를 추측해 source에 고정하지 않는다.

### 5.8 Unsupported matrix

| Family ID | 제안 파일 | 핵심 검증 |
| --- | --- | --- |
| NGI-NEG-004 | `indexTypes.tc` | partitioned/partial global, R-tree, B_TREE2, user-defined type 거부 |
| NGI-NEG-005 | `keyStorageOptions.tc` | DIRECTKEY, Memory PERSISTENT/compressed, Disk index-only 계열 거부 |
| NGI-NEG-006 | `buildModes.tc` | online/parallel/FORCE/TOPDOWN/NOLOGGING 조합 거부 |
| NGI-NEG-007 | `tablespaceState.tc` | participant/index TBS ONLINE/OFFLINE 전환 거부 |
| NGI-NEG-008 | `mixedMediaAndVolatile.tc` | mixed media, volatile, private/temporary 대상 거부 |
| NGI-NEG-009 | `ddlCombination.tc` | 한 statement/transaction의 금지된 native DDL 조합 거부 |
| NGI-NEG-010 | `savepointDdlCombination.tc` | savepoint를 가로지르는 복수 native global DDL 거부 |

각 negative case는 실패 자체 외에 다음 후속 검증을 반드시 포함한다.

1. 요청 전후 logical index row 수가 동일하다.
2. 기존 native index의 implementation type과 table identity가 동일하다.
3. hidden fallback object가 생성되지 않는다.
4. 기존 index를 사용하는 SELECT와 후속 DML이 계속 성공한다.
5. 실패한 이름을 정상 DDL에서 다시 사용할 수 있다.

## 6. media별 차등 보강

공통 family를 기계적으로 복사하지 않고 구현 차이를 다음처럼 드러낸다.

### Memory

- variable key와 서로 다른 Memory tablespace participant 조합
- long snapshot 이후 DELETE/재삽입의 논리 결과
- restart 시 base row rebuild가 필요한 lifecycle matrix
- Memory 전용 금지 옵션: `INDEX PERSISTENT`, dictionary/compressed key
- startup rebuild 중 duplicate와 allocation failure는 Lifecycle/FIT로 분리

### Disk

- participant data TBS와 global index TBS 분리
- WAL을 사용하는 INSERT/UPDATE/DELETE/row movement의 transaction rollback
- offline REBUILD generation 교체의 user-visible atomicity
- Disk 전용 금지 옵션: NOLOGGING/FORCE/TOPDOWN/clustered/index-only 계열
- segment bind, crash redo/undo, corruption은 Lifecycle/FIT로 분리

## 7. 이번 단계에서 작성하지 않을 executable test

다음 항목은 V1에 필요하지만 서버 또는 환경 계약 없이는 올바른 artifact를
작성할 수 없다. 계획과 case ID는 유지하되 `.tc`를 추측해서 만들지 않는다.

| Lane | 필요한 항목 | 선행 조건 |
| --- | --- | --- |
| Lifecycle/Memory | clean/abnormal restart, startup rebuild, duplicate startup failure | restart helper, SERVICE 상태 oracle |
| Lifecycle/Disk | DML crash redo/undo, CREATE/REBUILD/DROP crash matrix | crash control, recovery/integrity oracle |
| FIT | allocation/WAL/publish N번째 failure, cleanup exact-once | 존재하는 공식 FIT UID 또는 source 변경 승인 |
| Compatibility | legacy hidden type 1 보존과 재생성 native 전환 | old binary fixture와 upgrade runner |
| Replication | base-row apply, sync DDL version gate, async DDL 거부 | 2-server topology와 fix-version contract |
| AdminTool | DROP USER/TBS cascade, iSQL DESC, aexport, backup/restore | 권한/fixture/tool runner |
| Performance | local/legacy/native 비교, capacity, long-running stress | scale, timeout, baseline hardware |

이 lane은 일반 SQL root suite에 연결하지 않는다. 특히 FIT point 이름, restart
명령, error text, timeout을 임의로 만들지 않는다.

## 8. 구현 순서

### Phase A: source 구조 보강

1. Disk와 Memory에 `Transaction`, `Concurrency`, `Boundary` 디렉터리와 `.ts`를
   만든다.
2. 각 media root `.ts`에 일반 SQL로 확정 가능한 suite만 연결한다.
3. `TEST_MATRIX.md`에 모든 case의 ID, media, source, oracle, 상태를 기록한다.
4. `README.md`의 source 수와 SourceOnly 상태를 갱신한다.

### Phase B: portable single-session P0

다음 순서로 먼저 작성한다.

1. statement/savepoint/transaction rollback
2. CREATE TABLE PK/UK, constraint lifecycle, duplicate build abort
3. indexed-column dependency, rename, multi-index cascade
4. pruning 0/1/N/all, `FOR UPDATE`, statistics continuity
5. 64/65 index count와 large deterministic data
6. unsupported option/type/media/DDL combination 전체 matrix

### Phase C: verified multi-session source

1. 구버전과 현재 NATC tree에서 canonical THREAD/connection idiom을 찾는다.
2. unique wait commit/rollback을 최소 two-client case로 작성한다.
3. 서로 다른 partition의 concurrent DML을 작성한다.
4. timing-only synchronization이 없는지 정적 리뷰한다.
5. active cursor DDL은 최종 lock 계약이 확인될 때 연결한다.

### Phase D: 서버 사용 가능 이후

1. 가장 작은 Disk/Memory create smoke부터 실행한다.
2. 실제 `.out`에서 catalog column, error code, plan node를 검토한다.
3. intentional output만 `caseName_A4_64.lst`로 설치한다.
4. 동일 명령을 다시 실행하여 PASS를 확인한다.
5. P0, P1, Boundary, Concurrency 순으로 범위를 넓힌다.
6. Lifecycle/FIT/Compatibility/Replication/AdminTool lane은 각 환경에서 별도
   suite로 실행한다.

## 9. source-only 정적 완료 조건

서버 없이 진행하는 이번 보강은 다음 조건을 만족하면 완료로 기록한다.

- 모든 신규 `.tc`에 description, project ID, `DEF MAIN()`이 있다.
- 네 sector가 INITIALIZATION부터 FINALIZATION까지 정확한 순서로 존재한다.
- 모든 신규 `.ts` 참조가 실제 `.tc`에 상대 경로로 연결된다.
- root suite에는 일반 SQL source만 연결된다.
- Disk와 Memory object 이름이 충돌하지 않는다.
- visible multi-row result에 deterministic `ORDER BY`가 있다.
- cleanup은 case가 생성한 object만 대상으로 한다.
- negative case가 error 다음의 data/catalog 불변성까지 확인한다.
- native success oracle에 `$GIT_*` physical row 조회가 없다.
- old-style directive, absolute path, shell wrapper, guessed plan/error text가 없다.
- `.lst`가 없다는 이유로 Runnable/Pass로 표시하지 않고 모두 SourceOnly로 둔다.
- server-dependent case는 Planned 또는 EnvironmentBlocked로 명확히 구분한다.

## 10. 최종 release 완료 조건

source 보강만으로 V1 테스트가 완료된 것은 아니다. 최종 완료에는 다음이 모두
필요하다.

- 모든 P0/P1/Boundary SQL case의 reviewed tagged `.lst`
- 같은 target command의 두 번째 PASS
- Memory clean/abnormal restart와 startup rebuild 검증
- Disk clean restart, crash redo/undo, CREATE/REBUILD/DROP recovery 검증
- unique concurrency commit/rollback과 active cursor 경합 검증
- 64개 성공, 65번째 거부, 실패 뒤 persistent 변경 없음 확인
- legacy hidden upgrade compatibility
- version-gated replication DDL과 base-row apply 검증
- DROP USER/TBS, export/import, backup/restore 등 별도 admin/tool lane
- performance/capacity baseline 및 장시간 stress

따라서 이번 작업의 산출물은 **V1 source coverage 보강**이며, 서버가 준비된 뒤
oracle 생성과 lifecycle/integration 실행을 거쳐야 **V1 release coverage 완료**로
판정한다.

## 11. 예상 산출물

portable source 범위를 모두 구현하면 media별 약 35~45개 case가 추가되어 전체
SQL prototype은 약 110~130개가 된다. 정확한 수는 하나의 case에 지나치게 많은
독립 실패 지점을 넣지 않는 원칙과 SQL 문법 확인 결과에 따라 조정한다.

산출물은 다음과 같다.

- 신규/갱신 `.tc`, `.ts`
- 갱신된 `README.md`, `TEST_MATRIX.md`, `LEGACY_COVERAGE.md`
- lifecycle/deferred lane의 환경 계약 checklist
- 정적 참조 검사 결과
- 나중에 생성할 `.lst` manifest

이번 단계에서는 `.lst`, 실제 PASS 기록, 추측한 expected error/plan output을
산출물로 만들지 않는다.
