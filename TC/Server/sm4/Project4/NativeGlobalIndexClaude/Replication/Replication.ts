TestSuiteDescription  = Native Global Index - Replication
###############################################################################
#
# ★ 이 레인은 두 서버가 필요하다 -- TC_GUIDE.md 의 Hard Stops 범위 밖이다.
#   따르는 것은 repl4 의 실사용 패턴이고, 템플릿은 이 디렉터리의
#   initialize.tc 다. 새 복제 케이스는 그것을 보고 쓴다.
#
#   순서가 하중을 받는다: initialize 가 db1/db2 를 짓고 서버를 띄우며,
#   finalize 가 내린다. 본문 케이스는 그 사이에만 둔다.
#
initialize.tc                           # 두 인스턴스를 세운다 (템플릿)
globalPkRowMovement.tc                  # 글로벌 PK + row movement 복제 (V4 C 트랙, 템플릿)
ddlSyncPropertyMismatch.tc              # 프로퍼티 어긋난 쌍의 거절 (V4 D-2, 거절 템플릿)
finalize.tc                             # 두 인스턴스를 내린다
-------------------------------------------------------------------------------
