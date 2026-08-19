# Simple TEMP tablespace NATC suite

This directory contains the NATC replacement surface for the Simple TEMP
tablespace feature. The root suite registers one `.ts` per top-level role; the
nested role suites contain 115 executable test cases in total. The former
`temp_tablespace_claude` gap suite is merged into these role folders rather than
being maintained as a second top-level suite.

## Directory roles

- `ddl/create`: CREATE syntax, catalog defaults, extent sizes, multi-file definitions
- `ddl/alter`: SIZE and AUTOEXTEND definition changes and boundary validation
- `ddl/tempfile`: ADD/DROP TEMPFILE membership and reuse behavior
- `control`: CONTROL-phase RENAME, CREATE DATAFILE, and DISCARD lifecycle
- `safety/atomicity`: statement failure must not publish a partial definition
- `safety/binding`: active pathname/inode collision and retired-path reuse
- `safety/path`: path revalidation when the registered pathname is substituted
- `runtime/spill`: real sort/hash work-area spills, runtime growth, extent shapes, multi-file I/O
- `runtime/concurrency`: concurrent spill and AUTOEXTEND serialization
- `runtime/fileset`: runtime allocation preservation across file-set DDL
- `recovery/restart`: ordinary restart and missing-file reconstruction
- `recovery/reconcile`: committed definition versus runtime size and foreign-header rejection
- `recovery/crash`: abrupt restart with a grown TEMP runtime
- `negative`: unsupported or invalid SQL with unchanged-state assertions
- `views`: public `V$TABLESPACES` and `V$DATAFILES` runtime projection
- `regression/data`: guard that ordinary DATA tablespace routing is unchanged

Each role folder has a same-folder suite (`control/control.ts`,
`ddl/create/create.ts`, and so on). Intermediate suites such as `ddl/ddl.ts`
register their child role suites, while the root
[temp_tablespace.ts](temp_tablespace.ts) registers only top-level role suites.

## Oracle status

The current executable suite has 115 matching `_A4_64.lst` files for 115 cases.
`runtime/spill/spill.ts` comments out the three intentional future definitions:
`extent38Spill`, `extent67Spill`, and `variableExtentSpill`. Their non-64-page
runtime support is outside the current server capability and was explicitly
excluded from this fix. The `.tc` definitions remain but are not registered as
executable cases, so their expected future behavior is not silently removed.

The original 77-case oracle audit is retained as a historical snapshot in
[ORACLE_REVIEW_20260818.md](ORACLE_REVIEW_20260818.md). Subsequent focused
diagnosis and verified oracle promotion are recorded in
[INVESTIGATION_STATUS_20260818.md](INVESTIGATION_STATUS_20260818.md). Per
`docs/TC_GUIDE.md`, expected output comes from an inspected target run rather
than a handwritten or guessed oracle. Helper `process.out` files are execution
logs, not case oracles.

## Known execution issues (2026-08-19)

The integration run exposed the following server/runtime results. They are
recorded separately and were not converted into passing oracles or fixed as
part of this suite-layout change.

- [concurrentSpillWithShrink FATAL](CONCURRENT_SPILL_WITH_SHRINK_ISSUE_20260819.md)
- [runtimeSortHashMatrix FATAL](RUNTIME_SORT_HASH_MATRIX_ISSUE_20260819.md)
- [safety binding error-code differences](SAFETY_BINDING_ISSUES_20260819.md)

## References used for SQL and iSQL behavior

- `/home/et16/work/manual/Manuals/Altibase_7.1/eng/SQL Reference.md`
- `/home/et16/work/manual/Manuals/Altibase_7.1/eng/Administrator's Manual.md`
- `/home/et16/work/altidev4_gi/docs/manuals/altibase/Altibase_7.1/eng/Performance Tuning Guide.md`
- `/home/et16/work/altidev4_gi/docs/manuals/altibase/Altibase_7.1/eng/iSQL User's Manual.md`

The exact-version 7.1 manuals match the server generation used by these cases.
The repository's exact-version tuning and iSQL manuals were checked first. The
repository has no mirrored 7.1 SQL/Admin manuals, so the exact-version local
manual tree above supplied those references.
CONTROL tests follow the established `stdFunc.i` sysdba process pattern and do
not introduce external shell scripts.

The 7.1 SQL Reference `DROP TABLESPACE` section states that
`INCLUDING CONTENTS AND DATAFILES` physically removes every file belonging to a
disk tablespace. This also applies to user disk TEMP tablespaces: a live
2026-08-19 check created `CODEX_DROP_TEMP_VERIFY`, dropped it with that clause,
observed its catalog count change from one to zero, and confirmed that its
tempfile no longer existed. Cleanup therefore uses this single statement for
files still owned by the tablespace. An explicit `RM -f` remains appropriate
only for a file detached earlier by `DROP TEMPFILE`, or for a failed/foreign
target that never became part of the tablespace definition.

## Deliberate NATC boundary

The suite covers behavior observable through SQL, public views, filesystem
effects, concurrent iSQL clients, and server restart. It does not attempt to
replace unit-only fault injection for individual `open`/`sync`/`rename`/Anchor
failures, internal WAL/CLR byte images and private counters, forced allocator
interleavings that require an in-process barrier, or ASan/TSan lifetime checks.
Those conditions cannot be made deterministic through the NATC/iSQL surface;
encoding them as timing-only expected output would create a false oracle.
