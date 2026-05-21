--############################################################################
--# INITIALIZE DATABASE
--#
--# DATABASE CHARACTER SET: KO16KSC5601
--# NATIONAL CHARACTER SET: UTF16
--############################################################################

--+SET_ENV ALTIBASE_NLS_USE=KO16KSC5601;
--+SET_ENV ALTIBASE_LOB_OBJECT_BUFFER_SIZE=64000;

--+SYSTEM server kill;
--+SYSTEM clean ksc5601 utf16;
--+SYSTEM server start;

