--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/PDT/Design/CREATE_TABLE/AS_SELECT/HashPartTable.sql
--#
--# Body below is byte-identical to the original. The one line this port
--# adds is the premise: the original measures these statements on the
--# $GIT_ hidden-table implementation, this file measures the same
--# statements on the native global index (F07 -- see include/pinNative.sql).
--###########################################################################
--###########################################################################
--# NativeGlobalIndexPort1624 - the premise of every ported .sql case.
--#
--# A .sql case cannot CALL a DEF the way a .tc case calls PIN_DISK_NATIVE(),
--# so the same two statements are pulled in per case with ATC's own include
--# directive:
--#
--#     --+LOAD_SQL <relative path>/include/pinNative.sql;
--#
--# ATC inlines this file into the case transcript between BEGIN/END markers,
--# which is exactly what F07 asks for: the case states its own premise at the
--# head of its own transcript instead of inheriting whatever the instance
--# happens to be configured with.
--#
--#     DISK_GLOBAL_INDEX_ENABLE = 1  -> native  (this suite)
--#     DISK_GLOBAL_INDEX_ENABLE = 0  -> $GIT_   (the original suite)
--#
--# The readout below is not decoration. It is the tooth: if the property is
--# ever 0 when a case runs, this one line differs and the case is red before
--# it has measured anything, instead of quietly measuring the other
--# implementation (disk-natc.md 6 records nine assertions that drifted that
--# way).
--#
--# ASCII only, on purpose: 87 of the ported case bodies are EUC-KR and their
--# bytes must stay untouched, so nothing this port adds may introduce a
--# second encoding into a transcript.
--###########################################################################

ALTER SYSTEM SET DISK_GLOBAL_INDEX_ENABLE = 1;

SELECT CAST(VALUE1 AS VARCHAR(10)) DISK_GLOBAL_INDEX_ENABLE
FROM V$PROPERTY WHERE NAME = 'DISK_GLOBAL_INDEX_ENABLE';

--###################################################################
--# CREATE TABLE AS SELECT TEST
--###################################################################

--###################################################################
--+SECTOR; PREPARATION
--###################################################################

--+SKIP BEGIN;
DROP TABLE T1;
DROP TABLE T2;
--+SKIP END;


--###################################################################
--+SECTOR; Hash->Range (Single Part-Key Column)
--###################################################################
DROP TABLE T1;

-- should be success
CREATE TABLE T1 ( I1 INTEGER )
PARTITION BY HASH (I1)
( PARTITION P1,
  PARTITION P2,
  PARTITION P3,
  PARTITION P4
) TABLESPACE PDT_TBS;

INSERT INTO T1 VALUES (NULL);
INSERT INTO T1 VALUES (0);
INSERT INTO T1 VALUES (100);
INSERT INTO T1 VALUES (150);
INSERT INTO T1 VALUES (200);
INSERT INTO T1 VALUES (250);
INSERT INTO T1 VALUES (300);
INSERT INTO T1 VALUES (350);


--##############################
--+SECTOR; CREATE none-partitioned table
--##############################
DROP TABLE T2;
CREATE TABLE T2 ( I1 ) TABLESPACE PDT_TBS
AS SELECT I1 FROM T1;

-- should be 8
SELECT COUNT(*) FROM T2;


--##############################
--+SECTOR; CREATE partitioned table
--##############################
DROP TABLE T2;
CREATE TABLE T2 ( I1 )
PARTITION BY RANGE(I1)
(
    PARTITION P1 VALUES LESS THAN (100),
    PARTITION P2 VALUES LESS THAN (200),
    PARTITION P3 VALUES LESS THAN (300),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS
AS SELECT I1 FROM T1;

-- result: 1
SELECT COUNT(*) FROM T2 PARTITION (P1);
-- result: 2
SELECT COUNT(*) FROM T2 PARTITION (P2);
-- result: 2
SELECT COUNT(*) FROM T2 PARTITION (P3);
-- result: 3
SELECT COUNT(*) FROM T2 PARTITION (P4);


--##############################
--+SECTOR; prepruning
--##############################
DROP TABLE T2;
CREATE TABLE T2 ( I1 )
PARTITION BY RANGE(I1)
(
    PARTITION P1 VALUES LESS THAN (150),
    PARTITION P2 VALUES LESS THAN (250),
    PARTITION P3 VALUES LESS THAN (350),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS
AS SELECT I1 FROM T1 PARTITION(P2);

SELECT COUNT(*) FROM T2 PARTITION (P1);
SELECT COUNT(*) FROM T2 PARTITION (P2);
SELECT COUNT(*) FROM T2 PARTITION (P3);
SELECT COUNT(*) FROM T2 PARTITION (P4);



--###################################################################
--+SECTOR; Hash->List (Single Part-Key Column)
--###################################################################

--##############################
--+SECTOR; CREATE none-partitioned table
--##############################
DROP TABLE T2;
CREATE TABLE T2 ( I1 ) TABLESPACE PDT_TBS
AS SELECT I1 FROM T1;

-- should be 8
SELECT COUNT(*) FROM T2;


--##############################
--+SECTOR; CREATE partitioned table
--##############################
DROP TABLE T2;
CREATE TABLE T2 ( I1 )
PARTITION BY LIST(I1)
(
    PARTITION P1 VALUES (NULL, 0),
    PARTITION P2 VALUES (100, 150),
    PARTITION P3 VALUES (200, 250),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS
AS SELECT I1 FROM T1;

-- result: 2
SELECT COUNT(*) FROM T2 PARTITION (P1);
-- result: 2
SELECT COUNT(*) FROM T2 PARTITION (P2);
-- result: 2
SELECT COUNT(*) FROM T2 PARTITION (P3);
-- result: 2
SELECT COUNT(*) FROM T2 PARTITION (P4);


--##############################
--+SECTOR; prepruning
--##############################
DROP TABLE T2;
CREATE TABLE T2 ( I1 )
PARTITION BY LIST(I1)
(
    PARTITION P1 VALUES (NULL, 0),
    PARTITION P2 VALUES (100, 150),
    PARTITION P3 VALUES (200, 250),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS
AS SELECT I1 FROM T1 PARTITION(P2);

SELECT COUNT(*) FROM T2 PARTITION (P1);
SELECT COUNT(*) FROM T2 PARTITION (P2);
SELECT COUNT(*) FROM T2 PARTITION (P3);
SELECT COUNT(*) FROM T2 PARTITION (P4);



--###################################################################
--+SECTOR; Hash->Hash(Single Part-Key Column)
--###################################################################

--##############################
--+SECTOR; CREATE none-partitioned table
--##############################
DROP TABLE T2;
CREATE TABLE T2 ( I1 ) TABLESPACE PDT_TBS
AS SELECT I1 FROM T1;

-- should be 8
SELECT COUNT(*) FROM T2;


--##############################
--+SECTOR; CREATE partitioned table
--##############################
DROP TABLE T2;
CREATE TABLE T2 ( I1 )
PARTITION BY HASH(I1)
(
    PARTITION P1,
    PARTITION P2,
    PARTITION P3,
    PARTITION P4
) TABLESPACE PDT_TBS
AS SELECT I1 FROM T1;

-- result: 8
SELECT COUNT(*) FROM T2;


--##############################
--+SECTOR; prepruning
--##############################
DROP TABLE T2;
CREATE TABLE T2 ( I1 )
PARTITION BY HASH(I1)
(
    PARTITION P1,
    PARTITION P2,
    PARTITION P3,
    PARTITION P4
) TABLESPACE PDT_TBS
AS SELECT I1 FROM T1 PARTITION(P2);

SELECT COUNT(*) FROM T2;



--###################################################################
--+SECTOR; Hash->Range (Multiple Part-Key Column, Index )
--###################################################################
DROP TABLE T1;

-- should be success
CREATE TABLE T1 ( I1 INTEGER, I2 VARCHAR(1000) )
PARTITION BY HASH (I1, I2)
( PARTITION P1,
  PARTITION P2,
  PARTITION P3,
  PARTITION P4
) TABLESPACE PDT_TBS;

INSERT INTO T1 VALUES (NULL, 'ABC');
INSERT INTO T1 VALUES (0, 'ABC');
INSERT INTO T1 VALUES (100, 'ABC');
INSERT INTO T1 VALUES (150, 'ABC');
INSERT INTO T1 VALUES (200, 'ABC');
INSERT INTO T1 VALUES (250, 'ABC');
INSERT INTO T1 VALUES (300, 'ABC');
INSERT INTO T1 VALUES (350, 'ABC');

CREATE INDEX IDX1 ON T1(I1) LOCAL;
CREATE INDEX IDX2 ON T1(I2) LOCAL;
CREATE INDEX IDX3 ON T1(I1, I2) LOCAL;


--##############################
--+SECTOR; CREATE none-partitioned table
--##############################
DROP TABLE T2;
CREATE TABLE T2 ( I1, I2 ) TABLESPACE PDT_TBS
AS SELECT I1, I2 FROM T1;

-- should be 8
SELECT COUNT(*) FROM T2;


--##############################
--+SECTOR; CREATE partitioned table
--##############################
DROP TABLE T2;
CREATE TABLE T2 ( I1, I2 )
PARTITION BY RANGE(I1)
(
    PARTITION P1 VALUES LESS THAN (100),
    PARTITION P2 VALUES LESS THAN (200),
    PARTITION P3 VALUES LESS THAN (300),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS
AS SELECT I1, I2 FROM T1;

-- result: 1
SELECT COUNT(*) FROM T2 PARTITION (P1);
-- result: 2
SELECT COUNT(*) FROM T2 PARTITION (P2);
-- result: 2
SELECT COUNT(*) FROM T2 PARTITION (P3);
-- result: 3
SELECT COUNT(*) FROM T2 PARTITION (P4);


--##############################
--+SECTOR; prepruning
--##############################
DROP TABLE T2;
CREATE TABLE T2 ( I1, I2 )
PARTITION BY RANGE(I1)
(
    PARTITION P1 VALUES LESS THAN (150),
    PARTITION P2 VALUES LESS THAN (250),
    PARTITION P3 VALUES LESS THAN (350),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS
AS SELECT I1, I2 FROM T1 PARTITION(P2);

SELECT COUNT(*) FROM T2 PARTITION (P1);
SELECT COUNT(*) FROM T2 PARTITION (P2);
SELECT COUNT(*) FROM T2 PARTITION (P3);
SELECT COUNT(*) FROM T2 PARTITION (P4);



--###################################################################
--+SECTOR; Hash->List (Multiple Part-Key Column, Index )
--###################################################################

--##############################
--+SECTOR; CREATE none-partitioned table
--##############################
DROP TABLE T2;
CREATE TABLE T2 ( I1, I2 ) TABLESPACE PDT_TBS
AS SELECT I1, I2 FROM T1;

-- should be 8
SELECT COUNT(*) FROM T2;


--##############################
--+SECTOR; CREATE partitioned table
--##############################
DROP TABLE T2;
CREATE TABLE T2 ( I1, I2 )
PARTITION BY LIST(I1)
(
    PARTITION P1 VALUES (NULL, 0),
    PARTITION P2 VALUES (100, 150),
    PARTITION P3 VALUES (200, 250),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS
AS SELECT I1, I2 FROM T1;

-- result: 2
SELECT COUNT(*) FROM T2 PARTITION (P1);
-- result: 2
SELECT COUNT(*) FROM T2 PARTITION (P2);
-- result: 2
SELECT COUNT(*) FROM T2 PARTITION (P3);
-- result: 2
SELECT COUNT(*) FROM T2 PARTITION (P4);


--##############################
--+SECTOR; prepruning
--##############################
DROP TABLE T2;
CREATE TABLE T2 ( I1, I2 )
PARTITION BY LIST(I1)
(
    PARTITION P1 VALUES (NULL, 0),
    PARTITION P2 VALUES (100, 150),
    PARTITION P3 VALUES (200, 250),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS
AS SELECT I1, I2 FROM T1 PARTITION(P2);

SELECT COUNT(*) FROM T2 PARTITION (P1);
SELECT COUNT(*) FROM T2 PARTITION (P2);
SELECT COUNT(*) FROM T2 PARTITION (P3);
SELECT COUNT(*) FROM T2 PARTITION (P4);



--###################################################################
--+SECTOR; Hash->Hash (Multiple Part-Key Column, Index )
--###################################################################

--##############################
--+SECTOR; CREATE none-partitioned table
--##############################
DROP TABLE T2;
CREATE TABLE T2 ( I1, I2 ) TABLESPACE PDT_TBS
AS SELECT I1, I2 FROM T1;

-- should be 8
SELECT COUNT(*) FROM T2;


--##############################
--+SECTOR; CREATE partitioned table
--##############################
DROP TABLE T2;
CREATE TABLE T2 ( I1, I2 )
PARTITION BY HASH(I1)
(
    PARTITION P1,
    PARTITION P2,
    PARTITION P3,
    PARTITION P4
) TABLESPACE PDT_TBS
AS SELECT I1, I2 FROM T1;

-- result: 8
SELECT COUNT(*) FROM T2;


--##############################
--+SECTOR; prepruning
--##############################
DROP TABLE T2;
CREATE TABLE T2 ( I1, I2 )
PARTITION BY HASH(I1)
(
    PARTITION P1,
    PARTITION P2,
    PARTITION P3,
    PARTITION P4
) TABLESPACE PDT_TBS
AS SELECT I1, I2 FROM T1 PARTITION(P2);

SELECT COUNT(*) FROM T2;



--###################################################################
--+SECTOR; Hash->Range (Multiple Part-Key Column, Index, Lob Column )
--###################################################################
DROP TABLE T1;

-- should be success
CREATE TABLE T1 ( I1 INTEGER, I2 VARCHAR(1000), I3 BLOB, I4 BLOB )
PARTITION BY HASH (I1, I2)
( PARTITION P1 TABLESPACE PDT_TBS2
            LOB STORE AS ( TABLESPACE PDT_TBS3 ),
  PARTITION P2 
            LOB(I3) STORE AS ( TABLESPACE PDT_TBS4 ),
  PARTITION P3
            LOB(I4) STORE AS ( TABLESPACE PDT_TBS5 ),
  PARTITION P4
) TABLESPACE PDT_TBS;

INSERT INTO T1 VALUES (NULL, 'ABC', 'ABC', 'ABC' );
INSERT INTO T1 VALUES (0, 'ABC', 'ABC', 'ABC' );
INSERT INTO T1 VALUES (100, 'ABC', 'ABC', 'ABC' );
INSERT INTO T1 VALUES (150, 'ABC', 'ABC', 'ABC' );
INSERT INTO T1 VALUES (200, 'ABC', 'ABC', 'ABC' );
INSERT INTO T1 VALUES (250, 'ABC', 'ABC', 'ABC' );
INSERT INTO T1 VALUES (300, 'ABC', 'ABC', 'ABC' );
INSERT INTO T1 VALUES (350, 'ABC', 'ABC', 'ABC' );

CREATE INDEX IDX1 ON T1(I1) LOCAL;
CREATE INDEX IDX2 ON T1(I2) LOCAL;
CREATE INDEX IDX3 ON T1(I1, I2) LOCAL;


--##############################
--+SECTOR; CREATE none-partitioned table
--##############################
DROP TABLE T2;
CREATE TABLE T2 ( I1, I2, I3, I4 ) TABLESPACE PDT_TBS
AS SELECT I1, I2, I3, I4 FROM T1;

-- should be 8
SELECT COUNT(*) FROM T2;


--##############################
--+SECTOR; CREATE partitioned table
--##############################
DROP TABLE T2;
CREATE TABLE T2 ( I1, I2, I3, I4 )
PARTITION BY RANGE(I1)
(
    PARTITION P1 VALUES LESS THAN (100) TABLESPACE PDT_TBS2
                            LOB (I3) STORE AS ( TABLESPACE PDT_TBS3 ),
    PARTITION P2 VALUES LESS THAN (200)
                            LOB (I4) STORE AS ( TABLESPACE PDT_TBS4 ),
    PARTITION P3 VALUES LESS THAN (300)
                            LOB STORE AS ( TABLESPACE PDT_TBS5 ),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS
AS SELECT I1, I2, I3, I4 FROM T1;

-- result: 1
SELECT COUNT(*) FROM T2 PARTITION (P1);
-- result: 2
SELECT COUNT(*) FROM T2 PARTITION (P2);
-- result: 2
SELECT COUNT(*) FROM T2 PARTITION (P3);
-- result: 3
SELECT COUNT(*) FROM T2 PARTITION (P4);


--##############################
--+SECTOR; prepruning
--##############################
DROP TABLE T2;
CREATE TABLE T2 ( I1, I2, I3, I4 )
PARTITION BY RANGE(I1)
(
    PARTITION P1 VALUES LESS THAN (150),
    PARTITION P2 VALUES LESS THAN (250) TABLESPACE PDT_TBS2
                            LOB (I3) STORE AS ( TABLESPACE PDT_TBS3 ),
    PARTITION P3 VALUES LESS THAN (350)
                            LOB STORE AS ( TABLESPACE PDT_TBS4 ),
    PARTITION P4 VALUES DEFAULT
                            LOB (I4) STORE AS ( TABLESPACE PDT_TBS5 )
) TABLESPACE PDT_TBS
AS SELECT I1, I2, I3, I4 FROM T1 PARTITION(P2);

SELECT COUNT(*) FROM T2 PARTITION (P1);
SELECT COUNT(*) FROM T2 PARTITION (P2);
SELECT COUNT(*) FROM T2 PARTITION (P3);
SELECT COUNT(*) FROM T2 PARTITION (P4);



--###################################################################
--+SECTOR; Hash->List (Multiple Part-Key Column, Index, Lob Column )
--###################################################################

--##############################
--+SECTOR; CREATE none-partitioned table
--##############################
DROP TABLE T2;
CREATE TABLE T2 ( I1, I2, I3, I4 ) TABLESPACE PDT_TBS
AS SELECT I1, I2, I3, I4 FROM T1;

-- should be 8
SELECT COUNT(*) FROM T2;


--##############################
--+SECTOR; CREATE partitioned table
--##############################
DROP TABLE T2;
CREATE TABLE T2 ( I1, I2, I3, I4 )
PARTITION BY LIST(I1)
(
    PARTITION P1 VALUES (NULL, 0) TABLESPACE PDT_TBS2
                            LOB (I3) STORE AS ( TABLESPACE PDT_TBS3 ),
    PARTITION P2 VALUES (100, 150)
                            LOB (I4) STORE AS ( TABLESPACE PDT_TBS4 ),
    PARTITION P3 VALUES (200, 250)
                            LOB STORE AS ( TABLESPACE PDT_TBS5 ),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE PDT_TBS
AS SELECT I1, I2, I3, I4 FROM T1;

-- result: 2
SELECT COUNT(*) FROM T2 PARTITION (P1);
-- result: 2
SELECT COUNT(*) FROM T2 PARTITION (P2);
-- result: 2
SELECT COUNT(*) FROM T2 PARTITION (P3);
-- result: 2
SELECT COUNT(*) FROM T2 PARTITION (P4);


--##############################
--+SECTOR; prepruning
--##############################
DROP TABLE T2;
CREATE TABLE T2 ( I1, I2, I3, I4 )
PARTITION BY LIST(I1)
(
    PARTITION P1 VALUES (NULL, 0),
    PARTITION P2 VALUES (100, 150) TABLESPACE PDT_TBS2
                            LOB (I3) STORE AS ( TABLESPACE PDT_TBS3 ),
    PARTITION P3 VALUES (200, 250)
                            LOB STORE AS ( TABLESPACE PDT_TBS4 ),
    PARTITION P4 VALUES DEFAULT
                            LOB (I4) STORE AS ( TABLESPACE PDT_TBS5 )
) TABLESPACE PDT_TBS
AS SELECT I1, I2, I3, I4 FROM T1 PARTITION(P2);

SELECT COUNT(*) FROM T2 PARTITION (P1);
SELECT COUNT(*) FROM T2 PARTITION (P2);
SELECT COUNT(*) FROM T2 PARTITION (P3);
SELECT COUNT(*) FROM T2 PARTITION (P4);



--###################################################################
--+SECTOR; Hash->Hash (Multiple Part-Key Column, Index, Lob Column )
--###################################################################

--##############################
--+SECTOR; CREATE none-partitioned table
--##############################
DROP TABLE T2;
CREATE TABLE T2 ( I1, I2, I3, I4 ) TABLESPACE PDT_TBS
AS SELECT I1, I2, I3, I4 FROM T1;

-- should be 8
SELECT COUNT(*) FROM T2;


--##############################
--+SECTOR; CREATE partitioned table
--##############################
DROP TABLE T2;
CREATE TABLE T2 ( I1, I2, I3, I4 )
PARTITION BY HASH(I1)
(
    PARTITION P1 TABLESPACE PDT_TBS2
            LOB (I3) STORE AS ( TABLESPACE PDT_TBS3 ),
    PARTITION P2 
            LOB (I4) STORE AS ( TABLESPACE PDT_TBS4 ),
    PARTITION P3
            LOB STORE AS ( TABLESPACE PDT_TBS5 ),
    PARTITION P4
) TABLESPACE PDT_TBS
AS SELECT I1, I2, I3, I4 FROM T1;

-- result: 8
SELECT COUNT(*) FROM T2;


--##############################
--+SECTOR; prepruning
--##############################
DROP TABLE T2;
CREATE TABLE T2 ( I1, I2, I3, I4 )
PARTITION BY HASH(I1)
(
    PARTITION P1 TABLESPACE PDT_TBS2
            LOB (I3) STORE AS ( TABLESPACE PDT_TBS3 ),
    PARTITION P2 
            LOB (I4) STORE AS ( TABLESPACE PDT_TBS4 ),
    PARTITION P3
            LOB STORE AS ( TABLESPACE PDT_TBS5 ),
    PARTITION P4
) TABLESPACE PDT_TBS
AS SELECT I1, I2, I3, I4 FROM T1 PARTITION(P2);

SELECT COUNT(*) FROM T2;



--##################################################################
--+SECTOR; FINALIZATION
--##################################################################
--+SKIP BEGIN;
DROP TABLE T1 CASCADE;
DROP TABLE T2 CASCADE;
--+SKIP END;
