--###########################################################################
--# TASK-2297
--###########################################################################

--+SKIP BEGIN;
--+SYSTEM server kill;
--+SET_ENV ALTIBASE_SYS_DATA_FILE_MAX_SIZE  = 23M;
--+SET_ENV ALTIBASE_SYS_DATA_FILE_INIT_SIZE = 1M;
--+SYSTEM clean;
--+SYSTEM server start;
--+SKIP END;

--##################################
--+SECTOR; PREPARATION
--##################################

CREATE TABLE T1 ( I1 INTEGER ) TABLESPACE SYS_TBS_DISK_DATA;
CREATE INDEX T1X ON T1 ( I1 ) PARALLEL 1;
CREATE TABLE T2 ( I1 INTEGER ) TABLESPACE SYS_TBS_DISK_DATA;
CREATE INDEX T2X ON T2 ( I1 ) PARALLEL 1;

CREATE OR REPLACE FUNCTION CHECK_INDEX_FUNC(
          DEPTH_IDX  IN INTEGER, 
          COLUMN_IDX IN INTEGER,
          ORDER_TYPE IN CHAR(8) ) 
RETURN CHAR( 15 )
AS
    BEGIN
        DECLARE
        CURSOR C1 IS SELECT DEPTH, NTH_SLOT, LPAD( RTRIM(VALUE24B), 24, '0' ) VALUEB
                     FROM D$DISK_INDEX_BTREE_KEY( T1X ) 
                     WHERE DEPTH = DEPTH_IDX AND NTH_COLUMN = COLUMN_IDX;
        IDX_REC C1%ROWTYPE;
        PRVVALUE CHAR(24);
        CURVALUE CHAR(24);
        BEGIN
            PRVVALUE := ''; 
            CURVALUE := ''; 
            OPEN C1;
                LOOP
                    FETCH C1 INTO IDX_REC;
                    EXIT WHEN C1%NOTFOUND;
                    PRVVALUE := CURVALUE;
                    CURVALUE := IDX_REC.VALUEB;
                    
                    IF ORDER_TYPE = 'ASC' THEN
                        IF PRVVALUE > CURVALUE THEN
                            RETURN 'DISORDERED';
                            EXIT;
                        END IF;
                    ELSE
                    IF PRVVALUE < CURVALUE THEN
                            RETURN 'DISORDERED';
                            EXIT;
                        END IF;
                    END IF;
                END LOOP;
            CLOSE C1;
        END;
        RETURN 'ORDERED';
    END;
/

CREATE OR REPLACE FUNCTION CHECK_INDEX_INTEGRITY_FUNC( 
           MAX_DEPTH  IN INTEGER, 
           COLUMN_CNT IN INTEGER,
           ORDER_TYPE IN CHAR(8) ) 
RETURN CHAR(15)
AS
RESULT CHAR(15);
BEGIN
    FOR I IN 0 .. MAX_DEPTH LOOP
        FOR J IN 0 .. (COLUMN_CNT-1) LOOP
            RESULT := CHECK_INDEX_FUNC(I, J, ORDER_TYPE);
            IF RESULT = 'DISORDERED' THEN
                RETURN 'DISORDERED';
                EXIT;
            END IF;
        END LOOP;
    END LOOP;
    RETURN 'ORDERED';
END;
/

CREATE OR REPLACE FUNCTION CHECK_INDEX_FUNC2(
          DEPTH_IDX  IN INTEGER, 
          COLUMN_IDX IN INTEGER,
          ORDER_TYPE IN CHAR(8) ) 
RETURN CHAR( 15 )
AS
    BEGIN
        DECLARE
        CURSOR C1 IS SELECT DEPTH, NTH_SLOT, LPAD( RTRIM(VALUE24B), 24, '0' ) VALUEB
                     FROM D$DISK_INDEX_BTREE_KEY( T2X ) 
                     WHERE DEPTH = DEPTH_IDX AND NTH_COLUMN = COLUMN_IDX;
        IDX_REC C1%ROWTYPE;
        PRVVALUE CHAR(24);
        CURVALUE CHAR(24);
        BEGIN
            PRVVALUE := ''; 
            CURVALUE := ''; 
            OPEN C1;
                LOOP
                    FETCH C1 INTO IDX_REC;
                    EXIT WHEN C1%NOTFOUND;
                    PRVVALUE := CURVALUE;
                    CURVALUE := IDX_REC.VALUEB;
                    
                    IF ORDER_TYPE = 'ASC' THEN
                        IF PRVVALUE > CURVALUE THEN
                            RETURN 'DISORDERED';
                            EXIT;
                        END IF;
                    ELSE
                    IF PRVVALUE < CURVALUE THEN
                            RETURN 'DISORDERED';
                            EXIT;
                        END IF;
                    END IF;
                END LOOP;
            CLOSE C1;
        END;
        RETURN 'ORDERED';
    END;
/

CREATE OR REPLACE FUNCTION CHECK_INDEX_INTEGRITY_FUNC2( 
           MAX_DEPTH  IN INTEGER, 
           COLUMN_CNT IN INTEGER,
           ORDER_TYPE IN CHAR(8) ) 
RETURN CHAR(15)
AS
RESULT CHAR(15);
BEGIN
    FOR I IN 0 .. MAX_DEPTH LOOP
        FOR J IN 0 .. (COLUMN_CNT-1) LOOP
            RESULT := CHECK_INDEX_FUNC2(I, J, ORDER_TYPE);
            IF RESULT = 'DISORDERED' THEN
                RETURN 'DISORDERED';
                EXIT;
            END IF;
        END LOOP;
    END LOOP;
    RETURN 'ORDERED';
END;
/

CREATE OR REPLACE PROCEDURE WAIT_MEM_LOGICAL_AGER_PROC( )
AS
    BEGIN
        DECLARE
        CURSOR C1 IS SELECT AGING_REQUEST_OID_CNT, AGING_PROCESSED_OID_CNT
                     FROM V$MEMGC 
                     WHERE GC_NAME = 'MEM_LOGICAL_AGER';
        IDX_REC C1%ROWTYPE;
        BEGIN
            LOOP
                OPEN C1;
                    FETCH C1 INTO IDX_REC;
                    EXIT WHEN C1%NOTFOUND;
                    IF IDX_REC.AGING_REQUEST_OID_CNT = IDX_REC.AGING_PROCESSED_OID_CNT THEN
                        EXIT;
                    END IF;
                CLOSE C1;
            END LOOP;
        END;
    END;
/

CREATE OR REPLACE PROCEDURE WAIT_MEM_PHYSICAL_AGER_PROC( )
AS
    BEGIN
        DECLARE
        CURSOR C1 IS SELECT AGING_REQUEST_OID_CNT, AGING_PROCESSED_OID_CNT
                     FROM V$MEMGC 
                     WHERE GC_NAME = 'MEM_DELTHR';
        IDX_REC C1%ROWTYPE;
        BEGIN
            LOOP
                OPEN C1;
                    FETCH C1 INTO IDX_REC;
                    EXIT WHEN C1%NOTFOUND;
                    IF IDX_REC.AGING_REQUEST_OID_CNT = IDX_REC.AGING_PROCESSED_OID_CNT THEN
                        EXIT;
                    END IF;
                CLOSE C1;
            END LOOP;
        END;
    END;
/

CREATE OR REPLACE PROCEDURE WAIT_MEMGC_PROC( )
AS
    BEGIN
        WAIT_MEM_LOGICAL_AGER_PROC;
        WAIT_MEM_PHYSICAL_AGER_PROC;
    END;
/

DROP TABLE T1;
DROP TABLE T2;
