--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/PDT/Design/LOCK_TABLE/S_NOWAIT.sql
--#
--# Body below is byte-identical to the original. The one line this port
--# adds is the premise: the original measures these statements on the
--# $GIT_ hidden-table implementation, this file measures the same
--# statements on the native global index (F07 -- see include/pinNative.sql).
--###########################################################################
--###########################################################################
--# NativeGlobalIndexPort1624 - the premise of every ported .sql case.
--#
--# A .sql case cannot CALL a DEF the way a .tc case calls PIN_DISK_NATIVE(),
--# so the same two statements are pulled in per case with ATC's own include
--# directive:
--#
--#     --+LOAD_SQL <relative path>/include/pinNative.sql;
--#
--# ATC inlines this file into the case transcript between BEGIN/END markers,
--# which is exactly what F07 asks for: the case states its own premise at the
--# head of its own transcript instead of inheriting whatever the instance
--# happens to be configured with.
--#
--#     DISK_GLOBAL_INDEX_ENABLE = 1  -> native  (this suite)
--#     DISK_GLOBAL_INDEX_ENABLE = 0  -> $GIT_   (the original suite)
--#
--# The readout below is not decoration. It is the tooth: if the property is
--# ever 0 when a case runs, this one line differs and the case is red before
--# it has measured anything, instead of quietly measuring the other
--# implementation (disk-natc.md 6 records nine assertions that drifted that
--# way).
--#
--# ASCII only, on purpose: 87 of the ported case bodies are EUC-KR and their
--# bytes must stay untouched, so nothing this port adds may introduce a
--# second encoding into a transcript.
--###########################################################################

ALTER SYSTEM SET DISK_GLOBAL_INDEX_ENABLE = 1;

SELECT CAST(VALUE1 AS VARCHAR(10)) DISK_GLOBAL_INDEX_ENABLE
FROM V$PROPERTY WHERE NAME = 'DISK_GLOBAL_INDEX_ENABLE';

--############################################################################
--# Lock (Partitioned)Table Execution TEST
--############################################################################

--###################################
--+SECTOR; PREPARATION
--###################################
--+SKIP BEGIN;
DROP TABLE RANGE_TAB;
DROP TABLE HASH_TAB;
--+SKIP END;

--########################################################
--+SECTOR; SHARE = LOCK(S)
--########################################################

--####################################
--# DROP TABLE
--####################################
--+LOAD_SQL Schema.sql;

--+PWAIT;

    --+PROCESS P1;
        AUTOCOMMIT OFF;
	
	LOCK TABLE RANGE_TAB IN SHARE MODE NOWAIT;

--+PWAIT;

    --+PROCESS P2;
        DROP TABLE RANGE_TAB;

--+PWAIT;

    --+PROCESS P1;
	COMMIT;

--+PWAIT;

--####################################
--# CREATE INDEX
--####################################
--+LOAD_SQL Schema.sql;

--+PWAIT;

    --+PROCESS P1;
        AUTOCOMMIT OFF;

        LOCK TABLE RANGE_TAB IN SHARE MODE NOWAIT;

--+PWAIT;

    --+PROCESS P2;
        CREATE INDEX NEW_IDX ON RANGE_TAB(I1) LOCAL
        (
            PARTITION P1_IDX1 ON P1,
            PARTITION P2_IDX1 ON P2,
            PARTITION P3_IDX1 ON P3,
            PARTITION P4_IDX1 ON P4
        );

--+PWAIT;

    --+PROCESS P1;
        COMMIT;

--+PWAIT;

--####################################
--# DROP INDEX
--####################################
--+LOAD_SQL Schema.sql;

--+PWAIT;

    --+PROCESS P1;
        AUTOCOMMIT OFF;

        LOCK TABLE RANGE_TAB IN SHARE MODE NOWAIT;

--+PWAIT;

    --+PROCESS P2;
        DROP INDEX IDX1;

--+PWAIT;

    --+PROCESS P1;
        COMMIT;

--+PWAIT;


--####################################
--# ADD COLUMN
--####################################
--+LOAD_SQL Schema.sql;

--+PWAIT;

    --+PROCESS P1;
        AUTOCOMMIT OFF;

        LOCK TABLE RANGE_TAB IN SHARE MODE NOWAIT;

--+PWAIT;

    --+PROCESS P2;
        ALTER TABLE RANGE_TAB ADD COLUMN ( I3 INTEGER );

--+PWAIT;

    --+PROCESS P1;
        COMMIT;

--+PWAIT;

--####################################
--# DROP COLUMN
--####################################
--+LOAD_SQL Schema.sql;

--+PWAIT;

    --+PROCESS P1;
        AUTOCOMMIT OFF;

        LOCK TABLE RANGE_TAB IN SHARE MODE NOWAIT;

--+PWAIT;

    --+PROCESS P2;
        ALTER TABLE RANGE_TAB DROP COLUMN I2;

--+PWAIT;

    --+PROCESS P1;
        COMMIT;

--+PWAIT;

--####################################
--# TRUNCATE TABLE
--####################################
--+LOAD_SQL Schema.sql;

--+PWAIT;

    --+PROCESS P1;
        AUTOCOMMIT OFF;

        LOCK TABLE RANGE_TAB IN SHARE MODE NOWAIT;

--+PWAIT;

    --+PROCESS P2;
        TRUNCATE TABLE RANGE_TAB;

--+PWAIT;

    --+PROCESS P1;
        COMMIT;

--+PWAIT;

--####################################
--# RENAME TABLE
--####################################
--+LOAD_SQL Schema.sql;

--+PWAIT;

    --+PROCESS P1;
        AUTOCOMMIT OFF;

        LOCK TABLE RANGE_TAB IN SHARE MODE NOWAIT;

--+PWAIT;

    --+PROCESS P2;
        ALTER TABLE RANGE_TAB RENAME TO NEW_RANGE_TAB;

--+PWAIT;

    --+PROCESS P1;
        COMMIT;

--+PWAIT;

--+SKIP BEGIN;
DROP TABLE NEW_RANGE_TAB;
--+SKIP END;


--####################################
--# ADD PARTITION
--####################################
--+LOAD_SQL Schema.sql;

--+PWAIT;

    --+PROCESS P1;
        AUTOCOMMIT OFF;

        LOCK TABLE HASH_TAB IN SHARE MODE NOWAIT;

--+PWAIT;

    --+PROCESS P2;
        ALTER TABLE HASH_TAB ADD PARTITION P5;

--+PWAIT;

    --+PROCESS P1;
        COMMIT;

--+PWAIT;

--####################################
--# COALESCE PARTITION
--####################################
--+LOAD_SQL Schema.sql;

--+PWAIT;

    --+PROCESS P1;
        AUTOCOMMIT OFF;

        LOCK TABLE HASH_TAB IN SHARE MODE NOWAIT;

--+PWAIT;

    --+PROCESS P2;
        ALTER TABLE HASH_TAB COALESCE PARTITION;

--+PWAIT;

    --+PROCESS P1;
        COMMIT;

--+PWAIT;

--####################################
--# DROP PARTITION
--####################################
--+LOAD_SQL Schema.sql;

--+PWAIT;

    --+PROCESS P1;
        AUTOCOMMIT OFF;

        LOCK TABLE RANGE_TAB IN SHARE MODE NOWAIT;

--+PWAIT;

    --+PROCESS P2;
        ALTER TABLE RANGE_TAB DROP PARTITION P2;

--+PWAIT;

    --+PROCESS P1;
        COMMIT;

--+PWAIT;

--####################################
--# MERGE PARTITION
--####################################
--+LOAD_SQL Schema.sql;

--+PWAIT;

    --+PROCESS P1;
        AUTOCOMMIT OFF;

        LOCK TABLE RANGE_TAB IN SHARE MODE NOWAIT;

--+PWAIT;

    --+PROCESS P2;
        ALTER TABLE RANGE_TAB MERGE PARTITIONS P2, P3
        INTO PARTITION P2_3;

--+PWAIT;

    --+PROCESS P1;
        COMMIT;

--+PWAIT;

--####################################
--# RENAME PARTITION
--####################################
--+LOAD_SQL Schema.sql;

--+PWAIT;

    --+PROCESS P1;
        AUTOCOMMIT OFF;

        LOCK TABLE RANGE_TAB IN SHARE MODE NOWAIT;

--+PWAIT;

    --+PROCESS P2;
        ALTER TABLE RANGE_TAB RENAME PARTITION P2 TO P2_NEW;

--+PWAIT;

    --+PROCESS P1;
        COMMIT;

--+PWAIT;

--####################################
--# SPLIT PARTITION
--####################################
--+LOAD_SQL Schema.sql;

--+PWAIT;

    --+PROCESS P1;
        AUTOCOMMIT OFF;

        LOCK TABLE RANGE_TAB IN SHARE MODE NOWAIT;

--+PWAIT;

    --+PROCESS P2;
        ALTER TABLE RANGE_TAB SPLIT PARTITION P2
        AT (15)
        INTO ( PARTITION P2_1,
               PARTITION P2_2 );

--+PWAIT;

    --+PROCESS P1;
        COMMIT;

--+PWAIT;

--####################################
--# TRUNCATE PARTITION
--####################################
--+LOAD_SQL Schema.sql;

--+PWAIT;

    --+PROCESS P1;
        AUTOCOMMIT OFF;

        LOCK TABLE RANGE_TAB IN SHARE MODE NOWAIT;

--+PWAIT;

    --+PROCESS P2;
        ALTER TABLE RANGE_TAB TRUNCATE PARTITION P3;

--+PWAIT;

    --+PROCESS P1;
        COMMIT;

--+PWAIT;


--####################################
--# REBUILD PARTITION
--####################################
--+LOAD_SQL Schema.sql;

--+PWAIT;

    --+PROCESS P1;
        AUTOCOMMIT OFF;

        LOCK TABLE RANGE_TAB IN SHARE MODE NOWAIT;

--+PWAIT;

    --+PROCESS P2;
        ALTER INDEX IDX1 REBUILD PARTITION P2_IDX1;

--+PWAIT;

    --+PROCESS P1;
        COMMIT;

--+PWAIT;


--####################################
--# SELECT
--####################################
--+LOAD_SQL Schema.sql;

--+PWAIT;

    --+PROCESS P1;
        AUTOCOMMIT OFF;

        LOCK TABLE RANGE_TAB IN SHARE MODE NOWAIT;

--+PWAIT;

    --+PROCESS P2;
        SELECT * FROM RANGE_TAB;

--+PWAIT;

    --+PROCESS P1;
        COMMIT;

--+PWAIT;


--####################################
--# SELECT FOR UPDATE
--####################################
--+LOAD_SQL Schema.sql;

--+PWAIT;

    --+PROCESS P1;
        AUTOCOMMIT OFF;

        LOCK TABLE RANGE_TAB IN SHARE MODE NOWAIT;

        --+SYSTEM sleep 2;

        COMMIT;


    --+PROCESS P2;
        --+SYSTEM sleep 1;
        SELECT * FROM RANGE_TAB FOR UPDATE;

--+PWAIT;

    --+PROCESS P1;
        COMMIT;

--+PWAIT;


--####################################
--# INSERT
--####################################
--+LOAD_SQL Schema.sql;

--+PWAIT;

    --+PROCESS P1;
        AUTOCOMMIT OFF;

        LOCK TABLE RANGE_TAB IN SHARE MODE NOWAIT;

        --+SYSTEM sleep 2;

        COMMIT;


    --+PROCESS P2;
        --+SYSTEM sleep 1;
        INSERT INTO RANGE_TAB VALUES ( 123, 'ABC' );

--+PWAIT;

    --+PROCESS P1;
        COMMIT;

--+PWAIT;


--####################################
--# UPDATE
--####################################
--+LOAD_SQL Schema.sql;

--+PWAIT;

    --+PROCESS P1;
        AUTOCOMMIT OFF;

        LOCK TABLE RANGE_TAB IN SHARE MODE NOWAIT;

        --+SYSTEM sleep 2;

        COMMIT;


    --+PROCESS P2;
        --+SYSTEM sleep 1;
        UPDATE RANGE_TAB SET I1 = 777;

--+PWAIT;

    --+PROCESS P1;
        COMMIT;

--+PWAIT;


--####################################
--# DELETE
--####################################
--+LOAD_SQL Schema.sql;

--+PWAIT;

    --+PROCESS P1;
        AUTOCOMMIT OFF;

        LOCK TABLE RANGE_TAB IN SHARE MODE NOWAIT;

        --+SYSTEM sleep 2;

        COMMIT;


    --+PROCESS P2;
        --+SYSTEM sleep 1;
        DELETE FROM RANGE_TAB;

--+PWAIT;

    --+PROCESS P1;
        COMMIT;

--+PWAIT;


--#################################
--+SECTOR; FINALIZATION
--#################################

--+SKIP BEGIN;
DROP TABLE RANGE_TAB;
DROP TABLE HASH_TAB;
--+SKIP END;

