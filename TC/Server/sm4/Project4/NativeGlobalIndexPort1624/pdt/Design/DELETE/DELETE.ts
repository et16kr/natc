TestSuiteDescription  = PDT DELETE PARTITION Design 4 test
###############################################################################
# ---------------------------------------------------------------------------
# HELD OUT (V4 J19): RangePartTable
#
# The case is ported and sits beside this file, but it has no expectation
# because it cannot be recorded reproducibly here. Its FK sector deletes
# rows that violate several foreign keys at once, and the server names
# whichever one it checked first:
#     [ERR-31076 ... Check the referential constraints. T3_T1_FK]
#     [ERR-31076 ... Check the referential constraints. T2_T1_FK]
# are both real answers to the same statement. Two consecutive runs on two
# freshly created databases disagree on 16 such lines. The original froze
# one of the names; re-freezing another would be the same mistake, so the
# case waits until the order is either pinned or the sector is rewritten to
# violate one key at a time. v4-natc-port.md 6.
# ---------------------------------------------------------------------------

integer_hash.sql                         # HASH : INTEGER Test
integer_range.sql                        # RANGE : INTEGER Test
integer_list.sql                         # LIST : INTEGER Test
ListPartTable.sql                        #
HashPartTable.sql                        #
-------------------------------------------------------------------------------
