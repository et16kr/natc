TestSuiteDescription  = Native Global Index - Bugs
###############################################################################
#
# PROJ-1624 이식분은 **원본 실행 순서**를 지킨다 -- 알파벳순으로 늘어놓으면
#   서로에게 기대는 케이스들이 어긋난다(실측: Duplicate index name · FK 의존).
#   원본 경로는 각 케이스 첫 주석과 MANIFEST 가 보존한다.
#
pdtBug_INITIALIZE.sql                   # 이 영역의 전제 (원본에서 짝이었다)
pdtBug_BUG-9.sql                        # pdt/Bugs/BUG-9/BUG-9.sql
pdtBug_BUG-14.sql                       # pdt/Bugs/BUG-14/BUG-14.sql
pdtBug_BUG-17.sql                       # pdt/Bugs/BUG-17/BUG-17.sql
pdtBug_BUG-18.sql                       # pdt/Bugs/BUG-18/BUG-18.sql
pdtBug_BUG-20.sql                       # pdt/Bugs/BUG-20/BUG-20.sql
pdtBug_BUG-22.sql                       # pdt/Bugs/BUG-22/BUG-22.sql
pdtBug_BUG-24.sql                       # pdt/Bugs/BUG-24/BUG-24.sql
pdtBug_BUG-27.sql                       # pdt/Bugs/BUG-27/BUG-27.sql
pdtBug_BUG-37.sql                       # pdt/Bugs/BUG-37/BUG-37.sql
pdtBug_BUG-45.sql                       # pdt/Bugs/BUG-45/BUG-45.sql
pdtBug_BUG-49.sql                       # pdt/Bugs/BUG-49/BUG-49.sql
pdtBug_BUG-56.sql                       # pdt/Bugs/BUG-56/BUG-56.sql
bug_function_index.tc                   # bugs/function_index.tc
bug_rollup.tc                           # bugs/rollup.tc
bug_maxvalue.tc                         # bugs/maxvalue.tc
bug_drop_table.tc                       # bugs/drop_table.tc
bug_reset_subquery_exec.sql             # bugs/reset_subquery_exec.sql
bug_BUG-35460.tc                        # bugs/BUG-35460/BUG-35460.tc
pdtBug_FINALIZE.sql                     # 〃
-------------------------------------------------------------------------------
