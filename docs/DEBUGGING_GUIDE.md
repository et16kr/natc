# AI Coding Agent TC Debug Brief

이 문서는 AI coding agent에게 실패하거나 `ERROR`가 나는 ATAF `.tc`/`.ts`
디버깅을 요청할 때 필요한 정보와 처리 기준만 정리한다.

일회성 조사 문서는 필요한 경우에만 `docs/debug/<case-name>.md`처럼
테스트 케이스 이름으로 만들고, 아래 항목만 남긴다. 해결 후 사용자가
원하지 않으면 삭제한다.

## First Reproduction

항상 사용자가 준 명령을 먼저 실행해서 현재 실패를 확인한다.

기록할 정보:

- 실행 명령과 exit code.
- 실행 시각과 작업 디렉터리.
- 주요 환경 변수: `ATAF_TEST_CASE`, `ATAF_TEST_RESULT`, `ATC_HOME`,
  `ATC_WORK`, `ALTIBASE_HOME`, `LANG`, `ATAF_RESULT_SUFFIX`.
- 사용된 runner path: `atsclnt`, `atsc`, `ntiRunTest`, `altibase`, `is`.
- stdout의 PASS/FAIL/ERROR/FATAL/HANG 요약.
- `work/log/report.log`, `work/log/debug.log`, `work/log/lstout.log`,
  `work/log/error.log`, `work/log/exception.log` 중 의미 있는 내용.

실행 후 남은 `atsclnt`, `ntiRunTest`, 대상 TC 관련 프로세스가 있는지
확인한다. 내가 실행한 프로세스만 정리하고, 기존 서버/타 사용자 프로세스는
건드리지 않는다.

## FAIL Handling

`FAIL`은 TC가 실행됐고 `.lst`와 `.out` 비교가 실패한 상태다. 먼저 oracle
차이인지 실제 서버/SQL 동작 차이인지 분리한다.

확인할 정보:

- 실패한 `.tc` path.
- 대응하는 expected `.lst`와 generated `.out` path.
- expected `.lst`가 없는지 여부. 이 경우 `work/log/lstout.log`에 보통
  expected path와 generated `.out` path가 같이 남는다.
- `diff -u <lst> <out>`의 핵심 차이.
- 차이가 공백, 프롬프트, trailing blank line, SQL formatting transcript
  같은 oracle-only 변화인지 여부.
- 결과 row 수, 에러 코드, SQL 결과값, 정렬 순서, plan-dependent output이
  달라졌는지 여부.

처리 기준:

- 공백이나 transcript formatting만 다르고 SQL 결과가 정상이라면 `.out`으로
  `.lst`를 갱신한 뒤 같은 명령으로 재실행한다.
- 새 TC에서 expected `.lst`가 없어 FAIL인 경우는 runner/SQL 실패가 아니라
  oracle artifact 미완성으로 본다. 단, generated `.out`에 SQL error,
  crash, hang, 의도하지 않은 row/result 차이가 있으면 `.lst`로 승격하지
  않는다.
- 결과값, row 수, 에러 코드, crash, hang이 다르면 `.lst`를 덮어쓰지 않고
  서버/SQL 문제로 본다.
- 한 runner wrapper가 환경 문제로 실행 전 실패하면 사용자가 지정한 runner
  path로 재현한다. 예를 들어 `bin/atc`가 Perl 모듈 로딩 문제로 실패해도
  `atsclnt` 실행 결과는 별도로 확인한다.
- 서버 문제로 보이면 서버 소스와 빌드 위치는 `$HOME/work/altidev4`를 우선
  사용한다. 이때 TC 입력 SQL, schema/data setup, 서버 로그, core 여부,
  `altibase -v`, 관련 properties를 같이 기록한다.

## ERROR Handling

`ERROR`는 보통 TC runner가 SQL 실행 전 또는 실행 중 제어 문법을 처리하다
중단한 상태다. 이 경우 `.lst` 갱신을 먼저 하지 않는다.

우선 확인할 정보:

- `work/log/debug.log`의 `PARSE ERROR`, syntax error, missing file,
  invalid command, timeout/error line.
- 에러가 가리키는 `.tc` line 주변 20-40줄.
- `.tc` 전체 크기와 에러 statement 크기.
- include file 존재 여부와 `.ts` path가 상대 경로로 맞는지 여부.
- `SET_ENV`, `UNSET_ENV`, `SHELL`, `EXEC`, `THREAD`, `JOIN`, external file
  사용 여부.

처리 기준:

- TC 문법/파서 오류는 `.tc`를 수정한다.
- 단일 SQL 길이 오류는 문자열 리터럴 내부는 보존하고 SQL 바깥 공백,
  들여쓰기, 불필요한 개행을 줄인다. 그래도 64KB를 넘으면 CTE를 임시
  테이블/뷰로 분해하거나 runner가 지원하는 file 실행 방식을 찾는다.
- include/path 오류는 `.ts`, `.tc`, include 위치를 수정한다.
- runner 환경 문제는 필요한 환경 변수와 runner binary path를 먼저 정리한다.
- ERROR가 해결되어 FAIL로 바뀌면 `FAIL Handling` 기준으로 다시 판단한다.

## Server Debug Information

서버 디버깅이 필요한 경우에만 아래 정보를 모은다.

- 서버 tree: `$HOME/work/altidev4`.
- 재현 SQL 또는 최소화한 SQL.
- TC setup DDL/DML와 cleanup 순서.
- 서버 실행 상태와 PID.
- `altibase -v` 출력.
- 관련 `altibase.properties` 또는 테스트에서 변경한 system property.
- server trace/log/core 위치.
- crash/hang이면 backtrace, core file, 남은 프로세스 상태.
- 의심 모듈이나 stack trace가 있으면 관련 source path.

서버 원인 조사가 시작되면 expected `.lst`는 근거 없이 갱신하지 않는다.

## Per-Case Debug Note Format

조사 내용 저장이 필요할 때만 아래 형식으로 짧게 남긴다.

```text
# <case-name> debug notes

## Reproduction
- Command:
- Result:
- Exit code:

## Classification
- Status: FAIL | ERROR | FATAL | HANG
- Likely area: oracle | tc-syntax | runner | server

## Evidence
- report.log:
- debug.log:
- lst/out diff:
- failing line or SQL size:

## Decision
- Update .lst:
- Edit .tc:
- Debug server:

## Verification
- Command:
- Result:
```

문서에는 다음 디버깅에 실제로 필요한 사실만 남긴다. 긴 SQL 전문, 전체 diff,
전체 로그는 문서에 붙이지 말고 파일 경로와 핵심 요약만 남긴다.
