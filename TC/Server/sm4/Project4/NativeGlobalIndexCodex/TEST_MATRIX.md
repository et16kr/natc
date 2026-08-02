# NativeGlobalIndexCodex test matrix

This matrix is the source and A4_64 oracle manifest. Every linked SQL case has
a reviewed sibling named `<caseName>_A4_64.lst`. The root suite passed twice
consecutively after the oracles were installed on 2026-08-02.

## Baseline SQL tests

| ID | Media | Area | Source | Primary oracle | Status |
| --- | --- | --- | --- | --- | --- |
| NGI-D-CAT-001 | Disk | Catalog | `Disk/Catalog/implementationType.tc` | type 3, `INDEX_TABLE_ID` 0 | Pass (A4_64) |
| NGI-D-CAT-002 | Disk | Catalog | `Disk/Catalog/noHiddenObjects.tc` | hidden object name counts 0 | Pass (A4_64) |
| NGI-D-CRT-001 | Disk | Create | `Disk/Create/partitionKinds.tc` | range/list/hash create and scan | Pass (A4_64) |
| NGI-D-CRT-002 | Disk | Create | `Disk/Create/keyAndConstraint.tc` | fixed/variable, PK/UK, unique | Pass (A4_64) |
| NGI-D-CRT-003 | Disk | Create | `Disk/Create/functionBased.tc` | expression key create and update | Pass (A4_64) |
| NGI-D-QRY-001 | Disk | Query | `Disk/Query/rangeOrderPruning.tc` | index/full-scan result equality | Pass (A4_64) |
| NGI-D-QRY-002 | Disk | Query | `Disk/Query/localGlobalCoexist.tc` | local/native access coexistence | Pass (A4_64) |
| NGI-D-QRY-003 | Disk | Query | `Disk/Query/predicateMatrix.tc` | bind, NULL, IN, LIKE, tuple, grouping | Pass (A4_64) |
| NGI-D-QRY-004 | Disk | Query | `Disk/Query/joinSubqueryView.tc` | join, outer join, subquery, view | Pass (A4_64) |
| NGI-D-DML-001 | Disk | DML | `Disk/DML/insertUpdateDelete.tc` | ordered rows after each DML | Pass (A4_64) |
| NGI-D-DML-002 | Disk | DML | `Disk/DML/rowMovementAndUnique.tc` | owner move and global uniqueness | Pass (A4_64) |
| NGI-D-DML-003 | Disk | DML | `Disk/DML/hashListMutation.tc` | hash/list key and owner mutation | Pass (A4_64) |
| NGI-D-DML-004 | Disk | DML | `Disk/DML/insertSelectMultiIndex.tc` | INSERT SELECT with three indexes | Pass (A4_64) |
| NGI-D-DDL-001 | Disk | DDL | `Disk/DDL/rebuildAndDrop.tc` | rebuild visibility and drop | Pass (A4_64) |
| NGI-D-DDL-002 | Disk | DDL | `Disk/DDL/cascadeDrop.tc` | table cascade leaves no index row | Pass (A4_64) |
| NGI-D-DDL-003 | Disk | DDL | `Disk/DDL/schemaEvolution.tc` | add/rename/drop column continuity | Pass (A4_64) |
| NGI-D-DDL-004 | Disk | DDL | `Disk/DDL/truncateAndRename.tc` | rename, truncate, index reuse | Pass (A4_64) |
| NGI-D-NEG-001 | Disk | Unsupported | `Disk/Unsupported/partitionDdl.tc` | topology DDL pre-change rejection | Pass (A4_64) |
| NGI-D-NEG-002 | Disk | Unsupported | `Disk/Unsupported/buildOptions.tc` | build/disable rejection | Pass (A4_64) |
| NGI-D-NEG-003 | Disk | Unsupported | `Disk/Unsupported/splitMergePartition.tc` | split/merge pre-change rejection | Pass (A4_64) |
| NGI-M-CAT-001 | Memory | Catalog | `Memory/Catalog/implementationType.tc` | type 2, `INDEX_TABLE_ID` 0 | Pass (A4_64) |
| NGI-M-CAT-002 | Memory | Catalog | `Memory/Catalog/noHiddenObjects.tc` | hidden object name counts 0 | Pass (A4_64) |
| NGI-M-CRT-001 | Memory | Create | `Memory/Create/partitionKinds.tc` | range/list/hash create and scan | Pass (A4_64) |
| NGI-M-CRT-002 | Memory | Create | `Memory/Create/keyAndConstraint.tc` | variable values, PK/UK, unique | Pass (A4_64) |
| NGI-M-CRT-003 | Memory | Create | `Memory/Create/functionBased.tc` | expression key create and update | Pass (A4_64) |
| NGI-M-QRY-001 | Memory | Query | `Memory/Query/rangeOrderPruning.tc` | range/order/pruning equality | Pass (A4_64) |
| NGI-M-QRY-002 | Memory | Query | `Memory/Query/localGlobalCoexist.tc` | local/native access coexistence | Pass (A4_64) |
| NGI-M-QRY-003 | Memory | Query | `Memory/Query/predicateMatrix.tc` | bind, NULL, IN, LIKE, tuple, grouping | Pass (A4_64) |
| NGI-M-QRY-004 | Memory | Query | `Memory/Query/joinSubqueryView.tc` | join, outer join, subquery, view | Pass (A4_64) |
| NGI-M-DML-001 | Memory | DML | `Memory/DML/insertUpdateDelete.tc` | ordered rows after each DML | Pass (A4_64) |
| NGI-M-DML-002 | Memory | DML | `Memory/DML/rowMovementAndUnique.tc` | owner move and global uniqueness | Pass (A4_64) |
| NGI-M-DML-003 | Memory | DML | `Memory/DML/hashListMutation.tc` | hash/list variable-key owner mutation | Pass (A4_64) |
| NGI-M-DML-004 | Memory | DML | `Memory/DML/insertSelectMultiIndex.tc` | INSERT SELECT with three indexes | Pass (A4_64) |
| NGI-M-DDL-001 | Memory | DDL | `Memory/DDL/rebuildAndDrop.tc` | rebuild visibility and drop | Pass (A4_64) |
| NGI-M-DDL-002 | Memory | DDL | `Memory/DDL/cascadeDrop.tc` | table cascade leaves no index row | Pass (A4_64) |
| NGI-M-DDL-003 | Memory | DDL | `Memory/DDL/schemaEvolution.tc` | add/rename/drop column continuity | Pass (A4_64) |
| NGI-M-DDL-004 | Memory | DDL | `Memory/DDL/truncateAndRename.tc` | rename, truncate, index reuse | Pass (A4_64) |
| NGI-M-NEG-001 | Memory | Unsupported | `Memory/Unsupported/partitionDdl.tc` | topology DDL pre-change rejection | Pass (A4_64) |
| NGI-M-NEG-002 | Memory | Unsupported | `Memory/Unsupported/mediaAndOptions.tc` | media/build/disable rejection | Pass (A4_64) |
| NGI-M-NEG-003 | Memory | Unsupported | `Memory/Unsupported/splitMergePartition.tc` | split/merge pre-change rejection | Pass (A4_64) |

## V1 reinforcement SQL tests

Disk and Memory artifacts share a family ID but remain independent source and
oracle files.

| ID | Media | Area | Source | Primary oracle | Status |
| --- | --- | --- | --- | --- | --- |
| NGI-TRX-001 | Disk | Transaction | `Disk/Transaction/statementRollback.tc` | failed statement preserves rows and identity | Pass (A4_64) |
| NGI-TRX-002 | Disk | Transaction | `Disk/Transaction/savepointRollback.tc` | index/full scan equal after savepoint rollback | Pass (A4_64) |
| NGI-TRX-003 | Disk | Transaction | `Disk/Transaction/transactionRollback.tc` | multi-index row set restored | Pass (A4_64) |
| NGI-TRX-004 | Disk | Transaction | `Disk/Transaction/ddlTransactionGuard.tc` | active-transaction DDL leaves no change | Pass (A4_64) |
| NGI-CRT-004 | Disk | Create | `Disk/Create/tableConstraintForms.tc` | inline/out-of-line PK/UK identity | Pass (A4_64) |
| NGI-CRT-005 | Disk | Create | `Disk/Create/alterConstraintLifecycle.tc` | ADD/DROP constraint backing lifetime | Pass (A4_64) |
| NGI-CRT-006 | Disk | Create | `Disk/Create/duplicateBuildAbort.tc` | duplicate build publishes no object | Pass (A4_64) |
| NGI-CRT-007 | Disk | Create | `Disk/Create/emptyAndPopulatedBuild.tc` | empty/populated create and later DML | Pass (A4_64) |
| NGI-CRT-008 | Disk | Create | `Disk/Create/keyShapeBoundary.tc` | NULL/composite/direction/long key | Pass (A4_64) |
| NGI-CRT-009 | Disk | Create | `Disk/Create/sameMediaTablespaces.tc` | two Disk TBS participants and index TBS | Pass (A4_64) |
| NGI-QRY-005 | Disk | Query | `Disk/Query/optimizerSelection.tc` | unhinted/index/full results equal | Pass (A4_64) |
| NGI-QRY-006 | Disk | Query | `Disk/Query/pruningCardinality.tc` | pruning 0/1/N/all results | Pass (A4_64) |
| NGI-QRY-007 | Disk | Query | `Disk/Query/forUpdateAndCursor.tc` | FOR UPDATE followed by DML | Pass (A4_64) |
| NGI-QRY-008 | Disk | Query | `Disk/Query/statisticsContinuity.tc` | stats preserve data and identity | Pass (A4_64) |
| NGI-QRY-009 | Disk | Query | `Disk/Query/nullSkewAndDuplicates.tc` | NULL/skew/duplicate predicates | Pass (A4_64) |
| NGI-QRY-010 | Disk | Query | `Disk/Query/descendingCompositeOrder.tc` | mixed-direction range ordering | Pass (A4_64) |
| NGI-DML-006 | Disk | DML | `Disk/DML/multiRowStatementAtomicity.tc` | partial failure rolls back statement | Pass (A4_64) |
| NGI-DML-007 | Disk | DML | `Disk/DML/repeatedRowMovement.tc` | repeated partition movement exact-one | Pass (A4_64) |
| NGI-DML-008 | Disk | DML | `Disk/DML/manyGlobalIndexes.tc` | eight index entries stay current | Pass (A4_64) |
| NGI-DML-009 | Disk | DML | `Disk/DML/bulkDeterministicRows.tc` | deterministic 200-row summaries | Pass (A4_64) |
| NGI-DML-010 | Disk | DML | `Disk/DML/deleteReinsertReuse.tc` | deleted unique key can be reused | Pass (A4_64) |
| NGI-DDL-005 | Disk | DDL | `Disk/DDL/renameTableAndConstraint.tc` | table/index rename preserves identity | Pass (A4_64) |
| NGI-DDL-006 | Disk | DDL | `Disk/DDL/indexedColumnDependency.tc` | rejected column DDL leaves no change | Pass (A4_64) |
| NGI-DDL-007 | Disk | DDL | `Disk/DDL/constraintCascade.tc` | FK protects parent constraint/index | Pass (A4_64) |
| NGI-DDL-009 | Disk | DDL | `Disk/DDL/dropMultipleIndexes.tc` | multi-drop and cascade cleanup | Pass (A4_64) |
| NGI-DDL-010 | Disk | DDL | `Disk/DDL/truncateReuseMultiIndex.tc` | multi-index reuse after truncate | Pass (A4_64) |
| NGI-BND-001 | Disk | Boundary | `Disk/Boundary/singleAndManyPartitions.tc` | one/many participant contract | Pass (A4_64) |
| NGI-BND-002 | Disk | Boundary | `Disk/Boundary/globalIndexCount64.tc` | 64 creates and DML succeed | Pass (A4_64) |
| NGI-BND-003 | Disk | Boundary | `Disk/Boundary/globalIndexCount65Reject.tc` | 65th rejected; 64 unchanged | Pass (A4_64) |
| NGI-BND-004 | Disk | Boundary | `Disk/Boundary/dropCascade64.tc` | 64-index cascade cleanup | Pass (A4_64) |
| NGI-BND-006 | Disk | Boundary | `Disk/Boundary/recreateObjectIdentity.tc` | repeated recreation has no stale ref | Pass (A4_64) |
| NGI-NEG-004 | Disk | Unsupported | `Disk/Unsupported/indexTypes.tc` | RTREE/TDRTREE reject; name reusable | Pass (A4_64) |
| NGI-NEG-005 | Disk | Unsupported | `Disk/Unsupported/keyStorageOptions.tc` | DIRECTKEY/PERSISTENT rejection atomicity | Pass (A4_64) |
| NGI-NEG-006 | Disk | Unsupported | `Disk/Unsupported/buildModes.tc` | NOLOGGING/FORCE/parallel reject | Pass (A4_64) |
| NGI-NEG-008 | Disk | Unsupported | `Disk/Unsupported/mixedMediaAndVolatile.tc` | mixed/volatile reject; no fallback | Pass (A4_64) |
| NGI-NEG-009 | Disk | Unsupported | `Disk/Unsupported/ddlCombination.tc` | multiple native creates in one statement reject | Pass (A4_64) |
| NGI-NEG-010 | Disk | Unsupported | `Disk/Unsupported/savepointDdlCombination.tc` | savepoint-crossing DDL reject | Pass (A4_64) |
| NGI-TRX-001 | Memory | Transaction | `Memory/Transaction/statementRollback.tc` | failed statement preserves rows and identity | Pass (A4_64) |
| NGI-TRX-002 | Memory | Transaction | `Memory/Transaction/savepointRollback.tc` | index/full scan equal after savepoint rollback | Pass (A4_64) |
| NGI-TRX-003 | Memory | Transaction | `Memory/Transaction/transactionRollback.tc` | multi-index row set restored | Pass (A4_64) |
| NGI-TRX-004 | Memory | Transaction | `Memory/Transaction/ddlTransactionGuard.tc` | active-transaction DDL leaves no change | Pass (A4_64) |
| NGI-CRT-004 | Memory | Create | `Memory/Create/tableConstraintForms.tc` | inline/out-of-line PK/UK identity | Pass (A4_64) |
| NGI-CRT-005 | Memory | Create | `Memory/Create/alterConstraintLifecycle.tc` | ADD/DROP constraint backing lifetime | Pass (A4_64) |
| NGI-CRT-006 | Memory | Create | `Memory/Create/duplicateBuildAbort.tc` | duplicate build publishes no object | Pass (A4_64) |
| NGI-CRT-007 | Memory | Create | `Memory/Create/emptyAndPopulatedBuild.tc` | empty/populated create and later DML | Pass (A4_64) |
| NGI-CRT-008 | Memory | Create | `Memory/Create/keyShapeBoundary.tc` | NULL/composite/direction/long key | Pass (A4_64) |
| NGI-CRT-009 | Memory | Create | `Memory/Create/sameMediaTablespaces.tc` | two Memory TBS participants and index TBS | Pass (A4_64) |
| NGI-QRY-005 | Memory | Query | `Memory/Query/optimizerSelection.tc` | unhinted/index/full results equal | Pass (A4_64) |
| NGI-QRY-006 | Memory | Query | `Memory/Query/pruningCardinality.tc` | pruning 0/1/N/all results | Pass (A4_64) |
| NGI-QRY-007 | Memory | Query | `Memory/Query/forUpdateAndCursor.tc` | FOR UPDATE followed by DML | Pass (A4_64) |
| NGI-QRY-008 | Memory | Query | `Memory/Query/statisticsContinuity.tc` | stats preserve data and identity | Pass (A4_64) |
| NGI-QRY-009 | Memory | Query | `Memory/Query/nullSkewAndDuplicates.tc` | NULL/skew/duplicate predicates | Pass (A4_64) |
| NGI-QRY-010 | Memory | Query | `Memory/Query/descendingCompositeOrder.tc` | mixed-direction range ordering | Pass (A4_64) |
| NGI-DML-006 | Memory | DML | `Memory/DML/multiRowStatementAtomicity.tc` | partial failure rolls back statement | Pass (A4_64) |
| NGI-DML-007 | Memory | DML | `Memory/DML/repeatedRowMovement.tc` | repeated partition movement exact-one | Pass (A4_64) |
| NGI-DML-008 | Memory | DML | `Memory/DML/manyGlobalIndexes.tc` | eight index entries stay current | Pass (A4_64) |
| NGI-DML-009 | Memory | DML | `Memory/DML/bulkDeterministicRows.tc` | deterministic 200-row summaries | Pass (A4_64) |
| NGI-DML-010 | Memory | DML | `Memory/DML/deleteReinsertReuse.tc` | deleted unique key can be reused | Pass (A4_64) |
| NGI-DDL-005 | Memory | DDL | `Memory/DDL/renameTableAndConstraint.tc` | table/index rename preserves identity | Pass (A4_64) |
| NGI-DDL-006 | Memory | DDL | `Memory/DDL/indexedColumnDependency.tc` | rejected column DDL leaves no change | Pass (A4_64) |
| NGI-DDL-007 | Memory | DDL | `Memory/DDL/constraintCascade.tc` | FK protects parent constraint/index | Pass (A4_64) |
| NGI-DDL-009 | Memory | DDL | `Memory/DDL/dropMultipleIndexes.tc` | multi-drop and cascade cleanup | Pass (A4_64) |
| NGI-DDL-010 | Memory | DDL | `Memory/DDL/truncateReuseMultiIndex.tc` | multi-index reuse after truncate | Pass (A4_64) |
| NGI-BND-001 | Memory | Boundary | `Memory/Boundary/singleAndManyPartitions.tc` | one/many participant contract | Pass (A4_64) |
| NGI-BND-002 | Memory | Boundary | `Memory/Boundary/globalIndexCount64.tc` | 64 creates and DML succeed | Pass (A4_64) |
| NGI-BND-003 | Memory | Boundary | `Memory/Boundary/globalIndexCount65Reject.tc` | 65th rejected; 64 unchanged | Pass (A4_64) |
| NGI-BND-004 | Memory | Boundary | `Memory/Boundary/dropCascade64.tc` | 64-index cascade cleanup | Pass (A4_64) |
| NGI-BND-006 | Memory | Boundary | `Memory/Boundary/recreateObjectIdentity.tc` | repeated recreation has no stale ref | Pass (A4_64) |
| NGI-NEG-004 | Memory | Unsupported | `Memory/Unsupported/indexTypes.tc` | RTREE/TDRTREE reject; name reusable | Pass (A4_64) |
| NGI-NEG-005 | Memory | Unsupported | `Memory/Unsupported/keyStorageOptions.tc` | DIRECTKEY/PERSISTENT rejection atomicity | Pass (A4_64) |
| NGI-NEG-006 | Memory | Unsupported | `Memory/Unsupported/buildModes.tc` | NOLOGGING/FORCE/parallel reject | Pass (A4_64) |
| NGI-NEG-008 | Memory | Unsupported | `Memory/Unsupported/mixedMediaAndVolatile.tc` | mixed/volatile reject; no fallback | Pass (A4_64) |
| NGI-NEG-009 | Memory | Unsupported | `Memory/Unsupported/ddlCombination.tc` | multiple native creates in one statement reject | Pass (A4_64) |
| NGI-NEG-010 | Memory | Unsupported | `Memory/Unsupported/savepointDdlCombination.tc` | savepoint-crossing DDL reject | Pass (A4_64) |

## Planned or environment-blocked SQL families

These rows intentionally have no guessed `.tc` source.

| ID | Media | Area | Proposed source | Required oracle/contract | Status |
| --- | --- | --- | --- | --- | --- |
| NGI-CON-001 | Disk | Concurrency | `Disk/Concurrency/uniqueWaitCommit.tc` | deterministic two-client wait then commit | EnvironmentBlocked |
| NGI-CON-002 | Disk | Concurrency | `Disk/Concurrency/uniqueWaitRollback.tc` | deterministic two-client wait then rollback | EnvironmentBlocked |
| NGI-CON-003 | Disk | Concurrency | `Disk/Concurrency/disjointPartitionDml.tc` | synchronized disjoint DML | EnvironmentBlocked |
| NGI-CON-004 | Disk | Concurrency | `Disk/Concurrency/activeCursorDdl.tc` | final cursor/DDL lock contract | EnvironmentBlocked |
| NGI-CON-001 | Memory | Concurrency | `Memory/Concurrency/uniqueWaitCommit.tc` | deterministic two-client wait then commit | EnvironmentBlocked |
| NGI-CON-002 | Memory | Concurrency | `Memory/Concurrency/uniqueWaitRollback.tc` | deterministic two-client wait then rollback | EnvironmentBlocked |
| NGI-CON-003 | Memory | Concurrency | `Memory/Concurrency/disjointPartitionDml.tc` | synchronized disjoint DML | EnvironmentBlocked |
| NGI-CON-004 | Memory | Concurrency | `Memory/Concurrency/activeCursorDdl.tc` | final cursor/DDL lock contract | EnvironmentBlocked |
| NGI-DML-005 | Disk | DML | `Disk/DML/mergeAndReplacePatterns.tc` | target-version MERGE/UPSERT grammar | Planned |
| NGI-DML-005 | Memory | DML | `Memory/DML/mergeAndReplacePatterns.tc` | target-version MERGE/UPSERT grammar | Planned |
| NGI-DDL-008 | Disk | DDL/FIT | `Disk/DDL/rebuildFailureAtomicity.tc` | approved failure point and generation oracle | EnvironmentBlocked |
| NGI-DDL-008 | Memory | DDL/FIT | `Memory/DDL/rebuildFailureAtomicity.tc` | approved failure point and generation oracle | EnvironmentBlocked |
| NGI-BND-005 | Disk | Boundary | `Disk/Boundary/maximumKeyShape.tc` | final key-column and byte limits | Planned |
| NGI-BND-005 | Memory | Boundary | `Memory/Boundary/maximumKeyShape.tc` | final key-column and byte limits | Planned |
| NGI-NEG-007 | Disk | Unsupported | `Disk/Unsupported/tablespaceState.tc` | isolated ONLINE/OFFLINE transition fixture | EnvironmentBlocked |
| NGI-NEG-007 | Memory | Unsupported | `Memory/Unsupported/tablespaceState.tc` | isolated ONLINE/OFFLINE transition fixture | EnvironmentBlocked |

### Partially deferred branches

| Family | Deferred branch | Reason | Status |
| --- | --- | --- | --- |
| NGI-NEG-004 | partitioned/partial global, B_TREE2, user-defined type | target grammar/type fixture not confirmed | Planned |
| NGI-NEG-005 | Memory compression/dictionary, Disk clustered/index-only | target grammar not confirmed | Planned |
| NGI-NEG-006 | online and TOPDOWN build | target grammar not confirmed | Planned |
| NGI-NEG-008 | private/temporary table | isolated object fixture not confirmed | Planned |
| NGI-DDL-005 | direct constraint rename | target DDL grammar not confirmed | Planned |

## Lifecycle and deferred lanes

| ID/Lane | Media | Scenario | Blocker | Status |
| --- | --- | --- | --- | --- |
| NGI-D-LIF-001 | Disk | clean restart and segment reuse | restart helper contract | EnvironmentBlocked |
| NGI-D-LIF-002 | Disk | DML crash redo/undo | crash point and recovery oracle | EnvironmentBlocked |
| NGI-D-LIF-003 | Disk | CREATE/REBUILD/DROP crash matrix | approved FIT UIDs | EnvironmentBlocked |
| NGI-D-LIF-004 | Disk | corrupt meta/token startup failure | supported corruption fixture | EnvironmentBlocked |
| NGI-M-LIF-001 | Memory | clean restart composite rebuild | restart helper contract | EnvironmentBlocked |
| NGI-M-LIF-002 | Memory | abnormal shutdown after DML | crash point and rebuild oracle | EnvironmentBlocked |
| NGI-M-LIF-003 | Memory | duplicate during startup rebuild | pre-service failure oracle | EnvironmentBlocked |
| NGI-M-LIF-004 | Memory | variable-key multi-TBS rebuild | restart fixture | EnvironmentBlocked |
| AdminTool | Both | cascade, DESC, export/import, backup/restore | isolated admin/tool environment | EnvironmentBlocked |
| Replication | Both | base-row apply and version-gated DDL | deterministic two-server topology | EnvironmentBlocked |
| Performance | Both | comparison, capacity, long stress | calibrated baseline environment | EnvironmentBlocked |

Legacy hidden-index catalog upgrade/downgrade is excluded from this
incompatible new-version release rather than tracked as an environment-blocked
test lane.

## Readiness states

| State | Meaning |
| --- | --- |
| Planned | contract or syntax must be confirmed before source is written |
| EnvironmentBlocked | executable source depends on unavailable environment/helper/FIT contract |
| SourceOnly | `.tc` exists; no target execution or `.lst` |
| OracleReady | server output reviewed and tagged `.lst` added |
| Runnable | suite can be scheduled in the target environment |
| Pass | same target command passes after oracle installation |

All 114 linked SQL tests are `Pass (A4_64)`: 57 Disk and 57 Memory. Each
full-suite run reported `PASS 114`, zero failure/fatal/hang/jump/core/error,
and no skipped suite.

J057 also directly verified clean database creation, normal restart and
SIGKILL recovery with committed Memory/Disk native indexes. Lifecycle rows
above remain deferred as standalone NATC artifacts because the portable root
suite does not own the server process.
