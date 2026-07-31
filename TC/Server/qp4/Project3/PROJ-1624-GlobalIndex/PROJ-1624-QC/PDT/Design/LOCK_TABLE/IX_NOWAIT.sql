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

--+APPEND_LST Schema.sql;

--########################################################
--+SECTOR; ROW EXCLUSIVE = LOCK(IX)
--########################################################

--####################################
--# DROP TABLE
--####################################
--+LOAD_SQL Schema.sql;

--+PWAIT;

    --+PROCESS P1;
        AUTOCOMMIT OFF;
	
	LOCK TABLE RANGE_TAB IN ROW EXCLUSIVE MODE NOWAIT;

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

        LOCK TABLE RANGE_TAB IN ROW EXCLUSIVE MODE NOWAIT;

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

        LOCK TABLE RANGE_TAB IN ROW EXCLUSIVE MODE NOWAIT;

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

        LOCK TABLE RANGE_TAB IN ROW EXCLUSIVE MODE NOWAIT;

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

        LOCK TABLE RANGE_TAB IN ROW EXCLUSIVE MODE NOWAIT;

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

        LOCK TABLE RANGE_TAB IN ROW EXCLUSIVE MODE NOWAIT;

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

        LOCK TABLE RANGE_TAB IN ROW EXCLUSIVE MODE NOWAIT;

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

        LOCK TABLE HASH_TAB IN ROW EXCLUSIVE MODE NOWAIT;

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

        LOCK TABLE HASH_TAB IN ROW EXCLUSIVE MODE NOWAIT;

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

        LOCK TABLE RANGE_TAB IN ROW EXCLUSIVE MODE NOWAIT;

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

        LOCK TABLE RANGE_TAB IN ROW EXCLUSIVE MODE NOWAIT;

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

        LOCK TABLE RANGE_TAB IN ROW EXCLUSIVE MODE NOWAIT;

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

        LOCK TABLE RANGE_TAB IN ROW EXCLUSIVE MODE NOWAIT;

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

        LOCK TABLE RANGE_TAB IN ROW EXCLUSIVE MODE NOWAIT;

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

        LOCK TABLE RANGE_TAB IN ROW EXCLUSIVE MODE NOWAIT;

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

        LOCK TABLE RANGE_TAB IN ROW EXCLUSIVE MODE NOWAIT;

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

        LOCK TABLE RANGE_TAB IN ROW EXCLUSIVE MODE NOWAIT;

--+PWAIT;

    --+PROCESS P2;
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

        LOCK TABLE RANGE_TAB IN ROW EXCLUSIVE MODE NOWAIT;

--+PWAIT;

    --+PROCESS P2;
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

        LOCK TABLE RANGE_TAB IN ROW EXCLUSIVE MODE NOWAIT;

--+PWAIT;

    --+PROCESS P2;
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

        LOCK TABLE RANGE_TAB IN ROW EXCLUSIVE MODE NOWAIT;

--+PWAIT;

    --+PROCESS P2;
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

