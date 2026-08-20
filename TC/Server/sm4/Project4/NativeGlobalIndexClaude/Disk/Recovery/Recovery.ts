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
#   (`-Coverage-Gaps.md` §10.2).
#
restartCatalogSurvival.sql              # kill/clean/start 후 카탈로그 (PROJ-1624 원본 복원)
-------------------------------------------------------------------------------
