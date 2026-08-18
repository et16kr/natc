--###########################################################################
--# ported from qp4/Project3/PROJ-1624-GlobalIndex/PROJ-1624-QC/PDT/Bugs/INITIALIZE.sql
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
