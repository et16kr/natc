# safety binding suite 실행 이슈

## 재현

- 시각: 2026-08-19 09:51~09:53 KST
- 작업 디렉터리: `/home/et16/work/natc`
- 명령: `atsclnt TC/Server/sm4/Project4/temp_tablespace/safety/safety.ts`
- 결과: `PASS: 2 FAIL: 3 FATAL: 0`

## 결과

- PASS: `createMultiFileFailure.tc`, `dropPathSubstitution.tc`
- FAIL: `activeDataAliasReuse.tc`, `activeTempAliasReuse.tc`, `dropReuse.tc`
- 세 FAIL 모두 예상한 `ERR-11034` 대신 서버가 `ERR-41082`와 내부 오류 코드
  `0x42000000`을 반환한 oracle 차이임
- 실행 당시 생성된 `.out`에는 SQL 실행 중단이나 서버 연결 종료가 없었음

## 근거 파일

- `safety/binding/activeDataAliasReuse_A4_64.lst`
- `safety/binding/activeDataAliasReuse_A4_64.out`
- `safety/binding/activeTempAliasReuse_A4_64.lst`
- `safety/binding/activeTempAliasReuse_A4_64.out`
- `safety/binding/dropReuse_A4_64.lst`
- `safety/binding/dropReuse_A4_64.out`

위 `.out` 파일은 결과를 이 문서에 기록한 뒤 `docs/TC_GUIDE.md`의 산출물
정리 원칙에 따라 작업 트리에서 제거함.

## 결정

- 사용자 요청에 따라 이번 작업에서 원인을 추가 분석하거나 수정하지 않음
- 실제 오류를 정상 결과로 간주해 `.lst`를 갱신하지 않음
- 대상 TC와 기존 oracle은 변경하지 않음
