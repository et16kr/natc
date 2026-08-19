# concurrentSpillWithShrink 실행 이슈

## 재현

- 시각: 2026-08-19 09:19~09:33 KST
- 작업 디렉터리: `/home/et16/work/natc`
- 명령: `atsclnt TC/Server/sm4/Project4/temp_tablespace/temp_tablespace.ts`
- 결과: `PASS: 94 FAIL: 0 FATAL: 1`
- 중단 위치: `runtime/concurrency/concurrentSpillWithShrink.tc` (전체 115건 중 95번째)
- 후속 단독 실행: 같은 TC가 `PASS: 1 FAIL: 0 FATAL: 0`으로 통과함

## 분류

- 상태: 전체 suite에서는 FATAL, 단독 실행에서는 PASS
- 범위: 실행 순서 또는 timing에 영향을 받는 server/runtime 이슈 가능성
- 이번 통합·정리 작업에서 해당 TC와 oracle의 동작 조건은 변경하지 않음

## 근거

- worker 연결은 `ERR-91015: Communication failure`로 종료됨
- 서버 로그에는 `src/sm/smi/smiTempTable.cpp:322`의 assert와
  `ERR-42000(errno=11)`이 기록됨
- assert 직후 Altibase 서버 프로세스가 종료되어 뒤의 20개 TC는 실행되지 않음
- 관련 로그:
  - `/home/et16/work/natc/work/log/debug.log`
  - `/home/et16/work/altidev4/altibase_home/trc/altibase_error.log`
  - `/home/et16/work/altidev4/altibase_home/trc/altibase_sm.log`

## 결정

- 사용자 요청에 따라 이 이슈는 이번 작업에서 추가 분석하거나 수정하지 않음
- `.lst`를 FATAL 결과로 갱신하지 않음
- crash 후 서버는 `scripts/startup.sh`로 복구했고 연결을 확인함
- 통합 suite의 앞선 94개 PASS와 단독 실행 PASS만 검증 결과로 기록함
