--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/PDT/Bugs/BUG-37/BUG-37.sql
--#
--# Body below is byte-identical to the original. The one line this port
--# adds is the premise: the original measures these statements on the
--# $GIT_ hidden-table implementation, this file measures the same
--# statements on the native global index (F07 -- see include/pinNative.sql).
--###########################################################################
--+LOAD_SQL ../../../include/pinNative.sql;

--###################################################################
--+SECTOR; PREPARATION
--###################################################################

--+SKIP BEGIN;
DROP TABLE T1;
DROP INDEX IDX;
--+SKIP END;

CREATE TABLE T1( I1 DATE, I2 DATE, I3 INTEGER )
PARTITION BY RANGE (I1, I2)
(
    PARTITION P1 VALUES LESS THAN ( TO_DATE('2007-05-05', 'YYYY-MM-DD'), TO_DATE('2007-05-05', 'YYYY-MM-DD') ) TABLESPACE PDT_TBS2,
    PARTITION P2 VALUES LESS THAN ( TO_DATE('2007-06-05', 'YYYY-MM-DD'), TO_DATE('2007-05-05', 'YYYY-MM-DD') ) TABLESPACE PDT_TBS3,
    PARTITION P3 VALUES LESS THAN ( TO_DATE('2007-07-05', 'YYYY-MM-DD'), TO_DATE('2007-05-05', 'YYYY-MM-DD') ),
    PARTITION P4 VALUES DEFAULT TABLESPACE PDT_TBS4
) TABLESPACE PDT_TBS;

CREATE INDEX IDX ON T1(I2, I3);

ALTER TABLE T1 ENABLE ROW MOVEMENT;

INSERT INTO T1 VALUES (TO_DATE('2007-05-01', 'YYYY-MM-DD'), TO_DATE('2007-05-05', 'YYYY-MM-DD'), 100);
INSERT INTO T1 VALUES (TO_DATE('2007-05-05', 'YYYY-MM-DD'), TO_DATE('2007-05-05', 'YYYY-MM-DD'), 100);
INSERT INTO T1 VALUES (TO_DATE('2007-05-15', 'YYYY-MM-DD'), TO_DATE('2007-05-05', 'YYYY-MM-DD'), 100);
INSERT INTO T1 VALUES (TO_DATE('2007-06-05', 'YYYY-MM-DD'), TO_DATE('2007-05-05', 'YYYY-MM-DD'), 100);
INSERT INTO T1 VALUES (TO_DATE('2007-06-15', 'YYYY-MM-DD'), TO_DATE('2007-05-05', 'YYYY-MM-DD'), 100);
INSERT INTO T1 VALUES (TO_DATE('2007-07-05', 'YYYY-MM-DD'), TO_DATE('2007-05-05', 'YYYY-MM-DD'), 100);
INSERT INTO T1 VALUES (TO_DATE('2007-07-15', 'YYYY-MM-DD'), TO_DATE('2007-05-05', 'YYYY-MM-DD'), 100);
INSERT INTO T1 VALUES (TO_DATE('2007-08-05', 'YYYY-MM-DD'), TO_DATE('2007-05-05', 'YYYY-MM-DD'), 100);

--##################################################################
--+SECTOR; DO JOB
--##################################################################

UPDATE T1 SET I1 = TO_DATE('2007-05-01', 'YYYY-MM-DD');

--+SYSTEM sleep 1;

-- should be success
SELECT COUNT(*) FROM T1 PARTITION (P4);

--##################################################################
--+SECTOR; FINALIZATION
--##################################################################

--+SKIP BEGIN;
DROP TABLE T1;
DROP INDEX IDX;
--+SKIP END;
