TestSuiteDescription  = Native Global Index - Query
###############################################################################
#
# PROJ-1624 이식분은 **원본 실행 순서**를 지킨다 -- 알파벳순으로 늘어놓으면
#   서로에게 기대는 케이스들이 어긋난다(실측: Duplicate index name · FK 의존).
#   원본 경로는 각 케이스 첫 주석과 MANIFEST 가 보존한다.
#
parallelGlobalScan.tc                   # 병렬 글로벌 스캔의 답 (GR-04, 그물에서 건짐)
partitionAllowSet.tc                    # PARTITION(p) 허용 집합 (J19/J19b, 그물에서 건짐)
statisticsAndHeader.tc                  # 통계·V$DISK_BTREE_HEADER·커버링 (그물에서 건짐)
parallelIsolationGate.tc                # R1 게이트 — 격리 × 병렬 (신규)
memberDirectory.tc                      # 멤버 디렉터리 관측 창 (신규 N16)
select_integer_hash.tc                  # pdt/Design/SELECT/integer_hash.tc
select_date_hash.tc                     # pdt/Design/SELECT/date_hash.tc
select_varchar_hash.tc                  # pdt/Design/SELECT/varchar_hash.tc
select_numeric_hash.tc                  # pdt/Design/SELECT/numeric_hash.tc
select_integer_range.tc                 # pdt/Design/SELECT/integer_range.tc
select_date_range.tc                    # pdt/Design/SELECT/date_range.tc
select_varchar_range.tc                 # pdt/Design/SELECT/varchar_range.tc
select_numeric_range.tc                 # pdt/Design/SELECT/numeric_range.tc
select_integer_list.tc                  # pdt/Design/SELECT/integer_list.tc
select_date_list.tc                     # pdt/Design/SELECT/date_list.tc
select_varchar_list.tc                  # pdt/Design/SELECT/varchar_list.tc
select_numeric_list.tc                  # pdt/Design/SELECT/numeric_list.tc
design_plan.tc                          # design/plan.tc
design_selectivity.tc                   # design/selectivity.tc
design_selectivity2.tc                  # design/selectivity2.tc
design_indexable_pred.tc                # design/indexable_pred.tc
design_join_method.tc                   # design/join_method.tc
design_join_pred.tc                     # design/join_pred.tc
design_join_pred2.tc                    # design/join_pred2.tc
design_host_var.tc                      # design/host_var.tc
design_preserved_order.tc               # design/preserved_order.tc
design_preserved_order2.tc              # design/preserved_order2.tc
design_part_filter.tc                   # design/part_filter.tc
design_constant_filter.tc               # design/constant_filter.tc
design_subq_key_range.tc                # design/subq_key_range.tc
design_hint.tc                          # design/hint.tc
design_view_push_pred.tc                # design/view_push_pred.tc
design_table_lock.tc                    # design/table_lock.tc
qc_DuplicateIndexName.tc                # qc/DuplicateIndexName.tc
qc_index.tc                             # qc/index.tc
qc_index_disable.tc                     # qc/index_disable.tc
qc_indexThrMovement.sql                 # qc/indexThrMovement.sql
qc_JoinTest.tc                          # qc/JoinTest.tc
qc_keyrange.tc                          # qc/keyrange.tc
#
# ★ 아래는 **맨 뒤여야 한다.** 위 이식분 다수가 절대 카탈로그 id
#   (`__SYS_PART_IDX_ID_<n>`)를 기대값에 담고 있어, 앞에 케이스를 끼우면
#   그 id 가 전부 밀린다. 새 케이스는 이 줄 아래에 붙인다.
#
psmGlobalAccessDisk.tc                  # PSM 커서·DML·FOR UPDATE (신규)
-------------------------------------------------------------------------------
