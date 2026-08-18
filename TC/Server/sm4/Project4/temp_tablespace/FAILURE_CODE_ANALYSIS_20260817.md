# TEMP tablespace NATC FATAL/FAIL 코드 분석

- 분석일: 2026-08-17
- 대상 스위트: `temp_tablespace.ts`
- 최신 결과: `PASS 19 / FAIL 41 / FATAL 2`
- 제품 소스: `/home/et16/work/altidev4_gi`, branch `workspace/simple_temp_tablespace`, commit `8e5eab2540c7`
- 실행 바이너리 소스 트리: `/home/et16/work/altidev4`, 위와 같은 branch/commit

## 1. 분석 범위와 판정 기준

이번 문서는 다음 자료만 사용한 정적 원인 분석이다.

- 각 `.tc`와 최신 `_A4_64.out`
- 현재 branch의 QP/SM 소스와 관련 단위 테스트
- 기존 NATC oracle(`.lst`)의 유무와 크기

테스트 재실행, 서버 로그/코어/콜스택 확인, debugger 부착, 제품 코드 수정은 하지 않았다. 따라서 아래에서 “확정적”이라고 한 것은 **소스의 값과 호출 계약만으로 결과가 결정되는 경우**를 뜻하며, 실제 종료 콜스택을 확인했다는 뜻은 아니다.

41개 FAIL 중 39개는 대응하는 `.lst`가 없고, `unsupportedDdl_A4_64.lst`와 `resize_01_A4_64.lst`는 0 byte이다. 따라서 이 41개는 출력이 기능적으로 옳더라도 NATC 비교상 PASS가 될 수 없다. 아래 분석은 단순한 oracle 부재와 실제 제품/TC 문제를 분리한다.

## 2. 결론 요약

| ID | 우선순위 | 코드로 예상되는 원인 | 영향 테스트 | 신뢰도 |
|---|---:|---|---|---|
| F-01 | P0 | 첫 TEMP 파일 ID 0의 첫 extent가 PID 0을 반환한다. PID 0은 `SM_NULL_PID`이므로 기존 TEMP consumer의 hard assertion에 걸린다. | FATAL 2건 | 매우 높음 |
| D-01 | P0 | definition generation은 증가하지만 module/extent/autoextend runtime generation이 함께 이동하지 않는다. | SIZE, AUTOEXTEND, LOGGING 후 `ERR-41082` | 매우 높음 |
| D-02 | P0 | AUTOEXTEND apply가 계산한 target runtime을 전혀 적용하지 않고 definition만 publish한다. | `auto_02`~`auto_07`, 복합 ALTER | 매우 높음 |
| D-03 | P0 | ADD payload의 `mSpaceID`는 QP가 채우지 않는데 ADD validator는 반드시 일치해야 한다고 검사한다. | 모든 유효 ADD, `restart_03/04` | 매우 높음 |
| D-04 | P0 | ADD/DROP TEMPFILE apply에는 runtime file 배열을 추가/제거하는 동작이 없다. | ADD/DROP 전체 경로의 잠재/후속 오류 | 매우 높음 |
| D-05 | P1 | AUTOEXTEND 동일값 prepare는 operation을 없애고 성공하는데 handler가 NULL operation을 다시 commit한다. | `auto_01`, `auto_06` 첫 문장 | 매우 높음 |
| D-06 | P1 | 한 TEMP owner의 stale generation이 `V$TABLESPACES`/`V$DATAFILES` 전체 fixed-table 생성을 실패시킨다. | 뒤따르는 no-op/reject 검증의 `ERR-41082` | 높음 |
| T-01 | TC | 실패한 ADD가 소비한 file ID는 재사용하지 않는 것이 코드 계약인데 TC는 cursor rewind를 기대한다. | `addDropTempfile` | 매우 높음 |
| T-02 | TC | 이미 기본값인 COMPRESSED LOGGING을 다시 설정해 성공을 기대한다. | `create_08`, 복합 ALTER 일부 | 매우 높음 |
| T-03 | TC | `MAXSIZE == current size`를 성공으로 기대하지만 구현 계약은 `current >= MAX`를 거부한다. | `auto_08` | 매우 높음 |
| T-04 | TC | tablespace-level 문법에서 `ALTER AUTOEXTEND`의 첫 `ALTER`가 빠졌다. | `reject_05` | 매우 높음 |

핵심적으로, FATAL 2건은 autoextend 자체까지 도달하지 못했다. FAIL 다수는 하나의 mutation 이후 definition/runtime 세대가 갈라지고, 그 owner가 이후 fixed-table 조회까지 전역으로 오염시키는 동일 계열이다.

## 3. FATAL 우선 분석

### 3.1 공통 관찰

`runtimeAutoextend.tc`와 `runtimeResizeRestart.tc` 모두 다음 순서까지 정상이다.

1. TEMP tablespace 생성 성공
2. 소스 테이블에 30,000건 적재 성공
3. `/*+ TEMP_TBS_DISK DISTINCT_HASH */`가 붙은 첫 spill 유도 SELECT 시작
4. 해당 SELECT에서 서버 연결이 끊기고 `ERR-50032` 발생

따라서 시작 전 연결 실패가 아니라, 첫 실제 disk TEMP extent 요청이 서버 종료를 유발한 모양이다.

### 3.2 F-01: file 0/page 0과 NULL PID의 충돌

소스만으로 다음 값이 연쇄적으로 결정된다.

1. CREATE 표준 lane은 file cursor를 0에서 시작한다.
   - `src/sm/sdp/sdpte/sdpteStandardLane.cpp:642-666`
2. sparse extent allocator는 가장 낮은 free bit부터 선택하며 첫 extent index는 0이다.
   - `src/sm/sdp/sdpte/sdpteExtent.cpp:690-713`
3. 첫 파일 ID 0, 첫 논리 페이지 0이면 `SD_CREATE_PID(0, 0)`은 정수 0이다.
   - `src/sm/include/smDef.h:340-345`
4. `SD_NULL_PID`와 `SM_NULL_PID`도 모두 정수 0이다.
   - `src/sm/include/smDef.h:340`, `src/sm/include/smDef.h:415`
5. bridge는 이 값이 NULL PID인지 검사하지 않고 정상 descriptor로 복사해 성공을 반환한다.
   - `src/sm/sdp/sdpte/sdpteExtentBridge.cpp:395-416`
6. 기존 TEMP 작업영역 consumer는 성공한 extent의 첫 PID가 `SM_NULL_PID`가 아니어야 한다고 hard assert한다.
   - `src/sm/sdt/sdtWAExtentMgr.cpp:871-876`

즉 실제 값은 다음과 같다.

```text
primary file ID = 0
first extent index = 0
first logical page = 0
SD_CREATE_PID(0, 0) = 0
SM_NULL_PID = 0
=> IDE_ASSERT(mExtFstPID != SM_NULL_PID) 실패 예상
```

두 TC의 `EXTENTSIZE 512K`는 8KB 페이지 기준 64페이지이고, 기존 consumer의 `SDT_WAEXTENT_PAGECOUNT`도 64이다(`src/sm/include/sdtDef.h:82-84`). 따라서 바로 앞의 length assertion보다는 PID assertion이 일치하는 원인이다.

더 강한 정적 증거로, 현재 bridge 단위 테스트가 production primary file ID 0을 사용한 뒤 **성공한 첫 descriptor가 `SD_NULL_PID`라고 명시적으로 기대**한다.

- fixture의 primary file ID 0: `src/sm/unittest/unittestSdpteExtentBridge.cpp:524-557`
- 성공 후 `sFirst.mExtFstPID == SD_NULL_PID` 기대: `src/sm/unittest/unittestSdpteExtentBridge.cpp:620-633`

이 단위 테스트는 bridge 내부 왕복에는 통과하지만, 실제 consumer의 non-NULL 계약과 정면으로 충돌한다. 즉 단위 테스트가 production adapter 경계의 오류를 오히려 정상값으로 고정한 상태다.

### 3.3 FATAL별 판정

| 테스트 | 실제 도달 지점 | 코드상 예상 원인 | 판정 |
|---|---|---|---|
| `runtimeAutoextend.tc` | 첫 `DISTINCT_HASH` spill SELECT | 첫 extent PID가 0이어서 consumer hard assertion | 제품 결함, F-01 |
| `runtimeResizeRestart.tc` | 첫 `DISTINCT_HASH` spill SELECT | 위와 동일 | 제품 결함, F-01 |

`runtimeAutoextend`는 이름과 달리 첫 extent에서 종료될 수 있으므로 실제 AUTOEXTEND growth의 성공/실패를 검증하지 못했다. `runtimeResizeRestart`도 첫 spill에서 종료되어 뒤의 resize, surplus, restart 재사용 단계에는 도달하지 못했다.

## 4. FAIL 공통 원인

### 4.1 D-01/D-02: definition과 runtime generation의 분리

현재 owner에는 서로 일치해야 하는 generation이 최소 세 곳에 있다.

- definition snapshot generation
- module identity generation
- extent/autoextend runtime generation

초기화 시에는 같은 값을 넣는다.

- module: `src/sm/sdp/sdpte/sdpteModule.cpp:640-645`
- extent: `src/sm/sdp/sdpte/sdpteExtent.cpp:1199-1202`
- autoextend: `src/sm/sdp/sdpte/sdpteAutoExtend.cpp:711-714`

그러나 `sdpteModule::publishDefinitionImage()`는 snapshot store에 새 definition만 publish한다(`src/sm/sdp/sdpte/sdpteModule.cpp:851-879`). module identity, extent, autoextend generation을 새 값으로 옮기지 않는다.

각 DDL apply도 다음과 같다.

- ALTER SIZE: definition publish 후 runtime page/capacity만 갱신
  - `src/sm/sdp/sdpte/sdpteService.cpp:844-886`, `:917-942`
  - `publishResizedPages()`는 generation을 바꾸지 않음: `src/sm/sdp/sdpte/sdpteAutoExtend.cpp:1169-1240`
- ALTER AUTOEXTEND: plan에 `mTargetRuntime`이 있지만 apply는 definition만 publish
  - target generation 계산: `src/sm/sdp/sdpte/sdpteAlterAutoExtend.cpp:324-359`
  - plan 전달: `src/sm/sdp/sdpte/sdpteAlterAutoExtend.cpp:500-528`
  - target runtime을 무시하는 apply: `src/sm/sdp/sdpte/sdpteService.cpp:1058-1068`
- LOGGING attribute: definition-only publication이며 runtime action이 없다고 명시
  - `src/sm/sdp/sdpte/sdpteService.cpp:1081-1102`
- ADD/DROP TEMPFILE: apply가 definition image만 publish
  - ADD: `src/sm/sdp/sdpte/sdpteService.cpp:563-605`
  - DROP: `src/sm/sdp/sdpte/sdpteService.cpp:618-649`

반면 view는 generation과 file count가 정확히 같지 않으면 stale snapshot으로 거부한다.

- module identity 대 definition 비교: `src/sm/sdp/sdpte/sdpteViewFacade.cpp:224-257`
- file/space runtime 대 definition 비교: `src/sm/sdp/sdpte/sdpteView.cpp:430-500`

따라서 definition을 실제로 변경한 첫 DDL 직후 `V$TABLESPACES` 또는 `V$DATAFILES`가 `ERR-41082`를 내는 것은 현재 코드와 정확히 일치한다.

### 4.2 D-06: 한 owner가 뒤 테스트의 view까지 실패시키는 이유

`V$DATAFILES` fixed-table builder는 disk tablespace/file을 순회하면서 TEMP row마다 `sdpteViewFacade::projectDataFile()`을 호출하고 하나라도 실패하면 record build 전체를 실패시킨다.

- `src/sm/sdd/sddDiskFT.cpp:285-387`, 특히 `:359-370`

`V$TABLESPACES`도 TEMP row마다 `projectTableSpace()`를 호출하고 실패를 상위로 전달한다.

- `src/sm/sct/sctFT.cpp:427-479`

SQL의 `WHERE NAME = ...`가 특정 테스트 tablespace만 요구하더라도 fixed table row 생성은 그보다 먼저 다른 TEMP owner를 만날 수 있다. 또한 각 TC의 cleanup이 `SKIP` 안에 있어, stale owner 때문에 DROP cleanup까지 실패하면 다음 케이스에 남는다.

이 구조가 다음 현상을 설명한다.

- `resize_01`의 실제 mutation 후 `resize_03`/`resize_08` 같은 no-op 검증도 실패
- AUTOEXTEND/REJECT 테스트가 자기 대상은 변경하지 않았는데 view만 `ERR-41082`
- expected rejection 자체는 정상 error를 냈지만, 바로 다음 “변경되지 않음” SELECT가 내부 오류

따라서 뒤쪽 `ERR-41082`를 모두 해당 TC가 직접 만든 결함으로 해석하면 안 된다. 첫 stale owner가 만든 suite-level 연쇄 영향이 섞여 있다.

### 4.3 D-03/D-04: ADD TEMPFILE 입력 계약과 runtime publication 누락

유효한 ADD가 모두 statement 단계에서 실패하는 가장 직접적인 정적 원인은 `smiDataFileAttr::mSpaceID` 계약 불일치다.

1. QP parser는 ADD/CREATE용 `smiDataFileAttr`의 여러 필드를 설정하지만 `mSpaceID`는 설정하지 않는다.
   - 예: `src/qp/qcp/qcply.y:41837-41893`
2. `qdtAlter::executeAddFile()`은 별도 인자인 tablespace ID와 parser의 file attr 포인터를 그대로 SM에 전달한다.
   - `src/qp/qdt/qdtAlter.cpp:608-680`
3. `smiTableSpace::addDataFile()`도 별도 space ID를 전달할 뿐 각 file attr의 `mSpaceID`를 채우지 않는다.
   - `src/sm/smi/smiTableSpace.cpp:467-485`
4. 신규 `sdpteAddTempFileValidateAttributes()`는 각 file attr의 `mSpaceID`가 current definition의 space ID와 같아야 한다고 요구한다.
   - `src/sm/sdp/sdpte/sdpteAddTempFile.cpp:155-174`

기존 public ADD 인터페이스는 space ID를 별도 인자로 소유하고 있었으므로, 신규 validator가 parser payload의 미설정 필드를 신뢰한 것이 원인으로 예상된다.

또한 handler는 `sdpteAddTempFile::prepare()`의 typed result를 사용자 error로 매핑하지 않고 단순히 성공 여부만 본다(`src/sm/sdp/sdpte/sdpteHandler.cpp:938-1000`). 그래서 출력의 `ERR-11034`는 실제 `SDPTE_ADD_TEMPFILE_INVALID_ATTRIBUTE`를 설명하는 신뢰 가능한 error가 아니다. 이 경로는 새 오류를 설정하지 않아 이전 error stack의 메시지가 노출될 수 있다.

이 입력 검사를 고친 뒤에도 다음 정적 결함이 남는다.

- 새 runtime config는 `mIOFileNode = NULL`로 만들어진다.
  - `src/sm/sdp/sdpte/sdpteAddTempFile.cpp:503-543`
- service prepare는 config/pin 일부만 검사하고 새 파일을 extent/autoextend/module/bridge에 attach하지 않는다.
  - `src/sm/sdp/sdpte/sdpteService.cpp:566-605`
- DROP apply도 definition만 바꾸고 drained runtime file을 owner 배열에서 제거하지 않는다.
  - `src/sm/sdp/sdpte/sdpteService.cpp:622-649`

즉 현재 코드에는 runtime file set을 COW로 추가/제거하고 모든 component generation을 함께 옮기는 publication 단계가 없다.

### 4.4 T-01과 추가 제품 결함: 실패한 ADD의 file-ID gap

ADD handler는 신규 ADD validation 전에 standard lane에서 file ID를 먼저 할당한다.

- handler 순서: `src/sm/sdp/sdpte/sdpteHandler.cpp:938-975`
- standard cursor는 `mNewFileID++`: `src/sm/sdd/sddTableSpace.cpp:1794-1805`

실패 rollback은 cursor를 의도적으로 되감지 않는다.

- `src/sm/sdp/sdpte/sdpteStandardLane.cpp:356-366`

따라서 2-file ADD가 실패하면 기존 `NEXT_FILE_ID=1`이 3이 되는 것이 코드 계약이다. `addDropTempfile.tc`의 `PASS_FAILED_ADD_ATOMIC`은 1로 되돌아가야 한다고 기대하므로 TC 기대값이 틀렸다.

동시에 제품 쪽 projection도 gap을 끝까지 처리하지 못한다. 다음 ADD가 실제 standard cursor에서 ID 3, 4를 받더라도 `appendFiles()`는 current definition의 `mNextFileID=1`과 `+ fileCount`로 상한 3을 만들어 ID 3부터 거부한다.

- assigned ID 검사: `src/sm/sdp/sdpte/sdpteProjection.cpp:154-200`
- 잘못된 상한 구성: `src/sm/sdp/sdpte/sdpteProjection.cpp:425-466`

즉 다음 두 항목을 분리해야 한다.

- TC 문제: 실패한 ID의 재사용/rewind를 기대함
- 제품 문제: non-reuse 계약으로 생긴 합법적인 ID gap을 다음 projection이 수용하지 못함

### 4.5 D-05: AUTOEXTEND 동일값 no-op과 NULL operation

AUTOEXTEND prepare는 definition과 runtime이 이미 요청값과 같으면 publication을 finish하고 operation을 파괴한 뒤 성공을 반환한다.

- `src/sm/sdp/sdpte/sdpteAlterAutoExtend.cpp:474-484`

그러나 handler는 prepare 성공 후 standard attribute lane을 수행하고, `sResult == IDE_SUCCESS`이면 operation이 NULL인지 확인하지 않고 무조건 commit한다.

- `src/sm/sdp/sdpte/sdpteHandler.cpp:1209-1238`

`commit(NULL)`은 INVALID_STATE를 반환하므로 사용자에게는 구체 error가 없는 internal error가 된다. 이것이 `auto_01`과 `auto_06`의 첫 `AUTOEXTEND OFF`에 직접 대응한다.

### 4.6 TC/oracle 계약 불일치

#### COMPRESSED LOGGING 동일값

기본 attribute bit 0은 COMPRESSED LOGGING을 뜻하며 주석도 이를 기본값으로 명시한다.

- `src/sm/include/smiDef.h:730-742`

따라서 CREATE 직후 다시 `COMPRESSED LOGGING`을 실행하면 `ERR-11115`가 나는 현재 동작이 일관된다. `create_08`의 최종 `PASS_CREATE_08=1`은 상태가 이미 맞음을 확인한다.

#### MAXSIZE가 현재 크기와 같은 경우

AUTOEXTEND validation은 `runtime current >= MAX`를 거부한다.

- `src/sm/sdp/sdpte/sdpteAttributeLane.cpp:525-529`
- `src/sm/sdp/sdpte/sdpteAlterAutoExtend.cpp:243-250`

따라서 8M 파일에 `MAXSIZE 8M`을 주는 `auto_08`은 현재 코드 계약상 정상 거부다. TC가 성공을 기대한다면 TC 기대값 변경이 필요하다. 단, error 문구의 “less than”과 실제 `>=` 조건의 표현 일치 여부는 별도 제품 검토 대상이다.

#### reject_05 문법

`reject_05.tc`는 다음과 같이 작성되어 parser error `ERR-31001`에서 끝난다.

```sql
ALTER TABLESPACE SDPTE_REJ05 AUTOEXTEND ON ...;
```

tablespace-level semantic rejection을 시험하려면 동일 스위트의 `unsupportedDdl.tc`처럼 `ALTER TABLESPACE ... ALTER AUTOEXTEND ...`여야 한다. 현재 TC는 intended semantic handler까지 도달하지 않는다.

## 5. FAIL 41건 개별 판정

### 5.1 복합/안전성 테스트

| 테스트 | 출력 해석 | 코드상 예상 원인 | 분류 |
|---|---|---|---|
| `addDropTempfile` | 두 ADD 실패, 네 PASS 값 모두 0/내부 오류 | 미설정 `mSpaceID` 검사(D-03), 실패 ID rewind를 기대한 TC(T-01), gap을 못 받는 projection, runtime ADD/DROP 누락(D-04)이 겹침 | 제품+TC 복합, oracle 생성 금지 |
| `alterSizeAutoextend` | 첫 SIZE 16M은 성공, 즉시 view 내부 오류. 후속 SIZE/AUTO/LOGGING이 연쇄 실패 | 첫 SIZE가 definition generation만 전진시켜 owner를 stale로 만듦(D-01). AUTO target runtime 미적용(D-02). COMPRESSED는 이미 기본값 | 제품 결함 중심 |
| `dropReuse` | REUSE 없는 재생성은 예상대로 거부, 명시적 REUSE 성공, 두 PASS 값 1 | DROP TABLESPACE/REUSE 안전성 동작은 출력상 정상 | oracle 부재만으로 FAIL |
| `activeDataAliasReuse` | 4개 alias 시도 거부, 검증 5개 모두 1 | active DATA inode/path alias 차단 정상 | oracle 부재만으로 FAIL |
| `activeTempAliasReuse` | 4개 alias 시도 거부, 검증 5개 모두 1 | active TEMP inode/path alias 차단 정상 | oracle 부재만으로 FAIL |
| `unsupportedDdl` | intended rejection 후 `PASS_REJECTIONS_UNCHANGED=1` | 대부분 정상 expected error. 단 primary tempfile DROP은 소스상 `CannotRemoveDataFileNode`로 매핑해야 하는데 실제 `ERR-41082`여서 error 경로가 일치하지 않음 | 기능 상태 정상, internal error는 oracle로 승인 금지 |
| `create_08` | 동일값 COMPRESSED가 `ERR-11115`, 최종 PASS=1 | 기본이 이미 COMPRESSED(T-02) | TC 의도 명확화 후 expected-error oracle 가능 |

`unsupportedDdl`의 primary file 경로에서 소스는 `SDPTE_DROP_TEMPFILE_PRIMARY_FILE`을 반환하고(`src/sm/sdp/sdpte/sdpteDropTempFile.cpp:215-239`), handler는 이를 기존 “data file is in use” 오류로 매핑한다(`src/sm/sdp/sdpte/sdpteHandler.cpp:184-202`). 실제 `ERR-41082`는 이 정적 경로와 다르다. 디버깅 없이 어느 중간 result로 이탈했는지는 확정하지 않지만, internal error를 정상 모범답안으로 삼아서는 안 된다.

### 5.2 RESIZE 8건

| 테스트 | 자체 동작 분석 | 현재 view 실패 해석 |
|---|---|---|
| `resize_01` | 8M→16M 실제 grow. definition/runtime generation 분리(D-01) | 직접 결함 |
| `resize_02` | 16M→4M 실제 shrink. generation 분리 | 직접 결함 |
| `resize_03` | 8M→8M no-op이며 after image를 만들지 않는 코드 경로 | 앞서 남은 stale owner의 fixed-table 연쇄 영향 가능성이 높음 |
| `resize_04` | 8M→1M 실제 shrink | 직접 결함 |
| `resize_05` | 8M→2M 실제 shrink | 직접 결함 |
| `resize_06` | 첫 8M→16M이 owner를 stale로 만든 뒤 두 번째 16M→4M이 내부 오류 | 첫 mutation의 직접 결함+후속 연쇄 |
| `resize_07` | 8M→16M 실제 grow | 직접 결함 |
| `resize_08` | 8M→8M no-op | 앞서 남은 stale owner의 fixed-table 연쇄 영향 가능성이 높음 |

SIZE after-image는 실제 값이 바뀔 때만 generation을 증가시킨다(`src/sm/sdp/sdpte/sdpteAlterSize.cpp:380-444`). 따라서 `resize_03/08`을 mutation 결함으로 묶기보다는 suite 오염을 분리하는 것이 맞다.

### 5.3 AUTOEXTEND 8건

| 테스트 | 자체 동작 분석 | 분류 |
|---|---|---|
| `auto_01` | OFF→OFF no-op prepare가 operation을 없앤 뒤 handler가 NULL commit | D-05 직접 결함 |
| `auto_02` | OFF→ON, NEXT 2M/MAX 32M. definition만 바뀌고 runtime config/gen은 그대로 | D-01/D-02 직접 결함 |
| `auto_03` | OFF→ON, MAX 16M | D-01/D-02 직접 결함 |
| `auto_04` | OFF→ON, UNLIMITED normalization | D-01/D-02 직접 결함 |
| `auto_05` | 첫 변경은 성공하지만 runtime 미적용. 같은 값의 두 번째 ALTER가 불일치 상태에서 내부 오류 | D-01/D-02 후속 결함 |
| `auto_06` | 첫 OFF→OFF는 NULL commit 오류, 뒤 ON 변경은 definition만 갱신 | D-05와 D-01/D-02 복합 |
| `auto_07` | OFF→ON, NEXT/MAX 변경 | D-01/D-02 직접 결함 |
| `auto_08` | MAX 8M == current 8M이 구현 계약상 정상 거부. 뒤 view는 앞 stale owner의 영향 | TC 기대값(T-03)+suite 연쇄 |

### 5.4 ADD/DROP 8건

| 테스트 | 첫 실패 원인 | 후속 출력 해석 |
|---|---|---|
| `adddrop_01` | 유효 ADD가 미설정 `mSpaceID` 검사에서 거부 예상 | DATAFILE_COUNT 2 검증은 실패하며 view는 suite stale 영향 |
| `adddrop_02` | 위와 동일 | AUTOEXTEND 옵션과 무관하게 ADD 입구에서 실패 |
| `adddrop_03` | 두 파일 모두 같은 입력 계약 문제 | 3-file 기대에 도달하지 못함 |
| `adddrop_04` | ADD 실패 | 뒤 DROP은 등록되지 않은 파일을 대상으로 하며 결과는 2차 오류 |
| `adddrop_05` | multi ADD 실패 | multi DROP도 2차 오류 |
| `adddrop_06` | ADD 실패 | 새 파일 RESIZE가 `ERR-311D9 File not found`인 것은 직접적인 후속 결과 |
| `adddrop_07` | ADD 실패 | 새 파일 AUTOEXTEND가 `ERR-311D9`인 것은 직접적인 후속 결과 |
| `adddrop_08` | 첫 ADD 실패 | DROP 및 같은 경로 REUSE는 선행 ADD 부재에 따른 2차 결과 |

이 8건은 현재 출력으로 ADD runtime publication 이후의 세부 동작을 검증한 것이 아니다. 모두 ADD 입구에서 막혔다. D-03을 고친 후에는 D-04의 runtime file set publication도 반드시 함께 검증해야 한다.

### 5.5 REJECT 8건

| 테스트 | rejection 자체 | 뒤 `ERR-41082` 해석 |
|---|---|---|
| `reject_01` | TEMP tablespace OFFLINE을 `ERR-311E7`로 정상 거부 | 선행 stale owner의 fixed-table 오염 |
| `reject_02` | TEMP tablespace ONLINE을 `ERR-311E7`로 정상 거부 | 동일 |
| `reject_03` | TEMPFILE OFFLINE을 `ERR-41088`로 거부 | 동일 |
| `reject_04` | TEMPFILE ONLINE을 `ERR-41088`로 거부 | 동일 |
| `reject_05` | parser `ERR-31001`; intended semantic rejection에 도달하지 않음 | TC 문법 오류+동일 |
| `reject_06` | TEMP에 `ALTER DATAFILE`을 사용해 `ERR-311DA` 정상 거부 | 동일 |
| `reject_07` | primary TEMPFILE DROP이 internal error | 소스가 의도한 typed user error와 불일치; 별도 제품 error-path 문제 |
| `reject_08` | MAX 2M < current 8M을 `ERR-1101F`로 정상 거부 | 동일 |

REJECT TC는 rejection 이후 대상 상태가 변하지 않았음을 view로 확인하려 했으나, suite 전역의 stale owner 때문에 그 확인 SELECT가 실행되지 못했다. rejection 자체와 검증 SELECT 실패를 분리해야 한다.

### 5.6 RESTART 2건

| 테스트 | 출력 해석 | 원인 |
|---|---|---|
| `restart_03` | ADD 실패 후 두 번째 파일을 지우고 restart. 재기동 후 DATAFILE_COUNT=1이라 PASS=0 | restart 결함이 아니라 선행 ADD가 definition에 들어가지 않은 결과 |
| `restart_04` | ADD 실패 후 restart. 재기동 후 DATAFILE_COUNT=1이라 PASS=0 | 위와 동일 |

두 테스트 모두 server stop/start와 재접속은 완료됐다. 따라서 현재 출력은 ADD 실패의 restart 후 지속성을 보여 줄 뿐, “성공한 2-file definition의 restart 복원”은 시험하지 못했다.

## 6. oracle 작성 여부 권고

현재 출력 그대로 `.lst`로 승인해도 되는 후보는 다음 3건이다.

- `dropReuse`
- `activeDataAliasReuse`
- `activeTempAliasReuse`

`create_08`은 “이미 기본값인 COMPRESSED를 다시 지정했을 때 expected error”를 의도한 것인지 TC 설명을 명확히 한 뒤 oracle로 만들 수 있다.

다음 출력은 모범답안으로 고정하면 안 된다.

- 두 FATAL의 연결 끊김
- 모든 `ERR-41082 Internal server error`
- ADD 유효 문장의 `ERR-11034`
- `auto_01/06`의 no-op internal error
- `reject_05`의 parser error를 semantic rejection으로 간주한 결과
- `reject_07`/`unsupportedDdl` primary DROP의 internal error

`unsupportedDdl_A4_64.lst`와 `resize_01_A4_64.lst`의 0-byte 파일도 유효 oracle이 아니다.

## 7. 코드 수정 우선순위 제안

1. **P0 — PID 0 충돌 해결**
   - allocator가 file 0/logical page 0을 legacy PID로 반환하지 않도록 reservation/offset 계약을 정하고, bridge unit test가 non-NULL PID와 실제 consumer 계약을 검증하도록 변경해야 한다.
2. **P0 — mutation publication을 하나의 coherent runtime generation으로 완성**
   - module identity, extent, autoextend, bridge, file set과 definition을 같은 generation으로 원자적으로 옮기는 API가 필요하다.
   - AUTOEXTEND의 target runtime 적용, SIZE의 generation rekey, logging-only generation rekey가 각각 빠져 있다.
3. **P0 — ADD 입력 계약 수정**
   - 별도 `aSpaceID`를 authoritative 값으로 쓰거나 handler에서 file attr을 정규화하고, parser가 채우지 않는 `mSpaceID`를 validator가 직접 신뢰하지 않아야 한다.
4. **P0 — ADD/DROP runtime file-set COW 구현**
   - extent/autoextend/module/bridge의 file 배열 추가/제거와 IO node ownership을 definition publication과 함께 처리해야 한다.
5. **P1 — handler no-op/error mapping 정리**
   - prepare가 성공하면서 NULL operation을 반환하는 계약을 handler가 처리하고, ADD/DROP typed failure마다 실제 원인을 사용자 error로 매핑해야 한다.
6. **P1 — TC 수정**
   - `addDropTempfile`의 non-reuse file-ID 기대값, `reject_05` 문법, `auto_08` 계약, `create_08` expected-error 의도를 바로잡은 뒤 oracle을 생성해야 한다.

## 8. 최종 판정

- FATAL 2건은 같은 **PID 0/NULL PID 경계 결함**으로 예상되며 신뢰도가 매우 높다.
- FAIL 중 실제 제품 문제의 중심은 **definition/runtime publication 불완전**, **ADD payload 계약 불일치**, **runtime file set 갱신 누락**, **AUTOEXTEND no-op handler 오류**다.
- 다수의 후속 `ERR-41082`는 각 TC의 독립 결함이 아니라, 앞서 남은 stale TEMP owner가 fixed-table 전체 scan을 실패시킨 연쇄 영향이다.
- `dropReuse`와 두 alias 안전성 TC는 출력상 정상이며 oracle 부재만으로 FAIL이다.
- 이번 분석에서는 원인 확인을 위한 재실행이나 디버깅을 하지 않았다.
