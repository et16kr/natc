#!/bin/sh

if [ -z "$ALTIBASE_HOME" ]
then
    echo "please set ORACLE_HOME environment variable"
    exit -1
fi
if [ -z "$ALTIDEV_HOME" ]
then
    echo "please set ALTIDEV_HOME environment variable"
    exit -1
fi
export ALTIBASE_ADAPTER_HOME=$ALTIDEV_HOME/ut/adapter/src/dist

cd $ALTIDEV_HOME/ut/adapter/src
make clean
make altiAdapter
make dist_altiAdapter
export ADAPTER_TYPE=0
cd $OLDPWD

atsclnt $ATC_HOME/TC/Utility/adapter/altiAdapter.ts 


