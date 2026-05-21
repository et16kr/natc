--###########################################################################
--# PROJ-1872 initialize compare test
--###########################################################################

--+SKIP BEGIN;
DROP INDEX D1X;
DROP TABLE D1;
--+SKIP END;


--##################################
--+SECTOR; PREPARATION
--##################################

CREATE TABLE D1 ( I1 BIGINT ) TABLESPACE SYS_TBS_DISK_DATA;

CREATE INDEX D1X ON D1 ( I1 );

CREATE OR REPLACE FUNCTION CHECK_INDEX_FUNC(
          DEPTH_IDX  IN INTEGER, 
          COLUMN_IDX IN INTEGER,
          ORDER_TYPE IN CHAR(8) ) 
RETURN CHAR( 15 )
AS
    BEGIN
        DECLARE
        CURSOR C1 IS SELECT DEPTH, NTH_SLOT,
                     LPAD( RTRIM(VALUE24B) , 24, 0 ) VALUEB
                     FROM D$DISK_INDEX_BTREE_KEY( D1X ) 
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

CREATE OR REPLACE FUNCTION CHECK_INDEX_FUNC_FOR_FLOAT(
          DEPTH_IDX  IN INTEGER, 
          COLUMN_IDX IN INTEGER,
          ORDER_TYPE IN CHAR(8) ) 
RETURN CHAR( 15 )
AS
    BEGIN
        DECLARE
        CURSOR C1 IS SELECT DEPTH, NTH_SLOT,
                     LPAD( RTRIM( ROUND(TO_NUMBER(VALUE24B))), 24, 0) VALUEB
                     FROM D$DISK_INDEX_BTREE_KEY( D1X ) 
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

CREATE OR REPLACE FUNCTION CHECK_INDEX_INTEGRITY_FUNC_FOR_FLOAT( 
           MAX_DEPTH  IN INTEGER, 
           COLUMN_CNT IN INTEGER,
           ORDER_TYPE IN CHAR(8) ) 
RETURN CHAR(15)
AS
RESULT CHAR(15);
BEGIN
    FOR I IN 0 .. MAX_DEPTH LOOP
        FOR J IN 0 .. (COLUMN_CNT-1) LOOP
            RESULT := CHECK_INDEX_FUNC_FOR_FLOAT(I, J, ORDER_TYPE);
            IF RESULT = 'DISORDERED' THEN
                RETURN 'DISORDERED';
                EXIT;
            END IF;
        END LOOP;
    END LOOP;
    RETURN 'ORDERED';
END;
/

CREATE OR REPLACE FUNCTION CHECK_INDEX_FUNC_FOR_STRING(
          DEPTH_IDX  IN INTEGER, 
          COLUMN_IDX IN INTEGER,
          ORDER_TYPE IN CHAR(8) ) 
RETURN CHAR( 15 )
AS
    BEGIN
        DECLARE
        CURSOR C1 IS SELECT DEPTH, NTH_SLOT,
                     RPAD( RTRIM(VALUE24B) , 24, 0 ) VALUEB
                     FROM D$DISK_INDEX_BTREE_KEY( D1X ) 
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

CREATE OR REPLACE FUNCTION CHECK_INDEX_INTEGRITY_FUNC_FOR_STRING( 
           MAX_DEPTH  IN INTEGER, 
           COLUMN_CNT IN INTEGER,
           ORDER_TYPE IN CHAR(8) ) 
RETURN CHAR(15)
AS
RESULT CHAR(15);
BEGIN
    FOR I IN 0 .. MAX_DEPTH LOOP
        FOR J IN 0 .. (COLUMN_CNT-1) LOOP
            RESULT := CHECK_INDEX_FUNC_FOR_STRING(I, J, ORDER_TYPE);
            IF RESULT = 'DISORDERED' THEN
                RETURN 'DISORDERED';
                EXIT;
            END IF;
        END LOOP;
    END LOOP;
    RETURN 'ORDERED';
END;
/

DROP INDEX D1X;
DROP TABLE D1;
