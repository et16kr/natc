echo "select count(*) from V$LFG" | ${ALTIBASE_HOME}/bin/isql -s 127.0.0.1 -u sys -p MANAGER | grep "Client unable to establish connection" | wc -l
