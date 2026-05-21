--###########################################################################
--# PROJ-1872 initialize compare test
--###########################################################################

--+SKIP BEGIN;
DROP INDEX D1X;
DROP TABLE D1;
DROP PROCEDURE INSERT_DATA;
DROP PROCEDURE INSERT_STRING;
--+SKIP END;

--##################################
--+SECTOR; PREPARATION
--##################################

CREATE TABLE D1 ( I1 BIGINT, I2 BIGINT, I3 BIGINT ) TABLESPACE SYS_TBS_DISK_DATA;

CREATE OR REPLACE PROCEDURE INSERT_DATA(
    COUNT IN INTEGER,
    MAXNUM IN BIGINT )
AS
    BEGIN
        FOR I IN 1 .. COUNT LOOP
            INSERT INTO D1 VALUES( 
                MOD( POWER(1844, I) + 4213, MAXNUM ),
                MOD( POWER(1854, I) + 4213, MAXNUM ),
                MOD( POWER(1864, I) + 4213, MAXNUM )
                );
        END LOOP;
    END;
/

CREATE OR REPLACE PROCEDURE INSERT_STRING ( 
    COUNT IN INTEGER,
    LENGTH IN INTEGER)
AS
    BEGIN
        FOR i IN 1 .. COUNT LOOP
            INSERT INTO D1 VALUES( 
                RPAD( MOD(POWER(1864, I) + 4213,100) , MOD( POWER(1884, I) + 4213, LENGTH), '0'),
                RPAD( MOD(POWER(1874, I) + 4213,100) , MOD( POWER(1894, I) + 4213, LENGTH), '0'),
                RPAD( MOD(POWER(1884, I) + 4213,100) , MOD( POWER(1804, I) + 4213, LENGTH), '0') );
        END LOOP;
    END;
/

DROP TABLE D1;
