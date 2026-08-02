# NativeGlobalIndexCodex tests

## Status

This directory contains executable tests for the native global index
implementation owned by SM. The V1 reinforcement adds portable single-session
transaction, create, query, DML, DDL, boundary, and unsupported coverage while
keeping environment-dependent work out of the root suite.

- Test sources: 114 .tc files (57 Disk, 57 Memory)
- V1 reinforcement: 74 .tc files (37 Disk, 37 Memory)
- Media groups: Disk and Memory
- Expected results: 114 reviewed `caseName_A4_64.lst` files
- Runtime status: two consecutive root-suite passes on 2026-08-02
- Target result: `PASS 114`, all failure/skip counters zero

| Area | Disk | Memory | Total |
| --- | ---: | ---: | ---: |
| Catalog | 2 | 2 | 4 |
| Create | 9 | 9 | 18 |
| Query | 10 | 10 | 20 |
| DML | 9 | 9 | 18 |
| Transaction | 4 | 4 | 8 |
| DDL | 9 | 9 | 18 |
| Boundary | 5 | 5 | 10 |
| Unsupported | 9 | 9 | 18 |
| Total | 57 | 57 | 114 |

`NativeGlobalIndexCodex.ts` is runnable on the A4_64 target. Every linked `.tc`
has a real target run, reviewed `.out`, tagged `.lst`, and two consecutive PASS
runs.

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
        Transaction/
        Concurrency/       # structured, unlinked, no executable source yet
        DDL/
        Boundary/
        Unsupported/
        Lifecycle/
      Memory/
        Catalog/
        Create/
        Query/
        DML/
        Transaction/
        Concurrency/       # structured, unlinked, no executable source yet
        DDL/
        Boundary/
        Unsupported/
        Lifecycle/
      Deferred/
        AdminTool/
        Replication/
        Performance/

Disk and Memory use the same functional taxonomy but do not share test
objects or expected-result files. This keeps media-specific failures visible.

## Runtime contract

Each .tc follows the current NATC source shape:

- INCLUDE stdFunc.i
- one DEF MAIN entry point
- INITIALIZATION, PREPARATION, TEST, FINALIZATION sectors
- deterministic ORDER BY for visible row sets
- best-effort cleanup only for objects created by that case
- no query against $GIT_* physical rows (catalog name-count checks are allowed)
- reviewed A4_64 expected-result file beside every linked case

Native identity is checked through SYSTEM_.SYS_INDICES_:

| Media | Expected INDEX_IMPL_TYPE | Expected INDEX_TABLE_ID |
| --- | ---: | ---: |
| Disk | 3 | 0 |
| Memory | 2 | 0 |

The numeric contract must be reconfirmed against the release candidate before
generating .lst files.

## Oracle strategy

The tests intentionally combine independent public oracles:

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
13. statement, savepoint, and whole-transaction rollback
14. CREATE/DDL failure atomicity and failed-name reuse
15. 64-index success, 65th-index rejection, and cascade cleanup
16. unsupported type, storage, build, media, and transaction combinations

Native index entries are not directly queried. Legacy hidden-index catalog
upgrade and downgrade are outside this incompatible new-version release scope.

## Negative cases

Unsupported tests intentionally execute SQL expected to return an error,
then query the original table and catalog to prove that the existing native
index remains usable and no fallback object was published.

Every new negative case records pre/post logical index counts, the surviving
native index identity, hidden-fallback count, ordered query results, follow-up
DML, and normal reuse of a rejected name where practical. The exact error text
is not frozen in these sources. Capture it only after the server error mapping
is final.

## Portable-suite boundary

`Transaction` and `Boundary` are linked from each media root. `Concurrency`
has an empty, unlinked suite because the repository does not provide a verified
same-server two-session synchronization idiom. Timing-only sleeps were not
introduced.

The following planned families have no executable `.tc` yet:

- NGI-CON-001 through NGI-CON-004: deterministic multi-session contract needed
- NGI-DML-005: target-version MERGE/UPSERT syntax not confirmed
- NGI-DDL-008: reproducible REBUILD failure requires an approved FIT point
- NGI-BND-005: maximum key dimensions need final manual/implementation limits
- NGI-NEG-007: ONLINE/OFFLINE tablespace behavior needs a state-transition fixture

`TEST_MATRIX.md` is also the expected-result manifest. Every linked path has a
reviewed sibling named `<caseName>_A4_64.lst` and passed two full-suite runs.

## Lifecycle boundary

Lifecycle directories contain planned restart/recovery matrices rather than
invented executable helpers.

- Memory must rebuild the global tree from recovered base rows.
- Disk must recover and bind the committed GLOBAL_V1 segment.
- restart, process kill, multi-server replication, and fault injection require
  an explicit environment contract.

Those scenarios should become executable artifacts only after the target
server lifecycle helper, timeout, and log oracle are known.

For J057, lifecycle behavior was verified directly outside the portable root
suite: clean database creation, normal restart, and SIGKILL recovery all
succeeded with committed Memory/Disk native indexes. After each restart the
catalog remained Memory type 2 / Disk type 3, `INDEX_TABLE_ID=0`, hidden-object
count 0, and all fixture rows were readable. The server error log did not grow.

## References used

- NATC source guide: docs/TC_GUIDE.md
- legacy baseline: qp4/Project3/PROJ-1624-GlobalIndex root suite
- iSQL behavior:
  `altidev4_gi/docs/manuals/altibase/trunk/eng/iSQL User's Manual.md`
- hint syntax:
  `altidev4_gi/docs/manuals/altibase/trunk/eng/Performance Tuning Guide.md`
- native contract: server repository native-global-index design documents

The exact local manual files used for this reinforcement were:

- `/home/et16/work/altidev4_gi/docs/manuals/altibase/trunk/eng/iSQL User's Manual.md`
- `/home/et16/work/altidev4_gi/docs/manuals/altibase/trunk/eng/Performance Tuning Guide.md`
