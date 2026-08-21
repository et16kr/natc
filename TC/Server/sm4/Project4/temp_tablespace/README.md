# Simple TEMP tablespace NATC suite

This directory contains the NATC replacement surface for the Simple TEMP
tablespace feature. The root suite registers one `.ts` per top-level role; the
nested role suites contain 134 executable test cases in total. The former
`temp_tablespace_claude` gap suite is merged into these role folders rather than
being maintained as a second top-level suite.

## Directory roles

- `ddl/create`: CREATE syntax, catalog defaults, extent sizes, multi-file definitions
- `ddl/alter`: SIZE and AUTOEXTEND definition changes and boundary validation
- `ddl/tempfile`: ADD/DROP TEMPFILE membership and reuse behavior
- `ddl/binding`: user-to-TEMP binding through CREATE USER and ALTER USER
- `control`: CONTROL-phase RENAME, CREATE DATAFILE, and DISCARD lifecycle and rejections
- `safety/atomicity`: statement failure must not publish a partial definition
- `safety/binding`: active pathname/inode collision and retired-path reuse
- `safety/path`: path revalidation when the registered pathname is substituted
- `runtime/spill`: real sort/hash work-area spills, runtime growth, extent shapes, multi-file I/O
- `runtime/concurrency`: concurrent spill, AUTOEXTEND serialization, multi-user space isolation
- `runtime/exhaust`: work-area reservation refusal at AUTOEXTEND OFF and at MAXSIZE, and recovery
- `runtime/fileset`: runtime allocation preservation across file-set DDL
- `runtime/lifecycle`: extent reuse across repeated spills and release on session exit
- `recovery/restart`: ordinary restart and missing-file reconstruction
- `recovery/reconcile`: committed definition versus runtime size and foreign-header rejection
- `recovery/crash`: abrupt restart with a grown TEMP runtime, and around resize and file DDL
- `negative`: unsupported or invalid SQL with unchanged-state assertions
- `views`: public `V$TABLESPACES`, `V$DATAFILES`, `V$DISK_TEMP_STAT`, `V$DISK_TEMP_INFO`
  projection and the `SYS_USERS_` / `SYS_TBS_USERS_` catalog binding
- `regression/data`: guard that ordinary DATA tablespace routing is unchanged

Each role folder has a same-folder suite (`control/control.ts`,
`ddl/create/create.ts`, and so on). Intermediate suites such as `ddl/ddl.ts`
register their child role suites, while the root
[temp_tablespace.ts](temp_tablespace.ts) registers only top-level role suites.

## Oracle status

All 134 registered cases have a matching `_A4_64.lst` captured from an
inspected target run. Per `docs/TC_GUIDE.md`, helper `process.out` files and
other execution logs are not case oracles.

`runtime/spill/spill.ts` comments out four intentional future definitions:
`extent38Spill`, `extent67Spill`, `extentSizeSpillMatrix` and
`variableExtentSpill`. Their non-64-page
runtime support is outside the current server capability and was explicitly
excluded from this fix. The `.tc` definitions remain but are not registered as
executable cases, so their expected future behavior is not silently removed.

The original 77-case oracle audit is retained as a historical snapshot in
[ORACLE_REVIEW_20260818.md](ORACLE_REVIEW_20260818.md). Subsequent focused
diagnosis and verified oracle promotion are recorded in
[INVESTIGATION_STATUS_20260818.md](INVESTIGATION_STATUS_20260818.md). Per
`docs/TC_GUIDE.md`, expected output comes from an inspected target run rather
than a handwritten or guessed oracle.

## Coverage added 2026-08-20

These 19 cases close gaps the 2026-08-20 suite audit found. Each behavior below
was confirmed against a live server before the case was written; the exact
values the cases assert come from those observations, not from prediction.

| Case | Gap it closes | Confirmed behavior |
|---|---|---|
| `runtime/exhaust/exhaustAutoextendOff.tc` | no case exercised work-area exhaustion at all | `ERR-11184`, session survives, `ALLOCATED_PAGE_COUNT` returns to 0, `CURRSIZE` unchanged, a smaller spill then succeeds |
| `runtime/exhaust/exhaustAtMaxsize.tc` | AUTOEXTEND was never driven into its cap | grows to exactly `MAXSIZE` (512 pages), then `ERR-11184`; `INITSIZE` stays at the definition baseline |
| `runtime/exhaust/exhaustThenGrowRecovers.tc` | no case showed a refusal is operator-recoverable | resizing the exhausted file makes the same refused query succeed without a restart |
| `runtime/exhaust/exhaustThenAddTempfileRecovers.tc` | ADD/DROP TEMPFILE after a work-area refusal regressed during file-set publication work | adding capacity makes the same refused query succeed; subsequent DROP TEMPFILE and spill also succeed |
| `ddl/binding/alterUserTempTablespace.tc` | `ALTER USER ... TEMPORARY TABLESPACE` had zero coverage | rebinding updates `SYS_USERS_.TEMP_TBS_ID` and routes later sessions to the new space |
| `ddl/binding/rejectNonTempAsTempTablespace.tc` | the `ERR_INVALID_TEMP_TBS` guard was untested | `ERR-311E4` for DATA, memory, dictionary and undo targets; `ERR-1102A` for an unknown name; the previous binding is kept |
| `ddl/binding/dropBoundTempTablespace.tc` | dropping a bound TEMP space was unpinned | the drop is not guarded and leaves `TEMP_TBS_ID` dangling; a later spill is refused rather than faulting, and rebinding restores service |
| `runtime/lifecycle/repeatedSpillReusesExtents.tc` | nothing checked that freed extents return | six identical spills hold `CURRSIZE` at 7808 pages with `ALLOCATED_PAGE_COUNT` at 0 |
| `runtime/lifecycle/sessionExitReleasesRuntime.tc` | session teardown during TEMP use was untested | workers that exit without committing release every extent, and the capacity is immediately reusable |
| `views/diskTempStatProjection.tc` | `V$DISK_TEMP_STAT` / `V$DISK_TEMP_INFO` had zero coverage | both stay queryable and joinable; the live list is empty when idle and after a spill drains |
| `views/userTempBindingMeta.tc` | the catalog side of the binding had zero coverage | `SYS_USERS_` carries the binding for bound and unbound users; binding creates no implicit `SYS_TBS_USERS_` row, an explicit `ACCESS ... ON/OFF` does |
| `ddl/create/createDefaultsFromProperty.tc` | the property-default CREATE path was never taken | omitted clauses resolve to `USER_TEMP_FILE_INIT_SIZE` (12800 pages), `USER_TEMP_TBS_EXTENT_SIZE` (64 pages), AUTOEXTEND OFF, `SEGMENT MANAGEMENT MANUAL` |
| `negative/rejectFileSizeBeyondLimit.tc` | four size guards were unasserted | `ERR-11153`, `ERR-11154` on CREATE and ADD TEMPFILE, `ERR-11022` on ALTER AUTOEXTEND, with no orphan file and no definition change |
| `runtime/spill/sortOperatorMatrix.tc` | 68 of 75 spill hints were `DISTINCT_HASH` | `GROUP_SORT`, `USE_MERGE`, `UNION`, `MINUS`, `INTERSECT` and a bare `ORDER BY` all drive the space and release it; disk index build does not consume it |
| `runtime/concurrency/multiUserTempIsolation.tc` | every concurrency case ran one user against one space | two users with two bindings spill concurrently; each space keeps its own INITSIZE/NEXTSIZE and both quiesce; retiring one leaves the other working |
| `recovery/crash/abruptDuringResize.tc` | crash coverage had one kill point, during spill | after an abort around a 4M→128M grow, CURRSIZE is one of the two legal sizes and TOTAL_PAGE_COUNT matches it; further resizes are accepted and durable |
| `recovery/crash/abruptDuringFileDdl.tc` | no kill during ADD/DROP TEMPFILE | after an abort around each, the file count is legal, TOTAL_PAGE_COUNT equals the sum of live CURRSIZE, and file DDL is accepted again |
| `control/discardDoubleReject.tc` | `ERR-110FD` unasserted | a repeat DISCARD is refused, the state does not move, a live sibling is unaffected, and only DROP is accepted |
| `control/createDatafileTargetExists.tc` | `ERR-11025` ran only under NODISPLAY | an occupied target and an occupied AS target are both refused with the CONTROL output visible; the squatter is never adopted or unlinked |

`runtime/exhaust/exhaustAutoextendOff.tc` also covers the benign-error contract
in `src/sm/smi/smiTempTable.cpp`: `smERR_ABORT_NOT_ENOUGH_WORKAREA` is on the
`checkAndDump()` allow list, so exhaustion must arrive as a statement error and
never as the `IDE_ERROR( 0 )` at `smiTempTable.cpp:322`.

## Extent size is fixed at 64 pages (2026-08-20)

`SDT_WAEXTENT_PAGECOUNT` is a compile-time `64` (`src/sm/include/sdtDef.h:83`) and
`sdtWAExtentMgr::allocFreeNExtent` asserts on any other value
(`src/sm/sdt/sdtWAExtentMgr.cpp:880`). CREATE accepts a TEMP tablespace with a
different `EXTENTSIZE`, but the first spill into it aborts the server:

```
IDE_ASSERT( sExtDesc.mLength == SDT_WAEXTENT_PAGECOUNT ), [sdtWAExtentMgr.cpp:880]
```

This was reproduced on 2026-08-20 with `EXTENTSIZE 256K` (32 pages). It is the
same limitation that keeps `extent38Spill`, `extent67Spill` and
`variableExtentSpill` commented out of `runtime/spill/spill.ts`.

Consequence for this suite: **any registered case that spills must use
`EXTENTSIZE 512K`.** A case may still create a differently sized TEMP tablespace
to assert catalog projection, as `ddl/create/create_catalog.tc` and
`ddl/create/create_extent_256k.tc` do, provided nothing ever spills into it.

The scenario itself is preserved as `runtime/spill/extentSizeSpillMatrix.tc`,
commented out of `runtime/spill/spill.ts` alongside `extent38Spill`,
`extent67Spill` and `variableExtentSpill`. It drives 256K, 512K, 1M and 2M
extents through both a hash spill and a sort spill, with the 512K control first
so a fixture problem is distinguishable from missing extent support. It carries
no `_A4_64.lst` because on the current server it aborts the process rather than
returning a result. It is expected to run on the internal server once
non-64-page runtime support lands.

Why it is separate from the three older exclusions: `extent38Spill` (304K, 38
pages) and `extent67Spill` (536K, 67 pages) probe deliberately odd geometries,
while this case probes the round values a DBA actually types and that the
`ddl/create` cases already prove the catalog accepts. Those CREATE cases stop at
the projection and never spill, so the gap between "accepted at CREATE" and
"servable at runtime" is covered only here.

## File-set DDL after a spill (2026-08-20)

Found during the 2026-08-20 oracle capture run and **fixed the same day**. Once a
TEMP tablespace had served any work area, `ADD TEMPFILE` returned `ERR-11034`
naming a path that was never registered and `DROP TEMPFILE` returned `ERR-41082`
with `code=0x42000000`. The cause was a rollback-image validation that inspected
the pre-forward-apply snapshot; the misleading error codes were a second,
independent error-reporting defect in the two handlers. Both are fixed.

`runtime/spill/multiTempfileSpill.tc` regressed against its recorded oracle and
now passes against that same untouched oracle. The three `safety/binding`
failures recorded on 2026-08-19 are also resolved.

The late-suite `concurrentSpillWithFileDdl.tc` FATAL and the discarded-space
CREATING residue are resolved. Page I/O now distinguishes transient file-set
replacement from a missing owner and retries outside the registry mutex; startup
definition derivation omits only pure, uncommitted CREATING residue. T-03 still
has narrower reopen, V$ projection and no-exception-reader gaps, so this is not
recorded as complete reader coverage. Evidence and current limits are in
[FILESET_DDL_AFTER_SPILL_20260820.md](FILESET_DDL_AFTER_SPILL_20260820.md).

## Known execution issues (2026-08-19)

The integration run exposed the following server/runtime results. They are
recorded separately and were not converted into passing oracles or fixed as
part of this suite-layout change.

- [concurrentSpillWithShrink FATAL](CONCURRENT_SPILL_WITH_SHRINK_ISSUE_20260819.md)
- [runtimeSortHashMatrix FATAL](RUNTIME_SORT_HASH_MATRIX_ISSUE_20260819.md)
- [safety binding error-code differences](SAFETY_BINDING_ISSUES_20260819.md)

## References used for SQL and iSQL behavior

- `ALTIBASE/Documents/Manuals/Altibase_7.1/eng/SQL Reference.md`
- `ALTIBASE/Documents/Manuals/Altibase_7.1/eng/Administrator's Manual.md`
- `/home/et16/work/altidev4_gi/docs/manuals/altibase/Altibase_7.1/eng/Performance Tuning Guide.md`
- `/home/et16/work/altidev4_gi/docs/manuals/altibase/Altibase_7.1/eng/iSQL User's Manual.md`

The exact-version 7.1 manuals match the server generation used by these cases.
The repository's exact-version tuning and iSQL manuals were checked first. The
repository has no mirrored 7.1 SQL/Admin manuals, so the official
`ALTIBASE/Documents` 7.1 tree supplied those references.
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
