# Defect regressions added on 2026-09-27

These cases cover the current development implementation. They do not establish
that the G2 execution, recovery, or publication paths are complete.

| Case | Contract and expected behavior | Suite |
| --- | --- | --- |
| `Memory/Recovery/replaceLocalIndexRecovery.tc` | Exclusive disposable DB; uncommitted REPLACE and LOCAL index CREATE/DROP in both orders; abort/restart restores original rows/indexes and later DML rollback | `Memory/Recovery/Recovery.ts` |
| `Disk/Recovery/replaceLocalIndexRecovery.tc` | Same contract for disk tables | `Disk/Recovery/Recovery.ts` |
| `Disk/Recovery/replaceGlobalMemberRecovery.tc` | Exclusive disposable DB; loser REPLACE recovery must restore GLOBAL scans as well as heap/LOCAL scans | **Explicit** `Disk/Recovery/KnownFailures.ts` |
| `Disk/Transaction/memberFixupOwnership.tc` | Exclusive instance with `MULTIPLEXING_THREAD_COUNT=1` and `MULTIPLEXING_MAX_THREAD_COUNT=1`; peer commit/rollback must not consume the REPLACE owner's pending work | **Explicit** `Disk/Transaction/SingleWorker.ts` |
| `Tool/dumpShortMeta.tc` | POSIX shell and `ALTIBASE_HOME/bin/{dumpddf,dumpsbf}`; empty/short inputs must report an incomplete read without guessing the index format | `Tool/Tool.ts` |

Recovery cases use the existing `stdFunc.i` SYSDBA `shutdown abort` / startup
contract and reconnect each client. They interrupt every session on that instance.
They do not call the older recovery cases' database-clean scripts. The Memory
recovery suite is appended after the existing Memory lanes to preserve their
catalog-ID ordering.

R5 remains open: `replaceGlobalMemberRecovery.tc` currently **fails** because both
GLOBAL scans return `ERR-11110`, while the heap and LOCAL scans recover the original
rows. Its oracle expects those original rows through GLOBAL scans too. Do not
replace that expectation with the error or add a rebuild/heal step. The known
failure suite is intentionally separate from the regular passing recovery suite.

The single-worker case checks its two multiplexing properties visibly. Configure
and restore those properties through the project's instance lifecycle procedure;
the TC does not restart/reconfigure an arbitrary shared server. A mismatching
configuration is not evidence that the ownership regression passes.

Existing cases also cover R2/R6 (`Disk/DDL/replacePartitionRemap.tc`), R8
(`Memory/DDL/unsupportedRtree.tc`), R9/R10 (`Disk/DDL/purgeLeafAccounting.tc`), R11
(`Disk/DDL/replacePartitionCachedPlan.tc`), and R12/R13 (both media's
`DDL/replacePartitionLocalColumns.tc`). The sibling `NativeGlobalIndexCodex`
Memory/Disk `Transaction/savepointLogBoundary.tc` cases cover the cross-log-file
savepoint boundary bug.

R3/R4 require targeted recoverable failures inside compaction or member-fixup
allocation/begin/write paths. There are no matching FIT points in those paths;
ordinary SQL or a process abort cannot demonstrate the same live-server failure
behavior. They have no new NATC PASS claim here.

Validation on 2026-09-27: the four new passing cases and eight existing cases
listed above passed with the fixed development server; R5 failed as described.
In a separate freshly created database, the saved pre-fix executable reproduced
R1 (GLOBAL scan loses `(1,101)`, heap retains it) and the existing Disk
`replacePartitionLocalColumns.tc` reproduced R12 (server exits with `Column not
found` during savepoint rollback). The fixed executable passes both unchanged
oracles. Evidence is under `/tmp/native-global-index-natc-20260927/`; the saved
executable's SHA-256 is
`b35d92bff26234124c59dfee02505036adfa4b32c2d6510448cb920f5ea236e4`.
