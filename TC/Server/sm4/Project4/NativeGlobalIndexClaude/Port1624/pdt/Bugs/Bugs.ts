TestSuiteDescription  = PDT Bugs test
###############################################################################
INITIALIZE.sql                        # CREATE TBS
BUG-9/BUG-9.sql                       #
BUG-14/BUG-14.sql                     # Create Local Unique Index
BUG-17/BUG-17.sql                     # Create Index
BUG-18/BUG-18.sql                     # Delete Hint
BUG-20/BUG-20.sql                     # D$DISK_BTREE_STRUCTURE
BUG-22/BUG-22.sql                     # PARTITION PRUNING
BUG-24/BUG-24.sql                     # LEGACY(DUPLICATE INDEX COLUMN)
BUG-27/BUG-27.sql                     # LEGACY(DROP USER AND SELECT)
BUG-37/BUG-37.sql                     # COMPOSITE CURSOR BUG
BUG-45/BUG-45.sql                     # PR-16131 (PR-17444) TDRTREE
BUG-49/BUG-49.sql                     # index direction
BUG-56/BUG-56.sql                     # index select diff
FINALIZE.sql                          # DROP TBS
-------------------------------------------------------------------------------
