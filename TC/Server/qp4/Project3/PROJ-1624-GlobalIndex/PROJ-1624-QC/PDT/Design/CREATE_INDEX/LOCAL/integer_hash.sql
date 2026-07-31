--######################################################
-- INDEX LOCAL PARTITIOIN ON HASH PDT( PK:INTEGER )
--######################################################

--###################################
--+SECTOR; INTIALIZE
--###################################

--+SKIP BEGIN;
DROP TABLE PDT_HASH;
--+SKIP END;


--#########################################
--+SECTOR; DO JOB #1 (1. Basic Test)
--#########################################

----------------------------------------
-- 2.1 CREATING INDEX USING CREATE_TABLE
----------------------------------------
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
INSERT INTO PDT_HASH VALUES( 7, 0 );
INSERT INTO PDT_HASH VALUES( 6, 0 );
INSERT INTO PDT_HASH VALUES( 5, 0 );
INSERT INTO PDT_HASH VALUES( 4, 0 );
INSERT INTO PDT_HASH VALUES( 3, 0 );
INSERT INTO PDT_HASH VALUES( 2, 0 );
INSERT INTO PDT_HASH VALUES( 1, 0 );
INSERT INTO PDT_HASH VALUES( 0, 0 );

-- should be {0}
SELECT F1 FROM PDT_HASH
WHERE F1 >= 0 LIMIT 1;

----------------------------------------
-- 2.2 CREATING INDEX USING CREATE_INDEX
----------------------------------------
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
INSERT INTO PDT_HASH VALUES( 7, 0 );
INSERT INTO PDT_HASH VALUES( 6, 0 );
INSERT INTO PDT_HASH VALUES( 5, 0 );
INSERT INTO PDT_HASH VALUES( 4, 0 );
INSERT INTO PDT_HASH VALUES( 3, 0 );
INSERT INTO PDT_HASH VALUES( 2, 0 );
INSERT INTO PDT_HASH VALUES( 1, 0 );
INSERT INTO PDT_HASH VALUES( 0, 0 );

-- should be {4}
SELECT F1 FROM PDT_HASH PARTITION( P1 ) LIMIT 1;

CREATE INDEX IDX_LOCAL 
ON PDT_HASH( F1 ) LOCAL;

-- should be {0}
SELECT /*+ INDEX ASC ( PDT_HASH, IDX_LOCAL ) */ F1
FROM PDT_HASH PARTITION( P1 ) LIMIT 1;

--#########################################
--+SECTOR; DO JOB #2 (2. Validation Test)
--#########################################

----------------------------
-- 2.1 파티셔너블 객체 검사 
----------------------------
CREATE TABLE T
(
    F1   INTEGER,
    F2   INTEGER
);
-- should be fail
CREATE INDEX IDX_LOCAL 
ON T( F1 ) LOCAL;

-----------------------------------
-- 2.2 유니크 인덱스 생성 여부 검사 
-----------------------------------
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

-- should be fail
CREATE UNIQUE INDEX IDX_LOCAL 
ON PDT_HASH( F2 ) LOCAL;

-----------------------------------
-- 2.3 인덱스 파티션 개수 검사 
-----------------------------------
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

-- should be fail
CREATE INDEX IDX_LOCAL 
ON PDT_HASH( F1 ) LOCAL
(
    PARTITION IDX_P1 ON P1,
    PARTITION IDX_P2 ON P2,
    PARTITION IDX_P3 ON P3,
    PARTITION IDX_P4 ON P4,
    PARTITION IDX_P5 ON P5
);

-- should be fail
CREATE INDEX IDX_LOCAL 
ON PDT_HASH( F1 ) LOCAL
(
    PARTITION IDX_P1 ON P1,
    PARTITION IDX_P5 ON P5
);

-- should be success
CREATE INDEX IDX_LOCAL 
ON PDT_HASH( F1 ) LOCAL
(
    PARTITION IDX_P1 ON P1
);

-----------------------------------
-- 2.4 인덱스 이름 중복 검사
-----------------------------------
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

-- should be fail
CREATE INDEX IDX_LOCAL 
ON PDT_HASH( F1 ) LOCAL
(
    PARTITION IDX_P1 ON P1,
    PARTITION IDX_P2 ON P2,
    PARTITION IDX_P3 ON P2,
    PARTITION IDX_P4 ON P4
);

-- should be fail
CREATE INDEX IDX_LOCAL 
ON PDT_HASH( F1 ) LOCAL
(
    PARTITION IDX_P1 ON P1,
    PARTITION IDX_P2 ON P2,
    PARTITION IDX_P2 ON P3,
    PARTITION IDX_P4 ON P4
);


-----------------------------------
-- 2.5 테이블스페이스 검사 
-----------------------------------
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

-- memory tablespace
-- should be fail
CREATE INDEX IDX_LOCAL 
ON PDT_HASH( F1 ) LOCAL
(
    PARTITION IDX_P1 ON P1 TABLESPACE SYS_TBS_MEM_DATA
);

-- should be fail
-- temporary tablespace
CREATE INDEX IDX_LOCAL 
ON PDT_HASH( F1 ) LOCAL
(
    PARTITION IDX_P1 ON P1 TABLESPACE SYS_TBS_TEMP
);

-- should be fail
-- undo tablespace
CREATE INDEX IDX_LOCAL 
ON PDT_HASH( F1 ) LOCAL
(
    PARTITION IDX_P1 ON P1 TABLESPACE SYS_TBS_UNDO
);

--#########################################
--+SECTOR; DO JOB #3 (3. Execution Test)
--#########################################

-----------------------------------------
-- 3.1 Preserved Order(프리픽스드 인덱스)
-----------------------------------------
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
INSERT INTO PDT_HASH VALUES( 7, 0 );
INSERT INTO PDT_HASH VALUES( 6, 0 );
INSERT INTO PDT_HASH VALUES( 5, 0 );
INSERT INTO PDT_HASH VALUES( 4, 0 );
INSERT INTO PDT_HASH VALUES( 3, 0 );
INSERT INTO PDT_HASH VALUES( 2, 0 );
INSERT INTO PDT_HASH VALUES( 1, 0 );
INSERT INTO PDT_HASH VALUES( 0, 0 );

CREATE UNIQUE INDEX IDX_LOCAL 
ON PDT_HASH( F1 ) LOCAL;

-- should be {0,1,2,3,4,5,6,7}
SELECT /*+ INDEX ASC ( PDT_HASH, IDX_LOCAL ) */ F1
FROM PDT_HASH;

-----------------------------------------------
-- 3.2 Non-Preserved Order(논프리픽스드 인덱스)
-----------------------------------------------
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
INSERT INTO PDT_HASH VALUES( 7, 2 );
INSERT INTO PDT_HASH VALUES( 6, 3 );
INSERT INTO PDT_HASH VALUES( 5, 4 );
INSERT INTO PDT_HASH VALUES( 4, 5 );
INSERT INTO PDT_HASH VALUES( 3, 6 );
INSERT INTO PDT_HASH VALUES( 2, 7 );
INSERT INTO PDT_HASH VALUES( 1, 0 );
INSERT INTO PDT_HASH VALUES( 0, 1 );

CREATE UNIQUE INDEX IDX_LOCAL 
ON PDT_HASH( F2 ) LOCAL;

-- will be {1,5,0,4,3,7,2,6}
SELECT /*+ INDEX ASC ( PDT_HASH, IDX_LOCAL ) */ F2
FROM PDT_HASH;

-----------------------------------------
-- 3.3 Unique violation
-----------------------------------------
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
INSERT INTO PDT_HASH VALUES( 7, 2 );
INSERT INTO PDT_HASH VALUES( 6, 3 );
INSERT INTO PDT_HASH VALUES( 5, 4 );
INSERT INTO PDT_HASH VALUES( 4, 5 );
INSERT INTO PDT_HASH VALUES( 3, 6 );
INSERT INTO PDT_HASH VALUES( 2, 7 );
INSERT INTO PDT_HASH VALUES( 1, 0 );
INSERT INTO PDT_HASH VALUES( 0, 1 );

CREATE UNIQUE INDEX IDX_LOCAL 
ON PDT_HASH( F1 ) LOCAL;

-- should be fail
INSERT INTO PDT_HASH VALUES( 7, 2 );
-- should be fail
INSERT INTO PDT_HASH VALUES( 6, 3 );
-- should be fail
INSERT INTO PDT_HASH VALUES( 5, 4 );
-- should be fail
INSERT INTO PDT_HASH VALUES( 4, 5 );
-- should be fail
INSERT INTO PDT_HASH VALUES( 3, 6 );
-- should be fail
INSERT INTO PDT_HASH VALUES( 2, 7 );
-- should be fail
INSERT INTO PDT_HASH VALUES( 1, 0 );
-- should be fail
INSERT INTO PDT_HASH VALUES( 0, 1 );

ALTER TABLE PDT_HASH
ENABLE ROW MOVEMENT;

-- should be fail
UPDATE PDT_HASH SET F1 = 6
WHERE F1 = 7;

--###################################
--+SECTOR; FINALIZE
--###################################

DROP TABLE PDT_HASH;
