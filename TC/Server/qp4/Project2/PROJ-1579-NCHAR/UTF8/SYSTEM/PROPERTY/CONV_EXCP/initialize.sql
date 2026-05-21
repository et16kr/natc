--############################################################################
--# INITIALIZE DATABASE
--#
--# DATABASE CHARACTER SET: KO16KSC5601
--# NATIONAL CHARACTER SET: UTF8
--############################################################################

--+SET_ENV ALTIBASE_NLS_USE=KO16KSC5601;

--+SYSTEM server kill;
--+SYSTEM clean ksc5601 utf8;
--+SYSTEM server start;

