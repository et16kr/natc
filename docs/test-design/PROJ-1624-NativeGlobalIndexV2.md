# Native Global Index V2 테스트 구상

- 작성일: 2026-08-01
- 상태: 서버 구현 중인 시점의 설계 및 source prototype 기준선
- 구버전 기준:
  TC/Server/qp4/Project3/PROJ-1624-GlobalIndex
- 서버 설계 기준:
  /home/et16/work/altidev4_gi/docs/analysis/codex-global-index
- 확인한 서버 HEAD: f6691b82 (Implement global index startup shells)

이 문서는 source prototype과 expected result를 확정하기 전의 설계 문서다.
SM 소유 prototype은 TC/Server/sm4/Project4/NativeGlobalIndexCodex에 있다.
현재 서버의 사용자 SQL gate가 닫혀 있고 구현도 진행 중이므로 테스트를
실행하거나 .lst를 만들지 않았다. 서버 구현 완료 시점에 설계와 실제 문법,
catalog, plan 명칭, error code를 다시 대조해야 한다.

## 1. 결론

구버전 PROJ-1624의 시나리오 의도는 상당 부분 재사용할 수 있지만 테스트
코드는 그대로 복사하면 안 된다.

가장 큰 차이는 다음과 같다.

1. 구버전 global index는 disk partitioned table 위에 hidden table과
   hidden index를 만드는 방식이다.
2. 신버전은 parent가 직접 소유하는 native Memory/Disk B-tree이며 새 object는
   $GIT_* table을 만들지 않는다.
3. 구버전의 핵심 consistency oracle은 $GIT_* table을 직접 조회하는 것이므로
   native 구현에서는 성립하지 않는다.
4. 구버전에서 성공하던 partition topology/reset DDL 중 다수는 native V1에서
   명시적으로 거부해야 한다.
5. Memory global index, native Disk recovery, startup bind, implementation
   discriminator, mixed-media 거부는 구버전 suite에 충분히 존재하지 않는다.

따라서 신버전 테스트는 다음 세 계층으로 나누는 것이 적절하다.

| 계층 | 목적 | 실행 환경 |
| --- | --- | --- |
| SQL regression | 공개 SQL, catalog, plan, DML, constraint, 명시적 unsupported | 일반 NATC single server |
| lifecycle/integration | clean/crash restart, upgrade, backup/restore, RP DDL sync | 환경 계약이 있는 별도 suite |
| server internal/FIT | allocator, WAL 지점, recovery format, race, fatal invariant | 서버 unittest/FIT; 일반 .tc에 넣지 않음 |

## 2. 구버전 테스트 인벤토리

### 2.1 전체 파일과 실제 root suite

구버전 디렉터리 전체에는 다음 artifact가 있다.

| 종류 | 수 |
| --- | ---: |
| .tc | 107 |
| .sql | 179 |
| .ts | 41 |
| .lst | 222 |
| .i | 10 |

하지만 최상위 PROJ-1624.ts에서 재귀적으로 도달하는 것은 12개 suite와
77개 case뿐이다. 활성 case는 .tc 76개와 .sql 1개다. 나머지 209개
.tc/.sql은 PROJ-1624-QC, PDT의 schema fixture, 별도 performance 자료 등으로
최상위 suite에 연결되지 않는다.

최상위 활성 case 분포는 다음과 같다.

| 영역 | case 수 | 주요 내용 |
| --- | ---: | --- |
| DDL | 25 | create/drop/rebuild, column/constraint, partition DDL |
| basic | 16 | select와 range/hash/list INSERT/UPDATE/DELETE/MOVE |
| design | 16 | plan, predicate, join, selectivity, hint, order |
| meta | 8 | table/index/constraint/user/tablespace catalog 변화 |
| bugs | 6 | function index, rollup, maxvalue, drop, 과거 BUG |
| tool | 6 | iSQL, aexport, atomic array insert |
| 합계 | 77 | |

최상위 replication/replication.ts와 performance/performance.ts에는 실행
case가 없다. replication/README는 별도 repl4 경로를 가리킨다.
PROJ-1624-QC/repl에는 구형 2-server test가 있으나 최상위 suite에는
연결되어 있지 않다.

### 2.2 활성 case의 동작 분포

활성 77개 case를 내용 기준으로 검색한 결과다. 한 case가 여러 행에 중복될
수 있다.

| 패턴 | 포함 case 수 |
| --- | ---: |
| CREATE INDEX | 69 |
| LOCAL index 대조 | 27 |
| $GIT_* 직접 조회 | 9 |
| SYSTEM_ catalog 직접 조회 | 5 |
| explain plan | 47 |
| INSERT | 51 |
| UPDATE | 8 |
| DELETE | 10 |
| MOVE | 3 |
| row movement | 6 |
| partition topology DDL | 6 |
| PK/UK | 43 |
| statistics | 3 |
| tool/external command | 11 |

구버전 tree 전체에서 107개 .tc 중 104개는 DEF MAIN을 갖지만 대부분
SECTOR를 실행 문법이 아니라 주석으로만 표시한다. .tc/.sql 134개에는
old-style --+ directive가 있다. 신버전 artifact는 현재 TC_GUIDE.md 형식으로
새로 작성해야 하며 이 문법을 답습하지 않는다.

## 3. 구버전이 검증하는 모델

### 3.1 object 선택

구버전의 disk partitioned table에서 LOCAL을 쓰지 않은 non-partitioned
index는 global index로 처리된다. LOCAL index를 같은 table에 함께 만들어
optimizer와 DML 회귀의 대조군으로 사용한다.

global PK/UK와 일반 index를 만들면 다음 hidden object가 생성되는 구조를
테스트가 전제로 한다.

    Logical index
      -> $GIT_<INDEX_NAME> hidden table
      -> $GIK_* / $GIR_* hidden indexes
      -> user key + $GIT_OID + $GIT_RID

### 3.2 기존 oracle

| oracle | 구버전 방식 | 신버전 처리 |
| --- | --- | --- |
| row consistency | 각 partition의 user key/OID/RID와 $GIT_* row를 full outer join | 폐기; native에는 queryable hidden row가 없음 |
| physical description | DESC "$GIT_<INDEX>" | 폐기 |
| catalog | $로 시작하는 SYS_TABLES_/SYS_INDICES_ row 확인 | native discriminator와 INDEX_TABLE_ID=0 확인으로 교체 |
| query correctness | SELECT 결과와 explain plan | 유지하되 native plan으로 oracle 재생성 |
| optimizer | local/global NDV, hint, predicate, order | 의도 재사용 |
| DDL | hidden table을 포함한 create/drop/rebuild/partition DDL | native 지원/거부 범위로 재분류 |
| DML | INSERT/UPDATE/DELETE/MOVE 후 hidden row 비교 | 결과 집합, uniqueness, rollback, plan, restart로 교체 |
| tool | iSQL DESC, aexport, atomic insert | native metadata가 노출되지 않는지 포함해 재작성 |

### 3.3 재사용 가치가 높은 부분

- range/list/hash partition data 구성
- local/global index가 같이 있을 때의 optimizer 선택
- fixed/variable, NULL, composite, ASC/DESC key
- empty/non-empty table의 CREATE INDEX
- PK/UK backing index와 cross-partition uniqueness
- INSERT/UPDATE/DELETE와 partition-key UPDATE row movement
- equality/range/IN/LIKE/host variable/join/order/FOR UPDATE
- DROP/REBUILD와 object cascade
- statistics, iSQL, aexport, atomic insert의 사용자 관점

### 3.4 그대로 재사용하면 안 되는 부분

- $GIT_*, $GIK_*, $GIR_, $GIT_OID, $GIT_RID 직접 참조
- hidden table에 대한 DDL/DML/권한 검사
- hidden row를 갱신해 만든 expected result
- native에서 제외된 ADD/DROP/TRUNCATE/SPLIT/MERGE/MOVE/EXCHANGE/REPLACE
  partition의 성공 기대
- 구버전 plan 문자열과 hidden table cardinality
- 최상위 suite에서 사용하지 않는 PROJ-1624-QC/PDT 자료의 일괄 이관
- 현재 규칙에 없는 old-style --+ directive와 외부 shell 의존성

## 4. 신버전 기능 계약

### 4.1 신규 object의 분류

서버 설계상 fresh database에서 feature gate가 열린 뒤 homogeneous
partitioned table의 신규 global index는 property 선택 없이 매체에 따라
native로 생성된다.

| 대상 | INDEX_IMPL_TYPE | INDEX_TABLE_ID | hidden table |
| --- | ---: | ---: | --- |
| 일반/local index | 0 | 기존 계약 | 없음 |
| upgrade로 보존된 legacy hidden global | 1 | nonzero | 있음 |
| native Memory global | 2 | 0 | 없음 |
| native Disk global | 3 | 0 | 없음 |

기존 hidden object의 in-place conversion은 없다. old binary에서 만든 hidden
object는 upgrade 뒤에도 type 1로 유지하고, DROP 후 같은 SQL로 다시 만들면
현재 매체의 native type으로 생성되는 별도 compatibility scenario가 필요하다.

### 4.2 V1 지원 범위

공통 지원 범위:

- homogeneous Memory-only 또는 Disk-only partition set
- range/list/hash partitioned table
- built-in non-partitioned B-tree
- unique/non-unique, PK/UK backing index
- fixed/variable, NULL, composite, ASC/DESC key
- equality/range/ordered scan과 partition pruning
- INSERT/UPDATE/DELETE
- partition-key UPDATE에 의한 row movement
- statement/savepoint/transaction rollback
- offline CREATE/REBUILD, DROP과 DROP TABLE CASCADE
- local index와 native global index의 공존
- base-row replication apply와 version-gated synchronous DDL sync

Memory는 restart 때 base row로 composite tree를 다시 build한다. Disk는
GLOBAL_V1 segment와 WAL을 보존해 recovery 후 bind한다. 같은 SQL 결과라도
restart oracle은 매체별로 분리해야 한다.

### 4.3 V1 명시적 거부 범위

다음 요청은 hidden으로 fallback하지 않고 persistent 변경 전에 실패해야
한다.

- mixed Memory/Disk, volatile, private/temporary table
- global partitioned index, partial global index
- R-tree/B_TREE2/user-defined index type
- DIRECTKEY
- online 또는 parallel CREATE/REBUILD
- native ALTER INDEX ENABLE/DISABLE
- parallel global scan
- Memory INDEX PERSISTENT
- Disk NOLOGGING/FORCE/TOPDOWN build와 clustered index
- Memory dictionary/compressed key
- Disk index-only/full-index-scan optimization
- ADD/DROP/TRUNCATE/SPLIT/MERGE/MOVE/EXCHANGE/REPLACE partition
- participant/index tablespace ONLINE/OFFLINE 전환
- async native-global DDL replication
- XA/2PC prepared transaction의 native global DDL
- savepoint를 가로지르는 복수 native global DDL
- 한 parent 또는 child의 65번째 native global index

지원 여부가 Memory와 Disk에서 다른 항목은 하나의 multi-oracle case로
숨기지 말고 매체별 case로 분리한다.

## 5. native SQL oracle 설계

### 5.1 기본 원칙

native tree는 SQL에서 직접 조회하지 않는다. 하나의 internal physical
표현에 의존하는 대신 서로 독립적인 사용자 관점 oracle을 조합한다.

1. catalog identity
2. forced full scan과 native index scan의 결과 동등성
3. cross-partition uniqueness
4. DML/rollback 뒤의 결정적 결과 집합
5. explain plan의 native access path
6. restart 전후 동일 결과
7. DROP/REBUILD 뒤 object와 catalog 수명

### 5.2 catalog oracle

native CREATE 직후 최소한 다음을 확인한다.

- parent의 logical index row가 정확히 하나
- INDEX_IMPL_TYPE이 Memory 2 또는 Disk 3
- INDEX_TABLE_ID가 0
- index column 순서, sort order, uniqueness와 tablespace가 요청과 일치
- 해당 index에서 파생된 $GIT_/$GIK_/$GIR_ catalog object가 0개
- local index의 INDEX_IMPL_TYPE은 0

legacy upgrade lane에서는 반대로 type 1과 nonzero INDEX_TABLE_ID, 기존
hidden object 보존을 확인한다.

catalog column의 최종 공개 명칭과 접근 권한은 서버 완료 후 확정한다.
numeric 값만 검사하는 helper에는 값의 의미를 주석과 test ID로 남긴다.

### 5.3 data consistency oracle

각 주요 DML 뒤 다음 두 query의 정렬된 결과가 같아야 한다.

- native index를 사용하도록 유도한 query
- full scan을 사용하도록 유도한 query

직접적인 row set 외에 COUNT, MIN/MAX, key별 GROUP BY count를 함께 사용해
missing/duplicate entry를 검출한다. 결과에는 항상 ORDER BY를 붙이고,
힌트가 실제 적용됐는지는 explain plan으로 별도 확인한다.

특히 다음 변화를 전후 비교한다.

- 모든 partition에 INSERT
- key column UPDATE
- non-key column UPDATE
- partition key UPDATE와 row movement
- DELETE
- statement/savepoint/transaction rollback
- REBUILD
- clean/crash restart

### 5.4 uniqueness oracle

partition key는 다르지만 global unique key가 같은 두 row를 서로 다른
partition에 넣는다.

- 첫 transaction commit 뒤 두 번째 INSERT 실패
- 두 transaction이 동시에 같은 key를 넣을 때 하나만 commit
- 대기 transaction의 상대 transaction commit/rollback 결과
- 실패 뒤 base row와 index scan 결과에 orphan/duplicate가 없음

동시성 case는 일반 single-client .tc와 분리하고 THREAD/CLIENT 환경 계약이
확정된 뒤 작성한다.

### 5.5 negative oracle

unsupported case는 다음 순서로 검증한다.

1. 요청 전 catalog row 수와 base row를 기록
2. DDL 실행과 안정된 error code 확인
3. 요청 후 catalog/index/hidden object 수가 이전과 같음
4. 기존 native index로 SELECT와 DML이 계속 성공
5. hidden implementation으로 생성된 object가 없음

현재 서버에서 error code와 메시지가 모두 확정되기 전에는 .lst를 추측하지
않는다.

## 6. artifact 구조

신버전은 QP project가 아니라 SM Project4에 다음 구조로 둔다.

    TC/Server/sm4/Project4/NativeGlobalIndexCodex/
      NativeGlobalIndexCodex.ts
      TEST_MATRIX.md
      Disk/
        Catalog/
        Create/
        Query/
        DML/
        DDL/
        Unsupported/
        Lifecycle/
      Memory/
        Catalog/
        Create/
        Query/
        DML/
        DDL/
        Unsupported/
        Lifecycle/

일반 SQL source prototype은 매체별 suite에 연결한다. Lifecycle은 restart와
fault 환경 계약이 확정되기 전까지 README 시나리오만 유지하고 기본 suite에
연결하지 않는다. compatibility, replication, performance도 실행 환경이
확정될 때 별도 SM suite로 추가한다.

현재 source baseline은 실행 가능한 SQL prototype 40개와 이를 연결하는
suite 15개다. Disk와 Memory가 각각 20개이며 실제 파일명, Test ID, 주
oracle의 대응은 prototype 디렉터리의 TEST_MATRIX.md를 기준으로 한다.

여러 디렉터리에서 재사용할 catalog helper가 안정되면
TC/include/nativeGlobalIndex.i 같은 공용 include를 검토한다. 그 전에는
helper signature를 추측하지 않고 case-local query를 사용한다.

모든 신규 .tc는 TC_GUIDE.md에 따라 다음을 지킨다.

- DEF MAIN과 INITIALIZATION, PREPARATION, TEST, FINALIZATION 순서
- caseName_A4_64.lst tagged oracle
- deterministic ORDER BY
- case가 만든 object만 cleanup
- old-style --+ directive 금지
- 실제 서버 실행 전 복잡한 error/plan .lst 생성 금지

## 7. 우선순위별 SQL regression case

아래 표는 현재 40개 source baseline 이후의 확장 backlog다. 이미 작성한
prototype과의 정확한 대응은 TEST_MATRIX.md를 사용한다.

### P0. gate 직후 smoke

| Test ID | 제안 case | 핵심 검증 |
| --- | --- | --- |
| NGIV2-SMK-001 | createDisk.tc | Disk range table의 신규 global이 type 3, hidden 0개 |
| NGIV2-SMK-002 | createMemory.tc | Memory range table의 신규 global이 type 2, hidden 0개 |
| NGIV2-SMK-003 | localCoexist.tc | local type 0과 native global 공존 |
| NGIV2-SMK-004 | insertScan.tc | 모든 partition INSERT 후 index/full scan 동등 |
| NGIV2-SMK-005 | updateDelete.tc | key/non-key UPDATE, DELETE 결과 |
| NGIV2-SMK-006 | rowMovement.tc | partition 이동 뒤 old/new entry exact-one |
| NGIV2-SMK-007 | crossPartitionUnique.tc | 다른 partition의 같은 unique key 거부 |
| NGIV2-SMK-008 | rollback.tc | statement/savepoint/transaction rollback |
| NGIV2-SMK-009 | rebuildDrop.tc | offline REBUILD와 DROP 수명 |
| NGIV2-SMK-010 | unsupportedTopology.tc | partition topology/reset DDL 사전 거부 |

각 P0 case는 가능하면 Memory와 Disk를 분리한다. 공통 논리를 한 파일에
반복하더라도 실패한 매체와 단계가 .lst에서 명확히 보여야 한다.

### P1. 기능 matrix

| Test ID 범위 | 영역 | matrix |
| --- | --- | --- |
| NGIV2-CAT-* | catalog | create/drop, PK/UK, copy/recreate, type 0/2/3 |
| NGIV2-KEY-* | key | fixed/variable, NULL, composite, ASC/DESC, max key |
| NGIV2-PART-* | partition | range/list/hash, 1/N partition, 서로 다른 동일-media TBS |
| NGIV2-QRY-* | query | equality/range/IN/LIKE, host variable, join, order, FOR UPDATE |
| NGIV2-OPT-* | optimizer | local/native 선택, hint, NDV/selectivity, pruning 0/1/N/all |
| NGIV2-DML-* | DML | insert/update/delete/move, multiple global indexes, no local index |
| NGIV2-CON-* | constraint | unique/PK/UK/FK, duplicate build, cross-partition race |
| NGIV2-DDL-* | DDL | empty/non-empty create, rebuild, drop, table/user/TBS cascade |
| NGIV2-STA-* | statistics | native tree stats, local/hidden 수집 횟수 회귀 |
| NGIV2-NEG-* | unsupported | 매체·index type·option·partition DDL·transaction 제한 |
| NGIV2-TOL-* | tool | iSQL DESC, aexport, atomic insert |

### P2. 경계와 장시간

- local index 64개 + global index 64개
- 65번째 global index 실패와 잔여 object 0개
- global index 2개/64개를 가진 table의 DROP CASCADE
- active cursor와 DROP/REBUILD 경쟁
- long-running old snapshot 뒤 DELETE/aging
- variable key가 서로 다른 Memory tablespace에 있는 경우
- Disk의 서로 다른 participant data tablespace와 별도 index tablespace
- 반복 CREATE/REBUILD/DROP과 object ID 재사용

P2의 counter/race와 internal leak 검증은 SQL 결과만으로 충분하지 않다.
필요한 fixed table 또는 trace 항목이 서버에 제공될 때만 NATC oracle로
추가한다.

## 8. lifecycle, recovery와 replication

### 8.1 restart

Memory와 Disk suite를 분리한다.

Memory:

- clean restart 뒤 base row로 global tree를 rebuild
- rebuild 완료 전 SERVICE/query 차단
- duplicate 때문에 startup build가 실패하면 SERVICE 진입 차단
- empty/non-empty, fixed/variable, PK/UK 조합

Disk:

- clean restart에서 기존 segment 재사용
- DML 중 abnormal shutdown 뒤 redo/undo
- CREATE/REBUILD/DROP의 publish 전후 crash
- startup bind 뒤 query/DML과 integrity verify
- corrupt/mismatched meta는 silent rebuild가 아니라 startup 실패

일반 TC_GUIDE는 restart를 reference-gated로 분류한다. server lifecycle helper,
재시작 모드, timeout, log oracle이 확정되기 전에는 실행 artifact를 만들지
않는다.

### 8.2 upgrade와 legacy hidden

이 lane에는 old binary로 만든 fixture가 필요하다.

1. old binary에서 disk partitioned table과 hidden global index 생성
2. base DML과 $GIT_* consistency 확인
3. new binary로 meta 9.4 upgrade
4. existing index가 type 1과 nonzero INDEX_TABLE_ID를 유지하는지 확인
5. 기존 SELECT/DML/DDL이 hidden 경로로 정상 동작하는지 확인
6. index DROP 후 같은 SQL로 재생성
7. 재생성 object가 type 3, INDEX_TABLE_ID 0, hidden 0개인지 확인
8. 9.4에서 9.3 downgrade가 거부되는지 확인

fresh database native regression만으로는 이 compatibility를 검증할 수 없다.
구버전 suite의 $GIT_* helper는 이 upgrade lane에서만 제한적으로 재사용한다.

### 8.3 replication

별도 2-server 환경에서 다음을 검증한다.

- sender base INSERT/UPDATE/DELETE가 receiver의 native index를 정확히 한 번 유지
- physical global leaf/token/OID는 전송하지 않음
- fix 8 peer와 native DDL sync 사전 거부
- 동일 fix의 homogeneous topology에서 CREATE/DROP/REBUILD 동기화
- endpoint별 catalog type은 같고 OID/create token은 독립
- remote media/topology mismatch, remote build failure, ACK loss rollback
- async DDL 대상 native CREATE/DROP/REBUILD 사전 거부

PROJ-1624-QC/repl의 DECLARE SERVER/CLIENT와 stdServer* 호출은 참고 자료일
뿐이다. 현재 server.conf와 client.conf 계약을 확인한 뒤 새 환경으로
작성한다.

### 8.4 server internal/FIT 소유 범위

다음 항목은 NATC 일반 SQL case가 아니라 서버 unittest/FIT가 주 oracle이다.

- Memory row OID/variable descriptor collision
- Disk GLOBAL_V1 meta/key/log golden bytes
- WAL log point별 crash와 compensation exact-once
- registry publish N번째 allocation failure
- startup shell/bind N번째 failure와 ownership leak
- latch/refcount/use-after-free/fatal invariant
- create token collision, copied header identity와 32/64-bit wire

NATC는 이 결과를 반복 구현하지 않고 최종 사용자 smoke와 restart 결과를
연결한다.

## 9. 구버전 case 이관 지도

| 구버전 영역 | 신버전 처리 |
| --- | --- |
| basic/select.tc | query/predicate/order/FOR UPDATE 의도 이관 |
| basic/insert_*.tc | Memory/Disk 및 range/list/hash로 분리, hidden check 제거 |
| basic/update_*.tc | key/non-key/row movement/rollback oracle로 재작성 |
| basic/delete_*.tc | old snapshot과 rollback을 보강 |
| basic/move_*.tc | 지원 SQL 의미 확인 후 DML 또는 unsupported로 분류 |
| DDL/create/drop/alter_index.tc | native create/drop/offline rebuild 중심으로 이관 |
| DDL/*partition.tc | legacy hidden positive와 native negative로 분리 |
| DDL/global_index_table.tc | native에는 대상 hidden table이 없으므로 compatibility lane만 유지 |
| meta/*.tc | INDEX_IMPL_TYPE/INDEX_TABLE_ID와 hidden absence 중심으로 재작성 |
| design/*.tc | plan 명칭과 cost가 확정된 뒤 expected output 재생성 |
| bugs/*.tc | 재현 원인이 native에도 적용되는지 case별 triage |
| tool/isql | native descriptor에 hidden object가 노출되지 않는지 확인 |
| tool/aexport | export/import 후 implementation type과 data/query 결과 확인 |
| tool/atomic | array insert 뒤 native index/full scan 동등성 |
| performance | local, legacy hidden, native Memory, native Disk을 분리 측정 |
| PROJ-1624-QC/PDT | root 미연결 자료; 필요한 fixture만 출처를 기록해 선택 이관 |

## 10. 서버 구현 Job과 test traceability

| 서버 범위 | NATC/Test 범위 |
| --- | --- |
| J002-J004 catalog/QP discriminator | NGIV2-CAT, upgrade compatibility |
| J005-J015 common API/runtime/lifecycle | smoke, rollback, DDL, lifecycle; internal unittest/FIT |
| J016-J029 Memory backend | NGIV2 Memory query/DML/constraint/restart |
| J030-J043 Disk backend/recovery | NGIV2 Disk query/DML/DDL/restart; server recovery FIT |
| J044-J045 replication | NGIV2-RP 별도 2-server suite |
| J046 V1 exclusion | NGIV2-NEG |
| J048 gate activation | P0 smoke 최초 실행 |
| J049 post-gate verification | 전체 SQL regression과 최종 .lst 확정 |

case manifest를 만들 때 최소한 다음 column을 둔다.

| column | 의미 |
| --- | --- |
| Test ID | NGIV2-* 안정 ID |
| media | Memory, Disk, Both, Legacy Hidden |
| layer | SQL, Lifecycle, RP, Internal/FIT |
| feature | create/query/DML/DDL/recovery 등 |
| oracle | catalog/result/plan/error/restart |
| legacy source | 재사용한 구버전 file 또는 신규 |
| server Job | J002-J049 trace |
| status | Planned, Blocked, Ready, Pass, Fail |

## 11. 작성과 실행 순서

### 단계 A. 서버 gate가 닫힌 현재

- 이 설계와 case manifest만 유지
- 구버전 case를 재사용/교체/폐기 대상으로 분류
- 실제 .tc, .lst와 error text는 만들지 않음
- restart/RP 환경 계약과 upgrade fixture 소유자를 정함

### 단계 B. J047 완료 후, J048 전

- 최종 SQL grammar와 media 판정 규칙 재확인
- catalog column/권한, plan node 명칭, error code 확정
- P0 .tc source 작성
- expected .lst는 아직 생성하지 않음

### 단계 C. J048 gate 개방 직후

- createDisk/createMemory/catalog/insert/unique/negative smoke 실행
- 실제 .out을 검토해 _A4_64.lst 생성
- 같은 명령을 다시 실행해 PASS 확인
- smoke 실패 시 broad suite를 실행하지 않고 server owner Job으로 되돌림

### 단계 D. J049와 release 후보

- P1 전체 SQL regression
- local index와 upgrade hidden regression
- Memory/Disk restart와 Disk recovery
- RP, tool, backup/restore
- performance baseline
- 모든 test ID와 server audit evidence 연결

## 12. 구현 전 확인할 미결정 사항

1. 공식 project ID와 최종 artifact 경로
2. 최종 server에서 homogeneous 신규 object가 자동 native가 되는 정확한 gate
3. INDEX_IMPL_TYPE/INDEX_TABLE_ID의 test 계정 접근 방법
4. native plan node와 fixed-table/diagnostic column 명칭
5. V1 unsupported 항목별 안정 error code와 message
6. Memory tablespace/partition 생성의 최종 지원 SQL
7. restart/crash runner와 server lifecycle helper 계약
8. old binary upgrade fixture를 생성·보관할 위치
9. RP fix version의 최종 번호와 2-server config
10. aexport/backup이 implementation type을 보존하는 최종 format

이 항목이 확정되지 않은 상태에서 SQL 문법, error text 또는 .lst를 추측하지
않는다.

## 13. 완료 기준

신버전 테스트 준비는 다음 조건을 만족할 때 완료로 본다.

- 모든 P0/P1 case가 stable Test ID와 server Job을 가짐
- native Memory/Disk와 local/legacy hidden 네 경로가 구분됨
- native SQL case에 $GIT_* physical oracle이 없음
- native와 full scan 결과를 독립 비교함
- 지원하지 않는 기능이 persistent 변경 전에 실패함
- Memory/Disk restart 정책의 차이가 별도 suite로 검증됨
- upgrade hidden object가 보존되고 DROP/CREATE 뒤 native로 전환됨
- RP, restart, fault test가 일반 SQL suite와 환경별로 분리됨
- 실제 target 실행으로 생성한 tagged .lst가 존재함
- root .ts의 모든 참조가 존재하고 전체 suite가 반복 PASS함
