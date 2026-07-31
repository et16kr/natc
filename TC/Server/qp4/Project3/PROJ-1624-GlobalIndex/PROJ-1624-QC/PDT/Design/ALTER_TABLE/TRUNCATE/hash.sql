--######################################################
-- TRUNCATE PARTITIOIN
--######################################################

--###################################
--+SECTOR; INTIALIZE
--###################################

--+SKIP BEGIN;
DROP TABLE T1;
DROP TABLE PDT_HASH;
--+SKIP END;

CREATE TABLE PDT_HASH
(
    F1   INTEGER,
    F2   INTEGER
) 
PARTITION BY HASH( F1 )
(
    PARTITION P1,
    PARTITION P2,
    PARTITION P3,
    PARTITION P4
) TABLESPACE PDT_TBS;


--#########################################
--+SECTOR; DO JOB #1 (1. Basic Test)
--#########################################

INSERT INTO PDT_HASH VALUES( 0, 0 );
INSERT INTO PDT_HASH VALUES( 1, 0 );
INSERT INTO PDT_HASH VALUES( 2, 0 );
INSERT INTO PDT_HASH VALUES( 3, 0 );
INSERT INTO PDT_HASH VALUES( 4, 0 );

-- should be 5
SELECT COUNT(*) FROM PDT_HASH;

ALTER TABLE PDT_HASH
TRUNCATE PARTITION P1;

SELECT COUNT(*) FROM PDT_HASH;

-- should be 0
SELECT COUNT(*) FROM PDT_HASH PARTITION( P1 );


--#########################################
--+SECTOR; DO JOB #2 (2. Validation Test)
--#########################################

----------------------------
-- 2.1 파티션 이름 검사
----------------------------
-- should be fail
ALTER TABLE PDT_HASH
TRUNCATE PARTITION P5;

----------------------------
-- 2.2 참조키 검사 
----------------------------
DROP TABLE PDT_HASH;
CREATE TABLE PDT_HASH
(
    F1   INTEGER PRIMARY KEY,
    F2   INTEGER
) 
PARTITION BY HASH( F1 )
(
    PARTITION P1,
    PARTITION P2,
    PARTITION P3,
    PARTITION P4
) TABLESPACE PDT_TBS;
INSERT INTO PDT_HASH VALUES( 0, 0 );
INSERT INTO PDT_HASH VALUES( 1, 0 );
INSERT INTO PDT_HASH VALUES( 2, 0 );
INSERT INTO PDT_HASH VALUES( 3, 0 );
INSERT INTO PDT_HASH VALUES( 4, 0 );

CREATE TABLE T1
(
    F1  INTEGER CONSTRAINT FK_CONST REFERENCES PDT_HASH( F1 ),
    F2  INTEGER
);

-- should be fail
ALTER TABLE PDT_HASH
TRUNCATE PARTITION P1;


--#########################################
--+SECTOR; DO JOB #3 (3. Execution Test)
--#########################################

DROP TABLE T1;
DROP TABLE PDT_HASH;
CREATE TABLE PDT_HASH
(
    F1   INTEGER,
    F2   INTEGER
) 
PARTITION BY HASH( F1 )
(
    PARTITION P1,
    PARTITION P2,
    PARTITION P3,
    PARTITION P4
) TABLESPACE PDT_TBS;
INSERT INTO PDT_HASH VALUES( 0, 0 );
INSERT INTO PDT_HASH VALUES( 1, 0 );
INSERT INTO PDT_HASH VALUES( 2, 0 );
INSERT INTO PDT_HASH VALUES( 3, 0 );
INSERT INTO PDT_HASH VALUES( 4, 0 );
INSERT INTO PDT_HASH VALUES( NULL, 0 );
INSERT INTO PDT_HASH VALUES( NULL, 0 );

SELECT F1 FROM PDT_HASH;

ALTER TABLE PDT_HASH
TRUNCATE PARTITION P4;

SELECT F1 FROM PDT_HASH;

SELECT F1 FROM PDT_HASH PARTITION( P1 );
SELECT F1 FROM PDT_HASH PARTITION( P2 );
SELECT F1 FROM PDT_HASH PARTITION( P3 );
SELECT F1 FROM PDT_HASH PARTITION( P4 );


--###################################
--+SECTOR; FINALIZE
--###################################

DROP TABLE PDT_HASH;
