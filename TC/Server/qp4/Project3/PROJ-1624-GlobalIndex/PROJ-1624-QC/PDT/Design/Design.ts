TestSuiteDescription  = PDT Design 4 test
###############################################################################
INITIALIZE.sql                             # initialize tablespace
CREATE_TABLE/CREATE_TABLE.ts               # CREATE TABLE Test
ALTER_TABLE/ALTER_TABLE.ts                 # ALTER TABLE Test
CREATE_INDEX/CREATE_INDEX.ts               # CREATE INDEX Test
ALTER_INDEX/ALTER_INDEX.ts                 # ALTER INDEX Test
DROP_TABLESPACE/basic.sql                  # DROP TABLESPACE Test
SELECT/SELECT.ts                           # SELECT Test
INSERT/INSERT.ts                           # INSERT Test
DELETE/DELETE.ts                           # DELETE Test
UPDATE/UPDATE.ts                           # UPDATE Test
MOVE/MOVE.ts                               # MOVE Test
LOCK_TABLE/LOCK_TABLE.ts                   # LOCK TABLE Test
FINALIZE.sql                               # clean up tablespace
-------------------------------------------------------------------------------
