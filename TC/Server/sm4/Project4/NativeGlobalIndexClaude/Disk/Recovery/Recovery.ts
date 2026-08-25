TestSuiteDescription  = Native Global Index (disk) - Recovery
###############################################################################
#
# 서버를 죽였다 살리는 레인이다. TC_GUIDE 의 Hard Stops("server restart") 밖이고,
# 따르는 계약이 다르다 -- 케이스 첫 주석에 그 사실을 적는다(계획 §3.3).
#
# ★ 이 레인은 Disk.ts 의 **맨 뒤**에 온다. `--+SYSTEM clean` 이
#   destroydb + createdb 라 앞선 케이스가 만든 것을 전부 지우기 때문이다.
#
# ★ 이 레인이 재야 할 것 (오늘 첫 케이스 하나뿐이다)
#     - redo 로그 6 종 replay: GIDX_INSERT_UNIQUE_KEY · INSERT_DUP_KEY ·
#       DELETE_KEY_WITH_NTA · FREE_KEYS · COMPACT_INDEX_PAGE · KEY_STAMPING
#     - undo 핸들러 3 종
#     - 재기동 후 멤버 집합 재구성 · 판별자 인식 · 미디어 복구
#   그물이 지고 있던 단언 310 이 여기 들어와야 한다
#   (`-Coverage-Gaps.md` §10.2). 오늘 선 것은 셋이고, 남은 것은
#   미디어 복구(ARCHIVELOG·RECOVER DATABASE)와 FIT 크래시 주입이다.
#
# ★ 실행 간 여파 -- `clean` 은 DB 를 지운다
#   restartCatalogSurvival.sql 의 `clean` 은 destroydb+createdb 이므로
#   **이 실행이 끝난 뒤의 DB 는 빈 것**이다. 그래서
#     - 다음 실행의 첫 케이스들이 앞 실행의 잔재를 전제할 수 없고
#     - DB 에 설치한 것(예: DBMS_STATS 패키지)이 사라진다
#   이 스위트의 실행 계약은 **auto-init ON**(계획 §8.7)이므로 매 실행 DB 가
#   새로 만들어지는 것이 정상이고, `clean` 은 그 계약 안에서만 안전하다.
#   `atsclnt` 를 맨손으로 두 번 돌리면 둘째 실행이 어긋나는 것을 실측했다.
#
# ★ 그리고 그것이 statisticsAndHeader 의 조건을 드러냈다
#   그 케이스는 `DBMS_STATS` 를 부르는데 `createdb` 는 그 패키지를 설치하지
#   않는다. 신선한 DB 에서는 항상 붉다 -- 러너 초기화가 패키지를 넣어 주거나,
#   케이스가 그 의존을 걷어내야 한다. 별건으로 남긴다.
#
restartRedoReplay.sql                   # 크래시 후 redo 재적용 — 커밋 키 생존 (신규)
restartUndoRollback.sql                 # 언두 — ROLLBACK 과 크래시가 되돌리는가 (신규)
restartConvergeMembers.sql               # 크래시 뒤 재기동이 멤버 집합을 스스로 되맞추는가 — A-3 의 뒤집힌 기준 (신규)
restartCatalogSurvival.sql              # kill/clean/start 후 카탈로그 (PROJ-1624 원본 복원)
#   ★ clean 을 쓰는 것은 이 하나뿐이라 **레인 안에서도 맨 뒤**다.
-------------------------------------------------------------------------------
