TestSuiteDescription  = Native Global Index - Tool
###############################################################################
#
# PROJ-1624 이식분은 **원본 실행 순서**를 지킨다 -- 알파벳순으로 늘어놓으면
#   서로에게 기대는 케이스들이 어긋난다(실측: Duplicate index name · FK 의존).
#   원본 경로는 각 케이스 첫 주석과 MANIFEST 가 보존한다.
#
iloaderRoundTrip.tc                     # iloader out/in 왕복 (신규 N14)
tool_isql_global_index.tc               # tool/isql/global_index.tc
tool_aexport_initialize.tc              # tool/aexport/initialize.tc
tool_aexport_aexport_all.tc             # tool/aexport/aexport_all.tc
tool_aexport_aexport_user.tc            # tool/aexport/aexport_user.tc
tool_aexport_aexport_obj.tc             # tool/aexport/aexport_obj.tc
tool_atomic_atomic_test.tc              # tool/atomic/atomic_test.tc
-------------------------------------------------------------------------------
