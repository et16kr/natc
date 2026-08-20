TestSuiteDescription  = Native Global Index - DML
###############################################################################
#
# PROJ-1624 이식분은 **원본 실행 순서**를 지킨다 -- 알파벳순으로 늘어놓으면
#   서로에게 기대는 케이스들이 어긋난다(실측: Duplicate index name · FK 의존).
#   원본 경로는 각 케이스 첫 주석과 MANIFEST 가 보존한다.
#
multiTableRowMovement.tc                # 멀티테이블 UPDATE 의 row movement (O-8, 신규 N8)
basic_select.tc                         # basic/select.tc
basic_insert_range.tc                   # basic/insert_range.tc
basic_insert_hash.tc                    # basic/insert_hash.tc
basic_insert_list.tc                    # basic/insert_list.tc
basic_insert_part_range.tc              # basic/insert_part_range.tc
basic_insert_part_list.tc               # basic/insert_part_list.tc
basic_update_range.tc                   # basic/update_range.tc
basic_update_hash.tc                    # basic/update_hash.tc
basic_update_list.tc                    # basic/update_list.tc
basic_delete_range.tc                   # basic/delete_range.tc
basic_delete_hash.tc                    # basic/delete_hash.tc
basic_delete_list.tc                    # basic/delete_list.tc
basic_move_range.tc                     # basic/move_range.tc
basic_move_hash.tc                      # basic/move_hash.tc
basic_move_list.tc                      # basic/move_list.tc
basic_null_value.tc                     # basic/null_value.tc
rowMovement_RangePartTable_Integer.sql  # pdt/Design/ALTER_TABLE/ROW_MOVEMENT/RangePartTable_Integer.sql
rowMovement_RangePartTable_Date.sql     # pdt/Design/ALTER_TABLE/ROW_MOVEMENT/RangePartTable_Date.sql
rowMovement_RangePartTable_Varchar.sql  # pdt/Design/ALTER_TABLE/ROW_MOVEMENT/RangePartTable_Varchar.sql
rowMovement_ListPartTable_Integer.sql   # pdt/Design/ALTER_TABLE/ROW_MOVEMENT/ListPartTable_Integer.sql
rowMovement_ListPartTable_Date.sql      # pdt/Design/ALTER_TABLE/ROW_MOVEMENT/ListPartTable_Date.sql
rowMovement_ListPartTable_Varchar.sql   # pdt/Design/ALTER_TABLE/ROW_MOVEMENT/ListPartTable_Varchar.sql
rowMovement_HashPartTable_Integer.sql   # pdt/Design/ALTER_TABLE/ROW_MOVEMENT/HashPartTable_Integer.sql
rowMovement_HashPartTable_Date.sql      # pdt/Design/ALTER_TABLE/ROW_MOVEMENT/HashPartTable_Date.sql
rowMovement_HashPartTable_Varchar.sql   # pdt/Design/ALTER_TABLE/ROW_MOVEMENT/HashPartTable_Varchar.sql
insert_InsertSelect.tc                  # pdt/Design/INSERT/InsertSelect.tc
delete_integer_hash.sql                 # pdt/Design/DELETE/integer_hash.sql
delete_integer_range.sql                # pdt/Design/DELETE/integer_range.sql
delete_integer_list.sql                 # pdt/Design/DELETE/integer_list.sql
delete_ListPartTable.sql                # pdt/Design/DELETE/ListPartTable.sql
delete_HashPartTable.sql                # pdt/Design/DELETE/HashPartTable.sql
update_integer_hash.sql                 # pdt/Design/UPDATE/integer_hash.sql
update_integer_range.sql                # pdt/Design/UPDATE/integer_range.sql
update_integer_list.sql                 # pdt/Design/UPDATE/integer_list.sql
move_integer_hash.sql                   # pdt/Design/MOVE/integer_hash.sql
move_integer_range.sql                  # pdt/Design/MOVE/integer_range.sql
move_integer_list.sql                   # pdt/Design/MOVE/integer_list.sql
-------------------------------------------------------------------------------
