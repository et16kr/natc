cd $ALTIBASE_HOME/conf
grep -v  DEFAULT_TEST_TABLESPACE  altibase.properties >> altibase.properties.disk
mv  altibase.properties.disk altibase.properties
echo "__DEFAULT_TEST_TABLESPACE = 2"        >> altibase.properties
