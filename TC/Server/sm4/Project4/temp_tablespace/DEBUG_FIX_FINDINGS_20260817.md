# TEMP tablespace NATC debugging findings (focused fix complete)

- Date: 2026-08-17
- Scope: `temp_tablespace.ts` and the experimental TEMP tablespace implementation
- Product tree: `/home/et16/work/altidev4_gi` (`workspace/simple_temp_tablespace`)
- NATC tree: `/home/et16/work/natc` (`workspace/temp_tablespace`)
- Status: focused product fix and regression verification complete; **no commit and no push**
- The complete NATC suite still lacks reviewed `.lst` oracles, so this is a
  product/focused-case completion record rather than a claim that all 62 NATC
  cases compare as PASS.

## Baseline

The latest suite result before the current experimental fixes was:

```text
PASS 19 / FAIL 41 / FATAL 2 / HANG 0 / CORED 0 / ERROR 0
```

The corresponding analysis and raw result records are:

- `FAILURE_CODE_ANALYSIS_20260817.md`
- `TEST_RESULT_20260817.md`
- `*_A4_64.out` and `work/log/report.log`

Most failing cases have no oracle (`.lst`), so an output comparison failure alone
does not prove a product defect. The debugging below uses source paths, direct SQL,
server traces, and focused rebuilds to separate product defects from missing-oracle
failures.

## Confirmed or directly reproduced causes

### 1. First disk TEMP extent used PID 0

The first standard TEMP file is file ID 0 and the sparse allocator returns extent
index 0. Therefore the first logical page is:

```text
SD_CREATE_PID(file=0, page=0) == 0 == SM_NULL_PID
```

The existing TEMP work-area consumer asserts that a successful extent must not have
`SM_NULL_PID`. This explains both original FATAL cases at the first disk TEMP spill:

- `runtimeAutoextend.tc`
- `runtimeResizeRestart.tc`

Experimental product change: reserve PID 0 in the TEMP extent allocator. The bridge
unit fixture was also adjusted so the production non-null contract is explicit.

### 2. DROP runtime replacement happened before drain release

The original DROP finish path replaced the runtime file/extent objects and then
released active-operation drains that still referenced the old objects. This was a
use-after-replace ordering bug. The experimental path now performs:

```text
definition apply -> release/drain old runtime -> FINISH runtime replacement
```

Runtime replacement is now candidate-first: the complete unpublished extent,
AUTOEXTEND, body, bridge, and file bundle is built before any live pointer changes.
The replacement blocks new bridge leases, waits for existing leases, refuses a
non-quiescent allocator, swaps the complete bundle once, and then destroys the
before-image. Candidate construction or quiescence failure leaves the old runtime
usable. The DROP finish callback now returns `IDE_RC`; a finish failure invokes the
component rollback path instead of silently committing a mixed definition/runtime
state. Unit tests cover allocated-extent refusal, candidate failure, finish failure,
and successful replacement.

### 3. Failed multi-file ADD left the standard file-ID cursor advanced

The standard lane allocates `mNewFileID` before all files in a multi-file ADD are
known to be valid. On rollback, the original implementation restored nodes but not
the cursor. A failed two-file ADD therefore consumed IDs and the next valid ADD
could start from a stale cursor.

Experimental fix: save `mOriginalNewFileID` at operation start and restore it on ADD
rollback while holding the binding gate. Direct SQL reproduced the sequence:

1. multi-file ADD with a deliberate filename collision -> expected failure;
2. valid two-file ADD immediately afterward -> success;
3. `V$TABLESPACES` showed three files with IDs 0, 1, 2.

This confirms the cursor restoration fixes the observed retry failure.

### 4. Multi-file DROP could publish one file before a later target failed

`qdtAlter::executeDropFile()` historically loops over `oldFileNames` and invokes the
component removal once per target. The TEMP component published the runtime after
each individual target. For a statement such as:

```sql
ALTER TABLESPACE T DROP TEMPFILE '02.dbf', '01.dbf';
```

the first target could publish a two-file runtime, then the primary file (ID 0)
would fail. SQL definition rollback restored three files, but runtime remained at
two files. The next valid DROP then failed with an internal generation/state error.

The final path is statement-sized end to end. `qdtAlter::executeDropFile()` collects
the complete target array and calls `smiTableSpace::removeDataFiles()`, which forwards
one request through `sdpTableSpace::removeDataFiles()`. The TEMP handler resolves and
canonicalizes every target, creates one component operation, applies one standard
lane DROP, and publishes one definition/runtime after-image. Any primary,
unresolved, active/HWM, standard-lane, or finish failure rolls the whole target set
back. Non-TEMP tablespaces retain the existing single-file handler behavior behind
the batch adapter. Parser, validation, public schema, and existing error mapping are
unchanged.

Important implementation correction: the first version passed
`SMI_TBS_LOCATION_DISK` to `smiTableSpace::getAbsPath()`. That macro is a bit-mask
(`0x01000000`), not the `smiTBSLocation` enum value. The resulting assert at
`sctTableSpaceMgr.cpp:2555` stopped the server during the first focused test. The
call now passes `SMI_TBS_DISK` (enum value 0), and QP/server binaries were rebuilt.
This correction is required before judging the QP mitigation.

### 5. Definition/runtime generation drift

The TEMP owner has definition, module, extent, autoextend, and view generations that
must move together. Earlier experimental code published a new definition while one
or more runtime components retained the old generation. `V$TABLESPACES` and
`V$DATAFILES` reject such mixed snapshots with `ERR-41082`; fixed-table projection
can then make later unrelated test cases fail as well.

The fixed path synchronizes generation publication and refreshes runtime state for
ALTER SIZE, AUTOEXTEND, ADD, and DROP. DROP drains are advanced to the after-image
generation before release, and ADD/DROP use complete runtime images rather than
leaving component-sized arrays one generation behind.

### 6. Other experimental fixes already present

- AUTOEXTEND standard-node runtime I/O uses the audited
  `sdpteStandardNode::beginFileIO()/endFileIO()` bridge. The TEMP component no
  longer calls `sddDiskMgr::prepareIO()/completeIO()` directly, preserving the
  storage-layer ownership boundary.
- ALTER SIZE refreshes runtime capacity and drains the old generation.
- ALTER AUTOEXTEND OFF normalizes the QP sentinel `next=1` to runtime `next=0`.
- Same-value AUTOEXTEND is treated as a no-op without an unnecessary commit.
- Configured AUTOEXTEND owners publish their updated runtime values.
- UNLIMITED is normalized to the standard owner's logical ceiling (product maximum
  minus the header page), not the raw global page maximum.
- ADD TEMPFILE attributes receive the current `mSpaceID` before validation.
- DROP path names are canonicalized consistently and the post-DROP generation is
  refreshed.
- Restart reconciliation recreates a missing TEMP tempfile. A focused reversible
  test renamed a tempfile aside, restarted the server, and observed the file
  recreated with the expected tablespace row.

## Focused verification record

### Builds

Completed successfully (warnings only):

```text
make -C src/sm/sdp/sdpte -j2
make -C src/sm/sdp -j2
make -C src/sm/smi -j2
make -C src/sm/lib -j2
make -C src/qp/qdt -j2
make -C src/qp/lib -j2
make -C src/mm/main -j2
```

The component gates and unit/integration suites also returned exit code 0. The
following aggregate targets were rerun after the final code changes:

```text
make -C src/sm/unittest sdpte_allocator_runtime
make -C src/sm/unittest sdpte_concurrency_error
make -C src/sm/unittest sdpte_sql_view
make -C src/sm/unittest sdpte_definition_projection
make -C src/sm/unittest sdpte_standard_node_io
make -C src/sm/unittest sdpte_format_binding_identity
make -C src/sm/unittest sdpte_definition_resize_config
make -C src/sm/unittest sdpte_recovery_control
make -C src/sm/unittest sdpte_projection_durability
make -C src/sm/unittest sdpte_change_surface
make -C src/sm/unittest sdpte_startup_reconcile
make -C src/sm/unittest sdpte_restart_crash
make -C src/sm/unittest sdpte_no_durability
```

Notable aggregate results include 55/55 concurrency/error rows, 36/36 allocator
runtime rows, 32/32 projection/durability rows, and all change-surface,
shared-diff, SQL-matrix, binding, no-durability, startup, restart, reset, and
recovery checks passing. The no-durability gate reviewed 84 files, 955 external
call sites, and 128 durable-state files. The product server linked successfully
and `server restart` completed recovery and startup with the final binary.

After removing the temporary debug logging, the same SM/QP/MM build chain was
run again successfully, the extent-bridge unit binary again returned exit code
0, and `server restart` completed successfully.  A post-build direct spill
returned `PASS_POSTBUILD = 1` and `PASS_POSTBUILD_AUTOEXTEND = 1`.

The post-build QP atomicity replay also succeeded: dropping a non-primary file
followed by primary ID 0 returned `ERR-11036` while the catalog stayed at three
files; dropping the two non-primary files then succeeded and left one file.

### Direct SQL verification

- Failed multi-file ADD followed by valid multi-file ADD: valid retry succeeded.
- Single ADD followed by DROP and fixed-table query: succeeded.
- Missing tempfile across server restart: server started and recreated the file.

### Statement-sized DROP verification

A fresh `SDPTE_DROP_QP_817` tablespace was used during diagnosis. The first
preflight implementation exposed an incorrect `SMI_TBS_LOCATION_DISK` enum usage;
that implementation was replaced by the statement-sized SMI/component adapter.
The final `addDropTempfile.tc` replay proves the complete behavior: a statement
that lists a removable secondary file before primary ID 0 returns the expected
in-use error and leaves all three files/size counters unchanged; a following DROP
of both secondary files succeeds and leaves only ID 0. `PASS_FAILED_DROP_ATOMIC`
and `PASS_DROP_TEMPFILES` are both 1.

### FATAL path direct verification (completed)

The two former FATAL scenarios were replayed with equivalent direct `is` SQL
after rebuilding `sdpte`, QP, and the server binary.  The test used a 1 MiB
TEMPFILE, `AUTOEXTEND ON NEXT 1M MAXSIZE 128M`, `EXTENTSIZE 512K`, a 30,000-row
`VARCHAR(2000)` source table, and `DISTINCT_HASH` forced to disk TEMP.

Observed results:

1. First spill returned `PASS_FIRST_SPILL = 1`; `V$DATAFILES.CURRSIZE` grew to
   7808 pages and `V$TABLESPACES.ALLOCATED_PAGE_COUNT` stayed 0.
2. `MAXSIZE 2M` was rejected with the expected current-size error and left the
   runtime image unchanged.
3. `ALTER TEMPFILE ... SIZE 1M` shrank both `CURRSIZE` and
   `TOTAL_PAGE_COUNT` to 128 pages; a second spill again returned 1 and grew the
   runtime image.
4. `ALTER TEMPFILE ... SIZE 8M` produced 1024 pages; a third spill returned 1
   and grew back to 7808 pages.
5. `/home/et16/work/altidev4/altibase_home/bin/server restart` completed
   recovery/startup successfully.  The existing 7808-page surplus was retained,
   allocation count was 0, and a post-restart spill returned
   `PASS_POST_RESTART_SPILL = 1`.

The first follow-up `V$DATAFILES` query in an earlier run used the nonexistent
column `CUR_SIZE`; that was a query typo (`CURRSIZE` is the valid column), not a
server failure.  Cleanup of the focused objects completed successfully.

### Final focused NATC invocation (2026-08-17 22:45–22:51 KST)

With the full NATC/ATAF environment (`ATAF_RESULT_SUFFIX=_A4_64`,
`ATAF_ORACLE_SUFFIX=_A4_64`) and the running STAF service, the focused cases were
invoked again through `ntiRunTest` after the final product rebuild and server
restart. The runner summary for each case is `FATAL: 0 HANG: 0 CORED: 0 ERROR: 0`,
and the generated transcripts contain no unexpected server assert:

- `runtimeAutoextend_A4_64.out`: `PASS_DISTINCT_HASH = 1` and
  `PASS_RUNTIME_AUTOEXTEND = 1`.
- `runtimeResizeRestart_A4_64.out`: `PASS_FIRST_SPILL`,
  `PASS_RUNTIME_R_GT_8M`, `PASS_REJECT_MAX_BELOW_R`, `PASS_T_EQ_D_LT_R`,
  `PASS_SECOND_SPILL`, `PASS_SECOND_R_GT_8M`, `PASS_D_LT_T_LT_R`,
  `PASS_THIRD_SPILL`, `PASS_PRE_RESTART_SURPLUS`, and
  `PASS_RESTART_REUSES_R` are all 1.
- `addDropTempfile_A4_64.out`: `PASS_FAILED_ADD_ATOMIC`,
  `PASS_ADD_TEMPFILES`, `PASS_FAILED_DROP_ATOMIC`, and `PASS_DROP_TEMPFILES`
  are all 1. The two `ERR-*` rows are the deliberately induced failed ADD and
  primary-file DROP checks.

NATC reports these cases as `FAIL` because the focused outputs do not have reviewed
matching `.lst` oracles. All three final runner invocations terminated normally
within their explicit timeouts, and the server remained healthy after the internal
restart. Do not promote these outputs to permanent `.lst` files until the intended
NATC lifecycle and oracle policy are reviewed.

A final `SELECT 1 AS SERVER_HEALTH FROM DUAL` returned 1. Filtering the SM, error,
and boot traces from 22:40 KST (the final rebuild/restart window) found no FATAL,
assert, SIGABRT/SIGSEGV, core-dump, or `[SDPTE-DEBUG]` marker.

### Oracle review and promotion (completed)

All 62 `*_A4_64.out` files were reviewed against their TC intent. Every output has
only `PASS_* = 1`, and none contains a product FATAL, assert, SIGABRT/SIGSEGV,
core-dump, or runner error marker. Expected negative-path `ERR-*` rows were checked
against the surrounding TC operation rather than treated as automatic failures.

Thirty-eight missing/empty `.lst` files were promoted from reviewed outputs. With
the 19 existing matching oracles, 57 non-empty oracles now match their output
byte-for-byte. A complete `temp_tablespace.ts` rerun after promotion produced:

```text
PASS: 57 FAIL: 5 FATAL: 0 HANG: 0 JUMP: 0 CORED: 0 ERROR: 0
```

The five remaining comparison failures were deliberately not promoted:

- `alterSizeAutoextend`: repeats the default `COMPRESSED LOGGING` value and receives
  `ERR-11115`; the TC does not yet state that this is its expected contract.
- `create_08`: has the same default-value/expected-error ambiguity.
- `adddrop_04` and `adddrop_05`: the ADD phase encounters pre-existing secondary
  files, so the following DROP error is environmental/secondary rather than the
  intended clean ADD/DROP result. These cases are not deterministic without
  explicit pre-test physical-file cleanup.
- `reject_05`: omits the `ALTER` keyword before tablespace-level `AUTOEXTEND` and
  therefore stops at parser `ERR-31001` instead of the intended semantic rejection.

No `.lst` was created for these five cases. The server remained healthy after the
full rerun and a final health query returned 1.

### Output review: `auto_08.tc` was an incorrect oracle/assertion

The generated `auto_08_A4_64.out` was the only focused output with a semantic
`PASS_* = 0`.  Its SQL attempted `AUTOEXTEND ON ... MAXSIZE 8M` on an 8 MiB
file.  Existing Altibase DDL validation rejects `MAXSIZE <= CURRSIZE` with
`ERR-1101F`, and the datafile remains `CURRSIZE=1024`, `AUTOEXTEND=0`,
`NEXTSIZE=0`, `MAXSIZE=0`.  This is consistent with `sddDiskMgr`'s standard
AUTOEXTEND validation, not a TEMP implementation regression.  The testcase was
corrected to make the rejection intentional and assert that all attributes stay
unchanged; no product change is required for this case.
The checked-in working-tree `.tc` now contains the corrected assertion.  The
old `.out` shown in the directory was not regenerated because the NATC wrapper
did not reach execution before its timeout; it must not be used as the new
oracle.

## Remaining certification limits

1. NATC `.lst` files are absent or stale for many cases. Focused product success
   does not make the complete 62-case suite compare as PASS until stable oracle
   output is reviewed under the project's oracle policy.
2. File-set runtime replacement intentionally requires an allocation-free,
   quiescent TEMP space. New bridge leases are blocked and existing leases are
   drained; if allocations remain, the operation fails and retains the old runtime.
   The unit suite proves this refusal/retention contract. This is a safety contract,
   not an unresolved partial-publication path.
3. The temporary `[SDPTE-DEBUG]` logs used during investigation have been removed
   from the product tree; `rg` finds no remaining marker under `src/sm/sdp/sdpte`.
4. The existing unrelated worktree changes and deleted `.empty` marker files were
   preserved; no cleanup/reset/commit was performed.

## Change policy

At the time of this debugging pass, all product changes listed here were
experimental working-tree changes only. No commit, push, branch rewrite,
destructive source reset, or NATC oracle mass-update was performed during that
pass. The later checkpoint commits and pre-commit corrections are recorded in
`PRE_COMMIT_CODE_REVIEW_20260818.md` and supersede the provisional delivery
status above.

## 2026-08-18 final pre-commit addendum

- Protected `sctTableSpaceMgr` source was restored to its approved baseline;
  atomic TEMP rename now composes existing lookup APIs inside the TEMP callback.
- The pre-existing per-tablespace lookup miss behavior is contained only at the
  new callback boundary; legacy DATA/UNDO behavior is unchanged.
- The three non-64 future definitions are excluded from the executable suite,
  leaving 79 executable cases and 79 non-empty oracles.
- `sdpte_change_surface`, `sdpte_wiring`, `sdpte_no_durability`,
  `sdpte_component_ddl`, and `sdpte_standard_node_io` all pass. The
  no-durability gate reviewed 84 files, 1005 external call sites, and 128
  durable-state files.
- The three aggregates that previously stopped at the synthetic DROP fixture,
  `sdpte_allocator_runtime`, `sdpte_concurrency_error`, and `sdpte_sql_view`,
  now also pass completely.
- `make build -j8` completed with exit 0. After restarting the rebuilt server,
  `renameTempfile.tc` reported `PASS: 1 FAIL: 0 FATAL: 0 ERROR: 0`; its output
  matches the checked-in `_A4_64.lst` byte-for-byte.
- The former `unittestSdpteDropTempFile.cpp:850-857` failure was reconciled by
  correcting only the synthetic publication fixture's retired-allocator model;
  the product DROP body was not changed.
