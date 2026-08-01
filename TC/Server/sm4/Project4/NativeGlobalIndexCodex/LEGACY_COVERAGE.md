# Legacy PROJ-1624 coverage review

## Baseline

The legacy root suite at
`qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624.ts` reaches 12 suites and
77 `.tc` or `.sql` cases. The larger `PROJ-1624-QC/PDT` tree also contains
useful references, but most of it is not reachable from that root suite.

The native suite does not copy hidden-table checks or preserve the old folder
shape. It carries forward public SQL intent and uses native catalog identity.

## Added from legacy gaps

| Legacy intent | Native Disk | Native Memory |
| --- | --- | --- |
| function-based index bug regression | `Disk/Create/functionBased.tc` | `Memory/Create/functionBased.tc` |
| indexable predicates, host binds, preserved order | `Disk/Query/predicateMatrix.tc` | `Memory/Query/predicateMatrix.tc` |
| joins, subquery key range, view predicates | `Disk/Query/joinSubqueryView.tc` | `Memory/Query/joinSubqueryView.tc` |
| hash/list UPDATE, DELETE, row movement | `Disk/DML/hashListMutation.tc` | `Memory/DML/hashListMutation.tc` |
| INSERT SELECT and multiple index maintenance | `Disk/DML/insertSelectMultiIndex.tc` | `Memory/DML/insertSelectMultiIndex.tc` |
| add/drop/rename column | `Disk/DDL/schemaEvolution.tc` | `Memory/DDL/schemaEvolution.tc` |
| index rename and TRUNCATE TABLE | `Disk/DDL/truncateAndRename.tc` | `Memory/DDL/truncateAndRename.tc` |
| SPLIT/MERGE partition rejection | `Disk/Unsupported/splitMergePartition.tc` | `Memory/Unsupported/splitMergePartition.tc` |

The earlier native prototypes already cover the legacy range/list/hash create,
basic INSERT/UPDATE/DELETE, NULL and composite keys, local/global coexistence,
unique constraints, REBUILD, DROP INDEX, DROP TABLE cascade, hints, ordering,
and partition-topology statements.

## Deliberately changed

- Legacy `$GIT_*`, `$GIK_*`, and `$GIR_*` physical-table consistency queries
  are not ported. Native indexes have no hidden table; catalog type plus public
  ordered-query results are the SQL oracle.
- ADD/DROP/TRUNCATE/SPLIT/MERGE partition success tests become V1 rejection
  tests because native V1 freezes the participant set. Hash COALESCE is checked
  with the same pre-change catalog and data oracle.
- Legacy `ALTER INDEX DISABLE`, `NOLOGGING`, and parallel build success paths
  become explicit unsupported tests.
- Disk-only legacy cases are duplicated as independent Disk and Memory cases
  instead of mixing media expectations in one output.

## Deferred environment lanes

| Legacy area | Reason not linked now | Intended destination |
| --- | --- | --- |
| aexport and iSQL metadata formatting | tool version and output oracle required | `Tool` suite after gate |
| atomic array insert | APRE build/runtime fixture required | `Tool/Atomic` suite |
| replication | two-server topology and fix-level contract required | separate replication suite |
| performance | calibrated server, data volume, and TPS threshold required | non-regression performance lane |
| DROP USER/TABLESPACE cascade | isolated admin fixture and file policy required | destructive DDL environment lane |
| restart and crash recovery | restart helper and fault-point contract required | existing `Lifecycle` plans |

These lanes must not be represented by guessed `.lst` output or by helpers
copied from the legacy environment without revalidation.
