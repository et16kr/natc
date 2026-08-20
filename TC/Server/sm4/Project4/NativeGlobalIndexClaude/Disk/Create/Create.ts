TestSuiteDescription  = Native Global Index - Create
###############################################################################
#
# PROJ-1624 이식분은 **원본 실행 순서**를 지킨다 -- 알파벳순으로 늘어놓으면
#   서로에게 기대는 케이스들이 어긋난다(실측: Duplicate index name · FK 의존).
#   원본 경로는 각 케이스 첫 주석과 MANIFEST 가 보존한다.
#
createIndexLocalUnique_integer_range.sql# PROJ-1624 이식
createTable_RangePartTable.sql          # pdt/Design/CREATE_TABLE/RangePartTable.sql
createTable_HashPartTable.sql           # pdt/Design/CREATE_TABLE/HashPartTable.sql
createTable_ListPartTable.sql           # pdt/Design/CREATE_TABLE/ListPartTable.sql
createTableAsSelect_RangePartTable.sql  # pdt/Design/CREATE_TABLE/AS_SELECT/RangePartTable.sql
createTableAsSelect_HashPartTable.sql   # pdt/Design/CREATE_TABLE/AS_SELECT/HashPartTable.sql
createTableAsSelect_ListPartTable.sql   # pdt/Design/CREATE_TABLE/AS_SELECT/ListPartTable.sql
createIndexLocal_RangePartTable.sql     # pdt/Design/CREATE_INDEX/LOCAL/RangePartTable.sql
createIndexLocal_HashPartTable.sql      # pdt/Design/CREATE_INDEX/LOCAL/HashPartTable.sql
createIndexLocal_ListPartTable.sql      # pdt/Design/CREATE_INDEX/LOCAL/ListPartTable.sql
createIndexLocalUnique_integer_hash.sql # pdt/Design/CREATE_INDEX/LOCAL_UNIQUE/integer_hash.sql
createIndexLocalUnique_integer_list.sql # pdt/Design/CREATE_INDEX/LOCAL_UNIQUE/integer_list.sql
-------------------------------------------------------------------------------
