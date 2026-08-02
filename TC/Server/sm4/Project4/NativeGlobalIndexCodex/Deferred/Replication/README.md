# Replication lane

Planned coverage:

1. Replicate base-row INSERT/UPDATE/DELETE and row movement.
2. Synchronize native-global DDL only across compatible fix versions.
3. Reject asynchronous or incompatible native-global DDL without partial state.
4. Reconnect and resync without orphan metadata or duplicate keys.

Executable cases require a deterministic two-server topology, replication
helpers, and the final fix-version contract. State: `EnvironmentBlocked`.
