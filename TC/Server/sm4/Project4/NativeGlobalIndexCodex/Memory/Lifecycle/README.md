# Memory lifecycle prototypes

These scenarios are deliberately not linked from Memory.ts.

Planned cases:

1. clean restart rebuilds one composite tree from all participant rows
2. abnormal shutdown after committed and rolled-back DML
3. duplicate key found during startup rebuild blocks SERVICE
4. variable keys in different memory tablespaces rebuild correctly
5. startup allocation failure publishes no partial child ref set
6. QP startup abort tears down the rebuilt tree once
7. clean shutdown orders QP detach, ager join, and module drop

Executable sources require an approved restart helper, fault point names,
timeouts, and startup-state oracle.

