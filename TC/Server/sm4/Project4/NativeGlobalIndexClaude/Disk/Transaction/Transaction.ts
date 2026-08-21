TestSuiteDescription  = Native Global Index - Transaction
###############################################################################
#
# PROJ-1624 이식분은 **원본 실행 순서**를 지킨다 -- 알파벳순으로 늘어놓으면
#   서로에게 기대는 케이스들이 어긋난다(실측: Duplicate index name · FK 의존).
#   원본 경로는 각 케이스 첫 주석과 MANIFEST 가 보존한다.
#
lockTable_S_NOWAIT.sql                  # pdt/Design/LOCK_TABLE/S_NOWAIT.sql
lockTable_IS_NOWAIT.sql                 # pdt/Design/LOCK_TABLE/IS_NOWAIT.sql
lockTable_IX_NOWAIT.sql                 # pdt/Design/LOCK_TABLE/IX_NOWAIT.sql
lockTable_X_NOWAIT.sql                  # pdt/Design/LOCK_TABLE/X_NOWAIT.sql
lockTable_SIX_NOWAIT.sql                # pdt/Design/LOCK_TABLE/SIX_NOWAIT.sql
#
# ★ 아래는 **맨 뒤여야 한다.** 위 이식분 다수가 절대 카탈로그 id
#   (`__SYS_PART_IDX_ID_<n>`)를 기대값에 담고 있어, 앞에 케이스를 끼우면
#   그 id 가 전부 밀린다. 새 케이스는 이 줄 아래에 붙인다.
#
savepointDdlDisk.tc                     # 세이브포인트를 가로지르는 DDL 사다리 (신규)
crossPartitionConcurrency.tc            # 두 세션의 경합 — FOR UPDATE NOWAIT · 전 파티션 X 잠금 (신규)
-------------------------------------------------------------------------------
