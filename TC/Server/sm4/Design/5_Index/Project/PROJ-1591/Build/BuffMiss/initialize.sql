--###########################################################################
--# PROJ-1591
--###########################################################################

--+SKIP BEGIN;
DROP INDEX T1X;
DROP TABLE T1;
DROP INDEX T2X;
DROP TABLE T2;
--+SYSTEM server kill;
--+SET_ENV ALTIBASE_BUFFER_AREA_SIZE = 1M;
--+SET_ENV ALTIBASE_DISK_INDEX_BUILD_MERGE_PAGE_COUNT = 16;
--+SET_ENV ALTIBASE_QUERY_TIMEOUT = 0;
--+SET_ENV ALTIBASE_FETCH_TIMEOUT = 0;
--+SYSTEM clean ;
--+SYSTEM server start;
--+SKIP END;

--##################################
--+SECTOR; PREPARATION
--##################################

ALTER SYSTEM SET __DISK_INDEX_RTREE_MAX_KEY_COUNT = 3;
ALTER SYSTEM SET FETCH_TIMEOUT = 1000;

CREATE TABLE T1 ( I1 GEOMETRY ) TABLESPACE SYS_TBS_DISK_DATA;
CREATE INDEX T1X ON T1 ( I1 ) NOLOGGING;
CREATE TABLE T2 ( I1 INTEGER ) TABLESPACE SYS_TBS_DISK_DATA;
CREATE INDEX T2X ON T2 ( I1 ) NOLOGGING;

CREATE OR REPLACE FUNCTION CHECK_INDEX_MBR_FUNC1(
          NODE_PAGEID  IN INTEGER, 
          NODE_MIN_X   IN DOUBLE,
          NODE_MIN_Y   IN DOUBLE,
          NODE_MAX_X   IN DOUBLE,
          NODE_MAX_Y   IN DOUBLE ) 
RETURN CHAR( 15 )
AS
    BEGIN
        DECLARE
        CURSOR C1 IS SELECT MIN_X, MIN_Y, MAX_X, MAX_Y
                     FROM D$DISK_INDEX_RTREE_KEY( T1X ) 
                     WHERE MY_PAGEID = NODE_PAGEID;
        IDX_REC C1%ROWTYPE;
        BEGIN
            OPEN C1;
                LOOP
                    FETCH C1 INTO IDX_REC;
                    EXIT WHEN C1%NOTFOUND;

                    IF NODE_MIN_X > IDX_REC.MIN_X THEN
                        RETURN 'INCONSISTENT';
                        EXIT;
                    END IF;
                    IF NODE_MIN_Y > IDX_REC.MIN_Y THEN
                        RETURN 'INCONSISTENT';
                        EXIT;
                    END IF;
                    IF NODE_MAX_X < IDX_REC.MAX_X THEN
                        RETURN 'INCONSISTENT';
                        EXIT;
                    END IF;
                    IF NODE_MAX_Y < IDX_REC.MAX_Y THEN
                        RETURN 'INCONSISTENT';
                        EXIT;
                    END IF;
                END LOOP;
            CLOSE C1;
        END;
        RETURN 'CONSISTENT';
    END;
/

CREATE OR REPLACE FUNCTION CHECK_INDEX_INTEGRITY_FUNC1()
RETURN CHAR(15)
AS
RESULT CHAR(15);
    BEGIN
        DECLARE
        CURSOR C1 IS SELECT MY_PAGEID, MIN_X, MIN_Y, MAX_X, MAX_Y
                     FROM D$DISK_INDEX_RTREE_STRUCTURE( T1X );
        IDX_REC C1%ROWTYPE;
        BEGIN
            OPEN C1;
                LOOP
                    FETCH C1 INTO IDX_REC;
                    EXIT WHEN C1%NOTFOUND;

                    RESULT := CHECK_INDEX_MBR_FUNC1( IDX_REC.MY_PAGEID, 
                                                     IDX_REC.MIN_X,
                                                     IDX_REC.MIN_Y,
                                                     IDX_REC.MAX_X,
                                                     IDX_REC.MAX_Y );
                    IF RESULT = 'INCONSISTENT' THEN
                        RETURN 'INCONSISTENT';
                        EXIT;
                    END IF;
                END LOOP;
            CLOSE C1;
        END;

        DECLARE
        CURSOR C1 IS SELECT ((SELECT COUNT(*) FROM T1) - 
                             (SELECT COUNT(*) FROM D$DISK_INDEX_RTREE_KEY( T1X ) 
                              WHERE IS_LEAF = 'T' AND STATE <> 'D' AND STATE <> 'd')) DIFF
                     FROM DUAL;
        IDX_REC C1%ROWTYPE;
        BEGIN
            OPEN C1;
                FETCH C1 INTO IDX_REC;

                IF IDX_REC.DIFF <> 0 THEN
                    RETURN 'INCONSISTENT';
                END IF;
            CLOSE C1;
        END;

        RETURN 'CONSISTENT';
    END;
/

CREATE OR REPLACE FUNCTION CHECK_INDEX_MBR_FUNC2(
          NODE_PAGEID  IN INTEGER, 
          NODE_MIN_X   IN DOUBLE,
          NODE_MIN_Y   IN DOUBLE,
          NODE_MAX_X   IN DOUBLE,
          NODE_MAX_Y   IN DOUBLE ) 
RETURN CHAR( 15 )
AS
    BEGIN
        DECLARE
        CURSOR C1 IS SELECT MIN_X, MIN_Y, MAX_X, MAX_Y
                     FROM D$DISK_INDEX_RTREE_KEY( T2X ) 
                     WHERE MY_PAGEID = NODE_PAGEID;
        IDX_REC C1%ROWTYPE;
        BEGIN
            OPEN C1;
                LOOP
                    FETCH C1 INTO IDX_REC;
                    EXIT WHEN C1%NOTFOUND;

                    IF NODE_MIN_X > IDX_REC.MIN_X THEN
                        RETURN 'INCONSISTENT';
                        EXIT;
                    END IF;
                    IF NODE_MIN_Y > IDX_REC.MIN_Y THEN
                        RETURN 'INCONSISTENT';
                        EXIT;
                    END IF;
                    IF NODE_MAX_X < IDX_REC.MAX_X THEN
                        RETURN 'INCONSISTENT';
                        EXIT;
                    END IF;
                    IF NODE_MAX_Y < IDX_REC.MAX_Y THEN
                        RETURN 'INCONSISTENT';
                        EXIT;
                    END IF;
                END LOOP;
            CLOSE C1;
        END;
        RETURN 'CONSISTENT';
    END;
/

CREATE OR REPLACE FUNCTION CHECK_INDEX_INTEGRITY_FUNC2()
RETURN CHAR(15)
AS
RESULT CHAR(15);
    BEGIN
        DECLARE
        CURSOR C1 IS SELECT MY_PAGEID, MIN_X, MIN_Y, MAX_X, MAX_Y
                     FROM D$DISK_INDEX_RTREE_STRUCTURE( T2X );
        IDX_REC C1%ROWTYPE;
        BEGIN
            OPEN C1;
                LOOP
                    FETCH C1 INTO IDX_REC;
                    EXIT WHEN C1%NOTFOUND;

                    RESULT := CHECK_INDEX_MBR_FUNC2( IDX_REC.MY_PAGEID, 
                                                     IDX_REC.MIN_X,
                                                     IDX_REC.MIN_Y,
                                                     IDX_REC.MAX_X,
                                                     IDX_REC.MAX_Y );
                    IF RESULT = 'INCONSISTENT' THEN
                        RETURN 'INCONSISTENT';
                        EXIT;
                    END IF;
                END LOOP;
            CLOSE C1;
        END;

        DECLARE
        CURSOR C1 IS SELECT ((SELECT COUNT(*) FROM T1) - 
                             (SELECT COUNT(*) FROM D$DISK_INDEX_RTREE_KEY( T2X ) 
                              WHERE IS_LEAF = 'T' AND STATE <> 'D' AND STATE <> 'd')) DIFF
                     FROM DUAL;
        IDX_REC C1%ROWTYPE;
        BEGIN
            OPEN C1;
                FETCH C1 INTO IDX_REC;

                IF IDX_REC.DIFF <> 0 THEN
                    RETURN 'INCONSISTENT';
                END IF;
            CLOSE C1;
        END;

        RETURN 'CONSISTENT';
    END;
/

DROP TABLE T1;
DROP TABLE T2;
