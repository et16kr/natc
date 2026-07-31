#!/usr/local/bin/bash

# 프로그램 컴파일
make clean; make;

# 이전 로그 삭제
a=testResult
log="$a".log
if [ ! -d "$a" ]; then
    mkdir "$a";
fi

function doJob4LT()
{
    # 이전 로그 삭제
    rm -rf test.log

    # 프로세스 실행
    ./testLT $opType 10000 &

    wait
}

function doJob4GT()
{
    # 이전 로그 삭제
    rm -rf test.log

    # 프로세스 실행
    ./testGT $opType 10000 &

    wait
}

for testType in LT GT
do
    # server clean, BUFFER_AREA_SIZE 늘임
    server_restart.sh;
    wait

    # TBS & TBL 생성 
    is -f schema.sql;
    is -f checkpoint.sql;

    echo "#######################################################"
    echo "#  Partitioned Disk Table Test [$testType] [I/S/U/R/D] "
    echo "#######################################################"

    # S/U/D 연산 수행
    for opType in I S U R D
    do
        case $opType in
            R) is -f alter_table.sql
        esac

        case $testType in
            GT) doJob4GT;;
            LT) doJob4LT;;
        esac

        case $opType in
            I) echo "$testType INSERT" >> $log;;
            S) echo "$testType SELECT" >> $log;;
            U) echo "$testType UPDATE" >> $log;;
            R) echo "$testType UPDATE_ROW_MOVEMENT" >> $log;;
            D) echo "$testType DELETE" >> $log;;
        esac
        
        # TPS 계산 및 로그 저장
        tps.sh >> $log; mv test.log "$a"/"$testType"_"$opType".log
        sleep 10

    done
done    


