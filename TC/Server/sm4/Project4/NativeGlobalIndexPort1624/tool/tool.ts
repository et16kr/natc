TestSuiteDescription  = Global Non-Partitioned Index Test
###############################################################################
isql/isql.ts                            # isql test
atomic/atomic.ts                        # atomic array insert test
#
# aexport/aexport.ts is NOT wired here. Its four cases are held for E-4: the
# shape of the aexport output for a native global index is not settled yet,
# and the original froze ERR-91014 as the expectation for the $GIT_ tables
# (v3-natc-port.md 6.1 -- an error frozen as an expectation goes green for
# the wrong reason). natc-port-check.sh carries the same four in its HELD
# table with this reason, so they cannot go missing quietly.
-------------------------------------------------------------------------------
