# runtimeSortHashMatrix 실행 이슈

## 재현

- 시각: 2026-08-19 09:42 KST
- 작업 디렉터리: `/home/et16/work/natc`
- 명령: `atsclnt TC/Server/sm4/Project4/temp_tablespace/runtime/spill/spill.ts`
- 결과: `PASS: 4 FAIL: 0 FATAL: 1`
- 중단 위치: `runtime/spill/runtimeSortHashMatrix.tc`
- 증상: runner가 `Can't connect to Server.`를 보고하고 suite를 중단함

## 실행 범위

- PASS: `multiTempfileSpill.tc`, `extent64Spill.tc`,
  `runtimeAutoextend.tc`, `runtimeResizeRestart.tc`
- 기존 주석 처리: `extent38Spill.tc`, `extent67Spill.tc`,
  `variableExtentSpill.tc`
- FATAL로 미실행: `runtimeReadback.tc`

## 결정

- 사용자 요청에 따라 이 이슈는 이번 작업에서 추가 분석하거나 수정하지 않음
- `.lst`를 FATAL 결과로 갱신하지 않음
- 서버를 복구하고 연결을 확인함
- 미실행됐던 `runtimeReadback.tc`는 분리 실행하여
  `PASS: 1 FAIL: 0 FATAL: 0`을 확인함
