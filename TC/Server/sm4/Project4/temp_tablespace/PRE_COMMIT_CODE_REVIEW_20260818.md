# TEMP tablespace pre-commit code review

작성일: 2026-08-18

## 최초 리뷰 결론

리뷰 시점의 staged change-set은 **커밋 보류(BLOCKED)** 상태였다. 제품 빌드와 집중
단위/NATC 테스트는 통과했지만, 커밋 전 필수 구조 검사가 새 변경 때문에
실패하고 있으며 실행 suite에도 의도적으로 제외한 미검증 case가 등록되어
있었다.

이번 리뷰에서는 제품 또는 TC 코드를 수정하지 않았다. 아래 문제와 재현
근거만 기록했다.

## 검토 범위

- 제품 저장소 staged 파일 20개
- NATC 저장소 기존 staged 파일 43개와 이 리뷰 문서 1개
- TEMP 설계의 production seam 및 정적 gate
- rename의 registry locking, 오류 전달, 단위/NATC coverage
- 신규 15개 `_A4_64.lst`와 대응 `.out`

## 발견 사항

### 1. BLOCKER: 새 rename 구현이 필수 SDPTE 정적 gate 세 개를 실패시킴

다음 명령은 현재 staged 상태에서 실패한다.

```text
make -C src/sm/unittest sdpte_no_durability_check
make -C src/sm/unittest sdpte_shared_diff_check
make -C src/sm/unittest sdpte_change_surface_check
```

재현된 핵심 위반은 다음과 같다.

```text
src/sm/sdp/sdpte/sdpteStandardNode.cpp:379:
    standard-owner-call: sctTableSpaceMgr::getDataFileNodeByNameLow

src/sm/include/sctTableSpaceMgr.h:
    existing production diff outside the 16.2 seams

src/sm/sct/sctTableSpaceMgr.cpp:
    protected source differs from 0953d614
    DATA/UNDO WAL owner differs from 0953d614

src/sm/smi/smiMediaRecovery.cpp:
    2 TEMP type tests exceed the recorded M-17 budget of 1
```

이는 단순 allowlist 누락으로만 볼 수 없다. 현재 설계와 readiness 문서는
M-17의 RENAME 쪽을 기존 `sddDiskMgr::alterDataFileName()` lane 및 **shared
diff 0**으로 고정하고, `sctTableSpaceMgr.cpp`를 protected source로 지정한다.
반면 staged 구현은 새 public `getDataFileNodeByNameLow()`와 owner callback을
추가하고 `ALTER DATABASE RENAME DATAFILE`의 TEMP branch를 새 control lane으로
보낸다.

권고:

1. 새 atomic rename seam이 실제 요구사항이라면 설계 16.2, cutover manifest,
   owner-call policy, protected-path 근거와 정적 gate를 함께 재승인하고 DATA/UNDO
   불변 증거를 추가한다.
2. 기존 seam 계약을 유지해야 한다면 protected `sct` 변경과 새 direct owner
   call 없이 원자성을 제공하도록 구현을 다시 설계한다.
3. 어느 경우든 gate를 단순 우회하거나 검사 대상에서 제외한 채 커밋하지 않는다.

### 2. HIGH: 정상적인 registry miss가 stale server error를 남김

`sctTableSpaceMgr::getDataFileNodeByNameLow()`은 각 tablespace에서
`sddTableSpace::getPageRangeByName()`을 호출한다. 이 하위 함수는 이름을 찾지
못하면 `smERR_ABORT_NotFoundDataFileNode`를 설정하고 `IDE_FAILURE`를 반환한다.
그러나 새 low-level 함수는 그 failure를 다음 tablespace 탐색을 위한 정상 miss로
취급하고, 최종적으로 대상이 없어도 `IDE_SUCCESS`와 `NULL` node를 반환하면서
오류를 지우지 않는다.

TEMP rename에서 destination이 없는 것은 성공의 필수 조건이므로 모든 정상 rename이
이 stale error를 남길 수 있다. `sdpteHandlerAlterFileName()`은 일부 실패를
`ideGetErrorCode() == 0`일 때만 fallback 오류로 바꾸므로, 이후 callback이 자체
오류를 설정하지 않고 실패하면 실제 원인 대신 이전 lookup의
`NotFoundDataFileNode`가 노출될 수도 있다.

같은 파일의 기존 `sdpteStandardNodeFindFileNodeByName()`은 정상 miss에서
`IDE_CLEAR()`를 호출해 이 계약을 명시적으로 지킨다.

권고:

- expected miss가 오류 공간을 오염시키지 않는 no-exception lookup 계약을
  사용하거나 callback 경계에서 해당 miss를 명시적으로 clear한다.
- 성공 rename 뒤 error code가 0인지, registry/node/Anchor failure가 자신의 오류를
  보존하는지 handler 수준 단위 테스트를 추가한다.

### 3. HIGH: 제외한 non-64 runtime case가 실행 suite에 등록되어 있음

`runtime/spill/spill.ts`에는 아래 세 case가 등록되어 있다.

```text
extent38Spill.tc
extent67Spill.tc
variableExtentSpill.tc
```

세 case에는 `_A4_64.lst`가 없고 README와 조사 문서는 server capability 밖이라
이번 수정에서 실행·수정·oracle 승격하지 않았다고 기록한다. 특히 새
`extent38Spill.tc`와 `extent67Spill.tc`는 spill query가 끝난 뒤에도
`D.IOCOUNT > 0`을 요구한다. 같은 change-set의 다른 TC와 조사 결과는
`IOCOUNT`가 누적값이 아닌 in-flight count이므로 완료 후 0이 정상이라고
확정했다.

따라서 현재 root suite의 “82 cases”에는 실행하지 않은 두 신규 case와 기존
미완료 case가 포함되고, 79/82 oracle 상태로는 aggregate regression을 green으로
판정할 수 없다.

권고:

- 지원이 준비될 때까지 세 case를 executable `.ts`에서 제외하고 future test
  definition으로만 보관하거나,
- 조건을 현재 `IOCOUNT` 계약에 맞게 고친 뒤 세 case를 실제 실행하고 검토된
  `_A4_64.lst`를 함께 추가한다.

### 4. MEDIUM: staged 검증 문서가 현재 gate 결과와 불일치

`DEBUG_FIX_FINDINGS_20260817.md`는 change-surface, shared-diff,
no-durability를 포함한 모든 component gate가 최종 코드에서 통과했다고 기록한다.
`FINAL_DIFF_CODE_REVIEW_20260818.md`의 후속 검증 절도 빌드와 일부 단위/NATC
테스트만 PASS로 기록하며 위 gate 실패를 반영하지 않는다.

권고:

- 1~3번을 해결한 최종 staged 상태에서 전체 gate를 다시 실행한다.
- 실제 최종 명령, exit code와 suite 제외 범위를 두 문서에 갱신한다.

## 통과하거나 정합한 항목

- 제품 `git diff --cached --check`: 통과
- NATC non-`.lst` staged diff check: 통과
- 신규 golden 15개: 대응 `.out`과 byte-for-byte 일치
- 신규 golden의 모든 `PASS_*` 결과: 1
- rename의 source 재검증, destination 조회와 node mutation을 하나의 registry
  critical section으로 묶은 control-lane 순서 자체는 단위 테스트로 확인됨
- `sdpte_binding_check`, `sdpte_wiring_check`, `sdpte_node_owner_check`: 통과

## staged 변경과 무관한 관찰

`sdpte_format_routing_check`는 `src/sm/sdd/sddDataFile.cpp`의 기존 routing
위반으로 실패했지만 해당 파일은 이번 staged diff에 포함되지 않는다. 이번
change-set에서 새로 만든 회귀로 분류하지 않았으며 별도 baseline 정리가 필요하다.

## 커밋 전 최소 종료 조건

1. `sdpte_no_durability_check`, `sdpte_shared_diff_check`,
   `sdpte_change_surface_check`가 승인된 설계와 함께 통과한다.
2. 정상 destination miss 뒤 stale error가 남지 않으며 handler 오류 매핑 테스트가
   이를 고정한다.
3. 38/67-page case를 suite에서 제외하거나 실제 실행·oracle 승격까지 완료한다.
4. staged 검증 문서를 최종 실행 결과와 일치시킨다.

## 후속 해결 및 최종 판정

최초 리뷰의 네 종료 조건은 후속 변경에서 모두 충족했다. 따라서 현재 후속
change-set의 판정은 **커밋 가능(RESOLVED)** 이다.

1. protected `sctTableSpaceMgr.h/.cpp`는 기준 commit의 byte 상태로 복원했다. 새
   public/low-level accessor는 두지 않았고, TEMP rename callback이 기존
   `findSpaceNodeWithoutException()`과 tablespace별 lookup을 registry mutex 안에서
   조합한다. DATA/UNDO rename body는 기존 `sddDiskMgr::alterDataFileName()` 경로를
   유지한다.
2. stale error의 근원은 새 rename에서 처음 생긴 것이 아니다. 기존
   `getDataFileNodeByName()`의 tablespace 순회도 정상 miss에서 하위
   `NotFoundDataFileNode`를 남길 수 있었다. legacy DATA/UNDO 동작은 바꾸지 않고,
   이 동작을 새 callback이 재사용하는 경계에서 expected miss만 `IDE_CLEAR()`하여
   격리했다. handler 테스트는 정상 miss/성공이 no-error를 유지하고 node/Anchor
   failure가 각자 설정한 오류를 보존함을 확인한다.
3. M-17 manifest는 CREATE와 TEMP RENAME 두 branch를 승인하도록 갱신했다. 측정된
   `smiMediaRecovery.cpp` change surface는 `53 additions / 9 deletions`이며,
   `sdpte_change_surface_check`, `sdpte_shared_diff_check`,
   `sdpte_no_durability_check`가 모두 통과한다.
4. `extent38Spill`, `extent67Spill`, `variableExtentSpill`은 future definition으로
   보관하되 `runtime/spill/spill.ts`에서 주석 처리했다. 실행 suite와 non-empty
   oracle 수는 `79 / 79`로 일치한다.
5. 추가 aggregate 실행에서 확인된 `unittestSdpteDropTempFile` FINISH-failure 문제는
   제품 DROP body가 아니라 테스트 fixture가 실제 publication과 달리 drain을 가진
   retired allocator의 generation을 즉시 변경한 문제였다. fixture만 실제
   `sdpteService`의 old-runtime 보존 방식에 맞췄고, 제품/공용 DROP 코드는 바꾸지
   않았다. 이후 `sdpte_component_ddl`과 `sdpte_standard_node_io`가 통과했다.
6. 커밋 직전 문서 리뷰에서 설계 변경 뒤 세 문서의 SHA-256 evidence가 이전 값인
   것을 발견했다. 실제 설계 파일 hash `11f42099…97f580`으로 validation,
   readiness, adapter-map을 함께 갱신했다.
7. 제품 전체 `git diff --cached --check`는 복원된 protected `sct` baseline의 기존
   trailing space 1건과 EOF blank line 1건을 보고한다. 두 파일은 `0953d614`와
   byte-for-byte 일치해야 shared-diff 보호 계약을 만족하므로 정리하지 않았다.
   두 baseline 파일을 제외한 intended staged diff와 NATC staged diff의
   `--check`는 모두 통과한다.

최종 확인 명령과 결과:

```text
make -C src/sm/unittest sdpte_change_surface    PASS
make -C src/sm/unittest sdpte_wiring            PASS
make -C src/sm/unittest sdpte_no_durability     PASS
make -C src/sm/unittest sdpte_component_ddl     PASS
make -C src/sm/unittest sdpte_standard_node_io  PASS
make -C src/sm/unittest sdpte_allocator_runtime PASS
make -C src/sm/unittest sdpte_concurrency_error PASS
make -C src/sm/unittest sdpte_sql_view          PASS
```

`sdpte_no_durability_check`의 최종 계수는 84 files, 1005 external call sites,
128 durable-state files이며, change-surface gate는 11 WAL owners, 14 wrapped
bodies, 16 seam paths, 5 ordered phases를 확인했다. `make build -j8`도 exit 0으로
완료했다. 새 서버 바이너리로 restart한 뒤 `renameTempfile.tc`는
`PASS: 1 FAIL: 0 FATAL: 0 ERROR: 0`이었고, 생성된 `_A4_64.out`은 checked-in
`_A4_64.lst`와 byte-for-byte 일치했다. 세 collision은 모두 `ERR-11099`, 네
`PASS_*` 결과는 모두 1이었다.
