cd $ALTIBASE_HOME/conf
grep -v  DEFAULT_TEST_TABLESPACE  altibase.properties >> altibase.properties.restore
mv  altibase.properties.restore altibase.properties
