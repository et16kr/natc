--#############################################################
--# MEMORY INDEX BUILD INITIALIZE
--#############################################################

ALTER SYSTEM SET MEMORY_INDEX_BUILD_VALUE_LENGTH_THRESHOLD=8192;

SELECT NAME, VALUE1 FROM V$PROPERTY WHERE NAME = 'MEMORY_INDEX_BUILD_VALUE_LENGTH_THRESHOLD';
