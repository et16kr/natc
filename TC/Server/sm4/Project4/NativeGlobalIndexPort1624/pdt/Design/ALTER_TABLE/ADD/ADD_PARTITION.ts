TestSuiteDescription  = PDT ADD PARTITION Design 4 test
###############################################################################
# ---------------------------------------------------------------------------
# HELD OUT (V4 J19 -> J19b): HashPartTable_Integer, HashPartTable_Date,
# HashPartTable_Varchar.
#
# The three cases are ported and sit beside this file, but they are not run
# yet. Each of them asks
#     SELECT COUNT(*) FROM T2 PARTITION( Pn ) WHERE I1 < 1000 OR I1 IS NULL
# on a HASH table whose non-prefixed indexes are native global, and the
# server answers ERR-01011 for every partition but one. Recording that
# transcript would freeze a defect as the expectation, which this project
# does not do. Root cause and repro: v4-natc-port.md 5 (defect 2),
# reproduced by scripts/global-index/global-partfilter-check.sh section C.
# J19b wires these three lines back in and records them.
# ---------------------------------------------------------------------------


integer_hash.sql                         # HASH : INTEGER Test
integer_range.sql                        # RANGE : INTEGER Test
integer_list.sql                         # LIST : INTEGER Test

index_partition.sql                      # 인덱스 파티션을 명시한 경우 Test
-------------------------------------------------------------------------------
