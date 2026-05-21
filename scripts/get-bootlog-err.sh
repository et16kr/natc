tail -128 $ALTIBASE_HOME/trc/altibase_boot.log  | grep "ERR-" | sed "s/\[Thr:[ ]*[0-9]*\]//g" | sed -e "s|${ATAF_TEST_RESULT}||g" | tail -1

