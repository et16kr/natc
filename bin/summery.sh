#!/usr/local/bin/bash

if [ "x$1" == "x" ]
then
   rpath=""
else
   rpath=/result_p$1
fi

cat $ATAF_TEST_RESULT$rpath/work/log/*all_count*.log > $ATAF_TEST_RESULT$rpath/work/log/total_count.log
cat $ATAF_TEST_RESULT$rpath/work/log/report.log > $ATAF_TEST_RESULT$rpath/work/log/total_report.log 

all_cnt=`cat $ATAF_TEST_RESULT$rpath/work/log/total_count.log | wc -l`
Y_cnt=`cat $ATAF_TEST_RESULT$rpath/work/log/total_count.log | awk -F '|' '{print $1}' | grep Y | wc -l`
N_cnt=`cat $ATAF_TEST_RESULT$rpath/work/log/total_count.log | awk -F '|' '{print $1}' | grep N | wc -l`
S_cnt=`cat $ATAF_TEST_RESULT$rpath/work/log/total_count.log | awk -F '|' '{print $1}' | grep S | wc -l`

run_all=`cat $ATAF_TEST_RESULT$rpath/work/log/total_report.log | grep -v END | wc -l`
run_pass=`cat $ATAF_TEST_RESULT$rpath/work/log/total_report.log | awk -F '|' '{printf("%s\n", $2);}' | grep PASS | wc -l`
run_fail=`cat $ATAF_TEST_RESULT$rpath/work/log/total_report.log| awk -F '|' '{printf("%s\n", $2);}' | grep FAIL | wc -l`
run_fatal=`cat $ATAF_TEST_RESULT$rpath/work/log/total_report.log | awk -F '|' '{printf("%s\n", $2);}' | grep FATAL | wc -l`

echo "============= TOTAL ================"
echo "  TOTAL CNT   :   $all_cnt";
echo "  PASS  CNT   :   $run_pass";
echo "  FAIL  CNT   :   $run_fail";
echo "  SKIP  CNT   :   $S_cnt";
echo "  RUN   CNT   :   $run_all";
echo "  #     CNT   :   $N_cnt";
echo "  FATAL CNT   :   $run_fatal";

