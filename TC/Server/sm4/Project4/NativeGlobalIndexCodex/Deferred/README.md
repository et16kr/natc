# Deferred native global index lanes

These lanes are required for V1 release coverage, but they are intentionally
not linked from `NativeGlobalIndexCodex.ts`. Each lane needs an execution
contract that is unavailable to a portable single-session SQL test.

| Lane | Required contract | Current state |
| --- | --- | --- |
| AdminTool | isolated admin account, file policy, tool versions, restore fixture | EnvironmentBlocked |
| Replication | two-server topology and fix-version compatibility contract | EnvironmentBlocked |
| Performance | calibrated hardware, scale, timeout, and comparison baseline | EnvironmentBlocked |

Disk and Memory restart/crash work remains in each media's `Lifecycle/`
directory. Fault-injection cases must use approved FIT UIDs and belong in the
FIT lane rather than this portable SQL root.
