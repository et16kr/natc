# TEMP file-set DDL is broken after a spill (2026-08-20)

> **상태: 순차 file-set DDL 결함은 해결됨 (2026-08-20).** 원인과 수정은
> 아래 "근본 원인과 수정" 절 참고. 전체 suite에서만 재현되는 동시 spill
> FATAL과 CREATING 노드가 남은 discarded tablespace의 DROP 실패는 미해결이다.

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

## 미해결 1: 동시 spill 중 DROP TEMPFILE

위 수정으로 file-set DDL 이 실제로 진행되면서, 그동안 가려져 있던 두 번째 결함이
드러났다. `runtime/concurrency/concurrentSpillWithFileDdl.tc` 는 여전히 FATAL 이다.

대표 로그의 page 값은 22-bit FPID 분할로 다시 확인했다. `FID 0 / FPID 797`이며
primary file 안의 **정상 page 번호**다. 이전의 "무효 page ID" 및
"retired-bundle use-after-free" 단정은 잘못이므로 철회한다.

현재 확인된 현상은 work area가 기억한 page가 file-set DDL 게시 뒤의 runtime `R`
범위 밖에 놓인다는 것이다. 그 page는 primary file이 AUTOEXTEND로 성장한 뒤에만
존재하므로, 현재 가설은 AUTOEXTEND 성장 게시와 file-set DDL 게시 사이의 경합이다.
정확한 ownership 위반 지점은 아직 확정하지 않았다.

순차 DROP 은 정상이다 — `runtime/fileset/dropFilePreservesRuntime.tc` 와
`ddl/tempfile` 14건이 모두 통과한다.

재현은 **실행 순서에 의존한다.** 단독 실행과 `runtime/concurrency` 단독 실행에서는
통과하고, 전체 suite 실행의 뒤쪽(약 77%)에서만 나타난다. 2026-08-19 문서가
`concurrentSpillWithShrink.tc` 에 대해 기록한 "전체 suite FATAL / 단독 PASS" 와
같은 성격이다.

## 미해결 2: 미해소 CREATING 노드를 가진 discarded tablespace 는 drop 되지 않는다

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

기존 실행에서 단계 태깅 로그가 없었던 것은 handler 이전 실패의 증거가 아니다.
DISCARDED/cache-null 공간은 `sdpteHandlerDropTBSNoOwner()`로 진입할 수 있는데,
당시에는 그 lane에 단계 로그가 없었다. 이번 체크포인트는 no-owner lane에도 단계
태깅을 추가했지만 결함 자체는 수정하지 않았다. 다음 재현에서 QP/SM 진입 전인지,
owner-backed handler인지, no-owner handler인지 로그로 다시 분류해야 한다.

## 최종 검증 결과

| | 전체 suite 결과 |
|---|---|
| 2026-08-19 (수정 전) | `PASS 94 / FATAL 1` — suite 가 중단되어 20건 미실행 |
| 2026-08-20 (순차 수정 후 한 실행) | `PASS 132 / FAIL 1 / FATAL 0` — 앞선 crash residue 때문에 concurrency case의 CREATE가 실패 |
| 2026-08-20 (별도 전체 suite 실행) | 약 77%에서 `concurrentSpillWithFileDdl.tc` FATAL |
| 2026-08-20 (`abruptDuringFileDdl.tc` focused) | clean 상태 첫 실행은 모든 불변식 PASS. 즉시 재실행은 종료 시 남은 CREATING/discarded residue 때문에 준비 CREATE가 실패하여 미해결 2를 재현 |

두 결과는 모순이 아니다. 이 case는 단독 실행과 `runtime/concurrency` 단독 suite에서는
통과하고, 전체 suite 뒤쪽에서만 FATAL이 재현된다. FATAL 뒤에 남은 drop 불가
tablespace가 정리되지 않은 다음 실행에서는 같은 case가 CREATE 단계에서 FAIL한다.
따라서 현재 상태를 green full-suite로 해석해서는 안 된다.

해소된 기존 이슈:

- `SAFETY_BINDING_ISSUES_20260819.md` 의 binding FAIL 3건 → 통과
- `CONCURRENT_SPILL_WITH_SHRINK_ISSUE_20260819.md` 의 FATAL → 통과
- `RUNTIME_SORT_HASH_MATRIX_ISSUE_20260819.md` 의 FATAL → 통과
