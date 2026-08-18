# TEMP tablespace oracle review — initial 77-case snapshot (2026-08-18)

This document is the historical static review taken before the suite grew to
82 cases and before the later focused fixes. It must not be used as the current
oracle inventory; see [README.md](README.md) and
[INVESTIGATION_STATUS_20260818.md](INVESTIGATION_STATUS_20260818.md) for the
current 82-case state. No NATC/ATC case or suite was run during this original
review, and no debugging or corrective investigation was performed in that
review step.

The suite has 77 `.tc` cases. It now has 64 matching `_A4_64.lst` files: the 57
existing lists were preserved byte-for-byte, and the seven outputs below were
reviewed and promoted. Thirteen cases remain without a list because their
output is incomplete, contradictory, or not a stable oracle.

## Promoted outputs

Each output had the expected case-level `PASS_*` assertions set to `1`, with no
unexpected case failure. The visible error in `reject_tablespace_autoextend`
is the intentional rejection being asserted by that negative case.

| Case | Reviewed output | Result |
|---|---|---|
| `control/createDatafile.tc` | `createDatafile_A4_64.out` | Durable CREATE DATAFILE control result passed. |
| `ddl/alter/alter_size_autoextend_logging.tc` | `alterSizeAutoextend_A4_64.out` | SIZE/AUTOEXTEND and logging transition assertions passed. |
| `ddl/create/create_logging_transition.tc` | `create_08_A4_64.out` | UNCOMPRESSED/COMPRESSED transition assertions passed. |
| `ddl/tempfile/add_drop_single.tc` | `adddrop_04_A4_64.out` | Single TEMPFILE add/drop lifecycle passed. |
| `ddl/tempfile/add_drop_multi.tc` | `adddrop_05_A4_64.out` | Multi-TEMPFILE add/drop lifecycle passed. |
| `negative/reject_tablespace_autoextend.tc` | `reject_05_A4_64.out` | Unsupported TABLESPACE AUTOEXTEND form was rejected as expected. |
| `safety/atomicity/createMultiFileFailure.tc` | `createMultiFileFailure_A4_64.out` | No-partial-definition and collision-preservation assertions passed. |

The promoted files are the matching `.lst` files beside those `.tc` files.

## Outputs deliberately not promoted

These 13 outputs remain `.out` only. They are evidence for later diagnosis, not
expected-output files.

| Case | Output evidence | Why it is unsuitable now |
|---|---|---|
| `control/createDatafileCrash.tc` | `createDatafileCrash_A4_64.out` | `PASS_OLD_ANCHOR_AUTHORITATIVE=0` and `PASS_ACTIVE_ORPHAN_REJECTED=0`. |
| `control/discardLifecycle.tc` | `discardLifecycle_A4_64.out` | The discard projections pass, but `PASS_DROP_ONLY_LIFECYCLE=0`. |
| `control/renameTempfile.tc` | `renameTempfile_A4_64.out` | `PASS_CONTROL_RENAME=0` and `PASS_RENAME_ANCHOR_DURABLE=0`. |
| `negative/reject_backup.tc` | `backupGuard_A4_64.out` | `PASS_BACKUP_REJECTIONS_UNCHANGED=0`; output includes `ERR-311B1`. |
| `recovery/crash/abruptRuntimeRestart.tc` | `abruptRuntimeRestart_A4_64.out` | Pre-abort runtime and abort reconciliation assertions are `0`. |
| `recovery/reconcile/foreignHeaderReject.tc` | `foreignHeaderReject_A4_64.out` | Startup rejection passes, but `PASS_DEFINITIONS_UNCHANGED=0`. |
| `recovery/reconcile/runtimeAnchorBaseline.tc` | `runtimeAnchorBaseline_A4_64.out` | Runtime growth passes, but `PASS_RECREATE_FROM_ANCHOR_D=0`. |
| `runtime/concurrency/parallelAutoextend.tc` | `parallelAutoextend_A4_64.out` | No complete case-level `PASS_*` result is visible; communication failed. |
| `runtime/spill/multiTempfileSpill.tc` | `multiTempfileSpill_A4_64.out` | Spill passes, but `PASS_BOTH_FILES_USED=0`. |
| `runtime/spill/runtimeSortHashMatrix.tc` | `runtimeSortHashMatrix_A4_64.out` | Sort/hash spill assertions pass, but `PASS_RUNTIME_IO_PROJECTION=0`. |
| `runtime/spill/variableExtentSpill.tc` | `variableExtentSpill_A4_64.out` | Output is incomplete after `PASS_EXTENT_38_SPILL`; client connection failed. |
| `safety/path/dropPathSubstitution.tc` | `dropPathSubstitution_A4_64.out` | `PASS_DROP_REFUSED=0`, despite the data source remaining unchanged. |
| `views/runtimeProjection.tc` | `runtimeProjection_A4_64.out` | Initial and runtime file projections are `0`; only view spill passed. |

`process.out` files under the case folders are helper-process logs and are not
case outputs. They were not converted to `.lst`.

No `.lst` was invented for any unsuitable or missing result. A later reviewed
run is required before those 13 cases can be considered complete.
