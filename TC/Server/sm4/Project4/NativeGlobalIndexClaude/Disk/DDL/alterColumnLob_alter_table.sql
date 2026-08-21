--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/PDT/Design/ALTER_TABLE/ALTER_COLUMN_LOB/alter_table.sql
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
--# ALTER TABLE ... ALTER COLUMN LOB
--###################################################################

--###################################################################
--+SECTOR; PREPARATION
--###################################################################

--+SKIP BEGIN;
DROP TABLE T1;
DROP TABLE T2;
--+SKIP END;

CREATE TABLE T1( I1 INTEGER, I2 CLOB DEFAULT 'DEFAULT', I3 BLOB )
PARTITION BY HASH (I1)
(
    PARTITION P1,
    PARTITION P2,
    PARTITION P3,
    PARTITION P4
) TABLESPACE SYS_TBS_DISK_DATA;

INSERT INTO T1 VALUES ( 1, 'CLOB1', 'FF' );
INSERT INTO T1 VALUES ( 2, 'CLOB2', 'FFFF' );
INSERT INTO T1 VALUES ( 3, 'CLOB3', 'FFFFFF' );
INSERT INTO T1 VALUES ( 4, 'CLOB4', 'FFFFFFFF' );
INSERT INTO T1 VALUES ( 5, 'CLOB5', 'FFFFFFFFFF' );

CREATE TABLE T2( I1 INTEGER, I2 CLOB DEFAULT 'DEFAULT', I3 BLOB )
PARTITION BY RANGE (I1)
(
    PARTITION P1 VALUES LESS THAN (2),
    PARTITION P2 VALUES LESS THAN (3),
    PARTITION P3 VALUES LESS THAN (4),
    PARTITION P4 VALUES DEFAULT
) TABLESPACE SYS_TBS_DISK_DATA;

INSERT INTO T2 VALUES ( 1, 'CLOB1', 'FF' );
INSERT INTO T2 VALUES ( 2, 'CLOB2', 'FFFF' );
INSERT INTO T2 VALUES ( 3, 'CLOB3', 'FFFFFF' );
INSERT INTO T2 VALUES ( 4, 'CLOB4', 'FFFFFFFF' );
INSERT INTO T2 VALUES ( 5, 'CLOB5', 'FFFFFFFFFF' );


--#########################################################################
--+ SECTOR; 1. ADD PARTITION
--#########################################################################

---------------------------------------------------
-- 1.1 LOB STORE
---------------------------------------------------
ALTER TABLE T1 ALTER COLUMN LOB STORE AS ( NOLOGGING );
ALTER TABLE T1 ADD PARTITION P5;
-- {(P5,F,T), (P5,F,T)}
SELECT PART.PARTITION_NAME, LOBS.LOGGING, LOBS.BUFFER
FROM SYSTEM_.SYS_TABLES_ TAB, SYSTEM_.SYS_PART_LOBS_ LOBS,
     SYSTEM_.SYS_TABLE_PARTITIONS_ PART
WHERE TAB.TABLE_ID = LOBS.TABLE_ID AND
      TAB.TABLE_NAME = 'T1' AND 
      PART.PARTITION_ID = LOBS.PARTITION_ID AND
      PART.PARTITION_NAME = 'P5'
ORDER BY PART.PARTITION_NAME, LOBS.COLUMN_ID;
ALTER TABLE T1 COALESCE PARTITION;

---------------------------------------------------
-- 초기화
---------------------------------------------------
ALTER TABLE T1 ALTER COLUMN LOB STORE AS ( LOGGING BUFFER );

---------------------------------------------------
-- 1.2 LOB( clob_column ) STORE
---------------------------------------------------
ALTER TABLE T1 ALTER COLUMN LOB(I2) STORE AS ( NOLOGGING );
ALTER TABLE T1 ADD PARTITION P5;
-- {(P5,F,T), (P5,T,T)}
SELECT PART.PARTITION_NAME, LOBS.LOGGING, LOBS.BUFFER
FROM SYSTEM_.SYS_TABLES_ TAB, SYSTEM_.SYS_PART_LOBS_ LOBS,
     SYSTEM_.SYS_TABLE_PARTITIONS_ PART
WHERE TAB.TABLE_ID = LOBS.TABLE_ID AND
      TAB.TABLE_NAME = 'T1' AND 
      PART.PARTITION_ID = LOBS.PARTITION_ID AND
      PART.PARTITION_NAME = 'P5'
ORDER BY PART.PARTITION_NAME, LOBS.COLUMN_ID;
ALTER TABLE T1 COALESCE PARTITION;

---------------------------------------------------
-- 초기화
---------------------------------------------------
ALTER TABLE T1 ALTER COLUMN LOB STORE AS ( LOGGING BUFFER );

---------------------------------------------------
-- 1.3 LOB( blob_column ) STORE
---------------------------------------------------
ALTER TABLE T1 ALTER COLUMN LOB(I3) STORE AS ( NOLOGGING );
ALTER TABLE T1 ADD PARTITION P5;
-- {(P5,T,T), (P5,F,T)}
SELECT PART.PARTITION_NAME, LOBS.LOGGING, LOBS.BUFFER
FROM SYSTEM_.SYS_TABLES_ TAB, SYSTEM_.SYS_PART_LOBS_ LOBS,
     SYSTEM_.SYS_TABLE_PARTITIONS_ PART
WHERE TAB.TABLE_ID = LOBS.TABLE_ID AND
      TAB.TABLE_NAME = 'T1' AND 
      PART.PARTITION_ID = LOBS.PARTITION_ID AND
      PART.PARTITION_NAME = 'P5'
ORDER BY PART.PARTITION_NAME, LOBS.COLUMN_ID;
ALTER TABLE T1 COALESCE PARTITION;

---------------------------------------------------
-- 초기화
---------------------------------------------------
ALTER TABLE T1 ALTER COLUMN LOB STORE AS ( LOGGING BUFFER );

---------------------------------------------------
-- 1.4 LOB( * ) STORE
---------------------------------------------------
ALTER TABLE T1 ALTER COLUMN LOB(I2, I3) STORE AS ( NOLOGGING );
ALTER TABLE T1 ADD PARTITION P5;
-- {(P5,F,T), (P5,F,T)}
SELECT PART.PARTITION_NAME, LOBS.LOGGING, LOBS.BUFFER
FROM SYSTEM_.SYS_TABLES_ TAB, SYSTEM_.SYS_PART_LOBS_ LOBS,
     SYSTEM_.SYS_TABLE_PARTITIONS_ PART
WHERE TAB.TABLE_ID = LOBS.TABLE_ID AND
      TAB.TABLE_NAME = 'T1' AND 
      PART.PARTITION_ID = LOBS.PARTITION_ID AND
      PART.PARTITION_NAME = 'P5'
ORDER BY PART.PARTITION_NAME, LOBS.COLUMN_ID;
ALTER TABLE T1 COALESCE PARTITION;


--#########################################################################
--+ SECTOR; 2. SPLIT PARTITION
--#########################################################################

---------------------------------------------------
-- 초기화
---------------------------------------------------
ALTER TABLE T2 ALTER COLUMN LOB STORE AS ( LOGGING BUFFER );

---------------------------------------------------
-- 2.1 LOB STORE
---------------------------------------------------
ALTER TABLE T2 ALTER COLUMN LOB STORE AS ( NOLOGGING );
ALTER TABLE T2 SPLIT PARTITION P4 AT(5) INTO ( PARTITION P4, PARTITION P5 );
-- {(P5,F,T), (P5,F,T)}
SELECT PART.PARTITION_NAME, LOBS.LOGGING, LOBS.BUFFER
FROM SYSTEM_.SYS_TABLES_ TAB, SYSTEM_.SYS_PART_LOBS_ LOBS,
     SYSTEM_.SYS_TABLE_PARTITIONS_ PART
WHERE TAB.TABLE_ID = LOBS.TABLE_ID AND
      TAB.TABLE_NAME = 'T2' AND 
      PART.PARTITION_ID = LOBS.PARTITION_ID AND
      PART.PARTITION_NAME = 'P5'
ORDER BY PART.PARTITION_NAME, LOBS.COLUMN_ID;
ALTER TABLE T2 MERGE PARTITIONS P4, P5 INTO PARTITION P4;

---------------------------------------------------
-- 초기화
---------------------------------------------------
ALTER TABLE T2 ALTER COLUMN LOB STORE AS ( LOGGING BUFFER );

---------------------------------------------------
-- 2.2 LOB( clob_column ) STORE
---------------------------------------------------
ALTER TABLE T2 ALTER COLUMN LOB(I2) STORE AS ( NOLOGGING );
ALTER TABLE T2 SPLIT PARTITION P4 AT(5) INTO ( PARTITION P4, PARTITION P5 );
-- {(P5,F,T), (P5,T,T)}
SELECT PART.PARTITION_NAME, LOBS.LOGGING, LOBS.BUFFER
FROM SYSTEM_.SYS_TABLES_ TAB, SYSTEM_.SYS_PART_LOBS_ LOBS,
     SYSTEM_.SYS_TABLE_PARTITIONS_ PART
WHERE TAB.TABLE_ID = LOBS.TABLE_ID AND
      TAB.TABLE_NAME = 'T2' AND 
      PART.PARTITION_ID = LOBS.PARTITION_ID AND
      PART.PARTITION_NAME = 'P5'
ORDER BY PART.PARTITION_NAME, LOBS.COLUMN_ID;
ALTER TABLE T2 MERGE PARTITIONS P4, P5 INTO PARTITION P4;

---------------------------------------------------
-- 초기화
---------------------------------------------------
ALTER TABLE T2 ALTER COLUMN LOB STORE AS ( LOGGING BUFFER );

---------------------------------------------------
-- 2.3 LOB( blob_column ) STORE
---------------------------------------------------
ALTER TABLE T2 ALTER COLUMN LOB(I3) STORE AS ( NOLOGGING );
ALTER TABLE T2 SPLIT PARTITION P4 AT(5) INTO ( PARTITION P4, PARTITION P5 );
-- {(P5,T,T), (P5,F,T)}
SELECT PART.PARTITION_NAME, LOBS.LOGGING, LOBS.BUFFER
FROM SYSTEM_.SYS_TABLES_ TAB, SYSTEM_.SYS_PART_LOBS_ LOBS,
     SYSTEM_.SYS_TABLE_PARTITIONS_ PART
WHERE TAB.TABLE_ID = LOBS.TABLE_ID AND
      TAB.TABLE_NAME = 'T2' AND 
      PART.PARTITION_ID = LOBS.PARTITION_ID AND
      PART.PARTITION_NAME = 'P5'
ORDER BY PART.PARTITION_NAME, LOBS.COLUMN_ID;
ALTER TABLE T2 MERGE PARTITIONS P4, P5 INTO PARTITION P4;

---------------------------------------------------
-- 초기화
---------------------------------------------------
ALTER TABLE T2 ALTER COLUMN LOB STORE AS ( LOGGING BUFFER );

---------------------------------------------------
-- 2.4 LOB( * ) STORE
---------------------------------------------------
ALTER TABLE T2 ALTER COLUMN LOB(I2, I3) STORE AS ( NOLOGGING );
ALTER TABLE T2 SPLIT PARTITION P4 AT(5) INTO ( PARTITION P4, PARTITION P5 );
-- {(P5,F,T), (P5,F,T)}
SELECT PART.PARTITION_NAME, LOBS.LOGGING, LOBS.BUFFER
FROM SYSTEM_.SYS_TABLES_ TAB, SYSTEM_.SYS_PART_LOBS_ LOBS,
     SYSTEM_.SYS_TABLE_PARTITIONS_ PART
WHERE TAB.TABLE_ID = LOBS.TABLE_ID AND
      TAB.TABLE_NAME = 'T2' AND 
      PART.PARTITION_ID = LOBS.PARTITION_ID AND
      PART.PARTITION_NAME = 'P5'
ORDER BY PART.PARTITION_NAME, LOBS.COLUMN_ID;
ALTER TABLE T2 MERGE PARTITIONS P4, P5 INTO PARTITION P4;

--#########################################################################
--+ SECTOR; 3. MERGE PARTITION
--#########################################################################

---------------------------------------------------
-- 초기화
---------------------------------------------------
ALTER TABLE T2 ALTER COLUMN LOB STORE AS ( LOGGING BUFFER );

---------------------------------------------------
-- 2.1 LOB STORE
---------------------------------------------------
ALTER TABLE T2 ALTER COLUMN LOB STORE AS ( NOLOGGING );
ALTER TABLE T2 MERGE PARTITIONS P3, P4 INTO PARTITION P5;
-- {(P5,F,T), (P5,F,T)}
SELECT PART.PARTITION_NAME, LOBS.LOGGING, LOBS.BUFFER
FROM SYSTEM_.SYS_TABLES_ TAB, SYSTEM_.SYS_PART_LOBS_ LOBS,
     SYSTEM_.SYS_TABLE_PARTITIONS_ PART
WHERE TAB.TABLE_ID = LOBS.TABLE_ID AND
      TAB.TABLE_NAME = 'T2' AND 
      PART.PARTITION_ID = LOBS.PARTITION_ID AND
      PART.PARTITION_NAME = 'P5'
ORDER BY PART.PARTITION_NAME, LOBS.COLUMN_ID;
ALTER TABLE T2 SPLIT PARTITION P5 AT(4) INTO ( PARTITION P3, PARTITION P4 );

---------------------------------------------------
-- 초기화
---------------------------------------------------
ALTER TABLE T2 ALTER COLUMN LOB STORE AS ( LOGGING BUFFER );

---------------------------------------------------
-- 2.2 LOB( clob_column ) STORE
---------------------------------------------------
ALTER TABLE T2 ALTER COLUMN LOB(I2) STORE AS ( NOLOGGING );
ALTER TABLE T2 MERGE PARTITIONS P3, P4 INTO PARTITION P5;
-- {(P5,F,T), (P5,T,T)}
SELECT PART.PARTITION_NAME, LOBS.LOGGING, LOBS.BUFFER
FROM SYSTEM_.SYS_TABLES_ TAB, SYSTEM_.SYS_PART_LOBS_ LOBS,
     SYSTEM_.SYS_TABLE_PARTITIONS_ PART
WHERE TAB.TABLE_ID = LOBS.TABLE_ID AND
      TAB.TABLE_NAME = 'T2' AND 
      PART.PARTITION_ID = LOBS.PARTITION_ID AND
      PART.PARTITION_NAME = 'P5'
ORDER BY PART.PARTITION_NAME, LOBS.COLUMN_ID;
ALTER TABLE T2 SPLIT PARTITION P5 AT(4) INTO ( PARTITION P3, PARTITION P4 );

---------------------------------------------------
-- 초기화
---------------------------------------------------
ALTER TABLE T2 ALTER COLUMN LOB STORE AS ( LOGGING BUFFER );

---------------------------------------------------
-- 2.3 LOB( blob_column ) STORE
---------------------------------------------------
ALTER TABLE T2 ALTER COLUMN LOB(I3) STORE AS ( NOLOGGING );
ALTER TABLE T2 MERGE PARTITIONS P3, P4 INTO PARTITION P5;
-- {(P5,T,T), (P5,F,T)}
SELECT PART.PARTITION_NAME, LOBS.LOGGING, LOBS.BUFFER
FROM SYSTEM_.SYS_TABLES_ TAB, SYSTEM_.SYS_PART_LOBS_ LOBS,
     SYSTEM_.SYS_TABLE_PARTITIONS_ PART
WHERE TAB.TABLE_ID = LOBS.TABLE_ID AND
      TAB.TABLE_NAME = 'T2' AND 
      PART.PARTITION_ID = LOBS.PARTITION_ID AND
      PART.PARTITION_NAME = 'P5'
ORDER BY PART.PARTITION_NAME, LOBS.COLUMN_ID;
ALTER TABLE T2 SPLIT PARTITION P5 AT(4) INTO ( PARTITION P3, PARTITION P4 );

---------------------------------------------------
-- 초기화
---------------------------------------------------
ALTER TABLE T2 ALTER COLUMN LOB STORE AS ( LOGGING BUFFER );

---------------------------------------------------
-- 2.4 LOB( * ) STORE
---------------------------------------------------
ALTER TABLE T2 ALTER COLUMN LOB(I2, I3) STORE AS ( NOLOGGING );
ALTER TABLE T2 MERGE PARTITIONS P3, P4 INTO PARTITION P5;
-- {(P5,F,T), (P5,F,T)}
SELECT PART.PARTITION_NAME, LOBS.LOGGING, LOBS.BUFFER
FROM SYSTEM_.SYS_TABLES_ TAB, SYSTEM_.SYS_PART_LOBS_ LOBS,
     SYSTEM_.SYS_TABLE_PARTITIONS_ PART
WHERE TAB.TABLE_ID = LOBS.TABLE_ID AND
      TAB.TABLE_NAME = 'T2' AND 
      PART.PARTITION_ID = LOBS.PARTITION_ID AND
      PART.PARTITION_NAME = 'P5'
ORDER BY PART.PARTITION_NAME, LOBS.COLUMN_ID;
ALTER TABLE T2 SPLIT PARTITION P5 AT(4) INTO ( PARTITION P3, PARTITION P4 );

--###################################################################
--+ SECTOR; FINALIZATION
--###################################################################

--+SKIP BEGIN;
DROP TABLE T1;
DROP TABLE T2;
--+SKIP END;

