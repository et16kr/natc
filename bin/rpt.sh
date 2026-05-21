#!/usr/local/bin/bash

if [ $# -eq 1 ]
then
ATAF_TEST_RESULT=$1
fi

if [ "$HOSTNAME" = "m5000" ]; then
count=15
else
count=2
fi

i=0;
while [ $i -ne $count ]
do
 echo "=== report_p$i.log=== ";
 head -n 1 $ATAF_TEST_RESULT/result_p$i/work/log/report.log;
 tail -1 $ATAF_TEST_RESULT/result_p$i/work/log/report.log;

start_h=`head -n 1 $ATAF_TEST_RESULT/result_p$i/work/log/report.log |awk '{print $2}'|awk -F: '{print $1}'`
start_m=`head -n 1 $ATAF_TEST_RESULT/result_p$i/work/log/report.log |awk '{print $2}'|awk -F: '{print $2}'`
start_s=`head -n 1 $ATAF_TEST_RESULT/result_p$i/work/log/report.log |awk '{print $2}'|awk -F: '{print $3}'|awk -F] '{print $1}'`

end_h=`tail -1 $ATAF_TEST_RESULT/result_p$i/work/log/report.log |awk '{print $2}'|awk -F: '{print $1}'`
end_m=`tail -1 $ATAF_TEST_RESULT/result_p$i/work/log/report.log |awk '{print $2}'|awk -F: '{print $2}'`
end_s=`tail -1 $ATAF_TEST_RESULT/result_p$i/work/log/report.log |awk '{print $2}'|awk -F: '{print $3}'|awk -F] '{print $1}'`

start_h=`echo $start_h|sed 's/^0*//'`
start_m=`echo $start_m|sed 's/^0*//'`
start_s=`echo $start_s|sed 's/^0*//'`
end_h=`echo $end_h|sed 's/^0*//'`
end_m=`echo $end_m|sed 's/^0*//'`
end_s=`echo $end_s|sed 's/^0*//'`

elapsed_h=$((end_h-start_h));
elapsed_m=$((end_m-start_m));
elapsed_s=$((end_s-start_s));

if [ $elapsed_s -lt 0 ]; then
elapsed_s=$((elapsed_s+60))
elapsed_m=$((elapsed_m-1))
fi

if [ $elapsed_m -lt 0 ]; then
elapsed_m=$((elapsed_m+60))
elapsed_h=$((elapsed_h-1))
fi

if [ $elapsed_h -lt 0 ]; then
elapsed_h=$((elapsed_h+24))
fi

echo "        ** $elapsed_h:$elapsed_m:$elapsed_s";

i=`expr $i + 1`
done
