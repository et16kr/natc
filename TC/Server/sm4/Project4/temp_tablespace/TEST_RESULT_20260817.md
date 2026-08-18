# TEMP tablespace NATC 실행 결과

- 실행일: 2026-08-17 (최신 실행)
- 테스트 스위트: `temp_tablespace.ts`
- 실행 옵션: `--ignore=FATAL`
- 결과: `PASS: 0 FAIL: 60 FATAL: 2 HANG: 0 JUMP: 0 CORED: 0 ERROR: 0`

FATAL 발생 후 `server_restart.sql`을 수행하고 다음 케이스로 계속 진행했습니다. 최신 실행에서는 60개 케이스가 테스트 본문까지 실행되어 FAIL, 2개 케이스가 실행 중 연결 오류로 FATAL이 되었습니다.

## FATAL 목록

- `runtimeAutoextend.tc`
- `runtimeResizeRestart.tc`

두 케이스는 실행 중 `ERR-50032` 연결 오류가 발생했습니다.

## `.lst`로 반영한 케이스

SQL 오류 없이 검증 쿼리의 `PASS_* = 1` 결과가 확인된 19개 케이스는 최신 `.out`을 검토한 뒤 대응하는 `_A4_64.lst`로 갱신했습니다.

`createCatalog`, `create_01`~`create_07`, `dataRoutingIsolation`, `restartRecreate`, `restart_01`, `restart_02`, `restart_05`~`restart_07`, `route_01`~`route_04`

## `.lst`로 반영하지 않은 FAIL 목록

`addDropTempfile`, `dropReuse`, `activeDataAliasReuse`, `activeTempAliasReuse`, `unsupportedDdl`, `create_08`, `resize_01`~`resize_08`, `auto_01`~`auto_08`, `adddrop_01`~`adddrop_08`, `reject_01`~`reject_08`, `restart_03`, `restart_04`

해당 출력에는 `ERR-11034`, `ERR-41082` 등 SQL/서버 오류 또는 검증값 `0`이 포함되어 있어 expected `.lst`로 승격하지 않았습니다.

## 비고

이번 작업에서는 테스트케이스, `stdFunc.i`, 제품 코드에 대한 수정 및 디버깅을 수행하지 않았습니다. 상세 결과는 같은 디렉터리의 `*_A4_64.out` 파일과 `work/log/report.log`에 보존되어 있습니다.
