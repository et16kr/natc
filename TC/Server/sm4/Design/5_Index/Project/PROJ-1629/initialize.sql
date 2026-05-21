--###########################################################################
--# PROJ-1629
--###########################################################################

--+SKIP BEGIN;
DROP INDEX M1X;
DROP TABLE M1;
DROP INDEX M2X;
DROP TABLE M2;
--+SKIP END;


--##################################
--+SECTOR; PREPARATION
--##################################

CREATE TABLE M1 ( I1 INTEGER );
CREATE INDEX M1X ON M1 ( I1 ) ;
CREATE TABLE M2 ( I1 INTEGER );
CREATE INDEX M2X ON M2 ( I1 ) ;

CREATE OR REPLACE FUNCTION CHECK_INDEX_FUNC(
          DEPTH_IDX  IN INTEGER, 
          COLUMN_IDX IN INTEGER,
          ORDER_TYPE IN CHAR(8) ) 
RETURN CHAR( 15 )
AS
    BEGIN
        DECLARE
        CURSOR C1 IS SELECT DEPTH, NTH_SLOT, LPAD( RTRIM(VALUE24B), 24, '0' ) VALUEB, ROW_PTR
                     FROM D$MEM_INDEX_BTREE_KEY( M1X ) 
                     WHERE DEPTH = DEPTH_IDX AND NTH_COLUMN = COLUMN_IDX;
        IDX_REC C1%ROWTYPE;
        PRVVALUE CHAR(24);
        CURVALUE CHAR(24);
        PRVPOINTER CHAR(8);
        CURPOINTER CHAR(8);
        BEGIN
            PRVVALUE := ''; 
            CURVALUE := '';
            PRVPOINTER := '';
            CURPOINTER := '';
            OPEN C1;
                LOOP
                    FETCH C1 INTO IDX_REC;
                    EXIT WHEN C1%NOTFOUND;
                    PRVVALUE := CURVALUE;
                    CURVALUE := IDX_REC.VALUEB;
                    PRVPOINTER := CURPOINTER;
                    CURPOINTER := IDX_REC.ROW_PTR;
                    
                    IF ORDER_TYPE = 'ASC' THEN
                        IF PRVVALUE > CURVALUE THEN
                            RETURN 'DISORDERED';
                            EXIT;
                        ELSE
                            IF PRVVALUE = CURVALUE THEN
                                IF PRVPOINTER > CURPOINTER THEN
                                    RETURN 'DISORDERED';
                                    EXIT;
                                END IF;
                            END IF;
                        END IF;
                    ELSE
                        IF ORDER_TYPE = 'DESC' THEN
                            IF PRVVALUE < CURVALUE THEN
                                RETURN 'DISORDERED';
                                EXIT;
                            ELSE
                                IF PRVVALUE = CURVALUE THEN
                                    IF PRVPOINTER > CURPOINTER THEN
                                        RETURN 'DISORDERED';
                                        EXIT;
                                    END IF;
                                END IF;
                            END IF;
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
        CURSOR C1 IS SELECT DEPTH, NTH_SLOT, LPAD( RTRIM(VALUE24B), 24, '0' ) VALUEB, ROW_PTR
                     FROM D$MEM_INDEX_BTREE_KEY( M2X ) 
                     WHERE DEPTH = DEPTH_IDX AND NTH_COLUMN = COLUMN_IDX;
        IDX_REC C1%ROWTYPE;
        PRVVALUE CHAR(24);
        CURVALUE CHAR(24);
        PRVPOINTER CHAR(8);
        CURPOINTER CHAR(8);
        BEGIN
            PRVVALUE := ''; 
            CURVALUE := '';
            PRVPOINTER := '';
            CURPOINTER := '';
            OPEN C1;
                LOOP
                    FETCH C1 INTO IDX_REC;
                    EXIT WHEN C1%NOTFOUND;
                    PRVVALUE := CURVALUE;
                    CURVALUE := IDX_REC.VALUEB;
                    PRVPOINTER := CURPOINTER;
                    CURPOINTER := IDX_REC.ROW_PTR;
                    
                    IF ORDER_TYPE = 'ASC' THEN
                        IF PRVVALUE > CURVALUE THEN
                            RETURN 'DISORDERED';
                            EXIT;
                        ELSE
                            IF PRVVALUE = CURVALUE THEN
                                IF PRVPOINTER > CURPOINTER THEN
                                    RETURN 'DISORDERED';
                                    EXIT;
                                END IF;
                            END IF;
                        END IF;
                    ELSE
                        IF ORDER_TYPE = 'DESC' THEN
                            IF PRVVALUE < CURVALUE THEN
                                RETURN 'DISORDERED';
                                EXIT;
                            ELSE
                                IF PRVVALUE = CURVALUE THEN
                                    IF PRVPOINTER > CURPOINTER THEN
                                        RETURN 'DISORDERED';
                                        EXIT;
                                    END IF;
                                END IF;
                            END IF;
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

DROP TABLE M1;
DROP TABLE M2;
