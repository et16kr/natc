# 결함 보고 — `FROM TABLE SCHEMA` 가 게이트 둘을 지나친다

- 발견: 2026-08-20
- 방법: `NativeGlobalIndex-TC-Method.md` **수-1 형제 훑기**
- 감시자: `TC/.../NativeGlobalIndexClaude/Memory/Create/createPathSweep.tc` (D 절)
          `TC/.../NativeGlobalIndexClaude/Disk/DDL/copySchemaGate.tc` (A·B·C 절)
- 상태: **결함 셋 수정 완료 / 양쪽 매체 검증 완료.** 후속 감사도 닫았고,
  스위트는 정식 실행기에서 **GREEN 273/273** 이다 (2026-08-21).

---

## 0. 이 문서가 다루는 셋

| # | 무엇 | 어디 | 상태 |
|---|---|---|---|
| D1 | 프로퍼티 게이트를 스키마 복사가 지나친다 | `qdbCopySwap::validateCreateTableFromTableSchema` | 수정 · 검증 |
| D2 | **D1 의 수정이 전 디스크 복사를 통째로 막았다** | 같은 함수 (매체 개수를 잘못 셈) | 수정 · 검증 |
| D3 | `$GIT_` 은퇴 게이트(V4 D-2)도 같은 경로가 지나친다 | 같은 함수 | 수정 · 검증 |

셋 다 같은 뿌리다 — **이 경로는 원본의 인덱스를 그대로 복제하면서
"지금 만들면 무엇이 서는가" 를 한 번도 묻지 않았다.**

---

## 1. D1 — 한 문장

`MEM_GLOBAL_INDEX_ENABLE = 0`(또는 `DISK_` = 0) 인 상태에서
**`CREATE TABLE ... FROM TABLE SCHEMA ... USING PREFIX ...` 는
네이티브 글로벌 인덱스를 만들어 준다.** 같은 인덱스를 `CREATE INDEX` ·
`ADD CONSTRAINT` · `CREATE TABLE ... PRIMARY KEY` 로 만들려 하면 전부
거절되는데, 이 경로만 통과한다.

### 재현

```sql
ALTER SYSTEM SET MEM_GLOBAL_INDEX_ENABLE = 1;

CREATE TABLE VG_SRC ( P INTEGER, K INTEGER, V VARCHAR(16) )
PARTITION BY RANGE ( P )
( PARTITION P1 VALUES LESS THAN (10), PARTITION PD VALUES DEFAULT )
TABLESPACE SYS_TBS_MEM_DATA;

CREATE UNIQUE INDEX VG_SRC_U ON VG_SRC ( K ) TABLESPACE SYS_TBS_MEM_DATA;

ALTER SYSTEM SET MEM_GLOBAL_INDEX_ENABLE = 0;   -- ★ 게이트를 닫는다

CREATE TABLE VG_COPY FROM TABLE SCHEMA VG_SRC USING PREFIX ZZ;
--> 수정 전: Create success.   (ZZVG_SRC_U / NATIVE / PARTITION_TYPE 101)
--> 수정 후: [ERR-313D0]       (VG_COPY 자체가 생성되지 않는다)
```

`DISK_GLOBAL_INDEX_ENABLE = 0` 에서도 같았다.

### 카탈로그 흔적이 아니라 **작동하는 인덱스**였다

```sql
INSERT INTO VG_COPY VALUES (1,  500, 'a');   --> 1 row inserted.
INSERT INTO VG_COPY VALUES (21, 500, 'b');   --> [ERR-11058]
```

두 행은 서로 다른 파티션(P1 과 PD)에 들어간다. 파티션 간 중복이 거절된다는
것은 하나의 트리가 파티션을 가로질러 서 있다는 뜻이고, 로컬 인덱스는 그렇게
하지 못한다. 즉 게이트가 닫힌 인스턴스에 **기능하는 네이티브 글로벌
인덱스**가 존재했다.

### 형제 대조

| 경로 | 검증기 호출 | 프로퍼티 0 에서 |
|---|---|---|
| `CREATE INDEX` | `qdx::validateIndexRestriction` | 거절 `ERR-313D0` |
| `ALTER TABLE ADD CONSTRAINT UNIQUE` | `qdbCommon::createConstrPrimaryUnique` | 거절 `ERR-31415` |
| `CREATE TABLE (... PRIMARY KEY ...)` | `qdbCommon::createConstrPrimaryUnique` | 거절 `ERR-31415` |
| **`CREATE TABLE ... FROM TABLE SCHEMA`** | **없었다** | **Create success → 수정 후 `ERR-313D0`** |

### 좌표

`qdx::validateNativeGlobalIndex` 를 부르는 자리는 소스 전체에서 셋뿐이다.

```
src/qp/qdx/qdx.cpp:3454       qdx::validateAlterRebuild
src/qp/qdx/qdx.cpp:11362      qdx::validateIndexRestriction
src/qp/qdb/qdbCommon.cpp:6931 qdbCommon::createConstrPrimaryUnique
```

`FROM TABLE SCHEMA` 는 `src/qp/qdb/qdbCopySwap.cpp` 가 처리하고, 그 파일에는
그 호출이 없었다.

### 수정

`qdbCopySwap::validateCreateTableFromTableSchema` 에 형제와 같은 판정식을
넣었다 — 원본이 네이티브 글로벌 인덱스를 갖고 있으면
`snapshotGlobalIndexEnable()` 로 프로퍼티를 굳히고,
`getTableTypeCountInPartInfoList()` 로 매체를 세고,
`qdx::isNativeGlobalIndexMedia()` 로 판정한다. 닫혀 있으면 `ERR-313D0`.

**대안 판정**: 복제를 허용하되 로컬 인덱스로 낮춰 만드는 것도 가능한
설계다. 다만 "스키마 복제 결과가 원본과 다르다" 가 되므로 복제의 계약을
바꾸는 결정이고, 문서로 남겨야 한다. 여기서는 고르지 않았다.

---

## 2. D2 — **그 수정이 전 디스크 복사를 막았다** (회귀)

D1 의 수정(커밋 `5ed1f3574`)은 매체 개수를 이렇게 셌다.

```c
UInt sSrcTableType = 0;                      /* ← 여기 */
qdbCommon::getTableTypeCountInPartInfoList( & sSrcTableType, ... );
```

`getTableTypeCountInPartInfoList` 의 **첫 인자는 입력**이다. 논리 테이블의
매체를 담아 보내면 그 함수가 개수에 더한다(그 함수의 1번). 형제 호출부
둘(`qdbCommon.cpp:6730`, `qdbCommon.cpp:17810`)은 전부
`tableFlag & SMI_TABLE_TYPE_MASK` 를 넣는다.

0 을 넣으면 `(0 & SMI_TABLE_TYPE_MASK)` 가 `SMI_TABLE_META`(0x0)이고, 그
함수는 META 를 **메모리로 센다**(`smiDef.h:1202`).

| 원본 | 세어진 값 | `isNativeGlobalIndexMedia` |
|---|---|---|
| 전 메모리 | mem = 1 + N, disk = 0 | 전 메모리 → 프로퍼티대로. **우연히 맞음** |
| 전 디스크 | mem = **1**, disk = N | **hybrid** → 항상 `ID_FALSE` |

즉 전 디스크 원본은 `DISK_GLOBAL_INDEX_ENABLE = 1` 이어도 복사가 거절됐다.

### 실측 (2026-08-20, 수정 전)

```
메모리 게이트 ON  -> Create success        (옳음)
메모리 게이트 OFF -> ERR-313D0             (옳음)
디스크 게이트 ON  -> ERR-313D0   ★ 회귀    (성공해야 한다)
디스크 게이트 OFF -> ERR-313D0             (옳은 답, 틀린 이유)
```

### 왜 잡히지 않았나 — 커버리지 공백

`CREATE TABLE ... FROM TABLE SCHEMA` 를 재는 케이스가 이 트리에 셋 있었고
(`createPathSweep` · `createTableFromSchema` · `createIndexError`)
**셋 다 메모리**였다. 디스크 쪽에는 하나도 없었다. 그래서 스위트가 전부
초록인 채로 디스크 경로가 죽어 있었다.

`Disk/DDL/copySchemaGate.tc` 의 **A 절**이 그 감시자다.

### 수정

```c
UInt sSrcTableType = sTableInfo->tableFlag & SMI_TABLE_TYPE_MASK;
```

---

## 3. D3 — `$GIT_` 은퇴 게이트도 같은 경로가 지나친다

V4 D-2(GR-14 3단계)는 은퇴한 `$GIT_` 숨김 인덱스 테이블의 **생성**을 닫았다.
`idpDescResource.cpp` 의 `__DISK_GLOBAL_INDEX_LEGACY_CREATE` 주석은 그 게이트가
**네 자리**라고 회계한다 — `qdx::validate`(CREATE INDEX),
`qdn::validateConstraints` 두 자리(PK/UK), `qdx::validateAlterRebuild`.

그런데 `qdbCopySwap::createConstraintAndIndexFromInfo` 는 원본 인덱스의
판별자가 `QCM_NONE_PARTITIONED_INDEX`(100)이면 `qdx::createIndexTable` 로
**새 숨김 인덱스 테이블을 짓는다.** 그 자리에 `checkIndexTableRetired` 가
없었다.

### 재현 (수정 전, 2026-08-20 실측)

```sql
ALTER SYSTEM SET DISK_GLOBAL_INDEX_ENABLE = 0;
ALTER SYSTEM SET __DISK_GLOBAL_INDEX_LEGACY_CREATE = 1;
CREATE TABLE ZG_SRC (...) PARTITION BY RANGE (P) (...) TABLESPACE SYS_TBS_DISK_DATA;
CREATE INDEX ZG_SRC_G ON ZG_SRC (K) TABLESPACE SYS_TBS_DISK_DATA;   -- $GIT_ 하나

ALTER SYSTEM SET __DISK_GLOBAL_INDEX_LEGACY_CREATE = 0;             -- ★ 은퇴시킨다

CREATE INDEX ZG_SRC_G2 ON ZG_SRC (V) ...;   --> [ERR-314B6]  거절
CREATE TABLE ZG_CPY FROM TABLE SCHEMA ZG_SRC USING PREFIX FF;
                                            --> Create success.  ★ 결함
```

```
$GIT_ 테이블 수 : 1 -> 2
새로 생긴 것    : $GIT_FFZG_SRC_G   (INDEX_TABLE_ID 320, 새 INDEX_ID)
```

### TRUNCATE · 컬럼 DDL 과 무엇이 다른가

`qdbCommon::createIndexFromInfo` 도 `qdx::createIndexTable` 을 부른다
(TRUNCATE TABLE · ADD/DROP COLUMN · 테이블 재생성). 그러나 그것은 **같은
인덱스를 다시 세우는 것**이다 — `INDEX_ID` 도 이름도 그대로다. 은퇴 문서가
"이미 만들어진 인덱스는 한 자리도 건드리지 않는다" 고 한 그 범주다.

스키마 복사는 다르다. **새 테이블 위에 새 `INDEX_ID` 로 인덱스가 하나 더
생긴다.** 데이터베이스 안의 `$GIT_` 객체 수가 늘어난다. 그것이 D-2 가 닫은
일이다.

### 수정

같은 함수에 두 번째 게이트를 넣었다. 원본에 판별자 100 인 인덱스가 있으면
(= `mSourcePartTable->mIndexTableList` 가 비어 있지 않으면)
`qdx::checkIndexTableRetired` 를 부른다. 근거는 리빌드가 든 것 그대로다 —
**복사가 새로 만드는 인덱스가 어느 구현으로 서는지는 "지금 CREATE 하면
무엇이 서는가" 와 같아야 한다**(`qdx::validateAlterRebuild` 의 주석).

`__DISK_GLOBAL_INDEX_LEGACY_CREATE = 1` 이면 종전대로 복사되므로 하위 호환
그물은 그대로 잴 수 있다.

---

## 4. 수정 후 실측 (2026-08-20, 재빌드 · 재기동 후)

| 매체 | 상태 | 결과 |
|---|---|---|
| 메모리 | `MEM_ = 1` | Create success, 복사본 판별자 101 |
| 메모리 | `MEM_ = 0` | `ERR-313D0`, 테이블 생성 안 됨 |
| 디스크 | `DISK_ = 1` | Create success, 복사본 판별자 101 |
| 디스크 | `DISK_ = 0` | `ERR-313D0`, 테이블 생성 안 됨 |
| 디스크 `$GIT_` | `LEGACY_CREATE = 1` | Create success, `$GIT_` 이 새로 생김 (종전 동작) |
| 디스크 `$GIT_` | `LEGACY_CREATE = 0` | `ERR-314B6`, 테이블도 `$GIT_` 도 생기지 않음 |

### 오류 코드가 매체마다 다른 점 — 알고 남긴다

디스크에서 프로퍼티 0 일 때 형제(`CREATE INDEX`)는 `ERR-314B6` 을 내고
복사 경로는 `ERR-313D0` 을 낸다. 이유가 다른 게이트에서 나오기 때문이다:
형제는 남는 구현이 `$GIT_` 뿐인데 그것이 은퇴해서, 복사는 원본이 이미
네이티브라 프로퍼티 게이트가 먼저 잡아서. 메모리에서는 둘 다 `ERR-313D0`
으로 같다.

둘 다 거절이고 결과(테이블이 생기지 않는다)는 같다. 코드를 맞추는 것은
설계 결정이라 여기서는 손대지 않고 `copySchemaGate.tc` B 절이 실측대로
못박는다. `ERR-313D0` 의 문구("A non-partitioned index can be created on a
disk partitioned table")가 디스크 테이블에 나오면 읽는 사람에게 도움이 되지
않는다는 점은 남는 흠이다.

---

## 5. 후속 감사 — §6-3 이 열어 둔 항목들 (전부 닫음)

### 5.1 다른 제한도 이 경로로 새는가 → **아니다**

`FROM TABLE SCHEMA` 는 원본의 인덱스를 **그대로 복제**한다. 실행 쪽이
쓰는 값이 전부 원본의 것이다:

- 파티션 테이블스페이스: `sPeerPartInfo->partitionInfo->TBSID`
  (`qdbCopySwap::executeCreateTablePartition`)
- 인덱스 플래그 · 세그 속성: `smiTable::getIndexInfo(sIndex->indexHandle)` 등
  (`createConstraintAndIndexFromInfo`)
- 키 컬럼 · 인덱스 개수: 원본 `qcmIndex` 배열의 복사

복사본에서 원본과 달라지는 것은 **이름뿐**이다(접두사). 그래서 인덱스
정의의 성질에 걸린 제한은 복사본이 새로 어길 수 없다.

| 제한 | 왜 새지 않는가 | 실측 |
|---|---|---|
| 혼합·휘발성 매체 `ERR-314AB` | 복사본의 TBSID 가 원본과 같다. 원본이 뒤늦게 혼합이 될 수도 없다 — 네이티브 글로벌 인덱스가 있는 테이블에 다른 매체 파티션을 붙이면 SM 이 거절한다 | `ALTER TABLE ... ADD PARTITION ... TABLESPACE SYS_TBS_DISK_DATA` → `ERR-1109B` |
| 함수 기반 키 `ERR-314AD` | 생성 시점에 거절되므로 원본이 가질 수 없다 | `CREATE INDEX ... ON t(UPPER(V))` → `ERR-314AD` |
| 압축 키 `ERR-314AD` | 파티션드 테이블은 매체를 불문하고 컬럼 압축 자체를 지원하지 않는다 → 도달 불가 | 메모리 `ERR-313D1` · 디스크 `ERR-3140B` |
| 인덱스 비트 예산 `ERR-314AC` | 테이블당 인덱스 총수를 SM 이 64 로 막는다. 로컬을 나중에 늘려도 `maxLocal + global ≤ 64` 를 넘길 수 없다 | 글로벌 1 + 로컬 63 = 64 에서 다음 `CREATE INDEX ... LOCAL` 이 `ERR-11065`, 그 상태의 DML 은 정상 |
| 키 길이 상한 `ERR-311E0` | 키 컬럼 · 인덱스 타입 · 매체만의 함수이고 셋 다 그대로 복사된다 | 경계는 `Disk/Boundary/keySizeLimit.tc` 가 이미 못박고 있다(전역 3384 / 비전역 3386) |

**정리**: 새는 것은 "인덱스 정의에 없고 **서버 상태**에 있는 값" 뿐이었다.
그것이 정확히 D1(프로퍼티)과 D3(은퇴 스위치) 둘이다.

### 5.2 인덱스를 만들거나 복제하는 DDL 경로 재계수

`smiTable::createIndex` / `createGlobalIndex` 호출부를 전부 세고
(`qcmDictionary` · `qcuTemporaryObj` · `qds` 의 내부용 셋 제외) 문장 단위로
분류했다.

**새 인덱스를 만드는 문장 — 게이트가 서야 하는 자리**

| 문장 | 함수 | 게이트 |
|---|---|---|
| `CREATE INDEX` | `qdx::validate` / `validateIndexRestriction` | 있음 |
| `ALTER TABLE ADD CONSTRAINT PK/UK` | `qdn::validateConstraints` → `createConstrPrimaryUnique` | 있음 |
| `CREATE TABLE (... PK/UK ...)` | 같음 | 있음 |
| `CREATE TABLE AS SELECT (... PK/UK ...)` | 같음 | 있음 |
| `ALTER INDEX ... REBUILD` ($GIT_ → 네이티브 전환) | `qdx::validateAlterRebuild` | 있음 |
| **`CREATE TABLE ... FROM TABLE SCHEMA`** | `qdbCopySwap::validateCreateTableFromTableSchema` | **이번에 넣었다** |

**이미 있는 인덱스를 다시 세우는 문장 — 게이트가 서면 안 되는 자리**

프로퍼티의 계약이 "생성 시점에만 의미가 있다" 이므로, 아래는 카탈로그
판별자(101/100)만 보고 갈라져야 한다. 실제로 전부 그렇다.

| 문장 | 함수 |
|---|---|
| `ALTER INDEX ... REBUILD` (네이티브 → 네이티브) | `qdx::executeAlterRebuild` |
| **`ALTER TABLE ... ALL INDEX ENABLE / DISABLE`** | `qdbAlter::executeAllIndexEnable` / `Disable` |
| `TRUNCATE TABLE` | `qdd::executeTruncateTable` → `createIndexFromInfo` |
| `ALTER TABLE ADD / DROP COLUMN`, 테이블 재생성 | `qdbAlter::executeAddColByRecreateTable` · `executeDropCol` · `recreateTableForMemory/ForDisk` |
| `TRUNCATE / ADD / COALESCE / MERGE / SPLIT / DROP PARTITION` | `qdbAlter::execute*Partition` |
| `ALTER TABLE ... REORGANIZE` | `qdbAlter::recreateIndexForReorganize` |
| 온라인 테이블스페이스 변경 | `qdx::createAllIndexOfTableForAlterTablespace` |

`ALL INDEX ENABLE` 은 이름과 달리 인덱스를 **만들지 않는다** —
`smiTable::enableAllIndex` 에 멤버 파티션 핸들 배열을 넘겨 기존 트리를
다시 세운다. `ALTER INDEX REBUILD` 와 같은 범주이고, 게이트가 닫혀 있어도
성공하는 것이 옳다(`createPathSweep.tc` E 절이 REBUILD 로 이미 못박고 있다).

**복제 메타 DDL**: `src/rp` 에는 인덱스를 만드는 코드가 **없다**. 수신자는
DDL 문장 텍스트를 `qciMisc::runDDLforInternal` 로 다시 실행한다
(`rpcDDLSyncManager::runDDL` · `rpxReceiverApply` · `rpxDDLExecutor`). 즉
위 게이트가 수신자에도 그대로 적용된다. 따라서 이번 수정의 여파로,
프로퍼티가 어긋난 쌍에서는 복제된 `FROM TABLE SCHEMA` 도 수신자에서
실패한다 — `CREATE INDEX` 가 이미 그런 것과 같고,
`Replication/ddlSyncPropertyMismatch.tc` 가 그 계약을 재고 있다.

### 5.3 실패 건들의 판정 → **서버 회귀 아님. 뿌리는 오라클 하나다**

> **정정 (2026-08-20 저녁).** 이 절의 첫 판은 실패를 "절대 카탈로그 id ·
> 문자셋 · 패키지 미설치 · 복제 비활성" 넷으로 갈랐다. **그 분류는 증상을
> 갈랐을 뿐 뿌리가 아니었다.** 아래가 추적 결과다.

#### 5.3.1 먼저 — 이 스위트는 맨손 `atsclnt` 로 도는 것이 아니다

정식 실행기가 있다: **`altidev4/scripts/global-index/natc-check.sh`**.

| | 맨손 `atsclnt NativeGlobalIndex.ts` | `natc-check.sh` |
|---|---|---|
| 인스턴스 | `$ALTIBASE_HOME`(개발용, 포트 20104) | 격리 인스턴스 `~/.ngi-testdb`(포트 20399) |
| 문자셋 | `clean` 기본값 `KO16KSC5601` | `server create UTF8 UTF8` |
| 시스템 패키지 | 없음 | `dbms_concurrent_exec` + `dbms_stats` 설치 |
| `packages/` 링크 | 없음 | 만든다 (aexport 의 `DBMS_METADATA`) |
| 신선도 | `--auto-init=ON` | `NEEDS_FRESH_INSTANCE` 를 보고 인스턴스를 재생성 |
| 실행 | `atsclnt <ts>` | `atsclnt --auto-init=OFF --core=OFF <ts>` |

환경 계약은 전부 **`scripts/global-index/testdb.sh`** 의 `do_init` 에 있다.
그 안의 주석이 이 사태를 그대로 예고해 두었다 — *"`server create` leaves
the instance bare -- no system packages. Install the ones the check scripts
need, **so that destroying and recreating this instance does not silently
turn statistics-dependent cases into failures**"*.

즉 **`DBMS_STATS` 는 재구성 과정에서 빠진 것이 아니다.** 애초에 TC 트리에
있던 적이 없고(원본 `PROJ-1624` 트리도 쓰지 않는다), 스위트의 환경을 짓는
하네스에 있었으며 그 하네스는 지금도 있다. 맨손 `atsclnt` 가 그 하네스를
건너뛴 것이다.

**실측**: `natc-check.sh` 로 돌리면 `pdtBug_BUG-9` · `alterColumnLob_basic`
· `statisticsAndHeader` 셋이 **전부 초록**이고 결과는 **PASS 267 / FAIL 6**
이다.

#### 5.3.2 남은 6 의 뿌리 — 커밋 `df87aaa` 가 오라클 10 개를 안 찍었다

`df87aaa` *"Fold every helper into the case that uses it, and delete the
shared includes"* 는 `.tc`·`.sql` **243 개**를 고치면서 `.lst` 를 **233 개**만
다시 찍었다. 남겨진 10 개가 이것이다.

| 남겨진 원본 경로 | 오늘의 케이스 | 오늘 |
|---|---|---|
| `Memory/DDL/replicationReject.tc` | `replicationReject` | **FAIL** |
| `Port1624/qc/JoinTest.tc` | `Disk/Query/qc_JoinTest` | **FAIL** |
| `Port1624/pdt/Design/CREATE_INDEX/LOCAL/RangePartTable.sql` | `Disk/Create/createIndexLocal_RangePartTable` | **FAIL** |
| `Port1624/pdt/Design/CREATE_INDEX/LOCAL/HashPartTable.sql` | `…_HashPartTable` | **FAIL** |
| `Port1624/pdt/Design/CREATE_INDEX/LOCAL/ListPartTable.sql` | `…_ListPartTable` | **FAIL** |
| `Port1624/pdt/Design/CREATE_TABLE/AS_SELECT/RangePartTable.sql` | `Disk/Create/createTableAsSelect_RangePartTable` | **FAIL** |
| `Port1624/pdt/Bugs/BUG-9/BUG-9.sql` | `Disk/Bugs/pdtBug_BUG-9` | 정식 실행기에서는 PASS |
| `Port1624/pdt/Design/ALTER_TABLE/ALTER_COLUMN_LOB/basic.sql` | `Disk/DDL/alterColumnLob_basic` | 정식 실행기에서는 PASS |
| `Port1624/include/pinNative.sql` | (인클루드 — 오라클 없음) | — |
| `Port1624/pdt/Design/DELETE/RangePartTable.sql` | **MANIFEST 가 `held`** (비결정적 FK 보고) | — |

**남겨진 8 개의 오라클 = 오늘 붉은 6 개 + 인스턴스가 맞으면 초록인 2 개.**
다른 원인은 없다.

증상이 두 모양으로 나뉜 것도 여기서 설명된다.

- `replicationReject` 는 **삭제된 공유 인클루드의 주석 전사**가 오라클에
  아직 남아 있다. 그것이 차이의 전부다(주석 블록 외 차이 0).
- `qc_JoinTest` 는 같은 주석 문제에 더해, 원본이 **EUC-KR** 이라 오라클도
  EUC-KR 바이트인데 러너 출력은 UTF-8 이고, 한글 리터럴이 손상된 채
  이식돼(`컬럼` → `�÷�`) 바이트 길이가 달라지면서 `ERR-21069`
  유무까지 갈린다.
- 나머지 넷은 **절대 카탈로그 id**(`__SYS_PART_IDX_ID_1933` ↔ `254`,
  `TABLE_ID 289` ↔ `406`)다. 오라클이 이력 있는 인스턴스에서 찍힌 채
  다시 찍히지 않았다.

#### 5.3.3 CopySwap 수정과의 관계 → 없다

- 6 건 중 `CREATE TABLE ... FROM TABLE SCHEMA` 를 쓰는 케이스는 **하나도
  없다.** 그 문장을 쓰는 케이스는 트리 전체에 넷이고
  (`createPathSweep` · `createTableFromSchema` · `createIndexError` ·
  새 `copySchemaGate`) 전부 통과한다.
- 실행 중이던 서버가 **수정 이전 바이너리**였던 것(`/proc/<pid>/exe` 가
  deleted)은 별개로 확인해 재빌드·재기동했다.

## 6. 재현 · 검증에 쓴 정확한 명령

```bash
# 빌드 (altidev4)
cd /data/et16/work/altidev4 && make build -j"$(nproc)"

# ★ 스위트 실행 — 이것이 정식 경로다.
#   격리 인스턴스를 UTF8 로 짓고 시스템 패키지를 넣고 --auto-init=OFF 로 돈다.
cd /data/et16/work/altidev4 && ./scripts/global-index/natc-check.sh
#   --no-fresh 를 주면 인스턴스 재생성을 건너뛴다.

# 단일 케이스만 볼 때 (개발용 인스턴스, 포트 20104)
cd /data/et16/work/natc && server stop && server start
atsclnt TC/Server/sm4/Project4/NativeGlobalIndexClaude/Disk/DDL/copySchemaGate.tc
atsclnt TC/Server/sm4/Project4/NativeGlobalIndexClaude/Memory/Create/createPathSweep.tc
```

> **맨손 `atsclnt <NativeGlobalIndex.ts>` 로 전체를 돌리지 말 것.** 개발용
> 인스턴스는 문자셋이 `KO16KSC5601` 이고 시스템 패키지가 없어서 §5.3.1 의
> 셋이 실패로 보인다. 서버의 문제가 아니다.
>
> `bin/atc` / `bin/atc2` 는 이 기계에서 돌지 않는다 — `atc.pl` 이 요구하는
> perl `Event` 모듈이 없다.

## 7. 남은 것

- [x] ~~`df87aaa` 가 남긴 오라클 8 개~~ **닫힘 (2026-08-21).** 다섯을 신선
      인스턴스에서 재기록했고, `qc_JoinTest` 는 재기록이 아니라 **한글
      복원**이 답이었다 — 그 커밋이 EUC-KR → UTF-8 변환에서 리터럴 21 곳을
      파괴해 케이스가 재는 행 집합이 8/4/5/3 에서 7/3/5/3 으로 줄어 있었다.
      원본 바이트로 되살리자 8/4/5/3 으로 돌아왔다. `natc-check.sh`
      **GREEN 273/273**.
- [ ] `ERR-313D0` 의 문구가 디스크 파티션드 테이블에 나오면 오해를 부른다.
      매체별 오류 코드 정리는 설계 결정이라 손대지 않았다(§4).
- (정정) `restartCatalogSurvival.sql` 의 `--+SYSTEM clean;` 을 결함으로
      적었다가 내린다 (2026-08-21). `--+SYSTEM clean` 은 ATAF 의 정상
      관용구이고, 표준 하네스에서는 auto-init 이 어차피 DB 를 다시 만드니
      비용은 시간뿐이다.

      **사실만 남기면**: 이 스위트는 비표준 인스턴스(UTF8 + 시스템 패키지)
      위에서 돌고 `clean` 은 기본 구성(`KO16KSC5601`, 패키지 없음)으로
      다시 만든다. 그래서 한 실행의 전반부와 후반부가 서로 다른 DB
      구성에서 돈다. **오늘 그 차이를 읽는 케이스는 없다** -- clean 뒤에
      오는 `Memory/` · `Tool/` 전체에 비ASCII SQL 리터럴이 0 건이고,
      `DBMS_STATS` 를 쓰는 케이스는 `statisticsAndHeader` 하나뿐인데 그것은
      `Disk/Query` 라 clean **앞**에서 돈다(실측). 오라클도 각자 자기가 도는
      구성에서 찍혀 자기정합적이고, 이 상태로 GREEN 273/273 이다.

      남는 것은 **순서 의존** 하나다 -- 케이스를 단독 실행하면 clean 앞
      구성에서 돈다. 한글 데이터나 통계에 의존하는 케이스를 `Recovery`
      뒤에 놓게 되는 날 드러난다. 그때 그 케이스가 자기 전제를 세우면 된다.

      ★ 왜 결함으로 적었었나 -- `tool_aexport_initialize.tc` 가 원본의
      `stdClean()` 을 **바로 이 이유로 제거**한 PORT EDIT 을 갖고 있어서,
      같은 기계장치를 다시 넣은 것을 "앞의 판단을 못 물려받았다" 로 읽었다.
      두 자리는 상황이 다르다 -- aexport 뒤 세 케이스는 DDL 을 덤프해
      비교하므로 인스턴스 구성에 실제로 의존하고, `restartCatalogSurvival`
      뒤는 아니다. **기계장치가 같다고 결과가 같다고 추정한 것이 틀렸다.**
- [ ] 이 하네스는 `.tc` 바이트를 **EUC-KR 로 읽는다.** 이식분의 한글 SQL
      리터럴은 EUC-KR 이어야 하고, UTF-8 로 두면 `ERR-31001` 이 난다.
      `ALTIBASE_NLS_USE=UTF8` 이 셸과 STAFProc 환경에 있는데도 그렇다 —
      ATAF 가 spawn 하는 isql 에 닿지 않는 것으로 보인다. 하네스 쪽
      판단이 필요하다.
- [ ] `.tc`·`.sql` 을 고치는 커밋은 대응 `.lst` 를 같은 커밋에서 다시
      찍는다. 인코딩을 바꾸는 커밋은 한글 개수를 원본과 대조한다.
