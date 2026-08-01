# NativeGlobalIndexCodex test matrix

## SQL prototypes

| ID | Media | Area | Source | Primary oracle |
| --- | --- | --- | --- | --- |
| NGI-D-CAT-001 | Disk | Catalog | Disk/Catalog/implementationType.tc | type 3, INDEX_TABLE_ID 0 |
| NGI-D-CAT-002 | Disk | Catalog | Disk/Catalog/noHiddenObjects.tc | derived hidden object count 0 |
| NGI-D-CRT-001 | Disk | Create | Disk/Create/partitionKinds.tc | range/list/hash create and scan |
| NGI-D-CRT-002 | Disk | Create | Disk/Create/keyAndConstraint.tc | fixed/variable, PK/UK, unique |
| NGI-D-CRT-003 | Disk | Create | Disk/Create/functionBased.tc | expression key create and update |
| NGI-D-QRY-001 | Disk | Query | Disk/Query/rangeOrderPruning.tc | index/full scan result equality |
| NGI-D-QRY-002 | Disk | Query | Disk/Query/localGlobalCoexist.tc | local/native access coexistence |
| NGI-D-QRY-003 | Disk | Query | Disk/Query/predicateMatrix.tc | binds, NULL, IN, LIKE, tuple, grouping |
| NGI-D-QRY-004 | Disk | Query | Disk/Query/joinSubqueryView.tc | join, outer join, subquery, view |
| NGI-D-DML-001 | Disk | DML | Disk/DML/insertUpdateDelete.tc | exact ordered rows after each DML |
| NGI-D-DML-002 | Disk | DML | Disk/DML/rowMovementAndUnique.tc | owner move and global uniqueness |
| NGI-D-DML-003 | Disk | DML | Disk/DML/hashListMutation.tc | hash/list key and owner mutation |
| NGI-D-DML-004 | Disk | DML | Disk/DML/insertSelectMultiIndex.tc | INSERT SELECT with three indexes |
| NGI-D-DDL-001 | Disk | DDL | Disk/DDL/rebuildAndDrop.tc | rebuild visibility and drop |
| NGI-D-DDL-002 | Disk | DDL | Disk/DDL/cascadeDrop.tc | table cascade leaves no index row |
| NGI-D-DDL-003 | Disk | DDL | Disk/DDL/schemaEvolution.tc | add/rename/drop column continuity |
| NGI-D-DDL-004 | Disk | DDL | Disk/DDL/truncateAndRename.tc | rename, truncate, and index reuse |
| NGI-D-NEG-001 | Disk | Unsupported | Disk/Unsupported/partitionDdl.tc | topology DDL pre-change rejection |
| NGI-D-NEG-002 | Disk | Unsupported | Disk/Unsupported/buildOptions.tc | nologging/parallel/disable rejection |
| NGI-D-NEG-003 | Disk | Unsupported | Disk/Unsupported/splitMergePartition.tc | split/merge pre-change rejection |
| NGI-M-CAT-001 | Memory | Catalog | Memory/Catalog/implementationType.tc | type 2, INDEX_TABLE_ID 0 |
| NGI-M-CAT-002 | Memory | Catalog | Memory/Catalog/noHiddenObjects.tc | derived hidden object count 0 |
| NGI-M-CRT-001 | Memory | Create | Memory/Create/partitionKinds.tc | range/list/hash create and scan |
| NGI-M-CRT-002 | Memory | Create | Memory/Create/keyAndConstraint.tc | variable values, PK/UK, unique |
| NGI-M-CRT-003 | Memory | Create | Memory/Create/functionBased.tc | expression key create and update |
| NGI-M-QRY-001 | Memory | Query | Memory/Query/rangeOrderPruning.tc | range/order/pruning equality |
| NGI-M-QRY-002 | Memory | Query | Memory/Query/localGlobalCoexist.tc | local/native access coexistence |
| NGI-M-QRY-003 | Memory | Query | Memory/Query/predicateMatrix.tc | binds, NULL, IN, LIKE, tuple, grouping |
| NGI-M-QRY-004 | Memory | Query | Memory/Query/joinSubqueryView.tc | join, outer join, subquery, view |
| NGI-M-DML-001 | Memory | DML | Memory/DML/insertUpdateDelete.tc | exact ordered rows after each DML |
| NGI-M-DML-002 | Memory | DML | Memory/DML/rowMovementAndUnique.tc | owner move and global uniqueness |
| NGI-M-DML-003 | Memory | DML | Memory/DML/hashListMutation.tc | hash/list variable-key owner mutation |
| NGI-M-DML-004 | Memory | DML | Memory/DML/insertSelectMultiIndex.tc | INSERT SELECT with three indexes |
| NGI-M-DDL-001 | Memory | DDL | Memory/DDL/rebuildAndDrop.tc | rebuild visibility and drop |
| NGI-M-DDL-002 | Memory | DDL | Memory/DDL/cascadeDrop.tc | table cascade leaves no index row |
| NGI-M-DDL-003 | Memory | DDL | Memory/DDL/schemaEvolution.tc | add/rename/drop column continuity |
| NGI-M-DDL-004 | Memory | DDL | Memory/DDL/truncateAndRename.tc | rename, truncate, and index reuse |
| NGI-M-NEG-001 | Memory | Unsupported | Memory/Unsupported/partitionDdl.tc | topology DDL pre-change rejection |
| NGI-M-NEG-002 | Memory | Unsupported | Memory/Unsupported/mediaAndOptions.tc | media/parallel/disable rejection |
| NGI-M-NEG-003 | Memory | Unsupported | Memory/Unsupported/splitMergePartition.tc | split/merge pre-change rejection |

## Planned lifecycle cases

| ID | Media | Scenario | Blocker |
| --- | --- | --- | --- |
| NGI-D-LIF-001 | Disk | clean restart and segment reuse | restart helper contract |
| NGI-D-LIF-002 | Disk | DML crash redo/undo | crash point and recovery oracle |
| NGI-D-LIF-003 | Disk | CREATE/REBUILD/DROP crash matrix | fault injection owner |
| NGI-D-LIF-004 | Disk | corrupt meta/token startup failure | supported corruption fixture |
| NGI-M-LIF-001 | Memory | clean restart composite rebuild | restart helper contract |
| NGI-M-LIF-002 | Memory | abnormal shutdown after DML | crash point and rebuild oracle |
| NGI-M-LIF-003 | Memory | duplicate during startup rebuild | pre-service failure oracle |
| NGI-M-LIF-004 | Memory | variable-key multi-TBS rebuild | second memory TBS fixture |

## Readiness states

| State | Meaning |
| --- | --- |
| SourceOnly | .tc exists, no target execution or .lst |
| OracleReady | server output reviewed and tagged .lst added |
| Runnable | suite can be scheduled in the target environment |
| Pass | same target command passes after oracle installation |

All current SQL prototypes are SourceOnly.
