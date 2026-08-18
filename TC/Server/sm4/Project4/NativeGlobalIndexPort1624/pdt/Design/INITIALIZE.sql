--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/PDT/Design/INITIALIZE.sql
--#
--# Body below is byte-identical to the original. The one line this port
--# adds is the premise: the original measures these statements on the
--# $GIT_ hidden-table implementation, this file measures the same
--# statements on the native global index (F07 -- see include/pinNative.sql).
--###########################################################################
--+LOAD_SQL ../../include/pinNative.sql;

--######################################################
-- Initialize tablespace 
--######################################################

--+SKIP BEGIN;
DROP TABLESPACE PDT_TBS 
INCLUDING CONTENTS AND DATAFILES
CASCADE CONSTRAINTS;

DROP TABLESPACE PDT_TBS2 
INCLUDING CONTENTS AND DATAFILES
CASCADE CONSTRAINTS;

DROP TABLESPACE PDT_TBS3
INCLUDING CONTENTS AND DATAFILES
CASCADE CONSTRAINTS;

DROP TABLESPACE PDT_TBS4
INCLUDING CONTENTS AND DATAFILES
CASCADE CONSTRAINTS;

DROP TABLESPACE PDT_TBS5
INCLUDING CONTENTS AND DATAFILES
CASCADE CONSTRAINTS;

DROP FUNCTION TO_DATE_FUNC;

--+SKIP END;

CREATE TABLESPACE PDT_TBS
DATAFILE 'PDT_TBS.dbf' 
SIZE 50M 
AUTOEXTEND ON;

CREATE TABLESPACE PDT_TBS2
DATAFILE 'PDT_TBS2.dbf' 
SIZE 10M 
AUTOEXTEND ON;

CREATE TABLESPACE PDT_TBS3
DATAFILE 'PDT_TBS3.dbf' 
SIZE 10M 
AUTOEXTEND ON;

CREATE TABLESPACE PDT_TBS4
DATAFILE 'PDT_TBS4.dbf' 
SIZE 10M 
AUTOEXTEND ON;

CREATE TABLESPACE PDT_TBS5
DATAFILE 'PDT_TBS5.dbf' 
SIZE 10M 
AUTOEXTEND ON;

CREATE OR REPLACE FUNCTION TO_DATE_FUNC( P1 IN VARCHAR(100), P2 IN VARCHAR(100) )
RETURN DATE
AS
    BEGIN
        RETURN TO_DATE( P1, P2 );
    END;
/
