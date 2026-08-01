# NativeGlobalIndexCodex prototype tests

## Status

This directory contains source-only prototype tests for the native global
index implementation owned by SM.

- Test sources: 40 .tc files (20 Disk, 20 Memory)
- Media groups: Disk and Memory
- Expected results: not generated
- Runtime status: blocked until the native SQL feature gate is open
- Default oracle to generate later: caseName_A4_64.lst

Do not schedule NativeGlobalIndexCodex.ts in a normal regression run yet.
The .ts hierarchy exists to validate the intended suite structure, but every
.tc still needs a real target run, reviewed .out, tagged .lst, and a second
PASS run.

## Layout

    NativeGlobalIndexCodex/
      NativeGlobalIndexCodex.ts
      TEST_MATRIX.md
      LEGACY_COVERAGE.md
      Disk/
        Catalog/
        Create/
        Query/
        DML/
        DDL/
        Unsupported/
        Lifecycle/
      Memory/
        Catalog/
        Create/
        Query/
        DML/
        DDL/
        Unsupported/
        Lifecycle/

Disk and Memory use the same functional taxonomy but do not share test
objects or expected-result files. This keeps media-specific failures visible.

## Prototype contract

Each .tc follows the current NATC source shape:

- INCLUDE stdFunc.i
- one DEF MAIN entry point
- INITIALIZATION, PREPARATION, TEST, FINALIZATION sectors
- deterministic ORDER BY for visible row sets
- best-effort cleanup only for objects created by that case
- no $GIT_* physical-table oracle
- no guessed expected-result file

Native identity is checked through SYSTEM_.SYS_INDICES_:

| Media | Expected INDEX_IMPL_TYPE | Expected INDEX_TABLE_ID |
| --- | ---: | ---: |
| Disk | 3 | 0 |
| Memory | 2 | 0 |

The numeric contract must be reconfirmed against the release candidate before
generating .lst files.

## Oracle strategy

The prototypes intentionally combine independent public oracles:

1. catalog implementation type and index-table identity
2. ordered SQL results
3. INDEX-hinted and FULL SCAN-hinted result equivalence
4. cross-partition uniqueness
5. DML and row-movement results
6. object lifetime after REBUILD, DROP, and DROP TABLE
7. persistent-change absence after unsupported DDL
8. function-based key maintenance after UPDATE
9. bind, NULL, IN, LIKE, tuple, DISTINCT, and GROUP BY predicates
10. join, outer join, correlated subquery, and view results
11. hash/list row movement and multi-index INSERT SELECT
12. schema evolution, index rename, and whole-table TRUNCATE reuse

Native index entries are not directly queried. Hidden $GIT_* tables are
expected only in a separate legacy-upgrade compatibility suite, not here.

## Negative cases

Unsupported prototypes intentionally execute SQL expected to return an error,
then query the original table and catalog to prove that the existing native
index remains usable and no fallback object was published.

The exact error text is not frozen in these sources. Capture it only after the
server error mapping is final.

## Lifecycle boundary

Lifecycle directories contain planned restart/recovery matrices rather than
invented executable helpers.

- Memory must rebuild the global tree from recovered base rows.
- Disk must recover and bind the committed GLOBAL_V1 segment.
- restart, process kill, multi-server replication, and fault injection require
  an explicit environment contract.

Those scenarios should become executable artifacts only after the target
server lifecycle helper, timeout, and log oracle are known.

## References used

- NATC source guide: docs/TC_GUIDE.md
- legacy baseline: qp4/Project3/PROJ-1624-GlobalIndex root suite
- iSQL behavior:
  `altidev4_gi/docs/manuals/altibase/trunk/eng/iSQL User's Manual.md`
- hint syntax:
  `altidev4_gi/docs/manuals/altibase/trunk/eng/Performance Tuning Guide.md`
- native contract: server repository native-global-index design documents
