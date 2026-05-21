#!/bin/sh

if [ -z "$ORACLE_HOME" ]
then
    echo "please set ORACLE_HOME environment variable"
    exit -1
fi

cd $ALTIDEV_HOME/ut/adapter/src
make clean
make oraAdapter
make dist_oraAdapter||true
export ADAPTER_TYPE=1
cd $OLDPWD

if [ -d "$ALTIDEV_HOME/ut/adapter/src/dist" ]
then
    export ORA_ADAPTER_HOME=$ALTIDEV_HOME/ut/adapter/src/dist
else
    echo "please make dist_oraAdapter $ALTIDEV_HOME/ut/adapter/src/dist"
    exit -1
fi


atsclnt $ATC_HOME/TC/Utility/adapter/oraAdapter.ts 


