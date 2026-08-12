# 네이티브 글로벌 인덱스 — 시나리오와 기대 결과

이 문서는 `.lst` 를 만들 때 "무엇이 정답인지"를 미리 확정해 둔 것이다.
서버를 띄우면 케이스를 돌리고 출력을 여기와 대조만 하면 되도록,
기대 결과를 전부 altidev4 소스에서 유도해 두었다.

추측으로 `.lst` 를 만들지 않는다. 여기 근거가 없는 항목은 실행 결과를
보고 판단한 뒤 이 문서를 먼저 갱신한다.

근거 표기는 `altidev4_new` 저장소 기준이다.

---

## 1. 지금 상태

- `.tc` 37 개, `.i` 4 개, `.lst` **37 개**. **전 케이스 PASS**
  (PASS 37 / FAIL 0 / FATAL 0 / ERROR 0, 두 번 연속).
- `.lst` 는 전부 실제 실행 결과다. 만들기 전에 두 번 돌려 출력이 바이트
  단위로 같은 것을 확인했다 — 비결정 요소는 하나 있었고(이름 없는 PK 가
  받는 `__SYS_IDX_ID_<증가 번호>`) 제약에 이름을 주어 없앴다.
- 오프라인 검사(`tools/lint-tc.py`)도 통과한다. 다만 그것은 **SQL 을
  파싱하지 않는다** — 아래 §11 의 문법 사실들은 전부 실행해야 드러났다.

### 실행 요건

| 항목 | 값 |
|---|---|
| 환경변수 | `LANG=C`, `OS_NAME=linux`, `ATAF_HOME=STAF_HOME=~/work/ataf/ataf_home`, `STAF_INSTANCE_NAME=STAF_$LOGNAME`, `ATAF_TEST_CASE=ATC_HOME=~/work/natc`, `ATC_WORK=$ATAF_TEST_RESULT/work` |
| 데몬 | `ataf start` |
| 서버 | 미리 떠 있어야 한다. `atsclnt` 는 서버를 만들지도 띄우지도 않는다 |
| 포트 | `~/work/natc/conf/server.conf` 의 `%PORT_NO0` 치환값. `ALTIBASE_PORT_NO` 는 무시된다 |
| 문자셋 | server.conf 가 `KO16KSC5601` 을 강제한다. **UTF8 인스턴스로는 못 붙는다** |
| 세션 강제 설정 | `ALTIBASE___DISPLAY_PLAN_FOR_NATC=1`, `ALTIBASE___DPATH_INSERT_ENABLE=1` |

`ALTIBASE___DISPLAY_PLAN_FOR_NATC=1` 때문에 플랜의 COST 가
`COST: BLOCKED` 로 나온다(`src/qp/qmn/qmn.cpp:1247-1257`).
`GLOBAL-INDEX` 와 `ACCESS: n` 은 그대로다.

**단일 케이스 실행**: `atsclnt <경로>/<case>.tc`
결과는 케이스 옆의 `<case>_A4_64.out`, 로그는 `$ATC_WORK/log/`.

---

## 2. 판별의 기준선

모든 카탈로그 검사가 이 세 값에 기댄다.

| 무엇 | 네이티브 글로벌 | 로컬 | 구버전(숨김 테이블) |
|---|---|---|---|
| `SYS_PART_INDICES_.PARTITION_TYPE` | **101** | 파티션드 값 | 100 |
| `SYS_INDICES_.IS_PARTITIONED` | `F` | `T` | `F` |
| `SYS_INDICES_.INDEX_TABLE_ID` | **0** | — | 0 이 아님 |
| `SYS_INDEX_PARTITIONS_` 행 | **0 개** | 파티션 수만큼 | 0 개 |
| `$GIT_` / `$GIK_` / `$GIR_` 객체 | **없음** | 없음 | 있음 |

근거: `src/qp/include/qcmTableInfo.h:108-110`
(`QCM_GLOBAL_NATIVE_NONE_PARTITIONED_INDEX = 101`),
`src/qp/include/qmsParseTree.h:1561`.

플랜 표기는 `, GLOBAL-INDEX` 하나뿐이다(`src/qp/qmn/qmnScan.cpp:880-884`).
전체 형태:

```
SCAN ( TABLE: SYS.T, INDEX: SYS.I, GLOBAL-INDEX, [A-Z ]*SCAN, ACCESS: n, COST: ... )
```

프로퍼티는 `MEM_GLOBAL_INDEX_ENABLE`
(`src/id/idp/idpDescResource.cpp:8585`). 런타임 변경 가능하지만
**비영속**이다 — 재기동하면 파일 값(기본 0)으로 돌아간다. 그래서 각
케이스가 자기 PREPARE 에서 켠다.

---

## 3. 살아 있는 거부

`.tc` 는 에러 문자열을 하드코딩하지 않는다. 아래는 `.lst` 를 검토할 때
"이 코드가 나와야 맞다"를 판단하는 표다.

| 코드 | 조건 | 근거 |
|---|---|---|
| `ERR-314AB` | 매체 불일치 — 논리 테이블/파티션이 메모리·디스크·휘발성으로 섞임 | `qdx.cpp:10464, 10541-10543` |
| `ERR-313D0` | 프로퍼티 off 상태의 메모리 파티션드 non-partitioned index | `qdx.cpp:10537-10539` |
| `ERR-314AC` | 인덱스 비트 예산 초과: 최대로컬수 + 글로벌수 + 1 > 64 | `qdx.cpp:2072` |
| `ERR-314AD` | DIRECT KEY / PERSISTENT / 압축 키 컬럼 | `qdx.cpp:2038, 2041, 2048` |
| `ERR-314B4` | 복제 — PK 가 네이티브 글로벌인 테이블만 | `rpcValidate.cpp`, `rpdMeta.cpp` |

### V2 가 걷어낸 거부 — 이제 **성공**해야 한다

메시지는 `.msg` 에 남아 있지만 raise 사이트가 **하나도 없다**(고아 메시지).

| 옛 코드 | 무엇이 열렸나 | 담당 |
|---|---|---|
| `ERR-314AE` | SPLIT / MERGE / ADD HASH / COALESCE | V2 J07 |
| `ERR-314AF` | ADD / DROP / MODIFY / REORGANIZE COLUMN | V2 J08 |
| `ERR-314B0` | TRUNCATE TABLE, CREATE TABLE ... FROM TABLE SCHEMA | V2 J05 |
| `ERR-314B1` | 글로벌 PK/UK 를 참조하는 FK | V2 J04 |
| `ERR-314B2` | ALL INDEX ENABLE / DISABLE | V2 J13 |
| `ERR-314B3` | 복제 전면 거부 (PK 조건만 ERR-314B4 로 남음) | V2 J18 |

`.lst` 에 이 코드들이 나오면 회귀다.

---

## 4. 플랜 게이트가 닫히는 조합

`qmoPartition::isUsableNativeGlobalIndex` 가 아예 후보를 내지 않는
조합이 있다. **이 경우 플랜에 `GLOBAL-INDEX` 가 없는 것이 정답이다.**
인덱스는 살아 있고 유일성도 계속 강제된다 — 스캔 플랜만 빠진다.

| 조건 | 근거 |
|---|---|
| (a) memory variable 컬럼의 `colSpace` 가 논리 테이블과 파티션 사이에서 다름. **키 컬럼이 아니어도** 테이블에 하나라도 있으면 닫힌다 | `qmoPartition.cpp:3160-3186` |
| (b) 파티션 프루닝이 일어났고 **인덱스 키 컬럼**에 variable 이 있음 | 같은 파일 `:3205-3225` |
| (c) PARALLEL 힌트 | `sql-level-check.sh:291` (B6) 이 실증 |

(a) 는 실질적으로 "파티션이 서로 다른 메모리 테이블스페이스 + varchar"
를 뜻한다. 이 조합에서 `index` 힌트를 주고 차집합을 비교하면
**풀스캔 minus 풀스캔** 이 되어 항상 0 행 — 아무것도 시험하지 않으면서
통과한다. 그래서 헬퍼를 둘로 나눴다:

- `CHECK_INDEX_SCAN_OPEN_GATE` — 플랜을 먼저 남겨 힌트가 먹었음을
  `.lst` 에 박고 나서 차집합을 비교한다
- `CHECK_INDEX_SCAN_CLOSED_GATE` — 플랜에 `GLOBAL-INDEX` 가 **없음**을
  기록하고, 정합성은 풀스캔 집계와 유니크 제약으로만 판정한다

`datatype/variableColumn.tc` 가 이 두 갈래를 대조로 보여 준다.

---

## 5. V1 코드 리뷰 결함 → 케이스

| 결함 | 케이스 | 기대 |
|---|---|---|
| **P0-1** in-place UPDATE 가 옛 키를 안 지움 | `dml/updateInPlace.tc` **(신규)** | 차집합 0 행. 비워진 값의 재삽입이 **성공**. 살아 있는 값의 재삽입은 실패 |
| **P0-2** 판별자 101 을 로컬로 오분류 | `ddl/alterTableColumn.tc`, `partition/addTruncatePartition.tc` | 컬럼 DDL·TRUNCATE TABLE 전부 성공 |
| **P0-2 (세 번째 사례)** `ALTER INDEX ... REBUILD` | `ddl/alterIndexRebuild.tc` **(신규)** | 성공. 한때 서버를 죽였다 — §7 |
| **P0-3** 글로벌 PK 를 참조하는 FK | `ddl/constraint.tc` | V2 J04 이후 **성공**. 부모 키 조회가 논리 테이블 인덱스로 라우팅 |
| **P0-4** 디스크 파티션드 + 비파티션키 PK | `ddl/diskPartitionedTable.tc` **(신규)** | 프로퍼티 on/off 출력이 **동일**. 판별자 100, `$GIT_` 있음 |
| **P0-5** SERIALIZABLE | `dml/isolation.tc` **(신규)** | 세 격리 수준의 결과가 서로 같다 |
| **P1-1** ALL INDEX / TBS ONLINE | `ddl/allIndexAndTablespace.tc` **(신규)** | 둘 다 **성공**. V2 J13/J14 가 `ERR-314B2` 를 걷었다 — 그 파일의 기대를 뒤집어야 한다 |
| **P1-2** holdable 커서 + TRANSACTIONAL_DDL | — | 다중 세션 필요. §8 |
| **P1-3** 논리 테이블만 SKIP TBS | — | V1 에서 재현 불가로 남음. V2 J15 가 재시도 |
| **P1-4** 프로퍼티 런타임 재판정 | `regress/propertyRuntimeChange.tc` **(신규)** | 껐어도 기존 인덱스는 조회·DML·유일성 전부 그대로. 새로 만드는 것만 `ERR-313D0` |
| **P1-5** 프루닝 + variable + 상이 TBS | `datatype/variableColumn.tc` **(재설계)** | 플랜에 `GLOBAL-INDEX` 없음이 정답 |

---

## 6. V2 J01–J21 → 케이스

V2 는 **J01–J21 전부 완료**다. 아래 "전환 감시 지점" 은 이미 전환됐다는 뜻이므로,
해당 케이스의 기대를 거부에서 성공으로 뒤집어야 한다.

| Job | 범위 | 케이스 | 비고 |
|---|---|---|---|
| J03 | HASH/LIST 프루닝, rollbackable DDL | `partition/`, `scan/` | 기존 케이스가 덮음 |
| J04 | FK 라우팅 | `ddl/constraint.tc` | 기대가 거부→성공으로 바뀜 |
| J05 | TRUNCATE TABLE, FROM TABLE SCHEMA | `partition/addTruncatePartition.tc`, `ddl/createTableFromSchema.tc` **(신규)** | |
| J06 | 미커밋 로우 읽기 | — | TRANSACTIONAL_DDL 계약이 필요. §8 |
| J07 | SPLIT/MERGE/ADD HASH/COALESCE | `partition/splitMergeReplace.tc` **(수정)**, `coalesceAndBoundary.tc` | 전부 성공 |
| J08 | 컬럼 DDL 4종 | `ddl/alterTableColumn.tc` | 전부 성공 |
| J09 | 쓰기 동시성 | — | 다중 세션. §8 |
| J10 | 크래시 주입 | — | FIT 는 이 스위트 범위 밖. §8 |
| J11 | holdable 커서 회귀 | — | 다중 세션. §8 |
| J12 | SM 계측 확증 | — | 계측은 SQL 로 볼 수 없다 |
| J13 | 런타임 재구성 · ALL INDEX | `ddl/allIndexAndTablespace.tc` | **전환 감시 지점** — 기대가 `ERR-314B2` 에서 성공으로 바뀐다 |
| J14 | TBS ONLINE · restore | `ddl/allIndexAndTablespace.tc` | 동 |
| J15 | P1-3 사분면 | — | 재현되면 케이스 추가 |
| J16–J18 | 복제 | `repl/replicationReject.tc` **(신규)** | **전환 감시 지점** — J18 이후 `ERR-314B3` 이 사라진다. 실동작은 2 인스턴스 필요 |
| J19 | purge fast-path | `partition/dropPartition.tc` | 성능 변경이므로 **동작은 그대로여야** 한다 |
| J20 | 측정 | — | 성능은 이 스위트 범위 밖 |

---

## 7. 한때 서버를 죽이던 케이스 (고쳐짐)

`ddl/alterIndexRebuild.tc` 가 겨냥한 결함이다. **고쳐졌고** 이 케이스도
`ddl/ddl.ts` 에 들어가 있다. 아래는 무엇이 문제였는지의 기록이다.

```
qdx.cpp:5001, :5046   executeAlterRebuild 가 판별자를 옛 이분법으로 본다:
                        != QCM_NONE_PARTITIONED_INDEX
                      네이티브 글로벌은 101 이므로 "로컬 파티션드 인덱스"
                      가지로 잘못 들어간다.
qdx.cpp:5073          IDE_ASSERT( sLocalIndex != NULL );
                      네이티브 글로벌은 파티션별 물리 인덱스를 만들지
                      않으므로 파티션 indices[] 탐색이 반드시 실패한다.
qdx.cpp:2869          validateAlterRebuild 에 게이트가 없다.
```

`IDE_ASSERT` 는 `IDE_ERROR` 와 달리 `__ERROR_VALIDATION_LEVEL` 과 무관하게
**릴리스 빌드에서도 프로세스를 종료**한다.

같은 오분류의 앞선 두 사례는 이미 고쳐져 있다 —
`qdx.cpp:5905`, `qdbCommon.cpp:1638`:

```c
sIsNativeGlobalIndex =
    ( indexPartitionType == QCM_GLOBAL_NATIVE_NONE_PARTITIONED_INDEX )
    ? ID_TRUE : ID_FALSE;
```

**수정 내용**: `qdx::executeAlterRebuild` 가 판별자 101 을 먼저 걸러
`qdbAlter::recreateNativeGlobalIndexes` 로 보낸다 — 재구성 DDL 이 쓰는 것과
같은 DROP INDEX + CREATE INDEX 기계이고, 사용자가 이름을 댄 인덱스 하나만
대상이다. 전 파티션 X 잠금도 함께 잡는다.

**AGING 은 결함이 아니었다.** `qdx::validateAgingIndex` 가 파티션 목록의
디스크 파티션 수를 세어 0 이면 거부한다(`qdx.cpp:3188`). 메모리 전용인
네이티브 글로벌은 항상 0 이므로 `executeAgingIndex` 의 이분법에는 닿지
않는다. 저장 속성 계열(SEG ATTR / SEG STO / ALLOC EXTENT)도 마찬가지로
`smiIsDiskTable` 게이트가 이분법보다 앞에 있다.

**같은 계열의 또 다른 자리**가 `DROP TABLESPACE` 에 있었다. 인덱스만 다른
테이블스페이스에 둔 경우로, `qcmTableSpace::findIndexInfoListInTBS` 가
`INDEX_TABLE_ID = 0` 을 메타 손상으로 읽어 ERR-31015 를 냈다. 그것을 고치면
`qdtDrop::execute` 가 없는 인덱스 테이블을 tableID 0 으로 조회해 ERR-31011,
그것까지 고치면 `qdd::dropIndexPartitions` 의 같은 `IDE_ASSERT` 에 닿았다.
셋 다 고쳤다. `ddl/dropCascade.tc` 가 이 경로를 덮는다.

---

## 8. 이 스위트로 다룰 수 없는 것

`~/work/natc/docs/TC_GUIDE.md` 가 `reference-gated` / `avoid` 로 묶은
것들이다. 계약 없이 만들지 않는다.

| 항목 | 이유 | 어디서 다루나 |
|---|---|---|
| 다중 세션 동시성 | `THREAD`/`JOIN`, `DECLARE CLIENT` 가 reference-gated | `write-concurrency-check.sh` (V2 J09) |
| 크래시 주입 | `fitclient`, `##fail` 이 avoid | `crash-injection-check.sh` (V2 J10) |
| 서버 재기동 | lifecycle `std*` 헬퍼가 reference-gated | `sm-matrix-check.sh` 의 restart 절 |
| 이중화 실동작 | 인스턴스 2 개 필요 | V2 J16 하네스 |
| 성능 측정 | 출력이 비결정적 | `git-vs-native-bench.sh` (V2 J20) |
| SM 내부 계측 | SQL 로 볼 수 없다 | SM 단위 스위트 (V2 J12) |

`deferred/README` 에도 같은 취지가 적혀 있다.

---

## 9. `.lst` 만드는 순서

서버가 준비되면 아래 순서로 돌린다. 앞 단계가 깨끗해야 다음으로 간다.

1. **오프라인 검사** — `python3 tools/lint-tc.py` 가 0 을 반환해야 한다.
2. **가장 단순한 것부터** — `meta/nativeCatalog.tc` 하나만 `atsclnt` 로
   돌려 INCLUDE 해석과 접속이 되는지 본다.
3. **거부 케이스** — `ddl/createIndexError.tc`. §3 의 표와 대조해 실제
   에러 코드를 확인하고, 다르면 이 문서를 먼저 고친다.
4. **판별자** — `meta/`, `ddl/createIndex.tc`. §2 의 다섯 값 확인.
5. **정합성** — `unique/`, `dml/`, `scan/`.
6. **게이트** — `datatype/variableColumn.tc`. §4 대로 열림/닫힘이
   갈리는지 확인. 여기가 가장 틀리기 쉽다.
7. **파티션 DDL** — `partition/`.
8. **회귀** — `regress/`, `ddl/diskPartitionedTable.tc`.
9. **느린 것** — `ddl/indexBudget.tc` (인덱스 수십 개를 만든다).
10. 각 단계에서 `.out` 을 **눈으로 읽고** 의도한 결과일 때만
    `<case>_A4_64.lst` 로 복사한다.

`ddl/alterIndexRebuild.tc` 는 §7 의 결함이 고쳐진 뒤에.

---

## 10. 남은 것

- **프로젝트 ID 배정.** 지금 디렉터리는 `TC/Server/sm4/Project4/NativeGlobalIndexClaude`
  이고 `Project4` 도 임의다(natc git 에서 통째로 untracked). ID 가 정해지면
  디렉터리명과 각 `.tc` 헤더의 `# Project ID = Native Global Index (memory)`
  를 함께 바꾼다.
- **KO16KSC5601 인스턴스.** `.lst` 생성의 전제다.
- **`add partition ... values default`** (`partition/addTruncatePartition.tc:145`)
  — 기본 파티션을 나중에 추가하는 것이 허용되는지 확인하지 못했다.
  실행 결과로 판단할 것.
- **isql `desc` / aexport 출력** — `deferred/README` 참조. 형태가
  확정되면 추가한다.

---

## 11. 실행해서야 알게 된 문법 사실

오프라인 검사는 SQL 을 파싱하지 못한다. 아래는 전부 케이스를 실제로 돌려
드러난 것이고, `qcply.y` 에 대조해 확정했다. `tools/lint-tc.py` 에 규칙으로
넣어 두었다.

| 사실 | 근거 |
|---|---|
| `.tc` 의 주석은 `#` 뿐이다. 문장 수준의 `/* ... */` 는 **파서를 깨뜨린다** (`PARSE ERROR: Tokens is '/'`). SQL 힌트 `/*+ ... */` 만 예외 | `tableLock.tc` 가 이것 때문에 ERROR 였다 |
| 호스트 변수는 `var v1 integer;` 로 **선언**해야 한다 | 안 하면 ERR-91007 |
| `prepare` 는 준비만 하는 것이 아니라 **그 자리에서 실행하고 결과를 낸다.** 별도 `execute` 문은 없다 | ERR-91010. 구버전 `design/host_var.tc` 의 `.lst` |
| 호스트 변수를 쓰는 문장은 `prepare` 로 내야 한다. 평범한 `select` 로는 바인드가 안 붙는다 | ERR-31248 |
| `LOCK TABLE` 은 자동 커밋 상태에서 못 쓴다 | ERR-41057 |
| `V$LOCK` 은 `TABLE_ID` 가 아니라 **`TABLE_OID`** 를 들고 있다 | ERR-31058 |
| savepoint 는 자동 커밋 상태에서 즉시 사라진다 | ERR-11016 |
| 파생 테이블의 `ORDER BY` 는 표현식 이름으로 참조할 수 없다. **위치**로 준다 | ERR-31058 |
| `ADD PARTITION ... VALUES DEFAULT` 는 **지원되지 않는다** | `add_partition_spec` 의 그 가지가 주석 처리 + `/* todo */` |
| 리스트 파티션드 테이블에는 **`ADD PARTITION` 자체를 쓸 수 없다** (`VALUES` 뒤에 `LESS THAN` 만 온다) | parse error |
| `PERSISTENT` 는 `ALTER INDEX` 전용이고 `CREATE INDEX` 옵션이 아니다 | `alter_index_set_clause` |
| 압축은 컬럼 키워드가 아니라 테이블 수준 `COMPRESS ( col )` 절이다 | ERR-31001 |
| 복제 아이템이 여럿이면 각각 `FROM ~ TO` 를 온전히 적는다 | parse error |
| 이름 없는 PK 는 `__SYS_IDX_ID_<전역 증가 번호>` 를 받아 **출력이 비결정적**이 된다. 제약에 이름을 줄 것 | 두 실행의 `desc` 출력 차이 |

## 12. 이 스위트가 찾은 결함

| 결함 | 어디서 | 처리 |
|---|---|---|
| 함수 기반 인덱스가 **서버를 내렸다** (`CREATE INDEX ON t(식)`, 메모리 파티션드 + 프로퍼티 ON) | `datatype/functionIndex.tc` | `ERR-314AD` 로 거부. `sql-level-check.sh` I92~I99 |

프로젝트 회귀 스크립트에는 함수 기반 인덱스가 **0 건**이었다. 그래서 V1 코드
리뷰와 V2 의 21 잡을 모두 통과했다. 이 스위트를 살린 값어치가 그것이다.
