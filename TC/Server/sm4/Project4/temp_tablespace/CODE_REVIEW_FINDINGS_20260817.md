# TEMP tablespace diff static code review findings

- Date: 2026-08-17
- Product tree: `/home/et16/work/altidev4_gi`
- Branch/HEAD: `workspace/simple_temp_tablespace` / `8e5eab25`
- Review scope: current worktree diff against HEAD (staged change 없음) 및 diff가 참조하는
  untracked test hook source
- Purpose record: `DEBUG_FIX_FINDINGS_20260817.md`
- Normative design: `docs/temp-tablespace-memory-extent-design.md`
- Review mode: static code review only
- Not performed: source modification, build, unit/NATC execution, server run, debugging

## Verdict

**승인 보류**가 필요하다.

PID 0 예약, statement-sized multi-file DROP adapter, standard datafile-node I/O
owner 재사용, runtime 상태의 비영속성 유지 등은 TEMP tablespace의 기본 설계 방향과
맞는다. 그러나 새 file-set runtime replacement에는 다음 blocking 문제가 있다.

1. 교체 대상 runtime을 참조하는 모든 reader의 lifetime을 보호하지 않아
   use-after-free가 가능하다.
2. definition과 file-set runtime이 하나의 publication boundary에서 바뀌지 않아
   중간 혼합 상태가 public reader와 allocator에 노출된다.
3. ADD/DROP이 대상 파일 단위가 아니라 tablespace 전체 allocation-free 상태에서만
   성공한다. 이는 설계가 요구하는 온라인 ADD와 target-file DROP 의미를 축소한다.

이 세 항목은 focused test가 성공했다는 사실과 양립한다. 현재 focused ADD/DROP은
quiescent tablespace를 사용하며, concurrent reader/allocator와 live retained-file
allocation을 검증하지 않는다.

## Severity summary

| ID | Severity | Finding |
|---|---|---|
| F-01 | Blocker | Runtime replacement가 raw runtime reader를 drain하지 않아 use-after-free 가능 |
| F-02 | Blocker | Definition과 file-set runtime publication이 분리되어 mixed generation/file-set 노출 |
| F-03 | High | ADD/DROP이 tablespace 전체 allocation-free를 요구하여 기본 DDL 의미 위반 |
| F-04 | High | Runtime-grow된 tempfile DROP 후 standard `mTotalPageCount=sum(R)` 불변식 훼손 |
| F-05 | High | Generation/runtime publication 실패가 strong failure guarantee를 제공하지 않음 |
| F-06 | Medium | AUTOEXTEND가 file resize mutex를 잡은 채 global registry latch를 획득 |
| F-07 | Medium | AUTOEXTEND same-value 판정의 OR 조건이 definition/node drift를 성공 no-op으로 숨김 |
| F-08 | Medium (delivery) | Makefile이 참조하는 필수 test hook source가 untracked 상태 |

## Findings

### F-01 — Blocker: runtime replacement 중 raw runtime reader use-after-free

#### Evidence

- `sdpteModule::replaceRuntimeFiles()`는
  `src/sm/sdp/sdpte/sdpteModule.cpp:1113-1123`에서
  `mExtentBridgeLeaseCount`만 drain한다.
- 같은 함수는 `:1145`에서 runtime pointer bundle을 swap하고 `:1157`에서 old
  bundle을 즉시 destroy/free한다.
- 반면 `getExtent()` (`:1457-1478`), `getBody()` (`:1627-1648`),
  `getAutoExtend()` (`:1654-1675`), `getFile()` (`:1743-1768`)은 lifecycle
  mutex 안에서 pointer만 읽고 mutex를 푼 뒤 raw pointer를 반환한다. 이 pointer에는
  lease나 refcount가 없다.
- `sdpteService::openSpace()`는
  `src/sm/sdp/sdpte/sdpteService.cpp:1627-1652`에서 definition pin을 해제한 뒤
  `mExtent`, `mAutoExtend`, `mBody` raw pointer를 statement context에 보관한다.
  `closeSpace()` (`:1670-1695`)에는 runtime lease release가 없다.
- view도 `src/sm/sdp/sdpte/sdpteViewFacade.cpp:130-145`와 `:251-262`에서 raw
  extent/autoextend pointer를 얻은 후 별도 보호 없이 method를 호출한다.
- file facade도 `src/sm/sdp/sdpte/sdpteFileFacade.cpp:68-82`, `:133-169`에서
  교체 가능한 `mFiles` row와 autoextend owner를 같은 방식으로 사용한다.

#### Failing interleaving

1. View 또는 다른 handler가 `getExtent()`로 old `sdpteExtent *`를 얻고 lifecycle
   mutex를 반환한다.
2. ADD/DROP thread가 bridge lease count 0과 allocation count 0을 확인한다.
3. ADD/DROP thread가 bundle을 swap하고 old extent/autoextend/files를 free한다.
4. 첫 reader가 old pointer로 `getSpaceStats()`, `getFileStats()` 또는 file field를
   읽는다.

Bridge facade를 통한 alloc/free 호출만 새 lease로 보호된다. 위 view/service/file
facade reader는 그 lease count에 포함되지 않으므로 2단계가 이들을 기다리지 않는다.

#### Impact

- concurrent `V$TABLESPACES`/`V$DATAFILES`, ALTER handler, reopen validation 등에서
  heap use-after-free, crash 또는 잘못된 runtime row가 가능하다.
- 설계 13절의 “operation 동안 immutable projection을 pin”한다는 lifetime 계약과
  맞지 않는다.

#### Required direction

교체 가능한 runtime bundle 전체에 snapshot/lease를 두고 모든 reader가 동일한
lease를 사용하거나, raw pointer가 lifecycle mutex 밖으로 나오지 않도록 copy API로
바꿔야 한다. Old bundle은 모든 종류의 reader가 retire한 뒤에만 해제되어야 한다.

### F-02 — Blocker: definition과 runtime file set이 원자적으로 publish되지 않음

#### Evidence

- ADD apply는 `src/sm/sdp/sdpte/sdpteService.cpp:821-829`에서 먼저
  `sdpteServicePublishImage()`를 호출하고, 그 다음 별도 호출로
  `replaceRuntimeFiles()`를 실행한다.
- `publishDefinitionImage()`는
  `src/sm/sdp/sdpte/sdpteModule.cpp:1006-1038`에서 lifecycle mutex를 잡았다가
  완전히 해제한다. `replaceRuntimeFiles()`는 그 뒤 `:1093`에서 mutex를 다시 잡는다.
  따라서 두 호출 사이에 reader가 진입할 수 있다.
- DROP은 더 긴 분리 구간을 만든다. Definition은
  `src/sm/sdp/sdpte/sdpteService.cpp:908-928`에서 먼저 publish되고, component가
  old drains를 `src/sm/sdp/sdpte/sdpteDropTempFile.cpp:680`에서 풀어 준 뒤,
  `sdpteService.cpp:949-980`의 FINISH에서야 runtime을 교체한다.
- drain release는 `sdpteDropTempFile.cpp:454-468`에서 `abortFileDrain()`을 호출해
  target file의 old allocation gate도 다시 연다.
- View는 definition/runtime file count 불일치를
  `src/sm/sdp/sdpte/sdpteView.cpp:503-506`에서 invalid로 판정하고,
  `:582-585`에서 `SDPTE_VIEW_CORRUPT`로 바꾼다. `capture()`의 retry는
  `:650-660`처럼 `STALE_SNAPSHOT`에만 적용된다.

#### Observable states

- ADD: new definition/file count + old runtime arrays.
- DROP: removed-file definition + target file이 아직 포함된 old runtime arrays.
- DROP drain release 뒤 replacement 시작 전에는 new generation을 받은 old bridge가
  다시 열린 target file에 allocation을 허용할 수 있다. 그러면 replacement가
  전체 allocated count를 보고 실패하여 concurrent workload가 DDL을 불필요하게
  rollback시킬 수 있다.

#### Impact

- DDL과 concurrent view가 겹치면 일시적인 내부 오류/`ERR-41082` 계열 결과가
  정상 concurrency 결과가 될 수 있다.
- Definition generation만 같고 file set은 다른 상태가 생겨 generation guard가
  원자성 경계 역할을 하지 못한다.
- 설계 3.3절의 trailing final publication, 9.3절의 “file node/cache를 한 번에
  publish”, 13절의 gate 순서와 맞지 않는다.

#### Required direction

Definition snapshot, runtime bundle, identity generation, `sum(R)`, 그리고 gate 상태를
하나의 lifecycle publication transaction에서 교체해야 한다. DROP target gate는 old
bundle retire가 끝날 때까지 열면 안 된다. Public reader는 old 전체 또는 new 전체만
보아야 한다.

### F-03 — High: ADD/DROP이 tablespace 전체 allocation-free일 때만 성공

#### Evidence

- `replaceRuntimeFiles()`는 새 allocator/body/autoextend를 all-free 상태로 새로 만든다
  (`src/sm/sdp/sdpte/sdpteModule.cpp:1084-1091`).
- 교체 직전 old space의 `mAllocatedExtentCount != 0`이면 파일별 위치와 관계없이
  실패한다 (`:1127-1138`).
- ADD는 항상 이 교체 함수를 호출한다
  (`src/sm/sdp/sdpte/sdpteService.cpp:816-834`). 따라서 기존 파일 하나에라도 live
  extent가 있으면 단순 ADD TEMPFILE이 실패한다.
- DROP prepare는 올바르게 target file만 검사한다
  (`src/sm/sdp/sdpte/sdpteDropTempFile.cpp:319-352`). 그러나 FINISH의 whole-space
  교체 (`sdpteService.cpp:949-975`)가 retained file의 allocation까지 이유로 실패한다.
- 새 unit test는 이 제한을 기대값으로 고정한다
  (`src/sm/unittest/unittestSdpteModule.cpp:674-731`). 이는 safety regression을
  막지만, 설계가 요구하는 DDL 의미를 검증하지 않는다.

#### Design mismatch

- 설계 9.3절 `docs/temp-tablespace-memory-extent-design.md:717-725`는 ADD 준비 중
  기존 allocator가 old immutable projection으로 계속 동작해야 한다고 명시한다.
- 설계 9.4절 `:727-734`는 DROP 시 “해당 file”의 live extent/operation/I/O만
  drain하도록 한다.
- 설계 13절 `:1023-1026`도 ADD는 old allocator를 막지 않고 DROP은 target gate를
  닫는 방향이다.

#### Impact

- TEMP 사용 중인 정상 운영 환경에서 ADD TEMPFILE을 수행할 수 없다.
- 비어 있는 secondary tempfile을 DROP하려 해도 다른 retained file이 사용 중이면
  실패한다.
- 목적 문서의 “allocation-free, quiescent TEMP space가 필요하다”는 제한은 안전성
  설명일 수는 있지만 기본 설계와 SQL 동작을 축소하는 사양 변경이다.

#### Required direction

ADD는 retained file allocator/map/body state를 보존한 채 file directory만 확장해야
한다. DROP은 target file의 gate와 state만 제거하고 retained file의 allocation map과
runtime current를 그대로 승계해야 한다.

### F-04 — High: DROP 뒤 standard `mTotalPageCount`가 `sum(R)`와 달라질 수 있음

#### Evidence

- Generic `SCT_POP_DROP_DBF`는
  `src/sm/sct/sctTableSpaceMgr.cpp:2189-2232`에서 dropped node의
  `mCurrSize`, 즉 `D`만 `mTotalPageCount`에서 뺀다.
- TEMP standard lane은 per-file `SCT_POP_DROP_DBF`만 등록한다
  (`src/sm/sdp/sdpte/sdpteStandardLane.cpp:1143-1165`). 설계가 요구하는 trailing
  `SCT_POP_UPDATE_SPACECACHE`는 ADD/DROP 경로에 없다.
- `replaceRuntimeFiles()`에는 `sddTableSpaceNode *`가 없고 standard
  `mTotalPageCount`를 갱신하지 않는다.

#### Failing case

DROP target file이 runtime AUTOEXTEND로 `Rtarget > Dtarget`가 된 뒤 모든 extent가
FREE이면 DROP precheck는 통과한다. DROP 전 standard total이 설계대로 `sum(R)`라면
generic pending 뒤 값은 다음과 같다.

```text
actual   = sum(R_before) - Dtarget
required = sum(R_before) - Rtarget
drift    = Rtarget - Dtarget
```

현재 focused `addDropTempfile.tc`는 dropped files의 `R == D`인 경우만 확인하므로 이
차이를 발견하지 못한다. Runtime-backed V$ projection은 내부 autoextend total을 읽어
문제를 가릴 수 있지만 standard node 불변식과 그 직접 consumer는 계속 틀린다.

#### Design mismatch

설계 3.3절 `docs/temp-tablespace-memory-extent-design.md:229-238`은 generic D delta가
authority가 아니며 마지막 cache callback이 `sum(R)`를 다시 설정해야 한다고 명시한다.
설계 5.3절 `:383-397`도 OPEN standard node total을 `sum(R)`로 고정한다.

### F-05 — High: publication failure 후 부분 변경이 남을 수 있음

#### Evidence

- `publishDefinitionImage()`는 definition store를 먼저 publish한 뒤
  extent, autoextend, bridge generation을 단락 OR로 순서대로 변경한다
  (`src/sm/sdp/sdpte/sdpteModule.cpp:1012-1035`).
- 중간 update 또는 mutex unlock이 실패하면 함수는 `IDE_FAILURE`를 반환하지만 이미
  publish된 definition/generation을 rollback하지 않는다.
- Caller `sdpteServicePublishImage()`는 module 호출이 성공한 뒤에만
  `mApplied = ID_TRUE`로 만든다
  (`src/sm/sdp/sdpte/sdpteService.cpp:662-668`). 따라서 module이 부분 변경 후
  실패하면 `sdpteServiceRestoreImage()`의 `mApplied` guard (`:690`)가 before image를
  복원하지 않는다.
- `replaceRuntimeFiles()`도 swap 후 lifecycle unlock이 실패하면
  `src/sm/sdp/sdpte/sdpteModule.cpp:1142-1157`에서 live after-image를 유지한 채
  failure를 반환한다. 이 경우 service는 `mRuntimeApplied`를 설정하지 않아 runtime
  rollback 조건도 충족되지 않는다.

#### Impact

처리 가능한 오류가 definition/extent/autoextend/bridge generation 또는
definition/runtime file set의 영구 불일치로 바뀔 수 있다. 현재 fake publication
failure tests는 mutation 전에 실패하는 callback을 사용하므로 이 after-mutation
failure를 검증하지 않는다.

#### Required direction

Publication API는 성공 시 전체 after-image, 실패 시 byte-for-byte before-image라는
strong failure guarantee를 제공해야 한다. 각 내부 update 지점과 post-swap unlock
failure에 대한 fault-injection 검증도 필요하다.

### F-06 — Medium: AUTOEXTEND lock order가 설계의 역순

#### Evidence

- AUTOEXTEND leader는
  `src/sm/sdp/sdpte/sdpteAutoExtend.cpp:502`에서 file `mResizeMutex`를 잡고
  `:626`까지 유지한다.
- 그 상태에서 `:549-562`의 `beginFileIO()/endFileIO()`를 호출한다.
- 두 bridge 함수는
  `src/sm/sdp/sdpte/sdpteStandardNode.cpp:1409`와 `:1447`에서 global
  `sctTableSpaceMgr` latch를 획득한다.

따라서 실제 순서는 `file resize -> global registry`다. 설계 13절
`docs/temp-tablespace-memory-extent-design.md:1012-1021`의 고정 순서
`global registry -> space -> file resize -> allocation`과 반대다.

Standard node를 I/O owner로 사용한 방향은 맞지만, 이 중첩은 다른 lifecycle/DDL
경로가 설계 순서로 확장될 때 deadlock cycle을 만든다. 현재 역방향 acquisition을
제거하거나, pin protocol이 mutex 중첩 없이 같은 descriptor lifetime을 보장하도록
정리해야 한다.

### F-07 — Medium: same-value OR가 inconsistent owner를 no-op으로 처리

#### Evidence

- `sdpteAttributeLane::decideAutoExtend()`의 `mSameValue`는 standard file node의
  ON/NEXT/MAX만 비교한다
  (`src/sm/sdp/sdpte/sdpteAttributeLane.cpp:555-559`).
- Handler는 standard node가 같거나(`mSameValue`), immutable definition이 같으면
  둘 중 하나만 참이어도 성공 no-op으로 끝낸다
  (`src/sm/sdp/sdpte/sdpteHandler.cpp:1289-1296`).
- 그 결과 아래 두 상태가 모두 조용히 성공한다.
  - standard node는 request와 같지만 definition/runtime은 다름
  - definition은 request와 같지만 durable standard node는 다름
- Component의 정확한 no-op 판정은 definition match와 runtime match를 별도로
  검사한다 (`src/sm/sdp/sdpte/sdpteAlterAutoExtend.cpp:284-318`, `:474-484`).
  그러나 handler OR가 이 경로 자체를 건너뛴다.

설계 9.7절 `docs/temp-tablespace-memory-extent-design.md:798-805`은 SERVICE outcome이
standard configured 값과 runtime projection을 함께 갱신하고, “완전히 같은” DDL만
no-op으로 처리하도록 한다. 한 owner만 같은 경우는 no-op이 아니라 reconcile 또는
명시적 invalid-state 처리 대상이어야 한다.

### F-08 — Medium (delivery): tracked diff만으로 test target을 구성할 수 없음

- `src/sm/unittest/Makefile`의 여러 target이
  `unittestSdpteDiskHooks.cpp`를 source로 새로 참조한다. 예:
  `src/sm/unittest/Makefile:73-75`, `:154-156`, `:311-325`.
- 해당 파일은 현재 filesystem에는 있지만 `git status`에서 `??`이며
  `git ls-files --error-unmatch`에 실패한다.

따라서 지금 tracked diff만 commit/review 시스템에 전달하면 필요한 source가 빠져
unit target compile/link가 실패한다. 이 항목은 제품 로직 결함은 아니지만 변경 세트
완결성 측면의 제출 차단 사유다.

## Design-alignment assessment

| Design principle | Assessment | Notes |
|---|---|---|
| 기존 WAL/Anchor와 standard node가 durable definition 소유 | Aligned | 새 custom durable catalog/format은 확인되지 않음 |
| Runtime extent/page state는 boot-local, non-durable | Aligned | 새 allocator replacement도 memory-only임 |
| PID 0/`SM_NULL_PID`를 allocation에서 제외 | Aligned | allocator/bridge/view count가 같은 reservation을 반영함 |
| Ordinary/runtime grow I/O는 standard datafile node owner 사용 | Direction aligned | F-06 lock-order 문제는 별도 해결 필요 |
| Multi-file DROP을 statement 전체 old/new로 publication | Adapter direction aligned | F-01/F-02/F-03 때문에 runtime implementation은 아직 충족하지 못함 |
| ADD 중 old allocator 계속 사용 | Not aligned | F-03: live allocation이 있으면 ADD 실패 |
| DROP은 target file만 gate/drain | Not aligned | F-03: retained-file allocation도 DROP 실패 |
| Public reader는 final old/new projection만 관찰 | Not aligned | F-02: mixed definition/runtime 노출 |
| Runtime object는 reader retire 후 해제 | Not aligned | F-01: bridge lease 외 reader 미보호 |
| OPEN standard total은 `sum(R)` | Not aligned | F-04: R>D target DROP에서 drift |
| 고정 lock order 준수 | Not aligned | F-06 |
| 완전히 같은 AUTOEXTEND만 no-op | Not aligned | F-07 |

## Missing review gates

현재 변경을 수용하기 전 최소한 다음 성질을 검증해야 한다.

1. ADD/DROP replacement와 concurrent V$ capture/service open/file expectation read를
   겹쳐도 old runtime이 조기 free되지 않는다.
2. Definition/file-count/runtime/generation snapshot이 언제나 old 전체 또는 new 전체다.
3. Retained file에 live extent가 있는 상태에서 ADD가 성공하고 allocation이 보존된다.
4. Target file은 비어 있고 retained file은 사용 중인 상태에서 DROP이 성공하며 retained
   allocation이 보존된다.
5. `R>D`인 free target을 DROP한 뒤 standard node와 public projection 모두
   `mTotalPageCount=sum(R)`다.
6. Definition store publish 이후 extent/autoextend/bridge 각 단계 실패와 post-swap
   failure가 before-image를 완전히 보존한다.
7. Standard node만 same, definition/runtime만 same인 두 AUTOEXTEND drift case가
   성공 no-op으로 숨지 않는다.
8. Lock-order assertion 또는 동등한 정적 gate가 `file -> global` acquisition을 거부한다.

## Change-set hygiene notes

- TEMP 변경과 무관한 `ut/iloader3/src/iloFormLexer.cpp`에 1,152-line generated churn이
  섞여 있고 `git diff --check`는 이 파일의 trailing whitespace 4건을 보고한다.
- `altibase_home/arch_logs/.empty`, `altibase_home/dbs/.empty`,
  `altibase_home/logs/.empty`도 삭제 상태다.
- 목적 문서는 이 변경들을 기존 unrelated worktree state로 설명한다. TEMP 리뷰/제출
  범위에서는 별도 change set으로 분리하는 편이 안전하다.

## Review boundary

`DEBUG_FIX_FINDINGS_20260817.md`에 기록된 build, focused SQL, NATC 결과는 실행 이력으로
참고했지만 이번 리뷰에서 재실행하거나 디버깅하지 않았다. 위 finding은 현재 source와
diff, 그리고 설계 문서의 계약을 정적으로 대조한 결과다. 제품 source와 test source는
수정하지 않았다.
