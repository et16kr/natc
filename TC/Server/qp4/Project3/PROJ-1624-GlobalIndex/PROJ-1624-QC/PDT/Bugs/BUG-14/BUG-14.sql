--###################################################################
--# DROP CONSTRAINT
--###################################################################

--###################################################################
--+SECTOR; PREPARATION
--###################################################################

--+SKIP BEGIN;
DROP TABLE T1;
--+SKIP END;

CREATE TABLE T1 
(
    I1 NUMERIC, 
    I2 NUMERIC, 
    I3 NUMERIC
) 
PARTITION BY RANGE( I3 )
(
    PARTITION P1 VALUES LESS THAN( 20 ),
    PARTITION P2 VALUES LESS THAN( 40 ),
    PARTITION P3 VALUES DEFAULT
) TABLESPACE SYS_TBS_DISK_DATA;

INSERT INTO T1 VALUES ( NULL, NULL, NULL );
INSERT INTO T1 VALUES ( NULL, NULL, NULL );

--#########################################
--+SECTOR; DO JOB
--#########################################

-- should be success
CREATE UNIQUE INDEX IDX_T1 ON T1 (I3 DESC);

--###################################################################
--+SECTOR; FINALIZATION
--###################################################################

--+SKIP BEGIN;
DROP TABLE T1;
--+SKIP END;

