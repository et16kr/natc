#!/usr/local/bin/bash

cat $ATAF_TEST_RESULT/work/log/*all_count*.log > $ATAF_TEST_RESULT/work/log/total_count.log
cat $ATAF_TEST_RESULT/work/log/*report*.log > $ATAF_TEST_RESULT/work/log/total_report.log

all_cnt=`cat $ATAF_TEST_RESULT/work/log/total_count.log | wc -l`
Y_cnt=`cat $ATAF_TEST_RESULT/work/log/total_count.log | awk -F '|' '{print $1}' | grep Y | wc -l`
N_cnt=`cat $ATAF_TEST_RESULT/work/log/total_count.log | awk -F '|' '{print $1}' | grep N | wc -l`
S_cnt=`cat $ATAF_TEST_RESULT/work/log/total_count.log | awk -F '|' '{print $1}' | grep S | wc -l`

run_all=`cat $ATAF_TEST_RESULT/work/log/total_report.log | grep -v END | wc -l`
run_pass=`cat $ATAF_TEST_RESULT/work/log/total_report.log | awk -F '|' '{printf("%s\n", $2);}' | grep PASS | wc -l`
run_fail=`cat $ATAF_TEST_RESULT/work/log/total_report.log| awk -F '|' '{printf("%s\n", $2);}' | grep FAIL | wc -l`
run_fatal=`cat $ATAF_TEST_RESULT/work/log/total_report.log | awk -F '|' '{printf("%s\n", $2);}' | grep FATAL | wc -l`
run_hang=`cat $ATAF_TEST_RESULT/work/log/total_report.log | awk -F '|' '{printf("%s\n", $2);}' | grep HANG | wc -l`
run_cored=`cat $ATAF_TEST_RESULT/work/log/total_report.log | awk -F '|' '{printf("%s\n", $2);}' | grep CORED | wc -l`

echo "============= P$i ================"
echo "  TOTAL CNT   :   $all_cnt";
echo "  Y CNT       :   $Y_cnt";
echo "  N CNT       :   $N_cnt";
echo "  S CNT       :   $S_cnt";
echo "============= TOTAL ================"
echo "  RUN   p$i   :   $run_all";
echo "  PASS  p$i   :   $run_pass";
echo "  FAIL  p$i   :   $run_fail";
echo "  FATAL p$i   :   $run_fatal";
echo "  HANG p$i   :   $run_hang";
echo "  CORED p$i   :   $run_cored";

echo "insert into natc_summary(TEST_PK,TOTAL_CNT,DO_CNT,COMMENT_CNT,SKIP_CNT,RUN_CNT,PASS_CNT,FAIL_CNT,FATAL_CNT,HANG_CNT,CORED_CNT) values(%s,$all_cnt,$Y_cnt,$N_cnt,$S_cnt,$run_all,$run_pass,$run_fail,$run_fatal,$run_hang,$run_cored)" > $ATC_WORK/log/natc_count.log
