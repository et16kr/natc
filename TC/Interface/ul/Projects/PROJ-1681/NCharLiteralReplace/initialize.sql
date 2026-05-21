--############################################################################
--# FINALIZE DATABASE
--#
--# DATABASE CHARACTER SET: US7ASCII
--# NATIONAL CHARACTER SET: UTF16
--############################################################################

--+SET_ENV ALTIBASE_NLS_USE=US7ASCII;

--+SYSTEM server kill;
--+SYSTEM clean US7ASCII UTF16;
--+SYSTEM server start;
