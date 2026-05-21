--##########################################################################
--# ACTIVE-STANDBY REPLICATION START
--##########################################################################

--##########################################################################
--# BEFORE TEST
--##########################################################################

--########################################################
--+SECTOR; PREPARATION
--########################################################

--+DECLARE SERVER REPL_SERVER1 DB1;
--+DECLARE SERVER REPL_SERVER2 DB2;

--+DECLARE CLIENT DEFAULT P1 (SERVER=DB1);
--+DECLARE CLIENT DEFAULT P3 (SERVER=DB2);

    --+PROCESS P1;

    --####################################
    --# ON ACTIVE SYSTEM (CLIENT 1)
    --####################################
    --+SKIP BEGIN;
    DROP TABLE TABLEB;
    --+SKIP END;

    CREATE TABLE TABLEB ( I1 INTEGER PRIMARY KEY, I2 INTEGER );


        --+PROCESS P3;

        --###################################
        --# ON STANDBY SYSTEM
        --###################################
        --+SYSTEM @DB2 server kill;
        --+SET_ENV @DB2 ALTIBASE_REPLICATION_LOCK_TIMEOUT=3;
        --+SYSTEM @DB2 server start;

--+PWAIT;

--########################################################
--+SECTOR; BEFORE TEST
--########################################################

    --+PROCESS P1;

    --####################################
    --# ON ACTIVE SYSTEM (CLIENT 1)
    --####################################

    CREATE OR REPLACE PROCEDURE PROC1
    AS
    i INTEGER;
    BEGIN
    i := 1;
        WHILE i <= 5000000 LOOP
            INSERT INTO TABLEB VALUES (i, i);
            i := i + 1;
        END LOOP;
    END;
    /
    EXEC PROC1;

--+PWAIT;
