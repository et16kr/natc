TestSuiteDescription  = Native Global Index - DDL
###############################################################################
#
# PROJ-1624 이식분은 **원본 실행 순서**를 지킨다 -- 알파벳순으로 늘어놓으면
#   서로에게 기대는 케이스들이 어긋난다(실측: Duplicate index name · FK 의존).
#   원본 경로는 각 케이스 첫 주석과 MANIFEST 가 보존한다.
#
diskPartitionedTable.tc                 # 디스크 파티션드는 종전 그대로 (섹터마다 프로퍼티 못박음)
replacePartitionRemap.tc                # REPLACE PARTITION 리매핑 == 리빌드 (GR-10/J14, 신규 N1)
convertFromLegacy.tc                    # $GIT_ -> 네이티브 전환 3축 (리뷰 §3·§4·§6, 신규 N9/N10/N11)
coalescePartition_HashPartTable_Date.sql# PROJ-1624 이식
coalescePartition_HashPartTable_Integer.sql# PROJ-1624 이식
coalescePartition_HashPartTable_Varchar.sql# PROJ-1624 이식
dropPartition_RangePartTable_Integer.sql# PROJ-1624 이식
dropPartition_RangePartTable_Varchar.sql# PROJ-1624 이식
mergePartition_ListPartTable_Integer.sql# PROJ-1624 이식
mergePartition_ListPartTable_Varchar.sql# PROJ-1624 이식
mergePartition_RangePartTable_Integer.sql# PROJ-1624 이식
mergePartition_RangePartTable_Varchar.sql# PROJ-1624 이식
splitPartition_ListPartTable_Integer.sql# PROJ-1624 이식
splitPartition_ListPartTable_Varchar.sql# PROJ-1624 이식
splitPartition_RangePartTable_Integer.sql# PROJ-1624 이식
splitPartition_RangePartTable_Varchar.sql# PROJ-1624 이식
truncatePartition_HashPartTable_Date.sql# PROJ-1624 이식
truncatePartition_HashPartTable_Integer.sql# PROJ-1624 이식
truncatePartition_HashPartTable_Varchar.sql# PROJ-1624 이식
truncatePartition_ListPartTable_Date.sql# PROJ-1624 이식
truncatePartition_ListPartTable_Integer.sql# PROJ-1624 이식
truncatePartition_ListPartTable_Varchar.sql# PROJ-1624 이식
truncatePartition_RangePartTable_Date.sql# PROJ-1624 이식
truncatePartition_RangePartTable_Integer.sql# PROJ-1624 이식
truncatePartition_RangePartTable_Varchar.sql# PROJ-1624 이식
addPartition_HashPartTable_Integer.sql  # pdt/Design/ALTER_TABLE/ADD/HashPartTable_Integer.sql
addPartition_HashPartTable_Date.sql     # pdt/Design/ALTER_TABLE/ADD/HashPartTable_Date.sql
addPartition_HashPartTable_Varchar.sql  # pdt/Design/ALTER_TABLE/ADD/HashPartTable_Varchar.sql
addPartition_integer_hash.sql           # pdt/Design/ALTER_TABLE/ADD/integer_hash.sql
addPartition_integer_range.sql          # pdt/Design/ALTER_TABLE/ADD/integer_range.sql
addPartition_integer_list.sql           # pdt/Design/ALTER_TABLE/ADD/integer_list.sql
addPartition_index_partition.sql        # pdt/Design/ALTER_TABLE/ADD/index_partition.sql
dropPartition_RangePartTable_Date.sql   # pdt/Design/ALTER_TABLE/DROP/RangePartTable_Date.sql
dropPartition_ListPartTable_Integer.sql # pdt/Design/ALTER_TABLE/DROP/ListPartTable_Integer.sql
dropPartition_ListPartTable_Date.sql    # pdt/Design/ALTER_TABLE/DROP/ListPartTable_Date.sql
dropPartition_ListPartTable_Varchar.sql # pdt/Design/ALTER_TABLE/DROP/ListPartTable_Varchar.sql
dropPartition_integer_hash.sql          # pdt/Design/ALTER_TABLE/DROP/integer_hash.sql
dropPartition_integer_range.sql         # pdt/Design/ALTER_TABLE/DROP/integer_range.sql
dropPartition_integer_list.sql          # pdt/Design/ALTER_TABLE/DROP/integer_list.sql
mergePartition_RangePartTable_Date.sql  # pdt/Design/ALTER_TABLE/MERGE/RangePartTable_Date.sql
mergePartition_ListPartTable_Date.sql   # pdt/Design/ALTER_TABLE/MERGE/ListPartTable_Date.sql
splitPartition_RangePartTable_Date.sql  # pdt/Design/ALTER_TABLE/SPLIT/RangePartTable_Date.sql
splitPartition_ListPartTable_Date.sql   # pdt/Design/ALTER_TABLE/SPLIT/ListPartTable_Date.sql
renamePartition_hash.sql                # pdt/Design/ALTER_TABLE/RENAME/hash.sql
renamePartition_range.sql               # pdt/Design/ALTER_TABLE/RENAME/range.sql
renamePartition_list.sql                # pdt/Design/ALTER_TABLE/RENAME/list.sql
truncatePartition_hash.sql              # pdt/Design/ALTER_TABLE/TRUNCATE/hash.sql
truncatePartition_range.sql             # pdt/Design/ALTER_TABLE/TRUNCATE/range.sql
truncatePartition_list.sql              # pdt/Design/ALTER_TABLE/TRUNCATE/list.sql
alterTable_ADD_COLUMN_basic.sql         # pdt/Design/ALTER_TABLE/ADD_COLUMN/basic.sql
alterTable_DROP_COLUMN_basic.sql        # pdt/Design/ALTER_TABLE/DROP_COLUMN/basic.sql
alterColumnLob_basic.sql                # pdt/Design/ALTER_TABLE/ALTER_COLUMN_LOB/basic.sql
alterColumnLob_alter_table.sql          # pdt/Design/ALTER_TABLE/ALTER_COLUMN_LOB/alter_table.sql
alterIndexRebuild_integer_range.tc      # pdt/Design/ALTER_INDEX/REBUILD/integer_range.tc
alterIndexRebuild_integer_hash.tc       # pdt/Design/ALTER_INDEX/REBUILD/integer_hash.tc
alterIndexRebuild_integer_list.tc       # pdt/Design/ALTER_INDEX/REBUILD/integer_list.tc
pdtDesign_DROP_TABLESPACE_basic.sql     # pdt/Design/DROP_TABLESPACE/basic.sql
ddl_create_index.tc                     # DDL/create_index.tc
ddl_drop_index.tc                       # DDL/drop_index.tc
ddl_alter_index.tc                      # DDL/alter_index.tc
ddl_index_name.tc                       # DDL/index_name.tc
ddl_index_name2.tc                      # DDL/index_name2.tc
ddl_index_column_name.tc                # DDL/index_column_name.tc
ddl_index_rename.tc                     # DDL/index_rename.tc
ddl_reserved_name.tc                    # DDL/reserved_name.tc
ddl_create_table.tc                     # DDL/create_table.tc
ddl_truncate_table.tc                   # DDL/truncate_table.tc
ddl_drop_table.tc                       # DDL/drop_table.tc
ddl_add_column.tc                       # DDL/add_column.tc
ddl_drop_column.tc                      # DDL/drop_column.tc
ddl_rename_column.tc                    # DDL/rename_column.tc
ddl_add_constraint.tc                   # DDL/add_constraint.tc
ddl_drop_constraint.tc                  # DDL/drop_constraint.tc
ddl_add_partition.tc                    # DDL/add_partition.tc
ddl_drop_partition.tc                   # DDL/drop_partition.tc
ddl_coalesce_partition.tc               # DDL/coalesce_partition.tc
ddl_split_partition.tc                  # DDL/split_partition.tc
ddl_merge_partition.tc                  # DDL/merge_partition.tc
ddl_truncate_partition.tc               # DDL/truncate_partition.tc
ddl_security_column.tc                  # DDL/security_column.tc
ddl_global_index_table.tc               # DDL/global_index_table.tc
ddl_partitioned_mview.tc                # DDL/partitioned_mview.tc
#
# ★ 아래는 **맨 뒤여야 한다.** 위 이식분 다수가 절대 카탈로그 id
#   (`__SYS_PART_IDX_ID_<n>`)를 기대값에 담고 있어, 앞에 케이스를 끼우면
#   그 id 가 전부 밀린다. 새 케이스는 이 줄 아래에 붙인다.
#
copySchemaGate.tc                       # 스키마 복사의 게이트 둘 — 프로퍼티 · $GIT_ 은퇴 (신규)
alterColumnGlobalKey.tc                 # 글로벌 키 컬럼의 컬럼 DDL — O-2 · O-3 감시자 (신규)
-------------------------------------------------------------------------------
