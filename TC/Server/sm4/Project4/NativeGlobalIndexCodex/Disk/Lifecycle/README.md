# Disk lifecycle prototypes

These scenarios are deliberately not linked from Disk.ts.

Planned cases:

1. clean shutdown and restart reuses the committed GLOBAL_V1 segment
2. INSERT/UPDATE/DELETE crash recovery preserves ordered scan results
3. CREATE crash before and after catalog publication
4. REBUILD shadow generation commit and abort
5. DROP header detach and segment GC crash matrix
6. startup rejects unknown format or create-token mismatch
7. clean shutdown drops runtime cache once without freeing the segment

Executable sources require an approved restart helper, fault point names,
timeouts, and recovery verification interface.

