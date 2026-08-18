# Simple TEMP tablespace NATC suite

This directory contains the NATC replacement surface for the Simple TEMP
tablespace feature. The root suite registers one `.ts` per test folder; those
folder suites contain 82 test cases in total.

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
- `recovery/restart`: ordinary restart and missing-file reconstruction
- `recovery/reconcile`: committed definition versus runtime size and foreign-header rejection
- `recovery/crash`: abrupt restart with a grown TEMP runtime
- `negative`: unsupported or invalid SQL with unchanged-state assertions
- `views`: public `V$TABLESPACES` and `V$DATAFILES` runtime projection
- `regression/data`: guard that ordinary DATA tablespace routing is unchanged

Each role folder has a same-folder suite (`control/control.ts`,
`ddl/create/ddl_create.ts`, and so on). The root [temp_tablespace.ts](temp_tablespace.ts)
registers only those folder suites.

## Oracle status

The current suite has 79 matching `_A4_64.lst` files for 82 cases. The three
intentional exceptions are `extent38Spill`, `extent67Spill`, and
`variableExtentSpill`: their non-64-page runtime support is outside the current
server capability and was explicitly excluded from this fix. They remain test
definitions without a promoted oracle so their expected future behavior is not
silently removed.

The original 77-case oracle audit is retained as a historical snapshot in
[ORACLE_REVIEW_20260818.md](ORACLE_REVIEW_20260818.md). Subsequent focused
diagnosis and verified oracle promotion are recorded in
[INVESTIGATION_STATUS_20260818.md](INVESTIGATION_STATUS_20260818.md). Per
`docs/TC_GUIDE.md`, expected output comes from an inspected target run rather
than a handwritten or guessed oracle. Helper `process.out` files are execution
logs, not case oracles.


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

## Deliberate NATC boundary

The suite covers behavior observable through SQL, public views, filesystem
effects, concurrent iSQL clients, and server restart. It does not attempt to
replace unit-only fault injection for individual `open`/`sync`/`rename`/Anchor
failures, internal WAL/CLR byte images and private counters, forced allocator
interleavings that require an in-process barrier, or ASan/TSan lifetime checks.
Those conditions cannot be made deterministic through the NATC/iSQL surface;
encoding them as timing-only expected output would create a false oracle.
