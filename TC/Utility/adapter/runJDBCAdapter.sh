#!/bin/sh

if [ -z "$ALTIBASE_HOME" ]
then
    echo "please set ALTIBASE_HOME environment variable"
    exit -1
fi
if [ -z "$ALTIDEV_HOME" ]
then
    echo "please set ALTIDEV_HOME environment variable"
    exit -1
fi

export PATH=$ADAPTER_JAVA_HOME/bin:$PATH
export JDBC_ADAPTER_HOME=$ALTIDEV_HOME/ut/adapter/src/dist
export LD_LIBRARY_PATH=$ADAPTER_JAVA_HOME/jre/lib/amd64/server:$LD_LIBRARY_PATH

cd $ALTIDEV_HOME/ut/adapter/src
make clean
make jdbcAdapter
make dist_jdbcAdapter
cd $OLDPWD
unset ADAPTER_TYPE

atsclnt $ATC_HOME/TC/Utility/adapter/jdbcAdapter.ts

