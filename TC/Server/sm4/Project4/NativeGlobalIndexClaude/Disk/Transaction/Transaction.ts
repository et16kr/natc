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
-------------------------------------------------------------------------------
