--##########################################################################
--# PR-20578
--##########################################################################

--################################
--+SECTOR; PREPARATION
--################################

--+SKIP BEGIN;
DROP TABLESPACE user_data01 INCLUDING CONTENTS AND DATAFILES CASCADE CONSTRAINTS;
--+SKIP END;

CREATE TABLESPACE user_data01 DATAFILE 'user_data01.dbf' SIZE 10M AUTOEXTEND ON;


