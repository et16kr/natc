--###########################################################################
--# initialize
--###########################################################################

--##################################
--+SECTOR; PREPARATION
--##################################

--+SKIP BEGIN;
DROP TABLESPACE USER_VOL INCLUDING CONTENTS AND DATAFILES;
--+SKIP END;

--##################################
--+SECTOR; CREATE VOLATILE TABLESPACE
--##################################

CREATE VOLATILE DATA TABLESPACE USER_VOL SIZE 32M AUTOEXTEND ON NEXT 128M;
