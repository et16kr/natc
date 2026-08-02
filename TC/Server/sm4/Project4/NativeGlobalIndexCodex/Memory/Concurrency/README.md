# Memory concurrency contract

The NGI-CON-001 through NGI-CON-004 cases remain EnvironmentBlocked. The
repository has THREAD examples only with declared server/client topology and
does not provide a verified same-server two-session event contract for this
suite. Do not link `Concurrency.ts` until connection routing and deterministic
POST/WAIT or lock-based synchronization are defined. Timing-only `SLEEP`
synchronization is not acceptable.
