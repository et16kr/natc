TestSuiteDescription  = Native Global Index - Catalog
###############################################################################
#
# PROJ-1624 이식분은 **원본 실행 순서**를 지킨다 -- 알파벳순으로 늘어놓으면
#   서로에게 기대는 케이스들이 어긋난다(실측: Duplicate index name · FK 의존).
#   원본 경로는 각 케이스 첫 주석과 MANIFEST 가 보존한다.
#
meta_create_index.tc                    # meta/create_index.tc
meta_drop_index.tc                      # meta/drop_index.tc
meta_add_constraint.tc                  # meta/add_constraint.tc
meta_drop_constraint.tc                 # meta/drop_constraint.tc
meta_create_table.tc                    # meta/create_table.tc
meta_drop_table.tc                      # meta/drop_table.tc
meta_drop_user.tc                       # meta/drop_user.tc
meta_drop_tablespace.tc                 # meta/drop_tablespace.tc
-------------------------------------------------------------------------------
