# TEMP tablespace 최종 diff 코드리뷰

작성일: 2026-08-18

## 검토 방법과 범위

이번 리뷰는 실행이나 디버깅 없이 정적으로만 수행했다.

- 제품 저장소: `altidev4_gi`의 현재 HEAD 대비 TEMP 관련 diff
- NATC 저장소: 현재 HEAD 대비 staged/unstaged diff와 신규 oracle 파일 상태
- 제품 설계: `docs/temp-tablespace-memory-extent-design.md`
- 비교 제외: 사용자가 별도 저장소라고 확인한 `master`

이번 리뷰에서는 NATC/ATC 실행, 서버 재기동, 제품 빌드, 단위 테스트 및 재현 디버깅을 수행하지 않았다.

## 최종 판정

mutex kind 수정과 TEMP rename routing 방향, 완료된 I/O를 누적값처럼 보던 `IOCOUNT` oracle 정리는 타당하다. 그러나 현재 change-set은 아래 BLOCKER/HIGH 항목 때문에 그대로 커밋하거나 병합하기에 안전하지 않다.

## 발견 사항

### 1. BLOCKER: index와 worktree가 서로 다른 테스트를 담고 있음

NATC의 다음 신규 파일은 `AM` 상태다.

- `ddl/tempfile/reattachAfterSpill.tc`
- `runtime/spill/extent64Spill.tc`
- `runtime/spill/runtimeReadback.tc`

현재 index에는 수정 전 버전이 들어 있고 worktree에만 최종 수정이 있다.

- `reattachAfterSpill.tc`
  - index: TEMPFILE 2M × 2, page count 256/512
  - worktree: TEMPFILE 64M × 2, page count 8192/16384
- `extent64Spill.tc`
  - index: 완료 후 `D.IOCOUNT > 0` 조건이 남아 있음
  - worktree: 해당 조건 제거
- `runtimeReadback.tc`
  - index: 완료 후 `D.IOCOUNT > 0`, `D.OPENED = 1` 조건이 남아 있음
  - worktree: 두 조건 제거

그 밖의 focused 수정 TC 대부분은 unstaged 상태이며, 새로 만든 15개 `_A4_64.lst`도 untracked 상태다. 조사 문서 두 개 역시 untracked다. 현재 index만 커밋하면 suite에는 수정 전 신규 TC가 들어가고, 기존 TC의 oracle 수정과 새 `.lst`는 빠진다.

이는 코드 로직 문제가 아니라 change-set 무결성 문제지만, 현재 상태에서는 가장 먼저 해결해야 하는 병합 차단 항목이다. 최종 파일 목록을 확정한 뒤 index를 worktree와 명시적으로 맞춰야 한다.

### 2. HIGH: TEMP rename destination collision 검사가 mutation과 원자적이지 않음

제품 diff는 `smiMediaRecovery::renameDataFile()`에서 destination registry lookup을 TEMP 분기 앞으로 옮기고 source와 target space ID를 분리했다. 순차 실행에서 기존 TEMP/DATA 경로 충돌을 잡는 방향은 맞다.

그러나 검사와 변경 사이에는 latch가 없는 구간이 남는다.

1. `sctTableSpaceMgr::getDataFileNodeByName()`이 registry lock을 잡고 destination을 검사한다.
2. 함수가 lock을 해제하고 반환한다.
3. 이후 `sdpteOperation::alterFileName()`이 호출된다.
4. `sdpteControlLane::renameFile()`이 다시 registry lock을 잡고 `mSetFileName()`을 수행한다.

두 rename 요청이 같은 destination에 대해 1번을 모두 통과하면, 4번의 mutation 시점에는 destination collision을 다시 확인하지 않는다. 현재 NATC는 순차 collision만 검사하므로 이 race를 검출하지 못한다.

설계가 요구하는 registry/config serialization을 만족하려면 destination lookup과 node path mutation을 같은 registry critical section에서 수행하는 atomic rename primitive가 필요하다. 최소한 control lane owner에 destination lookup callback을 제공하고 `mSetFileName()` 직전에 같은 latch 아래서 확인해야 한다.

### 3. HIGH: `dropPathSubstitution.tc`가 DROP의 commit-time 안전성을 검증하지 않음

현재 TC는 DDL 실행 전에 TEMP 경로를 foreign inode로 바꾼 뒤 다음을 기대한다.

- `DROP TABLESPACE ... INCLUDING CONTENTS AND DATAFILES` 실패
- tablespace definition과 두 datafile row 유지
- foreign path 보존

이 시나리오는 `sdpteDropTableSpace::prepare()`의 file preflight 거부만 검증한다. 설계 9.5의 핵심 계약은 prepare가 성공한 뒤 commit/unlink 사이에 path가 바뀌어도 다음이 성립하는 것이다.

- metadata DROP은 commit 상태를 유지
- 바뀐 foreign inode는 unlink하지 않음
- cleanup 실패가 committed DROP을 되돌리지 않음

`unittestSdpteStandardLane.cpp`도 path가 outcome과 unlink 사이에 바뀐 경우 `CLEANUP_PATH_REPLACED`와 DROPPED node를 함께 기대한다. 현재 NATC처럼 substitution을 DDL 전에 완료하면 이 commit-time branch에는 도달하지 않는다.

따라서 현재 TC는 preflight safety 테스트로는 유효할 수 있으나 `T-DDL-04` 전체 또는 post-commit cleanup safety를 검증했다고 설명하면 안 된다. commit-time substitution은 FIT/unit coverage로 별도 유지해야 한다. 또한 다음 두 문서의 설명도 서로 다르다.

- `INVESTIGATION_REVIEW_20260818.md`: metadata DROP commit 및 foreign inode 보존
- `INVESTIGATION_STATUS_20260818.md`: preflight refusal 및 definition 유지

둘 중 하나로 합치는 것이 아니라, preflight scenario와 commit-time scenario를 서로 다른 계약으로 분리해 기록해야 한다.

### 4. MEDIUM: TEMP rename failure의 사용자 오류 계약이 비어 있음

새 경로는 `sdpteOperation::alterFileName()`의 `IDE_FAILURE`를 그대로 상위로 올린다. 그런데 `sdpteHandlerAlterFileName()`은 `sdpteControlLane::renameFile()`의 typed failure를 사용자 오류로 매핑하지 않고 단순히 `IDE_FAILURE`를 반환한다.

destination collision은 바깥 precheck에서 `smERR_ABORT_UseFileInOtherTBS`로 매핑되지만, 다음과 같은 control-lane failure에는 오류가 설정된다는 보장이 없다.

- invalid state/argument
- registry failure
- node mutation failure
- Anchor force failure

새 routing이 이 경로를 production SQL에 연결했으므로, typed result별 오류 매핑 또는 최소한 일관된 fallback 오류가 필요하다. 현재 `renameTempfile.tc`는 CONTROL 명령 출력을 `NODISPLAY`로 숨기고 최종 state만 검사하므로 오류 계약 회귀도 검출하지 않는다.

### 5. MEDIUM: rename negative coverage가 TEMP destination 한 종류뿐임

기존 리뷰는 이미 등록된 DATA path와 TEMP path 양쪽을 negative coverage로 요구했다. 현재 추가된 시나리오는 같은 TEMP tablespace의 첫 번째 TEMPFILE 경로로 두 번째 TEMPFILE을 rename하는 경우만 검사한다.

제품 precheck는 global registry를 사용하므로 DATA collision도 처리할 의도지만, NATC는 이를 고정하지 않는다. 또한 state 불변만 확인하고 기대 오류 코드는 확인하지 않는다.

최소 coverage는 다음을 구분해야 한다.

- TEMP → 동일 tablespace의 TEMP path
- TEMP → 다른 TEMP tablespace의 path
- TEMP → DATA tablespace의 datafile path
- 각 거부 후 source/destination definition과 Anchor가 그대로인지

### 6. MEDIUM: `reject_backup.tc`가 설명한 TEMP-specific guard를 검증하지 않음

TC 설명과 주석은 “TEMP tablespace는 online backup에 들어가지 않는다”를 검증한다고 되어 있다. 그러나 현재 golden output은 세 명령 모두 `ERR-11098` no-archive-log 오류다.

코드 순서는 다음과 같다.

1. `smiBackup::beginBackupTBS()`/`endBackupTBS()`가 archive mode를 먼저 검사
2. archive mode를 통과한 뒤 tablespace manager가 TEMP type을 거부

따라서 현재 TC가 고정하는 것은 다음뿐이다.

- SYSDBA 권한으로 backup path에 진입
- noarchivelog 선행 오류
- 오류 후 public state 불변

TEMP-specific backup guard를 검증하려면 archivelog 환경의 별도 TC가 필요하다. 현재 환경을 유지한다면 case 설명과 design coverage를 noarchivelog precedence/state-preservation으로 바꿔야 한다.

### 7. MEDIUM: 완료 후 `OPENED=1`을 안정적인 oracle로 사용함

다음 현재 TC는 spill query가 끝나고 session을 전환한 뒤 `OPENED=1`을 요구한다.

- `ddl/tempfile/reattachAfterSpill.tc`: 두 TEMPFILE 모두 `OPENED=1`
- `views/runtimeProjection.tc`: runtime file `OPENED=1`

`sdpteView::projectDataFile()`의 계약은 `OPENED`를 standard node의 현재 `mIsOpened`로 그대로 노출한다. 코드 주석도 fully OPEN tablespace의 file을 open-file LRU가 닫을 수 있다고 명시한다. 따라서 completed spill의 증거로 `OPENED=1`을 사용하면 FD/LRU pressure에 따라 golden이 흔들릴 수 있다.

`runtimeProjection.tc`가 `OPENED` column 자체를 시험하려면 descriptor가 열려 있음을 보장하는 deterministic phase에서 sampling해야 한다. `reattachAfterSpill.tc`는 reattached file 사용 여부를 `OPENED` 대신 안정적인 runtime/file 관측값으로 검증하는 편이 낫다.

### 8. MEDIUM: 대표 README와 oracle 문서가 현재 diff와 불일치

staged 상태의 `README.md`와 `ORACLE_REVIEW_20260818.md`는 현재 suite를 다음처럼 설명한다.

- 77 cases
- 64개 `.lst`
- 13 cases list-free
- reorganization 중 test/debug run 없음

현재 root suite 설명은 82 cases이고, focused 수정 대상의 신규 `.lst` 15개가 worktree에 추가되어 있다. `ORACLE_REVIEW_20260818.md`가 list-free라고 기록한 여러 case도 이제 `.lst`가 존재한다. README가 이 문서를 현재 oracle status의 authoritative 문서처럼 링크하므로 신규 독자는 잘못된 상태를 보게 된다.

과거 실행 자료는 삭제할 필요가 없지만 다음 중 하나가 필요하다.

- 문서 제목과 첫 문단에 “2026-08-17/초기 77-case snapshot”임을 명시
- README의 현재 status를 82-case 기준으로 갱신하고 최신 조사 문서로 링크

### 9. DEFERRED: 제외한 non-64 테스트의 `IOCOUNT > 0`

사용자 지시에 따라 다음 세 FATAL은 이번 디버깅 범위에서 제외했다.

- `extent38Spill.tc`
- `extent67Spill.tc`
- `variableExtentSpill.tc`

다만 `extent38Spill.tc`와 `extent67Spill.tc`에는 완료된 query 뒤 `D.IOCOUNT > 0` 조건이 남아 있다. `IOCOUNT`가 in-flight count라는 현재 수정 원칙과 충돌하므로 외부 수정 반영 후에도 별도 FAIL 원인이 된다. 이번 리뷰에서는 사용자 지정 범위를 존중해 수정하지 않고 deferred oracle debt로만 기록한다.

## 유지해도 되는 변경

다음 diff는 정적 코드 계약과 일치한다.

- condition wait에 전달되는 세 mutex를 `IDU_MUTEX_KIND_POSIX`로 변경
  - `sdpteExtent::mConfigMutex`
  - `sdpteAutoExtend::mConfigMutex`
  - `sdpteModule::mLifecycleMutex`
- TEMP `ALTER DATABASE RENAME DATAFILE`을 sdpte control lane으로 routing하는 방향
- destination lookup이 source `sSpaceID`를 덮지 않도록 `sTargetSpaceID`를 분리한 변경
- 완료 후 누적 I/O처럼 사용하던 `IOCOUNT > 0` 조건 제거
- 명확한 create/restart/cache-null phase의 `OPENED=0` 기대
- ordinary CREATE rejection에서 명시적 `REUSE`를 제거한 변경
- `reattachAfterSpill.tc`의 extent size를 512K(64 pages)로 유지하면서 intended DROP/REUSE 단계에 도달하도록 file capacity와 page-count oracle을 함께 조정한 변경

## 권고 순서

1. 최종 intended worktree 파일과 index를 일치시키고 필요한 `.lst`/문서를 명시적으로 포함한다.
2. rename destination collision check를 mutation과 같은 registry critical section으로 옮긴다.
3. rename typed failure의 사용자 오류 매핑과 DATA/TEMP collision coverage를 보완한다.
4. `dropPathSubstitution.tc`를 preflight scenario로 정확히 명명하고, commit-time substitution coverage를 별도로 명시한다.
5. backup TC 설명과 실제 noarchivelog 검증 범위를 일치시킨다.
6. completed spill 뒤의 `OPENED=1` oracle을 deterministic 관측으로 교체하거나 보장 조건을 명확히 한다.
7. README/oracle 문서를 82-case 현재 상태와 historical snapshot으로 구분한다.

## 리뷰 결론

제품 mutex 수정과 TEMP rename routing 자체는 유지할 수 있다. 하지만 현재 상태에서는 index/worktree 불일치가 실제 수정 누락을 만들고, rename collision 원자성 및 일부 NATC oracle/coverage 문제가 남아 있다. 위 BLOCKER와 HIGH 항목을 정리하기 전에는 현 change-set을 최종 병합본으로 판단하기 어렵다.

## 후속 해결 및 재검증

이 절은 위 정적 리뷰 이후의 구현·실행 결과다.

- source 재검증, global destination lookup, node path mutation을 같은 registry mutex 임계구역으로 묶어 rename collision TOCTOU를 제거했다.
- control-lane typed result를 기존 사용자 오류로 매핑하고, lower layer가 오류를 설정하지 않은 실패에는 일관된 fallback 오류를 설정했다.
- `renameTempfile.tc`가 동일 TEMP, 다른 TEMP, DATA destination을 구분해 거부하며 세 결과의 `ERR-11099`를 `.out`에 직접 고정한다.
- `dropPathSubstitution.tc`는 preflight subset으로 명시하고, post-commit path replacement는 `unittestSdpteStandardLane`의 별도 coverage로 기록했다.
- backup 설명은 NOARCHIVELOG 선행 오류와 state preservation 범위로 한정했고, 완료된 spill 뒤의 비결정적 `OPENED=1` oracle을 제거했다.
- 실행 suite는 non-64 future definition 세 건을 `spill.ts`에서 주석 처리해 79 executable cases / 79 non-empty `_A4_64.lst`로 일치시키며, oracle review 문서는 초기 77-case historical snapshot임을 명시한다.
- 최종 `temp_tablespace` TC·문서·검증된 15개 신규 oracle을 같은 index 상태로 맞췄으며, `TC/skip.ts`와 별도 실험/빌드 산출물은 staging에서 제외했다.

검증 결과:

```text
make build -j8                                      PASS
unittestSdpteControlLane                            PASS
unittestSdpteStandardLane                           PASS
unittestSdpteDropTableSpace                         PASS
8개 영향 단위 테스트 target compile                PASS
sdpte_change_surface                                PASS
sdpte_wiring                                        PASS
sdpte_no_durability                                 PASS
sdpte_component_ddl                                 PASS
sdpte_standard_node_io                              PASS
sdpte_allocator_runtime                             PASS
sdpte_concurrency_error                             PASS
sdpte_sql_view                                      PASS
renameTempfile.tc                                   PASS
runtimeProjection.tc                                PASS
reject_backup.tc                                    PASS
dropPathSubstitution.tc                             PASS
reattachAfterSpill.tc                               PASS
```

NATC 다섯 건은 golden 갱신 후 각각 `PASS: 1 FAIL: 0 FATAL: 0 ERROR: 0`으로 재실행했다. 사용자 지정 제외 대상인 `extent38Spill`, `extent67Spill`, `variableExtentSpill`은 이 후속 검증에서도 실행하거나 oracle로 승격하지 않았다.

후속 최소변경 재설계 뒤에는 protected `sctTableSpaceMgr.h/.cpp`를 기준 commit의
byte 상태로 복원하고, 기존 accessor만 조합하는 TEMP callback 안에서 registry
atomic lookup/mutation을 수행했다. stale lookup error는 legacy DATA/UNDO 경로를
바꾸지 않고 새 callback 경계에서만 clear했다. `unittestSdpteEnvironment`가 정상
miss/성공과 node/Anchor failure error 보존을 고정한다.

추가 aggregate 검증 중 발견된 `unittestSdpteDropTempFile` 실패는 제품 DROP body가
아니라 synthetic fixture가 drain을 보유한 retired allocator의 generation을 실제
제품보다 일찍 바꾸던 문제였다. fixture만 실제 publication 모델에 맞춘 뒤
`sdpte_component_ddl`과 `sdpte_standard_node_io`가 통과했다. 마지막 전체 빌드 후
서버를 재기동해 `renameTempfile.tc`를 다시 실행한 결과도
`PASS: 1 FAIL: 0 FATAL: 0 ERROR: 0`이며 output/list가 byte-for-byte 일치했다.
