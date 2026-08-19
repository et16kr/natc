TestSuiteDescription  = Native Global Index (disk) - Query
###############################################################################
parallelGlobalScan.tc                   # 병렬 글로벌 스캔의 답 (GR-04, 그물에서 건짐)
partitionAllowSet.tc                    # PARTITION(p) 허용 집합 (J19/J19b, 그물에서 건짐)
statisticsAndHeader.tc                  # 통계·V$DISK_BTREE_HEADER·커버링 (그물에서 건짐)
# ★ parallelIsolationGate.tc 는 아직 걸지 않는다 (보류)
#   REPEATABLE READ 에서 코디네이터 아래 워커가 전량(30000)을 훑는다.
#   명세 §4.3 R1 이 막으려던 것과 어긋나므로 기대값으로 굳히지 않는다.
memberDirectory.tc                      # 멤버 디렉터리 관측 창 (신규 N16)
-------------------------------------------------------------------------------
