# TEMP tablespace NATC 조사·해결 방향 리뷰

작성일: 2026-08-18

검토 대상:

- `TC/Server/sm4/Project4/temp_tablespace/INVESTIGATION_STATUS_20260818.md`
- 현재 `altidev4_gi` 제품 변경
- 현재 NATC 테스트 변경 및 `_A4_64.out` 산출물
- `docs/temp-tablespace-memory-extent-design.md`
- Altibase 7.1 SQL Reference와 현재 구현의 동작 계약

## 검토 범위와 결론

사용자 확인에 따라 `master`는 현재 제품 저장소와 다른 저장소이므로 비교하지 않았다. 제외한 non-64 runtime FATAL 3건이 외부 저장소에서 해결되었다는 내용은 사용자 제공 정보로만 취급하며, 현재 저장소에서 해당 수정 여부를 검증하지 않았다.

현재 조사 방향에는 올바른 부분이 있으나 그대로 병합할 수 있는 상태는 아니다. 다음 세 항목은 병합 전에 반드시 바로잡아야 한다.

1. `DROP TEMPFILE` path-substitution 테스트와 그에 따른 제품 변경은 현재 설계 계약과 맞지 않는다.
2. `sddDiskMgr` checkpoint assertion 변경은 TEMP 실패의 원인으로 입증되지 않았고, 보고서에 적힌 recoverable 처리도 실제 호출 구조에서는 성립하지 않는다.
3. TEMP rename routing은 성공 경로를 고쳤지만 destination registry collision 검사를 건너뛴다.

또한 일부 focused 검증 결과는 현재 보존된 `.out`과 일치하지 않으므로, 보고서에서 검증 완료와 수정 후 미실행 상태를 구분해야 한다.

## 중요 발견 사항

### 1. BLOCKER: `DROP TEMPFILE` path-substitution 수정 방향이 잘못됨

일반 `DROP TEMPFILE`은 metadata에서 파일을 제거하지만 물리 파일은 남기는 명령이다.

근거:

- `docs/temp-tablespace-memory-extent-design.md:727-734`
- `src/sm/sdp/sdpte/sdpteHandler.cpp:1228-1235`의 `SMI_ALL_NOTOUCH`
- `src/sm/sdp/sdpte/sdpteStandardLane.cpp:1405-1426`

따라서 등록 경로가 다른 inode로 치환되었다는 이유만으로 다음 명령 자체를 거부해야 한다는 요구는 현재 설계에 없다.

```sql
ALTER TABLESPACE ... DROP TEMPFILE ...;
```

현재 `safety/path/dropPathSubstitution.tc`는 DATA 파일을 TEMPFILE 경로에 복사한 뒤 `DROP TEMPFILE`이 실패해야 한다고 기대한다. 이 기대는 `DROP TEMPFILE`의 metadata-only 의미와 맞지 않을 가능성이 높다.

이에 따라 추가된 다음 제품 변경은 원복하는 것이 타당하다.

- `src/sm/sdp/sdpte/sdpteHandler.cpp:213-256`
- `sdpteHandlerValidateDropFilePath()` 호출부 `:1195-1202`

해당 helper는 header identity를 확인한 직후 pin을 닫고, 이후 별도 단계에서 metadata 변경을 수행한다. 따라서 이 검사를 유지하더라도 검증 후 경로를 다시 치환할 수 있는 TOCTOU가 남는다. 같은 expected header를 복제한 다른 inode도 boot-pinned inode 비교 없이 통과할 수 있다.

Path-substitution 안전성은 `DROP TABLESPACE ... INCLUDING CONTENTS AND DATAFILES`의 touch-mode cleanup으로 검사해야 한다. 올바른 기대는 다음과 같다.

- metadata DROP은 정상적으로 commit된다.
- 치환된 foreign inode는 삭제하지 않는다.
- 소유한 inode는 pre-DDL boot-pinned device/inode와 header identity가 일치할 때만 정리한다.
- identity 검증 실패가 committed DROP을 rollback하지 않는다.

관련 설계 근거:

- `docs/temp-tablespace-memory-extent-design.md:501-514`
- `docs/temp-tablespace-memory-extent-design.md:736-743`
- `docs/temp-tablespace-memory-extent-design.md:1254`

NATC의 `COUNT(D.ID) = 2`를 `COUNT(*) = 2`로 바꾼 변경도 원인이 설명되지 않는다. `D.ID`가 NULL이라면 별도의 projection 문제이므로 기존 검사를 약화시키지 않는 것이 좋다.

### 2. BLOCKER: checkpoint assertion 변경은 TEMP 문제의 해결책이 아님

진행 보고서는 foreign TEMP header 또는 missing TEMP 파일이 checkpoint에서 assertion을 일으킨 것으로 기록했으나, 현재 sdpte TEMP identify 동작은 checkpoint에서 TEMP body/header를 검증하지 않는다.

근거:

- `src/sm/sdd/sddDiskMgr.cpp:5791-5797`
- `docs/temp-tablespace-memory-extent-design.md:968-973`

`sddDiskMgr::identifyDBFilesOfAllTBS()` 내부의 checkpoint assertion을 `IDE_TEST_RAISE`로 바꾸더라도 상위 checkpoint 호출자가 반환값을 다시 `IDE_ASSERT`한다.

- `src/sm/smr/smrRecoveryMgr.cpp:3424-3428`
- `src/sm/smr/smrRecoveryMgr.cpp:3795-3799`

따라서 내부 변경으로 checkpoint 실패가 recoverable해졌다는 설명은 성립하지 않는다. 이 변경은 TEMP에 효과가 없으면서 DATA/UNDO checkpoint invariant의 동작까지 변경한다.

`foreignHeaderReject.tc`의 기존 출력에서도 startup rejection 자체는 이미 성공했다. 실패했던 assertion은 startup 거부가 아니라 restart 후 `OPENED=1` 기대였다. 실제 NATC 변경도 `OPENED=1`을 `OPENED=0`으로 고친 것뿐이다.

권고:

- `src/sm/sdd/sddDiskMgr.cpp`의 checkpoint assertion 변경을 원복한다.
- 별도의 DATA/UNDO checkpoint 재현 사례가 없다면 이 변경을 TEMP 수정으로 포함하지 않는다.
- 보고서의 “확인된 원인 4”를 “원인으로 입증되지 않음”으로 정정한다.

### 3. HIGH: TEMP rename destination collision 검사 누락

TEMP node의 `ALTER DATABASE RENAME DATAFILE`을 `sdpteOperation::alterFileName()`으로 전달하는 방향은 맞다. metadata-only rename 및 immediate Anchor force 계약과 일치한다.

그러나 현재 분기는 다음 순서다.

1. old path node를 찾는다.
2. TEMP이면 `sdpteOperation::alterFileName()`을 호출하고 즉시 return한다.
3. DATA/UNDO 경로에서만 new path registry collision을 검사한다.

근거:

- TEMP 분기: `src/sm/smi/smiMediaRecovery.cpp:616-624`
- destination lookup: `src/sm/smi/smiMediaRecovery.cpp:626-631`

이 구조에서는 new path가 이미 DATA 또는 TEMP node에 등록되어 있어도 TEMP rename이 충돌 검사를 건너뛴다. `makeValidABSPath()`는 canonical path와 directory 접근 권한만 검사하며 registry collision을 검사하지 않는다. `sdpteControlLane::renameFile()`도 destination registry precheck 없이 node path를 변경한다.

설계는 metadata-only rename에서도 기존 canonical path, registry collision, CONTROL phase 검사를 보존하도록 요구한다.

- `docs/temp-tablespace-memory-extent-design.md:820-831`

권고:

- destination registry lookup을 TEMP 분기보다 먼저 수행한다.
- source space ID가 destination lookup으로 덮이지 않도록 별도 target space ID 변수를 사용한다.
- 이미 등록된 DATA path 및 TEMP path로 rename하는 negative NATC를 추가한다.
- multi-pair rename에도 모든 destination precheck가 유지되는지 확인한다.

### 4. HIGH: focused 검증 결과 일부가 현재 `.out`과 불일치

진행 보고서 `:143-159`는 실제 `PASS_*` 출력 기준으로 검증했다고 기록한다. 그러나 현재 파일은 다음 상태다.

#### `extent64Spill.tc`

현재 `_A4_64.out`에는 수정 전 조건인 `D.IOCOUNT > 0`이 남아 있고 결과도 다음과 같다.

```text
PASS_EXTENT_64_SPILL=1
PASS_EXTENT_64_RUNTIME=0
```

따라서 보고서의 “query/projection assertion 통과”는 현재 보존된 산출물로 입증되지 않는다.

#### `runtimeSortHashMatrix.tc`

현재 출력은 수정 전 `D.IOCOUNT > 0` 조건을 포함하며 `PASS_RUNTIME_IO_PROJECTION=0`이다.

#### `runtimeReadback.tc`

현재 출력은 수정 전 `D.IOCOUNT > 0` 조건을 포함하며 `PASS_RUNTIME_REUSE_PROJECTION=0`이다.

#### `multiTempfileSpill.tc`

현재 출력은 정상 결과가 아니라 client connection failure로 종료된다. 앞선 서버 FATAL의 영향을 받은 것으로 보인다.

#### `reattachAfterSpill.tc`

현재 `.tc`는 TEMPFILE을 각각 2M으로 복원했으나 보존된 `.out`은 임시 8M 실험 내용이다. 현재 source와 output이 일치하지 않는다.

권고:

- 보고서에서 위 테스트들을 “oracle 수정 완료, 수정 후 미검증”으로 표시한다.
- 현재 `.tc` 기준 focused 실행으로 `.out`을 다시 생성한다.
- 현재 source와 일치하지 않는 `.out`을 golden 후보로 사용하지 않는다.

### 5. HIGH: `reattachAfterSpill.tc`는 아직 reattach를 실행하지 못함

FATAL은 다음 순서 중 첫 spill query에서 발생한다.

```text
첫 hash spill
→ DROP TEMPFILE
→ ADD TEMPFILE ... REUSE
→ 두 번째 hash spill
```

현재 실패 지점은 `DROP TEMPFILE`보다 앞이므로 아직 DROP 또는 reattach 동작을 검증하지 못했다. 따라서 현 단계에서 이를 reattach 결함으로 분류하면 안 된다.

서버 stack을 symbolicate한 결과는 다음 경로다.

```text
sdtHashModule::append()
→ sdtHashModule::insert()
→ smiTempTable::checkAndDump()
```

관련 source:

- `src/sm/include/sdtHashModule.h:709-742`
- `src/sm/sdt/sdtHashModule.cpp:1216-1284`
- `src/sm/smi/smiTempTable.cpp:291-340`

`checkAndDump`에 전달된 decimal error code `1107296256`은 hex `0x42000000`이며, 이는 `idERR_IGNORE_NoError`다.

- `src/id/ide/ideErrorMgr.cpp:39`

즉 `append()` 또는 그 하위 함수가 error code를 설정하지 않고 `IDE_FAILURE`를 반환한 것이 중요한 단서다. `ERR-42000(errno=11)`의 `errno=11`은 이 상황에서 직접 원인이라고 볼 근거가 없으며 stale errno일 수 있다.

dump의 `WAExtentListCount=8`, `MaxWAExtentCount=6`도 곧바로 비정상이라고 판단하면 안 된다. hash module은 total work area가 부족할 때 `memAllocWAExtent()`로 extent를 추가하고 `mOverAllocCount`를 증가시키는 경로가 있다.

- `src/sm/sdt/sdtHashModule.cpp:4208-4223`
- `src/sm/sdt/sdtWAExtentMgr.cpp:680-708`

다음 조사 방향:

1. DROP/reattach 없이 같은 first-spill workload만 수행하는 baseline TC를 분리한다.
2. `append → allocNewPage → checkExtentTerm4Insert → allocAndAssignNPage/writeNPage`의 각 failure return에서 error code가 설정되는지 확인한다.
3. error code 없이 `IDE_FAILURE`를 반환하는 정확한 edge를 instrumentation 또는 FIT point로 식별한다.
4. baseline spill이 성공한 뒤에만 DROP/REUSE 단계의 검증을 진행한다.
5. 2M과 8M 모두 같은 FATAL이라는 결과는 단순 tempfile capacity 부족 가설을 약화하지만, 아직 test validity나 reattach 동작을 판정하는 근거는 아니다.

### 6. MEDIUM: backup 테스트는 TEMP 전용 거부를 검증하지 못함

`CONNECT SYS/MANAGER AS SYSDBA` 변경은 올바르다. BACKUP SQL을 권한 오류가 아닌 storage path까지 전달하기 위해 필요하다.

그러나 현재 서버는 noarchivelog mode이고 실제 출력은 세 명령 모두 다음 오류다.

```text
ERR-11098: ... cannot be executed in no archive log mode
```

`smiBackup`은 TEMP type 검사보다 archive mode를 먼저 검사한다.

- `src/sm/smi/smiBackup.cpp:356-378`
- `src/sm/smi/smiBackup.cpp:394-420`

TEMP 전용 거부는 더 아래의 tablespace backup path에 있다.

- `src/sm/sct/sctTableSpaceMgr.cpp:3020-3035`

따라서 현재 TC가 입증하는 것은 다음뿐이다.

- SYSDBA session에서 명령이 privilege error 없이 전달된다.
- noarchivelog mode 오류가 먼저 반환된다.
- 거부 후 TEMP public state가 변하지 않는다.

현재 TC만으로 “disk temporary tablespace는 online backup 불가”라는 type-specific guard를 검증했다고 볼 수 없다. SQL Reference의 TEMP backup 금지 계약을 직접 검증하려면 dedicated archivelog 환경 또는 해당 storage guard unit test가 추가로 필요하다.

권고:

- 현재 TC를 noarchivelog first-error/state-preservation 테스트로 재정의하거나,
- 별도 archivelog 테스트에서 TEMP-specific error를 검증한다.

### 7. MEDIUM: 제외된 non-64 테스트에 잘못된 IOCOUNT oracle이 남음

사용자가 디버깅 대상에서 제외한 다음 테스트 중 두 개에는 완료 후 `IOCOUNT > 0` 조건이 남아 있다.

- `runtime/spill/extent38Spill.tc:67`
- `runtime/spill/extent67Spill.tc:67`

`IOCOUNT`는 누적 I/O 횟수가 아니라 현재 in-flight I/O count다. 외부 저장소의 수정이 merge되어 FATAL이 사라지더라도 이 두 테스트는 `IOCOUNT=0` 때문에 FAIL이 될 가능성이 높다.

현재는 사용자 요청대로 FATAL을 디버깅하지 않되, 보고서에는 “외부 수정 merge 후 정리할 oracle debt”로 기록해야 한다.

### 8. LOW: extent inventory 보완 필요

진행 보고서의 핵심 결론은 대체로 맞다.

- non-64 runtime spill:
  - `extent38Spill.tc`: `EXTENTSIZE 304K`, 38 pages
  - `extent67Spill.tc`: `EXTENTSIZE 536K`, 67 pages
  - `variableExtentSpill.tc`: 304K 및 536K
- 위 세 테스트는 사용자 요청으로 현재 디버깅 대상에서 제외한다.
- 나머지 runtime spill 테스트의 explicit extent는 512K, 64 pages다.

다만 DDL inventory에는 다음 테스트도 포함해야 한다.

- `ddl/create/create_extent_1m.tc`: 1M, 128 pages
- `ddl/create/create_extent_256k.tc`: 256K, 32 pages
- `ddl/create/create_catalog.tc`: 512K와 256K catalog projection

SQL Reference에 따르면 EXTENTSIZE를 생략한 기본값은 page size의 64배다.

- `/home/et16/work/manual/Manuals/Altibase_7.1/eng/SQL Reference.md:7717-7723`

## 올바른 방향으로 확인된 변경

### condition variable용 mutex를 POSIX로 변경

다음 세 변경은 제품 결함 수정으로 타당하다.

- `sdpteExtent::mConfigMutex`
- `sdpteAutoExtend::mConfigMutex`
- `sdpteModule::mLifecycleMutex`

`iduMutexEntry::getMutexForCondWait()`는 mutex kind가 POSIX임을 assertion으로 요구한다.

- `src/id/include/iduMutexEntry.h:86-89`

실제 각 mutex는 condition wait/timedwait에 전달되므로 `IDU_MUTEX_KIND_NATIVE`에서 `IDU_MUTEX_KIND_POSIX`로 바꾸는 것이 맞다. `parallelAutoextend.tc`에서 FATAL이 제거된 결과도 이 판단을 지지한다.

### 완료 후 IOCOUNT 조건 제거

다음 테스트에서 완료 후 `IOCOUNT > 0` 또는 `MIN(IOCOUNT) > 0` 조건을 제거한 것은 올바른 oracle 수정이다.

- `multiTempfileSpill.tc`
- `extent64Spill.tc`
- `runtimeSortHashMatrix.tc`
- `runtimeReadback.tc`
- `parallelAutoextend.tc`
- `abruptRuntimeRestart.tc`
- `runtimeProjection.tc`

`IOCOUNT`는 operation 시작 시 증가하고 완료 시 감소하며, 0보다 클 때만 현재 I/O 진행 중임을 뜻한다.

- `src/sm/sdd/sddTableSpace.cpp:2078-2106`

spill 증거는 `CURRSIZE > INITSIZE`, 결과 row count/readback, total page projection 등으로 검증해야 한다.

### 초기 및 restart 직후 OPENED=0 기대

TEMP 생성 직후 또는 startup reconcile 직후에는 operation-local file pin을 닫고 standard datafile node는 ordinary I/O 전까지 열리지 않는다.

- `src/sm/sdp/sdpte/sdpteStartup.cpp:211-217`
- `src/sm/sdp/sdpte/sdpteStartup.cpp:358-380`
- `src/sm/sdp/sdpte/sdpteView.cpp:847-855`

따라서 실제 I/O가 없는 명확한 phase boundary에서 `OPENED=1`을 `OPENED=0`으로 바꾼 것은 맞다. 다만 completed spill 후 `OPENED=1`은 LRU/FD pressure에 따라 닫힐 수 있으므로 테스트가 해당 파일의 open 상태를 반드시 보장하는지 별도로 확인해야 한다.

### createDatafileCrash에서 REUSE 제거

명시적 `REUSE`가 없는 CREATE는 existing target의 header identity가 일치하더라도 already-exists로 거부해야 한다.

- `src/sm/sdp/sdpte/sdpteTarget.cpp:350-358`
- `src/sm/unittest/unittestSdpteTarget.cpp:946-1010`

명시적 authorized `REUSE`일 때만 matching orphan 또는 허용된 non-active target을 adopt한다. 따라서 ordinary CREATE rejection을 검사하려는 `createDatafileCrash.tc`에서 `REUSE`를 제거한 것은 올바르다.

별도로 explicit `REUSE` adoption 성공 TC가 있어야 두 계약을 모두 보존할 수 있다.

### TEMP rename을 sdpte control lane으로 routing

TEMP node의 `ALTER DATABASE RENAME DATAFILE`을 physical validation을 수행하는 일반 DATA 경로가 아니라 metadata-only sdpte lane으로 전달한 방향은 맞다. 단, 앞에서 지적한 destination registry collision precheck를 추가해야 수정이 완성된다.

## `.lst` 및 `.out` 판정

### golden `.lst` 후보

현재 출력에서 모든 case-level `PASS_*`가 1이며, 테스트 변경 방향도 타당한 것은 다음과 같다. 최종 생성 전 현재 `.tc`와 출력 echo가 일치하고 비결정적 내용이 없는지 한 번 더 diff해야 한다.

- `control/createDatafileCrash.tc`
- `control/discardLifecycle.tc`
- `control/renameTempfile.tc`의 positive scenario
- `recovery/crash/abruptRuntimeRestart.tc`
- `recovery/reconcile/foreignHeaderReject.tc`
- `recovery/reconcile/runtimeAnchorBaseline.tc`
- `runtime/concurrency/parallelAutoextend.tc`
- `views/runtimeProjection.tc`

`renameTempfile.tc`의 positive output이 적합하더라도 제품의 collision negative coverage가 충분하다는 뜻은 아니다.

### 현재 golden으로 사용하면 안 되는 출력

- `runtime/spill/extent64Spill_A4_64.out`
  - 수정 전 IOCOUNT 조건과 `PASS_EXTENT_64_RUNTIME=0`
- `runtime/spill/runtimeSortHashMatrix_A4_64.out`
  - 수정 전 IOCOUNT 조건과 projection `0`
- `runtime/spill/runtimeReadback_A4_64.out`
  - 수정 전 IOCOUNT 조건과 projection `0`
- `runtime/spill/multiTempfileSpill_A4_64.out`
  - client connection failure
- `negative/reject_backup_A4_64.out`
  - 상태 검사는 통과하지만 TEMP-specific backup rejection을 검증하지 않음
- `safety/path/dropPathSubstitution_A4_64.out`
  - 테스트 기대와 제품 수정 방향 자체를 재검토해야 함
- `ddl/tempfile/reattachAfterSpill_A4_64.out`
  - FATAL이며 현재 2M source와 다른 8M 실험 출력

### 0-byte `.lst` (review 시점)

검토 당시 다음 파일은 존재하지만 크기가 0이었다.

- `ddl/tempfile/reattachAfterSpill_A4_64.lst`
- `runtime/spill/extent38Spill_A4_64.lst`
- `runtime/spill/variableExtentSpill_A4_64.lst`

이는 유효한 oracle도, 단순한 `.lst` 부재도 아니다. 후속 구현에서 `extent38Spill`과 `variableExtentSpill`의 placeholder는 제거했고, `reattachAfterSpill`은 유효한 64M 조건의 출력으로 재생성했다.

## 권고 작업 순서

1. `sdpteHandlerValidateDropFilePath()` 제품 변경을 원복한다.
2. `dropPathSubstitution.tc`를 `DROP TABLESPACE ... INCLUDING CONTENTS AND DATAFILES` cleanup 보존 시나리오로 다시 설계한다.
3. `sddDiskMgr.cpp` checkpoint assertion 변경을 원복한다.
4. TEMP rename 전에 destination registry collision precheck를 복원하고 negative NATC를 추가한다.
5. 진행 보고서에서 검증 완료, 수정 후 미실행, 사용자 제외 항목을 분리한다.
6. `extent64Spill`, `runtimeSortHashMatrix`, `runtimeReadback`, `multiTempfileSpill`을 현재 source로 focused 재실행한다.
7. `reject_backup.tc`를 noarchivelog precedence 테스트로 재정의하거나 TEMP-specific archivelog coverage를 추가한다.
8. `reattachAfterSpill.tc`의 first-spill workload를 독립 baseline으로 분리한다.
9. hash `append()` failure 중 error code를 설정하지 않는 정확한 return edge를 찾는다.
10. 유효한 output만 `.lst`로 승격한다.
11. 외부 저장소 수정이 merge된 후 제외한 non-64 테스트를 재실행하고 남아 있는 IOCOUNT oracle을 정리한다.
12. 마지막에 전체 `temp_tablespace` suite를 canonical `ALTIBASE_HOME`으로 재실행한다.

## 최종 판정

다음 변경은 유지할 수 있다.

- condition wait mutex의 POSIX 전환
- 완료 후 IOCOUNT 누적값 기대 제거
- 명확한 create/restart phase의 `OPENED=0` 기대
- ordinary CREATE rejection 테스트의 `REUSE` 제거
- TEMP rename의 sdpte metadata lane routing 자체
- backup 테스트의 SYSDBA 연결

다음 변경은 현재 형태로 병합하지 않는다.

- generic checkpoint assertion 완화
- `DROP TEMPFILE` 앞의 short-lived header validation helper
- destination collision precheck가 없는 TEMP rename
- 현재 의미 그대로의 `dropPathSubstitution.tc`
- 검증되지 않은 `.out` 또는 0-byte `.lst`의 golden 승격

## 후속 구현 및 focused 검증 결과

위 권고에 따라 다음 작업을 완료했다.

- `sdpteHandlerValidateDropFilePath()`와 checkpoint assertion 완화는 제품 소스에서 유지하지 않았다.
- TEMP rename의 source 재검증, destination registry collision 검사와 node mutation을 하나의 registry 임계구역으로 묶고 typed failure의 사용자 오류 매핑을 추가했다. NATC는 동일 TEMP, 다른 TEMP, DATA destination 충돌과 `ERR-11099`를 구분해 고정한다.
- `DROP TABLESPACE` path-substitution 테스트는 foreign inode를 보존하는 preflight 시나리오로 재설계했다. prepare 이후의 post-commit path replacement는 `unittestSdpteStandardLane`이 별도로 고정한다.
- 완료 후 `IOCOUNT`를 누적값처럼 검사하던 조건과 초기 또는 완료된 spill 뒤의 비결정적 `OPENED=1` 조건을 정리했다.
- `reattachAfterSpill.tc`는 extent size 512K(64 pages)를 유지하고 TEMPFILE만 64M으로 조정했다. 2M/8M 조건은 동일 first-spill workload에서 capacity 고갈로 reattach 단계에 도달하지 못했으며, 64M 조건에서는 DROP/REUSE 전후 검사가 모두 통과했다.
- `make build -j8`와 `unittestSdpteDropTableSpace`, `unittestSdpteStandardLane`, `unittestSdpteControlLane`가 성공했다.
- focused NATC에서 `createDatafileCrash`, `discardLifecycle`, `renameTempfile`, `reject_backup`, `abruptRuntimeRestart`, `foreignHeaderReject`, `runtimeAnchorBaseline`, `parallelAutoextend`, `multiTempfileSpill`, `extent64Spill`, `runtimeSortHashMatrix`, `runtimeReadback`, `dropPathSubstitution`, `runtimeProjection`, `reattachAfterSpill`의 case-level 검사가 모두 1이었다. 검증된 출력만 `.lst`로 승격했다.
- `extent38Spill`, `extent67Spill`, `variableExtentSpill`은 사용자 지시에 따라 수정·재현·oracle 승격 대상에서 제외했다.

원자성·오류 출력 보완 후에는 `renameTempfile`, `runtimeProjection`, `reject_backup`, `dropPathSubstitution`, `reattachAfterSpill`을 다시 실행했다. 세 destination collision은 `.out`에 `ERR-11099`로 직접 노출되며, golden 갱신 후 다섯 케이스 모두 runner `PASS: 1 FAIL: 0 FATAL: 0 ERROR: 0`이었다.

따라서 review 시점의 “reattach 미해결”과 “수정 후 미검증” 판정은 위 focused 재실행 결과로 갱신된다. 다만 non-64 세 테스트의 외부 수정 merge 후 검증은 여전히 별도 작업이다.
