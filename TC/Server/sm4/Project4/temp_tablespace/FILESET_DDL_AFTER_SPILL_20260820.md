# TEMP file-set DDL is broken after a spill (2026-08-20)

> **상태: 순차 file-set DDL, 동시 spill page-I/O FATAL, discarded/CREATING
> DROP 실패를 모두 해결함 (2026-08-21).** 다만 T-03 전체가 끝난 것은 아니다.
> reopen validation, V$ projection, no-exception page reader는 아래에 잔여 범위로
> 분리해 둔다.

## 요약

TEMP tablespace가 한 번이라도 spill을 겪은 뒤에는 그 tablespace에 대한
`ADD TEMPFILE` / `DROP TEMPFILE`이 정상 동작하지 않는다. 세 가지 증상이
같은 뿌리에서 나온다.

| 증상 | 반환 | 의미 |
|---|---|---|
| spill 이후 `ADD TEMPFILE` | `ERR-11034 : Data file node not found ( <새 경로> )` | 등록된 적 없는 자유 경로를 "노드 없음"으로 보고 |
| spill 이후 `DROP TEMPFILE` | `ERR-41082 : Internal server error (mmcStatement::execute code=0x42000000)` | `0x42000000` = `mmERR_IGNORE_NO_ERROR`, 에러코드 미설정 |
| spill 도중 `DROP TEMPFILE` | `ERR-1008d ... Type : 6` 후 FATAL 종료 | 유효한 page가 현재 게시된 runtime 범위 밖에 놓임; AUTOEXTEND와 file-set 게시 경합 추정 |

이 이슈는 `SAFETY_BINDING_ISSUES_20260819.md`가 기록한 `0x42000000`,
`CONCURRENT_SPILL_WITH_SHRINK_ISSUE_20260819.md`가 기록한 FATAL과 같은
서명을 가진다.

## 검증 환경

- 일시: 2026-08-20
- 서버: `/home/et16/work/altidev4/altibase_home`, ALTIBASE hdb 7.1.0.2.4
- 러너: `atsclnt`, `ATC_HOME=/home/et16/work/natc`

## 최소 재현

```sql
CREATE TEMPORARY TABLESPACE T TEMPFILE 't1.dbf' SIZE 4M AUTOEXTEND OFF EXTENTSIZE 512K;
-- 사용자를 T에 바인딩하고 spill 유발 질의를 1회 실행한 뒤

ALTER TABLESPACE T ADD TEMPFILE 't2.dbf' SIZE 8M AUTOEXTEND OFF;
-- [ERR-11034 : Data file node not found ( .../t2.dbf )]

ALTER TABLESPACE T DROP TEMPFILE 't1.dbf';
-- [ERR-41082 : Internal server error (mmcStatement::execute code=0x42000000 )]
```

중간에 `ALTER TABLESPACE T ALTER TEMPFILE 't1.dbf' SIZE 8M;`을 넣어도
상태는 풀리지 않는다.

## 기존 TC에 대한 영향 (회귀)

두 건은 **기록된 oracle이 성공을 기대**하는데 현재 서버에서 실패한다.
oracle은 갱신하지 않았다.

### `runtime/spill/multiTempfileSpill.tc`

```
105c105
< Alter success.
---
> [ERR-41082 : Internal server error (mmcStatement::execute code=0x42000000 )]
112c112
< 1
---
> 0
119c119
< Alter success.
---
> [ERR-11034 : Data file node not found ( .../sdpte_mf_02.dbf )]
```

### `runtime/concurrency/concurrentSpillWithFileDdl.tc`

FATAL로 종료. 서버 로그:

```
[FATAL] ERROR LINE => [ideErrorMgr.cpp:884] MSG[FATAL Error Code Occurred.]
ERR-1008d(errno=11) The data file containing page [391] does not exist.
                    ( Tablespace - ID : 348, Type : 6 )
```

`Type : 6`은 `SMI_DISK_USER_TEMP`다.

**복구 난이도가 높다.** 이 FATAL 이후 서버는 통상 재기동으로 살아나지
못했다. redo 중 `IDE_ASSERT( sCurTrans->mTransID == aTID ), [smxTransMgr.cpp:972]`
(역시 `ERR-42000`)로 다시 죽었고, CONTROL 단계에서 해당 TEMP tablespace를
`DISCARD`한 뒤에야 SERVICE로 진입했다.

## 왜 지금까지 안 잡혔나

`runtime/fileset/addFilePreservesRuntime.tc`는 spill 후 `ADD TEMPFILE`을
하고도 통과한다. 그 tablespace가 `AUTOEXTEND ON`이라 spill이 거절되지 않기
때문이다. 방아쇠는 spill 자체가 아니라 **work-area 거절(ERR-11184)을 겪은
tablespace**이며, 기존 suite에는 거절을 유발하는 케이스가 없었다.

## 이번 작업에서의 처리

- `runtime/exhaust/exhaustThenGrowRecovers.tc` — resize 복구 경로만 남기고
  등록. 통과하며 oracle 확보됨.
- `runtime/exhaust/exhaustThenAddTempfileRecovers.tc` — `ADD TEMPFILE` 복구
  경로. deferred restore 수정 후 `exhaust.ts`에 등록하고 target 실행에서
  oracle을 확보했다.
- `multiTempfileSpill.tc`, `concurrentSpillWithFileDdl.tc` — TC와 oracle을
  변경하지 않았다. 실제 오류를 정상 결과로 기록하지 않는다는 이 suite의
  기존 원칙을 따른다.


## 근본 원인과 수정

### 원인

`sdpteServiceStageRestoreFileSetSnapshot()` 이 만드는 것은 ADD/DROP TEMPFILE 의
**rollback 이미지**다. 이 이미지는 forward 이미지가 적용된 *뒤에만* 실행되지만,
검증은 statement 시점에 수행된다.

검증은 `sdpteModuleValidateRuntimeStateTransfer(candidate -> live)` 를 거쳐
`sdpteExtentCanTransferStateLocked()` 에 도달하고, 거기서 destination 각 행에
대해 다음을 요구했다.

```c
(sdpteExtentAtomicGetULong(&sDestinationFile->mAllocatedExtentCount) != 0) ||
(sDestinationFile->mDirectoryHead != NULL)
```

이 조건은 **forward** 전송에는 옳다. forward 의 destination 은 갓 만든 candidate 라
비어 있어야 한다. 그러나 **restore** 전송의 destination 은 *지금 살아 있는* bundle 이고,
work area 를 한 번이라도 서비스한 공간은 그 시점에 sparse directory 를 보유한다.
그래서 spill 을 한 번이라도 겪은 tablespace 는 이 검증을 통과할 수 없었다.

정리하면 **restore 이미지의 검증이 forward 적용 *이전* 스냅샷을 보고 있었다.**
`mDirectoryHead` 를 비우는 주체가 바로 그 forward 적용이다.

### 수정

- `sdpteExtent::validateDeferredRestoreStateTransfer()` 를 추가했다. identity,
  extent 기하, generation, lifecycle, quiescence 는 그대로 검증하고, forward
  적용이 비워 줄 destination 잔류 조건만 건너뛴다.
- 같은 deferred 규칙을 `sdpteBody::validateDeferredRestoreStateTransfer()` 에
  적용했다. retained-file의 same-boot claim/write witness도 forward가 먼저
  옮긴 뒤 rollback이 되돌려야 하므로 extent와 동일한 시간축을 사용한다.
- `sdpteModuleValidateRuntimeStateTransfer()` 에 `aDeferredRestore` 인자를 추가하고,
  `stageRestoreFileSetSnapshot()` 만 `ID_TRUE` 로 호출한다. forward 호출 3곳은
  종전 그대로다.
- `unittestSdpteModuleLiveFileSetChange` 는 live extent와 body witness를 가진 채
  forward/restore 이미지를 모두 먼저 stage한 뒤 두 교환을 실행하고, 원래
  owner로 동일한 state가 돌아오는 것을 검증한다.

### 잘못된 오류 보고도 함께 고쳤다

`sdpteHandlerCreateFiles()` / `sdpteHandlerDropFiles()` 는 여러 단계에서
`sResult = IDE_FAILURE` 만 세팅하고 오류를 남기지 않았다. 그래서 호출자는 error
stack 에 남아 있던 것을 그대로 보고했다 — 직전 benign lookup 의 잔재(`ERR-11034`)
이거나, stack 이 깨끗하면 `mmERR_IGNORE_NO_ERROR`(`ERR-41082 ... 0x42000000`).

단계 이름을 기록하고, 아무도 오류를 세팅하지 않은 채 실패했을 때만 그 단계를
`smERR_ABORT_INTERNAL_ARG` 로 보고하도록 했다. owner-backed ADD/DROP/TBS DROP뿐
아니라 discarded/cache-null 공간이 사용하는 no-owner DROP lane도 같은 로그를
남긴다.

### 검증

수정 후 NATC 결과(oracle 은 손대지 않음):

| suite | 결과 |
|---|---|
| `runtime/spill` | PASS 7 — `multiTempfileSpill.tc` 가 **원본 oracle 그대로** 통과 |
| `safety` | PASS 5 — 2026-08-19 문서의 binding FAIL 3건이 해소됨 |
| `ddl` | PASS 55 |
| `runtime/fileset` | PASS 3 |
| `views` / `negative` / `regression` | PASS 7 / 16 / 6 |
| `runtime/exhaust` / `runtime/lifecycle` | PASS 3 / 2 |
| `recovery` | PASS 17 |
| `control` | PASS 8 |

## 추가로 찾아 고친 것 2건

### 오류 미설정 경로가 `DROP TABLESPACE` 에도 있었다

`sdpteHandlerDropTBS()` 도 `sdpteHandlerCreateFiles`/`DropFiles` 와 같은 형태로
여러 단계에서 오류 없이 `IDE_FAILURE` 만 돌려주고 있었다. 같은 단계-태깅 처리를
적용했다.

### 복구가 미해결 TEMP 파일 노드에서 멈췄다

`sddTableSpace::calculateFileSizeOfTBS()` 는 복구 직후 tablespace 의
`DataFileCount`/`TotalPageCount` 를 다시 계산하면서 어떤 파일 노드도 전이 중이
아니라고 단정했다.

```c
IDE_DASSERT( SMI_FILE_STATE_IS_NOT_CREATING( sFileNode->mState ) );
```

그런데 `sdpteRecoveryRedoCreateFile()` 은 ADD TEMPFILE 을 redo 하면서 노드를
`SMI_FILE_CREATING` 으로 만들고, 그 해소는 pending operation 에 맡긴다. pending
해소는 이 재계산 **이후**에 일어난다. 그래서 ADD TEMPFILE 도중 서버가 죽으면
재기동이 이 지점에서 중단됐다.

debug build 에서는 assert 로 기동이 죽고, release build 에서는 assert 가 사라지는
대신 **아직 commit 되지 않은 파일의 page 수가 `TotalPageCount` 에 합산된다.** 양쪽
모두 잘못이다.

수정: TEMP tablespace 의 `CREATING` 노드는 `DROPPED` 노드와 똑같이 건너뛴다.
commit 되지 않은 파일은 committed size 에 기여하지 않는다.

이 수정으로, 그전까지 **어떤 방법으로도 기동되지 않던** 데이터베이스가 정상
기동했다.

## 해결: 동시 spill 중 file DDL 이 서버를 죽이던 문제 (2026-08-21)

### 정정

2026-08-20 기록에서 이 FATAL 의 원인을 "은퇴한 runtime bundle 을 reader lease 가
붙들어 성장이 안 보인다"로 적었다. **틀렸다.** 할당자도 페이지 조회도 매번 lease
를 새로 얻는다(`sdpteExtentFacade::allocate`, `sdpteFileFacadeBuildExpectation`).
또 로그의 `page [797]` 은 22bit 로 나누면 `FID 0 / FPID 797` 로, 손상된 값이 아니라
primary file 의 정상 페이지다.

### 실제 원인

ADD/DROP TEMPFILE 이 bundle 을 교체하는 동안 게시자는

```c
sPrivate->mRuntimeReplacementStarted = ID_TRUE;   /* sdpteModule.cpp */
```

로 창을 열고 기존 lease 가 빠지기를 기다린다. 그 창에서 새 lease 는
`SDPTE_RUNTIME_ACQUIRE_REPLACING` 으로 거부된다. 여기까지는 설계대로다.

문제는 **두 소비자가 이 거부를 정반대로 해석**한 것이다.

| 소비자 | 해석 | 결과 |
|---|---|---|
| 할당자 `sdpteExtentFacade::allocate` | `BUSY` → 락 놓고 대기 후 재시도 | 정상 |
| 페이지 조회 `sdpteFileFacadeBuildExpectation` | `ID_FALSE` 로 뭉갬 → "주인 없음" | `sWithinSize=ID_FALSE` → not found → `smERR_FATAL_NotFoundDataFile` → **서버 abort** |

즉 **"지금은 답할 수 없다"가 "그런 페이지는 없다"로 번역**됐다.

### 수정 — typed 결과를 락 밖 재시도까지 전달

| 층 | 파일 | 내용 |
|---|---|---|
| 1 | `sdpteModule.cpp/.h` | `sdpteModuleAcquireRuntimeLocked` 가 거부 이유를 `REPLACING`/`NO_OWNER` 로 구분. **판정 순서는 NO_OWNER 우선** — teardown/unpublished 인 owner 를 `REPLACING` 이라 부르면 성공할 수 없는 재시도로 보내게 된다 |
| 2 | `sdpteFileFacade.cpp/.h` | 이유를 버리지 않고 전달. raw registry 재조회를 버리고 공식 `sdpteModule::acquireRuntimeUnderRegistryLock()` 사용 (설계 3.3.1) |
| 3 | `sddDiskMgr.cpp` | TEMP page-node resolution prefix가 typed facade를 직접 호출한다. `REPLACING`이면 FATAL/IDE 오류를 설정하지 않고, outer helper가 registry mutex를 **놓고** 대기한 뒤 space ID로 node를 재조회한다. 소진 시에만 `smERR_ABORT_NOT_ENOUGH_WORKAREA`를 설정하고 세션 취소/타임아웃 오류는 보존한다. DATA/UNDO는 기존 `sddTableSpace::getDataFileNodeByPageID()`로 그대로 위임하며 public `sddTableSpace` API는 바꾸지 않았다 |

재시도 정책은 검증된 할당자와 동일하다 — 1ms, 최대 10000회.

TEMP ordinary page-I/O 진입점 10곳은 같은 helper로 통일했다. 남은 직접
`getDataFileNodeByPageID` 호출은 non-TEMP만 받는 direct-path/segment 경로다. 이전 시도에서 쓰던
lock-free 헬퍼는 **제거했다**: raw `sddTableSpaceNode*` 를 대기 너머로 보관해
그 사이 DROP 이 노드를 은퇴시키면 수명이 보장되지 않았고, 내부적으로는 이름 그대로
락 보유를 전제한 `buildExpectationUnderRegistryLock()` 을 부르고 있었다.

### T-03 상태 — 부분 해결

**page I/O 경로는 해결**됐다. 그러나 같은 창을 만나는 다른 reader 는 남아 있다.

- `sdpteFileFacade::validateReopenUnderRegistryLock()` — `REPLACING` 을 ordinary
  DATA/UNDO 의 `NO_OWNER` 와 같은 success-skip 으로 처리한다. registry 락 밖 재시도 또는
  reopen 완료까지의 lease 보존이 필요하다.
- `sdpteViewFacade.cpp` — `REPLACING` 을 `SDPTE_VIEW_RUNTIME_ERROR` 로 처리해
  `V$TABLESPACES`/`V$DATAFILES` 가 실패한다. 이 경로는 노드 순회 내내 registry
  락을 쥐므로 안에서 재시도할 수 없고, 값싼 fallback(=committed `D` 로 답하기)은
  같은 파일의 설계 주석이 "stale current 를 runtime 인 것처럼 publish 하게 된다"고
  명시적으로 금지한다. FT 빌더에서 락 밖 재시도로 올려야 한다.
- `getDataFileNodeByPageIDWithoutException()` — `REPLACING` 을 단순 invalid page
  로 처리한다. 유일한 호출처는 `sddDiskMgr::isValidPageID()` 로 FATAL 경로는
  아니지만, 창 안에서 정상 페이지를 invalid 로 보고한다.

따라서 **"concurrentSpillWithFileDdl FATAL 해결"은 맞고, "T-03 종결"로 기록하면
안 된다.**

### 검증의 한계

전체 suite 의 마지막 기록은 `PASS 134 / FAIL 0 / FATAL 0` 이다. 다만 그 NATC 실행은
**재시도 분기가 실제로 실행됐다는 증거가 아니다.** `concurrentSpillWithFileDdl.tc` 는
창을 결정적으로 열지 않으므로 outer crash guard 로만 본다. 대신
`unittestSdpteWiringRegistryLockedReopen()`이 replacement reservation을 직접 열고 facade가
`REPLACING`을 반환하며 IDE 오류를 남기지 않고 owner-missing 통계를 올리지 않는 것을
결정적으로 검증한다. 이 테스트는 원래 boolean collapse를 잡지만, `sddDiskMgr`의 실제
unlock/sleep/relock 반복이나 reopen 경로까지 실행하지는 않는다.

## 해결: 미해소 CREATING 노드를 가진 discarded tablespace 가 drop 되지 않던 문제

위 FATAL 이 남긴 tablespace 는 `DISCARD` 된 상태에서 파일 노드 하나가
`SMI_FILE_CREATING` 으로 남는다. 이 상태의 tablespace 는

```
DROP TABLESPACE t;
DROP TABLESPACE t INCLUDING CONTENTS;
DROP TABLESPACE t INCLUDING CONTENTS AND DATAFILES;
```

셋 다 `ERR-41082 ... code=0x42000000` 으로 실패한다. 정상 재기동을 여러 번 해도
해소되지 않는다. `control/discardLifecycle.tc` 가 규정한 "discarded 공간은 DROP 을
받는다" 계약을 어긴다.

DISCARDED/cache-null DROP은 runtime 없이 standard node에서 committed definition을
유도해야 한다. 수정 후 survey와 collection은 **pure `CREATING`** node만 커밋되지 않은
ADD residue로 함께 제외하고, 남은 stable file들로 no-owner DROP을 진행한다. 제외한
body는 committed evidence가 없으므로 자동 unlink하지 않는다.

이 예외는 모든 unstable node에 적용하지 않는다. `DROPPING`과 `RESIZING`은 작업 전부터
committed definition에 속했던 파일일 수 있고, mixed transient bit도 의미가 모호하다.
이들을 제외해 definition을 만들면 membership 또는 D를 조용히 바꾸므로 계속
`SDPTE_RECONCILE_DEFINITION_ERROR`로 거절한다. `unittestSdpteReconcile`이 stable +
CREATING은 1-file definition으로 유도하고, RESIZING/DROPPING/mixed state는 모두
거절하는 것을 직접 검증한다.

## 최종 검증 결과

| | 전체 suite 결과 |
|---|---|
| 2026-08-19 (수정 전) | `PASS 94 / FATAL 1` — suite 가 중단되어 20건 미실행 |
| 2026-08-20 (순차 수정 후 한 실행) | `PASS 132 / FAIL 1 / FATAL 0` — 앞선 crash residue 때문에 concurrency case의 CREATE가 실패 |
| 2026-08-20 (별도 전체 suite 실행) | 약 77%에서 `concurrentSpillWithFileDdl.tc` FATAL |
| 2026-08-20 (`abruptDuringFileDdl.tc` focused) | clean 상태 첫 실행은 모든 불변식 PASS. 즉시 재실행은 종료 시 남은 CREATING/discarded residue 때문에 준비 CREATE가 실패하여 미해결 2를 재현 |
| 2026-08-21 (typed page lookup + CREATING derive 후 전체 suite) | `PASS 134 / FAIL 0 / FATAL 0` |
| 2026-08-21 (최종 코드로 focused 재검증) | `concurrentSpillWithFileDdl.tc` 1/1, `runtime/concurrency` 4/4, `abruptDuringFileDdl.tc` 1/1, `recovery/reconcile` 6/6 — 모두 FAIL/FATAL 0 |

수정 전 결과들은 모순이 아니었다. 당시 case는 단독 실행과 `runtime/concurrency` 단독
suite에서는 통과했지만 전체 suite 뒤쪽에서만 FATAL이 재현됐고, 그 residue가 다음
실행의 CREATE까지 막았다. 2026-08-21의 green run은 두 증상이 사라진 첫 전체 결과다.
다만 위에 적은 대로 NATC가 REPLACING 재시도 분기 자체를 결정적으로 열지는 않으며,
reopen/V$/no-exception reader는 T-03 잔여 범위다.

해소된 기존 이슈:

- `SAFETY_BINDING_ISSUES_20260819.md` 의 binding FAIL 3건 → 통과
- `CONCURRENT_SPILL_WITH_SHRINK_ISSUE_20260819.md` 의 FATAL → 통과
- `RUNTIME_SORT_HASH_MATRIX_ISSUE_20260819.md` 의 FATAL → 통과
