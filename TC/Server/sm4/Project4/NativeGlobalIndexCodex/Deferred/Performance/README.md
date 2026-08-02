# Performance and capacity lane

Planned coverage:

1. Compare local, legacy, and native global index build and DML cost.
2. Measure point/range scan latency with pruning at representative scale.
3. Exercise the 64-index parent limit under sustained DML.
4. Run long-duration row movement, rebuild, and delete/reinsert workloads.

Executable cases require calibrated hardware, fixed scale and timeout values,
and an approved regression baseline. State: `EnvironmentBlocked`.
